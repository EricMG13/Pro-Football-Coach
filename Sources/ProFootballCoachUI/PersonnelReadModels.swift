public struct PlayerProfileReadModel: Identifiable, Sendable, Equatable {
    public struct Attribute: Identifiable, Sendable, Equatable {
        public let stableID: String
        public let label: String
        public let value: Int
        public let confidence: String
        public var id: String { stableID }

        public init(stableID: String, label: String, value: Int, confidence: String) {
            self.stableID = stableID
            self.label = label
            self.value = value
            self.confidence = confidence
        }
    }

    public struct AttributeGroup: Identifiable, Sendable, Equatable {
        public let stableID: String
        public let title: String
        public let attributes: [Attribute]
        public var id: String { stableID }

        public init(stableID: String, title: String, attributes: [Attribute]) {
            self.stableID = stableID
            self.title = title
            self.attributes = attributes
        }
    }

    public struct FormEntry: Identifiable, Sendable, Equatable {
        public let stableID: String
        public let opponent: String
        public let rating: Int
        public var id: String { stableID }

        public init(stableID: String, opponent: String, rating: Int) {
            self.stableID = stableID
            self.opponent = opponent
            self.rating = rating
        }
    }

    public let stableID: String
    public let person: CoachWorldPersonReference
    public let number: Int
    public let position: String
    /// The player's overall rating, on the 40-99 scale `04` section 6 states. The roster row that
    /// owns this profile already carries it; the profile carries it too so the dial has a figure
    /// rather than one assembled from the attribute groups, which would be a second opinion.
    public let overall: Int
    public let academicYear: String
    public let hometown: String
    public let rosterRole: String
    public let availability: String
    public let condition: Int
    public let schemeFit: String
    public let staffSummary: String
    public let strengths: [String]
    public let concern: String
    public let attributeGroups: [AttributeGroup]
    public let recentForm: [FormEntry]
    /// Bounded, source-backed evidence for the profile's development and history routes.
    /// These are presentation projections, not a second authority or persisted narrative.
    public let developmentEvidence: String
    public let historyEvidence: String
    public var id: String { stableID }

    public init(
        stableID: String,
        person: CoachWorldPersonReference,
        number: Int,
        position: String,
        overall: Int,
        academicYear: String,
        hometown: String,
        rosterRole: String,
        availability: String,
        condition: Int,
        schemeFit: String,
        staffSummary: String,
        strengths: [String],
        concern: String,
        attributeGroups: [AttributeGroup],
        recentForm: [FormEntry],
        developmentEvidence: String = "",
        historyEvidence: String = ""
    ) {
        self.stableID = stableID
        self.person = person
        self.number = number
        self.position = position
        self.overall = min(99, max(0, overall))
        self.academicYear = academicYear
        self.hometown = hometown
        self.rosterRole = rosterRole
        self.availability = availability
        self.condition = condition
        self.schemeFit = schemeFit
        self.staffSummary = staffSummary
        self.strengths = strengths
        self.concern = concern
        self.attributeGroups = attributeGroups
        self.recentForm = recentForm
        self.developmentEvidence = developmentEvidence
        self.historyEvidence = historyEvidence
    }
}

public struct RosterFeedbackReadModel: Sendable, Equatable {
    public let message: String

    public init(message: String) {
        self.message = message
    }
}

public struct RosterReadModel: Sendable, Equatable {
    public struct PlayerRow: Identifiable, Sendable, Equatable {
        public let stableID: String
        public let person: CoachWorldPersonReference
        public let number: Int
        public let position: String
        public let academicYear: String
        public let rosterRole: String
        public let overall: Int
        /// Legacy numeric slot retained for sample compatibility; production uses the bounded
        /// `developmentDelta` evidence instead of exposing a fake 0–99 development rating.
        public let development: Int
        public let developmentDelta: Int?
        public let schemeFit: String
        public let condition: Int
        public let availability: String
        public let profile: PlayerProfileReadModel
        public var id: String { stableID }

        public init(stableID: String, person: CoachWorldPersonReference, number: Int, position: String, academicYear: String, rosterRole: String, overall: Int, development: Int, schemeFit: String, condition: Int, availability: String, profile: PlayerProfileReadModel, developmentDelta: Int? = nil) {
            self.stableID = stableID
            self.person = person
            self.number = number
            self.position = position
            self.academicYear = academicYear
            self.rosterRole = rosterRole
            self.overall = overall
            self.development = development
            self.developmentDelta = developmentDelta
            self.schemeFit = schemeFit
            self.condition = condition
            self.availability = availability
            self.profile = profile
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
    public let rosterLimit: Int
    public let injuryCount: Int
    public let openNeedCount: Int
    public let players: [PlayerRow]
    public let canContinue: Bool
    public let continueReason: String?

    public init(snapshotID: String, provenance: CoachWorldDataProvenance, world: CoachWorldReference, team: CoachWorldTeamReference, coach: CoachWorldPersonReference, seasonLabel: String, weekLabel: String, recordLabel: String, rankLabel: String?, rosterLimit: Int, injuryCount: Int, openNeedCount: Int, players: [PlayerRow], canContinue: Bool = true, continueReason: String? = nil) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.world = world
        self.team = team
        self.coach = coach
        self.seasonLabel = seasonLabel
        self.weekLabel = weekLabel
        self.recordLabel = recordLabel
        self.rankLabel = rankLabel
        self.rosterLimit = rosterLimit
        self.injuryCount = injuryCount
        self.openNeedCount = openNeedCount
        self.players = players
        self.canContinue = canContinue
        self.continueReason = continueReason
    }
}

public enum RosterSortField: String, CaseIterable, Sendable, Equatable {
    case number, name, position, overall, development, condition
}

public struct RosterSortDescriptor: Sendable, Equatable {
    public let field: RosterSortField
    public let isAscending: Bool

    public init(field: RosterSortField, isAscending: Bool) {
        self.field = field
        self.isAscending = isAscending
    }

    public func sorted(_ players: [RosterReadModel.PlayerRow]) -> [RosterReadModel.PlayerRow] {
        players.sorted { lhs, rhs in
            switch field {
            case .number:
                if lhs.number == rhs.number { return lhs.stableID < rhs.stableID }
                return isAscending ? lhs.number < rhs.number : lhs.number > rhs.number
            case .name:
                if lhs.person.name == rhs.person.name { return lhs.stableID < rhs.stableID }
                return isAscending ? lhs.person.name < rhs.person.name : lhs.person.name > rhs.person.name
            case .position:
                if lhs.position == rhs.position { return lhs.stableID < rhs.stableID }
                return isAscending ? lhs.position < rhs.position : lhs.position > rhs.position
            case .overall:
                if lhs.overall == rhs.overall { return lhs.stableID < rhs.stableID }
                return isAscending ? lhs.overall < rhs.overall : lhs.overall > rhs.overall
            case .development:
                let lhsDelta = lhs.developmentDelta ?? 0
                let rhsDelta = rhs.developmentDelta ?? 0
                if lhsDelta == rhsDelta { return lhs.stableID < rhs.stableID }
                return isAscending ? lhsDelta < rhsDelta : lhsDelta > rhsDelta
            case .condition:
                if lhs.condition == rhs.condition { return lhs.stableID < rhs.stableID }
                return isAscending ? lhs.condition < rhs.condition : lhs.condition > rhs.condition
            }
        }
    }
}

#if DEBUG
public extension CoachWorldSampleData {
    static let roster: RosterReadModel = {
        func makePlayer(id: String, number: Int, name: String, position: String, year: String, role: String, overall: Int, development: Int, developmentDelta: Int, fit: String, condition: Int, availability: String, hometown: String, strengths: [String], concern: String, summary: String, athletic: [Int], technical: [Int], mental: [Int], form: [Int]) -> RosterReadModel.PlayerRow {
            let person = CoachWorldPersonReference(stableID: "\(id)-person", name: name, role: position)
            func group(_ key: String, _ title: String, _ labels: [String], _ values: [Int]) -> PlayerProfileReadModel.AttributeGroup {
                .init(stableID: "\(id)-\(key)", title: title, attributes: zip(labels, values).enumerated().map { index, pair in
                    .init(stableID: "\(id)-\(key)-\(index)", label: pair.0, value: pair.1, confidence: "Known")
                })
            }
            let profile = PlayerProfileReadModel(stableID: "\(id)-profile", person: person, number: number, position: position, overall: overall, academicYear: year, hometown: hometown, rosterRole: role, availability: availability, condition: condition, schemeFit: fit, staffSummary: summary, strengths: strengths, concern: concern, attributeGroups: [
                group("athletic", "Athletic", ["Speed", "Strength", "Stamina"], athletic),
                group("technical", "Technical", ["Technique", "Position Skill", "Ball Security"], technical),
                group("mental", "Mental", ["Decisions", "Awareness", "Leadership"], mental),
            ], recentForm: zip(["SOU", "WST", "MET"], form).enumerated().map { index, pair in
                .init(stableID: "\(id)-form-\(index)", opponent: pair.0, rating: pair.1)
            })
            return .init(stableID: id, person: person, number: number, position: position, academicYear: year, rosterRole: role, overall: overall, development: development, schemeFit: fit, condition: condition, availability: availability, profile: profile, developmentDelta: developmentDelta)
        }

        return RosterReadModel(snapshotID: "sample-roster-snapshot", provenance: .sample, world: world, team: homeTeam, coach: headCoach, seasonLabel: "2027 season", weekLabel: "Week 9", recordLabel: "6–2", rankLabel: "#19", rosterLimit: 85, injuryCount: 2, openNeedCount: 3, players: [
            makePlayer(id: "sample-roster-bishop", number: 12, name: "Andre Bishop", position: "QB", year: "SR", role: "Captain · Starter", overall: 91, development: 78, developmentDelta: 1, fit: "Elite", condition: 96, availability: "Available", hometown: "Calder Springs, Thornby Reach", strengths: ["Deep accuracy", "Pressure control"], concern: "Late movement can hold the ball too long", summary: "Commands the offense and protects high-leverage downs.", athletic: [82, 76, 88], technical: [92, 94, 89], mental: [91, 93, 90], form: [88, 91, 86]),
            makePlayer(id: "sample-roster-ward", number: 24, name: "Jalen Ward", position: "RB", year: "JR", role: "Starter", overall: 88, development: 86, developmentDelta: 0, fit: "Strong", condition: 91, availability: "Available", hometown: "Marrow Bend, Fenmark Flats", strengths: ["Contact balance", "Cut timing"], concern: "Pass protection remains inconsistent", summary: "Creates efficient early downs without wasting carries.", athletic: [91, 87, 90], technical: [86, 90, 84], mental: [85, 87, 79], form: [90, 84, 89]),
            makePlayer(id: "sample-roster-okafor", number: 6, name: "Miles Okafor", position: "WR", year: "SO", role: "Rotation", overall: 84, development: 92, developmentDelta: 1, fit: "Strong", condition: 100, availability: "Available", hometown: "Harrow Landing, Redmoor Coast", strengths: ["Release burst", "Open-field acceleration"], concern: "Boundary route detail is unfinished", summary: "The highest-upside receiver on the roster.", athletic: [94, 72, 86], technical: [83, 85, 80], mental: [79, 82, 68], form: [82, 87, 80]),
            makePlayer(id: "sample-roster-alvarez", number: 72, name: "Tomas Alvarez", position: "OT", year: "SR", role: "Starter", overall: 87, development: 74, developmentDelta: -1, fit: "Elite", condition: 88, availability: "Limited", hometown: "Pellham Mills, Dunmore Basin", strengths: ["Pass anchor", "Length"], concern: "Ankle limits lateral recovery", summary: "Reliable blind-side protection when healthy.", athletic: [76, 93, 82], technical: [90, 91, 88], mental: [86, 89, 84], form: [85, 88, 83]),
            makePlayer(id: "sample-roster-webb", number: 87, name: "Darius Webb", position: "EDGE", year: "JR", role: "Starter", overall: 89, development: 88, developmentDelta: 1, fit: "Elite", condition: 94, availability: "Available", hometown: "Larkin Crossing, Gallow Uplands", strengths: ["First step", "Counter timing"], concern: "Can lose run leverage chasing pressure", summary: "Changes passing downs and forces protection help.", athletic: [93, 86, 89], technical: [88, 92, 81], mental: [84, 86, 78], form: [92, 89, 90]),
            makePlayer(id: "sample-roster-reed", number: 55, name: "Marcus Reed", position: "MLB", year: "SR", role: "Captain · Starter", overall: 90, development: 76, developmentDelta: 0, fit: "Strong", condition: 97, availability: "Available", hometown: "Oakhaven Bluff, Netherby Divide", strengths: ["Run fits", "Communication"], concern: "Man coverage range is ordinary", summary: "Sets the front and prevents alignment errors.", athletic: [84, 89, 91], technical: [87, 90, 82], mental: [94, 95, 93], form: [89, 90, 91]),
            makePlayer(id: "sample-roster-brooks", number: 9, name: "Elijah Brooks", position: "CB", year: "SO", role: "Nickel", overall: 82, development: 94, developmentDelta: 1, fit: "Good", condition: 99, availability: "Available", hometown: "Wexford Harbor, Yarrow Tidelands", strengths: ["Press timing", "Recovery speed"], concern: "Route recognition varies snap to snap", summary: "Already playable inside with outside-corner upside.", athletic: [95, 70, 87], technical: [82, 84, 79], mental: [76, 78, 71], form: [81, 85, 83]),
        ])
    }()
}
#endif
