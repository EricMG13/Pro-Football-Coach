import Foundation
import FootballSimCore
import ProFootballCoachUI

public extension CoachWorldReadModelProvider {
    static func careerHub(from state: GameState) -> CareerHubReadModel? {
        guard let coachID = state.career.coachID,
              let coach = state.staff[coachID] else { return nil }

        let currentJob: CareerHubReadModel.JobRow?
        if let control = state.career.college,
           let programme = state.programmes[control.programmeID],
           let job = state.careerArc.currentJob,
           job.tier == .college,
           job.organisationID == control.programmeID {
            currentJob = CareerHubReadModel.JobRow(
                id: "current-\(programme.id.uuidString)",
                team: teamReference(programme.id, in: state),
                tier: "College",
                started: weekLabel(control.startedAt),
                canResign: state.careerArc.currentJob != nil
                    && state.pending.mandatoryDecisions.isEmpty
            )
        } else if let control = state.career.college,
                  let programme = state.programmes[control.programmeID],
                  state.careerArc.currentJob == nil,
                  state.careerArc.status == .seeking {
            currentJob = CareerHubReadModel.JobRow(
                id: "current-\(programme.id.uuidString)",
                team: teamReference(programme.id, in: state),
                tier: "College",
                started: weekLabel(control.startedAt)
            )
        } else if let job = state.careerArc.currentJob {
            currentJob = CareerHubReadModel.JobRow(
                id: "current-\(job.organisationID.uuidString)",
                team: teamReference(job.organisationID, in: state),
                tier: label(job.tier),
                started: weekLabel(job.startedAt),
                canResign: true
            )
        } else {
            currentJob = nil
        }

        let history = state.careerArc.jobHistory
            .sorted {
                if $0.job.startedAt != $1.job.startedAt {
                    return calendarOrder($1.job.startedAt, $0.job.startedAt)
                }
                return $0.job.organisationID.uuidString < $1.job.organisationID.uuidString
            }
            .map { entry in
                CareerHubReadModel.JobRow(
                    id: entry.job.organisationID.uuidString
                        + "-\(entry.job.startedAt.season)-\(entry.job.startedAt.week)",
                    team: teamReference(entry.job.organisationID, in: state),
                    tier: label(entry.job.tier),
                    started: weekLabel(entry.job.startedAt),
                    ended: weekLabel(entry.endedAt),
                    reason: label(entry.reason)
                )
            }

        let opportunities = state.careerArc.opportunities
            .sorted {
                if $0.expiresAt != $1.expiresAt {
                    return calendarOrder($0.expiresAt, $1.expiresAt)
                }
                return $0.id.uuidString < $1.id.uuidString
            }
            .map { opportunity in
                let isExpired = occurs(opportunity.expiresAt, before: state.calendar)
                let canAcceptWhileSeeking = state.careerArc.currentJob == nil
                    && state.careerArc.status == .seeking
                    && state.career.coachID != nil
                    && state.pending.mandatoryDecisions.isEmpty
                let canAcceptWhileEmployed = state.career.college != nil
                    && state.careerArc.currentJob?.tier == .college
                    && state.careerArc.currentJob?.organisationID == state.career.college?.programmeID
                    && state.careerArc.status == .employed
                    && state.pending.mandatoryDecisions.isEmpty
                let canAccept = opportunity.tier == .professional
                    && !occurs(state.calendar, before: opportunity.offeredAt)
                    && !isExpired
                    && (canAcceptWhileEmployed || canAcceptWhileSeeking)
                let unavailableReason: String?
                if canAccept {
                    unavailableReason = nil
                } else if opportunity.tier != .professional {
                    unavailableReason = "Only professional offers are actionable here."
                } else if isExpired {
                    unavailableReason = "This offer has expired."
                } else if state.careerArc.currentJob?.tier == .professional {
                    unavailableReason = "A professional appointment is already active."
                } else if occurs(state.calendar, before: opportunity.offeredAt) {
                    unavailableReason = "This offer is not active yet."
                } else if state.careerArc.status != .seeking {
                    unavailableReason = "The coach is not currently eligible to accept this offer."
                } else {
                    unavailableReason = nil
                }
                return CareerHubReadModel.OpportunityRow(
                    id: opportunity.id.uuidString,
                    team: teamReference(opportunity.organisationID, in: state),
                    tier: label(opportunity.tier),
                    offered: weekLabel(opportunity.offeredAt),
                    expires: weekLabel(opportunity.expiresAt),
                    prestige: opportunity.prestige.value,
                    rationale: label(opportunity.rationale),
                    canAccept: canAccept,
                    unavailableReason: unavailableReason
                )
            }

        let support = CareerStakeholder.allCases
            .sorted { $0.rawValue < $1.rawValue }
            .map { stakeholder in
                CareerHubReadModel.SupportRow(
                    id: stakeholder.rawValue,
                    stakeholder: label(stakeholder),
                    value: state.careerArc.stakeholderSupport[stakeholder] ?? 0,
                    rationale: stakeholderRationale(state.careerArc.stakeholderLastMovement[stakeholder])
                )
            }

        return CareerHubReadModel(
            snapshotID: snapshotID("career", coachID, state.calendar),
            provenance: .simulationSnapshot,
            world: worldReference(state),
            coach: CoachWorldPersonReference(
                stableID: coach.id.uuidString,
                name: coach.fullName,
                role: label(coach.role)
            ),
            status: label(state.careerArc.status),
            currentJob: currentJob,
            history: history,
            opportunities: opportunities,
            support: support
        )
    }

    private static func label(_ tier: CareerJobTier) -> String {
        tier == .college ? "College" : "Professional"
    }

    /// A plain sentence stating the signed delta, never an interpretation beyond it -- there is no
    /// per-stakeholder cause recorded anywhere to attribute the movement to, so the rationale says
    /// only what happened, not why, matching this codebase's convention against invented evidence.
    private static func stakeholderRationale(_ delta: Int?) -> String? {
        guard let delta else { return nil }
        if delta > 0 { return "Rose by \(delta) at the last evaluation." }
        if delta < 0 { return "Fell by \(abs(delta)) at the last evaluation." }
        return "Unchanged at the last evaluation."
    }

    private static func label(_ status: CareerEmploymentStatus) -> String {
        switch status {
        case .employed: return "Employed"
        case .fired: return "Fired"
        case .seeking: return "Seeking"
        }
    }

    private static func label(_ reason: CareerExitReason) -> String {
        switch reason {
        case .fired: return "Fired"
        case .promoted: return "Promoted"
        case .resigned: return "Resigned"
        }
    }

    private static func label(_ rationale: CareerOpportunityRationale) -> String {
        switch rationale {
        case .sustainedCollegeSuccess: return "Sustained college success"
        case .rivalryWin: return "Rivalry win"
        case .staffRecommendation: return "Staff recommendation"
        }
    }

    private static func label(_ stakeholder: CareerStakeholder) -> String {
        switch stakeholder {
        case .administration: return "Administration"
        case .boosters: return "Boosters"
        case .fanbase: return "Fanbase"
        case .lockerRoom: return "Locker room"
        }
    }

    private static func occurs(_ lhs: CalendarState, before rhs: CalendarState) -> Bool {
        lhs.season < rhs.season || (lhs.season == rhs.season && lhs.week < rhs.week)
    }
}
