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
                let capHit = contract.capHit(inYear: 0)
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
        let addedDeadMoney = contract.deadMoney(ifReleasedBeforeYear: 0)
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
}
