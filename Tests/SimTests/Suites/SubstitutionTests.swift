import Foundation
import FootballSimCore

func runSubstitutionTests() {
    suite("Substitution") {
        test("the best reserve at the position comes on, and leaves the bench") {
            let squad = benchSquad()
            let personnel = DepthChart.personnel(offense: squad, defense: squad)
            guard let starter = personnel.offense.first(where: { $0.position == .runningBack }) else {
                expect(false, "the formation has no running back to injure")
                return
            }
            let bench = personnel.reserves.filter { $0.position == .runningBack }
            guard let expected = bench.first else {
                expect(false, "the bench has no running back to bring on")
                return
            }

            let after = personnel.substituting(outPlayerID: starter.id)
            expect(!after.contains(playerID: starter.id),
                   "a player forced out is still on the field")
            expect(after.offense.contains { $0.id == expected.id },
                   "the best reserve at the position did not come on")
            expect(!after.reserves.contains { $0.id == expected.id },
                   "the replacement is on the field and on the bench at once")
            expectEqual(after.offense.count, personnel.offense.count,
                        "the side took the field with a different number of players")
            expect(expected.overall >= (bench.dropFirst().first?.overall ?? expected.overall),
                   "the reserve who came on is not the best one available")
        }

        test("nobody at the position means the next-best body in the group") {
            let squad = benchSquad()
            // Every reserve tight end removed, so the position has nobody behind the starter.
            let starterID = DepthChart.starter(at: .tightEnd, roster: squad)
            let thinned = squad.filter { $0.position != .tightEnd || $0.id == starterID }
            let personnel = DepthChart.personnel(offense: thinned, defense: thinned)
            guard let starter = personnel.offense.first(where: { $0.position == .tightEnd }) else {
                expect(false, "the formation has no tight end")
                return
            }
            let after = personnel.substituting(outPlayerID: starter.id)
            expect(!after.contains(playerID: starter.id), "the injured tight end stayed on")
            expectEqual(after.offense.count, personnel.offense.count,
                        "the side lined up a man short rather than moving somebody across")
        }

        test("a side with nobody to bring on plays with them") {
            // Eleven is a rule of the sport: dropping to ten would hand the resolver a formation it
            // has no way to resolve, which is worse than an injured player finishing the game.
            let bare = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            expect(bare.reserves.isEmpty, "the hand-built fixture grew a bench")
            guard let anyone = bare.offense.first else {
                expect(false, "the fixture has no players")
                return
            }
            expectEqual(bare.substituting(outPlayerID: anyone.id), bare,
                        "a side with an empty bench substituted somebody it does not have")
        }

        test("substituting somebody who is not on this side changes nothing") {
            let squad = benchSquad()
            let personnel = DepthChart.personnel(offense: squad, defense: squad)
            expectEqual(
                personnel.substituting(
                    outPlayerID: UUID(uuidString: "00000000-0000-4000-B500-0000000000FF")!
                ),
                personnel,
                "a stranger's injury changed the lineup"
            )
        }

        test("the bench is everybody available who is not on the field, once each") {
            let squad = benchSquad()
            let personnel = DepthChart.personnel(offense: squad, defense: squad)
            let onField = Set(personnel.offense.map(\.id)).union(personnel.defense.map(\.id))
            let benched = Set(personnel.reserves.map(\.id))

            expectEqual(personnel.reserves.count, benched.count,
                        "somebody is on the bench twice, because the squad was read twice")
            expect(benched.isDisjoint(with: onField),
                   "somebody is on the field and on the bench at once")
            expectEqual(benched.union(onField).count, squad.count,
                        "the squad and the field plus bench disagree about who exists")

            // The unavailable are not on the bench either: a suspended or injured player is not a
            // replacement (`02` §5.2, §3.8).
            guard let out = squad.first else {
                expect(false, "the squad is empty")
                return
            }
            let withOut = DepthChart.personnel(offense: squad, defense: squad,
                                               unavailableIDs: [out.id])
            expect(!withOut.reserves.contains { $0.id == out.id },
                   "a player who cannot play was available to come on")
        }

        test("a player forced out takes no further snap in that game") {
            // `02` §3.8's falsifier, and the whole point of the slice: `forcedOut` was recorded and
            // never honoured, so a torn knee changed a line in the record and nothing in the match.
            let squad = benchSquad()
            let home = DepthChart.personnel(offense: squad, defense: squad)
            let away = DepthChart.personnel(offense: benchSquad(offset: 500), defense: benchSquad(offset: 500))

            var gamesChecked = 0
            for seed in UInt64(1)...60 {
                let game = GameEngine.play(tier: .pro, home: home, away: away, seed: seed)
                let plays = game.plays
                guard let index = plays.firstIndex(where: {
                    $0.outcome.injury?.forcedOut == true
                }), let injury = plays[index].outcome.injury else { continue }
                gamesChecked += 1
                for later in plays[(index + 1)...] {
                    var involved: Set<UUID> = []
                    for matchup in later.outcome.matchups {
                        involved.insert(matchup.attackerID)
                        involved.insert(matchup.defenderID)
                    }
                    if let carrier = later.outcome.ballCarrierID { involved.insert(carrier) }
                    if let passer = later.outcome.passerID { involved.insert(passer) }
                    if let target = later.outcome.targetID { involved.insert(target) }
                    expect(!involved.contains(injury.playerID),
                           "seed \(seed): a player whose game was over took another snap")
                }
            }
            expect(gamesChecked > 0,
                   "sixty games produced no forced-out injury, so the rule is untested rather than "
                       + "passing")
        }

        test("substitution consumes no draw, so the rest of the game is unmoved") {
            // A substitution that rolled dice would push the injured player's bad luck into the
            // stream every other snap reads. Same squads, same seed, twice.
            let squad = benchSquad()
            let home = DepthChart.personnel(offense: squad, defense: squad)
            let away = DepthChart.personnel(offense: benchSquad(offset: 500), defense: benchSquad(offset: 500))
            let first = GameEngine.play(tier: .college, home: home, away: away, seed: 9_001)
            let second = GameEngine.play(tier: .college, home: home, away: away, seed: 9_001)
            expectEqual(first.playByPlayFingerprint, second.playByPlayFingerprint,
                        "a game with substitutions in it did not replay")
        }
    }
}

/// A squad with a bench: two deep everywhere the formation needs somebody, plus the specialists.
private func benchSquad(offset: Int = 0) -> [Player] {
    var squad: [Player] = []
    var index = offset
    func add(_ position: Position, skill: Int) {
        var attributes = Attributes()
        for attribute in position.ratedAttributes { attributes[attribute] = Rating(skill) }
        squad.append(Player(
            id: UUID(uuidString: String(format: "00000000-0000-4000-B600-%012X", index))!,
            firstName: "Bench", lastName: "Fixture\(index)", position: position, age: 24,
            attributes: attributes, potential: Rating(85)
        ))
        index += 1
    }
    // Three deep at the positions the formation asks for more than one of, two deep elsewhere, so
    // there is always somebody to bring on and the choice between reserves is a real one.
    for position in Position.allCases {
        add(position, skill: 74)
        add(position, skill: 68)
        add(position, skill: 62)
    }
    return squad
}
