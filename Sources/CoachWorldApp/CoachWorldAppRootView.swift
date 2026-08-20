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
    /// A successful restore populates `store` immediately but does not, on its own, enter
    /// gameplay -- `restoreExistingCareer()` no longer treats "loaded" as "confirmed." The coach
    /// sees `TitleContinueView`'s career summary and taps Continue first (`02` section 9's
    /// durable boundary). `startNewCareer(...)` sets this directly: a freshly created career
    /// needs no redundant confirmation of a career the coach just finished naming.
    @State private var careerConfirmed = false
    @State private var failure: String?
    @State private var isStarting = false
    @State private var isRestoring = false
    /// Set before the first `await`, not after it. `.task` can run more than once for one view,
    /// and `store == nil` stays true across every suspension point inside the load — so guarding on
    /// the store alone lets two loads, or two world generations, start side by side.
    @State private var hasAttemptedRestore = false
    @State private var screen: CoachWorldScreenID = .coachingHQ
    @State private var teamHealthOrigin: CoachWorldScreenID = .coachingHQ
    @State private var inboxOrigin: CoachWorldScreenID = .coachingHQ
    /// Where Tactics opened Game Plan from, so submitting or closing returns there rather than to
    /// Coaching HQ. Not persisted across a relaunch the way `teamHealthOrigin`/`inboxOrigin` are —
    /// quitting mid-adjustment lands back on Coaching HQ instead of Match Day on the next launch, a
    /// narrower gap than the two return routes already wired into the save document.
    @State private var gamePlanOrigin: CoachWorldScreenID = .coachingHQ
    @State private var careerFocus: CoachWorldScreenID = .careerHub
    @State private var proFocus: CoachWorldScreenID = .proOffseason
    @State private var recruitingProspectID: String?
    @State private var personnelPlayerID: String?
    @State private var recoveryRequired = false
    @State private var showingNewCareerSetup = false
    @State private var startingJobs: [StartingJobReadModel] = []
    @State private var startingJobsRequest: UInt64 = 0
    @State private var setupError: String?

    @State private var coordinator: SaveCoordinator
    /// The one deferred write. While it is outstanding, further intents only hand the coordinator a
    /// newer document; the task that is already waiting writes whichever is newest when it fires.
    @State private var flushTask: Task<Void, Never>?
    @Environment(\.scenePhase) private var scenePhase

    /// How long a committed intent may sit unwritten.
    ///
    /// Every intent used to force a flush, which is why the coordinator's coalescing never
    /// coalesced anything: a match snap cost a full encode, a read-back and two whole-file writes,
    /// measured at 2.9 s at season 0 and growing with the career. Requesting is cheap and the
    /// write is deferred, so a burst of snaps costs one write rather than one per snap. Leaving
    /// the app writes immediately, so the exposure is a crash inside this window, against a backup
    /// file and a previous save that both remain on disk.
    private static let flushDelay: Duration = .seconds(4)

    public init(saves: CoachWorldSaveStore = CoachWorldSaveStore()) {
        _coordinator = State(initialValue: SaveCoordinator(storage: saves))
    }

    public var body: some View {
        Group {
            if let store, careerConfirmed {
                career(store)
            } else if showingNewCareerSetup {
                NewCareerCoachIdentityView(
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
            } else if screen == .settingsAccessibility {
                SettingsAccessibilityView(onClose: { screen = .titleContinue })
            } else {
                title
            }
        }
        .background(CoachWorldTokens.dark.page.color)
        .preferredColorScheme(.dark)
        .task { await restoreExistingCareer() }
        // Leaving the app is the deadline the deferred write is measured against: whatever an
        // intent committed in the last few seconds is on disk before the process can be suspended
        // or killed behind the coach's back.
        .onChange(of: scenePhase) { _, phase in
            guard phase != .active else { return }
            flushTask?.cancel()
            flushTask = nil
            Task { await flushNow(reason: .background) }
        }
    }

    /// Which screen is on the glass, and nothing else. A reachable route whose read model has not
    /// been retained reports that truthfully through `surface(_:screen:content:)` rather than
    /// rendering nothing — `04` §4.4 again, applied to navigation: an empty Depth Chart would claim
    /// the screen exists, but so would a blank one.
    @ViewBuilder
    private func career(_ store: CoachWorldStore) -> some View {
        Group {
            switch Self.canonicalScreen(screen) {
            case .roster:
                surface(store.roster, screen: .roster) { model in
                    RosterView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onContinue: { Task { await advance(store) } },
                        onNavigate: { navigate($0, in: store) },
                        onInspectDevelopment: { playerID in
                            store.openDevelopmentEvidence(for: playerID)
                        },
                        onOpenProfile: { playerID in
                            personnelPlayerID = playerID
                            navigate(.playerProfile, in: store)
                        },
                        showsRecruitingBoard: store.availableScreens.contains(.recruitingBoard)
                    )
                    .floodlitChrome(
                        chrome(for: .roster, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .developmentPlan:
                surface(store.roster, screen: .developmentPlan) { model in
                    DevelopmentPlanView(model: model, statusMessage: failure ?? store.statusMessage,
                                        onClose: { navigate(.roster, in: store) })
                    .floodlitChrome(
                        chrome(for: .developmentPlan, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .inbox:
                surface(store.inbox, screen: .inbox) { model in
                    InboxView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { navigate(inboxOrigin, in: store) },
                        onOpen: { navigate($0, in: store) },
                        onRead: {
                            store.markInboxItemRead($0)
                            Task { await persistOrReport(store) }
                        },
                        onContinue: { Task { await advance(store) } }
                    )
                    .floodlitChrome(
                        chrome(for: .inbox, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .settingsAccessibility:
                SettingsAccessibilityView(
                    onClose: { navigate(.coachingHQ, in: store) },
                    callInsPerGame: store.callInsPerGame,
                    onSetCallInsPerGame: { store.setCallInsPerGame($0) }
                )
                    .floodlitChrome(
                        chrome(for: .settingsAccessibility, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
            case .opponentReportFilmRoom:
                surface(store.opponentFilm, screen: .opponentReportFilmRoom) { model in
                    OpponentReportFilmRoomView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { closeCareer(in: store) },
                        onContinue: { navigate(.gamePlan, in: store) }
                    )
                    .floodlitChrome(
                        chrome(for: .opponentReportFilmRoom, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .news:
                surface(store.news, screen: .news) { model in
                    NewsView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { navigate(.leagueMap, in: store) }
                    )
                    .floodlitChrome(
                        chrome(for: .news, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .recordBook:
                surface(store.legacyHistory, screen: .recordBook) { model in
                    RecordBookView(model: model, statusMessage: failure ?? store.statusMessage,
                                   onClose: { closeCareer(in: store) },
                                   onNavigate: { navigate($0, in: store) })
                    .floodlitChrome(
                        chrome(for: .recordBook, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .rivalries:
                surface(store.legacyHistory, screen: .rivalries) { model in
                    RivalriesView(model: model, statusMessage: failure ?? store.statusMessage,
                                  onClose: { closeCareer(in: store) },
                                  onNavigate: { navigate($0, in: store) })
                    .floodlitChrome(
                        chrome(for: .rivalries, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .careerLine:
                surface(store.legacyHistory, screen: .careerLine) { model in
                    CareerLineView(model: model, statusMessage: failure ?? store.statusMessage,
                                   onClose: { closeCareer(in: store) },
                                   onNavigate: { navigate($0, in: store) })
                    .floodlitChrome(
                        chrome(for: .careerLine, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .coachingTree:
                surface(store.legacyHistory, screen: .coachingTree) { model in
                    CoachingTreeView(model: model, statusMessage: failure ?? store.statusMessage,
                                     onClose: { closeCareer(in: store) },
                                     onNavigate: { navigate($0, in: store) })
                    .floodlitChrome(
                        chrome(for: .coachingTree, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .recruitingBoard:
                surface(store.recruitingBoard, screen: .recruitingBoard) { model in
                    RecruitingBoardView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onAction: { prospectID, intentID in
                            Task { await actOnProspect(prospectID, intentID, in: store) }
                        },
                        onContinue: { Task { await advance(store) } },
                        onNavigate: { navigate($0, in: store) },
                        onOpenProspect: { prospectID in
                            recruitingProspectID = prospectID
                            if let id = UUID(uuidString: prospectID) {
                                store.selectProspect(id)
                            }
                            navigate(.prospectProfile, in: store)
                        },
                        onOpenShortlist: {
                            navigate(.shortlist, in: store)
                        }
                    )
                    .floodlitChrome(
                        chrome(for: .recruitingBoard, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .prospectProfile:
                surface(store.recruitingBoard, screen: .prospectProfile) { model in
                    ProspectProfileView(
                        model: model,
                        prospectID: recruitingProspectID,
                        statusMessage: failure ?? store.statusMessage,
                        onAction: { prospectID, intentID in
                            Task { await actOnProspect(prospectID, intentID, in: store) }
                        },
                        onClose: { navigate(.recruitingBoard, in: store) }
                    )
                    .floodlitChrome(
                        chrome(for: .prospectProfile, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .shortlist:
                surface(store.recruitingBoard, screen: .shortlist) { model in
                    ShortlistView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onOpenProspect: { prospectID in
                            recruitingProspectID = prospectID
                            if let id = UUID(uuidString: prospectID) {
                                store.selectProspect(id)
                            }
                            navigate(.prospectProfile, in: store)
                        },
                        onClose: { navigate(.recruitingBoard, in: store) }
                    )
                    .floodlitChrome(
                        chrome(for: .shortlist, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .classOverview:
                surface(store.recruitingBoard, screen: .classOverview) { model in
                    ClassOverviewView(model: model, statusMessage: failure ?? store.statusMessage,
                                      onClose: { closeCareer(in: store) })
                    .floodlitChrome(
                        chrome(for: .classOverview, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .contactVisitPlanner:
                surface(store.recruitingBoard, screen: .contactVisitPlanner) { model in
                    ContactVisitPlannerView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onAction: { prospectID, intentID in
                            Task { await actOnProspect(prospectID, intentID, in: store) }
                        },
                        onClose: { closeCareer(in: store) }
                    )
                    .floodlitChrome(
                        chrome(for: .contactVisitPlanner, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .statisticsLeaders:
                surface(store.statisticsLeaders, screen: .statisticsLeaders) { model in
                    StatisticsLeadersView(model: model, statusMessage: failure ?? store.statusMessage,
                                          onClose: { navigate(.leagueMap, in: store) })
                    .floodlitChrome(
                        chrome(for: .statisticsLeaders, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .awardsHonours:
                surface(store.awardsHonours, screen: .awardsHonours) { model in
                    AwardsHonoursView(model: model, statusMessage: failure ?? store.statusMessage,
                                      onClose: { navigate(.leagueMap, in: store) })
                    .floodlitChrome(
                        chrome(for: .awardsHonours, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .realignmentEvent:
                surface(store.realignment, screen: .realignmentEvent) { model in
                    RealignmentEventView(model: model, statusMessage: failure ?? store.statusMessage,
                                         onClose: { navigate(.leagueMap, in: store) })
                    .floodlitChrome(
                        chrome(for: .realignmentEvent, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .leagueMap:
                surface(store.leagueMap, screen: .leagueMap) { model in
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
                            // Selecting a subject is presentation state and one cache eviction,
                            // so it no longer needs an actor hop to reach the world.
                            store.selectTeam(id)
                            navigate(.teamProgrammeProfile, in: store)
                        }
                    )
                    .floodlitChrome(
                        chrome(for: .leagueMap, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .matchDay:
                surface(store.matchDay, screen: .matchDay) { model in
                    MatchDayView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onControl: { intentID in
                            Task { await matchControl(intentID, in: store) }
                        },
                        onInterruption: { intentID in
                            Task { await matchControl(intentID, in: store) }
                        },
                        // The handoff's "← WEEK" link. Until it existed there was no way off this
                        // screen at all — every other surface here already takes an `onClose`.
                        onExit: { navigate(.coachingHQ, in: store) }
                    )
                }
            case .gamePlan:
                surface(store.gamePlan, screen: .gamePlan) { model in
                    GamePlanView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onSelect: { plan in
                            // Tactics opened this screen mid-match: the choice must reach
                            // MatchAction.setTacticalPlan on the live session, not setGamePlan's
                            // pre-game weekly plan store, which a live match never reads from again
                            // once kicked off.
                            if gamePlanOrigin == .matchDay,
                               let tacticsControl = store.matchDay?.controls.first(where: {
                                   $0.id == .tactics
                               }) {
                                let encoded = CoachWorldIntentID(rawValue: [
                                    tacticsControl.intentID.rawValue,
                                    String(plan.runPassBias.rawValue),
                                    String(plan.tempo.rawValue),
                                    String(plan.pressure.rawValue),
                                ].joined(separator: "|"))
                                Task { await matchControl(encoded, in: store) }
                            } else {
                                Task { await setGamePlan(plan, in: store) }
                            }
                        },
                        onClose: {
                            if gamePlanOrigin == .matchDay {
                                screen = .matchDay
                            } else {
                                navigate(gamePlanOrigin, in: store)
                            }
                        }
                    )
                    .floodlitChrome(
                        chrome(for: .gamePlan, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .practicePlan:
                surface(store.practicePlan, screen: .practicePlan) { model in
                    PracticePlanView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onSelect: { plan in
                            Task { await setPracticePlan(plan, in: store) }
                        },
                        onClose: { navigate(.coachingHQ, in: store) }
                    )
                    .floodlitChrome(
                        chrome(for: .practicePlan, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .depthChart:
                surface(store.depthChart, screen: .depthChart) { model in
                    DepthChartView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onSelect: { plan in
                            Task { await setPersonnelPlan(plan, in: store) }
                        },
                        onClose: { navigate(.roster, in: store) }
                    )
                    .floodlitChrome(
                        chrome(for: .depthChart, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .playerProfile:
                surface(store.roster, screen: .playerProfile) { model in
                    let surfaceChrome = chrome(for: .playerProfile, in: store)
                    let player = model.players.first { $0.stableID == personnelPlayerID }
                        ?? model.players.first
                    if let player {
                        PlayerProfileView(
                            model: player.profile,
                            team: model.team,
                            onClose: { navigate(.roster, in: store) },
                            onInspectDevelopment: { stableID in
                                store.openDevelopmentEvidence(for: stableID)
                                navigate(.developmentPlan, in: store)
                            }
                        )
                        .floodlitChrome(
                            surfaceChrome,
                            onNavigate: { navigateChrome($0, in: store) }
                        )
                    } else {
                        CoachWorldFloodlitStage(
                            palette: CoachWorldTokens.dark,
                            chrome: surfaceChrome,
                            onNavigate: { navigateChrome($0, in: store) }
                        ) {
                            CoachWorldSystemState(
                                .empty(
                                    "Player Profile unavailable. No player evidence is retained for this roster."
                                ),
                                palette: CoachWorldTokens.dark
                            )
                        }
                    }
                }
                .onDisappear { personnelPlayerID = nil }
            case .teamHealth:
                surface(store.teamHealth, screen: .teamHealth) { model in
                    TeamHealthView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { navigate(teamHealthOrigin, in: store) },
                        onContinue: { Task { await advance(store) } }
                    )
                    .floodlitChrome(
                        chrome(for: .teamHealth, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .proOffseason, .draftRoom:
                let focus = screen == .draftRoom ? .draftRoom : proFocus
                surface(store.proOffseason, screen: .proOffseason) { model in
                    ProOffseasonView(
                        model: model,
                        title: focus.taskName.uppercased(),
                        focus: focus,
                        statusMessage: failure ?? store.statusMessage,
                        onAction: { action in
                            Task { await store.actOnProMarket(action) }
                        },
                        onClose: { closeCareer(in: store) }
                    )
                    .floodlitChrome(
                        chrome(for: focus, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .collegeOffseason:
                surface(store.collegeOffseason, screen: .collegeOffseason) { model in
                    CollegeOffseasonView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onCommit: { intentID in Task { await commit(intentID, in: store) } },
                        onContinue: { Task { await advance(store) } },
                        onClose: { closeCareer(in: store) }
                    )
                    .floodlitChrome(
                        chrome(for: .collegeOffseason, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .signingDay:
                if store.availableScreens.contains(.collegeOffseason) {
                    surface(store.collegeOffseason, screen: .signingDay) { model in
                        SigningDayView(model: model, statusMessage: failure ?? store.statusMessage,
                                       onCommit: { id in Task { await commit(id, in: store) } },
                                       onContinue: { Task { await advance(store) } },
                                       onClose: { closeCareer(in: store) })
                        .floodlitChrome(
                            chrome(for: .signingDay, in: store),
                            onNavigate: { navigateChrome($0, in: store) }
                        )
                    }
                } else {
                    CoachWorldFloodlitStage(
                        palette: CoachWorldTokens.dark,
                        chrome: chrome(for: .signingDay, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    ) {
                        CoachWorldSystemState(
                            .empty(
                                failure ?? store.statusMessage
                                    ?? "Signing day is closed. The signing period is not active in the current recruiting cycle."
                            ),
                            palette: CoachWorldTokens.dark
                        )
                    }
                }
            case .capContracts:
                surface(store.proManagement, screen: .capContracts) { model in
                    CapContractsView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onAction: { action in
                            Task { await store.actOnProManagement(action) }
                        },
                        onClose: { closeCareer(in: store) }
                    )
                    .floodlitChrome(
                        chrome(for: .capContracts, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .contractNegotiation:
                surface(store.proManagement, screen: .contractNegotiation) { model in
                    ContractNegotiationView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onAction: { action in
                            Task { await store.actOnProManagement(action) }
                        },
                        onClose: { closeCareer(in: store) }
                    )
                    .floodlitChrome(
                        chrome(for: .contractNegotiation, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .rosterCutsTransactions:
                surface(store.proManagement, screen: .rosterCutsTransactions) { model in
                    RosterCutsTransactionsView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onAction: { action in Task { await store.actOnProManagement(action) } },
                        onClose: { closeCareer(in: store) }
                    )
                    .floodlitChrome(
                        chrome(for: .rosterCutsTransactions, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .staffRoom:
                surface(store.staffRoom, screen: .staffRoom) { model in
                    StaffRoomView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { closeCareer(in: store) }
                    )
                    .floodlitChrome(
                        chrome(for: .staffRoom, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .aftermath:
                surface(store.aftermath, screen: .aftermath) { model in
                    AftermathView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onContinue: { Task { await returnToHQ(store) } },
                        onOpenBoxScore: {
                            navigate(.gameDetailBoxScore, in: store)
                            Task { await persistOrReport(store) }
                        }
                    )
                    .floodlitChrome(
                        chrome(for: .aftermath, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .gameDetailBoxScore:
                surface(store.aftermath, screen: .gameDetailBoxScore) { model in
                    GameDetailBoxScoreView(
                        model: model,
                        onClose: { navigate(.aftermath, in: store) }
                    )
                    .floodlitChrome(
                        chrome(for: .gameDetailBoxScore, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .careerHub:
                surface(store.careerHub, screen: .careerHub) { model in
                    CareerHubView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { closeCareer(in: store) },
                        focus: careerFocus,
                        onNavigate: { navigate($0, in: store) },
                        onAcceptOpportunity: { id in
                            Task { await acceptCareerOpportunity(id, in: store) }
                        },
                        onResign: { Task { await resignCareer(in: store) } },
                        onContinue: { Task { await advance(store) } }
                    )
                    .floodlitChrome(
                        chrome(for: .careerHub, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .stakeholders:
                surface(store.careerHub, screen: .stakeholders) { model in
                    StakeholdersView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { closeCareer(in: store) },
                        onNavigate: { navigate($0, in: store) },
                        onAcceptOpportunity: { id in
                            Task { await acceptCareerOpportunity(id, in: store) }
                        },
                        onResign: { Task { await resignCareer(in: store) } },
                        onContinue: { Task { await advance(store) } }
                    )
                    .floodlitChrome(
                        chrome(for: .stakeholders, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .promotionDecision:
                surface(store.careerHub, screen: .promotionDecision) { model in
                    PromotionDecisionView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { closeCareer(in: store) },
                        onNavigate: { navigate($0, in: store) },
                        onAcceptOpportunity: { id in
                            Task { await acceptCareerOpportunity(id, in: store) }
                        },
                        onResign: { Task { await resignCareer(in: store) } },
                        onContinue: { Task { await advance(store) } }
                    )
                    .floodlitChrome(
                        chrome(for: .promotionDecision, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .standings:
                surface(store.standings, screen: .standings) { model in
                    StandingsView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { navigate(.leagueMap, in: store) },
                        onContinue: { Task { await advance(store) } },
                        onSelectTeam: { id in
                            // Selecting a subject is presentation state and one cache eviction,
                            // so it no longer needs an actor hop to reach the world.
                            store.selectTeam(id)
                            navigate(.teamProgrammeProfile, in: store)
                        }
                    )
                    .floodlitChrome(
                        chrome(for: .standings, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .schedule:
                surface(store.schedule, screen: .schedule) { model in
                    ScheduleView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { navigate(.leagueMap, in: store) },
                        onContinue: { Task { await advance(store) } },
                        onSelectTeam: { id in
                            // Selecting a subject is presentation state and one cache eviction,
                            // so it no longer needs an actor hop to reach the world.
                            store.selectTeam(id)
                            navigate(.teamProgrammeProfile, in: store)
                        }
                    )
                    .floodlitChrome(
                        chrome(for: .schedule, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .teamProgrammeProfile:
                surface(store.teamProgrammeProfile, screen: .teamProgrammeProfile) { model in
                    TeamProgrammeProfileView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { navigate(.leagueMap, in: store) },
                        onSelectTeam: { id in
                            // Selecting a subject is presentation state and one cache eviction,
                            // so it no longer needs an actor hop to reach the world.
                            store.selectTeam(id)
                            navigate(.teamProgrammeProfile, in: store)
                        }
                    )
                    .floodlitChrome(
                        chrome(for: .teamProgrammeProfile, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .worldSearch:
                surface(store.worldSearch, screen: .worldSearch) { model in
                    WorldSearchView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { navigate(.coachingHQ, in: store) },
                        onSelectTeam: { id in
                            // Selecting a subject is presentation state and one cache eviction,
                            // so it no longer needs an actor hop to reach the world.
                            store.selectTeam(id)
                            navigate(.teamProgrammeProfile, in: store)
                        }
                    )
                    .floodlitChrome(
                        chrome(for: .worldSearch, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .rankingsPlayoffPicture:
                surface(store.competitionOverview, screen: .rankingsPlayoffPicture) { model in
                    RankingsPlayoffPictureView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { navigate(.leagueMap, in: store) },
                        onContinue: { Task { await advance(store) } },
                        onSelectTeam: { id in
                            // Selecting a subject is presentation state and one cache eviction,
                            // so it no longer needs an actor hop to reach the world.
                            store.selectTeam(id)
                            navigate(.teamProgrammeProfile, in: store)
                        }
                    )
                    .floodlitChrome(
                        chrome(for: .rankingsPlayoffPicture, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            case .bracketPostseason:
                surface(store.competitionOverview, screen: .bracketPostseason) { model in
                    BracketPostseasonView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { navigate(.leagueMap, in: store) },
                        onContinue: { Task { await advance(store) } },
                        onSelectTeam: { id in
                            // Selecting a subject is presentation state and one cache eviction,
                            // so it no longer needs an actor hop to reach the world.
                            store.selectTeam(id)
                            navigate(.teamProgrammeProfile, in: store)
                        }
                    )
                    .floodlitChrome(
                        chrome(for: .bracketPostseason, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            default:
                surface(store.coachingHQ, screen: .coachingHQ) { model in
                    CoachingHQView(
                        model: model,
                        // A save failure has to reach the player while they are playing, so it
                        // takes the receipt line rather than waiting for a title screen they may
                        // not see again this session.
                        statusMessage: failure ?? store.statusMessage,
                        onCommit: { intentID in Task { await commit(intentID, in: store) } },
                        onInspect: {
                            Task {
                                await store.inspectOpponentFilm()
                                navigate(.opponentReportFilmRoom, in: store)
                            }
                        },
                        onDelegate: { Task { await delegate(store) } },
                        onPrepare: { Task { await prepare(store) } },
                        onContinue: { Task { await advance(store) } },
                        onOpenCorrespondence: { _ in },
                        onNavigate: { navigate($0, in: store) },
                        showsProOffseason: store.availableScreens.contains(.proOffseason),
                        showsDraftRoom: store.availableScreens.contains(.draftRoom),
                        showsSigningDay: store.availableScreens.contains(.signingDay),
                        showsCollegeOffseason: store.availableScreens.contains(.collegeOffseason),
                        showsProManagement: store.availableScreens.contains(.capContracts),
                        showsContractNegotiation: store.availableScreens.contains(.capContracts),
                        showsRecruitingBoard: store.availableScreens.contains(.recruitingBoard),
                        showsRealignmentEvent: store.availableScreens.contains(.realignmentEvent)
                    )
                    .floodlitChrome(
                        chrome(for: .coachingHQ, in: store),
                        onNavigate: { navigateChrome($0, in: store) }
                    )
                }
            }
        }
        .disabled(store.isWorking)
        .overlay { if store.isWorking { working } }
    }

    /// One truthful state for every registered route with no retained read model, in place of the
    /// 62 copies of an unwrapped optional binding with no `else` this file used to carry — a nil
    /// model rendered nothing at all, not even navigation chrome. Never invents a fallback model or
    /// changes which routes `navigate(_:in:)` considers reachable; it only changes what the glass
    /// shows when a reachable route's model has not been retained.
    @ViewBuilder
    private func surface<Model, Content: View>(
        _ model: Model?,
        screen: CoachWorldScreenID,
        @ViewBuilder content: (Model) -> Content
    ) -> some View {
        if let model {
            content(model)
        } else {
            VStack(spacing: CoachWorldTokens.Space.md) {
                CoachWorldSystemState(
                    .empty(
                        "\(screen.canonicalName) unavailable. No retained career evidence is "
                            + "available for this surface."
                    ),
                    palette: CoachWorldTokens.dark
                )
                if let store {
                    Button("Back to HQ") { navigate(.coachingHQ, in: store) }
                        .buttonStyle(.bordered)
                        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                }
            }
        }
    }

    /// The shared management chrome for a converted surface, or nil when the week hub's identity
    /// has not been retained — the header prints the programme, so without it there is nothing
    /// truthful to draw and the surface renders on the bare stage instead.
    private func chrome(
        for screen: CoachWorldScreenID,
        in store: CoachWorldStore
    ) -> FloodlitChromeReadModel? {
        guard let hub = store.coachingHQ else { return nil }
        return CoachWorldReadModelProvider.chrome(
            for: screen,
            hub: hub,
            context: headerContext(for: screen.canonicalDestination, in: store),
            availableScreens: availableScreens(in: store)
        )
    }

    /// The task registry only advertises canonical surfaces whose read models exist in this
    /// career. The legacy 62 numbers remain valid migration inputs, but never become sibling links.
    /// Sorted by registry number, because a `Set` has no order and the icon rail and the sibling
    /// row both read this list as an order.
    private func availableScreens(in store: CoachWorldStore) -> [CoachWorldScreenID] {
        [.settingsAccessibility] + store.availableScreens.sorted { $0.rawValue < $1.rawValue }
    }

    /// The header chip's surface context. The reference varies it per screen rather than printing
    /// the coming fixture everywhere, so each surface that holds its own headline figures supplies
    /// them; anything else falls back to the fixture, which is what the week hub shows.
    private func headerContext(
        for screen: CoachWorldScreenID,
        in store: CoachWorldStore
    ) -> String? {
        switch screen {
        case .roster, .depthChart, .developmentPlan, .staffRoom:
            guard let roster = store.roster else { return nil }
            return "\(roster.players.count) of \(roster.rosterLimit) on roster"
        case .recruitingBoard, .shortlist, .classOverview, .contactVisitPlanner:
            guard let board = store.recruitingBoard else { return nil }
            return "\(board.prospects.count) on the board"
        default:
            return nil
        }
    }

    /// Routes an identity-header or icon-rail tap. Chrome navigation goes through the same
    /// `navigate(_:in:)` every other route uses, so a rail tap cannot reach a screen the router
    /// considers unreachable.
    private func navigateChrome(_ intentID: CoachWorldIntentID, in store: CoachWorldStore) {
        guard let destination = CoachWorldReadModelProvider.routedScreen(for: intentID) else {
            return
        }
        navigate(destination, in: store)
    }

    private func navigate(_ destination: CoachWorldScreenID, in store: CoachWorldStore) {
        let canonicalDestination = destination.canonicalDestination
        if canonicalDestination != destination {
            navigate(canonicalDestination, in: store)
            careerFocus = Self.careerFocus(for: destination)
            if let focus = Self.proFocus(for: destination) {
                proFocus = focus
            }
            return
        }
        if destination != .teamHealth && destination != .inbox {
            store.setPresentationReturnRoute(nil)
        }
        switch destination {
        case .settingsAccessibility:
            screen = .settingsAccessibility
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .coachingHQ:
            screen = .coachingHQ
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .roster where store.availableScreens.contains(.roster):
            screen = .roster
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .inbox where store.availableScreens.contains(.inbox):
            inboxOrigin = screen == .roster ? .roster : .coachingHQ
            store.setPresentationReturnRoute(String(inboxOrigin.rawValue))
            screen = .inbox
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .opponentReportFilmRoom where store.availableScreens.contains(.opponentReportFilmRoom):
            screen = .opponentReportFilmRoom
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .news where store.availableScreens.contains(.news):
            screen = .news
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .recordBook where store.availableScreens.contains(.recordBook),
             .rivalries where store.availableScreens.contains(.recordBook),
             .careerLine where store.availableScreens.contains(.recordBook),
             .coachingTree where store.availableScreens.contains(.recordBook):
            screen = destination
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .statisticsLeaders where store.availableScreens.contains(.statisticsLeaders):
            screen = .statisticsLeaders
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .awardsHonours where store.availableScreens.contains(.awardsHonours):
            screen = .awardsHonours
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .realignmentEvent where store.availableScreens.contains(.realignmentEvent):
            screen = .realignmentEvent
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .gameDetailBoxScore where store.availableScreens.contains(.aftermath):
            screen = .gameDetailBoxScore
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .aftermath where store.availableScreens.contains(.aftermath):
            screen = .aftermath
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .recruitingBoard where store.availableScreens.contains(.recruitingBoard):
            screen = .recruitingBoard
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .prospectProfile where store.availableScreens.contains(.recruitingBoard):
            screen = .prospectProfile
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .shortlist where store.availableScreens.contains(.recruitingBoard):
            screen = .shortlist
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .classOverview where store.availableScreens.contains(.recruitingBoard),
             .contactVisitPlanner where store.availableScreens.contains(.recruitingBoard):
            screen = destination
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .leagueMap where store.availableScreens.contains(.leagueMap):
            screen = .leagueMap
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .gamePlan where store.availableScreens.contains(.gamePlan):
            gamePlanOrigin = switch screen {
            case .matchDay: .matchDay
            case .opponentReportFilmRoom: .opponentReportFilmRoom
            default: .coachingHQ
            }
            screen = .gamePlan
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .practicePlan where store.availableScreens.contains(.practicePlan):
            screen = .practicePlan
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .depthChart where store.availableScreens.contains(.depthChart):
            screen = .depthChart
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .playerProfile where store.availableScreens.contains(.playerProfile):
            screen = destination
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .developmentPlan where store.availableScreens.contains(.roster):
            screen = .developmentPlan
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .teamHealth where store.availableScreens.contains(.teamHealth):
            teamHealthOrigin = screen == .roster ? .roster : .coachingHQ
            store.setPresentationReturnRoute(String(teamHealthOrigin.rawValue))
            screen = .teamHealth
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .proOffseason where store.availableScreens.contains(.proOffseason):
            proFocus = .proOffseason
            screen = .proOffseason
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .draftRoom where store.availableScreens.contains(.draftRoom):
            proFocus = .draftRoom
            screen = .draftRoom
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .staffRoom where store.availableScreens.contains(.staffRoom):
            screen = .staffRoom
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .collegeOffseason where store.availableScreens.contains(.collegeOffseason):
            screen = .collegeOffseason
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .signingDay where store.availableScreens.contains(.signingDay):
            screen = destination
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .capContracts where store.availableScreens.contains(.capContracts),
             .contractNegotiation where store.availableScreens.contains(.capContracts),
             .rosterCutsTransactions where store.availableScreens.contains(.capContracts):
            screen = destination
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .careerHub where store.availableScreens.contains(.careerHub):
            careerFocus = .careerHub
            screen = .careerHub
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .stakeholders where store.availableScreens.contains(.stakeholders),
             .promotionDecision where store.availableScreens.contains(.promotionDecision):
            careerFocus = destination
            screen = .careerHub
            store.setPresentationRoute(String(CoachWorldScreenID.careerHub.rawValue))
            failure = nil
        case .standings where store.availableScreens.contains(.standings):
            screen = .standings
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .schedule where store.availableScreens.contains(.schedule):
            screen = .schedule
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .teamProgrammeProfile where store.availableScreens.contains(.teamProgrammeProfile):
            screen = .teamProgrammeProfile
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .worldSearch where store.availableScreens.contains(.worldSearch):
            screen = .worldSearch
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .rankingsPlayoffPicture where store.availableScreens.contains(.rankingsPlayoffPicture),
             .bracketPostseason where store.availableScreens.contains(.rankingsPlayoffPicture):
            screen = destination
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        default:
            failure = "\(destination.canonicalName) is not available yet"
        }
    }

    private func closeCareer(in store: CoachWorldStore) {
        navigate(store.coachingHQ == nil ? .careerHub : .coachingHQ, in: store)
    }

    private var title: some View {
        TitleContinueView(
            failure: failure,
            isStarting: isStarting,
            isRestoring: isRestoring,
            recoveryRequired: recoveryRequired,
            restoredCareer: store?.careerHub,
            onRetry: {
                hasAttemptedRestore = false
                recoveryRequired = false
                Task { await restoreExistingCareer() }
            },
            onUseBackup: { Task { await recoverFromBackup() } },
            onNewCareer: { Task { await beginNewCareerSetup() } },
            onContinue: { careerConfirmed = true },
            onSettings: { screen = .settingsAccessibility }
        )
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
#if DEBUG
        if let raw = ProcessInfo.processInfo.environment["PROOF_NEW_CAREER"] {
            if let seed = UInt64(raw) {
                await beginProofCareer(seed: seed)
            } else {
                await beginNewCareerSetup()
            }
            return
        }
#endif
        do {
            let outcome = try await coordinator.load()
            guard case let .loaded(document, _) = outcome else {
                return
            }
            store = try await CoachWorldStore.load(document: document)
            if let destination = Self.screenID(for: document.presentation.route) {
                careerFocus = Self.careerFocus(for: destination)
                proFocus = Self.proFocus(for: destination) ?? .proOffseason
                screen = Self.canonicalScreen(destination)
                store?.setPresentationRoute(String(screen.rawValue))
            }
            recruitingProspectID = store?.presentationSubjectID?.uuidString
            if let origin = document.presentation.returnRoute.flatMap(Self.screenID(for:)) {
                if screen == .teamHealth {
                    teamHealthOrigin = origin
                } else if screen == .inbox {
                    inboxOrigin = origin
                }
            }
            failure = nil
            recoveryRequired = false
#if DEBUG
            // The proof/screenshot harness needs deterministic, immediate access to a named
            // screen -- careerConfirmed's whole purpose is pausing an interactive coach at the
            // durable boundary, which does not apply to a harness driven by an environment
            // variable rather than a tap.
            if let proofScreen = Self.proofScreenNumber() {
                screen = proofScreen
                careerConfirmed = true
            }
#endif
        } catch {
            failure = Self.saveErrorMessage(error)
            recoveryRequired = true
        }
    }

#if DEBUG
    /// Reads `PROOF_NEW_CAREER`'s value as a seed and starts the same career the interactive setup
    /// button starts, on the first available job for that seed — bypassing
    /// `NewCareerCoachIdentityView` so a screenshot harness launches straight into a real, playable
    /// career with no hand on the device. Synthetic identity, chosen to read unmistakably as
    /// non-real. Gated `#if DEBUG` so this seam never reaches a release build regardless.
    private func beginProofCareer(seed: UInt64) async {
        let jobs = await CoachWorldStore.startingJobs(seed: seed)
        guard let first = jobs.first else { return }
        await startNewCareer(
            firstName: "Proof",
            lastName: "Coach",
            seed: seed,
            programmeID: first.id
        )
        // startNewCareer never throws out of this call — it catches its own failures and leaves
        // `store` nil, setting `setupError` instead. Applying the override on that outcome would
        // silently land the harness on a plausible-looking screen with no signal that career
        // creation actually failed.
        guard store != nil, let proofScreen = Self.proofScreenNumber() else { return }
        screen = proofScreen
    }

    /// `PROOF_SCREEN_NUMBER`: the registry number of the surface a proof harness wants to land on,
    /// preferred over whatever the restored or newly started career's presentation route would have
    /// set. Invalid or out-of-range values are ignored silently, not treated as a launch failure.
    private static func proofScreenNumber() -> CoachWorldScreenID? {
        guard let raw = ProcessInfo.processInfo.environment["PROOF_SCREEN_NUMBER"],
              let rawValue = Int(raw) else { return nil }
        return CoachWorldScreenID(rawValue: rawValue)
    }
#endif

    private func recoverFromBackup() async {
        guard !isRestoring && !isStarting else { return }
        isRestoring = true
        defer { isRestoring = false }
        do {
            let document = try await coordinator.recover(using: .useBackup)
            store = try await CoachWorldStore.load(document: document)
            if let destination = Self.screenID(for: document.presentation.route) {
                careerFocus = Self.careerFocus(for: destination)
                proFocus = Self.proFocus(for: destination) ?? .proOffseason
                screen = Self.canonicalScreen(destination)
                store?.setPresentationRoute(String(screen.rawValue))
            }
            recruitingProspectID = store?.presentationSubjectID?.uuidString
            if let origin = document.presentation.returnRoute.flatMap(Self.screenID(for:)) {
                if screen == .teamHealth {
                    teamHealthOrigin = origin
                } else if screen == .inbox {
                    inboxOrigin = origin
                }
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

    private static func canonicalScreen(_ screen: CoachWorldScreenID) -> CoachWorldScreenID {
        screen.canonicalDestination
    }

    private static func careerFocus(for screen: CoachWorldScreenID) -> CoachWorldScreenID {
        switch screen {
        case .jobBoard, .offer, .appointment, .stakeholders, .promotionDecision:
            return screen
        default:
            return .careerHub
        }
    }

    private static func proFocus(for screen: CoachWorldScreenID) -> CoachWorldScreenID? {
        switch screen {
        case .proOffseason, .proScoutingBoard, .draftBoard, .draftRoom, .freeAgency:
            return screen
        default:
            return nil
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
            careerConfirmed = true
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
        if store.availableScreens.contains(.careerHub), store.coachingHQ == nil {
            screen = .careerHub
            store.setPresentationRoute(String(CoachWorldScreenID.careerHub.rawValue))
        } else if store.matchDay != nil {
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

    private func acceptCareerOpportunity(_ stableID: String, in store: CoachWorldStore) async {
        await store.acceptCareerOpportunity(stableID)
        await persistOrReport(store)
    }

    private func resignCareer(in store: CoachWorldStore) async {
        await store.resignCareer()
        await persistOrReport(store)
    }

    private func matchControl(
        _ intentID: CoachWorldIntentID,
        in store: CoachWorldStore
    ) async {
        // A bare four-part "...tactics" intent is the button being tapped, not a plan being
        // submitted — GamePlanView's onSelect above appends the three chosen dial values before
        // this function sees a tactics intent again. Routing here rather than through the engine
        // keeps the tap itself from touching MatchSessionState at all: opening the picker is
        // presentation, the skill's "must not alter the recorded moment" for exactly this control.
        let parts = intentID.rawValue.split(separator: "|", omittingEmptySubsequences: false)
        if parts.count == 4, parts[3] == "tactics" {
            navigate(.gamePlan, in: store)
            return
        }
        await store.matchControl(intentID)
        if store.matchDay == nil {
            if store.availableScreens.contains(.aftermath) {
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
        scheduleFlush()
    }

    /// Arms the deferred write, or leaves the armed one alone.
    ///
    /// Deliberately does not restart the timer on each intent. A debounce that resets would never
    /// fire during a match, where snaps arrive faster than any sensible delay; this fires on a
    /// fixed deadline from the first unwritten intent, so the gap between committing and writing
    /// has a ceiling no matter how fast the coach is playing.
    private func scheduleFlush() {
        guard flushTask == nil else { return }
        flushTask = Task { @MainActor in
            try? await Task.sleep(for: Self.flushDelay)
            flushTask = nil
            await flushNow()
        }
    }

    /// Writes whatever is pending, now. Used by the deferred task and by leaving the app.
    private func flushNow(reason: SaveFlushReason = .explicit) async {
        do {
            try await coordinator.flush(reason: reason)
        } catch {
            failure = "The career could not be saved: \(error)"
        }
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
