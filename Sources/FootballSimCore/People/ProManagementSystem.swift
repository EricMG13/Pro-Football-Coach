import Foundation

/// The source of a professional roster acquisition.
public enum ProAcquisitionKind: String, Codable, Sendable, Equatable {
    case freeAgency
    case draft
}

public enum ProManagementAction: Codable, Sendable, Equatable {
    case acquire(
        playerID: UUID,
        teamID: UUID,
        kind: ProAcquisitionKind,
        contract: Contract
    )
    case release(playerID: UUID, teamID: UUID)
    case beginNegotiation(
        playerID: UUID,
        teamID: UUID,
        offer: Contract,
        deadline: CalendarState
    )
    case counterNegotiation(negotiationID: UUID, offer: Contract)
    case acceptNegotiation(negotiationID: UUID)
    case rejectNegotiation(negotiationID: UUID)
    case withdrawNegotiation(negotiationID: UUID)
}

public struct ProManagementRequest: Codable, Sendable, Equatable {
    public let calendar: CalendarState
    public let action: ProManagementAction

    public init(calendar: CalendarState, action: ProManagementAction) {
        self.calendar = calendar
        self.action = action
    }
}

/// A read-only cap projection for one professional team.
public struct ProCapSnapshot: Codable, Sendable, Equatable {
    public let teamID: UUID
    public let season: Int
    public let capLimit: Int
    public let committedCap: Int
    public let deadMoney: Int
    public let remainingCap: Int
    public let activeRosterCount: Int
    public let practiceSquadCount: Int

    public var isWithinCap: Bool { committedCap <= capLimit }
}

public enum ProManagementError: Error, Sendable, Equatable {
    case missingTeam
    case missingPlayer
    case invalidTeamRoster
    case invalidContract
    case playerAlreadyRostered
    case playerIsNotProfessionalFreeAgent
    case activeRosterFull
    case playerNotOnRoster
    case capExceeded
    case negotiationNotFound
    case negotiationAlreadyOpen
    case negotiationClosed
    case negotiationDeadlinePassed
    case invalidRoot
}

public struct ProAcquisitionReceipt: Sendable, Equatable {
    public let state: GameState
    public let playerID: UUID
    public let teamID: UUID
    public let kind: ProAcquisitionKind
    public let capBefore: ProCapSnapshot
    public let capAfter: ProCapSnapshot
}

public struct ProReleaseReceipt: Sendable, Equatable {
    public let state: GameState
    public let playerID: UUID
    public let teamID: UUID
    public let deadMoneyAdded: Int
    public let capAfter: ProCapSnapshot
}

public struct ProNegotiationReceipt: Sendable, Equatable {
    public let state: GameState
    public let negotiation: ProContractNegotiation
    public let capBefore: ProCapSnapshot
    public let capAfter: ProCapSnapshot
}

/// Cap and roster transactions for the professional tier.
///
/// This deliberately derives market availability from the existing root: an active player with no
/// contract and no organisation is a free agent. A later M6 market state can add dated offers and
/// draft fog without creating a second ownership ledger.
public enum ProManagementSystem {
    public static func capSnapshot(teamID: UUID, in state: GameState) throws -> ProCapSnapshot {
        guard let team = state.proTeams[teamID] else { throw ProManagementError.missingTeam }
        guard team.deadMoney >= 0 else { throw ProManagementError.invalidTeamRoster }
        let rosterIDs = team.rosterIDs + team.practiceSquadIDs
        guard Set(rosterIDs).count == rosterIDs.count else {
            throw ProManagementError.invalidTeamRoster
        }
        var committedCap = team.deadMoney
        for playerID in rosterIDs {
            guard let player = state.players[playerID], player.eligibility == nil else {
                throw ProManagementError.invalidTeamRoster
            }
            if let contract = player.contract {
                guard Self.isValid(contract) else { throw ProManagementError.invalidContract }
                let capHit = contract.capHit(atSeason: state.calendar.season)
                guard committedCap <= Int.max - capHit else {
                    throw ProManagementError.invalidContract
                }
                committedCap += capHit
            }
        }
        let capLimit = ProRules.salaryCap(seasonsAfterBase: state.calendar.season)
        return ProCapSnapshot(
            teamID: teamID,
            season: state.calendar.season,
            capLimit: capLimit,
            committedCap: committedCap,
            deadMoney: team.deadMoney,
            remainingCap: capLimit - committedCap,
            activeRosterCount: team.rosterIDs.count,
            practiceSquadCount: team.practiceSquadIDs.count
        )
    }

    public static func acquire(
        playerID: UUID,
        for teamID: UUID,
        kind: ProAcquisitionKind,
        contract: Contract,
        in state: GameState
    ) throws -> ProAcquisitionReceipt {
        guard Self.isValid(contract) else { throw ProManagementError.invalidContract }
        guard let player = state.players[playerID] else { throw ProManagementError.missingPlayer }
        guard let team = state.proTeams[teamID] else { throw ProManagementError.missingTeam }
        let ownedIDs = Set(state.programmes.values.flatMap(\.rosterIDs))
            .union(state.proTeams.values.flatMap { $0.rosterIDs + $0.practiceSquadIDs })
        guard !ownedIDs.contains(playerID), player.eligibility == nil, player.contract == nil else {
            throw ProManagementError.playerIsNotProfessionalFreeAgent
        }
        guard team.rosterIDs.count < ProRules.activeRosterLimit else {
            throw ProManagementError.activeRosterFull
        }
        let before = try capSnapshot(teamID: teamID, in: state)
        guard before.committedCap <= before.capLimit - contract.capHit(inYear: 0) else {
            throw ProManagementError.capExceeded
        }

        var next = state
        next.players.update(playerID) { $0.contract = contract }
        next.proTeams.update(teamID) { $0.rosterIDs.append(playerID) }
        guard WorldIntegrity.check(next).isValid else { throw ProManagementError.invalidRoot }
        let after = try capSnapshot(teamID: teamID, in: next)
        return ProAcquisitionReceipt(
            state: next,
            playerID: playerID,
            teamID: teamID,
            kind: kind,
            capBefore: before,
            capAfter: after
        )
    }

    public static func release(
        playerID: UUID,
        from teamID: UUID,
        in state: GameState
    ) throws -> ProReleaseReceipt {
        guard let team = state.proTeams[teamID] else { throw ProManagementError.missingTeam }
        guard let player = state.players[playerID], let contract = player.contract else {
            throw ProManagementError.playerNotOnRoster
        }
        let isActive = team.rosterIDs.contains(playerID)
        let isPractice = team.practiceSquadIDs.contains(playerID)
        guard isActive || isPractice else { throw ProManagementError.playerNotOnRoster }
        let addedDeadMoney = contract.deadMoney(ifReleasedAtSeason: state.calendar.season)
        guard team.deadMoney <= Int.max - addedDeadMoney else {
            throw ProManagementError.invalidTeamRoster
        }

        var next = state
        next.proTeams.update(teamID) {
            $0.rosterIDs.removeAll { $0 == playerID }
            $0.practiceSquadIDs.removeAll { $0 == playerID }
            $0.deadMoney += addedDeadMoney
        }
        next.players.update(playerID) { $0.contract = nil }
        guard WorldIntegrity.check(next).isValid else { throw ProManagementError.invalidRoot }
        return ProReleaseReceipt(
            state: next,
            playerID: playerID,
            teamID: teamID,
            deadMoneyAdded: addedDeadMoney,
            capAfter: try capSnapshot(teamID: teamID, in: next)
        )
    }

    public static func beginNegotiation(
        playerID: UUID,
        teamID: UUID,
        offer: Contract,
        deadline: CalendarState,
        in state: GameState
    ) throws -> ProNegotiationReceipt {
        guard isValid(offer) else { throw ProManagementError.invalidContract }
        guard state.proMarket.phase != .draft else {
            throw ProManagementError.negotiationClosed
        }
        guard let team = state.proTeams[teamID],
              let player = state.players[playerID],
              (team.rosterIDs + team.practiceSquadIDs).contains(playerID),
              player.contract != nil else { throw ProManagementError.playerNotOnRoster }
        guard deadline.isOnOrAfter(state.calendar) else {
            throw ProManagementError.negotiationDeadlinePassed
        }
        guard !state.proMarket.contractNegotiations.contains(where: {
            $0.teamID == teamID && $0.playerID == playerID && $0.status.isOpen
        }) else { throw ProManagementError.negotiationAlreadyOpen }
        let before = try capSnapshot(teamID: teamID, in: state)
        let after = try replacingContractCap(
            playerID: playerID,
            teamID: teamID,
            with: offer,
            in: state
        )
        guard after.isWithinCap else { throw ProManagementError.capExceeded }
        var negotiationRNG = SeededRandom(seed: SeededRandom.derive(
            from: SeededRandom.seed(from: teamID, playerID),
            scope: .contract,
            ordinal: state.proMarket.contractNegotiations.count
        ))
        let negotiation = ProContractNegotiation(
            id: negotiationRNG.uuid(),
            playerID: playerID,
            teamID: teamID,
            openedAt: state.calendar,
            deadline: deadline,
            offerHistory: [offer]
        )
        var next = state
        guard next.proMarket.addContractNegotiation(negotiation) else {
            throw ProManagementError.negotiationClosed
        }
        guard WorldIntegrity.check(next).isValid else { throw ProManagementError.invalidRoot }
        return ProNegotiationReceipt(
            state: next,
            negotiation: negotiation,
            capBefore: before,
            capAfter: after
        )
    }

    public static func counterNegotiation(
        negotiationID: UUID,
        offer: Contract,
        in state: GameState
    ) throws -> ProNegotiationReceipt {
        guard isValid(offer) else { throw ProManagementError.invalidContract }
        var next = state
        next.proMarket.expireContractNegotiations(at: state.calendar)
        guard var negotiation = next.proMarket.contractNegotiations.first(where: {
            $0.id == negotiationID
        }) else { throw ProManagementError.negotiationNotFound }
        guard negotiation.status.isOpen else { throw ProManagementError.negotiationClosed }
        guard !negotiation.isPastDeadline(at: state.calendar) else {
            throw ProManagementError.negotiationDeadlinePassed
        }
        let before = try capSnapshot(teamID: negotiation.teamID, in: next)
        let after = try replacingContractCap(
            playerID: negotiation.playerID,
            teamID: negotiation.teamID,
            with: offer,
            in: next
        )
        guard after.isWithinCap else { throw ProManagementError.capExceeded }
        guard negotiation.counter(with: offer), next.proMarket.updateContractNegotiation(negotiation) else {
            throw ProManagementError.negotiationClosed
        }
        guard WorldIntegrity.check(next).isValid else { throw ProManagementError.invalidRoot }
        return ProNegotiationReceipt(
            state: next,
            negotiation: negotiation,
            capBefore: before,
            capAfter: after
        )
    }

    public static func settleNegotiation(
        negotiationID: UUID,
        as status: ProContractNegotiationStatus,
        in state: GameState
    ) throws -> ProNegotiationReceipt {
        guard status == .accepted || status == .rejected
                || status == .withdrawn else { throw ProManagementError.negotiationClosed }
        var next = state
        next.proMarket.expireContractNegotiations(at: state.calendar)
        guard var negotiation = next.proMarket.contractNegotiations.first(where: {
            $0.id == negotiationID
        }) else { throw ProManagementError.negotiationNotFound }
        guard negotiation.status.isOpen else { throw ProManagementError.negotiationClosed }
        guard !negotiation.isPastDeadline(at: state.calendar) else {
            throw ProManagementError.negotiationDeadlinePassed
        }
        let before = try capSnapshot(teamID: negotiation.teamID, in: next)
        var after = before
        if status == .accepted {
            after = try replacingContractCap(
                playerID: negotiation.playerID,
                teamID: negotiation.teamID,
                with: negotiation.currentOffer,
                in: next
            )
            guard after.isWithinCap else { throw ProManagementError.capExceeded }
            next.players.update(negotiation.playerID) {
                $0.contract = negotiation.currentOffer.withSignedSeason(state.calendar.season)
            }
            after = try capSnapshot(teamID: negotiation.teamID, in: next)
        }
        guard negotiation.settle(as: status), next.proMarket.updateContractNegotiation(negotiation) else {
            throw ProManagementError.negotiationClosed
        }
        guard WorldIntegrity.check(next).isValid else { throw ProManagementError.invalidRoot }
        return ProNegotiationReceipt(
            state: next,
            negotiation: negotiation,
            capBefore: before,
            capAfter: after
        )
    }

    public struct ProCapComplianceRelease: Sendable, Equatable {
        public let playerID: UUID
        public let teamID: UUID
        public let deadMoneyAdded: Int
    }

    public struct ProCapComplianceReceipt: Sendable, Equatable {
        public let state: GameState
        public let releases: [ProCapComplianceRelease]
    }

    /// Beat 2 (`02` §4.2), the AI-facing half. Every professional team except the controlled one
    /// — that one is skipped deliberately; a mandatory decision for the player's own cap choices
    /// is a separate, unbuilt surface — is released down to cap-legal, cheapest dead money first.
    ///
    /// Mutates roster, contract and dead-money state directly rather than delegating to `release`,
    /// for the same reason `ProMarketSystem.expireContracts` does: `release`'s own internal
    /// `WorldIntegrity.check` is unconditional, so an intermediate state that is still over cap
    /// after one release (but less over cap than before) would be self-rejected before a second
    /// release could run. Validated once at the end instead, against only what this function
    /// itself introduced — the same difference-based guard `expireContracts` uses, so a root that
    /// already carries an unrelated issue is not falsely blamed on this pass.
    ///
    /// `WorldIntegrity.checkProfessionalCap` itself is untouched and stays exactly as strict as it
    /// is today: this function's job is to make sure nothing calls it with a still-over-cap root
    /// once compliance has run, not to relax what it checks.
    public static func enforceCapCompliance(
        at calendar: CalendarState,
        in state: GameState
    ) throws -> ProCapComplianceReceipt {
        let controlledTeamID = state.careerArc.currentJob.flatMap { job in
            job.tier == .professional ? job.organisationID : nil
        }
        var next = state
        var releases: [ProCapComplianceRelease] = []
        for teamID in state.proTeams.ids where teamID != controlledTeamID {
            while true {
                guard let snapshot = try? capSnapshot(teamID: teamID, in: next),
                      !snapshot.isWithinCap else { break }
                guard let team = next.proTeams[teamID] else {
                    throw ProManagementError.missingTeam
                }
                let candidates = (team.rosterIDs + team.practiceSquadIDs).compactMap {
                    playerID -> (UUID, Int)? in
                    guard let contract = next.players[playerID]?.contract else { return nil }
                    return (playerID, contract.deadMoney(ifReleasedAtSeason: calendar.season))
                }
                // Ties broken by identifier, the same rule every other deterministic ordering in
                // this project uses, so two processes given the same root release the same player.
                guard let (playerID, deadMoneyAdded) = candidates.min(by: { lhs, rhs in
                    lhs.1 == rhs.1 ? lhs.0.uuidString < rhs.0.uuidString : lhs.1 < rhs.1
                }) else {
                    // No contracted player remains and the team is still over cap: dead money
                    // alone exceeds the limit. Nothing left to release makes it legal.
                    throw ProManagementError.capExceeded
                }
                guard team.deadMoney <= Int.max - deadMoneyAdded else {
                    throw ProManagementError.invalidTeamRoster
                }
                next.proTeams.update(teamID) {
                    $0.rosterIDs.removeAll { $0 == playerID }
                    $0.practiceSquadIDs.removeAll { $0 == playerID }
                    $0.deadMoney += deadMoneyAdded
                }
                next.players.update(playerID) { $0.contract = nil }
                if !next.proMarket.freeAgentIDs.contains(playerID) {
                    guard next.proMarket.addFreeAgent(playerID) else {
                        throw ProManagementError.invalidRoot
                    }
                }
                releases.append(ProCapComplianceRelease(
                    playerID: playerID,
                    teamID: teamID,
                    deadMoneyAdded: deadMoneyAdded
                ))
            }
        }
        let inherited = WorldIntegrity.check(state).issues
        let introduced = WorldIntegrity.check(next).issues.filter { !inherited.contains($0) }
        guard introduced.isEmpty else { throw ProManagementError.invalidRoot }
        return ProCapComplianceReceipt(state: next, releases: releases)
    }

    /// Losers draft first from the most recently archived professional ranking; before the first
    /// archive, UUID order is the only stable fallback.
    public static func draftOrder(in state: GameState) -> [UUID] {
        let fallback = state.proTeams.ids
        guard let ranking = state.competition.archives.last?.finalProRanking,
              Set(ranking) == Set(fallback) else {
            return fallback
        }
        return ranking.reversed()
    }

    private static func isValid(_ contract: Contract) -> Bool {
        guard contract.years > 0,
              ProRules.contractYearsRange.contains(contract.years),
              contract.baseSalaryByYear.count == contract.years,
              contract.baseSalaryByYear.allSatisfy({ $0 >= 0 }),
              contract.signingBonus >= 0 else { return false }
        return (0..<contract.years).allSatisfy { year in
            contract.baseSalaryByYear[year]
                <= Int.max - contract.bonusProration(inYear: year)
        }
    }

    private static func replacingContractCap(
        playerID: UUID,
        teamID: UUID,
        with contract: Contract,
        in state: GameState
    ) throws -> ProCapSnapshot {
        guard let team = state.proTeams[teamID],
              team.rosterIDs.contains(playerID) || team.practiceSquadIDs.contains(playerID),
              state.players[playerID]?.contract != nil else {
            throw ProManagementError.playerNotOnRoster
        }
        var next = state
        next.players.update(playerID) { $0.contract = contract.withSignedSeason(state.calendar.season) }
        return try capSnapshot(teamID: teamID, in: next)
    }
}
