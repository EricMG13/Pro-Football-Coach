import Foundation

/// What one season leaves behind after its events fall out of the bounded hot journal.
///
/// `docs/roadmap/05-PERSISTENCE-PERFORMANCE-TESTING.md` §2 names this layer: a historical aggregate
/// archive between the bounded recent journal and the rebuildable indexes. `docs/roadmap/06` makes
/// it an M7 exit condition that important past events can be surfaced *without scanning the entire
/// save*, and the counter this replaces could surface nothing at all.
///
/// **Two numbers doing different jobs.** `archivedCount` is the volume signal and is unbounded in
/// value — a season that archived ten thousand events says so. `notableEvents` is a bounded sample
/// of bodies, so the digest's *size* is bounded even when the season's activity is not. Keeping the
/// count as well as the sample is what stops a truncated sample from reading as a quiet season.
public struct SeasonHistoryDigest: Codable, Sendable, Equatable, Identifiable {
    /// Bodies retained per season. A season is roughly 4,000 events at target scale, so this is a
    /// sample by construction rather than a limit that is rarely reached.
    public static let maximumNotableEvents = 32

    public var id: Int { season }
    public let season: Int
    public private(set) var archivedCount: Int
    public private(set) var notableEvents: [DomainEvent]

    public init(season: Int) {
        self.season = max(0, season)
        archivedCount = 0
        notableEvents = []
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedSeason = try container.decode(Int.self, forKey: .season)
        let decodedCount = try container.decode(Int.self, forKey: .archivedCount)
        let decodedEvents = try container.decode([DomainEvent].self, forKey: .notableEvents)

        var previousSequence: Int?
        let orderedWithinSeason = decodedEvents.allSatisfy { event in
            defer { previousSequence = event.sequence }
            return event.occurredAt.season == decodedSeason
                && (previousSequence.map { event.sequence > $0 } ?? true)
        }

        // A kept body is by definition an archived event, so the count can never be the smaller of
        // the two. That is the accounting a hand-edited save breaks first, and nothing downstream
        // re-derives it.
        guard decodedSeason >= 0,
              decodedCount >= 0,
              decodedEvents.count <= Self.maximumNotableEvents,
              decodedEvents.count <= decodedCount,
              orderedWithinSeason else {
            throw DecodingError.dataCorruptedError(
                forKey: .archivedCount,
                in: container,
                debugDescription: "The season history digest violates its bounds or its accounting."
            )
        }

        season = decodedSeason
        archivedCount = decodedCount
        notableEvents = decodedEvents
    }

    /// Folds one archived event in.
    ///
    /// Bodies are kept **earliest first** rather than most-recent-first: a finished season must stop
    /// changing, and a most-recent policy would rewrite 2027's history every time 2031 overflowed.
    public mutating func record(_ event: DomainEvent, isNotable: Bool) {
        archivedCount += 1
        guard isNotable, notableEvents.count < Self.maximumNotableEvents else { return }
        notableEvents.append(event)
    }
}
