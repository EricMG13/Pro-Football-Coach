import Foundation
import FootballSimCore

/// Attribution probe for "1,476 free-agency signings relocate nobody".
///
/// The churn band measured professional `moved` as exactly zero at every season boundary across ten
/// seasons and 32 clubs, while `--pro-soak` counted 1,476 `proPlayerSigned` events over the same
/// span. Both numbers are solid and they look contradictory, because a season-boundary snapshot
/// cannot see what happened between two boundaries: a signing that returns a player to the club
/// they left is invisible to it, and so is a signing whose player is gone again before the next
/// boundary.
///
/// So this watches every week rather than every season, and classifies each signing against the
/// club that last owned the player. It reports, per season:
///
///   - expiries, and the club each player left
///   - signings split into `returned` (same club) and `relocated` (different club)
///   - whether a signed player lands on the active roster or the practice squad, since the churn
///     snapshot reads `rosterIDs` only and a practice-squad landing would read as a departure
///   - the free-agent pool depth each week free agency runs, and who is left in it at season end
///
/// Written as a probe rather than as assertions in the ten-season band suite for the reason
/// `--pro-draft-probe` exists: that suite takes sixteen minutes and answers "something is wrong",
/// and this takes a fraction of it and answers "this is the wrong thing".
func runProMovementProbe() {
    let seasons = ProcessInfo.processInfo.environment["PRO_MOVEMENT_SEASONS"]
        .flatMap(Int.init) ?? 3
    var state = GameState.bootstrap(seed: 96_001)
    var ownerByPlayer = proOwnership(state)

    print("PROBE: bootstrap rosters=\(ownerByPlayer.count) freeAgents=\(state.proMarket.freeAgentIDs.count)")

    for targetSeason in 1...seasons {
        var expired = 0
        var returned = 0
        var relocated = 0
        var signedToPracticeSquad = 0
        var signedWithNoPriorClub = 0
        var retiredOrGone = 0
        var poolDepths: [Int] = []

        while state.calendar.season < targetSeason {
            let transition: WorldTransition
            do {
                transition = try WorldScheduler.advanceWeek(state)
            } catch {
                print("PROBE: advanceWeek failed at \(state.calendar): \(error)")
                return
            }
            let before = state
            state = transition.state

            if before.proMarket.phase == .freeAgency {
                poolDepths.append(before.proMarket.freeAgentIDs.count)
            }

            for event in transition.emittedEvents {
                switch event.payload {
                case .proContractExpired:
                    // The payload names only the player, so the club comes from the ownership map,
                    // which already holds whoever last rostered them.
                    expired += 1
                case let .proPlayerSigned(playerID, teamID, _, _):
                    switch ownerByPlayer[playerID] {
                    case .none: signedWithNoPriorClub += 1
                    case .some(teamID): returned += 1
                    case .some: relocated += 1
                    }
                    if state.proTeams[teamID]?.practiceSquadIDs.contains(playerID) == true {
                        signedToPracticeSquad += 1
                    }
                    ownerByPlayer[playerID] = teamID
                default:
                    break
                }
            }
        }

        let nowOwned = proOwnership(state)
        retiredOrGone = ownerByPlayer.keys.filter { nowOwned[$0] == nil }.count
        let poolSummary = poolDepths.isEmpty
            ? "free agency never ran"
            : "weeks=\(poolDepths.count) depth min=\(poolDepths.min() ?? 0) max=\(poolDepths.max() ?? 0)"

        print("""
        PROBE season \(targetSeason): expired=\(expired) \
        returned=\(returned) relocated=\(relocated) \
        noPriorClub=\(signedWithNoPriorClub) toPracticeSquad=\(signedToPracticeSquad)
        PROBE season \(targetSeason): rosters=\(nowOwned.count) \
        unaccounted=\(retiredOrGone) poolLeft=\(state.proMarket.freeAgentIDs.count) \
        freeAgency \(poolSummary)
        """)
        ownerByPlayer = nowOwned.merging(ownerByPlayer) { current, _ in current }
    }
}

/// Which club owns each professional right now, active roster and practice squad alike.
private func proOwnership(_ state: GameState) -> [UUID: UUID] {
    var owner: [UUID: UUID] = [:]
    for team in state.proTeams.values {
        for playerID in team.rosterIDs + team.practiceSquadIDs { owner[playerID] = team.id }
    }
    return owner
}

/// Attribution probe for "the draft takes zero picks in ten seasons while starting nine times".
///
/// `--pro-draft-probe` says a draft immediately after expiry succeeds — `ProMarketSystem.draft`
/// works, in isolation, right after `expireContracts`. But the live scheduler does not begin the
/// draft there: `ProRosterAISystem.signFreeAgents` runs free agency first, refilling rosters toward
/// 53 for as many weeks as it keeps signing someone, and only calls `beginDraft` on the first week
/// that signs nobody. By then the roster state the draft actually starts from may look nothing like
/// the probe's fixture. `ProRosterAISystem.makeDraftPicks` also swallows its own failure — any
/// thrown error just `break`s the loop with no record of what it was — so the live scheduler cannot
/// itself say why. This calls `ProMarketSystem.draft` the same way that loop does, the moment the
/// real scheduler enters `.draft`, and prints what it throws.
func runProDraftStallProbe() {
    let seasons = ProcessInfo.processInfo.environment["PRO_MOVEMENT_SEASONS"]
        .flatMap(Int.init) ?? 3
    var state = GameState.bootstrap(seed: 96_001)
    var reportedSeasons = 0

    while reportedSeasons < seasons {
        let before = state
        let transition: WorldTransition
        do {
            transition = try WorldScheduler.advanceWeek(state)
        } catch {
            print("PROBE: advanceWeek failed at \(state.calendar): \(error)")
            return
        }
        state = transition.state

        let justEnteredDraft = before.proMarket.phase != .draft && state.proMarket.phase == .draft
        guard justEnteredDraft else { continue }
        reportedSeasons += 1

        guard let teamID = state.proMarket.currentPickTeamID else {
            print("PROBE season \(reportedSeasons): entered draft with no team on the clock, "
                + "draftOrder empty=\(state.proMarket.draftOrder.isEmpty)")
            continue
        }
        let team = state.proTeams[teamID]
        let takenIDs = Set(state.proMarket.draftedProspectIDs)
        let best = state.proMarket.draftClass
            .filter { !takenIDs.contains($0.id) }
            .min { lhs, rhs in
                lhs.player.overall.value == rhs.player.overall.value
                    ? lhs.id.uuidString < rhs.id.uuidString
                    : lhs.player.overall.value > rhs.player.overall.value
            }
        guard let prospect = best else {
            print("PROBE season \(reportedSeasons): draft class exhausted immediately, "
                + "class=\(state.proMarket.draftClass.count) taken=\(takenIDs.count)")
            continue
        }
        let cap = (try? ProManagementSystem.capSnapshot(teamID: teamID, in: state))
        do {
            _ = try ProMarketSystem.draft(
                prospectID: prospect.id,
                for: teamID,
                contract: ProMarketSystem.rookieContract(for: prospect.player),
                in: state
            )
            print("PROBE season \(reportedSeasons): first live pick succeeded for \(teamID)")
        } catch {
            print("""
            PROBE season \(reportedSeasons): first live pick threw \(error) \
            team=\(teamID) roster=\(team?.rosterIDs.count ?? -1)/\(ProRules.activeRosterLimit) \
            practiceSquad=\(team?.practiceSquadIDs.count ?? -1)/\(ProRules.practiceSquadLimit) \
            committedCap=\(cap?.committedCap ?? -1)/\(cap?.capLimit ?? -1) \
            draftClass=\(state.proMarket.draftClass.count)
            """)
        }
    }
}
