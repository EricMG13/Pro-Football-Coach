import Foundation

/// A future draft selection a team owns and can trade.
public struct DraftPick: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public let year: Int
    public let round: Int
    /// The team whose record determines where this pick lands.
    public let originalTeamID: UUID
    /// Who currently holds it.
    public var ownerTeamID: UUID

    public init(
        id: UUID = UUID(),
        year: Int,
        round: Int,
        originalTeamID: UUID,
        ownerTeamID: UUID
    ) {
        self.id = id
        self.year = year
        self.round = round
        self.originalTeamID = originalTeamID
        self.ownerTeamID = ownerTeamID
    }

    public var label: String { "\(year) R\(round)" }
}

/// Assets moving in one direction of a trade.
public struct TradePackage: Sendable, Equatable {
    public var playerIDs: [UUID]
    public var pickIDs: [UUID]

    public init(playerIDs: [UUID] = [], pickIDs: [UUID] = []) {
        self.playerIDs = playerIDs
        self.pickIDs = pickIDs
    }

    public var isEmpty: Bool { playerIDs.isEmpty && pickIDs.isEmpty }
}

/// A complete proposal between two teams.
public struct TradeProposal: Sendable, Equatable {
    public let fromTeamID: UUID
    public let toTeamID: UUID
    /// What the proposing team sends.
    public let sending: TradePackage
    /// What the proposing team receives.
    public let receiving: TradePackage

    public init(fromTeamID: UUID, toTeamID: UUID, sending: TradePackage, receiving: TradePackage) {
        self.fromTeamID = fromTeamID
        self.toTeamID = toTeamID
        self.sending = sending
        self.receiving = receiving
    }
}

public enum TradeVerdict: Sendable, Equatable {
    case accepted
    case rejected(reason: String)

    public var isAccepted: Bool { self == .accepted }
}

/// Values assets and decides whether an AI front office says yes.
public enum TradeEngine {

    // MARK: - Valuation

    /// What a player is worth in trade. Cheap young talent is worth far more than an expensive
    /// veteran of the same overall — the contract is part of the asset.
    public static func value(of player: Player, salaryCap: Int = LeagueRules.salaryCapYearOne) -> Double {
        // Overall drives value steeply: stars are scarce.
        let quality = pow(max(0, Double(player.overall) - 55) / 30, 2.3) * 1_000

        let peak = LeagueRules.peakAgeWindow(player.position)
        let ageFactor: Double
        if player.age < peak.lowerBound {
            ageFactor = 1.15
        } else if player.age > peak.upperBound {
            ageFactor = max(0.30, 1.0 - Double(player.age - peak.upperBound) * 0.14)
        } else {
            ageFactor = 1.0
        }

        let potentialFactor = player.age <= 25
            ? 0.85 + player.potential.developmentMultiplier * 0.25
            : 1.0

        let positionFactor = 0.7 + LeagueRules.positionSalaryPremium(player.position) * 0.35

        // Contract quality: a bargain adds value, an albatross subtracts it.
        var contractFactor = 1.0
        if let contract = player.contract {
            let market = ContractPricer.marketSalary(for: player, salaryCap: salaryCap)
            let paid = contract.averagePerYear
            contractFactor = max(0.35, min(1.5, Double(market) / Double(max(1, paid))))
            if contract.isRookieDeal { contractFactor *= 1.2 }
        }

        let moraleFactor = 0.92 + Double(player.morale) / 100 * 0.16
        return quality * ageFactor * potentialFactor * positionFactor * contractFactor * moraleFactor
    }

    /// Draft-pick value on a smooth decay from the top of the first round, discounted for
    /// every year into the future because nobody knows where it will land.
    public static func value(of pick: DraftPick, currentYear: Int) -> Double {
        let slot = Double((pick.round - 1) * LeagueRules.teamCount + LeagueRules.teamCount / 2)
        let top = 3_000.0
        let raw = top * pow(1 - slot / Double(LeagueRules.draftPickCount), 3.0)
        let yearsOut = max(0, pick.year - currentYear)
        return max(2, raw) * pow(0.8, Double(yearsOut))
    }

    public static func value(
        of package: TradePackage,
        league: League,
        picks: [DraftPick]
    ) -> Double {
        var total = 0.0
        for playerID in package.playerIDs {
            if let (player, _) = league.findPlayer(id: playerID) {
                total += value(of: player, salaryCap: league.salaryCap)
            }
        }
        for pickID in package.pickIDs {
            if let pick = picks.first(where: { $0.id == pickID }) {
                total += value(of: pick, currentYear: league.year)
            }
        }
        return total
    }

    // MARK: - Evaluation

    /// Whether the receiving team accepts. The AI wants a surplus, scaled by difficulty and
    /// its own philosophy, and refuses anything that would leave it illegal.
    public static func evaluate(
        _ proposal: TradeProposal,
        league: League,
        picks: [DraftPick]
    ) -> TradeVerdict {
        guard let partner = league.team(id: proposal.toTeamID) else {
            return .rejected(reason: "That team is not in the league.")
        }
        guard !proposal.sending.isEmpty || !proposal.receiving.isEmpty else {
            return .rejected(reason: "There is nothing on the table.")
        }
        if case .regularSeason(let week) = league.phase, week > LeagueRules.tradeDeadlineWeek {
            return .rejected(reason: "The trade deadline has passed.")
        }
        if league.phase.isPlayoffs {
            return .rejected(reason: "Rosters are frozen for the playoffs.")
        }

        // From the partner's point of view: they receive what we send.
        let incoming = value(of: proposal.sending, league: league, picks: picks)
        let outgoing = value(of: proposal.receiving, league: league, picks: picks)

        let threshold = max(
            league.settings.tradeDifficulty.acceptanceThreshold,
            partner.aiPersonality.tradeSurplusRequired
        )

        // Rebuilders want youth and picks; win-now teams want proven players.
        var adjustedIncoming = incoming
        for playerID in proposal.sending.playerIDs {
            guard let (player, _) = league.findPlayer(id: playerID) else { continue }
            switch partner.aiPersonality {
            case .rebuilder where player.age <= 25: adjustedIncoming += value(of: player) * 0.15
            case .winNow where player.overall >= 80: adjustedIncoming += value(of: player) * 0.12
            case .capHawk:
                if let contract = player.contract,
                   contract.averagePerYear > ContractPricer.marketSalary(for: player) {
                    adjustedIncoming -= value(of: player) * 0.20
                }
            default: break
            }
        }

        guard adjustedIncoming >= outgoing * threshold else {
            let shortfall = outgoing * threshold - adjustedIncoming
            return .rejected(
                reason: shortfall > outgoing * 0.4
                    ? "Not close. They value what you're asking for far more than what you're offering."
                    : "Close, but they need a little more."
            )
        }

        // Legality: both sides must survive the roster and cap consequences.
        if !isRosterLegal(proposal, league: league) {
            return .rejected(reason: "That deal would leave a roster short at a position.")
        }
        return .accepted
    }

    private static func isRosterLegal(_ proposal: TradeProposal, league: League) -> Bool {
        guard let from = league.team(id: proposal.fromTeamID),
              let to = league.team(id: proposal.toTeamID) else { return false }

        func survives(_ team: Team, losing: [UUID], gaining: Int) -> Bool {
            let remaining = team.activeRoster.filter { !losing.contains($0.id) }
            guard remaining.count + gaining <= LeagueRules.activeRosterSize else { return false }
            for position in Position.allCases {
                let count = remaining.filter { $0.position == position }.count
                if count < position.minimumRosterCount { return false }
            }
            return true
        }

        return survives(from, losing: proposal.sending.playerIDs, gaining: proposal.receiving.playerIDs.count)
            && survives(to, losing: proposal.receiving.playerIDs, gaining: proposal.sending.playerIDs.count)
    }

    // MARK: - Execution

    /// Moves the assets. Call only after `evaluate` returns `.accepted`.
    @discardableResult
    public static func execute(
        _ proposal: TradeProposal,
        league: inout League,
        picks: inout [DraftPick]
    ) -> Bool {
        guard let fromIndex = league.teams.firstIndex(where: { $0.id == proposal.fromTeamID }),
              let toIndex = league.teams.firstIndex(where: { $0.id == proposal.toTeamID })
        else { return false }

        func move(_ playerIDs: [UUID], from source: Int, to destination: Int) {
            for playerID in playerIDs {
                guard let index = league.teams[source].roster.firstIndex(where: { $0.id == playerID })
                else { continue }
                var player = league.teams[source].roster.remove(at: index)
                // Being traded unsettles a player, but a fresh start is not all bad.
                player.morale = max(25, player.morale - 6)
                league.teams[destination].roster.append(player)
            }
        }

        move(proposal.sending.playerIDs, from: fromIndex, to: toIndex)
        move(proposal.receiving.playerIDs, from: toIndex, to: fromIndex)

        for pickID in proposal.sending.pickIDs {
            if let index = picks.firstIndex(where: { $0.id == pickID }) {
                picks[index].ownerTeamID = proposal.toTeamID
            }
        }
        for pickID in proposal.receiving.pickIDs {
            if let index = picks.firstIndex(where: { $0.id == pickID }) {
                picks[index].ownerTeamID = proposal.fromTeamID
            }
        }

        league.teams[fromIndex].autoSortDepthChart()
        league.teams[toIndex].autoSortDepthChart()

        let from = league.teams[fromIndex]
        let to = league.teams[toIndex]
        let summary = "\(proposal.sending.playerIDs.count + proposal.sending.pickIDs.count) assets for "
            + "\(proposal.receiving.playerIDs.count + proposal.receiving.pickIDs.count)."
        league.news.append(
            NewsEngine.trade(from: from, to: to, summary: summary, league: league, rng: &league.rng)
        )
        return true
    }

    /// Builds the full set of picks a league owns for the next few drafts.
    public static func makePicks(for league: League, years: Int = 3) -> [DraftPick] {
        var picks: [DraftPick] = []
        var rng = SeededRandom(seed: UInt64(truncatingIfNeeded: league.year))
        for yearOffset in 0..<years {
            for round in 1...LeagueRules.draftRounds {
                for team in league.teams {
                    picks.append(
                        DraftPick(
                            id: rng.uuid(),
                            year: league.year + yearOffset,
                            round: round,
                            originalTeamID: team.id,
                            ownerTeamID: team.id
                        )
                    )
                }
            }
        }
        return picks
    }
}
