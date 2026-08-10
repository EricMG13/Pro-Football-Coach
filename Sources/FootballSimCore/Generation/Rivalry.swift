import Foundation

/// A rivalry between two programmes or teams.
///
/// D6 clause 3: seeded from geography and conference, then **strengthened by what happens**. The
/// record is "a first-class save object with its own narrative line", so it is a stored type with
/// its own history rather than a number hanging off a programme.
public struct Rivalry: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    /// The two sides, always in ascending UUID order so one rivalry has one representation.
    public let sideA: UUID
    public let sideB: UUID

    /// Where the rivalry came from. Kept because "we are near each other" and "we have played four
    /// one-score games" are different stories and the surfaces say which.
    public enum Origin: String, Codable, Sendable {
        case geography, conference, both
    }

    public let origin: Origin

    /// On the rating scale. Seeded from origin, then moved by results.
    public private(set) var intensity: Rating

    /// Meetings that mattered, newest first, bounded.
    public private(set) var notableMeetings: [String]

    public static let notableMeetingLimit = 12

    public init(
        id: UUID,
        sideA: UUID,
        sideB: UUID,
        origin: Origin,
        intensity: Rating,
        notableMeetings: [String] = []
    ) {
        self.id = id
        // Canonical ordering. Without it the same rivalry can exist twice under two keys, and the
        // save carries both.
        let ordered = [sideA, sideB].sorted { $0.uuidString < $1.uuidString }
        self.sideA = ordered[0]
        self.sideB = ordered[1]
        self.origin = origin
        self.intensity = intensity
        self.notableMeetings = Array(notableMeetings.prefix(Rivalry.notableMeetingLimit))
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            sideA: try container.decode(UUID.self, forKey: .sideA),
            sideB: try container.decode(UUID.self, forKey: .sideB),
            origin: try container.decode(Origin.self, forKey: .origin),
            intensity: try container.decode(Rating.self, forKey: .intensity),
            notableMeetings: try container.decode([String].self, forKey: .notableMeetings)
        )
    }

    public func involves(_ id: UUID) -> Bool { sideA == id || sideB == id }

    public func other(than id: UUID) -> UUID? {
        if sideA == id { return sideB }
        if sideB == id { return sideA }
        return nil
    }

    /// A meeting strengthens or weakens the rivalry, and the memorable ones are remembered.
    ///
    /// The list is bounded and drops the oldest, which is what `CLAUDE.md` requires of anything
    /// that grows across seasons — a career is twenty of them.
    public mutating func record(meeting: String?, intensityDelta: Int) {
        intensity = intensity.adjusted(by: intensityDelta)
        guard let meeting else { return }
        notableMeetings = Array(([meeting] + notableMeetings).prefix(Rivalry.notableMeetingLimit))
    }
}

/// Seeds rivalries from geography and conference, per D6 clause 3.
public enum RivalrySeeder {
    /// Two programmes in the same conference are candidates; two within this squared grid distance
    /// are candidates whatever conference they are in.
    ///
    /// Expressed as a squared distance because `MapCity` compares squared distances and a square
    /// root would buy nothing but a chance to disagree across platforms. 200 grid units on a
    /// 1000-by-700 map: near enough to be local, far enough that it is not every neighbour.
    public static let geographicRadiusSquared = 200 * 200

    /// Base intensities by origin. A shared border and a shared conference is the strongest start;
    /// geography alone beats conference alone, because place is the thing D6 makes a mechanic.
    public static func baseIntensity(for origin: Rivalry.Origin) -> Int {
        switch origin {
        case .both: return 74
        case .geography: return 62
        case .conference: return 54
        }
    }

    /// One member's candidate rivals, strongest first, bounded by
    /// `SharedRules.rivalriesPerProgramme`.
    public struct Member {
        public let id: UUID
        public let conferenceID: UUID?
        public let city: MapCity

        public init(id: UUID, conferenceID: UUID?, city: MapCity) {
            self.id = id
            self.conferenceID = conferenceID
            self.city = city
        }
    }

    /// Every seeded rivalry across `members`, deduplicated by canonical pair ordering.
    public static func seed(members: [Member], using rng: inout SeededRandom) -> [Rivalry] {
        var rivalries: [Rivalry] = []
        // Ordered iteration over an array, never over a Set or a Dictionary, so the output order is
        // a function of the input rather than of this launch's hash seed.
        //
        // There was a `seen` set here that could never reject anything: the nested loop already
        // visits each unordered pair exactly once, so every key was new by construction. It read
        // like a guard against duplicate pairs while guarding nothing, and it hid the invariant
        // that actually holds — uniqueness comes from the loop shape, and the test below asserts
        // it against the output rather than trusting a set that cannot fire.
        for (indexA, memberA) in members.enumerated() {
            for memberB in members[(indexA + 1)...] {
                guard let origin = origin(memberA, memberB) else { continue }
                let jitter = rng.int(in: -6...6)
                rivalries.append(Rivalry(
                    id: rng.uuid(),
                    sideA: memberA.id,
                    sideB: memberB.id,
                    origin: origin,
                    intensity: Rating(baseIntensity(for: origin) + jitter)
                ))
            }
        }
        return rivalries
    }

    private static func origin(_ a: Member, _ b: Member) -> Rivalry.Origin? {
        let sameConference = a.conferenceID != nil && a.conferenceID == b.conferenceID
        let near = a.city.squaredDistance(to: b.city) <= geographicRadiusSquared
        switch (sameConference, near) {
        case (true, true): return .both
        case (false, true): return .geography
        case (true, false): return .conference
        case (false, false): return nil
        }
    }

    /// The strongest rivalries for `memberID`, bounded, strongest first.
    ///
    /// A conference of 16 gives every member 15 conference rivals before geography adds any, so
    /// something has to choose. Ties break on the rivalry's own id so the choice is deterministic
    /// rather than dependent on the order the array happened to arrive in.
    public static func strongest(for memberID: UUID, among rivalries: [Rivalry]) -> [UUID] {
        rivalries
            .filter { $0.involves(memberID) }
            .sorted {
                $0.intensity == $1.intensity
                    ? $0.id.uuidString < $1.id.uuidString
                    : $0.intensity > $1.intensity
            }
            .prefix(SharedRules.rivalriesPerProgramme)
            .compactMap { $0.other(than: memberID) }
    }
}
