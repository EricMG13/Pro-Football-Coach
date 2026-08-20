import Foundation
import FootballSimCore
import ProFootballCoachUI

public extension CoachWorldReadModelProvider {
    /// Projects the same roster rows used by Roster into explicit lifecycle evidence.
    /// `RosterReadModel` remains the participant authority; this surface only adds fatigue and
    /// suspension/injury facts that already exist in `PlayerLifecycleState`.
    static func teamHealth(from state: GameState) -> TeamHealthReadModel? {
        guard let roster = roster(from: state) else { return nil }
        let statuses = roster.players.compactMap { row -> TeamHealthReadModel.PlayerStatus? in
            guard let playerID = UUID(uuidString: row.stableID),
                  let lifecycle = state.people.playerLifecycle[playerID] else { return nil }
            let absences = [
                lifecycle.injury.map { "Injury \($0.weeksRemaining) week(s) remaining" },
                lifecycle.suspension.map { "Suspension \($0.weeksRemaining) week(s) remaining" }
            ].compactMap { $0 }
            let detail = absences.isEmpty
                ? (lifecycle.fatigue == 0 ? "No recorded fatigue" : "Fatigue is recorded")
                : absences.joined(separator: " · ")
            return TeamHealthReadModel.PlayerStatus(
                stableID: row.stableID,
                name: row.person.name,
                position: row.position,
                condition: row.condition,
                fatigue: lifecycle.fatigue,
                availability: row.availability,
                statusDetail: detail
            )
        }
        let bounded = Array(statuses.prefix(128))
        let averageCondition = bounded.isEmpty
            ? 0
            : bounded.map(\.condition).reduce(0, +) / bounded.count
        let averageFatigue = bounded.isEmpty
            ? 0
            : bounded.map(\.fatigue).reduce(0, +) / bounded.count
        let boundedIDs = bounded.compactMap { UUID(uuidString: $0.stableID) }
        let injuryCount = boundedIDs.filter {
            state.people.playerLifecycle[$0]?.injury != nil
        }.count
        let suspensionCount = boundedIDs.filter {
            state.people.playerLifecycle[$0]?.suspension != nil
        }.count
        return TeamHealthReadModel(
            snapshotID: "health-\(roster.team.stableID)-\(state.calendar.season)-\(state.calendar.week)",
            provenance: .simulationSnapshot,
            world: roster.world,
            team: roster.team,
            coach: roster.coach,
            weekLabel: roster.weekLabel,
            averageCondition: averageCondition,
            averageFatigue: averageFatigue,
            injuryCount: injuryCount,
            suspensionCount: suspensionCount,
            players: bounded,
            canContinue: roster.canContinue,
            continueReason: roster.continueReason
        )
    }
}
