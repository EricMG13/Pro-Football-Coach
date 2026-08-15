import SwiftUI
import FootballSimCore
import ProFootballCoachUI

/// The shipped application root: the screen the beta actually launches into.
///
/// It names no engine type. `CoachWorldStore` holds the world and vends read models; this file only
/// decides which screen is on the glass and hands intents back. That is the same boundary the
/// contract scan enforces on every file that imports a UI framework, and it is why this view and
/// the store live in separate files inside one target.
public struct CoachWorldAppRootView: View {
    @State private var store: CoachWorldStore?
    @State private var failure: String?
    @State private var isStarting = false
    @State private var isRestoring = false
    /// Set before the first `await`, not after it. `.task` can run more than once for one view,
    /// and `store == nil` stays true across every suspension point inside the load — so guarding on
    /// the store alone lets two loads, or two world generations, start side by side.
    @State private var hasAttemptedRestore = false
    @State private var screen: CoachWorldScreenID = .coachingHQ
    @State private var recoveryRequired = false
    @State private var showingNewCareerSetup = false
    @State private var startingJobs: [StartingJobReadModel] = []
    @State private var startingJobsRequest: UInt64 = 0
    @State private var setupError: String?

    @State private var coordinator: SaveCoordinator

    public init(saves: CoachWorldSaveStore = CoachWorldSaveStore()) {
        _coordinator = State(initialValue: SaveCoordinator(storage: saves))
    }

    public var body: some View {
        Group {
            if let store {
                career(store)
            } else if showingNewCareerSetup {
                NewCareerSetupView(
                    jobs: startingJobs,
                    defaultSeed: CoachWorldStore.defaultSeed,
                    isWorking: isStarting,
                    errorMessage: setupError,
                    onStart: { firstName, lastName, seed, programmeID in
                        Task {
                            await startNewCareer(
                                firstName: firstName,
                                lastName: lastName,
                                seed: seed,
                                programmeID: programmeID
                            )
                        }
                    },
                    onSeedChanged: { seed in
                        Task { await refreshStartingJobs(seed: seed) }
                    },
                    onCancel: {
                        showingNewCareerSetup = false
                        setupError = nil
                    }
                )
            } else {
                title
            }
        }
        .task { await restoreExistingCareer() }
    }

    /// Which screen is on the glass, and nothing else. A family with no production view reports
    /// that it has none rather than presenting an empty one — `04` §4.4 again, applied to
    /// navigation: an empty Depth Chart would claim the screen exists.
    @ViewBuilder
    private func career(_ store: CoachWorldStore) -> some View {
        Group {
            switch screen {
            case .roster:
                if let model = store.roster {
                    RosterView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onContinue: { Task { await advance(store) } },
                        onNavigate: { navigate($0, in: store) },
                        onInspectDevelopment: { playerID in
                            store.openDevelopmentEvidence(for: playerID)
                        }
                    )
                }
            case .recruitingBoard:
                if let model = store.recruitingBoard {
                    RecruitingBoardView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onAction: { prospectID, intentID in
                            Task { await actOnProspect(prospectID, intentID, in: store) }
                        },
                        onContinue: { Task { await advance(store) } },
                        onNavigate: { navigate($0, in: store) }
                    )
                }
            case .leagueMap:
                if let model = store.leagueMap {
                    LeagueMapView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        // The same `advance` path every other screen uses, so a pending decision
                        // refuses identically here. Roster and Recruiting Board once wired their
                        // copy of this control to a navigation instead, which made one button do
                        // two different things depending on where it was tapped.
                        onContinue: { Task { await advance(store) } },
                        onNavigate: { navigate($0, in: store) },
                        onSelectTeam: { id in
                            Task {
                                await store.selectTeam(id)
                                navigate(.teamProgrammeProfile, in: store)
                            }
                        }
                    )
                }
            case .matchDay:
                if let model = store.matchDay {
                    MatchDayView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onControl: { intentID in
                            Task { await matchControl(intentID, in: store) }
                        },
                        onInterruption: { intentID in
                            Task { await matchControl(intentID, in: store) }
                        }
                    )
                }
            case .gamePlan:
                if let model = store.gamePlan {
                    GamePlanView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onSelect: { plan in
                            Task { await setGamePlan(plan, in: store) }
                        },
                        onClose: { navigate(.coachingHQ, in: store) }
                    )
                }
            case .practicePlan:
                if let model = store.practicePlan {
                    PracticePlanView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onSelect: { plan in
                            Task { await setPracticePlan(plan, in: store) }
                        },
                        onClose: { navigate(.coachingHQ, in: store) }
                    )
                }
            case .depthChart:
                if let model = store.depthChart {
                    DepthChartView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onSelect: { plan in
                            Task { await setPersonnelPlan(plan, in: store) }
                        },
                        onClose: { navigate(.roster, in: store) }
                    )
                }
            case .aftermath:
                if let model = store.aftermath {
                    AftermathView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onContinue: { Task { await returnToHQ(store) } }
                    )
                }
            case .careerHub:
                if let model = store.careerHub {
                    CareerHubView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { navigate(.coachingHQ, in: store) }
                    )
                }
            case .standings:
                if let model = store.standings {
                    StandingsView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { navigate(.leagueMap, in: store) },
                        onContinue: { Task { await advance(store) } },
                        onSelectTeam: { id in
                            Task {
                                await store.selectTeam(id)
                                navigate(.teamProgrammeProfile, in: store)
                            }
                        }
                    )
                }
            case .schedule:
                if let model = store.schedule {
                    ScheduleView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { navigate(.leagueMap, in: store) },
                        onContinue: { Task { await advance(store) } },
                        onSelectTeam: { id in
                            Task {
                                await store.selectTeam(id)
                                navigate(.teamProgrammeProfile, in: store)
                            }
                        }
                    )
                }
            case .teamProgrammeProfile:
                if let model = store.teamProgrammeProfile {
                    TeamProgrammeProfileView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { navigate(.leagueMap, in: store) },
                        onSelectTeam: { id in
                            Task {
                                await store.selectTeam(id)
                                navigate(.teamProgrammeProfile, in: store)
                            }
                        }
                    )
                }
            case .worldSearch:
                if let model = store.worldSearch {
                    WorldSearchView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { navigate(.coachingHQ, in: store) },
                        onSelectTeam: { id in
                            Task {
                                await store.selectTeam(id)
                                navigate(.teamProgrammeProfile, in: store)
                            }
                        }
                    )
                }
            case .rankingsPlayoffPicture, .bracketPostseason:
                if let model = store.competitionOverview {
                    CompetitionOverviewView(
                        model: model,
                        focus: screen,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { navigate(.leagueMap, in: store) },
                        onContinue: { Task { await advance(store) } },
                        onSelectTeam: { id in
                            Task {
                                await store.selectTeam(id)
                                navigate(.teamProgrammeProfile, in: store)
                            }
                        }
                    )
                }
            default:
                if let model = store.coachingHQ {
                    CoachingHQView(
                        model: model,
                        // A save failure has to reach the player while they are playing, so it
                        // takes the receipt line rather than waiting for a title screen they may
                        // not see again this session.
                        statusMessage: failure ?? store.statusMessage,
                        onCommit: { intentID in Task { await commit(intentID, in: store) } },
                        onInspect: {},
                        onDelegate: { Task { await delegate(store) } },
                        onPrepare: { Task { await prepare(store) } },
                        onContinue: { Task { await advance(store) } },
                        onOpenCorrespondence: { _ in },
                        onNavigate: { navigate($0, in: store) }
                    )
                }
            }
        }
        .disabled(store.isWorking)
        .overlay { if store.isWorking { working } }
    }

    private func navigate(_ destination: CoachWorldScreenID, in store: CoachWorldStore) {
        switch destination {
        case .coachingHQ:
            screen = .coachingHQ
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .roster where store.roster != nil:
            screen = .roster
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .recruitingBoard where store.recruitingBoard != nil:
            screen = .recruitingBoard
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .leagueMap where store.leagueMap != nil:
            screen = .leagueMap
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .gamePlan where store.gamePlan != nil:
            screen = .gamePlan
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .practicePlan where store.practicePlan != nil:
            screen = .practicePlan
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .depthChart where store.depthChart != nil:
            screen = .depthChart
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .careerHub where store.careerHub != nil:
            screen = .careerHub
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .standings where store.standings != nil:
            screen = .standings
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .schedule where store.schedule != nil:
            screen = .schedule
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .teamProgrammeProfile where store.teamProgrammeProfile != nil:
            screen = .teamProgrammeProfile
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .worldSearch where store.worldSearch != nil:
            screen = .worldSearch
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .rankingsPlayoffPicture where store.competitionOverview != nil,
             .bracketPostseason where store.competitionOverview != nil:
            screen = destination
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        default:
            failure = "\(destination.canonicalName) is not available yet"
        }
    }

    private var title: some View {
        VStack(spacing: CoachWorldTokens.Space.md) {
            Text("Pro Football Coach")
                .font(CoachWorldTokens.TypeRole.display.weight(.black))
            if let failure {
                Text(failure)
                    .font(CoachWorldTokens.TypeRole.body)
                    .multilineTextAlignment(.center)
            }
            if isStarting {
                ProgressView("Building the world")
            } else if isRestoring {
                ProgressView("Loading career")
            } else if recoveryRequired {
                Button("Retry restore") {
                    hasAttemptedRestore = false
                    recoveryRequired = false
                    Task { await restoreExistingCareer() }
                }
                Button("Use backup") { Task { await recoverFromBackup() } }
                Button("Replace with a new career") { Task { await beginNewCareerSetup() } }
            } else {
                Button("New career") { Task { await beginNewCareerSetup() } }
                    .buttonStyle(.borderedProminent)
                    .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
            }
        }
        .padding(CoachWorldTokens.Space.xl)
    }

    private var working: some View {
        ProgressView()
            .controlSize(.large)
            .padding(CoachWorldTokens.Space.lg)
            .background(.regularMaterial, in: RoundedRectangle(
                cornerRadius: CoachWorldTokens.Shape.surfaceRadius
            ))
    }

    /// Only ever loads; it never silently starts a career, so a save that fails to decode surfaces
    /// as a message rather than as a mysteriously new world sitting where the old one was.
    ///
    /// The one exception is the proof entry point, which follows the convention `RootView` already
    /// established for the screen proofs: an environment variable names what to walk into, so a
    /// screen can be reached and photographed without a hand on the device. It starts the same
    /// career the button starts, with the same seed and through the same code path.
    private func restoreExistingCareer() async {
        guard !hasAttemptedRestore else { return }
        hasAttemptedRestore = true
        isRestoring = true
        defer { isRestoring = false }
        do {
            let outcome = try await coordinator.load()
            guard case let .loaded(document, _) = outcome else {
                if ProcessInfo.processInfo.environment["PROOF_NEW_CAREER"] != nil {
                    await beginNewCareerSetup()
                }
                return
            }
            store = try await CoachWorldStore.load(document: document)
            if let destination = Self.screenID(for: document.presentation.route) {
                screen = destination
            }
            failure = nil
            recoveryRequired = false
        } catch {
            failure = Self.saveErrorMessage(error)
            recoveryRequired = true
        }
    }

    private func recoverFromBackup() async {
        guard !isRestoring && !isStarting else { return }
        isRestoring = true
        defer { isRestoring = false }
        do {
            let document = try await coordinator.recover(using: .useBackup)
            store = try await CoachWorldStore.load(document: document)
            if let destination = Self.screenID(for: document.presentation.route) {
                screen = destination
            }
            failure = nil
            recoveryRequired = false
        } catch {
            failure = "The backup could not be opened: \(error)"
        }
    }

    private static func saveErrorMessage(_ error: Error) -> String {
        if let envelope = error as? SaveEnvelopeError,
           case .futureVersion = envelope {
            return "This save was made by a newer version of Pro Football Coach."
        }
        if let document = error as? SaveDocumentError,
           case .futureDocumentVersion = document {
            return "This save was made by a newer version of Pro Football Coach."
        }
        return "That save could not be opened. Retry, use the backup, or explicitly replace it."
    }

    private static func screenID(for route: String) -> CoachWorldScreenID? {
        if let rawValue = Int(route), let screen = CoachWorldScreenID(rawValue: rawValue) {
            return screen
        }
        let normalized = route.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return CoachWorldScreenID.allCases.first {
            String(describing: $0).lowercased() == normalized
                || $0.canonicalName.lowercased() == normalized
        }
    }

    private func beginNewCareerSetup() async {
        startingJobsRequest &+= 1
        let request = startingJobsRequest
        isStarting = true
        setupError = nil
        let jobs = await CoachWorldStore.startingJobs(seed: CoachWorldStore.defaultSeed)
        guard request == startingJobsRequest else { return }
        startingJobs = jobs
        guard !startingJobs.isEmpty else {
            setupError = "No eligible starting jobs were generated."
            isStarting = false
            return
        }
        showingNewCareerSetup = true
        isStarting = false
    }

    private func startNewCareer(
        firstName: String,
        lastName: String,
        seed: UInt64,
        programmeID: String
    ) async {
        guard !isStarting else { return }
        isStarting = true
        defer { isStarting = false }
        do {
            guard let selectedID = UUID(uuidString: programmeID) else {
                setupError = "That starting job is no longer available."
                return
            }
            let started = try await CoachWorldStore.newCareer(
                seed: seed,
                firstName: firstName,
                lastName: lastName,
                programmeID: selectedID
            )
            try await persist(started)
            store = started
            showingNewCareerSetup = false
            setupError = nil
            failure = nil
        } catch {
            if let startError = error as? CoachWorldStore.StartError,
               case .programmeUnavailable = startError {
                setupError = "Refresh the jobs for this seed, then select one before starting."
            } else {
                setupError = "The world could not be built: \(error)"
            }
        }
    }

    private func refreshStartingJobs(seed: UInt64) async {
        startingJobsRequest &+= 1
        let request = startingJobsRequest
        isStarting = true
        let jobs = await CoachWorldStore.startingJobs(seed: seed)
        guard request == startingJobsRequest else { return }
        startingJobs = jobs
        setupError = startingJobs.isEmpty ? "No eligible starting jobs were generated." : nil
        isStarting = false
    }

    private func advance(_ store: CoachWorldStore) async {
        await store.advanceWeek()
        if store.matchDay != nil {
            screen = .matchDay
            store.setPresentationRoute(String(CoachWorldScreenID.matchDay.rawValue))
        } else if screen == .matchDay {
            screen = .coachingHQ
            store.setPresentationRoute(String(CoachWorldScreenID.coachingHQ.rawValue))
        }
        await persistOrReport(store)
    }

    private func prepare(_ store: CoachWorldStore) async {
        await store.prepareWeek()
        await persistOrReport(store)
    }

    private func delegate(_ store: CoachWorldStore) async {
        await store.delegateCurrentDecision()
        await persistOrReport(store)
    }

    private func setGamePlan(_ plan: TacticalPlan, in store: CoachWorldStore) async {
        await store.setGamePlan(plan)
        await persistOrReport(store)
    }

    private func setPracticePlan(_ plan: TacticalPracticePlan, in store: CoachWorldStore) async {
        await store.setPracticePlan(plan)
        await persistOrReport(store)
    }

    private func setPersonnelPlan(_ plan: PersonnelPlan, in store: CoachWorldStore) async {
        await store.setPersonnelPlan(plan)
        await persistOrReport(store)
    }

    private func matchControl(
        _ intentID: CoachWorldIntentID,
        in store: CoachWorldStore
    ) async {
        await store.matchControl(intentID)
        if store.matchDay == nil {
            if store.aftermath != nil {
                screen = .aftermath
                store.setPresentationRoute(String(CoachWorldScreenID.aftermath.rawValue))
            } else {
                screen = .coachingHQ
                store.setPresentationRoute(String(CoachWorldScreenID.coachingHQ.rawValue))
            }
        } else {
            screen = .matchDay
            store.setPresentationRoute(String(CoachWorldScreenID.matchDay.rawValue))
        }
        await persistOrReport(store)
    }

    private func returnToHQ(_ store: CoachWorldStore) async {
        screen = .coachingHQ
        store.setPresentationRoute(String(CoachWorldScreenID.coachingHQ.rawValue))
        await persistOrReport(store)
    }

    private func commit(_ intentID: CoachWorldIntentID, in store: CoachWorldStore) async {
        await store.commit(intentID)
        await persistOrReport(store)
    }

    private func actOnProspect(
        _ prospectID: String,
        _ intentID: CoachWorldIntentID,
        in store: CoachWorldStore
    ) async {
        await store.actOnProspect(prospectID, intentID)
        await persistOrReport(store)
    }

    /// Autosave. `docs/plans/2026-08-12-road-to-beta.md` D-3 measured encode latency at 12.53 s at
    /// season 30, so this will need a policy — write on background rather than after every intent —
    /// before a long career is playable. It is an `await` off the main actor, so it delays the next
    /// intent rather than the current frame.
    private func persist(_ store: CoachWorldStore) async throws {
        let document = try await store.saveDocument()
        try await coordinator.requestSave(document, reason: .userAction)
        try await coordinator.flush(reason: .explicit)
    }

    /// A failed autosave is reported, never swallowed. `try?` here would leave the player playing a
    /// career that is no longer being written to disk, and the first they would learn of it is the
    /// next launch showing an older world — the one failure mode where saying nothing is worse than
    /// anything the message could say.
    private func persistOrReport(_ store: CoachWorldStore) async {
        do {
            try await persist(store)
        } catch {
            failure = "The career could not be saved: \(error)"
        }
    }
}
