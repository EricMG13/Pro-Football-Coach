import Foundation
import FootballSimCore

// M7's last limb. `DomainEventPayload` already states the rule this obeys: "Presentation text is
// derived by read-model builders, never persisted as the source of truth." So a headline is computed
// from a typed payload here and never stored, and `historicalWeight` - the rank M7B introduced to
// decide which bodies an archived season keeps - is the same rank that decides what leads the feed.
// One definition of "important", used twice.

func runNewsFeedTests() {
    suite("News feed: what makes news") {
        test("weekly bookkeeping produces no headline") {
            let state = newsState(events: [
                newsEvent(sequence: 0, season: 3, payload: .integrityChecked(issueCount: 0)),
            ])
            expect(NewsFeedReadModel.build(from: state).items.isEmpty,
                   "an integrity check is not news")
        }

        test("a season ending produces a headline naming its champions") {
            var state = GameState.bootstrap(seed: 97_001)
            let college = state.programmes.ids[0]
            let pro = state.proTeams.ids[0]
            state = appendingNews(to: state, events: [
                newsEvent(sequence: 90, season: 3, payload: .seasonCompleted(
                    season: 3,
                    collegeChampionID: college,
                    proChampionID: pro
                )),
            ])
            let items = NewsFeedReadModel.build(from: state).items
            let headline = try requireNews(items.first(where: { $0.weight == 100 })?.headline)
            expect(headline.contains(state.programmes[college]?.name ?? "?"),
                   "the college champion is not named: \(headline)")
            expect(headline.contains(state.proTeams[pro]?.name ?? "?"),
                   "the professional champion is not named: \(headline)")
        }

        test("a season-boundary headline displays the 1-indexed season, not the raw internal one") {
            // `CalendarState.season` is 0-indexed internally; every other season-display call site
            // (`CoachWorldReadModelProvider.seasonLabel`, and this same provider's own market-open
            // headline) adds 1. These four headlines must match that convention, not contradict it.
            let state = newsState(events: [
                newsEvent(sequence: 93, season: 0, payload: .seasonCompleted(
                    season: 0,
                    collegeChampionID: UUID(uuidString: "00000000-0000-4000-8000-0000000000F0")!,
                    proChampionID: UUID(uuidString: "00000000-0000-4000-8000-0000000000F1")!
                )),
                newsEvent(sequence: 94, season: 0, payload: .proMarketOpened(
                    season: 0, draftClassCount: 1, freeAgentCount: 1
                )),
                newsEvent(sequence: 95, season: 0, payload: .proDraftStarted(season: 0)),
                newsEvent(sequence: 96, season: 0, payload: .proMarketClosed(season: 0)),
            ])
            let headlines = NewsFeedReadModel.build(from: state).items.map(\.headline)
            for headline in headlines {
                expect(headline.contains("Season 1") || headline.contains("season 1"),
                       "raw season 0 must display as Season 1: \(headline)")
                expect(!headline.contains("Season 0") && !headline.contains("season 0"),
                       "the raw internal season leaked into a headline: \(headline)")
            }
        }

        test("a transfer names the player and both programmes") {
            var state = GameState.bootstrap(seed: 97_002)
            let playerID = state.players.ids[0]
            let source = state.programmes.ids[0]
            let destination = state.programmes.ids[1]
            state = appendingNews(to: state, events: [
                newsEvent(sequence: 91, season: 3, payload: .playerTransferred(
                    playerID: playerID,
                    sourceProgrammeID: source,
                    destinationProgrammeID: destination,
                    targetSeason: 3,
                    window: .postseason,
                    sourceWasScholarship: true,
                    finalNIL: 0
                )),
            ])
            let headline = try requireNews(NewsFeedReadModel.build(from: state).items.first?.headline)
            expect(headline.contains(state.players[playerID]?.fullName ?? "?"))
            expect(headline.contains(state.programmes[destination]?.name ?? "?"))
        }

        test("an unknown participant degrades rather than printing a raw identifier") {
            // A departed player leaves the roster but stays in history. A headline that printed a
            // UUID would be worse than one that says nothing about who.
            let state = newsState(events: [
                newsEvent(sequence: 92, season: 3, payload: .staffHired(
                    staffID: UUID(uuidString: "00000000-0000-4000-8000-0000000000EE")!,
                    organisationID: UUID(uuidString: "00000000-0000-4000-8000-0000000000EF")!,
                    role: .headCoach
                )),
            ])
            let headline = try requireNews(NewsFeedReadModel.build(from: state).items.first?.headline)
            expect(!headline.contains("0000000000EE"), "a raw identifier reached a headline")
            expect(!headline.isEmpty)
        }
    }

    suite("News feed: order and bounds") {
        test("the newest season leads, and within a season the heaviest story leads") {
            var state = GameState.bootstrap(seed: 97_003)
            let college = state.programmes.ids[0]
            let pro = state.proTeams.ids[0]
            state = appendingNews(to: state, events: [
                newsEvent(sequence: 80, season: 3, payload: .seasonCompleted(
                    season: 3, collegeChampionID: college, proChampionID: pro
                )),
                newsEvent(sequence: 81, season: 4, payload: .staffHired(
                    staffID: state.staff.ids[0], organisationID: college, role: .headCoach
                )),
                newsEvent(sequence: 82, season: 4, payload: .seasonCompleted(
                    season: 4, collegeChampionID: college, proChampionID: pro
                )),
            ])
            let items = NewsFeedReadModel.build(from: state).items
            expectEqual(items.prefix(3).map(\.occurredAt.season), [4, 4, 3],
                        "a newer season must lead an older one")
            expectEqual(items.prefix(2).map(\.weight), [100, 35],
                        "within a season the heavier story must lead")
        }

        test("the feed is bounded") {
            var state = GameState.bootstrap(seed: 97_004)
            let college = state.programmes.ids[0]
            let pro = state.proTeams.ids[0]
            let flood = (0..<(NewsFeedReadModel.maximumItems + 30)).map { index in
                newsEvent(sequence: 200 + index, season: 5, payload: .seasonCompleted(
                    season: 5, collegeChampionID: college, proChampionID: pro
                ))
            }
            state = appendingNews(to: state, events: flood)
            expectEqual(NewsFeedReadModel.build(from: state).items.count,
                        NewsFeedReadModel.maximumItems)
        }

        test("two builds of the same world are identical") {
            let state = GameState.bootstrap(seed: 97_005)
            expectEqual(NewsFeedReadModel.build(from: state), NewsFeedReadModel.build(from: state))
        }

        test("a story that has left the hot journal still reaches the feed") {
            // The reason M7B kept bodies at all. A retention limit of one drives everything but the
            // last event into the archive, and the champion must still be reportable from there.
            var state = GameState.bootstrap(seed: 97_006)
            let college = state.programmes.ids[0]
            let pro = state.proTeams.ids[0]
            var ledger = DomainEventLedger(retentionLimit: 1)
            expect(ledger.append(contentsOf: [
                newsEvent(sequence: 300, season: 6, payload: .seasonCompleted(
                    season: 6, collegeChampionID: college, proChampionID: pro
                )),
                newsEvent(sequence: 301, season: 6, payload: .integrityChecked(issueCount: 0)),
            ]))
            state.history = ledger
            expect(state.history.recent.count == 1, "the champion should have been archived")
            let items = NewsFeedReadModel.build(from: state).items
            expect(items.contains { $0.weight == 100 },
                   "an archived champion did not reach the feed, so the archive buys nothing")
        }
    }
}

private enum NewsFeedTestError: Error { case missing }

private func requireNews<T>(_ value: T?) throws -> T {
    guard let value else { throw NewsFeedTestError.missing }
    return value
}

private func newsEvent(
    sequence: Int,
    season: Int,
    payload: DomainEventPayload
) -> DomainEvent {
    DomainEvent(
        id: DomainEvent.deterministicID(rootSeed: 97_000, sequence: sequence),
        sequence: sequence,
        occurredAt: CalendarState(season: season, week: 1),
        payload: payload
    )
}

private func appendingNews(to state: GameState, events: [DomainEvent]) -> GameState {
    var next = state
    var ledger = DomainEventLedger()
    _ = ledger.append(contentsOf: events)
    next.history = ledger
    return next
}

private func newsState(events: [DomainEvent]) -> GameState {
    appendingNews(to: GameState.bootstrap(seed: 97_009), events: events)
}
