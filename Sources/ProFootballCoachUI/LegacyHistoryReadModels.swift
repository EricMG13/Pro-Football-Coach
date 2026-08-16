import FootballSimCore

/// One bounded projection for the four durable-history families. The engine's archive, rivalry,
/// staff-career and record-book values remain authoritative; this type only gives the routes one
/// stable, renderable shape.
public struct LegacyHistoryReadModel: Sendable, Equatable {
    public struct Record: Sendable, Equatable, Identifiable {
        public let id: String
        public let title: String
        public let value: Int
        public let team: CoachWorldTeamReference
        public let opponent: CoachWorldTeamReference
        public let gameLabel: String

        public init(id: String, title: String, value: Int, team: CoachWorldTeamReference,
                    opponent: CoachWorldTeamReference, gameLabel: String) {
            self.id = id
            self.title = title
            self.value = value
            self.team = team
            self.opponent = opponent
            self.gameLabel = gameLabel
        }
    }

    public struct Rivalry: Sendable, Equatable, Identifiable {
        public let id: String
        public let opponent: CoachWorldTeamReference
        public let origin: String
        public let intensity: Int
        public let meetings: [String]

        public init(id: String, opponent: CoachWorldTeamReference, origin: String,
                    intensity: Int, meetings: [String]) {
            self.id = id
            self.opponent = opponent
            self.origin = origin
            self.intensity = intensity
            self.meetings = meetings
        }
    }

    public struct CareerEntry: Sendable, Equatable, Identifiable {
        public let id: String
        public let season: Int
        public let organisation: CoachWorldTeamReference
        public let role: String

        public init(id: String, season: Int, organisation: CoachWorldTeamReference, role: String) {
            self.id = id
            self.season = season
            self.organisation = organisation
            self.role = role
        }
    }

    public struct TreeBranch: Sendable, Equatable, Identifiable {
        public let id: String
        public let mentorName: String
        public let disciples: [String]

        public init(id: String, mentorName: String, disciples: [String]) {
            self.id = id
            self.mentorName = mentorName
            self.disciples = disciples
        }
    }

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let team: CoachWorldTeamReference
    public let seasonLabel: String
    public let records: [Record]
    public let rivalries: [Rivalry]
    public let careerLine: [CareerEntry]
    public let coachingTree: [TreeBranch]

    public init(snapshotID: String, provenance: CoachWorldDataProvenance,
                team: CoachWorldTeamReference, seasonLabel: String, records: [Record],
                rivalries: [Rivalry], careerLine: [CareerEntry], coachingTree: [TreeBranch]) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.team = team
        self.seasonLabel = seasonLabel
        self.records = Array(records.prefix(8))
        self.rivalries = Array(rivalries.prefix(8))
        self.careerLine = Array(careerLine.sorted { $0.season == $1.season ? $0.id < $1.id : $0.season < $1.season }.prefix(64))
        self.coachingTree = Array(coachingTree.prefix(256))
    }
}
