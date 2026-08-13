import Foundation
import FootballSimCore

// FSC-013. A recorded game names the players who played in it, and whole-root integrity checked
// those names against the roster the organisation holds *now*. That is truthful only while ownership
// never changes inside a live season - and the moment anything releases a player mid-season, every
// game they already played becomes invalid. The professional tier hit exactly that: expiring
// contracts in the final week invalidated 315 players' worth of completed games.
//
// The fix needs no new state. `PlayerCareerSeason` already records which organisation a player
// belonged to in which season, bounded and persisted since M2. A participant is legal if the
// organisation owns them now *or* their career says they were there that season.

func runRosterTenureTests() {
    suite("Roster tenure: a game keeps the players who played it") {
        test("a departed player does not invalidate the game they played") {
            var fixture = try tenureFixture(seed: 99_001)
            let participant = try requireTenure(fixture.participantID)

            // They played, and then they left - the shape of contract expiry, a trade, or a cut.
            fixture.state.programmes.update(fixture.homeID) { programme in
                programme.rosterIDs.removeAll { $0 == participant }
            }
            expect(refusesGame(fixture),
                   "removing a participant with no career record should still be refused")

            // Their career says where they were that season, which is what makes it truthful.
            var people = fixture.state.people
            people.updatePlayerCareer(participant) { record in
                _ = record.append(PlayerCareerSeason(
                    season: fixture.state.calendar.season,
                    organisationID: fixture.homeID,
                    tier: .college,
                    games: 1,
                    starts: 1,
                    overallAtEnd: Rating(70)
                ))
            }
            fixture.state.people = people
            expect(!refusesGame(fixture),
                   "a game was invalidated by a departure its career record explains")
        }

        test("a player who never belonged to the team is still refused") {
            // The check must keep biting. Tenure legalises a *departure*, not an impostor.
            var fixture = try tenureFixture(seed: 99_002)
            let participant = try requireTenure(fixture.participantID)
            fixture.state.programmes.update(fixture.homeID) { programme in
                programme.rosterIDs.removeAll { $0 == participant }
            }
            var people = fixture.state.people
            people.updatePlayerCareer(participant) { record in
                _ = record.append(PlayerCareerSeason(
                    season: fixture.state.calendar.season,
                    organisationID: fixture.awayID,          // the wrong club
                    tier: .college,
                    games: 1,
                    starts: 1,
                    overallAtEnd: Rating(70)
                ))
            }
            fixture.state.people = people
            expect(refusesGame(fixture),
                   "a career at another club legalised a participant it should not")
        }

        test("tenure in a different season does not legalise this one") {
            var fixture = try tenureFixture(seed: 99_003)
            let participant = try requireTenure(fixture.participantID)
            fixture.state.programmes.update(fixture.homeID) { programme in
                programme.rosterIDs.removeAll { $0 == participant }
            }
            var people = fixture.state.people
            people.updatePlayerCareer(participant) { record in
                _ = record.append(PlayerCareerSeason(
                    season: fixture.state.calendar.season + 4,
                    organisationID: fixture.homeID,
                    tier: .college,
                    games: 1,
                    starts: 1,
                    overallAtEnd: Rating(70)
                ))
            }
            fixture.state.people = people
            expect(refusesGame(fixture),
                   "a later season's tenure legalised an earlier game")
        }

        test("an untouched game is accepted") {
            let fixture = try tenureFixture(seed: 99_004)
            expect(!refusesGame(fixture), "a freshly played game was refused")
        }
    }
}

private enum RosterTenureTestError: Error { case missing }

private func requireTenure<T>(_ value: T?) throws -> T {
    guard let value else { throw RosterTenureTestError.missing }
    return value
}

private struct TenureFixture {
    var state: GameState
    let gameID: UUID
    let homeID: UUID
    let awayID: UUID
    let participantID: UUID?
}

/// True when the root refuses *this game's* participant contract.
///
/// Asserted instead of whole-root validity on purpose: a hand-built fixture that removes a player
/// from a roster also trips scholarship reconciliation and career-history checks, and those are not
/// what FSC-013 is about. Naming the issue keeps the test measuring one thing.
private func refusesGame(_ fixture: TenureFixture) -> Bool {
    WorldIntegrity.check(fixture.state).issues.contains(.invalidScheduledGame(gameID: fixture.gameID))
}

/// A world with one completed college game, and the identity of somebody who played in it.
private func tenureFixture(seed: UInt64) throws -> TenureFixture {
    var state = GameState.bootstrap(seed: seed)
    let game = try requireTenure(state.competition.currentSchedule.games.first {
        $0.tier == .college && $0.week == state.calendar.week
    })
    let summary = AbstractGameSimulator.play(game, in: state)
    var schedule = state.competition.currentSchedule
    _ = try schedule.recordResults([ScheduledGameResult(gameID: game.id, summary: summary)])
    state.competition.currentSchedule = schedule
    return TenureFixture(
        state: state,
        gameID: game.id,
        homeID: game.homeID,
        awayID: game.awayID,
        participantID: summary.homeParticipantIDs.first
    )
}
