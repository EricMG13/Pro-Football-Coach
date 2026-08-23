import Foundation

public struct ProRosterAITransition: Sendable, Equatable {
    public let state: GameState
    public let eventPayloads: [DomainEventPayload]
    public let signedPlayerIDs: [UUID]
    /// Picks this pass passed because the club on the clock had no active seat.
    public let passedPicks: Int
    /// Why the draft loop stopped early, when it did. Not persisted and not an event: it is a
    /// diagnostic for tests and probes, and it exists because swallowing this was itself the defect
    /// that let a stalled draft go fifteen weeks without saying so.
    public let stoppedBecause: String?

    public init(
        state: GameState,
        eventPayloads: [DomainEventPayload],
        signedPlayerIDs: [UUID],
        passedPicks: Int = 0,
        stoppedBecause: String? = nil
    ) {
        self.state = state
        self.eventPayloads = eventPayloads
        self.signedPlayerIDs = signedPlayerIDs
        self.passedPicks = passedPicks
        self.stoppedBecause = stoppedBecause
    }
}

/// The headless professional roster policy. It operates only during free agency, skips the
/// controlled professional team, and makes one highest-rated legal signing per AI team per week.
/// `ponytail:` one deterministic pass; replace with a richer cap/need model when staff plans exist.
public enum ProRosterAISystem {

    public static func process(at calendar: CalendarState, in state: GameState) throws -> ProRosterAITransition {
        guard calendar == state.calendar else {
            return ProRosterAITransition(state: state, eventPayloads: [], signedPlayerIDs: [])
        }
        let controlledTeamID = state.careerArc.currentJob.flatMap { job in
            job.tier == .professional ? job.organisationID : nil
        }
        switch state.proMarket.phase {
        case .freeAgency:
            return try signFreeAgents(in: state, controlledTeamID: controlledTeamID)
        case .draft:
            return try makeDraftPicks(in: state, controlledTeamID: controlledTeamID)
        case .closed, .rosterBuild:
            return ProRosterAITransition(state: state, eventPayloads: [], signedPlayerIDs: [])
        }
    }

    /// Every pick the AI is entitled to make, in draft order, best available by rating.
    ///
    /// `02` §4.2: the offseason advances one phase per scheduled week and the draft is made pick by
    /// pick. This stops at the controlled team's pick, because that one is the player's decision and
    /// the design sells it as one. Before promotion no professional team is controlled, so the draft
    /// runs to completion unattended — which is what makes the league a promoted coach inherits a
    /// league that has been living without them.
    private static func makeDraftPicks(
        in state: GameState,
        controlledTeamID: UUID?
    ) throws -> ProRosterAITransition {
        var next = state
        var payloads: [DomainEventPayload] = []
        var drafted: [UUID] = []
        var passed = 0
        var stopped: (any Error)?

        while next.proMarket.phase == .draft,
              let teamID = next.proMarket.currentPickTeamID,
              teamID != controlledTeamID {
            let takenIDs = Set(next.proMarket.draftedProspectIDs)
            let best = next.proMarket.draftClass
                .filter { !takenIDs.contains($0.id) }
                .min { lhs, rhs in
                    lhs.player.overall.value == rhs.player.overall.value
                        ? lhs.id.uuidString < rhs.id.uuidString
                        : lhs.player.overall.value > rhs.player.overall.value
                }
            guard let prospect = best else { break }

            let pick = next.proMarket.nextPick
            let contract = ProMarketSystem.rookieContract(for: prospect.player)
            do {
                next = try ProMarketSystem.draftForScheduler(
                    prospectID: prospect.id,
                    for: teamID,
                    contract: contract,
                    in: next
                )
            } catch ProManagementError.activeRosterFull {
                // `02` section 4.2, 2026-08-23: the club has no seat, so it passes and the club
                // behind it is on the clock. The prospect stays on the board — a pass spends the
                // pick, not the player — so the next club takes the same best available.
                //
                // Measured before this line existed: expiry leaves clubs six to seventeen seats
                // short against seven rounds, the club that lost fewest filled up on its own sixth
                // pick, and `break` then ended the round for the other thirty-one. The market never
                // reached `.rosterBuild` in any season and the draft made 130 of 224 picks by
                // season four.
                guard next.proMarket.passDraftPick() else { break }
                passed += 1
                continue
            } catch {
                // Anything else is not a seat problem and this loop has no policy for it. Recorded
                // rather than swallowed: until 2026-08-23 the error vanished here, so a draft that
                // stalled could not say why and the probes had to re-run it to find out.
                stopped = error
                break
            }
            payloads.append(.proDraftPick(
                prospectID: prospect.id,
                teamID: teamID,
                pick: pick,
                contract: next.players[prospect.id]?.contract
                    ?? contract.withSignedSeason(next.proMarket.season)
            ))
            drafted.append(prospect.id)
        }

        return ProRosterAITransition(
            state: next,
            eventPayloads: payloads,
            signedPlayerIDs: drafted,
            passedPicks: passed,
            stoppedBecause: stopped.map { "\($0)" }
        )
    }

    private static func signFreeAgents(
        in state: GameState,
        controlledTeamID: UUID?
    ) throws -> ProRosterAITransition {
        var next = state
        var payloads: [DomainEventPayload] = []
        var signed: [UUID] = []
        let teamIDs = state.proTeams.ids.sorted { $0.uuidString < $1.uuidString }
        for teamID in teamIDs where teamID != controlledTeamID {
            // `02` §4.2: free agency signs while legal *and* while the roster leaves room for the
            // picks the team still holds. Without the reserve the draft could never take a player
            // at any seed -- free agency signs until the pool is dry, and a dry pool is exactly the
            // pass that starts the draft, so the draft always opened with all 53 seats filled and
            // every pick threw `activeRosterFull`.
            //
            // Counted from the draft order rather than from `ProRules.draftRounds`, so a team
            // holding an unusual number of picks reserves for the picks it actually holds. Clamped
            // at zero because the order arrives from disk.
            let remainingPicks = next.proMarket.draftOrder
                .dropFirst(next.proMarket.nextPick)
                .filter { $0 == teamID }
                .count
            let signingLimit = max(0, ProRules.activeRosterLimit - remainingPicks)
            guard let team = next.proTeams[teamID], team.rosterIDs.count < signingLimit else {
                continue
            }
            let candidates = next.proMarket.freeAgentIDs
                .compactMap { playerID -> Player? in next.players[playerID] }
                .sorted {
                    if $0.overall.value != $1.overall.value {
                        return $0.overall.value > $1.overall.value
                    }
                    return $0.id.uuidString < $1.id.uuidString
                }
            for candidate in candidates {
                let contract = ProMarketSystem.rookieContract(for: candidate)
                do {
                    // The scheduler validates the complete root at its integrity boundary after
                    // this batch; avoid repeating that full check for every AI signing.
                    next = try ProMarketSystem.signFreeAgentForScheduler(
                        playerID: candidate.id,
                        teamID: teamID,
                        contract: contract,
                        in: next
                    )
                } catch ProManagementError.capExceeded {
                    continue
                } catch ProManagementError.activeRosterFull {
                    break
                }
                payloads.append(.proPlayerSigned(
                    playerID: candidate.id,
                    teamID: teamID,
                    kind: .freeAgency,
                    contract: next.players[candidate.id]?.contract ?? contract.withSignedSeason(next.proMarket.season)
                ))
                signed.append(candidate.id)
                break
            }
        }
        // A pass that signs nobody means the pool is dry or every roster is full, so free agency has
        // nothing left to give and the draft begins. `02` §4.2's falsifier is that a season passes
        // with no draft pick; without this line that was the measured behaviour of every season.
        if signed.isEmpty, next.proMarket.phase == .freeAgency {
            next = try ProMarketSystem.beginDraft(in: next)
            payloads.append(.proDraftStarted(season: next.proMarket.season))
        }

        return ProRosterAITransition(
            state: next,
            eventPayloads: payloads,
            signedPlayerIDs: signed
        )
    }
}
