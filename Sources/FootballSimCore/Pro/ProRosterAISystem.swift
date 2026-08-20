import Foundation

public struct ProRosterAITransition: Sendable, Equatable {
    public let state: GameState
    public let eventPayloads: [DomainEventPayload]
    public let signedPlayerIDs: [UUID]

    public init(
        state: GameState,
        eventPayloads: [DomainEventPayload],
        signedPlayerIDs: [UUID]
    ) {
        self.state = state
        self.eventPayloads = eventPayloads
        self.signedPlayerIDs = signedPlayerIDs
    }
}

/// The headless professional roster policy. It operates only during free agency, skips the
/// controlled professional team, and makes one highest-rated legal signing per AI team per week.
/// `ponytail:` one deterministic pass; replace with a richer cap/need model when staff plans exist.
public enum ProRosterAISystem {
    /// How full an AI club lets free agency make it, leaving one seat per draft round it will pick
    /// in. `02` §4.2's beat 1 frees headcount "for free agency *and* the draft"; free agency runs
    /// first, so without a reservation it signs to `activeRosterLimit` and the draft's first pick
    /// then throws `activeRosterFull` — which it did, in every season, while the cap sat at 170M of
    /// 272M. Expiry frees about eleven a roster against seven rounds, so this fits inside what beat
    /// 1 already produces. Not a roster bound: a trade, a waiver claim or a practice-squad promotion
    /// may still carry a club past it, and `activeRosterLimit` stays the only hard limit.
    public static var freeAgencyRosterCeiling: Int {
        max(0, ProRules.activeRosterLimit - ProRules.draftRounds)
    }

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
            } catch {
                // A pick the cap or the roster refuses stops the run rather than spinning on the
                // same team forever. The market stays mid-draft and the next week tries again.
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

        return ProRosterAITransition(state: next, eventPayloads: payloads, signedPlayerIDs: drafted)
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
            guard let team = next.proTeams[teamID],
                  team.rosterIDs.count < freeAgencyRosterCeiling else {
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
