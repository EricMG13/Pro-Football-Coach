import Foundation
import FootballSimCore
import ProFootballCoachUI

public extension CoachWorldReadModelProvider {
    static func careerHub(from state: GameState) -> CareerHubReadModel? {
        guard let coachID = state.career.coachID,
              let coach = state.staff[coachID] else { return nil }

        let currentJob: CareerHubReadModel.JobRow?
        if let control = state.career.college,
           let programme = state.programmes[control.programmeID] {
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
                started: weekLabel(job.startedAt)
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
                CareerHubReadModel.OpportunityRow(
                    id: opportunity.id.uuidString,
                    team: teamReference(opportunity.organisationID, in: state),
                    tier: label(opportunity.tier),
                    offered: weekLabel(opportunity.offeredAt),
                    expires: weekLabel(opportunity.expiresAt),
                    prestige: opportunity.prestige.value,
                    rationale: label(opportunity.rationale)
                )
            }

        let support = CareerStakeholder.allCases
            .sorted { $0.rawValue < $1.rawValue }
            .map { stakeholder in
                CareerHubReadModel.SupportRow(
                    id: stakeholder.rawValue,
                    stakeholder: label(stakeholder),
                    value: state.careerArc.stakeholderSupport[stakeholder] ?? 0
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
}
