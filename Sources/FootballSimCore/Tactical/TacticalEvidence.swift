import Foundation

/// The bounded evidence needed to make opponent film observer-scoped. It deliberately stores
/// source fixture IDs rather than copying hidden team totals into every observer's save.
public struct OpponentObservation: Codable, Sendable, Equatable {
    public static let maximumSourceGames = 32
    public static let maximumAgeInWeeks = 4

    public let observerID: UUID
    public let opponentID: UUID
    public let observedThrough: CalendarState
    public let sourceGameIDs: [UUID]
    public let confidence: Int
    public let sampleSize: Int
    public let passRate: Int
    public let turnoverRate: Int

    public init(
        observerID: UUID,
        opponentID: UUID,
        observedThrough: CalendarState,
        sourceGameIDs: [UUID],
        confidence: Int,
        sampleSize: Int,
        passRate: Int,
        turnoverRate: Int
    ) {
        let uniqueSources = Array(Set(sourceGameIDs)).sorted { $0.uuidString < $1.uuidString }
        precondition(observerID != opponentID)
        precondition(uniqueSources.count <= Self.maximumSourceGames)
        precondition((0...100).contains(confidence))
        precondition((0...uniqueSources.count).contains(sampleSize))
        precondition((0...100).contains(passRate))
        precondition((0...100).contains(turnoverRate))
        self.observerID = observerID
        self.opponentID = opponentID
        self.observedThrough = observedThrough
        self.sourceGameIDs = uniqueSources
        self.confidence = confidence
        self.sampleSize = sampleSize
        self.passRate = passRate
        self.turnoverRate = turnoverRate
    }

    public init(
        observerID: UUID,
        snapshot: OpponentScoutingSnapshot,
        sourceGameIDs: [UUID],
        confidence: Int,
        sampleSize: Int
    ) {
        self.init(
            observerID: observerID,
            opponentID: snapshot.teamID,
            observedThrough: snapshot.observedThrough,
            sourceGameIDs: sourceGameIDs,
            confidence: confidence,
            sampleSize: sampleSize,
            passRate: snapshot.passRate,
            turnoverRate: snapshot.turnoverRate
        )
    }

    public var snapshot: OpponentScoutingSnapshot {
        OpponentScoutingSnapshot(
            teamID: opponentID,
            observedThrough: observedThrough,
            passRate: passRate,
            turnoverRate: turnoverRate
        )
    }

    /// Future evidence and evidence from another season are never usable. A bounded age prevents
    /// a stale scouting packet from silently becoming perfect knowledge later in a long career.
    public func isCurrent(at calendar: CalendarState) -> Bool {
        guard observedThrough.season == calendar.season,
              observedThrough.week <= calendar.week else { return false }
        return calendar.week - observedThrough.week <= Self.maximumAgeInWeeks
    }

    public static func balanced(
        observerID: UUID,
        opponentID: UUID,
        observedThrough: CalendarState
    ) -> OpponentObservation {
        OpponentObservation(
            observerID: observerID,
            opponentID: opponentID,
            observedThrough: observedThrough,
            sourceGameIDs: [],
            confidence: 0,
            sampleSize: 0,
            passRate: 50,
            turnoverRate: 0
        )
    }
}
