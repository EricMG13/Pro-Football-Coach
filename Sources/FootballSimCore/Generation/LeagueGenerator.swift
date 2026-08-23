import Foundation

/// Everything one seed produces. The starting state of a save.
public struct GeneratedWorld: Codable, Sendable, Equatable {
    public let league: League
    public let map: GameMap
    public let programmes: [Programme]
    public let proTeams: [ProTeam]
    public let identities: [UUID: TeamIdentity]
    public let rivalries: [Rivalry]

    public init(
        league: League,
        map: GameMap,
        programmes: [Programme],
        proTeams: [ProTeam],
        identities: [UUID: TeamIdentity],
        rivalries: [Rivalry]
    ) {
        self.league = league
        self.map = map
        self.programmes = programmes
        self.proTeams = proTeams
        self.identities = identities
        self.rivalries = rivalries
    }

    /// Every generated string that reaches a surface, which is exactly what the collision test
    /// sweeps.
    ///
    /// `docs/PORT-LOG.md`: "The collision test enumerates the **generated output**, not the source
    /// arrays. Reading a list and judging it fictional is what produced both failures." And: "Every
    /// generated field that reaches a surface is in scope — player name, coach name, and **college
    /// or alma mater**, which is the field that slipped here."
    ///
    /// So this is a property of the world rather than a list inside the test: a phase that adds a
    /// generated name and forgets to add it here is a visible omission in the model, not an
    /// invisible one in a suite.
    ///
    /// Split by kind since 2026-08-12, because real location names are permitted and real school
    /// names are not. This is the union of the two, so a generated name can never belong to neither
    /// kind and go unchecked; the suite asserts that the two partition it.
    public var everyGeneratedName: [String] {
        everyGeneratedInstitutionName + everyGeneratedPlaceName
    }

    /// Names of *things somebody owns*: schools, teams, conferences, divisions, venues, traditions.
    ///
    /// These carry the full blocklist. A fictional school must not be named after a real one, and
    /// eight real cities are refused here — Buffalo, Cincinnati, Houston, Kansas City, Miami,
    /// Pittsburgh, Tulsa, Washington — each because it either is a real programme or contains one.
    /// They are permitted as a place below, which is the whole reason this is split by kind rather
    /// than swept as one flat list.
    public var everyGeneratedInstitutionName: [String] {
        var names: [String] = []
        names.append(contentsOf: league.conferences.map(\.name))
        names.append(contentsOf: league.divisions.map(\.name))
        for programme in programmes {
            names.append(programme.name)
            names.append(programme.nickname)
        }
        for team in proTeams {
            names.append(team.displayName)
            names.append(team.nickname)
        }
        // Looked up through the ordered member arrays rather than by iterating `identities.values`,
        // which is hash-ordered. The collision test does not care about order, but a method whose
        // output order changes per launch is a determinism trap for whatever reads it next.
        for memberID in programmes.map(\.id) + proTeams.map(\.id) {
            guard let identity = identities[memberID] else { continue }
            names.append(identity.venueName)
            names.append(contentsOf: identity.traditions.map(\.name))
        }
        return names
    }

    /// Names of *places*: map regions, map cities, and the city a member plays in.
    ///
    /// **Owner decision, 2026-08-12: real location names are permitted, generator included.** These
    /// carry only the venue and person limbs of the blocklist, because a city called Rose Bowl or
    /// Nick Saban is still wrong while a city called Columbus is now fine.
    public var everyGeneratedPlaceName: [String] {
        var names: [String] = []
        names.append(contentsOf: map.regions.map(\.name))
        names.append(contentsOf: map.cities.map(\.name))
        names.append(contentsOf: programmes.map(\.cityName))
        names.append(contentsOf: proTeams.map(\.cityName))
        return names
    }
}

/// The generated identity that hangs off a programme or team: colours, venue, traditions.
///
/// Separate from `Programme` because `04` §2.1's `team.primary`/`.secondary`/`.onTeam` are a
/// presentation concern the engine computes once and the UI reads, and because P2 generates them
/// while P1's model predates them.
public struct TeamIdentity: Codable, Sendable, Equatable {
    public let colours: ColourPair
    public let venueName: String
    public let traditions: [Tradition]
    public let homeCityID: UUID

    public init(colours: ColourPair, venueName: String, traditions: [Tradition], homeCityID: UUID) {
        self.colours = colours
        self.venueName = venueName
        self.traditions = traditions
        self.homeCityID = homeCityID
    }
}

/// Builds a whole two-tier world from one seed.
///
/// Every draw comes off a `SeededRandom` threaded explicitly, and every identity comes from
/// `rng.uuid()`. The ambient-identity source scan enforces both; this is what it enforces them for.
public enum LeagueGenerator {
    public static func generate(seed: UInt64) -> GeneratedWorld {
        var rng = SeededRandom(seed: seed)
        let leagueID = rng.uuid()

        let totalMembers = CollegeRules.programmeCount + ProRules.teamCount
        let map = GameMap.generate(cityCount: totalMembers, using: &rng)

        let conferenceSizes = collegeConferenceSizes(using: &rng)
        var archetypeAllocation = collegeArchetypeAllocation(using: &rng)
        var conferences: [Conference] = []
        var divisions: [Division] = []

        var programmes: [Programme] = []
        var identities: [UUID: TeamIdentity] = [:]
        var cityCursor = 0
        var fallbackCursor = 0
        // Donor-named venues are drawn without replacement, like place names, so no two stadiums in
        // a league share a name.
        var donorVenues = NameGrammar.distinctDonorVenueNames(using: &rng)

        // MARK: College

        for size in conferenceSizes {
            let conferenceID = rng.uuid()
            var memberIDs: [UUID] = []
            for _ in 0..<size {
                let city = map.cities[cityCursor]
                cityCursor += 1
                let archetype = Archetype.with(id: archetypeAllocation.removeLast())
                let programmeID = rng.uuid()
                // Draw order is load-bearing: the school half first, the nickname second, exactly
                // as before. The public name is now the two joined, which is how a college team is
                // named everywhere it appears -- the nickname was always generated and never shown.
                let school = NameGrammar.institutionName(
                    place: NameGrammar.cityWithoutState(city.name),
                    using: &rng
                )
                let programmeNickname = NameGrammar.nickname(using: &rng)
                programmes.append(Programme(
                    id: programmeID,
                    name: "\(school) \(programmeNickname)",
                    nickname: programmeNickname,
                    cityName: city.name,
                    conferenceID: conferenceID,
                    archetypeID: archetype.id,
                    scheme: SchemeIdentity(
                        offense: rng.pick(archetype.offensiveLean),
                        defense: rng.pick(archetype.defensiveLean)
                    ),
                    prestige: Rating(rng.int(in: archetype.prestigeFloor...archetype.prestigeCeiling)),
                    resources: jittered(archetype.resources, using: &rng),
                    fanbaseVolatility: jittered(archetype.fanbaseVolatility, using: &rng),
                    academicConstraint: jittered(archetype.academicConstraint, using: &rng),
                    recruitingReach: jittered(archetype.recruitingReach, using: &rng)
                ))
                identities[programmeID] = identity(
                    city: city, seasonWeeks: CollegeRules.seasonWeeks,
                    fallbackIndex: fallbackCursor, donorVenues: &donorVenues, using: &rng
                )
                fallbackCursor += 1
                memberIDs.append(programmeID)
            }
            conferences.append(Conference(
                id: conferenceID,
                name: NameGrammar.conferenceName(using: &rng),
                tier: .college,
                memberIDs: memberIDs
            ))
        }

        // MARK: Pro

        var proTeams: [ProTeam] = []
        for _ in 0..<ProRules.conferenceCount {
            let conferenceID = rng.uuid()
            var conferenceMembers: [UUID] = []
            var divisionIDs: [UUID] = []
            for _ in 0..<ProRules.divisionsPerConference {
                let divisionID = rng.uuid()
                var divisionMembers: [UUID] = []
                for _ in 0..<ProRules.teamsPerDivision {
                    let city = map.cities[cityCursor]
                    cityCursor += 1
                    let teamID = rng.uuid()
                    let nickname = NameGrammar.nickname(using: &rng)
                    proTeams.append(ProTeam(
                        id: teamID,
                        name: "\(NameGrammar.cityWithoutState(city.name)) \(nickname)",
                        nickname: nickname,
                        cityName: city.name,
                        conferenceID: conferenceID,
                        divisionID: divisionID,
                        scheme: SchemeIdentity(
                            offense: rng.pick(OffensiveScheme.allCases),
                            defense: rng.pick(DefensiveScheme.allCases)
                        ),
                        prestige: Rating(rng.int(in: 48...92))
                    ))
                    identities[teamID] = identity(
                        city: city, seasonWeeks: ProRules.seasonWeeks,
                        fallbackIndex: fallbackCursor, donorVenues: &donorVenues, using: &rng
                    )
                    fallbackCursor += 1
                    divisionMembers.append(teamID)
                }
                divisions.append(Division(
                    id: divisionID,
                    name: NameGrammar.divisionName(using: &rng),
                    conferenceID: conferenceID,
                    memberIDs: divisionMembers
                ))
                divisionIDs.append(divisionID)
                conferenceMembers.append(contentsOf: divisionMembers)
            }
            conferences.append(Conference(
                id: conferenceID,
                name: NameGrammar.conferenceName(using: &rng),
                tier: .pro,
                memberIDs: conferenceMembers,
                divisionIDs: divisionIDs
            ))
        }

        // MARK: Rivalries

        // Seeded within a tier only. A college programme and a pro team never meet, so a rivalry
        // between them would be a record that can never be added to.
        var rivalries: [Rivalry] = []
        rivalries.append(contentsOf: RivalrySeeder.seed(
            members: programmes.compactMap { programme in
                identities[programme.id].map(\.homeCityID).flatMap(map.city).map {
                    RivalrySeeder.Member(id: programme.id,
                                         conferenceID: programme.conferenceID,
                                         city: $0)
                }
            },
            using: &rng
        ))
        rivalries.append(contentsOf: RivalrySeeder.seed(
            members: proTeams.compactMap { team in
                identities[team.id].map(\.homeCityID).flatMap(map.city).map {
                    RivalrySeeder.Member(id: team.id,
                                         conferenceID: team.divisionID,
                                         city: $0)
                }
            },
            using: &rng
        ))

        for index in programmes.indices {
            for rivalID in RivalrySeeder.strongest(for: programmes[index].id, among: rivalries) {
                programmes[index].addRival(rivalID)
            }
        }

        CanonicalTeamBranding.apply(
            seed: seed,
            programmes: &programmes,
            proTeams: &proTeams,
            identities: &identities
        )

        return GeneratedWorld(
            league: League(id: leagueID, seed: seed, conferences: conferences, divisions: divisions),
            map: map,
            programmes: programmes,
            proTeams: proTeams,
            identities: identities,
            rivalries: rivalries
        )
    }

    /// Conference sizes that sum to exactly `CollegeRules.programmeCount` while every one stays
    /// inside `conferenceSizeRange`.
    ///
    /// `02` §11.4 leaves composition to generation deliberately, so a fixed table would make every
    /// save's map identical. This distributes the remainder rather than dividing evenly, so the
    /// sizes vary between saves and still always sum correctly — a generator that could miss the
    /// total would silently produce a league with the wrong number of programmes.
    public static func collegeConferenceSizes(using rng: inout SeededRandom) -> [Int] {
        let count = CollegeRules.conferenceCount
        let range = CollegeRules.conferenceSizeRange
        var sizes = Array(repeating: range.lowerBound, count: count)
        var remaining = CollegeRules.programmeCount - range.lowerBound * count
        // Hand out the remainder one seat at a time to a randomly chosen conference that has room.
        // Bounded by construction: `remaining` decreases on every successful placement, and the
        // caller's own rules guarantee the capacity exists (`RulesTests` asserts it).
        while remaining > 0 {
            let index = rng.int(in: 0...(count - 1))
            guard sizes[index] < range.upperBound else { continue }
            sizes[index] += 1
            remaining -= 1
        }
        return sizes
    }

    /// One archetype id per programme, balanced and then shuffled.
    ///
    /// **Allocated rather than sampled**, for two reasons the first version demonstrated.
    ///
    /// Sampling `rng.int(in: 0...13)` per programme gave a 278-to-528 spread over forty leagues,
    /// where uniform sampling predicts 383 give or take 19. The cause is a feedback loop rather
    /// than a bad generator: the number of draws a programme consumes depends on which archetype it
    /// got — prestige spans differ per archetype, and colour generation retries a variable number
    /// of times — so the archetype chosen shifts the stream position that chooses the next one.
    /// Sampling the same call in isolation is uniform to within 1.19, which is how the coupling was
    /// identified rather than blamed on the RNG.
    ///
    /// And allocation makes "every archetype appears in a league" true by construction rather than
    /// by luck, which is what stops an archetype being dead capability with a name.
    static func collegeArchetypeAllocation(using rng: inout SeededRandom) -> [Int] {
        let count = Archetype.all.count
        var allocation: [Int] = []
        for index in 0..<CollegeRules.programmeCount { allocation.append(index % count) }
        return rng.shuffled(allocation)
    }

    /// An archetype's prior, realised onto one programme.
    ///
    /// The jitter has to be small enough that a nearest-centroid classifier still recovers the
    /// archetype — D6's falsifier — and large enough that two programmes of the same archetype are
    /// not identical. `Archetype.priorVector` separation is asserted at 20 rating points across
    /// four dimensions, so plus or minus 8 on each keeps the clusters apart.
    static let priorJitter = 8

    private static func jittered(_ prior: Int, using rng: inout SeededRandom) -> Rating {
        Rating(prior + rng.int(in: -priorJitter...priorJitter))
    }

    private static func identity(
        city: MapCity,
        seasonWeeks: Int,
        fallbackIndex: Int,
        donorVenues: inout [String],
        using rng: inout SeededRandom
    ) -> TeamIdentity {
        // Half the venues are named for the place and half for a donor. The place form is unique
        // because the city is; the donor form comes off a pool drawn without replacement. Both
        // draws happen unconditionally so the coin flip does not change how much of the stream the
        // identity consumes — the coupling that made archetype sampling non-uniform earlier.
        let placeVenue = NameGrammar.venueName(place: city.name, using: &rng)
        let donorVenue = donorVenues.popLast()
        let useDonor = rng.chance(0.5)
        return TeamIdentity(
            colours: ColourGenerator.pair(using: &rng, fallbackIndex: fallbackIndex),
            venueName: (useDonor ? donorVenue : nil) ?? placeVenue,
            traditions: TraditionGrammar.traditions(regionID: city.regionID,
                                                    seasonWeeks: seasonWeeks,
                                                    using: &rng),
            homeCityID: city.id
        )
    }
}
