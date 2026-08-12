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
    public static func process(at calendar: CalendarState, in state: GameState) throws -> ProRosterAITransition {
        guard calendar == state.calendar, state.proMarket.phase == .freeAgency else {
            return ProRosterAITransition(state: state, eventPayloads: [], signedPlayerIDs: [])
        }
        let controlledTeamID = state.careerArc.currentJob.flatMap { job in
            job.tier == .professional ? job.organisationID : nil
        }
        var next = state
        var payloads: [DomainEventPayload] = []
        var signed: [UUID] = []
        let teamIDs = state.proTeams.ids.sorted { $0.uuidString < $1.uuidString }
        for teamID in teamIDs where teamID != controlledTeamID {
            guard let team = next.proTeams[teamID], team.rosterIDs.count < ProRules.activeRosterLimit else {
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
                    next = try ProMarketSystem.signFreeAgent(
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
        return ProRosterAITransition(
            state: next,
            eventPayloads: payloads,
            signedPlayerIDs: signed
        )
    }
}
