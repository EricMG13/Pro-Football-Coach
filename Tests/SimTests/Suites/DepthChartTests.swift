import Foundation
import FootballSimCore

func runDepthChartTests() {
    suite("Depth chart") {
        test("the best available player starts") {
            let state = GameState.bootstrap(seed: 87_001)
            let programmeID = state.programmes.ids[0]
            let roster = state.programmes[programmeID]!.rosterIDs.compactMap { state.players[$0] }
            let chart = DepthChart.derive(roster: roster)

            expect(!chart.isEmpty, "a 105-player roster produced no depth chart")
            for (position, order) in chart {
                let players = order.compactMap { id in roster.first { $0.id == id } }
                expectEqual(players.count, order.count, "the chart named somebody off the roster")
                for index in 1..<max(1, players.count) {
                    expect(players[index - 1].overall >= players[index].overall,
                           "\(position.rawValue) is not ordered by rating")
                }
            }
        }

        test("an unavailable player falls to the bottom rather than off the chart") {
            // A chart that dropped the injured could not show a coach who is missing, and 02
            // section 3.8's forcedOut would have nowhere to point.
            let state = GameState.bootstrap(seed: 87_002)
            let programmeID = state.programmes.ids[0]
            let roster = state.programmes[programmeID]!.rosterIDs.compactMap { state.players[$0] }
            let quarterbacks = roster.filter { $0.position == .quarterback }
            guard let starter = DepthChart.starter(at: .quarterback, roster: roster) else {
                expect(false, "no quarterback started")
                return
            }
            expect(quarterbacks.count > 1, "the fixture has only one quarterback")

            let withoutStarter = DepthChart.derive(roster: roster, unavailableIDs: [starter])
            expect(withoutStarter[.quarterback]?.first != starter,
                   "an unavailable quarterback still started")
            expect(withoutStarter[.quarterback]?.contains(starter) == true,
                   "an unavailable quarterback vanished from the chart")
            expectEqual(withoutStarter[.quarterback]?.count, chartCount(roster, .quarterback),
                        "the chart lost a player when one became unavailable")
        }

        test("a lineup is eleven a side, and nobody plays twice") {
            let state = GameState.bootstrap(seed: 87_003)
            let programmeID = state.programmes.ids[0]
            let opponentID = state.programmes.ids[1]
            let home = state.programmes[programmeID]!.rosterIDs.compactMap { state.players[$0] }
            let away = state.programmes[opponentID]!.rosterIDs.compactMap { state.players[$0] }

            let personnel = DepthChart.personnel(offense: home, defense: away)
            expectEqual(personnel.defense.count, DepthChart.defensiveTemplate.count,
                        "the defence did not field its formation")
            expectEqual(personnel.offense.count, DepthChart.offensiveTemplate.count,
                        "the offence did not field its formation")
            expectEqual(Set(personnel.offense.map(\.id)).count, personnel.offense.count,
                        "a player lined up twice on offence")
            expectEqual(Set(personnel.defense.map(\.id)).count, personnel.defense.count,
                        "a player lined up twice on defence")
            expect(personnel.offensive(group: .quarterbacks).count >= 1,
                   "the offence took the field without a quarterback")
            expect(personnel.offensive(group: .runningBacks).count >= 2,
                   "the eligible personnel pool omitted the reserve back")
            expect(personnel.offensive(group: .specialists).count >= 1,
                   "the offence took the field with nobody who can kick")
        }

        test("every professional team fields a complete lineup from its own roster") {
            // Every prior test in this suite is college-tier (`state.programmes`); nothing had ever
            // resolved a personnel lineup against a real professional roster. Pass 4 of the
            // 2026-08-20 rules-compliance sweep raised `SharedRules.minimumPlayableRosterByPosition`
            // so the floor covers what `DepthChart`'s formation fields at every position -- this is
            // that fix's own falsifier, run against the roster shape the fix was written for.
            //
            // Enumerated over every professional team by construction, not one or two by index:
            // `CLAUDE.md`'s "coverage boundary is not the quality boundary" rule is the reason a
            // spot-checked version of this test would have missed exactly the gap pass 4 found, the
            // day a future formation or floor change reintroduces it at a team a spot check skips.
            let state = GameState.bootstrap(seed: 87_006)
            for teamID in state.proTeams.ids.sorted(by: { $0.uuidString < $1.uuidString }) {
                guard let team = state.proTeams[teamID] else { continue }
                let roster = team.rosterIDs.compactMap { state.players[$0] }
                let personnel = DepthChart.personnel(offense: roster, defense: roster)
                expectEqual(personnel.offense.count, DepthChart.offensiveTemplate.count,
                            "\(teamID) could not field a complete offence")
                expectEqual(personnel.defense.count, DepthChart.defensiveTemplate.count,
                            "\(teamID) could not field a complete defence")
                expectEqual(Set(personnel.offense.map(\.id)).count, personnel.offense.count,
                            "\(teamID) lined a player up twice on offence")
                expectEqual(Set(personnel.defense.map(\.id)).count, personnel.defense.count,
                            "\(teamID) lined a player up twice on defence")
            }
        }

        test("a roster hole still fields a full unit") {
            // Eleven players is a rule of the sport. A formation that shipped ten because a roster
            // had no third receiver would change the game the resolver plays.
            var attributes = Attributes()
            for attribute in Position.linebacker.ratedAttributes { attributes[attribute] = Rating(70) }
            let squad = (0..<11).map { index in
                Player(
                    id: UUID(uuidString: String(format: "00000000-0000-4000-E000-%012X", index))!,
                    firstName: "H", lastName: "\(index)", position: .linebacker, age: 24,
                    attributes: attributes, potential: Rating(70)
                )
            }
            let personnel = DepthChart.personnel(offense: squad, defense: squad)
            expectEqual(personnel.defense.count, DepthChart.defensiveTemplate.count,
                        "an all-linebacker squad could not field a defence")
            expectEqual(Set(personnel.defense.map(\.id)).count, personnel.defense.count,
                        "the fallback lined a player up twice")
        }

        test("the same roster derives the same chart every time") {
            let state = GameState.bootstrap(seed: 87_004)
            let roster = state.programmes[state.programmes.ids[0]]!.rosterIDs
                .compactMap { state.players[$0] }
            expectEqual(DepthChart.derive(roster: roster), DepthChart.derive(roster: roster),
                        "the chart is not a function of the roster")
            expectEqual(DepthChart.derive(roster: roster.reversed()),
                        DepthChart.derive(roster: roster),
                        "the chart depends on the order the roster arrived in")
        }

        test("personnel overrides persist and fall back when a selected player is unavailable") {
            let state = GameState.bootstrap(seed: 87_005)
            let programmeID = state.programmes.ids[0]
            let roster = state.programmes[programmeID]!.rosterIDs.compactMap { state.players[$0] }
            let quarterbacks = roster.filter { $0.position == .quarterback }
            guard quarterbacks.count > 1 else {
                expect(false, "the fixture has only one quarterback")
                return
            }
            let plan = PersonnelPlan(
                organisationID: programmeID,
                calendar: state.calendar,
                overrides: [DepthChartOverride(
                    position: .quarterback,
                    playerIDs: quarterbacks.map(\.id).reversed()
                )]
            )
            let selected = plan.resolve(roster: roster)
            expectEqual(selected[.quarterback]?.first, quarterbacks.last?.id)
            let unavailable = Set([quarterbacks.last!.id])
            let fallback = plan.resolve(roster: roster, unavailableIDs: unavailable)
            expectEqual(fallback[.quarterback]?.first, quarterbacks.dropLast().last?.id)
            expectEqual(
                try JSONDecoder.stable().decode(
                    PersonnelPlan.self,
                    from: JSONEncoder.stable().encode(plan)
                ),
                plan
            )
            var corrupted = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(DepthChartOverride(
                    position: .quarterback,
                    playerIDs: [quarterbacks[0].id]
                ))
            ) as! [String: Any]
            corrupted["playerIDs"] = [quarterbacks[0].id.uuidString, quarterbacks[0].id.uuidString]
            do {
                _ = try JSONDecoder().decode(
                    DepthChartOverride.self,
                    from: JSONSerialization.data(withJSONObject: corrupted)
                )
                expect(false, "duplicate personnel IDs decoded")
            } catch {
                expect(true)
            }
        }
    }
}

private func chartCount(_ roster: [Player], _ position: Position) -> Int {
    roster.filter { $0.position == position }.count
}
