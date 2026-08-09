import Foundation

/// A gap in the line, and how big the blocking made it.
public struct RunLane: Sendable, Equatable, Identifiable {
    /// Gap number, left to right, 0...5 for a five-man line.
    public let gapIndex: Int
    public let centerLateralYards: Double
    public let halfWidth: Double

    public var id: Int { gapIndex }

    public init(gapIndex: Int, centerLateralYards: Double, halfWidth: Double) {
        self.gapIndex = gapIndex
        self.centerLateralYards = centerLateralYards
        self.halfWidth = halfWidth
    }

    public var aimPoint: FieldPoint {
        FieldPoint.yards(depth: 2.5, lateralYards: centerLateralYards)
    }
}

/// Where the run is actually there to be had.
///
/// This is the run game's answer to the openness indicator: the blocking produces real gaps of
/// real widths, the highlight over the best one is only as trustworthy as the back's vision, and
/// the player can always ignore it and read the line themselves.
public enum RunLanes {

    /// The six gaps a five-man line makes, centred between adjacent blockers and outside the
    /// two ends.
    public static func gapCenters(blockers: [FieldedPlayer]) -> [Double] {
        let ordered = blockers.map(\.point.lateralYards).sorted()
        guard ordered.count >= 2 else { return [-3, 0, 3] }
        var centers: [Double] = [ordered[0] - 3.0]
        for index in 1..<ordered.count {
            centers.append((ordered[index - 1] + ordered[index]) / 2)
        }
        centers.append(ordered[ordered.count - 1] + 3.0)
        return centers
    }

    /// Opens the lanes for this snap.
    public static func open(
        blockers: [FieldedPlayer],
        defenders: [FieldedPlayer],
        call: OffensivePlay,
        rng: inout SeededRandom
    ) -> [RunLane] {
        let centers = gapCenters(blockers: blockers)
        var lanes: [RunLane] = []

        for (index, center) in centers.enumerated() {
            // The two blockers who own this gap, against the defenders nearest to it.
            let nearBlockers = blockers
                .sorted { abs($0.point.lateralYards - center) < abs($1.point.lateralYards - center) }
                .prefix(2)
            let nearDefenders = defenders
                .sorted { abs($0.point.lateralYards - center) < abs($1.point.lateralYards - center) }
                .prefix(2)

            let blocking = nearBlockers.isEmpty
                ? Double(LeagueRules.ratingFloor)
                : nearBlockers.reduce(0.0) { $0 + Double($1.athlete.runBlock) } / Double(nearBlockers.count)
            let shedding = nearDefenders.isEmpty
                ? Double(LeagueRules.ratingFloor)
                : nearDefenders.reduce(0.0) { $0 + Double($1.athlete.blockShed) } / Double(nearDefenders.count)

            var advantage = blocking - shedding + rng.gaussian(mean: 0, sd: 6)
            // An outside run is designed to get to the edge, so the edges are where the blocking
            // is aimed; an inside run is the reverse.
            let isEdge = index == 0 || index == centers.count - 1
            if call == .outsideRun { advantage += isEdge ? 10 : -6 }
            if call == .insideRun { advantage += isEdge ? -8 : 6 }

            lanes.append(
                RunLane(
                    gapIndex: index,
                    centerLateralYards: center,
                    halfWidth: ArcadeTuning.laneHalfWidth(blockAdvantage: advantage)
                )
            )
        }
        return lanes
    }

    /// The lane the highlight points at.
    ///
    /// A back with vision finds the crease; one without guesses, and the player who has been
    /// watching the line can still overrule him. Nothing here changes what the lanes *are* —
    /// only how reliably the game tells you which is best.
    public static func suggested(
        lanes: [RunLane],
        vision: Int,
        rng: inout SeededRandom
    ) -> RunLane? {
        guard !lanes.isEmpty else { return nil }
        guard let best = lanes.max(by: { $0.halfWidth < $1.halfWidth }) else { return nil }
        let reliability = ArcadeTuning.laneReadReliability(vision)
        if rng.chance(reliability) { return best }
        return lanes[rng.int(in: 0...(lanes.count - 1))]
    }

    /// The lane a carrier is currently running in, if any.
    public static func lane(containing point: FieldPoint, lanes: [RunLane]) -> RunLane? {
        lanes.first { abs(point.lateralYards - $0.centerLateralYards) <= $0.halfWidth }
    }
}
