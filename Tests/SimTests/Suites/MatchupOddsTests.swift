import Foundation
import FootballSimCore

func runMatchupOddsTests() {
    suite("MatchupOdds") {
        let league = LeagueFactory.makeDefaultLeague(seed: 3_301, userTeamIndex: 0, coach: .stub())
        let teams = league.teams.sorted { $0.overallRating > $1.overallRating }
        let best = teams.first!
        let worst = teams.last!

        test("home field is worth something") {
            let neutral = MatchupOdds.edge(home: best, away: best)
            expect(neutral > 0, "a team hosting itself must still hold home field, got \(neutral)")
        }

        test("the better team is favoured, and the edge flips with the venue") {
            let hosting = MatchupOdds.edge(home: best, away: worst)
            let visiting = MatchupOdds.edge(home: worst, away: best)
            expect(hosting > 0, "the best team at home must be favoured")
            expect(visiting < 0, "the worst team at home must still be the underdog")
            expect(hosting > -visiting, "home field must favour whoever is hosting")
        }

        test("win probability stays inside its bounds and tracks the edge") {
            for home in teams {
                for away in [best, worst] {
                    let probability = MatchupOdds.homeWinProbability(home: home, away: away)
                    expectIn(probability, 0.0...1.0, "\(home.abbreviation) v \(away.abbreviation)")
                }
            }
            let strong = MatchupOdds.homeWinProbability(home: best, away: worst)
            let weak = MatchupOdds.homeWinProbability(home: worst, away: best)
            expect(strong > 0.5, "the best team at home must be over even money, got \(strong)")
            expect(weak < 0.5, "the worst team at home must be under, got \(weak)")
            expect(strong > weak, "probability must track the edge")
        }

        // The display must agree with the engine it describes. GameSimulatorTests calibrates the
        // simulator's home win rate to 0.50–0.60; two identical teams are the pure home-field
        // case, so the model has to land in the same band or the odds are lying about the game.
        test("identical teams land inside the simulator's calibrated home win rate") {
            let probability = MatchupOdds.homeWinProbability(home: best, away: best)
            expectIn(probability, 0.50...0.60, "identical sides, home field only")
        }

        test("a large rating gap stays short of certainty") {
            let probability = MatchupOdds.homeWinProbability(home: best, away: worst)
            expect(
                probability < 0.80,
                "a \(String(format: "%.1f", best.overallRating - worst.overallRating))-point gap "
                    + "should not read as a lock, got \(String(format: "%.2f", probability))"
            )
        }

        test("the spread agrees with the edge on who is favoured") {
            for home in [best, worst] {
                for away in [best, worst] {
                    let edge = MatchupOdds.edge(home: home, away: away)
                    let spread = MatchupOdds.spread(home: home, away: away)
                    expect(
                        (edge >= 0) == (spread >= 0),
                        "edge \(edge) and spread \(spread) disagree on the favourite"
                    )
                }
            }
        }

        test("the summary names the user's side and never leaves a placeholder") {
            let sentence = MatchupOdds.summary(home: best, away: worst, userTeamID: best.id)
            expect(sentence.hasSuffix("."), "a sentence ends in a full stop: \(sentence)")
            expect(sentence.count > 20, "too short to be a sentence: \(sentence)")
            expect(!sentence.contains("Optional"), "a value leaked into the copy: \(sentence)")

            // Whoever is reading, the sentence has to be about them when they are playing.
            let asFavourite = MatchupOdds.summary(home: best, away: worst, userTeamID: best.id)
            expect(asFavourite.contains("You"), "the user's own game must address them: \(asFavourite)")
            let asUnderdog = MatchupOdds.summary(home: worst, away: best, userTeamID: worst.id)
            expect(
                asUnderdog.contains(best.name) || asUnderdog.contains("You"),
                "the underdog's sentence must name the opponent: \(asUnderdog)"
            )

            // A game the user is not in is described neutrally, never in second person.
            let others = teams.filter { $0.id != best.id && $0.id != worst.id }
            if let a = others.first, let b = others.last, a.id != b.id {
                let neutral = MatchupOdds.summary(home: a, away: b, userTeamID: best.id)
                expect(!neutral.contains("You"), "a game you are not in must stay third person: \(neutral)")
            }
        }
    }
}
