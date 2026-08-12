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

        var previous: DomainEvent?
        var sequences: Set<Int> = []
        let orderedWithinSeason = decodedEvents.allSatisfy { event in
            defer { previous = event }
            return event.occurredAt.season == decodedSeason
                && sequences.insert(event.sequence).inserted
                && (previous.map { Self.ranksBefore($0, event) } ?? true)
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

    /// True when `lhs` outranks `rhs` for a place in the sample: heavier first, and among equals the
    /// one that happened first.
    ///
    /// The sequence tie-break is what keeps this deterministic and keeps a finished season stable —
    /// once a season is over it receives no further events, so its sample stops moving.
    static func ranksBefore(_ lhs: DomainEvent, _ rhs: DomainEvent) -> Bool {
        let left = lhs.payload.historicalWeight
        let right = rhs.payload.historicalWeight
        return left == right ? lhs.sequence < rhs.sequence : left > right
    }

    /// Folds one archived event in, keeping the heaviest bodies the season produced.
    ///
    /// Ranked rather than first-come. A season archives roughly 70,000 events into 32 slots, so a
    /// first-come rule fills them in the opening weeks and the championship at the end never gets
    /// in — which is what the 30-season gate measured before this was ranked.
    public mutating func record(_ event: DomainEvent) {
        archivedCount += 1
        guard event.payload.historicalWeight > 0 else { return }

        // Nothing to do when the sample is full and this event cannot displace its weakest member,
        // which is the overwhelmingly common case at scale.
        if notableEvents.count >= Self.maximumNotableEvents,
           let weakest = notableEvents.last,
           !Self.ranksBefore(event, weakest) {
            return
        }
        let insertion = notableEvents.firstIndex { Self.ranksBefore(event, $0) }
            ?? notableEvents.count
        notableEvents.insert(event, at: insertion)
        if notableEvents.count > Self.maximumNotableEvents {
            notableEvents.removeLast(notableEvents.count - Self.maximumNotableEvents)
        }
    }
}
