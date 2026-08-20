import Foundation

/// The rules-owned, position-aware rating used by bounded player form read models.
///
/// This is deliberately a pure projection from one retained box-score line. It does not read
/// hidden attributes or future state, so the app can reuse it without creating a second authority.
public enum PlayerFormRating {
    public static func rating(
        for line: PlayerGameStatistics,
        position: Position
    ) -> Int {
        // Codable saves can contain hostilely large counters even though generated games cannot.
        // Cap each contribution before multiplication so the bounded display never overflows.
        let maxYards = SharedRules.ratingRange.upperBound * 20
        let maxTouchdowns = SharedRules.ratingRange.upperBound
        let passingYards = min(max(line.passingYards, 0), maxYards)
        let rushingYards = min(max(line.rushingYards, 0), maxYards)
        let receivingYards = min(max(line.receivingYards, 0), maxYards)
        let touchdowns = min(max(line.touchdowns, 0), maxTouchdowns)
        let production: Int
        switch position {
        case .quarterback:
            production = passingYards / 20 + touchdowns * 8
        case .runningBack:
            production = rushingYards / 10 + touchdowns * 8
        case .wideReceiver, .tightEnd:
            production = receivingYards / 10 + touchdowns * 8
        default:
            production = touchdowns * 8
        }
        return min(SharedRules.ratingRange.upperBound,
                   max(SharedRules.ratingRange.lowerBound, 55 + production))
    }
}
