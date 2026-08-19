import Foundation
import FootballSimCore
import ProFootballCoachUI

public extension CoachWorldReadModelProvider {
    /// Projects the controlled professional market without exposing hidden draft potential or
    /// inventing transaction legality. Every action carries the exact engine action that will be
    /// revalidated by `IntentResolver` at commit time.
    static func proOffseason(from state: GameState) -> ProOffseasonReadModel? {
        guard state.career.college == nil,
              state.careerArc.status == .employed,
              let job = state.careerArc.currentJob,
              job.tier == .professional,
              let team = state.proTeams[job.organisationID],
              let coach = state.career.coachID.flatMap({ state.staff[$0] })
                  ?? team.staffIDs.compactMap({ state.staff[$0] }).first,
              let cap = try? ProManagementSystem.capSnapshot(teamID: team.id, in: state)
        else { return nil }

        let market = state.proMarket
        let minimumFreeAgentContract = Contract(
            years: 1,
            baseSalaryByYear: [ProRules.bootstrapMinimumSalary],
            signingBonus: 0
        )
        let canAddActivePlayer = team.rosterIDs.count < ProRules.activeRosterLimit
        let canAffordMinimum = cap.remainingCap >= minimumFreeAgentContract.capHit(inYear: 0)
        let canDraft = market.currentPickTeamID == team.id && canAddActivePlayer
        let currentPickLabel = market.currentPickTeamID.flatMap { id in
            state.proTeams[id].map { "Pick \(market.nextPick + 1) · \($0.cityName) \($0.nickname)" }
        }

        var actions: [ProOffseasonReadModel.ActionRow] = []
        switch market.phase {
        case .closed:
            actions.append(action(
                id: "pro:open-offseason",
                title: "Open offseason",
                detail: "Create the next draft class and free-agent ledger.",
                action: .openOffseason
            ))
        case .freeAgency:
            actions.append(action(
                id: "pro:begin-draft",
                title: "Begin draft",
                detail: "Move the league to the controlled draft clock.",
                action: .beginDraft
            ))
        case .draft:
            if !canDraft, let currentPickLabel {
                actions.append(action(
                    id: "pro:wait-draft",
                    title: "Draft clock",
                    detail: currentPickLabel,
                    action: .beginDraft,
                    isAvailable: false,
                    unavailableReason: "The controlled team is not on the clock."
                ))
            }
        case .rosterBuild:
            actions.append(action(
                id: "pro:close-market",
                title: "Close offseason",
                detail: "Return the league to regular-season management.",
                action: .close
            ))
        }

        let expiredWaiverCount = market.waivers.filter {
            isBefore($0.claimDeadline, state.calendar)
        }.count
        if expiredWaiverCount > 0 {
            actions.append(action(
                id: "pro:resolve-waivers",
                title: "Resolve expired waivers",
                detail: "Release \(expiredWaiverCount) unclaimed player(s) into free agency.",
                action: .resolveExpiredWaivers
            ))
        }

        // Already-drafted prospects were never excluded here, unlike `freeAgentIDs` (shrunk by
        // `removeFreeAgent`) and waivers (shrunk by `removeWaiver`) -- an isolated omission, not a
        // deliberate pattern. In ordinary play the controlled team sees this board only once
        // `ProRosterAISystem` has already run every AI pick up to its own turn, so a stale,
        // still-enabled "Draft" row was the common case, not an edge case. Fixed 2026-08-19
        // source-tracing pass; `ProMarketSystem.draft` already refused these correctly
        // (`.duplicateDraftPick`), so nothing illegal could happen -- the row just never disappeared.
        let draftedProspectIDs = Set(market.draftedProspectIDs)
        let prospects = market.draftClass
            .filter { !draftedProspectIDs.contains($0.id) }
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .prefix(ProOffseasonReadModel.maximumRows)
            .map { prospect in
                let observation = market.observations.first {
                    $0.teamID == team.id && $0.prospectID == prospect.id
                }
                let prospectAction: ProOffseasonReadModel.ActionRow?
                switch market.phase {
                case .freeAgency:
                    prospectAction = action(
                        id: "pro:scout:\(prospect.id.uuidString)",
                        title: "Scout",
                        detail: "Record one controlled observation.",
                        action: .scout(teamID: team.id, prospectID: prospect.id)
                    )
                case .draft:
                    prospectAction = action(
                        id: "pro:draft:\(prospect.id.uuidString)",
                        title: "Draft",
                        detail: canDraft ? "Use the rookie contract." : currentPickLabel ?? "Wait for the clock.",
                        action: .draft(
                            prospectID: prospect.id,
                            teamID: team.id,
                            contract: ProMarketSystem.rookieContract(for: prospect.player)
                        ),
                        isAvailable: canDraft,
                        unavailableReason: canDraft ? nil : "The controlled team is not eligible to pick now."
                    )
                default:
                    prospectAction = nil
                }
                return ProOffseasonReadModel.ProspectRow(
                    id: prospect.id,
                    name: prospect.player.fullName,
                    position: positionLabel(prospect.player.position),
                    estimatedOverall: observation?.estimatedOverall,
                    confidence: observation?.confidence,
                    action: prospectAction
                )
            }

        let freeAgents = market.freeAgentIDs
            .sorted { $0.uuidString < $1.uuidString }
            .prefix(ProOffseasonReadModel.maximumRows)
            .compactMap { playerID -> ProOffseasonReadModel.FreeAgentRow? in
                guard let player = state.players[playerID] else { return nil }
                let signAction = action(
                    id: "pro:sign:\(playerID.uuidString)",
                    title: "Sign",
                    detail: "One-year minimum contract.",
                    action: .signFreeAgent(
                        playerID: playerID,
                        teamID: team.id,
                        contract: minimumFreeAgentContract
                    ),
                    isAvailable: canAddActivePlayer && canAffordMinimum,
                    unavailableReason: canAddActivePlayer
                        ? (canAffordMinimum ? nil : "No cap room for the minimum contract.")
                        : "The active roster is full."
                )
                return ProOffseasonReadModel.FreeAgentRow(
                    id: player.id,
                    name: player.fullName,
                    position: positionLabel(player.position),
                    action: signAction
                )
            }

        let waivers = market.waivers
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .prefix(ProOffseasonReadModel.maximumRows)
            .compactMap { entry -> ProOffseasonReadModel.WaiverRow? in
                guard let player = state.players[entry.playerID] else { return nil }
                let sourceIsControlled = entry.sourceTeamID == team.id
                let playerCapHit = player.contract?.capHit(atSeason: state.calendar.season) ?? Int.max
                let deadlineOpen = !isBefore(entry.claimDeadline, state.calendar)
                let canClaim = !sourceIsControlled
                    && deadlineOpen
                    && canAddActivePlayer
                    && playerCapHit <= cap.remainingCap
                let reason: String?
                if sourceIsControlled {
                    reason = "A team cannot claim its own waiver."
                } else if !deadlineOpen {
                    reason = "The claim deadline has passed."
                } else if !canAddActivePlayer {
                    reason = "The active roster is full."
                } else if playerCapHit > cap.remainingCap {
                    reason = "No cap room for this contract."
                } else {
                    reason = nil
                }
                return ProOffseasonReadModel.WaiverRow(
                    id: entry.id,
                    playerID: entry.playerID,
                    name: player.fullName,
                    deadline: weekLabel(entry.claimDeadline),
                    action: action(
                        id: "pro:claim:\(entry.playerID.uuidString)",
                        title: "Claim",
                        detail: "Assume the existing contract.",
                        action: .claimWaiver(playerID: entry.playerID, teamID: team.id),
                        isAvailable: canClaim,
                        unavailableReason: reason
                    )
                )
            }

        return ProOffseasonReadModel(
            snapshotID: snapshotID("pro-offseason", team.id, state.calendar)
                + "-\(market.phase.rawValue)-\(market.nextPick)",
            provenance: .simulationSnapshot,
            world: worldReference(state),
            team: teamReference(team.id, in: state),
            coach: CoachWorldPersonReference(
                stableID: coach.id.uuidString,
                name: coach.fullName,
                role: label(coach.role)
            ),
            seasonLabel: seasonLabel(state.calendar),
            phase: market.phase,
            cap: ProOffseasonReadModel.CapSummary(snapshot: cap),
            currentPickTeamID: market.currentPickTeamID,
            nextPick: market.nextPick,
            totalPicks: market.draftOrder.count,
            actions: actions,
            prospects: Array(prospects),
            freeAgents: Array(freeAgents),
            waivers: Array(waivers)
        )
    }

    private static func action(
        id: String,
        title: String,
        detail: String,
        action: ProMarketAction,
        isAvailable: Bool = true,
        unavailableReason: String? = nil
    ) -> ProOffseasonReadModel.ActionRow {
        ProOffseasonReadModel.ActionRow(
            id: id,
            title: title,
            detail: detail,
            action: action,
            isAvailable: isAvailable,
            unavailableReason: unavailableReason
        )
    }

    private static func isBefore(_ lhs: CalendarState, _ rhs: CalendarState) -> Bool {
        lhs.season < rhs.season || (lhs.season == rhs.season && lhs.week < rhs.week)
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
