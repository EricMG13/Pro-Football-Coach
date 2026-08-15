public struct StartingJobReadModel: Identifiable, Sendable, Equatable {
    public let stableID: String
    public let programme: CoachWorldTeamReference
    public let cityName: String
    public let prestige: Int
    public let resources: Int
    public let archetype: String
    public let expectation: String

    public var id: String { stableID }

    public init(
        stableID: String,
        programme: CoachWorldTeamReference,
        cityName: String,
        prestige: Int,
        resources: Int,
        archetype: String,
        expectation: String
    ) {
        self.stableID = stableID
        self.programme = programme
        self.cityName = cityName
        self.prestige = prestige
        self.resources = resources
        self.archetype = archetype
        self.expectation = expectation
    }
}
