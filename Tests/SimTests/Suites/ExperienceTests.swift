import Foundation
import FootballSimCore

/// The coaching XP economy. Goals settle every week, so a goal that stays complete must not keep
/// paying, and the events the design defines must actually fire.
/// Experience actually banked, levels included — `award` drains `experience` on every level-up,
/// so reading that field alone under-reports the moment a threshold is crossed.
private func totalExperience(_ coach: CoachProfile) -> Int {
    var total = coach.experience
    for level in 1..<max(1, coach.level) {
        total += Int((100.0 * pow(1.15, Double(level - 1))).rounded())
    }
    return total
}

func runExperienceTests() {
    suite("Experience") {

        test("a completed goal pays exactly once, however often goals settle") {
            var league = LeagueFactory.makeDefaultLeague(seed: 8_800, userTeamIndex: 0, coach: .stub())
            // A goal that is already satisfied the moment it is settled.
            var goals = [
                CoachEngine.SeasonGoal(
                    description: "Win at least none",
                    target: 0,
                    experienceReward: 120,
                    isEndOfSeason: false,
                    kind: .wins
                )
            ]

            let before = totalExperience(league.coach)
            let firstPass = CoachEngine.settleGoals(&goals, league: &league)
            let afterFirst = totalExperience(league.coach)

            expect(!firstPass.isEmpty, "a satisfied goal must complete on the first settle")
            expect(afterFirst > before, "completing a goal must pay experience")

            // Ten more weeks pass. Nothing about the goal changes.
            for _ in 0..<10 {
                let repeatPass = CoachEngine.settleGoals(&goals, league: &league)
                expect(
                    repeatPass.isEmpty,
                    "an already-paid goal must not report as newly completed again"
                )
            }
            let afterTen = totalExperience(league.coach)
            expectEqual(afterTen, afterFirst, "ten further settles must not pay again")
        }

        test("a goal that is paid stays paid across a save and load") {
            var league = LeagueFactory.makeDefaultLeague(seed: 8_801, userTeamIndex: 0, coach: .stub())
            var goals = [
                CoachEngine.SeasonGoal(
                    description: "Win at least none",
                    target: 0,
                    experienceReward: 120,
                    isEndOfSeason: false,
                    kind: .wins
                )
            ]
            _ = CoachEngine.settleGoals(&goals, league: &league)
            league.seasonGoals = goals

            let data = try JSONEncoder.stable().encode(league)
            var reloaded = try JSONDecoder.stable().decode(League.self, from: data)
            var reloadedGoals = reloaded.seasonGoals
            let experienceBefore = totalExperience(reloaded.coach)

            let pass = CoachEngine.settleGoals(&reloadedGoals, league: &reloaded)
            expect(pass.isEmpty, "a reloaded franchise must not re-pay its settled goals")
            expectEqual(
                totalExperience(reloaded.coach),
                experienceBefore,
                "reloading must not mint experience"
            )
        }

        // A save written before the flag existed has no idea whether it already paid. It must
        // still load, and it must not pay again on the next settle.
        test("a goal decoded without the paid flag is treated as already settled") {
            let json = """
            {"id":"\(UUID().uuidString)","description":"Legacy goal","target":1,"progress":1,
             "experienceReward":90,"isEndOfSeason":false,"kind":"capSpace"}
            """
            let goal = try JSONDecoder.stable().decode(
                CoachEngine.SeasonGoal.self, from: Data(json.utf8)
            )
            expect(goal.isComplete, "the legacy goal is complete")
            expect(
                goal.hasPaidOut,
                "a complete goal from an older save must be assumed paid, or it pays twice"
            )
        }

        test("the designed experience events all carry their documented value") {
            expectEqual(CoachEngine.ExperienceEvent.win.points, 40, "a win")
            expectEqual(CoachEngine.ExperienceEvent.divisionWin.points, 50, "a division win")
            expectEqual(CoachEngine.ExperienceEvent.playoffWin.points, 80, "a playoff win")
            expectEqual(CoachEngine.ExperienceEvent.championship.points, 200, "a title")
            expectEqual(CoachEngine.ExperienceEvent.draftSteal.points, 50, "a draft steal")
        }

        test("winning a game pays the coach") {
            let cases: [(divisional: Bool, playoff: Bool, points: Int, label: String)] = [
                (false, false, 40, "a plain win"),
                (true, false, 50, "a division win"),
                (false, true, 80, "a playoff win"),
            ]
            for scenario in cases {
                var league = LeagueFactory.makeDefaultLeague(
                    seed: 8_802, userTeamIndex: 0, coach: .stub()
                )
                let before = totalExperience(league.coach)
                CoachEngine.awardForResult(
                    win: true,
                    isDivisional: scenario.divisional,
                    isPlayoff: scenario.playoff,
                    in: &league
                )
                expectEqual(
                    totalExperience(league.coach) - before,
                    scenario.points,
                    "\(scenario.label) is worth \(scenario.points)"
                )
            }
        }

        // The scouting economy is only reachable if there is a class to scout before the draft.
        test("a season opens with a draft class on the board") {
            var league = LeagueFactory.makeDefaultLeague(seed: 9_100, userTeamIndex: 0, coach: .stub())
            expect(league.draftClass.isEmpty, "no class before kickoff")
            SeasonEngine.startSeason(&league)
            expect(
                !league.draftClass.isEmpty,
                "scouting needs a board from week one, not from the draft room"
            )
            expectEqual(
                league.draftClass.count,
                LeagueRules.draftPickCount + LeagueRules.undraftedPoolSize,
                "a full class is on the board"
            )
        }

        test("scouting the in-season board narrows a prospect and spends points") {
            var league = LeagueFactory.makeDefaultLeague(seed: 9_101, userTeamIndex: 0, coach: .stub())
            SeasonEngine.startSeason(&league)
            var prospects = league.draftClass
            guard let target = prospects.first else {
                expect(false, "a class must exist to scout"); return
            }
            let rangeBefore = target.scoutedHigh - target.scoutedLow
            var points = CoachEngine.scoutingPoints(for: league.coach)
            expect(points > 0, "a coach starts the season with scouting points")

            ScoutingEngine.scout(
                prospectID: target.id,
                action: .narrow,
                in: &prospects,
                pointsRemaining: &points,
                coach: league.coach
            )

            let after = prospects.first { $0.id == target.id }!
            let rangeAfter = after.scoutedHigh - after.scoutedLow
            expect(
                rangeAfter <= rangeBefore,
                "scouting must not widen the range: \(rangeBefore) -> \(rangeAfter)"
            )
            expect(
                points < CoachEngine.scoutingPoints(for: league.coach),
                "scouting must cost something"
            )
        }

        // The point of scouting is that what you learned survives to draft day.
        test("the draft consumes the board the coach scouted, not a fresh one") {
            var league = LeagueFactory.makeDefaultLeague(seed: 9_102, userTeamIndex: 0, coach: .stub())
            SeasonEngine.startSeason(&league)
            var prospects = league.draftClass
            for index in prospects.indices { prospects[index].fullyScouted = true }

            let picks = TradeEngine.makePicks(for: league)
            DraftEngine.runDraft(&league, prospects: &prospects, picks: picks)

            // Whoever is left undrafted must still carry what the coach paid to learn. A fresh
            // class would have arrived unscouted.
            expect(
                prospects.allSatisfy(\.fullyScouted),
                "the draft replaced the scouted board with a new one"
            )
        }

        test("losing pays nothing") {
            var league = LeagueFactory.makeDefaultLeague(seed: 8_803, userTeamIndex: 0, coach: .stub())
            let before = totalExperience(league.coach)
            CoachEngine.awardForResult(win: false, isDivisional: true, isPlayoff: true, in: &league)
            expectEqual(
                totalExperience(league.coach),
                before,
                "a defeat earns nothing"
            )
        }
    }
}
