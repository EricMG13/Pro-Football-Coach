import Foundation

/// What a tradition actually does.
///
/// D6 clause 4: "A tradition the player cannot feel in the simulation is decoration." Every
/// tradition carries one of these, so a tradition without a mechanical effect does not compile —
/// which is the structural form of `08-OPUS5-BUILD-PROMPT.md`'s first named failure mode, dead
/// capability that "looked finished and was hollow".
public enum TraditionEffect: Codable, Sendable, Equatable, Hashable {
    /// Home-field advantage rises by `bonus` rating points in this week of the season.
    case homeFieldInWeek(week: Int, bonus: Int)
    /// Recruiting interest rises by `bonus` for recruits from this region.
    case recruitingInRegion(regionID: UUID, bonus: Int)
    /// Morale moves by `delta` after a win, or the negative of it after a loss.
    case moraleAfterResult(afterWin: Bool, delta: Int)
    /// Home-field advantage rises by `bonus` against a rival.
    case homeFieldAgainstRival(bonus: Int)

    /// The rating-point size of the effect, for readouts and for the assertion that it is nonzero.
    public var magnitude: Int {
        switch self {
        case let .homeFieldInWeek(_, bonus): return Swift.abs(bonus)
        case let .recruitingInRegion(_, bonus): return Swift.abs(bonus)
        case let .moraleAfterResult(_, delta): return Swift.abs(delta)
        case let .homeFieldAgainstRival(bonus): return Swift.abs(bonus)
        }
    }
}

/// A generated tradition.
public struct Tradition: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    /// One short line for the surfaces. `04` owns copy; this is the engine-side default.
    public let blurb: String
    public let effect: TraditionEffect

    public init(id: UUID, name: String, blurb: String, effect: TraditionEffect) {
        self.id = id
        self.name = name
        self.blurb = blurb
        self.effect = effect
    }
}

/// Generates traditions from a grammar, each with a mechanical hook.
public enum TraditionGrammar {
    /// D6 clause 4: two to four per programme.
    public static let perProgrammeRange: ClosedRange<Int> = 2...4

    public static func traditions(
        regionID: UUID,
        seasonWeeks: Int,
        using rng: inout SeededRandom
    ) -> [Tradition] {
        let count = rng.int(in: perProgrammeRange)
        var traditions: [Tradition] = []
        for index in 0..<count {
            traditions.append(tradition(index: index, regionID: regionID,
                                        seasonWeeks: seasonWeeks, using: &rng))
        }
        return traditions
    }

    private static func tradition(
        index: Int,
        regionID: UUID,
        seasonWeeks: Int,
        using rng: inout SeededRandom
    ) -> Tradition {
        // The effect kind is chosen by index rather than at random, so a programme with three
        // traditions never gets three of the same kind — which would read as one tradition
        // repeated and would stack an effect the balance never anticipated.
        let effect: TraditionEffect
        let name: String
        let blurb: String
        switch index % 4 {
        case 0:
            let week = rng.int(in: 1...seasonWeeks)
            effect = .homeFieldInWeek(week: week, bonus: rng.int(in: 2...6))
            name = "\(rng.pick(ritualAdjectives)) \(rng.pick(ritualNouns))"
            blurb = "The crowd is loudest in week \(week)."
        case 1:
            effect = .recruitingInRegion(regionID: regionID, bonus: rng.int(in: 3...8))
            name = "\(rng.pick(ritualAdjectives)) \(rng.pick(pipelineNouns))"
            blurb = "Local families have sent sons here for generations."
        case 2:
            let afterWin = rng.chance(0.6)
            effect = .moraleAfterResult(afterWin: afterWin, delta: rng.int(in: 2...5))
            name = "The \(rng.pick(ritualNouns))"
            blurb = afterWin ? "The locker room sings after a win." : "Defeat is answered in silence."
        default:
            effect = .homeFieldAgainstRival(bonus: rng.int(in: 3...7))
            name = "\(rng.pick(rivalryAdjectives)) \(rng.pick(rivalryNouns))"
            blurb = "This one is circled a year in advance."
        }
        return Tradition(id: rng.uuid(), name: name, blurb: blurb, effect: effect)
    }

    private static let ritualAdjectives = [
        "Lantern", "Ironbell", "Midnight", "Harvest", "Coalfire", "Stonewalk", "Riverlight",
        "Frostgate", "Emberside", "Longbridge",
    ]
    private static let ritualNouns = [
        "Walk", "Vigil", "Chorus", "Toll", "Procession", "Bonfire", "Watch", "Chant",
    ]
    private static let pipelineNouns = [
        "Pipeline", "Covenant", "Compact", "Promise", "Homecoming",
    ]
    private static let rivalryAdjectives = [
        "Iron", "Bitter", "Old", "Border", "Founders", "Quarry",
    ]
    private static let rivalryNouns = [
        "Trophy", "Cup", "Bell", "Axe", "Spade", "Chain", "Keystone",
    ]
}
