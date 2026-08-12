import Foundation
import FootballSimCore

// The both-tier professional soak the M6/M7 handoff names as open.
//
// M6 built the whole professional market - free agency, the draft, waivers, practice squads, trades
// and sourced contract expiry - and until now **no soak had ever driven it across seasons**. The
// focused suites prove each transaction in isolation; nothing proved that thirty-two teams stay cap
// legal and roster legal while the college tier runs beside them for years.
//
// It asserts per season rather than only at the end, because a soak that checks once at the finish
// tells you something broke without telling you when.

func runProSoakTests() {
    let requested = ProcessInfo.processInfo.environment["PRO_SOAK_SEASONS"]
        .flatMap(Int.init) ?? 10
    precondition(requested >= 1, "The professional soak needs at least one season.")

    suite("Professional both-tier soak") {
        test("thirty-two professional teams stay legal for \(requested) seasons") {
            var state = GameState.bootstrap(seed: 96_001)
            var capBreaches: [String] = []
            var rosterBreaches: [String] = []
            var contractBreaches: [String] = []
            var weekDurations: [Double] = []
            var marketPhasesSeen: Set<String> = []
            var draftedPerSeason: [Int] = []
            // Counted from emitted events rather than sampled from the phase, because a phase read
            // at a week boundary misses a market that opened and closed inside one week, and a
            // "phases changed" guard passes while the draft itself never fires.
            var proEventCounts: [String: Int] = [:]
            var checkpoints: [(season: Int, bytes: Int)] = []
            let measured = Set([1, min(5, requested), requested])

            for targetSeason in 1...requested {
                while state.calendar.season < targetSeason {
                    let started = Date.timeIntervalSinceReferenceDate
                    let transition = try WorldScheduler.advanceWeek(state)
                    state = transition.state
                    weekDurations.append(Date.timeIntervalSinceReferenceDate - started)
                    marketPhasesSeen.insert(String(describing: state.proMarket.phase))
                    for event in transition.emittedEvents {
                        guard let name = proEventName(event.payload) else { continue }
                        proEventCounts[name, default: 0] += 1
                    }
                }

                // Cap and roster legality, every team, every season. `capSnapshot` is the same
                // derivation the transaction boundary validates against, so a soak failure here and
                // a rejected signing mean the same thing.
                for team in state.proTeams.values {
                    let cap = try ProManagementSystem.capSnapshot(teamID: team.id, in: state)
                    if !cap.isWithinCap {
                        capBreaches.append(
                            "s\(targetSeason) \(team.name): committed \(cap.committedCap) "
                                + "over \(cap.capLimit)"
                        )
                    }
                    if cap.activeRosterCount > ProRules.activeRosterLimit {
                        rosterBreaches.append(
                            "s\(targetSeason) \(team.name): \(cap.activeRosterCount) active"
                        )
                    }
                    if cap.practiceSquadCount > ProRules.practiceSquadLimit {
                        rosterBreaches.append(
                            "s\(targetSeason) \(team.name): \(cap.practiceSquadCount) practice squad"
                        )
                    }
                }

                // A contracted professional must be owned by exactly one team, and an owned
                // professional must not be carrying college eligibility.
                for team in state.proTeams.values {
                    for playerID in team.rosterIDs + team.practiceSquadIDs {
                        guard let player = state.players[playerID] else {
                            contractBreaches.append("s\(targetSeason): \(playerID) is owned but absent")
                            continue
                        }
                        if player.eligibility != nil {
                            contractBreaches.append(
                                "s\(targetSeason) \(team.name): \(player.fullName) carries college "
                                    + "eligibility on a professional roster"
                            )
                        }
                    }
                }

                draftedPerSeason.append(state.proMarket.draftedProspectIDs.count)
                expect(WorldIntegrity.check(state).isValid,
                       "the root is not valid at season \(targetSeason)")

                if measured.contains(targetSeason) {
                    checkpoints.append((targetSeason, try SaveEnvelope.encode(state).count))
                }
            }

            expect(capBreaches.isEmpty,
                   "teams exceeded the salary cap: " + capBreaches.prefix(5).joined(separator: "; "))
            expect(rosterBreaches.isEmpty,
                   "teams exceeded a roster bound: "
                       + rosterBreaches.prefix(5).joined(separator: "; "))
            expect(contractBreaches.isEmpty,
                   "professional ownership is inconsistent: "
                       + contractBreaches.prefix(5).joined(separator: "; "))

            // The guard against a green soak that drove nothing. Phase sampling is not enough: the
            // first version of this passed on closed/freeAgency alone while the draft never ran at
            // all, which is the whole professional intake path.
            expect((proEventCounts["proMarketOpened"] ?? 0) > 0,
                   "the professional market never opened across \(requested) seasons")
            expect((proEventCounts["proDraftPick"] ?? 0) > 0,
                   "no professional draft pick was ever made across \(requested) seasons, so "
                       + "professional rosters take in no drafted talent at all: "
                       + proEventCounts.sorted { $0.key < $1.key }
                           .map { "\($0.key)=\($0.value)" }.joined(separator: " "))

            let sizes = checkpoints.map { "s\($0.season)=\($0.bytes)B" }.joined(separator: " ")
            let weekTotal = weekDurations.reduce(0, +)
            print("""
            Pro soak: seasons=\(requested) weeks=\(weekDurations.count) \
            weekMeanMs=\(String(format: "%.2f", weekDurations.isEmpty ? 0 : weekTotal / Double(weekDurations.count) * 1000)) \
            teams=\(state.proTeams.count) phasesSeen=\(marketPhasesSeen.sorted().joined(separator: "/")) \
            draftedFinal=\(draftedPerSeason.last ?? 0) \
            events=[\(proEventCounts.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: " "))] \
            freeAgents=\(state.proMarket.freeAgentIDs.count) \
            waivers=\(state.proMarket.waivers.count) save: \(sizes)
            """)
        }

        test("a replayed professional career is byte-identical") {
            // Determinism across the professional systems specifically. The portal-scheduler replay
            // covers the college tier; nothing covered a run in which the draft, free agency and
            // waivers all fire.
            func run() throws -> Data {
                var state = GameState.bootstrap(seed: 96_002)
                for _ in 0..<(SharedRules.inSeasonWeeks * 2) {
                    state = try WorldScheduler.advanceWeek(state).state
                }
                return try SaveEnvelope.encode(state)
            }
            expectEqual(try run(), try run())
        }
    }
}


/// The professional payload names the soak counts, or nil for everything else.
///
/// A `switch` rather than `String(describing:)`, because these names are compared against literals
/// in assertions and a reflected case name is not a stable contract.
private func proEventName(_ payload: DomainEventPayload) -> String? {
    switch payload {
    case .proMarketOpened: return "proMarketOpened"
    case .proDraftStarted: return "proDraftStarted"
    case .proDraftPick: return "proDraftPick"
    case .proPlayerSigned: return "proPlayerSigned"
    case .proTradeCompleted: return "proTradeCompleted"
    case .proWaiverPlaced: return "proWaiverPlaced"
    case .proWaiverClaimed: return "proWaiverClaimed"
    case .proWaiverExpired: return "proWaiverExpired"
    case .proWaiversResolved: return "proWaiversResolved"
    case .proContractExpired: return "proContractExpired"
    case .proPracticeSquadMoved: return "proPracticeSquadMoved"
    case .proMarketClosed: return "proMarketClosed"
    case .proDraftScouted: return "proDraftScouted"
    default: return nil
    }
}

/// A fast probe for why the draft makes no picks, without advancing seasons.
///
/// The soak takes twelve minutes to say "no picks were made". This reaches the same state directly
/// and reports the thrown reason, which the AI driver deliberately swallows so one refused pick
/// cannot spin the loop forever.
func runProDraftProbeTests() {
    suite("Professional draft probe") {
        test("the first draft pick of a bootstrapped world reports why it fails") {
            var state = GameState.bootstrap(seed: 96_003)
            state = try ProMarketSystem.openOffseason(in: state)
            state = try ProMarketSystem.beginDraft(in: state)

            expectEqual(state.proMarket.phase, .draft)
            expect(!state.proMarket.draftClass.isEmpty, "the draft class is empty")

            guard let teamID = state.proMarket.currentPickTeamID else {
                expect(false, "no team is on the clock immediately after the draft begins")
                return
            }
            guard let prospect = state.proMarket.draftClass.first else { return }
            let team = state.proTeams[teamID]
            let cap = try ProManagementSystem.capSnapshot(teamID: teamID, in: state)

            do {
                _ = try ProMarketSystem.draft(prospectID: prospect.id, for: teamID, in: state)
                print("Pro draft probe: first pick succeeded")
            } catch {
                print("""
                Pro draft probe: first pick threw \(error) \
                roster=\(team?.rosterIDs.count ?? -1)/\(ProRules.activeRosterLimit) \
                practiceSquad=\(team?.practiceSquadIDs.count ?? -1)/\(ProRules.practiceSquadLimit) \
                committedCap=\(cap.committedCap)/\(cap.capLimit) \
                draftClass=\(state.proMarket.draftClass.count)
                """)
                expect(false, "the first draft pick of a fresh world cannot be made: \(error)")
            }
        }
    }
}
