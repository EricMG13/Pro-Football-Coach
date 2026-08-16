import Foundation
import FootballSimCore
import ProFootballCoachUI

public extension CoachWorldReadModelProvider {
    static func collegeOffseason(from state: GameState) -> CollegeOffseasonReadModel? {
        guard let control = state.career.college,
              let programme = state.programmes[control.programmeID],
              let recruiting = state.college.programmes[control.programmeID],
              let coach = state.staff[control.coachID] else { return nil }

        let allPending = state.pending.mandatoryDecisions
            .filter { $0.programmeID == control.programmeID }
        let pending = allPending
            .filter { $0.owner == .user }
            .sorted {
                if $0.deadline != $1.deadline {
                    return isBefore($0.deadline, $1.deadline)
                }
                return $0.id.uuidString < $1.id.uuidString
            }
            .compactMap { decision($0, in: state) }
        guard state.college.phase != .active
                || state.college.portal.phase != .closed
                || !pending.isEmpty else { return nil }

        return CollegeOffseasonReadModel(
            snapshotID: snapshotID("college-offseason", programme.id, state.calendar)
                + "-\(state.college.portal.phase.rawValue)",
            provenance: .simulationSnapshot,
            world: worldReference(state),
            programme: teamReference(programme.id, in: state),
            coach: CoachWorldPersonReference(
                stableID: coach.id.uuidString,
                name: coach.fullName,
                role: label(coach.role)
            ),
            seasonLabel: seasonLabel(state.calendar),
            recruitingSeason: state.college.recruitingSeason,
            cyclePhase: state.college.phase,
            portalPhase: state.college.portal.phase,
            boardCount: recruiting.boardIDs.count,
            scholarshipCount: recruiting.scholarshipPlayerIDs.count,
            contactPointsRemaining: recruiting.contactPointsRemaining,
            nilBudget: recruiting.nilState.annualBudget,
            nilCommitted: recruiting.nilState.annualBudget - recruiting.nilState.remaining,
            portalEntryCount: state.college.portal.entries.count,
            delegatedDecisionCount: allPending.filter {
                if case .delegated = $0.owner { return true }
                return false
            }.count,
            decisions: pending
        )
    }

    private static func isBefore(_ lhs: CalendarState, _ rhs: CalendarState) -> Bool {
        lhs.season < rhs.season || (lhs.season == rhs.season && lhs.week < rhs.week)
    }
}
