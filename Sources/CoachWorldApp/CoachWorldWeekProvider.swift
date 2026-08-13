import Foundation
import FootballSimCore
import ProFootballCoachUI

/// P12 week-family read models. Same G-01 rule as the HQ and personnel providers: a field the
/// root does not hold stays empty, and the test that pins the blank names the gap that would
/// fill it.
public extension CoachWorldReadModelProvider {
    static func inbox(from state: GameState) -> InboxReadModel? {
        guard let frame = frame(from: state),
              let control = state.career.college else { return nil }
        let decisions = state.pending.mandatoryDecisions
            .filter { $0.programmeID == control.programmeID }
        return InboxReadModel(
            snapshotID: snapshotID("inbox", control.programmeID, state.calendar),
            provenance: .simulationSnapshot,
            frame: frame,
            commitments: decisions.map { agendaItem($0, in: state) },
            correspondence: []
        )
    }

    static func opponentReport(from state: GameState) -> OpponentReportReadModel? {
        guard let frame = frame(from: state),
              let control = state.career.college else { return nil }
        let nextGame = scheduledGame(for: control.programmeID, in: state)
        let opponentID = nextGame.map { $0.homeID == control.programmeID ? $0.awayID : $0.homeID }
        let snapshot = opponentID.flatMap { state.tactical.scouting(for: $0) }
        return OpponentReportReadModel(
            snapshotID: snapshotID("film", control.programmeID, state.calendar),
            provenance: .simulationSnapshot,
            frame: frame,
            opponent: opponentID.map { teamReference($0, in: state) },
            venue: nextGame.map { venueReference($0.homeID, in: state) },
            passRate: snapshot?.passRate,
            turnoverRate: snapshot?.turnoverRate,
            observedThroughLabel: snapshot.map { weekLabel($0.observedThrough) }
        )
    }

    static func gamePlan(from state: GameState) -> GamePlanReadModel? {
        guard let frame = frame(from: state),
              let control = state.career.college else { return nil }
        let nextGame = scheduledGame(for: control.programmeID, in: state)
        let opponentID = nextGame.map { $0.homeID == control.programmeID ? $0.awayID : $0.homeID }
        let plan = state.tactical.plan(for: control.programmeID, at: state.calendar)
        return GamePlanReadModel(
            snapshotID: snapshotID("plan", control.programmeID, state.calendar),
            provenance: .simulationSnapshot,
            frame: frame,
            opponent: opponentID.map { teamReference($0, in: state) },
            runPass: plan.map { choice($0.runPassBias) },
            tempo: plan.map { choice($0.tempo) },
            pressure: plan.map { choice($0.pressure) }
        )
    }

    static func practicePlan(from state: GameState) -> PracticePlanReadModel? {
        guard let frame = frame(from: state),
              let control = state.career.college else { return nil }
        let recorded = state.tactical.practicePlan(
            for: control.programmeID,
            at: state.calendar
        )
        return PracticePlanReadModel(
            snapshotID: snapshotID("practice", control.programmeID, state.calendar),
            provenance: .simulationSnapshot,
            frame: frame,
            weeklyMinutes: TacticalPracticePlan.weeklyMinutes,
            installMinutes: recorded?.installMinutes ?? 0,
            conditioningMinutes: recorded?.conditioningMinutes ?? 0,
            recoveryMinutes: recorded?.recoveryMinutes ?? 0,
            positionFocusMinutes: recorded?.positionFocusMinutes ?? 0,
            positionFocusLabel: recorded?.positionFocus.map { label($0) },
            matchingPreset: recorded.flatMap(preset(matching:)),
            isRecordedThisWeek: recorded != nil
        )
    }

    static func teamHealth(from state: GameState) -> TeamHealthReadModel? {
        guard let frame = frame(from: state),
              let control = state.career.college,
              let programme = state.programmes[control.programmeID] else { return nil }
        let players = programme.rosterIDs.compactMap { state.players[$0] }
        let numbers = JerseyNumbers.assign(players)
        let rows: [TeamHealthReadModel.PlayerRow] = players.compactMap { player in
            let lifecycle = state.people.playerLifecycle[player.id]
            let injury = lifecycle?.injury
            let available = lifecycle?.isAvailable ?? true
            guard injury != nil || available == false else { return nil }
            return TeamHealthReadModel.PlayerRow(
                stableID: player.id.uuidString,
                person: person(player),
                number: numbers[player.id] ?? 0,
                position: label(player.position),
                availability: availability(player, in: state),
                condition: condition(player, in: state),
                injuryLabel: injury.map { label($0.area) },
                weeksRemaining: injury?.weeksRemaining
            )
        }
        .sorted { lhs, rhs in
            let leftWeeks = lhs.weeksRemaining ?? 0
            let rightWeeks = rhs.weeksRemaining ?? 0
            if leftWeeks != rightWeeks { return leftWeeks > rightWeeks }
            return lhs.stableID < rhs.stableID
        }
        let injured = players.filter { state.people.playerLifecycle[$0.id]?.injury != nil }.count
        let available = players.filter { state.people.playerLifecycle[$0.id]?.isAvailable ?? true }.count
        return TeamHealthReadModel(
            snapshotID: snapshotID("health", control.programmeID, state.calendar),
            provenance: .simulationSnapshot,
            frame: frame,
            rosterCount: players.count,
            availableCount: available,
            injuredCount: injured,
            rows: rows
        )
    }

    static func aftermath(from state: GameState) -> AftermathReadModel? {
        guard let frame = frame(from: state),
              let control = state.career.college else { return nil }
        let last = lastCompletedGame(for: control.programmeID, in: state)
        let result = last?.result
        let isHome = last.map { $0.homeID == control.programmeID }
        let opponentID = last.map { $0.homeID == control.programmeID ? $0.awayID : $0.homeID }
        let ourScore: Int?
        let theirScore: Int?
        if let result, let isHome {
            ourScore = isHome ? result.homeScore : result.awayScore
            theirScore = isHome ? result.awayScore : result.homeScore
        } else {
            ourScore = nil
            theirScore = nil
        }
        let review = last.flatMap { game in
            state.tactical.reviews.last { review in
                review.organisationID == control.programmeID
                    && review.opponentID == (game.homeID == control.programmeID
                        ? game.awayID : game.homeID)
                    && review.calendar.season == game.season
                    && review.calendar.week == game.week
            }
        }
        return AftermathReadModel(
            snapshotID: snapshotID("aftermath", control.programmeID, state.calendar),
            provenance: .simulationSnapshot,
            frame: frame,
            opponent: opponentID.map { teamReference($0, in: state) },
            ourScore: ourScore,
            theirScore: theirScore,
            isHome: isHome,
            gameWeekLabel: last.map { "Week \($0.week)" },
            runPass: review.map { choice($0.plan.runPassBias) },
            tempo: review.map { choice($0.plan.tempo) },
            pressure: review.map { choice($0.plan.pressure) },
            opponentPassRate: review?.opponentPassRate,
            opponentTurnoverRate: review?.opponentTurnoverRate
        )
    }

    static func practicePlan(for preset: CoachWorldPracticePreset) -> TacticalPracticePlan {
        switch preset {
        case .balanced:
            return .balanced
        case .install:
            return TacticalPracticePlan(
                installMinutes: 30,
                conditioningMinutes: 15,
                recoveryMinutes: 15,
                positionFocusMinutes: 0,
                positionFocus: nil
            )
        case .conditioning:
            return TacticalPracticePlan(
                installMinutes: 15,
                conditioningMinutes: 30,
                recoveryMinutes: 15,
                positionFocusMinutes: 0,
                positionFocus: nil
            )
        case .recovery:
            return TacticalPracticePlan(
                installMinutes: 15,
                conditioningMinutes: 15,
                recoveryMinutes: 30,
                positionFocusMinutes: 0,
                positionFocus: nil
            )
        }
    }

    static func tacticalPlan(
        runPass: CoachWorldRunPassChoice,
        tempo: CoachWorldTempoChoice,
        pressure: CoachWorldPressureChoice
    ) -> TacticalPlan {
        TacticalPlan(
            runPassBias: bias(runPass),
            tempo: engineTempo(tempo),
            pressure: enginePressure(pressure)
        )
    }

    // MARK: - Frame

    static func frame(from state: GameState) -> CoachWorldFrameContext? {
        guard let control = state.career.college,
              let programme = state.programmes[control.programmeID],
              let coach = state.staff[control.coachID] else { return nil }
        let due = state.pending.mandatoryDecisions.filter { $0.programmeID == programme.id }.count
        return CoachWorldFrameContext(
            team: teamReference(programme.id, in: state),
            coach: CoachWorldPersonReference(
                stableID: coach.id.uuidString,
                name: coach.fullName,
                role: label(coach.role)
            ),
            seasonLabel: seasonLabel(state.calendar),
            weekLabel: weekLabel(state.calendar),
            recordLabel: recordLabel(programme.id, in: state),
            rankLabel: rankLabel(programme.id, in: state),
            mandatoryDueCount: due
        )
    }

    // MARK: - Mapping

    private static func agendaItem(_ decision: MandatoryDecision, in state: GameState)
        -> CoachWorldAgendaItem {
        let delegatedName: String?
        if case let .delegated(staffID) = decision.owner {
            delegatedName = state.staff[staffID]?.fullName
        } else {
            delegatedName = nil
        }
        let stateKind: CoachWorldAgendaItem.State
        let detail: String
        if let delegatedName {
            stateKind = .delegated
            detail = "Delegated — \(delegatedName)"
        } else {
            stateKind = .mandatory
            detail = mandatoryConsequence
        }
        return CoachWorldAgendaItem(
            stableID: decision.id.uuidString,
            title: subjectTitle(decision, in: state),
            detail: detail,
            cost: weekLabel(decision.deadline),
            state: stateKind
        )
    }

    private static func lastCompletedGame(for organisationID: UUID, in state: GameState)
        -> ScheduledGame? {
        state.competition.currentSchedule.games
            .filter {
                ($0.homeID == organisationID || $0.awayID == organisationID)
                    && $0.result != nil
                    && $0.season == state.calendar.season
            }
            .max { lhs, rhs in
                lhs.week == rhs.week
                    ? lhs.id.uuidString < rhs.id.uuidString
                    : lhs.week < rhs.week
            }
    }

    private static func choice(_ bias: TacticalRunPassBias) -> CoachWorldRunPassChoice {
        switch bias {
        case .runHeavy: return .runHeavy
        case .balanced: return .balanced
        case .passHeavy: return .passHeavy
        }
    }

    private static func choice(_ tempo: TacticalTempo) -> CoachWorldTempoChoice {
        switch tempo {
        case .deliberate: return .deliberate
        case .balanced: return .balanced
        case .hurry: return .hurry
        }
    }

    private static func choice(_ pressure: TacticalPressure) -> CoachWorldPressureChoice {
        switch pressure {
        case .contain: return .contain
        case .balanced: return .balanced
        case .attack: return .attack
        }
    }

    private static func bias(_ choice: CoachWorldRunPassChoice) -> TacticalRunPassBias {
        switch choice {
        case .runHeavy: return .runHeavy
        case .balanced: return .balanced
        case .passHeavy: return .passHeavy
        }
    }

    private static func engineTempo(_ choice: CoachWorldTempoChoice) -> TacticalTempo {
        switch choice {
        case .deliberate: return .deliberate
        case .balanced: return .balanced
        case .hurry: return .hurry
        }
    }

    private static func enginePressure(_ choice: CoachWorldPressureChoice) -> TacticalPressure {
        switch choice {
        case .contain: return .contain
        case .balanced: return .balanced
        case .attack: return .attack
        }
    }

    private static func preset(matching plan: TacticalPracticePlan) -> CoachWorldPracticePreset? {
        for preset in CoachWorldPracticePreset.allCases {
            if practicePlan(for: preset) == plan { return preset }
        }
        return nil
    }

    private static func label(_ group: PositionGroup) -> String {
        switch group {
        case .quarterbacks: return "Quarterbacks"
        case .runningBacks: return "Running backs"
        case .receivers: return "Receivers"
        case .offensiveLine: return "Offensive line"
        case .defensiveLine: return "Defensive line"
        case .linebackers: return "Linebackers"
        case .secondary: return "Secondary"
        case .specialists: return "Specialists"
        }
    }
}
