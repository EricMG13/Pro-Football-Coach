import Foundation
import FootballSimCore

func runBowlTests() {
    suite("The postseason tail") {
        test("the ranked teams below the bracket get a game") {
            // 01-RESEARCH.md section 6.5 adopted this and canon dropped it: 126 of 134 programmes
            // ended every season with nothing, against the research's own finding that a wide tail
            // of small prizes is what keeps the other 129 playing.
            let ranking = (0..<134).map { index in
                UUID(uuidString: String(format: "00000000-0000-4000-F000-%012X", index))!
            }
            let pairs = PostseasonSystem.adjacentPairs(
                Array(ranking.dropFirst(CollegeRules.bracketTeams).prefix(CollegeRules.bowlTeams))
            )
            expectEqual(pairs.count, CollegeRules.bowlTeams / 2,
                        "the tail produced \(pairs.count) games rather than twenty")
            let participants = pairs.flatMap { [$0.0, $0.1] }
            expectEqual(Set(participants).count, participants.count,
                        "a programme was given two bowls")
            expect(Set(participants).isDisjoint(with: Set(ranking.prefix(CollegeRules.bracketTeams))),
                   "a bracket team was also given a bowl")
            // Adjacent rather than high-low: a prize whose pairing hands the best of the tail an
            // easy win is not a reward, it is a bye with a trophy.
            expectEqual(pairs.first?.0, ranking[CollegeRules.bracketTeams])
            expectEqual(pairs.first?.1, ranking[CollegeRules.bracketTeams + 1])
        }

        test("an odd tail leaves nobody half-paired") {
            let ranking = (0..<5).map { index in
                UUID(uuidString: String(format: "00000000-0000-4000-F100-%012X", index))!
            }
            let pairs = PostseasonSystem.adjacentPairs(ranking)
            expectEqual(pairs.count, 2, "an odd list did not drop its last entry")
            expect(!pairs.contains { $0.0 == $0.1 }, "a programme was paired with itself")
        }

        test("a bowl does not advance a bracket") {
            expect(!CompetitionStage.bowl.advancesBracket,
                   "a bowl advances a bracket, which makes it a second bracket wearing a new name")
            expect(CompetitionStage.quarterfinal.advancesBracket)
            expect(CompetitionStage.semifinal.advancesBracket)
            expect(!CompetitionStage.championship.advancesBracket)
        }

        test("the bowl case sits last, so no existing bracket game is re-seeded") {
            // PostseasonSystem derives a stage's seed from its index in allCases. Inserting a case
            // anywhere earlier would silently change every bracket game that already exists.
            expectEqual(CompetitionStage.allCases.last, .bowl,
                        "the bowl case moved, which re-seeds every bracket game in every save")
            expectEqual(CompetitionStage.allCases.firstIndex(of: .quarterfinal), 2)
            expectEqual(CompetitionStage.allCases.firstIndex(of: .championship), 4)
        }
    }
}
