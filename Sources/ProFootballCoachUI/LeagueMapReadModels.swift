/// The League Map's read model (`04` section 8 family 41: place, distance, regions and rivalry
/// context).
///
/// Coordinates arrive in the engine's own integer grid units rather than in points, because the grid
/// is where distance is *comparable* — `MapCity.squaredDistance` is integer-squared precisely so the
/// comparison cannot drift across platforms. Turning grid units into points is the view's job and
/// depends on the frame it is given; doing it here would bake one viewport into the model.
public struct LeagueMapReadModel: Sendable, Equatable {
    /// The two tier words this screen filters on, held once so the provider that writes
    /// `Place.tierLabel` and the view that compares against it cannot disagree about the spelling.
    /// It lives here rather than beside the provider because the dependency runs one way: the
    /// composition layer sees the UI target, never the reverse.
    public enum Tier {
        public static let college = "College"
        public static let professional = "Professional"
    }

    public struct Region: Sendable, Equatable, Identifiable {
        public let stableID: String
        public let name: String
        /// Rating scale. The engine's only consumer is prospect population, so this is a truthful
        /// "this region produces more talent" and nothing more.
        public let talentDensity: Int

        public var id: String { stableID }

        public init(stableID: String, name: String, talentDensity: Int) {
            self.stableID = stableID
            self.name = name
            self.talentDensity = talentDensity
        }
    }

    public struct Rival: Sendable, Equatable, Identifiable {
        public let stableID: String
        public let name: String
        /// Why the rivalry exists, worded from `Rivalry.Origin` and the place's own tier. Wording
        /// an enum the engine holds states no fact the root does not — but for a professional
        /// place, a `.conference`/`.both` origin is seeded from a shared *division*, not the
        /// 16-team conference this place's own `Place.conferenceName` names, so the word used here
        /// deliberately differs from that field.
        public let originLabel: String
        public let intensity: Int
        /// Always empty in v1. The engine stores each meeting as a pre-formatted string carrying a
        /// zero-based season, which would contradict the "Season N+1" labels used everywhere else
        /// on this screen. Rendering it would put two different season numbers in one frame.
        public let notableMeetings: [String]

        public var id: String { stableID }

        public init(
            stableID: String,
            name: String,
            originLabel: String,
            intensity: Int,
            notableMeetings: [String] = []
        ) {
            self.stableID = stableID
            self.name = name
            self.originLabel = originLabel
            self.intensity = intensity
            self.notableMeetings = notableMeetings
        }
    }

    /// One conference standing, for the table the map surface carries beside it.
    ///
    /// Separate from `Place` on purpose: a place is where a programme *is*, a standing is how it is
    /// *doing*, and only some places are in the conference being tabled.
    public struct ConferenceStanding: Sendable, Equatable, Identifiable {
        public var id: String { stableID }
        public let stableID: String
        public let team: CoachWorldTeamReference
        /// `3-1`, already formatted with the en dash the copy rules ask for.
        public let conferenceRecord: String
        public let overallRecord: String
        /// Points for minus points against. Signed, and the sign is the point of it.
        public let pointDifferential: Int
        public let isControlled: Bool

        public init(
            stableID: String,
            team: CoachWorldTeamReference,
            conferenceRecord: String,
            overallRecord: String,
            pointDifferential: Int,
            isControlled: Bool
        ) {
            self.stableID = stableID
            self.team = team
            self.conferenceRecord = conferenceRecord
            self.overallRecord = overallRecord
            self.pointDifferential = pointDifferential
            self.isControlled = isControlled
        }
    }

    public struct Place: Sendable, Equatable, Identifiable {
        public let stableID: String
        public let team: CoachWorldTeamReference
        public let cityName: String
        public let regionID: String
        public let regionName: String
        public let conferenceName: String?
        public let tierLabel: String
        public let isControlled: Bool
        public let x: Int
        public let y: Int
        public let marketSize: Int
        public let prestige: Int
        public let venueName: String
        public let rivals: [Rival]
        /// Always nil. `Programme.recruitingReach` exists on the model but no engine system reads
        /// it, so there is no grid-unit mapping to draw a radius from and any circle would be an
        /// invented fact under `04` section 4.4.
        public let reachRadius: Int?

        public var id: String { stableID }

        public init(
            stableID: String,
            team: CoachWorldTeamReference,
            cityName: String,
            regionID: String,
            regionName: String,
            conferenceName: String?,
            tierLabel: String,
            isControlled: Bool,
            x: Int,
            y: Int,
            marketSize: Int,
            prestige: Int,
            venueName: String,
            rivals: [Rival],
            reachRadius: Int? = nil
        ) {
            self.stableID = stableID
            self.team = team
            self.cityName = cityName
            self.regionID = regionID
            self.regionName = regionName
            self.conferenceName = conferenceName
            self.tierLabel = tierLabel
            self.isControlled = isControlled
            self.x = x
            self.y = y
            self.marketSize = marketSize
            self.prestige = prestige
            self.venueName = venueName
            self.rivals = rivals
            self.reachRadius = reachRadius
        }
    }

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let world: CoachWorldReference
    public let team: CoachWorldTeamReference
    public let coach: CoachWorldPersonReference
    public let seasonLabel: String
    public let weekLabel: String
    public let recordLabel: String
    public let rankLabel: String?
    public let gridWidth: Int
    public let gridHeight: Int
    public let regions: [Region]
    public let places: [Place]
    /// The coach's own conference, as a table. Empty when the programme has no conference or no
    /// results yet — an empty table is honest, a table of zeroes is not.
    public let conferenceStandings: [ConferenceStanding]
    public let conferenceName: String?

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        world: CoachWorldReference,
        team: CoachWorldTeamReference,
        coach: CoachWorldPersonReference,
        seasonLabel: String,
        weekLabel: String,
        recordLabel: String,
        rankLabel: String?,
        gridWidth: Int,
        gridHeight: Int,
        regions: [Region],
        places: [Place],
        conferenceStandings: [ConferenceStanding] = [],
        conferenceName: String? = nil
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.world = world
        self.team = team
        self.coach = coach
        self.seasonLabel = seasonLabel
        self.weekLabel = weekLabel
        self.recordLabel = recordLabel
        self.rankLabel = rankLabel
        self.gridWidth = gridWidth
        self.gridHeight = gridHeight
        self.regions = regions
        self.places = places
        self.conferenceStandings = conferenceStandings
        self.conferenceName = conferenceName
    }
}

#if DEBUG
/// The DEBUG proof fixture. `provenance: .sample` is what the "SAMPLE CAREER" flag reads, and a
/// fixture must never claim to be a snapshot. The cast is the one `04` section 10 fixes for every
/// proof: Carson Tech, head coach Eric Mercer, Week 9, Southern State as the current opponent.
///
/// Every place and venue name here is generated-grammar shaped rather than borrowed, per the legal
/// guardrail: the 2026-08-12 fixture defect was real hometowns typed into source, which the
/// generated-name sweep could not see because it enumerates what the generator emits.
public enum CoachWorldLeagueMapSampleData {
    public static let leagueMap = LeagueMapReadModel(
        snapshotID: "map-sample",
        provenance: .sample,
        world: CoachWorldReference(stableID: "world-sample", name: "Football Universe"),
        team: CoachWorldTeamReference(
            stableID: "00000000-0000-4000-8000-000000000001",
            name: "Carson Tech",
            abbreviation: "CAR",
            primaryColorHex: "2F6DB5",
            secondaryColorHex: "E8B23A"
        ),
        coach: CoachWorldPersonReference(
            stableID: "coach-mercer",
            name: "Eric Mercer",
            role: "Head Coach"
        ),
        seasonLabel: "Season 1",
        weekLabel: "Week 9",
        recordLabel: "6-2",
        rankLabel: "#18",
        gridWidth: 1000,
        gridHeight: 700,
        regions: [
            LeagueMapReadModel.Region(
                stableID: "region-north",
                name: "Kessel Reach",
                talentDensity: 71
            ),
            LeagueMapReadModel.Region(
                stableID: "region-south",
                name: "Marlow Basin",
                talentDensity: 84
            ),
        ],
        places: [
            LeagueMapReadModel.Place(
                stableID: "00000000-0000-4000-8000-000000000001",
                team: CoachWorldTeamReference(
                    stableID: "00000000-0000-4000-8000-000000000001",
                    name: "Carson Tech",
                    abbreviation: "CAR",
                    primaryColorHex: "2F6DB5",
                    secondaryColorHex: "E8B23A"
                ),
                cityName: "Carson Hollow",
                regionID: "region-north",
                regionName: "Kessel Reach",
                conferenceName: "Northern Reach Conference",
                tierLabel: "College",
                isControlled: true,
                x: 320,
                y: 240,
                marketSize: 62,
                prestige: 68,
                venueName: "Carson Hollow Grounds",
                rivals: [
                    LeagueMapReadModel.Rival(
                        stableID: "00000000-0000-4000-8000-000000000002",
                        name: "Southern State",
                        originLabel: "Conference neighbours",
                        intensity: 78
                    ),
                ]
            ),
            LeagueMapReadModel.Place(
                stableID: "00000000-0000-4000-8000-000000000002",
                team: CoachWorldTeamReference(
                    stableID: "00000000-0000-4000-8000-000000000002",
                    name: "Southern State",
                    abbreviation: "SOU",
                    primaryColorHex: "8E3B4F",
                    secondaryColorHex: "D9D2C4"
                ),
                cityName: "Marlow Flats",
                regionID: "region-south",
                regionName: "Marlow Basin",
                conferenceName: "Northern Reach Conference",
                tierLabel: "College",
                isControlled: false,
                x: 470,
                y: 430,
                marketSize: 74,
                prestige: 81,
                venueName: "Marlow Flats Field",
                rivals: [
                    LeagueMapReadModel.Rival(
                        stableID: "00000000-0000-4000-8000-000000000001",
                        name: "Carson Tech",
                        originLabel: "Conference neighbours",
                        intensity: 78
                    ),
                ]
            ),
        ],
        conferenceStandings: [
            .init(stableID: "cs-1", team: CoachWorldTeamReference(
                stableID: "team-halloran", name: "Halloran Tech", abbreviation: "HAL"),
                conferenceRecord: "4\u{2013}0", overallRecord: "5\u{2013}1",
                pointDifferential: 82, isControlled: false),
            .init(stableID: "cs-2", team: CoachWorldTeamReference(
                stableID: "team-cobalt", name: "Cobalt Valley", abbreviation: "COB"),
                conferenceRecord: "3\u{2013}1", overallRecord: "5\u{2013}2",
                pointDifferential: 51, isControlled: false),
            .init(stableID: "cs-3", team: CoachWorldTeamReference(
                stableID: "00000000-0000-4000-8000-000000000001", name: "Carson Tech", abbreviation: "CAR"),
                conferenceRecord: "3\u{2013}1", overallRecord: "4\u{2013}2",
                pointDifferential: 34, isControlled: true),
            .init(stableID: "cs-4", team: CoachWorldTeamReference(
                stableID: "team-ellenwood", name: "Ellenwood", abbreviation: "ELL"),
                conferenceRecord: "3\u{2013}2", overallRecord: "4\u{2013}3",
                pointDifferential: 19, isControlled: false),
            .init(stableID: "cs-5", team: CoachWorldTeamReference(
                stableID: "team-cedar", name: "Cedar Falls", abbreviation: "CED"),
                conferenceRecord: "2\u{2013}3", overallRecord: "3\u{2013}4",
                pointDifferential: -12, isControlled: false),
            .init(stableID: "cs-6", team: CoachWorldTeamReference(
                stableID: "team-marchmont", name: "Marchmont", abbreviation: "MAR"),
                conferenceRecord: "1\u{2013}3", overallRecord: "2\u{2013}5",
                pointDifferential: -47, isControlled: false),
        ],
        conferenceName: "Northern Reach Conference"
    )
}
#endif
