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
        case .rosterBuild:
            return try buildRosters(in: state, controlledTeamID: controlledTeamID)
        case .closed:
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
            } catch ProManagementError.practiceSquadFull {
                // A club whose squad is full passes, for the reason the active-seat pass existed
                // between 2026-08-20 and 2026-08-23: one club with nowhere to put a player must not
                // end the round for the thirty-one behind it. The prospect stays on the board.
                //
                // This should not fire. Seven picks a season against sixteen seats and a two-season
                // tenure is fourteen at worst, and `.rosterBuild` trims before the next draft. It is
                // here because the alternative to a pass is a stall, and a stall is what this whole
                // slice exists to undo.
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

    /// `.rosterBuild` — where a club turns the squad it drafted into the roster it plays.
    ///
    /// Dead code until 2026-08-23: this phase returned an empty transition, and before the draft was
    /// unstuck the market never even reached it. `02` section 4.2 gives it two jobs, in this order.
    ///
    /// **Promote.** Every active vacancy is filled from the club's own practice squad, best-rated
    /// first. This is the seat a returning veteran and a developing rookie now compete for; before
    /// the amendment the rookie was guaranteed it because the draft seated him directly.
    ///
    /// **Trim.** Then the squad is cut back to its limit and its tenure, lowest-rated first. Tenure
    /// is read from `contract.signedSeason` rather than a new stored field, because a drafted
    /// player's contract is stamped with the season he entered and that is exactly the clock.
    private static func buildRosters(
        in state: GameState,
        controlledTeamID: UUID?
    ) throws -> ProRosterAITransition {
        var next = state
        var payloads: [DomainEventPayload] = []
        var promoted: [UUID] = []

        for teamID in state.proTeams.ids.sorted(by: { $0.uuidString < $1.uuidString })
        where teamID != controlledTeamID {
            while let team = next.proTeams[teamID],
                  team.rosterIDs.count < ProRules.activeRosterLimit,
                  let best = bestByRating(team.practiceSquadIDs, in: next) {
                do {
                    next = try ProMarketSystem.promoteFromPracticeSquad(
                        playerID: best,
                        teamID: teamID,
                        in: next,
                        validateIntegrity: false
                    )
                } catch {
                    break
                }
                payloads.append(.proPracticeSquadMoved(
                    playerID: best,
                    teamID: teamID,
                    promoted: true
                ))
                promoted.append(best)
            }

            while let team = next.proTeams[teamID],
                  let worst = trimmable(team.practiceSquadIDs, in: next, season: next.proMarket.season) {
                do {
                    next = try ProManagementSystem.release(
                        playerID: worst,
                        from: teamID,
                        in: next
                    ).state
                } catch {
                    break
                }
                // No payload: there is no release event that means "trimmed from the squad", and
                // `proCapComplianceRelease` means something else — a club cut to get under the cap.
                // Free agency emits nothing when it declines to sign either. `02` section 4.2 does
                // not make a trim news, so nothing here invents a schema field to say it is.
            }
        }

        return ProRosterAITransition(
            state: next,
            eventPayloads: payloads,
            signedPlayerIDs: promoted
        )
    }

    /// Highest rated, ties on identifier, so the same squad promotes the same player on every run.
    private static func bestByRating(_ ids: [UUID], in state: GameState) -> UUID? {
        ids.compactMap { state.players[$0] }
            .max { lhs, rhs in
                lhs.overall.value == rhs.overall.value
                    ? lhs.id.uuidString > rhs.id.uuidString
                    : lhs.overall.value < rhs.overall.value
            }?
            .id
    }

    /// The player to cut next, or `nil` when the squad is legal. Over the limit, that is the worst
    /// player; otherwise it is the worst player who has served his two seasons. `02` section 4.2:
    /// 224 entering a year fits 448 into 512 seats, so the tenure is what keeps it there.
    private static func trimmable(_ ids: [UUID], in state: GameState, season: Int) -> UUID? {
        let players = ids.compactMap { state.players[$0] }
        func worst(_ pool: [Player]) -> UUID? {
            pool.min { lhs, rhs in
                lhs.overall.value == rhs.overall.value
                    ? lhs.id.uuidString < rhs.id.uuidString
                    : lhs.overall.value < rhs.overall.value
            }?.id
        }
        if players.count > ProRules.practiceSquadLimit { return worst(players) }
        let served = players.filter { player in
            guard let signed = player.contract?.signedSeason else { return false }
            return season - signed >= ProRules.practiceSquadSeasons
        }
        return served.isEmpty ? nil : worst(served)
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
            // The seat reservation is withdrawn — `02` section 4.2, 2026-08-23. It held back one
            // active seat per remaining round so the draft would have somewhere to put its picks;
            // a pick now enters on the practice squad and needs no active seat, so reserving one
            // would hold seven seats empty for nobody and leave the club short all season.
            guard let team = next.proTeams[teamID],
                  team.rosterIDs.count < ProRules.activeRosterLimit else {
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
