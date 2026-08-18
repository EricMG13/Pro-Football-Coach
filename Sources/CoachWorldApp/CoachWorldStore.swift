import Foundation
import Observation
import FootballSimCore
import ProFootballCoachUI

/// The application service: it owns the career, and it is the only observable the screens read.
///
/// It deliberately imports `Observation` rather than SwiftUI. `@Observable` is not a UI type, and
/// keeping this file free of a UI import is what lets it hold `GameState` without standing in front
/// of the boundary `03b` §1 draws — the contract scan forbids the root to any file that imports a
/// UI framework, and this one does not.
///
/// Every mutation goes through `CareerSession`, an actor, so the world advances off the main actor
/// and the screen keeps rendering while it does. That matters before it is measured: D4 budgets a
/// week advance at 2.0 s and the M2 soak measured about 0.6 s per week on a development Mac, so a
/// synchronous advance would freeze the interface for something close to the whole budget.
@MainActor
@Observable
public final class CoachWorldStore {
    public enum StartError: Error, Equatable {
        case noProgrammeAvailable
        case programmeUnavailable(UUID)
    }

    /// The seed a new career uses until a world-setup screen offers a choice.
    ///
    /// Fixed rather than drawn from the clock, and deliberately so for the beta: every tester then
    /// plays the same world, which makes a report about week 4 reproducible on the owner's device
    /// instead of a story about a world nobody else can reach.
    public static let defaultSeed: UInt64 = 20_260_812

    /// Nil only while a career has not been started, which the root view treats as its title state.
    public private(set) var coachingHQ: CoachingHQReadModel?
    /// Rebuilt alongside the HQ rather than on navigation, so moving between screens is a state
    /// change rather than a wait. A college roster is 85 rows; the whole model costs microseconds
    /// beside the seconds a week advance already takes.
    public private(set) var roster: RosterReadModel?
    public private(set) var recruitingBoard: RecruitingBoardReadModel?
    public private(set) var leagueMap: LeagueMapReadModel?
    public private(set) var matchDay: MatchDayReadModel?
    public private(set) var aftermath: AftermathReadModel?
    public private(set) var careerHub: CareerHubReadModel?
    public private(set) var standings: StandingsReadModel?
    public private(set) var schedule: ScheduleReadModel?
    public private(set) var teamProgrammeProfile: TeamProgrammeProfileReadModel?
    public private(set) var worldSearch: WorldSearchReadModel?
    public private(set) var competitionOverview: CompetitionOverviewReadModel?
    public private(set) var gamePlan: GamePlanReadModel?
    public private(set) var practicePlan: PracticePlanReadModel?
    public private(set) var depthChart: DepthChartReadModel?
    public private(set) var teamHealth: TeamHealthReadModel?
    public private(set) var collegeOffseason: CollegeOffseasonReadModel?
    public private(set) var proOffseason: ProOffseasonReadModel?
    public private(set) var proManagement: ProManagementReadModel?
    public private(set) var staffRoom: StaffRoomReadModel?
    public private(set) var inbox: InboxReadModel?
    public private(set) var opponentFilm: OpponentFilmReadModel?
    public private(set) var news: NewsReadModel?
    public private(set) var legacyHistory: LegacyHistoryReadModel?
    public private(set) var statisticsLeaders: StatisticsLeadersReadModel?
    public private(set) var awardsHonours: AwardsHonoursReadModel?
    public private(set) var realignment: RealignmentReadModel?
    /// True while an intent is in flight. Screens disable their commit controls on it.
    public private(set) var isWorking = false
    /// The last receipt or refusal, shown verbatim. Never a guess about what happened.
    public private(set) var statusMessage: String?
    public private(set) var presentationRoute: String
    /// The stable subject carried by a focused route. It is intentionally presentation-only; the
    /// authoritative recruiting and team providers still resolve the ID against the snapshot.
    public var presentationSubjectID: UUID? { presentation.selectedSubjectID }

    private let session: CareerSession
    private var presentation: CareerPresentationState
    private var metadata: CareerSaveMetadata
    private var mutationGeneration: UInt64 = 0

    private init(
        session: CareerSession,
        snapshot: GameState,
        presentation: CareerPresentationState = CareerPresentationState(route: "8"),
        metadata: CareerSaveMetadata = CareerSaveMetadata()
    ) {
        self.session = session
        self.presentation = presentation
        self.metadata = metadata
        self.presentationRoute = presentation.route
        rebuildScreens(from: snapshot)
    }

    /// Rebuild every route-scoped read model from the actor snapshot in one place.
    private func rebuildScreens(from snapshot: GameState) {
        coachingHQ = CoachWorldReadModelProvider.coachingHQ(from: snapshot)
        roster = CoachWorldReadModelProvider.roster(from: snapshot)
        recruitingBoard = CoachWorldReadModelProvider.recruitingBoard(from: snapshot)
        leagueMap = CoachWorldReadModelProvider.leagueMap(from: snapshot)
        matchDay = CoachWorldReadModelProvider.matchDay(from: snapshot)
        aftermath = CoachWorldReadModelProvider.aftermath(from: snapshot)
        careerHub = CoachWorldReadModelProvider.careerHub(from: snapshot)
        standings = CoachWorldReadModelProvider.standings(from: snapshot)
        schedule = CoachWorldReadModelProvider.schedule(from: snapshot)
        let controlledID = snapshot.career.college?.programmeID
            ?? (snapshot.careerArc.currentJob?.organisationID)
        let selectedID = presentation.selectedSubjectID ?? controlledID
        teamProgrammeProfile = selectedID.flatMap {
            CoachWorldReadModelProvider.teamProgrammeProfile($0, from: snapshot)
        }
        worldSearch = CoachWorldReadModelProvider.worldSearch(from: snapshot)
        competitionOverview = CoachWorldReadModelProvider.competitionOverview(from: snapshot)
        gamePlan = CoachWorldReadModelProvider.gamePlan(from: snapshot)
        practicePlan = CoachWorldReadModelProvider.practicePlan(from: snapshot)
        depthChart = CoachWorldReadModelProvider.depthChart(from: snapshot)
        teamHealth = CoachWorldReadModelProvider.teamHealth(from: snapshot)
        collegeOffseason = CoachWorldReadModelProvider.collegeOffseason(from: snapshot)
        proOffseason = CoachWorldReadModelProvider.proOffseason(from: snapshot)
        proManagement = CoachWorldReadModelProvider.proManagement(from: snapshot)
        staffRoom = CoachWorldReadModelProvider.staffRoom(from: snapshot)
        inbox = CoachWorldReadModelProvider.inbox(
            from: snapshot,
            readInboxItemIDs: Set(presentation.readInboxItemIDs)
        )
        opponentFilm = CoachWorldReadModelProvider.opponentFilm(from: snapshot)
        news = CoachWorldReadModelProvider.news(from: snapshot)
        legacyHistory = CoachWorldReadModelProvider.legacyHistory(from: snapshot)
        statisticsLeaders = CoachWorldReadModelProvider.statisticsLeaders(from: snapshot)
        awardsHonours = CoachWorldReadModelProvider.awardsHonours(from: snapshot)
        realignment = CoachWorldReadModelProvider.realignment(from: snapshot)
    }

    /// Generates a world from `seed` and appoints the selected starting programme.
    ///
    /// The optional selection and identity are supplied by the entry flow. Defaults preserve the
    /// proof harness and old callers while still making a direct API call deterministic.
    ///
    /// `nonisolated`, and the generation runs detached, because it is seconds of work on 15,766
    /// players and 2,158 staff. A `@MainActor` static would have run all of it on the main actor
    /// and frozen the title screen — including the progress indicator that exists to say it is
    /// working.
    public nonisolated static func newCareer(
        seed: UInt64,
        firstName: String = "",
        lastName: String = "",
        programmeID: UUID? = nil
    ) async throws -> CoachWorldStore {
        let started = try await Task.detached(priority: .userInitiated) {
            let world = GameState.bootstrap(seed: seed)
            let candidates = world.programmes.values.sorted {
                $0.prestige.value == $1.prestige.value
                    ? $0.id.uuidString < $1.id.uuidString
                    : $0.prestige.value < $1.prestige.value
            }
            guard let first = candidates.first else { throw StartError.noProgrammeAvailable }
            let selected: Programme
            if let programmeID {
                guard let requested = candidates.first(where: { $0.id == programmeID }) else {
                    throw StartError.programmeUnavailable(programmeID)
                }
                selected = requested
            } else {
                selected = first
            }
            var started = try CareerControlSystem.startCollegeCareer(at: selected.id, in: world).state
            let cleanFirst = String(firstName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(24))
            let cleanLast = String(lastName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(24))
            if let coachID = started.career.coachID {
                _ = started.staff.update(coachID) { coach in
                    if !cleanFirst.isEmpty { coach.firstName = cleanFirst }
                    if !cleanLast.isEmpty { coach.lastName = cleanLast }
                }
            }
            return started
        }.value
        return try await make(
            from: CoachWorldSaveDocument(
                gameState: started,
                presentation: CareerPresentationState(route: "8"),
                metadata: CareerSaveMetadata(createdFromSeed: seed)
            )
        )
    }

    public nonisolated static func startingJobs(seed: UInt64, limit: Int = 3) async -> [StartingJobReadModel] {
        await Task.detached(priority: .userInitiated) {
            CoachWorldReadModelProvider.startingJobs(
                from: GameState.bootstrap(seed: seed),
                limit: limit
            )
        }.value
    }

    /// Decoding is detached for the same reason, and it also runs the whole-root integrity check
    /// that `GameState`'s decoder performs — the most expensive thing the app ever does at launch.
    public nonisolated static func load(from data: Data) async throws -> CoachWorldStore {
        let decoded = try await Task.detached(priority: .userInitiated) {
            try CoachWorldSaveDocument.decode(envelopeData: data)
        }.value
        return try await make(from: decoded)
    }

    public nonisolated static func load(
        document: CoachWorldSaveDocument
    ) async throws -> CoachWorldStore {
        try await make(from: document)
    }

    private nonisolated static func make(
        from document: CoachWorldSaveDocument
    ) async throws -> CoachWorldStore {
        let session = try CareerSession(state: document.gameState)
        // The session refreshes mandatory decisions and re-checks integrity in its initialiser, so
        // the read model must be built from what it holds rather than from what was handed to it.
        let snapshot = await session.snapshot()
        return await CoachWorldStore(
            session: session,
            snapshot: snapshot,
            presentation: document.presentation,
            metadata: document.metadata
        )
    }

    public func save() async throws -> Data {
        let document = try await saveDocument()
        return try await Task.detached(priority: .utility) {
            try SaveEnvelope.encode(document)
        }.value
    }

    public func saveDocument() async throws -> CoachWorldSaveDocument {
        // A snapshot taken while a session intent is still committing can be older than the
        // mutation generation assigned after that intent. Wait at the app seam so an autosave
        // cannot publish a stale world as the newest document.
        while isWorking {
            try Task.checkCancellation()
            await Task.yield()
        }
        // Snapshotting is an actor hop. If a mutation commits while it is suspended, retry so a
        // stale snapshot can never receive the newest generation and beat the real state on disk.
        var observedMutation = mutationGeneration
        var snapshot = await session.snapshot()
        while observedMutation != mutationGeneration {
            observedMutation = mutationGeneration
            snapshot = await session.snapshot()
        }
        guard metadata.generation < UInt64.max else {
            throw SaveDocumentError.generationOverflow
        }
        metadata.generation += 1
        let presentation = self.presentation
        let documentMetadata = metadata
        return CoachWorldSaveDocument(
            gameState: snapshot,
            presentation: presentation,
            metadata: documentMetadata
        )
    }

    public func setPresentationRoute(_ route: String) {
        presentation.route = route
        presentationRoute = route
    }

    public func setPresentationReturnRoute(_ route: String?) {
        presentation.returnRoute = route
    }

    /// A read receipt changes only presentation state. It is bounded and immediately reflected in
    /// the current model, while the next save carries it through the application document.
    public func markInboxItemRead(_ stableID: String) {
        guard let current = inbox,
              current.items.contains(where: { $0.stableID == stableID }) else { return }
        guard !presentation.readInboxItemIDs.contains(stableID) else { return }
        presentation.readInboxItemIDs.append(stableID)
        if presentation.readInboxItemIDs.count > CareerPresentationState.maximumReadInboxItems {
            presentation.readInboxItemIDs.removeFirst(
                presentation.readInboxItemIDs.count
                    - CareerPresentationState.maximumReadInboxItems
            )
        }
        inbox = current.markingRead(stableID)
    }

    public func selectTeam(_ organisationID: UUID) async {
        presentation.selectedSubjectID = organisationID
        let snapshot = await session.snapshot()
        teamProgrammeProfile = CoachWorldReadModelProvider.teamProgrammeProfile(
            organisationID,
            from: snapshot
        )
    }

    public func selectProspect(_ prospectID: UUID) {
        presentation.selectedSubjectID = prospectID
    }

    /// Records the profile route handoff without inventing a development mutation. The profile
    /// already renders the authoritative evidence; this status is the receipt for the root-level
    /// callback and is intentionally presentation-only.
    public func openDevelopmentEvidence(for stableID: String) {
        guard let row = roster?.players.first(where: { $0.stableID == stableID }) else {
            statusMessage = "Development evidence is unavailable for that player"
            return
        }
        statusMessage = "Development evidence opened for \(row.person.name)"
    }

    /// Opens only observer-scoped film already retained by the tactical authority. A missing or
    /// stale observation is reported as unavailable rather than replaced with current hidden team
    /// statistics.
    public func inspectOpponentFilm() async {
        let snapshot = await session.snapshot()
        guard let hq = CoachWorldReadModelProvider.coachingHQ(from: snapshot),
              let opponent = hq.opponent,
              let observerID = UUID(uuidString: hq.team.stableID),
              let opponentID = UUID(uuidString: opponent.stableID),
              let observation = snapshot.tactical.observation(
                  for: observerID,
                  opponentID: opponentID,
                  at: snapshot.calendar
              ) else {
            statusMessage = "No current opponent film evidence is recorded."
            return
        }
        statusMessage = "Opponent film: \(observation.sampleSize) source games, \(observation.confidence)% confidence, \(observation.passRate)% pass rate, \(observation.turnoverRate)% turnover rate."
    }

    public func advanceWeek() async {
        await run { try await self.session.resolve(.advanceWeek) }
    }

    /// Commits the smallest truthful preparation when the HQ exposes an incomplete weekly board.
    /// The actor applies both existing tactical records atomically; this is a delegation shortcut,
    /// not a second simulation path, and it remains revalidated by the same integrity checks.
    /// ponytail: balanced fallback until authored Game Plan and Practice Plan routes land.
    public func prepareWeek() async {
        await run { try await self.session.resolve(.prepareWeek) }
    }

    public func setGamePlan(_ plan: TacticalPlan) async {
        await run { try await self.session.resolve(.tacticalPlan(plan)) }
    }

    public func setPracticePlan(_ plan: TacticalPracticePlan) async {
        await run { try await self.session.resolve(.practicePlan(plan)) }
    }

    public func setPersonnelPlan(_ plan: PersonnelPlan) async {
        await run { try await self.session.resolve(.personnelPlan(plan)) }
    }

    public func acceptCareerOpportunity(_ stableID: String) async {
        guard let opportunityID = UUID(uuidString: stableID) else {
            statusMessage = "That opportunity is no longer available"
            return
        }
        await run {
            try await self.session.resolve(
                .career(.acceptOpportunity(opportunityID: opportunityID))
            )
        }
    }

    public func resignCareer() async {
        await run { try await self.session.resolve(.career(.resign)) }
    }

    public func actOnProMarket(_ action: ProMarketAction) async {
        await run { try await self.session.resolve(.proMarket(action)) }
    }

    public func actOnProManagement(_ action: ProManagementAction) async {
        await run { try await self.session.resolve(.proManagement(action)) }
    }

    /// Delegates the currently due responsibility to one employed staff member. The selection is
    /// deterministic and visible in the receipt; the authority still validates ownership and
    /// employment inside `CareerControlSystem`.
    public func delegateCurrentDecision() async {
        let snapshot = await session.snapshot()
        guard let control = snapshot.career.college,
              let decision = snapshot.pending.mandatoryDecisions.first(where: {
                  $0.programmeID == control.programmeID && $0.owner == .user
              }),
              let programme = snapshot.programmes[control.programmeID] else {
            statusMessage = "There is no delegable responsibility at this checkpoint"
            return
        }
        let attribute: CoachAttribute = switch decision.responsibility {
        case .recruiting, .portalAndRetention, .nilAllocation:
            .recruiting
        case .redshirts:
            .development
        }
        let staff = programme.staffIDs
            .compactMap { snapshot.staff[$0] }
            .filter { $0.id != control.coachID }
            .sorted { lhs, rhs in
                let lhsRating = lhs.rating(attribute).value
                let rhsRating = rhs.rating(attribute).value
                if lhsRating != rhsRating { return lhsRating > rhsRating }
                return lhs.id.uuidString < rhs.id.uuidString
            }
            .first
        guard let staff else {
            statusMessage = "No employed staff member can take this responsibility"
            return
        }
        await run {
            try await self.session.resolve(.delegateDecision(
                decisionID: decision.id,
                staffID: staff.id
            ))
        }
        if statusMessage == nil {
            statusMessage = "Delegated \(decision.responsibility.rawValue) to \(staff.fullName)"
        }
    }

    /// Advances one recorded snap or resolves the currently displayed staff call-in. The
    /// identifier is route-scoped and revalidated against the persisted checkpoint by the actor.
    public func matchControl(_ intentID: CoachWorldIntentID) async {
        let parts = intentID.rawValue.split(separator: "|", omittingEmptySubsequences: false)
        guard parts.count >= 4,
              parts[0] == "match",
              let fixtureID = UUID(uuidString: String(parts[1])),
              let revision = UInt64(parts[2]) else {
            statusMessage = "That match action is no longer available"
            return
        }
        if parts[3] == "pause" {
            await run {
                try await self.session.resolveMatch(
                    fixtureID: fixtureID,
                    revision: revision,
                    action: .togglePause
                )
            }
            return
        }
        if parts[3] == "takeover" {
            await run {
                try await self.session.resolveMatch(
                    fixtureID: fixtureID,
                    revision: revision,
                    action: .toggleTakeover
                )
            }
            return
        }
        if parts[3] == "advance" {
            await run {
                try await self.session.resolveMatch(
                    fixtureID: fixtureID,
                    revision: revision,
                    action: .advance
                )
            }
            return
        }
        // A bare tap (four parts, no trailing dial values) is Tactics opening the picker, which the
        // screen router handles before this method is ever reached — it never emits nothing but
        // "tactics", so reaching here means either a stale intent or a submitted plan. The three
        // trailing raw values are the plan `GamePlanView`'s row carried; see
        // `CoachWorldAppRootView.matchControl(_:in:)`.
        if parts[3] == "tactics" {
            guard parts.count >= 7,
                  let runPassBiasRaw = Int(parts[4]),
                  let runPassBias = TacticalRunPassBias(rawValue: runPassBiasRaw),
                  let tempoRaw = Int(parts[5]),
                  let tempo = TacticalTempo(rawValue: tempoRaw),
                  let pressureRaw = Int(parts[6]),
                  let pressure = TacticalPressure(rawValue: pressureRaw) else {
                statusMessage = "That tactical plan is no longer available"
                return
            }
            let plan = TacticalPlan(runPassBias: runPassBias, tempo: tempo, pressure: pressure)
            await run {
                try await self.session.resolveMatch(
                    fixtureID: fixtureID,
                    revision: revision,
                    action: .setTacticalPlan(plan)
                )
            }
            return
        }
        guard parts.count >= 5, parts[3] == "callin" else {
            statusMessage = "That match action is unavailable at this checkpoint"
            return
        }
        if parts[4] == "inspect" { return }
        let actionIndex = parts[4] == "accept" || parts[4] == "dismiss" ? 5 : 4
        guard parts.count > actionIndex,
              let action = TacticalCallInAction(rawValue: String(parts[actionIndex])) else {
            statusMessage = "That call-in choice is no longer available"
            return
        }
        await run {
            try await self.session.resolveMatch(
                fixtureID: fixtureID,
                revision: revision,
                action: .chooseCallIn(action)
            )
        }
    }

    /// Resolves the open mandatory decision by the option the screen committed.
    ///
    /// The intent identifier a choice carries is the option's own identifier — see
    /// `CoachWorldReadModelProvider.decision` — so this is a lookup, not a re-derivation.
    public func commit(_ intentID: CoachWorldIntentID) async {
        guard let decision = coachingHQ?.decision,
              let optionID = UUID(uuidString: intentID.rawValue),
              let decisionID = UUID(uuidString: decision.stableID) else {
            statusMessage = "That choice is no longer available"
            return
        }
        await run {
            try await self.session.resolve(
                .mandatoryDecision(decisionID: decisionID, optionID: optionID)
            )
        }
    }

    /// Resolves a recruiting-board choice. `prospectID` is the stable ID a board row carries;
    /// `intentID` is the action's own case name, mapped back to `RecruitingAction` by
    /// `CoachWorldReadModelProvider.recruitingAction`.
    public func actOnProspect(_ prospectID: String, _ intentID: CoachWorldIntentID) async {
        guard let id = UUID(uuidString: prospectID),
              let action = CoachWorldReadModelProvider.recruitingAction(for: intentID) else {
            statusMessage = "That recruiting action is no longer available"
            return
        }
        await run { try await self.session.resolve(.recruiting(prospectID: id, action: action)) }
    }

    /// One place where an intent is run, a refusal is reported and the read models are rebuilt, so
    /// no caller can advance the world and forget to refresh the screen.
    private func run(_ intent: @escaping () async throws -> CareerSessionReceipt) async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            _ = try await intent()
            if mutationGeneration < UInt64.max { mutationGeneration += 1 }
            statusMessage = nil
        } catch {
            statusMessage = Self.refusalMessage(for: error)
        }
        rebuildScreens(from: await session.snapshot())
    }

    /// A refusal the player can act on, for every way the session can refuse.
    ///
    /// This used to hand-write one sentence and interpolate the raw error for the rest, so a
    /// blocked advance told the player
    /// `missingWeeklyPreparation([FootballSimCore.TacticalPreparationRequirement.gamePlan, ...])`.
    /// The switch is exhaustive on purpose: a new refusal cannot compile until someone writes the
    /// sentence that explains it.
    public nonisolated static func refusalMessage(for error: Error) -> String {
        guard let refusal = error as? CareerSessionError else {
            return "That action could not be completed. Nothing was changed."
        }
        switch refusal {
        case .missingControlledCareer:
            return "No career is under your control."
        case let .missingWeeklyPreparation(requirements):
            let work = requirements.map(Self.preparationName).joined(separator: " and ")
            return "Set the \(work) before the week can advance."
        case .responsibilityDelegated:
            return "A staff member owns this decision. Take it back to decide it yourself."
        case .missingMandatoryDecision:
            return "That decision is no longer waiting."
        case .missingDecisionOption:
            return "That option is no longer available on this decision."
        case .decisionActionFailed:
            return "The decision could not be committed. Nothing was changed."
        case .responsibilityUpdateFailed:
            return "That responsibility could not be reassigned. Nothing was changed."
        case .invalidState:
            return "That action does not apply right now."
        case .matchInProgress:
            return "A match is already under way."
        case .matchNotStarted:
            return "No match is under way."
        case .staleMatchCheckpoint:
            return "That match checkpoint is no longer current."
        case .matchActionFailed:
            return "The match could not accept that action. The recorded moment is unchanged."
        }
    }

    private nonisolated static func preparationName(
        _ requirement: TacticalPreparationRequirement
    ) -> String {
        switch requirement {
        case .gamePlan: return "game plan"
        case .practicePlan: return "practice plan"
        }
    }
}
