import Foundation

public enum ProMarketAction: Codable, Sendable, Equatable {
    case openOffseason
    case scout(teamID: UUID, prospectID: UUID)
    case beginDraft
    case signFreeAgent(playerID: UUID, teamID: UUID, contract: Contract)
    case draft(prospectID: UUID, teamID: UUID, contract: Contract?)
    case moveToPracticeSquad(playerID: UUID, teamID: UUID)
    case promoteFromPracticeSquad(playerID: UUID, teamID: UUID)
    case trade(
        sourcePlayerID: UUID,
        sourceTeamID: UUID,
        destinationPlayerID: UUID,
        destinationTeamID: UUID
    )
    case placeOnWaivers(playerID: UUID, teamID: UUID)
    case claimWaiver(playerID: UUID, teamID: UUID)
    case resolveExpiredWaivers
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
    case practiceSquadFull
    case activeRosterFull
    case playerNotOnRoster
    case teamsMustDiffer
    case tradePlayerUnavailable
    case waiverAlreadyOpen
    case waiverNotFound
    case waiverClaimExpired
    case waiverClaimInvalid
    case invalidRoot
}

public struct ProContractExpiryReceipt: Sendable, Equatable {
    public let state: GameState
    public let expiredPlayerIDs: [UUID]

    public init(state: GameState, expiredPlayerIDs: [UUID]) {
        self.state = state
        self.expiredPlayerIDs = expiredPlayerIDs
    }
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
        try signFreeAgent(
            playerID: playerID,
            teamID: teamID,
            contract: contract,
            in: state,
            validateIntegrity: true
        )
    }

    static func signFreeAgentForScheduler(
        playerID: UUID,
        teamID: UUID,
        contract: Contract,
        in state: GameState
    ) throws -> GameState {
        try signFreeAgent(
            playerID: playerID,
            teamID: teamID,
            contract: contract,
            in: state,
            validateIntegrity: false
        )
    }

    private static func signFreeAgent(
        playerID: UUID,
        teamID: UUID,
        contract: Contract,
        in state: GameState,
        validateIntegrity: Bool
    ) throws -> GameState {
        guard state.proMarket.phase == .freeAgency else { throw ProMarketError.invalidPhase }
        guard state.proMarket.freeAgentIDs.contains(playerID) else {
            throw ProMarketError.unavailableFreeAgent
        }
        guard contract.signedSeason == nil || contract.signedSeason == state.proMarket.season else {
            throw ProMarketError.invalidRoot
        }
        var next = state
        guard next.proMarket.removeFreeAgent(playerID) else {
            throw ProMarketError.unavailableFreeAgent
        }
        let receipt = try (validateIntegrity
            ? ProManagementSystem.acquire(
                playerID: playerID,
                for: teamID,
                kind: .freeAgency,
                contract: contract.signedSeason == nil
                    ? contract.withSignedSeason(state.proMarket.season)
                    : contract,
                in: next
            )
            : ProManagementSystem.acquireForScheduler(
            playerID: playerID,
            for: teamID,
            kind: .freeAgency,
            contract: contract.signedSeason == nil
                ? contract.withSignedSeason(state.proMarket.season)
                : contract,
            in: next
        ))
        next = receipt.state
        return next
    }

    public static func draft(
        prospectID: UUID,
        for teamID: UUID,
        contract: Contract? = nil,
        in state: GameState
    ) throws -> GameState {
        try draft(
            prospectID: prospectID,
            for: teamID,
            contract: contract,
            in: state,
            validateIntegrity: true
        )
    }

    /// The draft the weekly scheduler makes, which checks the whole root once for the batch rather
    /// than once per pick.
    ///
    /// Same reason `signFreeAgentForScheduler` exists: the scheduler validates the complete root at
    /// its own integrity boundary after the batch, so repeating a whole-world check inside every
    /// pick is redundant. It was also invisible until 2026-08-20, because the draft had never
    /// successfully made a pick — the first season it ran to completion it did 224 whole-root checks
    /// a season where free agency, doing comparable work, did none.
    static func draftForScheduler(
        prospectID: UUID,
        for teamID: UUID,
        contract: Contract? = nil,
        in state: GameState
    ) throws -> GameState {
        try draft(
            prospectID: prospectID,
            for: teamID,
            contract: contract,
            in: state,
            validateIntegrity: false
        )
    }

    private static func draft(
        prospectID: UUID,
        for teamID: UUID,
        contract: Contract?,
        in state: GameState,
        validateIntegrity: Bool
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
        if let contract, contract.signedSeason != nil, contract.signedSeason != state.proMarket.season {
            throw ProMarketError.invalidRoot
        }
        let requestedContract = contract ?? rookieContract(for: prospect.player)
        let resolvedContract = requestedContract.signedSeason == nil
            ? requestedContract.withSignedSeason(state.proMarket.season)
            : requestedContract
        var next = state
        next.players.insert(prospect.player)
        next.people.insert(player: prospect.player)
        guard next.proMarket.consumeDraftPick(prospectID: prospectID) else {
            throw ProMarketError.duplicateDraftPick
        }
        let receipt = try (validateIntegrity
            ? ProManagementSystem.acquire(
                playerID: prospectID,
                for: teamID,
                kind: .draft,
                contract: resolvedContract,
                in: next
            )
            : ProManagementSystem.acquireForScheduler(
                playerID: prospectID,
                for: teamID,
                kind: .draft,
                contract: resolvedContract,
                in: next
            ))
        next = receipt.state
        if validateIntegrity {
            guard WorldIntegrity.check(next).isValid else { throw ProMarketError.invalidRoot }
        }
        return next
    }

    public static func moveToPracticeSquad(
        playerID: UUID,
        teamID: UUID,
        in state: GameState
    ) throws -> GameState {
        guard let team = state.proTeams[teamID],
              team.rosterIDs.contains(playerID) else {
            throw ProMarketError.playerNotOnRoster
        }
        guard team.practiceSquadIDs.count < ProRules.practiceSquadLimit else {
            throw ProMarketError.practiceSquadFull
        }
        var next = state
        _ = next.proTeams.update(teamID) {
            $0.rosterIDs.removeAll { $0 == playerID }
            $0.practiceSquadIDs.append(playerID)
        }
        guard WorldIntegrity.check(next).isValid else { throw ProMarketError.invalidRoot }
        return next
    }

    public static func promoteFromPracticeSquad(
        playerID: UUID,
        teamID: UUID,
        in state: GameState
    ) throws -> GameState {
        guard let team = state.proTeams[teamID],
              team.practiceSquadIDs.contains(playerID) else {
            throw ProMarketError.playerNotOnRoster
        }
        guard team.rosterIDs.count < ProRules.activeRosterLimit else {
            throw ProMarketError.activeRosterFull
        }
        var next = state
        _ = next.proTeams.update(teamID) {
            $0.practiceSquadIDs.removeAll { $0 == playerID }
            $0.rosterIDs.append(playerID)
        }
        guard WorldIntegrity.check(next).isValid else { throw ProMarketError.invalidRoot }
        return next
    }

    public static func trade(
        sourcePlayerID: UUID,
        sourceTeamID: UUID,
        destinationPlayerID: UUID,
        destinationTeamID: UUID,
        in state: GameState
    ) throws -> GameState {
        guard sourceTeamID != destinationTeamID else {
            throw ProMarketError.teamsMustDiffer
        }
        guard let source = state.proTeams[sourceTeamID],
              let destination = state.proTeams[destinationTeamID] else {
            throw ProMarketError.missingTeam
        }
        guard source.rosterIDs.contains(sourcePlayerID),
              destination.rosterIDs.contains(destinationPlayerID) else {
            throw ProMarketError.tradePlayerUnavailable
        }
        guard let sourcePlayer = state.players[sourcePlayerID],
              let destinationPlayer = state.players[destinationPlayerID],
              sourcePlayer.eligibility == nil,
              destinationPlayer.eligibility == nil else {
            throw ProMarketError.tradePlayerUnavailable
        }
        var next = state
        _ = next.proTeams.update(sourceTeamID) {
            $0.rosterIDs.removeAll { $0 == sourcePlayerID }
            $0.rosterIDs.append(destinationPlayerID)
        }
        _ = next.proTeams.update(destinationTeamID) {
            $0.rosterIDs.removeAll { $0 == destinationPlayerID }
            $0.rosterIDs.append(sourcePlayerID)
        }
        do {
            guard try ProManagementSystem.capSnapshot(teamID: sourceTeamID, in: next).isWithinCap,
                  try ProManagementSystem.capSnapshot(teamID: destinationTeamID, in: next).isWithinCap
            else { throw ProMarketError.invalidRoot }
        } catch is ProManagementError {
            throw ProMarketError.invalidRoot
        }
        guard WorldIntegrity.check(next).isValid else { throw ProMarketError.invalidRoot }
        return next
    }

    public static func placeOnWaivers(
        playerID: UUID,
        teamID: UUID,
        at calendar: CalendarState,
        in state: GameState
    ) throws -> GameState {
        guard calendar == state.calendar else { throw ProMarketError.invalidSeason }
        guard let team = state.proTeams[teamID],
              team.rosterIDs.contains(playerID) || team.practiceSquadIDs.contains(playerID) else {
            throw ProMarketError.playerNotOnRoster
        }
        guard state.players[playerID]?.eligibility == nil,
              state.players[playerID]?.contract != nil else {
            throw ProMarketError.waiverClaimInvalid
        }
        guard !state.proMarket.waivers.contains(where: { $0.playerID == playerID }) else {
            throw ProMarketError.waiverAlreadyOpen
        }
        var waiverRNG = SeededRandom(seed: SeededRandom.derive(
            from: SeededRandom.seed(from: playerID, teamID),
            scope: .week,
            ordinal: calendar.week
        ))
        let entry = ProWaiverEntry(
            id: waiverRNG.uuid(),
            playerID: playerID,
            sourceTeamID: teamID,
            openedAt: calendar,
            claimDeadline: calendar.advancedWeek()
        )
        var next = state
        guard next.proMarket.addWaiver(entry) else {
            throw ProMarketError.waiverAlreadyOpen
        }
        guard WorldIntegrity.check(next).isValid else { throw ProMarketError.invalidRoot }
        return next
    }

    public static func claimWaiver(
        playerID: UUID,
        teamID: UUID,
        at calendar: CalendarState,
        in state: GameState
    ) throws -> GameState {
        guard calendar == state.calendar else { throw ProMarketError.invalidSeason }
        guard let entry = state.proMarket.waivers.first(where: { $0.playerID == playerID }) else {
            throw ProMarketError.waiverNotFound
        }
        guard entry.sourceTeamID != teamID,
              !isBefore(entry.claimDeadline, calendar),
              let source = state.proTeams[entry.sourceTeamID],
              let destination = state.proTeams[teamID],
              destination.rosterIDs.count < ProRules.activeRosterLimit,
              let player = state.players[playerID],
              player.contract != nil else {
            throw ProMarketError.waiverClaimInvalid
        }
        guard source.rosterIDs.contains(playerID) || source.practiceSquadIDs.contains(playerID) else {
            throw ProMarketError.waiverClaimInvalid
        }
        var next = state
        _ = next.proMarket.removeWaiver(entry.id)
        _ = next.proTeams.update(entry.sourceTeamID) {
            $0.rosterIDs.removeAll { $0 == playerID }
            $0.practiceSquadIDs.removeAll { $0 == playerID }
        }
        _ = next.proTeams.update(teamID) { $0.rosterIDs.append(playerID) }
        do {
            guard try ProManagementSystem.capSnapshot(teamID: teamID, in: next).isWithinCap else {
                throw ProMarketError.invalidRoot
            }
        } catch is ProManagementError {
            throw ProMarketError.invalidRoot
        }
        guard WorldIntegrity.check(next).isValid else { throw ProMarketError.invalidRoot }
        return next
    }

    public static func resolveExpiredWaivers(
        at calendar: CalendarState,
        in state: GameState
    ) throws -> GameState {
        var next = state
        for entry in state.proMarket.waivers where isBefore(entry.claimDeadline, calendar) {
            guard next.proMarket.removeWaiver(entry.id) != nil else {
                throw ProMarketError.waiverNotFound
            }
            let receipt = try ProManagementSystem.release(
                playerID: entry.playerID,
                from: entry.sourceTeamID,
                in: next
            )
            next = receipt.state
            if !next.proMarket.freeAgentIDs.contains(entry.playerID) {
                guard next.proMarket.addFreeAgent(entry.playerID) else {
                    throw ProMarketError.invalidRoot
                }
            }
        }
        guard WorldIntegrity.check(next).isValid else { throw ProMarketError.invalidRoot }
        return next
    }

    /// Ends only contracts with authoritative start seasons. Legacy contracts are deliberately
    /// left untouched because their start date is unknowable. Expiry is processed at the final
    /// week, before the next market opens, and returns released players to the same free-agent
    /// identity ledger without creating dead money.
    public static func expireContracts(
        at calendar: CalendarState,
        in state: GameState
    ) throws -> ProContractExpiryReceipt {
        guard calendar == state.calendar,
              calendar.week == SharedRules.inSeasonWeeks else {
            throw ProMarketError.invalidSeason
        }
        let nextSeason = calendar.season + 1

        // One pass classifies every owned professional into exactly one of three outcomes: the deal
        // runs on, the deal ends and the player reaches the market, or the deal ends and the club
        // re-signs because it has no other body at the position.
        //
        // A 53-man roster carries exactly one kicker and one punter, so expiring blindly leaves a
        // team with nobody who can play the position. That was latent until a generated world began
        // issuing contracts: nothing ever expired, so nothing ever hit it. The club keeps that
        // player — but by re-signing, not by leaving a run-out deal attached. The cap invariant
        // reads a contract as valid only while the season is inside its term, so keeping the
        // expired one made 11 of 32 teams permanently illegal the moment the root was projected
        // into the next season, which is exactly what the college portal's commit does. That is how
        // a professional contract rule surfaced as `portalCommitFailed(.postseason)`.
        // `02` §4.2a states the rule.
        var expiring: [(teamID: UUID, playerID: UUID)] = []
        var resigning: [UUID] = []
        for team in state.proTeams.values.sorted(by: { $0.id.uuidString < $1.id.uuidString }) {
            let owned = team.rosterIDs + team.practiceSquadIDs
            var remainingByPosition: [Position: Int] = [:]
            for playerID in owned {
                guard let position = state.players[playerID]?.position else { continue }
                remainingByPosition[position, default: 0] += 1
            }
            for playerID in owned {
                guard let player = state.players[playerID],
                      let contract = player.contract,
                      let signedSeason = contract.signedSeason,
                      nextSeason >= signedSeason + contract.years else { continue }
                let minimum = SharedRules.minimumPlayableRosterByPosition[player.position] ?? 0
                guard remainingByPosition[player.position, default: 0] > minimum else {
                    resigning.append(playerID)
                    continue
                }
                remainingByPosition[player.position, default: 0] -= 1
                expiring.append((team.id, playerID))
            }
        }
        guard expiring.count <= ProMarketState.maximumFreeAgentIDs else {
            throw ProMarketError.invalidRoot
        }

        var next = state
        for (teamID, playerID) in expiring {
            next.proTeams.update(teamID) {
                $0.rosterIDs.removeAll { $0 == playerID }
                $0.practiceSquadIDs.removeAll { $0 == playerID }
            }
            next.players.update(playerID) { $0.contract = nil }
            // The membership test is not redundant with `addFreeAgent`, which returns false both
            // when the pool is full and when the player is already in it. Without it, a player
            // already on the list would be read as an overflowing pool and refuse the whole root.
            if !next.proMarket.freeAgentIDs.contains(playerID) {
                guard next.proMarket.addFreeAgent(playerID) else {
                    throw ProMarketError.invalidRoot
                }
            }
        }
        // A one-year deal at the player's last base salary, signed for the season about to start.
        // No signing bonus, so it carries no dead money if the club moves on next year — and since
        // every contract this project issues is flat-salaried, this never raises a cap hit.
        for playerID in resigning {
            guard let salary = next.players[playerID]?.contract?.baseSalaryByYear.last else {
                continue
            }
            next.players.update(playerID) {
                $0.contract = Contract(
                    years: 1,
                    baseSalaryByYear: [salary],
                    signingBonus: 0
                ).withSignedSeason(nextSeason)
            }
        }
        // Refuses only what expiry itself introduced, rather than every issue the root happens to
        // carry when it is called.
        //
        // A plain `isValid` was unsatisfiable here. Expiry has to run after
        // `SeasonLifecycleSystem.advance`, because FSC-013 legalises a departure only once the
        // player's career record names the season; and it has to run before the college portal
        // commits, because that commit checks the root projected into the *next* season and the cap
        // invariant refuses a contract whose term has run out by then. Between those two points the
        // college rosters are mid-turnover — graduations have happened and the cycle has not
        // refilled them — so the root legitimately carries positional-coverage issues that expiry
        // neither caused nor can fix. Blaming this function for them made the only correct position
        // in the week the one position it refused to run in.
        //
        // The difference is taken by construction rather than by naming the checks expiry is
        // allowed to break, so a check added later is covered the day it is added.
        let inherited = Set(WorldIntegrity.check(state).issues)
        let introduced = WorldIntegrity.check(next).issues.filter { issue in
            !inherited.contains(issue)
        }
        guard introduced.isEmpty else { throw ProMarketError.invalidRoot }
        return ProContractExpiryReceipt(
            state: next,
            expiredPlayerIDs: expiring.map(\.playerID).sorted { $0.uuidString < $1.uuidString }
        )
    }

    public static func close(in state: GameState) throws -> GameState {
        var next = state
        guard next.proMarket.close() else { throw ProMarketError.invalidPhase }
        return next
    }

    private static func isBefore(_ lhs: CalendarState, _ rhs: CalendarState) -> Bool {
        lhs.season < rhs.season || (lhs.season == rhs.season && lhs.week < rhs.week)
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
        var usedIDs = existingIDs.union(state.proMarket.archivedDraftProspectIDs)
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
