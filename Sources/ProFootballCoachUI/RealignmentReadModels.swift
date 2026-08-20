import FootballSimCore

public struct RealignmentReadModel: Sendable, Equatable {
    public struct Swap: Sendable, Equatable, Identifiable {
        public let id: String
        public let firstProgramme: String
        public let secondProgramme: String
        public let firstFrom: String
        public let firstTo: String
        public let secondFrom: String
        public let secondTo: String

        public init(id: String, firstProgramme: String, secondProgramme: String,
                    firstFrom: String, firstTo: String, secondFrom: String, secondTo: String) {
            self.id = id; self.firstProgramme = firstProgramme; self.secondProgramme = secondProgramme
            self.firstFrom = firstFrom; self.firstTo = firstTo
            self.secondFrom = secondFrom; self.secondTo = secondTo
        }
    }

    public struct Event: Sendable, Equatable, Identifiable {
        public let id: String
        public let seasonLabel: String
        public let reason: String
        public let swaps: [Swap]

        public init(id: String, seasonLabel: String, reason: String, swaps: [Swap]) {
            self.id = id; self.seasonLabel = seasonLabel; self.reason = reason
            self.swaps = Array(swaps.prefix(2))
        }
    }

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let currentSeasonLabel: String
    public let event: Event?

    public init(snapshotID: String, provenance: CoachWorldDataProvenance,
                currentSeasonLabel: String, event: Event?) {
        self.snapshotID = snapshotID; self.provenance = provenance
        self.currentSeasonLabel = currentSeasonLabel; self.event = event
    }
}
