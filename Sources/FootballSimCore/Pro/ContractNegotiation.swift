import Foundation

/// What a club is offering. `02` §4.2d.
public struct ContractOffer: Sendable, Equatable, Identifiable {
    public var id: UUID { teamID }
    public let teamID: UUID
    public let contract: Contract
    /// The club's standing, which a player weighs alongside the money.
    public let prestige: Rating

    public init(teamID: UUID, contract: Contract, prestige: Rating) {
        self.teamID = teamID
        self.contract = contract
        self.prestige = prestige
    }
}

/// What a player wants, and which offer they take. `02` §4.2d.
///
/// `02` §4.2 sells free agency as "waves, with competing bidders and a market that reprices as it
/// moves" and there was **no negotiation at all**: `acquire` and `signFreeAgent` took a
/// fully-formed `Contract` and applied it, so a club could sign anybody for the league minimum and
/// nothing in the game would object. There was no asking price, no competing bid, and no way for a
/// player to prefer one club to another.
///
/// Pure functions over values, deliberately. A negotiation that mutated state could not be shown to
/// a coach *before* they committed to it, and the whole point of an asking price is that you see it
/// first.
///
/// **Every figure is a share of the cap.** The reason is in `ProRules.basisPointScale`: the cap
/// compounds, so a price in fixed dollars decays to nothing over a career. This is the same
/// mistake as the seed-from-`hashValue` defect in that no in-process test would ever see it — a
/// single season's tests pass at every value, and the market quietly dies in season twelve.
public enum ContractNegotiation {
    /// What this player is asking for.
    ///
    /// Rating-derived, and cap-relative, like every other money number in this project (`02` §4.2a's
    /// bootstrap contracts, §10's wages), because a price that ignored ability would make the
    /// market a formality. Age shortens the *term* rather than cutting the rate: a thirty-four-year
    /// old asks for what they are worth, for fewer years.
    public static func askingPrice(for player: Player, season: Int) -> Contract {
        let seasons = ProRules.seasonsAfterBase(season)
        let above = Swift.max(0, player.overall.value - ProRules.replacementRating)
        let annual = ProRules.minimumSalary(seasonsAfterBase: seasons)
            + ProRules.capShare(
                basisPoints: above * ProRules.askingBasisPointsPerRatingPoint,
                seasonsAfterBase: seasons
            )
        let years = requestedYears(for: player)
        return Contract(
            years: years,
            baseSalaryByYear: Array(repeating: annual, count: years),
            signingBonus: annual * ProRules.signingBonusPercent / 100,
            signedSeason: season
        )
    }

    /// How many years they want. Long deals for players with a future, short ones past the decline
    /// age — which is the same age table `02` §11.3.2 fixes, read here rather than re-invented.
    public static func requestedYears(for player: Player) -> Int {
        if player.isDeclining { return ProRules.decliningContractYears }
        if player.age <= ProRules.youngPlayerAge { return ProRules.youngContractYears }
        return ProRules.primeContractYears
    }

    /// What an offer is worth to this player, in the same units for every offer so they can be
    /// compared: every dollar of the deal, plus what the club's standing is worth to them.
    ///
    /// Prestige is worth real money here rather than being a tiebreak, because a player taking less
    /// to join a contender is one of the few things everybody knows about this market.
    public static func value(of offer: ContractOffer, to player: Player, season: Int) -> Int {
        let seasons = ProRules.seasonsAfterBase(season)
        let standing = ProRules.capShare(
            basisPoints: (offer.prestige.value - SharedRules.ratingRange.lowerBound)
                * ProRules.prestigeValueBasisPointsPerPoint,
            seasonsAfterBase: seasons
        )
        // A deal shorter than they asked for is worth less than its money says, because it puts
        // them back on the market sooner than they wanted. A longer one is not worth more: nobody
        // in this game has ever complained about being paid for an extra year.
        let shortfall = Swift.max(0, requestedYears(for: player) - offer.contract.years)
        let penalty = ProRules.capShare(
            basisPoints: shortfall * ProRules.shortTermPenaltyBasisPoints,
            seasonsAfterBase: seasons
        )
        return offer.contract.totalValue + standing - penalty
    }

    /// Whether this offer clears what the player is asking for.
    ///
    /// Money against money — standing does not buy a discount below the asking price, it only wins
    /// a tie between offers that already clear it. A club that could underpay by being famous would
    /// make the biggest club in the league permanently the cheapest, which is the opposite of the
    /// pressure `02` §4.2 wants on a good team.
    public static func meetsAskingPrice(_ offer: ContractOffer, player: Player, season: Int) -> Bool {
        offer.contract.totalValue >= askingPrice(for: player, season: season).totalValue
    }

    /// Which offer the player takes, or nil when none of them is worth taking.
    ///
    /// Deterministic: ties break on the club identifier, so the same market resolves the same way in
    /// every process. A player with no acceptable offer signs nothing, which is what makes an
    /// asking price mean something.
    public static func choose(
        from offers: [ContractOffer],
        player: Player,
        season: Int
    ) -> ContractOffer? {
        let acceptable = offers.filter { meetsAskingPrice($0, player: player, season: season) }
        guard !acceptable.isEmpty else { return nil }
        return acceptable.max { lhs, rhs in
            let lhsValue = value(of: lhs, to: player, season: season)
            let rhsValue = value(of: rhs, to: player, season: season)
            return lhsValue == rhsValue
                ? lhs.teamID.uuidString > rhs.teamID.uuidString
                : lhsValue < rhsValue
        }
    }
}
