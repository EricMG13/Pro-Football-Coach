import FootballSimCore

public struct StatisticsLeadersReadModel: Sendable, Equatable {
    public struct Row: Sendable, Equatable, Identifiable {
        public let id: String
        public let category: String
        public let player: CoachWorldPersonReference
        public let team: CoachWorldTeamReference
        public let value: Int
        public let seasonLabel: String

        public init(id: String, category: String, player: CoachWorldPersonReference,
                    team: CoachWorldTeamReference, value: Int, seasonLabel: String) {
            self.id = id; self.category = category; self.player = player
            self.team = team; self.value = value; self.seasonLabel = seasonLabel
        }
    }

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let seasonLabel: String
    public let weekLabel: String
    public let rows: [Row]

    public init(snapshotID: String, provenance: CoachWorldDataProvenance, seasonLabel: String,
                weekLabel: String, rows: [Row]) {
        self.snapshotID = snapshotID; self.provenance = provenance
        self.seasonLabel = seasonLabel; self.weekLabel = weekLabel
        self.rows = Array(rows.prefix(32))
    }
}

public struct AwardsHonoursReadModel: Sendable, Equatable {
    public struct Award: Sendable, Equatable, Identifiable {
        public let id: String
        public let title: String
        public let winner: String
        public let tier: String
        public let value: Int
        public let seasonLabel: String

        public init(id: String, title: String, winner: String, tier: String, value: Int,
                    seasonLabel: String) {
            self.id = id; self.title = title; self.winner = winner
            self.tier = tier; self.value = value; self.seasonLabel = seasonLabel
        }
    }

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let awards: [Award]

    public init(snapshotID: String, provenance: CoachWorldDataProvenance, awards: [Award]) {
        self.snapshotID = snapshotID; self.provenance = provenance
        self.awards = Array(awards.prefix(64))
    }
}
