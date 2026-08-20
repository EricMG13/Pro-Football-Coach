import Foundation
import FootballSimCore

func runTraitPopulationTests() {
    suite("Trait population persistence") {
        test("schema-six prospect payload requires canonical unique traits") {
            let prospect = Prospect(
                id: UUID(uuidString: "00000000-0000-4000-8000-00000000A001")!,
                firstName: "Trait",
                lastName: "Prospect",
                position: .quarterback,
                age: 18,
                originCityID: UUID(uuidString: "00000000-0000-4000-8000-00000000A002")!,
                attributes: Attributes(),
                potential: Rating(80),
                traits: [.restless, .ironman, .restless],
                priorities: [.proximity: Rating(70)]
            )
            expectEqual(prospect.traits, [.ironman, .restless])
            let encoded = try JSONEncoder.stable().encode(prospect)
            let object = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
            expect(object["traits"] != nil, "a persisted prospect omitted its mandatory traits")

            for (label, rawTraits) in [
                ("missing", Optional<[String]>.none),
                ("duplicate", ["ironman", "ironman"]),
                ("noncanonical", ["restless", "ironman"]),
            ] {
                var hostile = object
                hostile["traits"] = rawTraits
                if rawTraits == nil { hostile.removeValue(forKey: "traits") }
                let data = try JSONSerialization.data(withJSONObject: hostile)
                do {
                    _ = try JSONDecoder().decode(Prospect.self, from: data)
                    expect(false, "a \(label) prospect trait payload decoded")
                } catch {
                    expect(true)
                }
            }
        }
    }

    suite("Deterministic trait population") {
        test("the same seed repeats exact trait bytes on every generation path") {
            let seed: UInt64 = 84_000
            let world = LeagueGenerator.generate(seed: seed)
            let firstRoster = RosterPopulationGenerator.generate(
                seed: seed,
                season: 0,
                programmes: world.programmes,
                proTeams: world.proTeams
            )
            let secondRoster = RosterPopulationGenerator.generate(
                seed: seed,
                season: 0,
                programmes: world.programmes,
                proTeams: world.proTeams
            )
            let firstProspects = ProspectPopulationGenerator.generate(
                rootSeed: seed,
                season: 4,
                map: world.map
            )
            let secondProspects = ProspectPopulationGenerator.generate(
                rootSeed: seed,
                season: 4,
                map: world.map
            )
            let organisation = world.programmes[0]
            let firstWalkOn = RosterPopulationGenerator.walkOn(
                rootSeed: seed,
                season: 4,
                organisationID: organisation.id,
                position: .safety,
                ordinal: 77,
                prestige: organisation.prestige
            )
            let secondWalkOn = RosterPopulationGenerator.walkOn(
                rootSeed: seed,
                season: 4,
                organisationID: organisation.id,
                position: .safety,
                ordinal: 77,
                prestige: organisation.prestige
            )

            expectEqual(
                try JSONEncoder.stable().encode(firstRoster.players),
                try JSONEncoder.stable().encode(secondRoster.players)
            )
            expectEqual(
                try JSONEncoder.stable().encode(firstProspects),
                try JSONEncoder.stable().encode(secondProspects)
            )
            expectEqual(
                try JSONEncoder.stable().encode(firstWalkOn),
                try JSONEncoder.stable().encode(secondWalkOn)
            )
        }

        test("every generation path populates each active trait without emitting inactive ones") {
            let seed: UInt64 = 84_002
            let world = LeagueGenerator.generate(seed: seed)
            let population = RosterPopulationGenerator.generate(
                seed: seed,
                season: 0,
                programmes: world.programmes,
                proTeams: world.proTeams
            )
            let playersByID = Dictionary(uniqueKeysWithValues: population.players.map { ($0.id, $0) })
            let collegePlayers = population.programmeRosterIDs.values
                .flatMap { $0 }
                .compactMap { playersByID[$0] }
            let proPlayers = population.proRosterIDs.values
                .flatMap { $0 }
                .compactMap { playersByID[$0] }
            let prospects = ProspectPopulationGenerator.generate(
                rootSeed: seed,
                season: 2,
                map: world.map
            )
            let organisation = world.programmes[0]
            let walkOns = (0..<512).map { ordinal in
                RosterPopulationGenerator.walkOn(
                    rootSeed: seed,
                    season: 2,
                    organisationID: organisation.id,
                    position: Position.allCases[ordinal % Position.allCases.count],
                    ordinal: ordinal,
                    prestige: organisation.prestige
                )
            }
            let replacements = (0..<512).map { ordinal in
                RosterPopulationGenerator.replacement(
                    rootSeed: seed,
                    season: 2,
                    organisationID: organisation.id,
                    position: Position.allCases[ordinal % Position.allCases.count],
                    ordinal: ordinal,
                    prestige: organisation.prestige,
                    tier: .pro
                )
            }

            for (label, traitLists) in [
                ("initial college", collegePlayers.map(\.traits)),
                ("initial pro", proPlayers.map(\.traits)),
                ("annual prospect", prospects.map(\.traits)),
                ("walk-on", walkOns.map(\.traits)),
                ("replacement", replacements.map(\.traits)),
            ] {
                expect(traitLists.allSatisfy(isCanonicalTraits), "\(label) traits were noncanonical")
                let populated = Set(traitLists.flatMap { $0 })
                expect(populated.isSubset(of: activePopulationTraits),
                       "\(label) generation emitted an inactive trait: \(populated)")
                // Enumerated from the active set rather than naming one trait, so a trait promoted
                // here tomorrow is covered the day it is promoted rather than the day somebody
                // remembers to add a line — the coverage boundary `CLAUDE.md` forbids becoming the
                // quality boundary. This read `.contains(.restless)` while restless was the only
                // active trait, and ironman would have entered generation unmeasured.
                for trait in activePopulationTraits {
                    expect(traitLists.contains { $0.contains(trait) },
                           "\(label) generation produced no \(trait) evidence")
                }
            }
            expect(walkOns.indices.allSatisfy { walkOns[$0].traits == replacements[$0].traits },
                   "rating penalties changed the deterministic trait substream")
        }

        test("each active trait follows eight-percent direction and inactive ones stay unpopulated") {
            expectEqual(PeopleRules.traitPopulationProbability, 0.08)
            let seed: UInt64 = 84_003
            let world = LeagueGenerator.generate(seed: seed)
            let population = RosterPopulationGenerator.generate(
                seed: seed,
                season: 0,
                programmes: world.programmes,
                proTeams: world.proTeams
            )
            let prospects = ProspectPopulationGenerator.generate(
                rootSeed: seed,
                season: 1,
                map: world.map
            )
            let traitLists = population.players.map(\.traits) + prospects.map(\.traits)

            for trait in activePopulationTraits.sorted(by: { $0.rawValue < $1.rawValue }) {
                let rate = Double(traitLists.filter { $0.contains(trait) }.count)
                    / Double(traitLists.count)
                expectIn(rate, 0.065...0.095,
                         "\(trait) did not follow the 8% population direction")
            }
            for trait in futureSimulationTraits {
                expect(!traitLists.contains { $0.contains(trait) },
                       "inactive Future Simulation Contract trait \(trait) was populated")
            }
            expect(traitLists.allSatisfy { $0.count <= activePopulationTraits.count })
        }

        test("restless rate holds across many seeds and does not correlate with position") {
            // The single-seed check above is a spot check: one 15,000-plus-player world where the
            // rate happened to land inside the band. A generator bug that correlated restless with
            // position — the ordinal derivation reading something position-shaped instead of only
            // the player id — would not show up in an aggregate rate at all, only in the per-position
            // breakdown. Both are checked here, across a sweep rather than one seed.
            let seeds: [UInt64] = (0..<15).map { 84_100 + UInt64($0) }
            var countByPosition: [Position: (restless: Int, total: Int)] = [:]
            for seed in seeds {
                let world = LeagueGenerator.generate(seed: seed)
                let population = RosterPopulationGenerator.generate(
                    seed: seed,
                    season: 0,
                    programmes: world.programmes,
                    proTeams: world.proTeams
                )
                let prospects = ProspectPopulationGenerator.generate(
                    rootSeed: seed,
                    season: 1,
                    map: world.map
                )
                let drawn = population.players.map { ($0.position, $0.traits) }
                    + prospects.map { ($0.position, $0.traits) }
                let rate = Double(drawn.filter { $0.1.contains(.restless) }.count) / Double(drawn.count)
                expectIn(rate, 0.065...0.095, "seed \(seed): restless rate \(rate) left the 8% band")
                for (position, traits) in drawn {
                    var entry = countByPosition[position] ?? (restless: 0, total: 0)
                    entry.total += 1
                    if traits.contains(.restless) { entry.restless += 1 }
                    countByPosition[position] = entry
                }
            }
            for (position, counts) in countByPosition {
                let rate = Double(counts.restless) / Double(counts.total)
                expectIn(rate, 0.05...0.12,
                         "\(position.rawValue): restless rate \(rate) across \(counts.total) draws "
                             + "suggests the draw correlates with position rather than only the id")
            }
        }

        test("restless uses its fixed all-cases ordinal substream") {
            let seed: UInt64 = 84_005
            let world = LeagueGenerator.generate(seed: seed)
            let organisation = world.programmes[0]
            let restlessOrdinal = Trait.allCases.firstIndex(of: .restless)!

            for ordinal in 0..<512 {
                let player = RosterPopulationGenerator.replacement(
                    rootSeed: seed,
                    season: 3,
                    organisationID: organisation.id,
                    position: Position.allCases[ordinal % Position.allCases.count],
                    ordinal: ordinal,
                    prestige: organisation.prestige,
                    tier: .college
                )
                let personSeed = SeededRandom.seed(from: player.id)
                var traitRNG = SeededRandom(seed: SeededRandom.derive(
                    from: personSeed,
                    scope: .personnel,
                    ordinal: restlessOrdinal
                ))
                expectEqual(
                    player.has(.restless),
                    traitRNG.chance(PeopleRules.traitPopulationProbability),
                    "restless did not use its isolated trait ordinal for replacement \(ordinal)"
                )
            }
        }

        test("trait generation leaves the identity and value stream byte-for-byte stable") {
            let seed: UInt64 = 84_001
            let world = LeagueGenerator.generate(seed: seed)
            let population = RosterPopulationGenerator.generate(
                seed: seed,
                season: 0,
                programmes: world.programmes,
                proTeams: world.proTeams
            )
            let prospects = ProspectPopulationGenerator.generate(
                rootSeed: seed,
                season: 0,
                map: world.map
            )
            let replacement = RosterPopulationGenerator.replacement(
                rootSeed: seed,
                season: 3,
                organisationID: world.programmes[0].id,
                position: .quarterback,
                ordinal: 17,
                prestige: world.programmes[0].prestige,
                tier: .college
            )
            let initial = population.players[0]
            let prospect = prospects[0]

            expectEqual(initial.id.uuidString, "65AAA77C-F093-42EC-91CA-064775DA4536")
            expectEqual(initial.fullName, "Preston Corrcombe")
            expectEqual(initial.position, .quarterback)
            expectEqual(initial.age, 18)
            expectEqual(initial.potential, Rating(61))
            expectEqual(Attribute.allCases.map { initial.attributes[$0].value }, [
                59, 48, 46, 45, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40,
                40, 40, 49, 46, 47, 60, 56, 57, 40, 40, 40, 40, 40, 56, 62, 59, 43, 57,
            ])

            expectEqual(replacement.id.uuidString, "84ECCA2A-C6EA-45E2-AB7A-99C0B82291E1")
            expectEqual(replacement.fullName, "Tayick Jarrwick")
            expectEqual(replacement.position, .quarterback)
            expectEqual(replacement.age, 18)
            expectEqual(replacement.potential, Rating(70))
            expectEqual(Attribute.allCases.map { replacement.attributes[$0].value }, [
                46, 59, 42, 52, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40,
                40, 40, 59, 55, 57, 58, 58, 48, 40, 40, 40, 40, 40, 47, 42, 48, 57, 60,
            ])

            expectEqual(prospect.id.uuidString, "70552D28-F3C9-460F-86F5-3DB3E050F961")
            expectEqual(prospect.fullName, "Lemec Tarrworth")
            expectEqual(prospect.position, .quarterback)
            expectEqual(prospect.age, 19)
            expectEqual(prospect.originCityID.uuidString, "C4795271-5AC6-4182-BDA3-3F7551EAA186")
            // The value half of this golden moved +6 on 2026-08-20, when prospect generation
            // stopped carrying its own `42 + span * 28/59` and started calling the same
            // `RosterPopulationGenerator.baseRating` a programme's roster is generated on. The
            // identity half did not move at all — id, name, position, age, origin city and
            // priorities are all unchanged above — which is the split this test exists to police:
            // a trait draw must not perturb the identity stream, and it did not. The values moved
            // because the value scale was deliberately changed, not because the stream shifted.
            expectEqual(prospect.potential, Rating(79))
            expectEqual(Attribute.allCases.map { prospect.attributes[$0].value }, [
                63, 64, 71, 70, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40,
                40, 40, 70, 71, 76, 76, 63, 76, 40, 40, 40, 40, 40, 74, 71, 67, 70, 70,
            ])
            expectEqual(
                RecruitingPitch.allCases.map { prospect.priorities[$0]!.value },
                [73, 42, 89, 91, 49, 79, 79, 58]
            )
        }
    }

    suite("Trait signing continuity") {
        test("signing copies the prospect trait payload exactly into the player") {
            var state = GameState.bootstrap(seed: 84_004)
            let programmeID = state.programmes.ids[0]
            let rosterCounts = Dictionary(grouping: state.programmes[programmeID]!.rosterIDs.compactMap {
                state.players[$0]?.position
            }, by: { $0 }).mapValues(\.count)
            let prospect = state.prospects.values.first { candidate in
                !candidate.traits.isEmpty
                    && (rosterCounts[candidate.position] ?? 0)
                        > (SharedRules.minimumPlayableRosterByPosition[candidate.position] ?? 0)
            }!
            let prospectID = prospect.id

            for action in [
                RecruitingAction.addToBoard,
                .contact(points: 60),
                .scheduleVisit,
                .offerScholarship,
                .setNILAllocation(amount: 500),
            ] {
                let transition = try CollegeRecruitingSystem.apply(
                    RecruitingActionRequest(
                        programmeID: programmeID,
                        prospectID: prospectID,
                        action: action
                    ),
                    in: state
                )
                state.college = transition.college
                state.scouting = transition.scouting
            }
            state.calendar = CalendarState(
                season: state.calendar.season,
                week: CollegeRules.minimumCommitmentWeek
            )
            state.league.week = state.calendar.week
            let market = CollegeRecruitingMarketSystem.process(at: state.calendar, in: state)
            state.college = market.college
            expectEqual(
                state.college.prospectRecruitment[prospectID]?.programmeID,
                programmeID
            )

            let departingID = state.programmes[programmeID]!.rosterIDs.first {
                state.players[$0]?.position == prospect.position
            }!
            state.programmes.update(programmeID) {
                $0.rosterIDs.removeAll { $0 == departingID }
                $0.scholarshipCount -= 1
            }
            state.college.reconcileScholarships(with: state.programmes)

            let signing = try CollegeSigningSystem.signCommitted(in: state)
            expectEqual(signing.signings.map(\.prospectID), [prospectID])
            expectEqual(signing.players[prospectID]?.traits, prospect.traits)
            expect(!prospect.traits.isEmpty, "the continuity fixture carried no evidence")
        }
    }
}

private func isCanonicalTraits(_ traits: [Trait]) -> Bool {
    traits == Trait.allCases.filter(traits.contains)
}

private let activePopulationTraits: Set<Trait> = [.ironman, .restless, .volatile]
private let futureSimulationTraits = Trait.allCases.filter { !activePopulationTraits.contains($0) }
