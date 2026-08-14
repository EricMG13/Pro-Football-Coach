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

    /// What this club earns and has built. `02` §10. Optional for the same reason a programme's is:
    /// an additive optional is the only shape that does not strand a save written before money.
    public var finances: OrganisationFinances?

    public var rosterIDs: [UUID]
    public var practiceSquadIDs: [UUID]
    public var staffIDs: [UUID]

    /// Charged against the cap for players no longer on the roster. P8 owns how it gets here;
    /// `Contract.deadMoney(ifReleasedBeforeYear:)` owns how much.
    public var deadMoney: Int

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
        deadMoney: Int = 0,
        finances: OrganisationFinances? = nil
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
        self.finances = finances
    }

    /// The finances this club has, or the ones its standing implies. Nil means "not generated yet",
    /// never "broke".
    public func finances(defaultingFor tier: Tier = .pro) -> OrganisationFinances {
        finances ?? OrganisationFinances(
            facilities: prestige,
            reserves: OrganisationFinances.annualRevenue(prestige: prestige, tier: tier)
                / FinanceRules.openingReserveShare
        )
    }

    public var rosterLegality: RosterLegality {
        RosterLegality.pro(active: rosterIDs.count, practiceSquad: practiceSquadIDs.count)
    }
}
