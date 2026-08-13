import Foundation
import FootballSimCore

func runDraftPickTests() {
    let clubs = (0..<32).map { index in
        UUID(uuidString: String(format: "00000000-0000-4000-B100-%012X", index))!
    }

    suite("Draft picks") {
        test("a pick is a thing somebody owns") {
            // draftOrder was a flat list of team identities, so a pick was a position in a list
            // rather than an asset — which made trading one, trading a future one, and knowing whose
            // pick a slot originally was all impossible at once.
            let picks = DraftPickBook.picks(season: 3, order: clubs, rounds: ProRules.draftRounds)
            expectEqual(picks.count, ProRules.draftPickCount,
                        "a seven-round draft of thirty-two clubs produced \(picks.count) picks")
            expectEqual(Set(picks.map(\.id)).count, picks.count, "two picks share an identity")
            expect(picks.allSatisfy { $0.ownerID == $0.originalTeamID },
                   "a freshly built book already has a traded pick in it")
            expect(picks.allSatisfy { !$0.isTraded }, "a pick nobody traded reads as traded")
            expectEqual(DraftPickBook.held(by: clubs[0], in: picks).count, ProRules.draftRounds,
                        "a club does not hold one pick per round")
        }

        test("identity comes from the slot, so the same world describes the same picks") {
            let first = DraftPickBook.picks(season: 3, order: clubs, rounds: 2)
            let second = DraftPickBook.picks(season: 3, order: clubs, rounds: 2)
            expectEqual(first.map(\.id), second.map(\.id),
                        "the same draft described its picks differently twice")
            let laterSeason = DraftPickBook.picks(season: 4, order: clubs, rounds: 2)
            expect(Set(first.map(\.id)).isDisjoint(with: Set(laterSeason.map(\.id))),
                   "two seasons share pick identities")
        }

        test("trading a pick moves who is on the clock") {
            var picks = DraftPickBook.picks(season: 3, order: clubs, rounds: ProRules.draftRounds)
            expectEqual(DraftPickBook.owner(ofPick: 0, in: picks), clubs[0])
            guard let traded = DraftPickBook.transfer(pickID: picks[0].id, to: clubs[5], in: picks)
            else {
                expect(false, "a legal trade was refused")
                return
            }
            picks = traded
            expectEqual(DraftPickBook.owner(ofPick: 0, in: picks), clubs[5],
                        "the pick moved and the clock did not")
            expect(picks[0].isTraded, "a traded pick does not know it was traded")
            expectEqual(picks[0].originalTeamID, clubs[0],
                        "a traded pick forgot whose it was, so nothing can call it their first")
            expectEqual(DraftPickBook.held(by: clubs[5], in: picks).count,
                        ProRules.draftRounds + 1,
                        "the acquiring club does not hold the extra pick")
        }

        test("a trade that would do nothing is refused rather than silently ignored") {
            let picks = DraftPickBook.picks(season: 3, order: clubs, rounds: 1)
            expect(DraftPickBook.transfer(pickID: picks[0].id, to: clubs[0], in: picks) == nil,
                   "a pick was traded to the club that already held it")
            expect(DraftPickBook.transfer(pickID: UUID(), to: clubs[1], in: picks) == nil,
                   "a pick that is not in the book was traded")
        }

        test("a future pick is describable before its draft exists") {
            // The reason identity is derived from the slot: you can trade next year's second-rounder
            // without next year's draft having been built.
            let future = DraftPick(season: 9, round: 2, originalTeamID: clubs[7])
            let built = DraftPickBook.picks(season: 9, order: clubs, rounds: 3)
            expect(built.contains { $0.id == future.id },
                   "a pick described in advance is not the pick the draft later built")
        }

        test("a traded pick changes who is on the clock") {
            // The tail slice 25 left open: ownership existed and the draft ignored it, reading
            // `draftOrder` directly, so trading a pick changed nothing about who picked.
            var state = GameState.bootstrap(seed: 60_130)
            do {
                state = try ProMarketSystem.openOffseason(in: state)
                state = try ProMarketSystem.beginDraft(in: state)
            } catch {
                expect(false, "the draft would not open: \(error)")
                return
            }
            guard let onTheClock = state.proMarket.currentPickTeamID,
                  let buyer = state.proTeams.ids.first(where: { $0 != onTheClock }) else {
                expect(false, "a bootstrapped draft has nobody on the clock")
                return
            }
            expectEqual(state.proMarket.owner(ofPick: 0), onTheClock,
                        "an untraded pick is not held by the club it came from")

            expect(state.proMarket.tradePick(at: 0, to: buyer), "a legal pick trade was refused")
            expectEqual(state.proMarket.currentPickTeamID, buyer,
                        "the pick moved and the clock did not")
            expect(!state.proMarket.tradePick(at: 0, to: buyer),
                   "a trade to the club that already holds the pick was accepted")
            expect(!state.proMarket.tradePick(at: ProRules.draftPickCount, to: buyer),
                   "a pick outside the draft was traded")
            expect(WorldIntegrity.check(state).isValid, "a traded pick made the world invalid")
            expectEqual(
                try? SaveEnvelope.decode(GameState.self, from: SaveEnvelope.encode(state)),
                state,
                "a traded pick did not survive a save round trip"
            )

            // Traded back is not an exception any more, and is not stored as one.
            expect(state.proMarket.tradePick(at: 0, to: onTheClock))
            expectEqual(state.proMarket.currentPickTeamID, onTheClock)
            expect(state.proMarket.tradedPicks == nil,
                   "a pick traded home is still carried as an exception")
        }

        test("a league where nobody trades a pick weighs exactly what it did") {
            // Optional and omitted when empty: 224 records of "this club holds its own pick" is save
            // growth for a fact `draftOrder` already states, which FSC-003 makes a live concern.
            let state = GameState.bootstrap(seed: 60_131)
            expect(state.proMarket.tradedPicks == nil, "a fresh league already has traded picks")
            guard let bytes = try? JSONEncoder.stable().encode(state.proMarket),
                  let text = String(data: bytes, encoding: .utf8) else {
                expect(false, "the market would not encode")
                return
            }
            expect(!text.contains("tradedPicks"),
                   "every save grew a traded-pick key, so every existing save is stranded")
        }
    }
}
