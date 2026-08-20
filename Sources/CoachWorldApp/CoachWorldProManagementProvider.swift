import Foundation
import FootballSimCore
import ProFootballCoachUI

public extension CoachWorldReadModelProvider {
    static func proManagement(from state: GameState) -> ProManagementReadModel? {
        guard state.career.college == nil,
              state.careerArc.status == .employed,
              let job = state.careerArc.currentJob,
              job.tier == .professional,
              let team = state.proTeams[job.organisationID],
              let coach = state.career.coachID.flatMap({ state.staff[$0] })
                  ?? team.staffIDs.compactMap({ state.staff[$0] }).first,
              let cap = try? ProManagementSystem.capSnapshot(teamID: team.id, in: state) else {
            return nil
        }

        let activeByPosition = Dictionary(
            grouping: team.rosterIDs.compactMap { state.players[$0]?.position },
            by: { $0 }
        ).mapValues(\.count)

        func row(_ playerID: UUID, kind: String, isActive: Bool) -> ProManagementReadModel.PlayerRow? {
            guard let player = state.players[playerID], let contract = player.contract else {
                return nil
            }
            let minimum = SharedRules.minimumPlayableRosterByPosition[player.position] ?? 0
            let canRelease = !isActive || (activeByPosition[player.position, default: 0] > minimum)
            let action = ProManagementReadModel.ActionRow(
                id: "pro-management:release:\(player.id.uuidString)",
                title: "Release",
                detail: "Add remaining guarantees to dead money.",
                action: .release(playerID: player.id, teamID: team.id),
                isAvailable: canRelease,
                unavailableReason: canRelease
                    ? nil
                    : "The active roster needs one more \(positionLabel(player.position))."
            )
            return ProManagementReadModel.PlayerRow(
                id: player.id,
                name: player.fullName,
                position: positionLabel(player.position),
                rosterKind: kind,
                capHit: contract.capHit(atSeason: state.calendar.season),
                contract: contract,
                action: action
            )
        }

        let active = team.rosterIDs
            .sorted { $0.uuidString < $1.uuidString }
            .compactMap { row($0, kind: "Active", isActive: true) }
        let practice = team.practiceSquadIDs
            .sorted { $0.uuidString < $1.uuidString }
            .compactMap { row($0, kind: "Practice squad", isActive: false) }

        let negotiations = state.proMarket.contractNegotiations
            .filter { $0.teamID == team.id }
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .compactMap { negotiation -> ProManagementReadModel.NegotiationRow? in
                guard let player = state.players[negotiation.playerID] else { return nil }
                let status = negotiation.status.isOpen
                    && negotiation.isPastDeadline(at: state.calendar)
                    ? .expired
                    : negotiation.status
                return ProManagementReadModel.NegotiationRow(
                    id: negotiation.id,
                    playerID: negotiation.playerID,
                    playerName: player.fullName,
                    status: status,
                    currentOffer: negotiation.currentOffer,
                    offerCount: negotiation.offerHistory.count,
                    deadline: negotiation.deadline
                )
            }

        return ProManagementReadModel(
            snapshotID: snapshotID("pro-management", team.id, state.calendar),
            provenance: .simulationSnapshot,
            world: worldReference(state),
            team: teamReference(team.id, in: state),
            coach: CoachWorldPersonReference(
                stableID: coach.id.uuidString,
                name: coach.fullName,
                role: label(coach.role)
            ),
            seasonLabel: seasonLabel(state.calendar),
            calendar: state.calendar,
            cap: ProOffseasonReadModel.CapSummary(snapshot: cap),
            activeRoster: active,
            practiceSquad: practice,
            negotiations: negotiations
        )
    }

    private static func positionLabel(_ position: Position) -> String {
        switch position {
        case .quarterback: return "Quarterback"
        case .runningBack: return "Running back"
        case .wideReceiver: return "Wide receiver"
        case .tightEnd: return "Tight end"
        case .leftTackle: return "Left tackle"
        case .guardPosition: return "Guard"
        case .center: return "Center"
        case .rightTackle: return "Right tackle"
        case .edgeRusher: return "Edge rusher"
        case .defensiveTackle: return "Defensive tackle"
        case .linebacker: return "Linebacker"
        case .cornerback: return "Cornerback"
        case .safety: return "Safety"
        case .kicker: return "Kicker"
        case .punter: return "Punter"
        }
    }
}
