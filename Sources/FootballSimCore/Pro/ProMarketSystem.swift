import Foundation

public enum ProMarketAction: Codable, Sendable, Equatable {
    case openOffseason
    case scout(teamID: UUID, prospectID: UUID)
    case beginDraft
    case signFreeAgent(playerID: UUID, teamID: UUID, contract: Contract)
    case draft(prospectID: UUID, teamID: UUID, contract: Contract?)
    case close
}

public struct ProMarketRequest: Codable, Sendable, Equatable {
    public let calendar: CalendarState
    public let action: ProMarketAction

    public init(calendar: CalendarState, action: ProMarketAction) {
        self.calendar = calendar
        self.action = action
    }
}

public enum ProMarketError: Error, Sendable, Equatable {
    case marketAlreadyOpen
    case invalidSeason
    case invalidPhase
    case missingTeam
    case missingProspect
    case unavailableFreeAgent
    case wrongDraftTeam
    case duplicateDraftPick
    case invalidObservation
    case invalidRoot
}

/// Deterministic professional-market mutations. Each operation works on a value copy and only
/// returns the copy after the final root check, so a rejected market action cannot partially spend
/// a roster slot, cap dollar, or draft pick.
public enum ProMarketSystem {
    public static func openOffseason(in state: GameState) throws -> GameState {
        guard state.proMarket.phase == .closed else {
            throw ProMarketError.marketAlreadyOpen
        }
        let targetSeason = state.calendar.season + 1
        let order = draftOrder(for: state)
        guard order.count == ProRules.draftPickCount else {
            throw ProMarketError.invalidRoot
        }
        let draftClass = makeDraftClass(
            season: targetSeason,
            order: order,
            in: state
        )
        let owned = Set(state.programmes.values.flatMap(\.rosterIDs))
            .union(state.proTeams.values.flatMap { $0.rosterIDs + $0.practiceSquadIDs })
        let freeAgents = state.players.values
            .filter { player in
                player.eligibility == nil
                    && player.contract == nil
                    && !owned.contains(player.id)
            }
            .map(\.id)
            .sorted { $0.uuidString < $1.uuidString }
            .prefix(ProMarketState.maximumFreeAgentIDs)

        var next = state
        guard next.proMarket.open(
            season: targetSeason,
            draftClass: draftClass,
            draftOrder: order,
            freeAgentIDs: Array(freeAgents)
        ) else { throw ProMarketError.invalidRoot }
        return next
    }

    public static func recordScouting(
        teamID: UUID,
        prospectID: UUID,
        in state: GameState
    ) throws -> GameState {
        guard state.proMarket.phase == .freeAgency || state.proMarket.phase == .draft else {
            throw ProMarketError.invalidPhase
        }
        guard state.proTeams[teamID] != nil else { throw ProMarketError.missingTeam }
        guard let prospect = state.proMarket.draftClass.first(where: { $0.id == prospectID }) else {
            throw ProMarketError.missingProspect
        }
        let seed = SeededRandom.derive(
            from: state.league.seed,
            scope: .scouting,
            ordinal: Int(truncatingIfNeeded: SeededRandom.seed(from: teamID, prospectID))
        )
        var rng = SeededRandom(seed: seed)
        let observation = ProDraftObservation(
            teamID: teamID,
            prospectID: prospectID,
            season: state.proMarket.season,
            estimatedOverall: prospect.player.overall.value + rng.int(in: -8...8),
            estimatedPotential: prospect.player.potential.value + rng.int(in: -10...10),
            confidence: 45 + rng.int(in: 0...40),
            evidenceCount: 1
        )
        var next = state
        guard next.proMarket.record(observation) else {
            throw ProMarketError.invalidObservation
        }
        guard WorldIntegrity.check(next).isValid else { throw ProMarketError.invalidRoot }
        return next
    }

    public static func beginDraft(in state: GameState) throws -> GameState {
        var next = state
        guard next.proMarket.beginDraft() else { throw ProMarketError.invalidPhase }
        guard WorldIntegrity.check(next).isValid else { throw ProMarketError.invalidRoot }
        return next
    }

    public static func signFreeAgent(
        playerID: UUID,
        teamID: UUID,
        contract: Contract,
        in state: GameState
    ) throws -> GameState {
        guard state.proMarket.phase == .freeAgency else { throw ProMarketError.invalidPhase }
        guard state.proMarket.freeAgentIDs.contains(playerID) else {
            throw ProMarketError.unavailableFreeAgent
        }
        var next = state
        guard next.proMarket.removeFreeAgent(playerID) else {
            throw ProMarketError.unavailableFreeAgent
        }
        let receipt = try ProManagementSystem.acquire(
            playerID: playerID,
            for: teamID,
            kind: .freeAgency,
            contract: contract,
            in: next
        )
        next = receipt.state
        guard WorldIntegrity.check(next).isValid else { throw ProMarketError.invalidRoot }
        return next
    }

    public static func draft(
        prospectID: UUID,
        for teamID: UUID,
        contract: Contract? = nil,
        in state: GameState
    ) throws -> GameState {
        guard state.proMarket.phase == .draft else { throw ProMarketError.invalidPhase }
        guard state.proMarket.currentPickTeamID == teamID else {
            throw ProMarketError.wrongDraftTeam
        }
        guard let prospect = state.proMarket.draftClass.first(where: { $0.id == prospectID }) else {
            throw ProMarketError.missingProspect
        }
        guard !state.proMarket.draftedProspectIDs.contains(prospectID) else {
            throw ProMarketError.duplicateDraftPick
        }
        var next = state
        next.players.insert(prospect.player)
        next.people.insert(player: prospect.player)
        guard next.proMarket.consumeDraftPick(prospectID: prospectID) else {
            throw ProMarketError.duplicateDraftPick
        }
        let receipt = try ProManagementSystem.acquire(
            playerID: prospectID,
            for: teamID,
            kind: .draft,
            contract: contract ?? rookieContract(for: prospect.player),
            in: next
        )
        next = receipt.state
        guard WorldIntegrity.check(next).isValid else { throw ProMarketError.invalidRoot }
        return next
    }

    public static func close(in state: GameState) throws -> GameState {
        var next = state
        guard next.proMarket.close() else { throw ProMarketError.invalidPhase }
        return next
    }

    public static func rookieContract(for player: Player) -> Contract {
        let salary = 1_000_000 + player.overall.value * 25_000
        return Contract(
            years: 4,
            baseSalaryByYear: Array(repeating: salary, count: 4),
            signingBonus: salary / 2
        )
    }

    private static func draftOrder(for state: GameState) -> [UUID] {
        let base = ProManagementSystem.draftOrder(in: state)
        return (0..<ProRules.draftRounds).flatMap { round in
            round.isMultiple(of: 2) ? base : base.reversed()
        }
    }

    private static func makeDraftClass(
        season: Int,
        order: [UUID],
        in state: GameState
    ) -> [ProDraftProspect] {
        let positions = Position.allCases
        let existingIDs = Set(state.players.ids)
        var usedIDs = existingIDs
        var prospects: [ProDraftProspect] = []
        prospects.reserveCapacity(ProRules.draftPickCount)
        for pick in 0..<ProRules.draftPickCount {
            let teamID = order[pick]
            let team = state.proTeams[teamID]
            var ordinal = pick
            var player = RosterPopulationGenerator.replacement(
                rootSeed: state.league.seed,
                season: season,
                organisationID: teamID,
                position: positions[pick % positions.count],
                ordinal: ordinal,
                prestige: team?.prestige ?? Rating(60),
                tier: .pro
            )
            while usedIDs.contains(player.id) {
                ordinal += ProRules.draftPickCount
                player = RosterPopulationGenerator.replacement(
                    rootSeed: state.league.seed,
                    season: season,
                    organisationID: teamID,
                    position: positions[pick % positions.count],
                    ordinal: ordinal,
                    prestige: team?.prestige ?? Rating(60),
                    tier: .pro
                )
            }
            usedIDs.insert(player.id)
            prospects.append(ProDraftProspect(player: player, draftSeason: season))
        }
        return prospects
    }
}
