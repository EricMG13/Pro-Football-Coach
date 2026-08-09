import Foundation

/// The eleven players an offense puts on the field, drawn from the depth chart.
///
/// Groups are guaranteed distinct: a team thin at a position borrows from the fallback chain
/// rather than fielding the same man twice, which would break man-coverage targeting and give
/// two discs the same identity.
public struct OffensivePersonnel: Sendable {
    public let quarterback: Athlete
    public let backs: [Athlete]
    public let receivers: [Athlete]
    public let tightEnds: [Athlete]
    public let linemen: [Athlete]

    public init(
        quarterback: Athlete,
        backs: [Athlete],
        receivers: [Athlete],
        tightEnds: [Athlete],
        linemen: [Athlete]
    ) {
        self.quarterback = quarterback
        self.backs = backs
        self.receivers = receivers
        self.tightEnds = tightEnds
        self.linemen = linemen
    }

    /// Builds the unit from a team's depth chart, in depth order, healthy players first.
    public init(team: Team, clutchApplies: Bool = false) {
        var picker = SquadPicker(team: team, clutchApplies: clutchApplies)
        quarterback = picker.take(.qb, fallbacks: [.rb, .wr])
            ?? SquadPicker.placeholder(.qb)
        receivers = picker.take(.wr, count: 3, fallbacks: [.te, .rb])
        tightEnds = picker.take(.te, count: 1, fallbacks: [.wr, .ol])
        backs = picker.take(.rb, count: 1, fallbacks: [.te, .wr])
        linemen = picker.take(.ol, count: 5, fallbacks: [.te, .dl])
    }

    /// Everyone who can catch a pass, in the order routes are dealt to them.
    public var eligibles: [Athlete] { receivers + tightEnds + backs }
}

/// The eleven players a defense puts on the field for a given call.
public struct DefensivePersonnel: Sendable {
    public let linemen: [Athlete]
    public let linebackers: [Athlete]
    public let corners: [Athlete]
    public let safeties: [Athlete]

    public init(linemen: [Athlete], linebackers: [Athlete], corners: [Athlete], safeties: [Athlete]) {
        self.linemen = linemen
        self.linebackers = linebackers
        self.corners = corners
        self.safeties = safeties
    }

    /// Sub packages are personnel decisions before they are anything else: nickel trades a
    /// linebacker for a fifth defensive back, dime trades two, prevent trades a lineman as well.
    public static func counts(for call: DefensivePlay) -> (dl: Int, lb: Int, cb: Int, s: Int) {
        switch call {
        case .base, .blitz, .contain: (4, 3, 2, 2)
        case .nickel: (4, 2, 3, 2)
        case .dime: (4, 1, 4, 2)
        case .prevent: (3, 2, 4, 2)
        }
    }

    public init(team: Team, call: DefensivePlay, clutchApplies: Bool = false) {
        var picker = SquadPicker(team: team, clutchApplies: clutchApplies)
        let counts = Self.counts(for: call)
        linemen = picker.take(.dl, count: counts.dl, fallbacks: [.lb, .ol])
        linebackers = picker.take(.lb, count: counts.lb, fallbacks: [.s, .dl])
        corners = picker.take(.cb, count: counts.cb, fallbacks: [.s, .lb])
        safeties = picker.take(.s, count: counts.s, fallbacks: [.cb, .lb])
    }

    public var all: [Athlete] { linemen + linebackers + corners + safeties }
}

/// Draws distinct players off a depth chart, falling through related positions when a group
/// runs dry.
struct SquadPicker {
    private var pools: [Position: [Athlete]]
    private var used: Set<UUID> = []

    init(team: Team, clutchApplies: Bool) {
        var built: [Position: [Athlete]] = [:]
        for position in Position.allCases {
            built[position] = team.depthOrder(for: position)
                .map { Athlete(player: $0, clutchApplies: clutchApplies) }
        }
        pools = built
    }

    /// One player from `position`, or from the fallback chain if that group is exhausted.
    mutating func take(_ position: Position, fallbacks: [Position]) -> Athlete? {
        for candidate in [position] + fallbacks {
            if let found = pools[candidate]?.first(where: { !used.contains($0.id) }) {
                used.insert(found.id)
                return found
            }
        }
        // Last resort: anybody at all who is still standing.
        for (_, pool) in pools.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            if let found = pool.first(where: { !used.contains($0.id) }) {
                used.insert(found.id)
                return found
            }
        }
        return nil
    }

    mutating func take(_ position: Position, count: Int, fallbacks: [Position]) -> [Athlete] {
        var result: [Athlete] = []
        for _ in 0..<count {
            guard let next = take(position, fallbacks: fallbacks) else { break }
            result.append(next)
        }
        // A roster too thin to field the group at all still has to produce discs, or the snap
        // has no formation. Synthetic bodies are rated at the floor and clearly named.
        while result.count < count {
            result.append(SquadPicker.placeholder(position))
        }
        return result
    }

    /// A replacement-level body. Only reachable on a roster below the league's own minimums.
    static func placeholder(_ position: Position) -> Athlete {
        var values: [Attribute: Int] = [:]
        for attribute in position.attributes { values[attribute] = LeagueRules.ratingFloor }
        let player = Player(
            firstName: "Practice",
            lastName: "Squad",
            position: position,
            age: 24,
            yearsPro: 0,
            jersey: position.jerseyRange.lowerBound,
            heightInches: 72,
            weightPounds: 210,
            college: "Undrafted",
            ratings: Ratings(values: values),
            potential: .f
        )
        return Athlete(player: player)
    }
}

/// Where everybody lines up.
///
/// Placement only — who covers whom is `Coverage`'s job, and what the receivers run is
/// `Routes`'. Keeping those apart is what lets a formation be checked for legality (eleven men,
/// seven on the line, nobody out of bounds) without simulating anything.
public enum Formations {

    /// Half the distance between adjacent linemen, in yards.
    static let lineSplitYards: Double = 2.0

    /// Whether the call is run from the gun. Under centre sells play action and inside runs.
    public static func isShotgun(_ call: OffensivePlay) -> Bool {
        switch call {
        case .insideRun, .playAction, .twoPointConversion: false
        default: true
        }
    }

    public static func quarterbackDepth(_ call: OffensivePlay) -> Double {
        isShotgun(call) ? -5.0 : -1.5
    }

    /// The offensive eleven for a call.
    ///
    /// `variation` re-deals alignment within the same call family — the audible. It shifts
    /// splits and the back's alignment without changing the personnel or the play's identity.
    public static func offense(
        for call: OffensivePlay,
        personnel: OffensivePersonnel,
        variation: Int = 0
    ) -> [FieldedPlayer] {
        var players: [FieldedPlayer] = []
        let shift = Double((variation % 3) - 1) * 0.9

        // Five linemen across the ball.
        for (index, lineman) in personnel.linemen.prefix(5).enumerated() {
            let offset = (Double(index) - 2) * lineSplitYards
            players.append(
                FieldedPlayer(
                    athlete: lineman,
                    side: .offense,
                    role: .blocker,
                    point: .yards(depth: 0, lateralYards: offset)
                )
            )
        }

        players.append(
            FieldedPlayer(
                athlete: personnel.quarterback,
                side: .offense,
                role: .quarterback,
                point: .yards(depth: quarterbackDepth(call), lateralYards: 0)
            )
        )

        // Eligibles are numbered in the order routes are dealt: outside receivers, then the
        // tight end, then the back.
        var routeIndex = 0
        let wideSplits: [Double] = [-19 + shift, 17 - shift, -11 + shift, 12 - shift]
        for (index, receiver) in personnel.receivers.enumerated() {
            let lateral = wideSplits[index % wideSplits.count]
            players.append(
                FieldedPlayer(
                    athlete: receiver,
                    side: .offense,
                    role: .receiver(routeIndex: routeIndex),
                    point: .yards(depth: index >= 2 ? -1.0 : 0, lateralYards: lateral)
                )
            )
            routeIndex += 1
        }

        for (index, tightEnd) in personnel.tightEnds.enumerated() {
            let side: Double = index % 2 == 0 ? 1 : -1
            players.append(
                FieldedPlayer(
                    athlete: tightEnd,
                    side: .offense,
                    role: .receiver(routeIndex: routeIndex),
                    point: .yards(depth: 0, lateralYards: side * (lineSplitYards * 2 + 1.5))
                )
            )
            routeIndex += 1
        }

        for (index, back) in personnel.backs.enumerated() {
            // Offset behind the quarterback in the gun, directly behind him under centre.
            let lateral = isShotgun(call) ? (index % 2 == 0 ? 2.5 : -2.5) : 0
            players.append(
                FieldedPlayer(
                    athlete: back,
                    side: .offense,
                    role: .receiver(routeIndex: routeIndex),
                    point: .yards(depth: quarterbackDepth(call) - 1.6, lateralYards: lateral)
                )
            )
            routeIndex += 1
        }

        return players
    }

    /// The defensive eleven for a call, placed but not yet assigned.
    public static func defense(
        for call: DefensivePlay,
        personnel: DefensivePersonnel,
        variation: Int = 0
    ) -> [FieldedPlayer] {
        var players: [FieldedPlayer] = []
        let shift = Double((variation % 3) - 1) * 0.5

        // The front, spread wider on a contain call and tighter when they are coming.
        let frontSpread: Double = call == .contain ? 3.4 : (call == .blitz ? 2.2 : 2.8)
        let front = personnel.linemen
        for (index, lineman) in front.enumerated() {
            let centred = Double(index) - Double(front.count - 1) / 2
            players.append(
                FieldedPlayer(
                    athlete: lineman,
                    side: .defense,
                    role: .rusher,
                    point: .yards(depth: 1.0, lateralYards: centred * frontSpread)
                )
            )
        }

        let backerDepth: Double = call == .prevent ? 7.5 : 4.5
        for (index, backer) in personnel.linebackers.enumerated() {
            let centred = Double(index) - Double(personnel.linebackers.count - 1) / 2
            players.append(
                FieldedPlayer(
                    athlete: backer,
                    side: .defense,
                    // A blitz sends one off the edge; the rest read the play.
                    role: (call == .blitz && index == 0) ? .rusher : .runDefender,
                    point: .yards(depth: backerDepth, lateralYards: centred * 5.5 + shift)
                )
            )
        }

        // Corners travel with the width of the formation; the slot corner walks down.
        let cornerSplits: [Double] = [-18, 16, -10, 11]
        let cornerDepth: Double = call == .prevent ? 9.5 : 6.5
        for (index, corner) in personnel.corners.enumerated() {
            players.append(
                FieldedPlayer(
                    athlete: corner,
                    side: .defense,
                    role: .zoneCoverage(
                        anchor: .yards(
                            depth: cornerDepth + 4,
                            lateralYards: cornerSplits[index % cornerSplits.count]
                        )
                    ),
                    point: .yards(
                        depth: index >= 2 ? cornerDepth - 1.5 : cornerDepth,
                        lateralYards: cornerSplits[index % cornerSplits.count]
                    )
                )
            )
        }

        let safetyDepth: Double = {
            switch call {
            case .prevent: 18.0
            case .dime: 14.0
            case .blitz: 10.0
            default: 12.5
            }
        }()
        for (index, safety) in personnel.safeties.enumerated() {
            let centred = Double(index) - Double(personnel.safeties.count - 1) / 2
            players.append(
                FieldedPlayer(
                    athlete: safety,
                    side: .defense,
                    role: .zoneCoverage(
                        anchor: .yards(depth: safetyDepth, lateralYards: centred * 12)
                    ),
                    point: .yards(depth: safetyDepth, lateralYards: centred * 12)
                )
            )
        }

        return players
    }
}
