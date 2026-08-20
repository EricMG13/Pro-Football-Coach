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

    /// The world every screen is read from. Replaced once per committed intent, never observed
    /// directly: a screen depends on `revision` instead, so moving the world costs one notification
    /// rather than a diff over the whole root.
    @ObservationIgnored private var world: GameState
    /// Bumped whenever `world` moves or a presentation input a model reads changes.
    private var revision: UInt64 = 0
    /// Memoised screen models, cleared with the revision.
    ///
    /// Screens used to be *stored*, and all of them were rebuilt at the tail of every intent —
    /// including every match snap, and including the twenty-odd nobody was looking at. Measured on
    /// a refused intent, which does no simulation work at all, that cost 1.59 s; the engine's own
    /// week advance is 0.3 ms. Building the one screen on the glass, once, is the whole fix.
    ///
    /// Misses are cached as well as hits, so a nil model is decided once per world rather than on
    /// every read.
    @ObservationIgnored private var models: [String: Any] = [:]

    /// Reads a screen model, building it at most once per revision.
    ///
    /// `revision` is read before the cache so the access is registered with the observation
    /// registrar on a hit as well as a miss. Without that a cached read would take no dependency,
    /// and the screen would stop redrawing when the world moved.
    private func model<T>(_ key: String, _ build: (GameState) -> T?) -> T? {
        _ = revision
        if let boxed = models[key] { return boxed as? T }
        let value = build(world)
        models[key] = value as Any
        return value
    }

    /// Which routes exist right now. Answered from the root, not by building every screen.
    public var availableScreens: Set<CoachWorldScreenID> {
        model("availableScreens") { CoachWorldReadModelProvider.availableScreens(from: $0) } ?? []
    }

    public var coachingHQ: CoachingHQReadModel? { model("coachingHQ") { CoachWorldReadModelProvider.coachingHQ(from: $0) } }
    public var roster: RosterReadModel? { model("roster") { CoachWorldReadModelProvider.roster(from: $0) } }
    public var recruitingBoard: RecruitingBoardReadModel? { model("recruitingBoard") { CoachWorldReadModelProvider.recruitingBoard(from: $0) } }
    public var leagueMap: LeagueMapReadModel? { model("leagueMap") { CoachWorldReadModelProvider.leagueMap(from: $0) } }
    public var matchDay: MatchDayReadModel? { model("matchDay") { CoachWorldReadModelProvider.matchDay(from: $0) } }
    public var aftermath: AftermathReadModel? { model("aftermath") { CoachWorldReadModelProvider.aftermath(from: $0) } }
    public var careerHub: CareerHubReadModel? { model("careerHub") { CoachWorldReadModelProvider.careerHub(from: $0) } }
    public var standings: StandingsReadModel? { model("standings") { CoachWorldReadModelProvider.standings(tier: CoachWorldReadModelProvider.controlledCompetitionTier(from: $0), from: $0) } }
    public var schedule: ScheduleReadModel? { model("schedule") { CoachWorldReadModelProvider.schedule(tier: CoachWorldReadModelProvider.controlledCompetitionTier(from: $0), from: $0) } }
    public var worldSearch: WorldSearchReadModel? { model("worldSearch") { CoachWorldReadModelProvider.worldSearch(from: $0) } }
    public var competitionOverview: CompetitionOverviewReadModel? { model("competitionOverview") { CoachWorldReadModelProvider.competitionOverview(tier: CoachWorldReadModelProvider.controlledCompetitionTier(from: $0), from: $0) } }
    public var gamePlan: GamePlanReadModel? { model("gamePlan") { CoachWorldReadModelProvider.gamePlan(from: $0) } }
    public var practicePlan: PracticePlanReadModel? { model("practicePlan") { CoachWorldReadModelProvider.practicePlan(from: $0) } }
    public var depthChart: DepthChartReadModel? { model("depthChart") { CoachWorldReadModelProvider.depthChart(from: $0) } }
    public var teamHealth: TeamHealthReadModel? { model("teamHealth") { CoachWorldReadModelProvider.teamHealth(from: $0) } }
    public var collegeOffseason: CollegeOffseasonReadModel? { model("collegeOffseason") { CoachWorldReadModelProvider.collegeOffseason(from: $0) } }
    public var proOffseason: ProOffseasonReadModel? { model("proOffseason") { CoachWorldReadModelProvider.proOffseason(from: $0) } }
    public var proManagement: ProManagementReadModel? { model("proManagement") { CoachWorldReadModelProvider.proManagement(from: $0) } }
    public var staffRoom: StaffRoomReadModel? { model("staffRoom") { CoachWorldReadModelProvider.staffRoom(from: $0) } }
    public var opponentFilm: OpponentFilmReadModel? { model("opponentFilm") { CoachWorldReadModelProvider.opponentFilm(from: $0) } }
    public var news: NewsReadModel? { model("news") { CoachWorldReadModelProvider.news(from: $0) } }
    public var legacyHistory: LegacyHistoryReadModel? { model("legacyHistory") { CoachWorldReadModelProvider.legacyHistory(from: $0) } }
    public var statisticsLeaders: StatisticsLeadersReadModel? { model("statisticsLeaders") { CoachWorldReadModelProvider.statisticsLeaders(from: $0) } }
    public var awardsHonours: AwardsHonoursReadModel? { model("awardsHonours") { CoachWorldReadModelProvider.awardsHonours(from: $0) } }
    public var realignment: RealignmentReadModel? { model("realignment") { CoachWorldReadModelProvider.realignment(from: $0) } }
    /// Depends on the selected subject as well as the world, so `selectTeam` evicts it.
    public var teamProgrammeProfile: TeamProgrammeProfileReadModel? {
        model("teamProgrammeProfile") { state in
            let controlledID = state.career.college?.programmeID
                ?? state.careerArc.currentJob?.organisationID
            guard let id = self.presentation.selectedSubjectID ?? controlledID else { return nil }
            return CoachWorldReadModelProvider.teamProgrammeProfile(id, from: state)
        }
    }

    /// Depends on the read receipts as well as the world, so `markInboxItemRead` evicts it.
    public var inbox: InboxReadModel? {
        model("inbox") { state in
            CoachWorldReadModelProvider.inbox(
                from: state,
                readInboxItemIDs: Set(self.presentation.readInboxItemIDs)
            )
        }
    }

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
        world = snapshot
    }

    /// Adopts a new world. Screens are invalidated, not rebuilt: the next read of the one on the
    /// glass builds it, and nothing builds the rest.
    private func adopt(_ snapshot: GameState) {
        world = snapshot
        models.removeAll(keepingCapacity: true)
        revision &+= 1
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
        models["inbox"] = nil
        revision &+= 1
    }

    public func selectTeam(_ organisationID: UUID) {
        presentation.selectedSubjectID = organisationID
        models["teamProgrammeProfile"] = nil
        revision &+= 1
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
        let teamName = careerHub?.opportunities.first { $0.id == stableID }?.team.name
        await run(
            {
                try await self.session.resolve(
                    .career(.acceptOpportunity(opportunityID: opportunityID))
                )
            },
            successMessage: teamName.map { "Accepted \($0). Appointment updated." }
                ?? "Career appointment updated."
        )
    }

    public func resignCareer() async {
        let teamName = careerHub?.currentJob?.team.name ?? "the current appointment"
        await run(
            { try await self.session.resolve(.career(.resign)) },
            successMessage: "Resigned from \(teamName). Returned to the job search."
        )
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

    /// Resolves the mandatory decision encoded by the screen as `decisionID|optionID`.
    ///
    /// Legacy callers may still send the option ID alone; the canonical offseason surface sends
    /// `decisionID|optionID` so every visible decision card resolves its own subject.
    public func commit(_ intentID: CoachWorldIntentID) async {
        let parts = intentID.rawValue.split(separator: "|", omittingEmptySubsequences: true)
        let decisionID: UUID?
        let optionID: UUID?
        if parts.count == 2 {
            decisionID = UUID(uuidString: String(parts[0]))
            optionID = UUID(uuidString: String(parts[1]))
        } else {
            decisionID = coachingHQ?.decision.flatMap { UUID(uuidString: $0.stableID) }
            optionID = UUID(uuidString: intentID.rawValue)
        }
        guard let decisionID, let optionID else {
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
    private func run(
        _ intent: @escaping () async throws -> CareerSessionReceipt,
        successMessage: String? = nil
    ) async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            _ = try await intent()
            if mutationGeneration < UInt64.max { mutationGeneration += 1 }
            statusMessage = successMessage ?? "Action committed successfully."
        } catch {
            statusMessage = Self.refusalMessage(for: error)
        }
        adopt(await session.snapshot())
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
