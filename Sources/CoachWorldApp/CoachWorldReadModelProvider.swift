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
        guard let control = state.career.college,
              let programme = state.programmes[control.programmeID],
              let coach = state.staff[control.coachID] else { return nil }

        let calendar = state.calendar
        let nextGame = scheduledGame(for: programme.id, in: state)
        let opponentID = nextGame.map { $0.homeID == programme.id ? $0.awayID : $0.homeID }
        let decisions = state.pending.mandatoryDecisions
            .filter { $0.programmeID == programme.id }

        return CoachingHQReadModel(
            snapshotID: snapshotID("hq", programme.id, calendar),
            provenance: .simulationSnapshot,
            world: worldReference(state),
            team: teamReference(programme.id, in: state),
            coach: CoachWorldPersonReference(
                stableID: coach.id.uuidString,
                name: coach.fullName,
                role: label(coach.role)
            ),
            recordLabel: recordLabel(programme.id, in: state),
            rankLabel: rankLabel(programme.id, in: state),
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
            // Empty by construction, not by omission: there is no per-day plan in the root to
            // render. G-14 (engine-owned load policy) is what gives this strip something to say.
            weekPlan: [],
            unallocatedPracticeMinutes: unallocatedPracticeMinutes(programme.id, in: state),
            opponent: opponentID.map { teamReference($0, in: state) },
            obligations: decisions.map { obligation($0, in: state) },
            decision: decisions.first { $0.owner == .user }
                .flatMap { decision($0, in: state) },
            // G-02: engine-owned verdicts with named-staff attribution do not exist. A
            // recommendation needs a verdict, a reason *and* a confidence; the root holds a
            // recommended option and reason codes but no confidence, so three-quarters of a
            // recommendation would have to be invented to show any of it.
            staffRecommendation: nil,
            // No inbound-event or correspondence system exists — `WorldScheduler`'s
            // `expiringInboundEvents` step is inactive for exactly this reason.
            correspondence: []
        )
    }

    // MARK: - Shared references

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
