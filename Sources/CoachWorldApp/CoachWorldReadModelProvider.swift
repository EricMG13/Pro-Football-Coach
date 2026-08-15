import Foundation
import FootballSimCore
import ProFootballCoachUI

/// Builds screen read models from the authoritative root, so a shipped build shows the simulated
/// world rather than a fixture.
///
/// This is G-01 from `docs/plans/2026-08-12-road-to-beta.md`. Before it, every read model in the
/// build carried `provenance: .sample` and a RELEASE launch reached `ContentUnavailableView`; the
/// beta blocker was not that screens were missing but that nothing connected them to the world.
///
/// **The rule that governs every field below is `04` §4.4: a surface that lacks its engine backing
/// ships without the claim rather than with an invented one.** So there is no formatting here that
/// manufactures a football fact. Where the engine holds nothing — a per-day week plan, an inbox, a
/// staff verdict — the field is empty or nil and the view degrades, and the gap is named in the
/// comment beside it with the register item that closes it. Presentation *wording* for a value the
/// engine does hold is this layer's job and is not invention: `Position.quarterback` becoming "QB"
/// states no fact the root does not.
public enum CoachWorldReadModelProvider {
    /// Nil when no career is under control, which is the only state this cannot describe.
    public static func coachingHQ(from state: GameState) -> CoachingHQReadModel? {
        let organisationID: UUID
        let coach: Staff
        if let control = state.career.college,
           let college = state.programmes[control.programmeID],
           let collegeCoach = state.staff[control.coachID] {
            organisationID = college.id
            coach = collegeCoach
        } else if let job = state.careerArc.currentJob,
                  job.tier == .professional,
                  let team = state.proTeams[job.organisationID],
                  let professionalCoach = state.career.coachID.flatMap({ state.staff[$0] })
                      ?? team.staffIDs.compactMap({ state.staff[$0] }).first {
            organisationID = team.id
            coach = professionalCoach
        } else {
            return nil
        }

        let calendar = state.calendar
        let nextGame = scheduledGame(for: organisationID, in: state)
        let opponentID = nextGame.map {
            $0.homeID == organisationID ? $0.awayID : $0.homeID
        }
        let decisions = state.pending.mandatoryDecisions
            .filter { $0.programmeID == organisationID }

        return CoachingHQReadModel(
            snapshotID: snapshotID("hq", organisationID, calendar),
            provenance: .simulationSnapshot,
            world: worldReference(state),
            team: teamReference(organisationID, in: state),
            coach: CoachWorldPersonReference(
                stableID: coach.id.uuidString,
                name: coach.fullName,
                role: label(coach.role)
            ),
            recordLabel: recordLabel(organisationID, in: state),
            rankLabel: rankLabel(organisationID, in: state),
            // The venue is wherever this week's game is played, which is a fact the schedule holds.
            venue: nextGame.map { venueReference($0.homeID, in: state) },
            week: CoachingHQReadModel.WeekContext(
                seasonLabel: seasonLabel(calendar),
                weekLabel: weekLabel(calendar),
                // The calendar's finest grain is a week (`DomainEvent.CalendarState`), so the
                // "current day" a 7-day strip would name does not exist. Naming the week is the
                // truthful answer at the resolution the engine actually has.
                currentDay: weekLabel(calendar),
                nextDeadline: decisions.map(\.deadline).min(by: calendarOrder)
                    .map { "Due \(weekLabel($0))" } ?? "No deadline this week"
            ),
            weekPlan: weekPlan(
                programmeID: organisationID,
                decisions: decisions,
                nextGame: nextGame,
                in: state
            ),
            unallocatedPracticeMinutes: unallocatedPracticeMinutes(organisationID, in: state),
            opponent: opponentID.map { teamReference($0, in: state) },
            obligations: decisions.map { obligation($0, in: state) },
            decision: decisions.first { $0.owner == .user }
                .flatMap { decision($0, in: state) },
            staffRecommendation: staffRecommendation(
                for: decisions.first,
                organisationID: organisationID,
                in: state
            ),
            // No inbound-event or correspondence system exists — `WorldScheduler`'s
            // `expiringInboundEvents` step is inactive for exactly this reason.
            correspondence: []
        )
    }

    public static func gamePlan(from state: GameState) -> GamePlanReadModel? {
        guard let organisationID = controlledOrganisationID(in: state),
              let team = state.programmes[organisationID].map({ teamReference($0.id, in: state) })
                  ?? state.proTeams[organisationID].map({ teamReference($0.id, in: state) }) else {
            return nil
        }
        let opponent = scheduledGame(for: organisationID, in: state).map { game in
            teamReference(game.homeID == organisationID ? game.awayID : game.homeID, in: state)
        }
        let options = [
            GamePlanReadModel.Option(
                id: "balanced",
                title: "Balanced control",
                plan: .balanced,
                consequence: "Keeps tempo, run/pass balance, and pressure near the staff baseline."
            ),
            GamePlanReadModel.Option(
                id: "pressure",
                title: "Pressure the quarterback",
                plan: TacticalPlan(
                    runPassBias: .runHeavy,
                    tempo: .deliberate,
                    pressure: .attack
                ),
                consequence: "Adds early-down pressure and run support while accepting tempo cost."
            ),
            GamePlanReadModel.Option(
                id: "pace",
                title: "Play with pace",
                plan: TacticalPlan(
                    runPassBias: .passHeavy,
                    tempo: .hurry,
                    pressure: .contain
                ),
                consequence: "Creates more passing volume and pace while reducing defensive aggression."
            )
        ]
        return GamePlanReadModel(
            snapshotID: snapshotID("game-plan", organisationID, state.calendar),
            provenance: .simulationSnapshot,
            team: team,
            opponent: opponent,
            weekLabel: weekLabel(state.calendar),
            currentPlan: state.tactical.plan(for: organisationID, at: state.calendar),
            options: options
        )
    }

    public static func practicePlan(from state: GameState) -> PracticePlanReadModel? {
        guard let organisationID = controlledOrganisationID(in: state),
              let team = state.programmes[organisationID].map({ teamReference($0.id, in: state) })
                  ?? state.proTeams[organisationID].map({ teamReference($0.id, in: state) }) else {
            return nil
        }
        let options = [
            PracticePlanReadModel.Option(
                id: "balanced",
                title: "Balanced week",
                plan: .balanced,
                consequence: "Splits the 60 minutes across install, conditioning, recovery, and focus."
            ),
            PracticePlanReadModel.Option(
                id: "install",
                title: "Install and sharpen",
                plan: TacticalPracticePlan(
                    installMinutes: 30,
                    conditioningMinutes: 10,
                    recoveryMinutes: 5,
                    positionFocusMinutes: 15,
                    positionFocus: nil
                ),
                consequence: "Improves scheme installation while reducing recovery time."
            ),
            PracticePlanReadModel.Option(
                id: "recovery",
                title: "Recover and condition",
                plan: TacticalPracticePlan(
                    installMinutes: 10,
                    conditioningMinutes: 20,
                    recoveryMinutes: 15,
                    positionFocusMinutes: 15,
                    positionFocus: nil
                ),
                consequence: "Protects readiness and conditioning while installing less."
            )
        ]
        return PracticePlanReadModel(
            snapshotID: snapshotID("practice-plan", organisationID, state.calendar),
            provenance: .simulationSnapshot,
            team: team,
            weekLabel: weekLabel(state.calendar),
            currentPlan: state.tactical.practicePlan(for: organisationID, at: state.calendar),
            options: options
        )
    }

    public static func depthChart(from state: GameState) -> DepthChartReadModel? {
        guard let organisationID = controlledOrganisationID(in: state),
              let team = state.programmes[organisationID].map({ teamReference($0.id, in: state) })
                  ?? state.proTeams[organisationID].map({ teamReference($0.id, in: state) }) else {
            return nil
        }
        let rosterIDs = state.programmes[organisationID]?.rosterIDs
            ?? state.proTeams[organisationID]?.rosterIDs
            ?? []
        let roster = rosterIDs.compactMap { state.players[$0] }
        let unavailableIDs = Set(roster.compactMap { player in
            guard state.people.playerLifecycle[player.id]?.isAvailable == true else {
                return player.id
            }
            if state.programmes[organisationID] != nil,
               !CollegeRedshirtSystem.allowsAutomaticAppearance(
                   playerID: player.id,
                   programmeID: organisationID,
                   in: state
               ) {
                return player.id
            }
            return nil
        })
        let derived = DepthChart.derive(roster: roster, unavailableIDs: unavailableIDs)
        let current = state.tactical.personnelPlan(for: organisationID, at: state.calendar)
        let resolved = current?.resolve(roster: roster, unavailableIDs: unavailableIDs) ?? derived
        let overriddenIDs = Set(current?.overrides.flatMap(\.playerIDs) ?? [])
        let positions = Position.allCases.compactMap { position -> DepthChartReadModel.PositionGroup? in
            guard let ids = resolved[position], !ids.isEmpty else { return nil }
            let slots = ids.enumerated().compactMap { index, playerID -> DepthChartReadModel.Slot? in
                guard let player = state.players[playerID] else { return nil }
                // Match authority treats redshirt limits as unavailable even when the
                // lifecycle flag is still healthy. Keep the row text and starter marker on
                // that same bounded predicate so the screen cannot promise a player the
                // detailed or abstract resolver will exclude.
                let available = !unavailableIDs.contains(playerID)
                return DepthChartReadModel.Slot(
                    id: "\(position.rawValue)-\(playerID.uuidString)",
                    playerID: playerID.uuidString,
                    playerName: player.fullName,
                    availability: available ? "Available" : "Unavailable · fallback applies",
                    isStarter: index == 0 && available,
                    isUnavailable: !available,
                    isOverride: overriddenIDs.contains(playerID)
                )
            }
            return DepthChartReadModel.PositionGroup(
                id: position.rawValue,
                title: positionLabel(position),
                slots: slots
            )
        }
        let baseOverrides = derived.compactMap { position, ids -> DepthChartOverride? in
            guard !ids.isEmpty else { return nil }
            return DepthChartOverride(position: position, playerIDs: Array(ids.prefix(3)))
        }
        let rotatedOverrides = derived.compactMap { position, ids -> DepthChartOverride? in
            guard ids.count >= 2 else { return nil }
            return DepthChartOverride(
                position: position,
                playerIDs: [ids[1], ids[0]] + ids.dropFirst(2).prefix(1)
            )
        }
        let options = [
            DepthChartReadModel.Option(
                id: "derived",
                title: "Use derived depth",
                plan: PersonnelPlan(
                    organisationID: organisationID,
                    calendar: state.calendar,
                    overrides: []
                ),
                consequence: "The best available player at each position starts automatically."
            ),
            DepthChartReadModel.Option(
                id: "availability-first",
                title: "Lock available depth",
                plan: PersonnelPlan(
                    organisationID: organisationID,
                    calendar: state.calendar,
                    overrides: baseOverrides
                ),
                consequence: "Saves the current available order and falls back when availability changes."
            ),
            DepthChartReadModel.Option(
                id: "rotate-backups",
                title: "Rotate first backups",
                plan: PersonnelPlan(
                    organisationID: organisationID,
                    calendar: state.calendar,
                    overrides: rotatedOverrides
                ),
                consequence: "Uses the second available player before the derived starter where legal."
            )
        ]
        return DepthChartReadModel(
            snapshotID: snapshotID("depth-chart", organisationID, state.calendar),
            provenance: .simulationSnapshot,
            team: team,
            weekLabel: weekLabel(state.calendar),
            currentPlan: current,
            positions: positions,
            options: options
        )
    }

    private static func controlledOrganisationID(in state: GameState) -> UUID? {
        state.career.college?.programmeID
            ?? (state.careerArc.currentJob?.tier == .professional
                ? state.careerArc.currentJob?.organisationID
                : nil)
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

    /// Produces a bounded staff verdict only when the root carries both a named staff member and
    /// a mandatory decision's reason codes. The confidence is a deterministic presentation of
    /// the coordinator's stored game-planning rating plus the number of independent reasons; it
    /// never claims a staff opinion that the simulation did not record.
    static func staffRecommendation(
        for decision: MandatoryDecision?,
        organisationID: UUID,
        in state: GameState
    ) -> CoachingHQReadModel.StaffRecommendation? {
        guard let decision,
              let programme = state.programmes[organisationID] else { return nil }
        let candidates = programme.staffIDs.compactMap { state.staff[$0] }
        guard let staff = candidates
            .filter({ StaffRole.coordinators.contains($0.role) })
            .max(by: {
                let lhs = ($0.rating(.gamePlanning).value, $0.id.uuidString)
                let rhs = ($1.rating(.gamePlanning).value, $1.id.uuidString)
                return lhs < rhs
            }) else { return nil }
        let recommended = decision.options.first { $0.id == decision.recommendedOptionID }
        let action = recommended.map { label($0.action) } ?? "the balanced option"
        let reason = decision.reasons.prefix(2).map(evidence).joined(separator: " · ")
        let confidence = min(
            95,
            max(25, staff.rating(.gamePlanning).value / 2 + decision.reasons.count * 8)
        )
        return CoachingHQReadModel.StaffRecommendation(
            staff: CoachWorldPersonReference(
                stableID: staff.id.uuidString,
                name: staff.fullName,
                role: label(staff.role)
            ),
            verdict: "Recommend \(action)",
            reason: reason.isEmpty ? "No recorded reason" : reason,
            confidence: "\(confidence)%"
        )
    }

    // MARK: - Shared references

    /// A compact weekly agenda derived only from state that already exists. It deliberately uses
    /// management lanes rather than inventing Monday-to-Sunday assignments: the engine calendar is
    /// week-granular, while the four lanes name the work that can actually be due.
    static func weekPlan(
        programmeID: UUID,
        decisions: [MandatoryDecision],
        nextGame: ScheduledGame?,
        in state: GameState
    ) -> [CoachingHQReadModel.DayPlan] {
        let plan = state.tactical.plan(for: programmeID, at: state.calendar)
        let practiceMinutes = unallocatedPracticeMinutes(programmeID, in: state)
        let recruiting = state.college.programmes[programmeID]
        let recruitingStatus = recruiting.map {
            "\($0.boardIDs.count) prospects · \($0.contactPointsRemaining) pts"
        } ?? "Not available"
        let gameStatus: String
        if let nextGame {
            let opponentID = nextGame.homeID == programmeID ? nextGame.awayID : nextGame.homeID
            let opponent = teamReference(opponentID, in: state).name
            gameStatus = plan == nil ? "Needs plan · vs \(opponent)" : "Plan set · vs \(opponent)"
        } else {
            gameStatus = "No game scheduled"
        }
        return [
            CoachingHQReadModel.DayPlan(
                stableID: "\(programmeID)-inbox-\(state.calendar.season)-\(state.calendar.week)",
                dayLabel: "Inbox",
                assignment: decisions.isEmpty ? "Clear" : "\(decisions.count) due",
                isCurrent: !decisions.isEmpty
            ),
            CoachingHQReadModel.DayPlan(
                stableID: "\(programmeID)-game-plan-\(state.calendar.season)-\(state.calendar.week)",
                dayLabel: "Game plan",
                assignment: gameStatus,
                isCurrent: decisions.isEmpty && nextGame != nil && plan == nil
            ),
            CoachingHQReadModel.DayPlan(
                stableID: "\(programmeID)-practice-\(state.calendar.season)-\(state.calendar.week)",
                dayLabel: "Practice",
                assignment: practiceMinutes == 0 ? "Planned" : "\(practiceMinutes) min open",
                isCurrent: decisions.isEmpty && practiceMinutes > 0
            ),
            CoachingHQReadModel.DayPlan(
                stableID: "\(programmeID)-recruiting-\(state.calendar.season)-\(state.calendar.week)",
                dayLabel: "Recruiting",
                assignment: recruitingStatus,
                isCurrent: false
            )
        ]
    }

    static func worldReference(_ state: GameState) -> CoachWorldReference {
        // Identity only: no view reads `world.name`, and the root holds no name for the universe.
        CoachWorldReference(stableID: state.league.id.uuidString, name: "Football Universe")
    }

    static func teamReference(_ id: UUID, in state: GameState) -> CoachWorldTeamReference {
        let colours = state.identities[id]?.colours
        let name = state.programmes[id]?.name
            ?? state.proTeams[id].map { "\($0.cityName) \($0.nickname)" }
            ?? "Unknown team"
        return CoachWorldTeamReference(
            stableID: id.uuidString,
            name: name,
            abbreviation: abbreviation(name),
            primaryColorHex: colours?.primary.hex,
            secondaryColorHex: colours?.secondary.hex
        )
    }

    static func venueReference(_ organisationID: UUID, in state: GameState)
        -> CoachWorldVenueReference {
        CoachWorldVenueReference(
            stableID: "\(organisationID.uuidString)-venue",
            name: state.identities[organisationID]?.venueName ?? "Venue not set"
        )
    }

    /// The first three letters of the name, which is a rendering of the name rather than a claim
    /// about a mark the generator never produced. `TeamIdentity` carries colours, a venue and
    /// traditions; an abbreviation is not among them.
    static func abbreviation(_ name: String) -> String {
        let letters = name.filter { $0.isLetter }
        return String(letters.prefix(3)).uppercased()
    }

    static func snapshotID(_ kind: String, _ id: UUID, _ calendar: CalendarState) -> String {
        "\(kind)-\(calendar.season)-\(calendar.week)-\(id.uuidString)"
    }

    // MARK: - Competition context

    static func scheduledGame(for organisationID: UUID, in state: GameState) -> ScheduledGame? {
        state.competition.currentSchedule.games.first {
            $0.season == state.calendar.season
                && $0.week == state.calendar.week
                && ($0.homeID == organisationID || $0.awayID == organisationID)
        }
    }

    static func recordLabel(_ organisationID: UUID, in state: GameState) -> String {
        guard let row = standingRow(organisationID, in: state) else { return "0-0" }
        return "\(row.wins)-\(row.losses)"
    }

    static func standingRow(_ organisationID: UUID, in state: GameState) -> StandingRow? {
        for (_, rows) in state.competition.standings {
            if let row = rows.first(where: { $0.id == organisationID }) { return row }
        }
        return nil
    }

    /// Nil rather than an invented placing: an unranked programme has no rank, and `04` §4.4 says
    /// the surface then ships without the claim.
    static func rankLabel(_ organisationID: UUID, in state: GameState) -> String? {
        for (_, order) in state.competition.rankings {
            if let index = order.firstIndex(of: organisationID) { return "#\(index + 1)" }
        }
        return nil
    }

    static func seasonLabel(_ calendar: CalendarState) -> String {
        "Season \(calendar.season + 1)"
    }

    static func weekLabel(_ calendar: CalendarState) -> String { "Week \(calendar.week)" }

    static func calendarOrder(_ lhs: CalendarState, _ rhs: CalendarState) -> Bool {
        lhs.season == rhs.season ? lhs.week < rhs.week : lhs.season < rhs.season
    }

    /// The whole weekly budget when no plan is recorded *for this week*, and nothing once one is:
    /// `TacticalPracticePlan` may only be constructed spending the budget exactly.
    ///
    /// The record's own calendar is what decides, not merely the key's presence. A plan set in week
    /// 3 stays in the store afterwards, so keying on presence alone would report week 4 as fully
    /// allocated on the strength of last week's work.
    static func unallocatedPracticeMinutes(_ organisationID: UUID, in state: GameState) -> Int {
        state.tactical.practicePlansByOrganisation[organisationID]?.calendar == state.calendar
            ? 0
            : TacticalPracticePlan.weeklyMinutes
    }

    // MARK: - Decisions

    static func obligation(_ decision: MandatoryDecision, in state: GameState)
        -> CoachingHQReadModel.Obligation {
        CoachingHQReadModel.Obligation(
            stableID: decision.id.uuidString,
            title: subjectTitle(decision, in: state),
            due: weekLabel(decision.deadline),
            consequence: Self.mandatoryConsequence,
            // Every queued decision is mandatory: `advanceWeek` refuses to run while one is
            // unresolved (`IntentResolutionError.unresolvedMandatoryDecisions`).
            isMandatory: true
        )
    }

    /// Nil when the root's option count cannot satisfy the read model's 2–3 contract. The two agree
    /// today (`MandatoryDecision.optionCountRange` is the same range), so this is a guard against
    /// them drifting apart rather than a case that fires.
    static func decision(_ decision: MandatoryDecision, in state: GameState)
        -> CoachingHQReadModel.Decision? {
        try? CoachingHQReadModel.Decision(
            stableID: decision.id.uuidString,
            title: subjectTitle(decision, in: state),
            deadline: weekLabel(decision.deadline),
            evidence: decision.reasons.map(evidence),
            choices: decision.options.map { option in
                CoachWorldActionChoice(
                    intentID: CoachWorldIntentID(rawValue: option.id.uuidString),
                    title: label(option.action),
                    // The root prices no option, and a cost is a fact. `02` §4 owns what a
                    // recruiting action spends; until a read model can quote it, this states the
                    // decision's own currency rather than a number nothing computed.
                    cost: "This week",
                    consequence: option.id == decision.recommendedOptionID
                        ? "The staff recommendation"
                        : ""
                )
            }
        )
    }

    static func subjectTitle(_ decision: MandatoryDecision, in state: GameState) -> String {
        let name = personName(decision.subject.entityID, in: state)
        switch decision.subject {
        case .recruiting: return "Recruiting: \(name)"
        case .portalRetention: return "Transfer portal: \(name)"
        case .redshirt: return "Redshirt: \(name)"
        case .nilAllocation: return "NIL allocation: \(name)"
        }
    }

    /// What the root actually enforces, rather than a dramatised outcome: `IntentResolver` refuses
    /// `.advanceWeek` while any mandatory decision is unresolved.
    static let mandatoryConsequence = "The week cannot advance while this is open."

    static func personName(_ id: UUID, in state: GameState) -> String {
        if let prospect = state.prospects[id] { return prospect.fullName }
        if let player = state.players[id] { return player.fullName }
        if let departed = state.people.departedPlayers[id] {
            return "\(departed.firstName) \(departed.lastName)"
        }
        return "Unnamed"
    }

    /// One line per reason the root recorded, with its own value. The wording renders the code; the
    /// number is the engine's.
    static func evidence(_ reason: MandatoryDecisionReason) -> String {
        "\(label(reason.code)): \(reason.value)"
    }

    // MARK: - Wording for engine enumerations

    static func label(_ role: StaffRole) -> String {
        switch role {
        case .headCoach: return "Head coach"
        case .offensiveCoordinator: return "Offensive coordinator"
        case .defensiveCoordinator: return "Defensive coordinator"
        case .specialTeamsCoordinator: return "Special teams coordinator"
        case .strengthCoordinator: return "Strength coordinator"
        case .positionCoach: return "Position coach"
        }
    }

    static func label(_ action: MandatoryDecisionAction) -> String {
        switch action {
        case let .recruiting(recruiting): return label(recruiting)
        case .portalRetention: return "Keep"
        case .portalRelease: return "Release"
        case let .redshirt(limit): return limit == nil ? "No redshirt" : "Redshirt"
        case .nilAllocation: return "Set NIL"
        }
    }

    static func label(_ action: RecruitingAction) -> String {
        switch action {
        case .addToBoard: return "Add to board"
        case .contact: return "Contact"
        case .evaluate: return "Evaluate"
        case .scheduleVisit: return "Schedule visit"
        case .offerScholarship: return "Offer scholarship"
        case .setNILAllocation: return "Set NIL"
        case .withdraw: return "Withdraw"
        }
    }

    static func label(_ code: MandatoryDecisionReasonCode) -> String {
        switch code {
        case .rosterNeed: return "Roster need"
        case .rosterPath: return "Roster path"
        case .scholarshipCapacity: return "Scholarship capacity"
        case .nilBudget: return "NIL budget"
        case .playingTime: return "Playing time"
        case .relationship: return "Relationship"
        case .teamSuccess: return "Team success"
        case .restless: return "Restlessness"
        case .eligibility: return "Eligibility"
        case .fit: return "Scheme fit"
        case .deadline: return "Deadline"
        }
    }
}
