import Foundation

/// A pro team.
public struct ProTeam: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public var name: String
    public var nickname: String
    public var cityName: String
    public var conferenceID: UUID?
    public var divisionID: UUID?

    public var scheme: SchemeIdentity
    public var prestige: Rating

    public var rosterIDs: [UUID]
    public var practiceSquadIDs: [UUID]
    public var staffIDs: [UUID]

    /// Charged against the cap for players no longer on the roster. P8 owns how it gets here;
    /// `Contract.deadMoney(ifReleasedBeforeYear:)` owns how much.
    public var deadMoney: Int

    /// Public team name used by read models. Older saves stored only the market in `name`; keeping
    /// this compatibility projection avoids a migration while new worlds store the full
    /// location-plus-nickname form.
    public var displayName: String {
        name == cityName ? "\(cityName) \(nickname)" : name
    }

    public init(
        id: UUID = UUID(),
        name: String,
        nickname: String,
        cityName: String,
        conferenceID: UUID? = nil,
        divisionID: UUID? = nil,
        scheme: SchemeIdentity,
        prestige: Rating,
        rosterIDs: [UUID] = [],
        practiceSquadIDs: [UUID] = [],
        staffIDs: [UUID] = [],
        deadMoney: Int = 0
    ) {
        self.id = id
        self.name = name
        self.nickname = nickname
        self.cityName = cityName
        self.conferenceID = conferenceID
        self.divisionID = divisionID
        self.scheme = scheme
        self.prestige = prestige
        self.rosterIDs = rosterIDs
        self.practiceSquadIDs = practiceSquadIDs
        self.staffIDs = staffIDs
        self.deadMoney = deadMoney
    }

    public var rosterLegality: RosterLegality {
        RosterLegality.pro(active: rosterIDs.count, practiceSquad: practiceSquadIDs.count)
    }
}
