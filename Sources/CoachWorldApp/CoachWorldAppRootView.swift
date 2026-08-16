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
    @State private var teamHealthOrigin: CoachWorldScreenID = .coachingHQ
    @State private var inboxOrigin: CoachWorldScreenID = .coachingHQ
    @State private var recruitingProspectID: String?
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
            case .developmentPlan:
                if let model = store.roster {
                    DevelopmentPlanView(model: model, statusMessage: failure ?? store.statusMessage,
                                        onClose: { navigate(.roster, in: store) })
                }
            case .inbox:
                if let model = store.inbox {
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
                }
            case .opponentReportFilmRoom:
                if let model = store.opponentFilm {
                    OpponentReportFilmRoomView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { closeCareer(in: store) },
                        onContinue: { Task { await advance(store) } }
                    )
                }
            case .news:
                if let model = store.news {
                    NewsView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { closeCareer(in: store) }
                    )
                }
            case .recordBook:
                if let model = store.legacyHistory {
                    RecordBookView(model: model, statusMessage: failure ?? store.statusMessage,
                                   onClose: { closeCareer(in: store) },
                                   onNavigate: { navigate($0, in: store) })
                }
            case .rivalries:
                if let model = store.legacyHistory {
                    RivalriesView(model: model, statusMessage: failure ?? store.statusMessage,
                                  onClose: { closeCareer(in: store) },
                                  onNavigate: { navigate($0, in: store) })
                }
            case .careerLine:
                if let model = store.legacyHistory {
                    CareerLineView(model: model, statusMessage: failure ?? store.statusMessage,
                                   onClose: { closeCareer(in: store) },
                                   onNavigate: { navigate($0, in: store) })
                }
            case .coachingTree:
                if let model = store.legacyHistory {
                    CoachingTreeView(model: model, statusMessage: failure ?? store.statusMessage,
                                     onClose: { closeCareer(in: store) },
                                     onNavigate: { navigate($0, in: store) })
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
                }
            case .prospectProfile:
                if let model = store.recruitingBoard {
                    ProspectProfileView(
                        model: model,
                        prospectID: recruitingProspectID,
                        statusMessage: failure ?? store.statusMessage,
                        onAction: { prospectID, intentID in
                            Task { await actOnProspect(prospectID, intentID, in: store) }
                        },
                        onClose: { navigate(.recruitingBoard, in: store) }
                    )
                }
            case .shortlist:
                if let model = store.recruitingBoard {
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
                }
            case .classOverview:
                if let model = store.recruitingBoard {
                    ClassOverviewView(model: model, statusMessage: failure ?? store.statusMessage,
                                      onClose: { closeCareer(in: store) })
                }
            case .contactVisitPlanner:
                if let model = store.recruitingBoard {
                    ContactVisitPlannerView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onAction: { prospectID, intentID in
                            Task { await actOnProspect(prospectID, intentID, in: store) }
                        },
                        onClose: { closeCareer(in: store) }
                    )
                }
            case .statisticsLeaders:
                if let model = store.statisticsLeaders {
                    StatisticsLeadersView(model: model, statusMessage: failure ?? store.statusMessage,
                                          onClose: { closeCareer(in: store) })
                }
            case .awardsHonours:
                if let model = store.awardsHonours {
                    AwardsHonoursView(model: model, statusMessage: failure ?? store.statusMessage,
                                      onClose: { closeCareer(in: store) })
                }
            case .realignmentEvent:
                if let model = store.realignment {
                    RealignmentEventView(model: model, statusMessage: failure ?? store.statusMessage,
                                         onClose: { closeCareer(in: store) })
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
            case .teamHealth:
                if let model = store.teamHealth {
                    TeamHealthView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { navigate(teamHealthOrigin, in: store) },
                        onContinue: { Task { await advance(store) } }
                    )
                }
            case .proOffseason:
                if let model = store.proOffseason {
                    ProOffseasonView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onAction: { action in
                            Task { await store.actOnProMarket(action) }
                        },
                        onClose: { closeCareer(in: store) }
                    )
                }
            case .draftBoard:
                if let model = store.proOffseason {
                    DraftBoardView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onAction: { action in Task { await store.actOnProMarket(action) } },
                        onClose: { closeCareer(in: store) }
                    )
                }
            case .draftRoom:
                if let model = store.proOffseason {
                    DraftRoomView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onAction: { action in
                            Task { await store.actOnProMarket(action) }
                        },
                        onClose: { closeCareer(in: store) }
                    )
                }
            case .freeAgency:
                if let model = store.proOffseason {
                    FreeAgencyView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onAction: { action in Task { await store.actOnProMarket(action) } },
                        onClose: { closeCareer(in: store) }
                    )
                }
            case .proScoutingBoard:
                if let model = store.proOffseason {
                    ProScoutingBoardView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onAction: { action in Task { await store.actOnProMarket(action) } },
                        onClose: { closeCareer(in: store) }
                    )
                }
            case .collegeOffseason:
                if let model = store.collegeOffseason {
                    CollegeOffseasonView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onCommit: { intentID in Task { await commit(intentID, in: store) } },
                        onContinue: { Task { await advance(store) } },
                        onClose: { closeCareer(in: store) }
                    )
                }
            case .portalHub:
                if let model = store.collegeOffseason {
                    PortalHubView(model: model, statusMessage: failure ?? store.statusMessage,
                                  onCommit: { id in Task { await commit(id, in: store) } },
                                  onContinue: { Task { await advance(store) } },
                                  onClose: { closeCareer(in: store) })
                }
            case .retentionDecisions:
                if let model = store.collegeOffseason {
                    RetentionDecisionsView(model: model, statusMessage: failure ?? store.statusMessage,
                                            onCommit: { id in Task { await commit(id, in: store) } },
                                            onContinue: { Task { await advance(store) } },
                                            onClose: { closeCareer(in: store) })
                }
            case .portalMarket:
                if let model = store.collegeOffseason {
                    PortalMarketView(model: model, statusMessage: failure ?? store.statusMessage,
                                     onCommit: { id in Task { await commit(id, in: store) } },
                                     onContinue: { Task { await advance(store) } },
                                     onClose: { closeCareer(in: store) })
                }
            case .nilAllocation:
                if let model = store.collegeOffseason {
                    NilAllocationView(model: model, statusMessage: failure ?? store.statusMessage,
                                      onCommit: { id in Task { await commit(id, in: store) } },
                                      onContinue: { Task { await advance(store) } },
                                      onClose: { closeCareer(in: store) })
                }
            case .signingDay:
                if let model = store.collegeOffseason {
                    SigningDayView(model: model, statusMessage: failure ?? store.statusMessage,
                                   onCommit: { id in Task { await commit(id, in: store) } },
                                   onContinue: { Task { await advance(store) } },
                                   onClose: { closeCareer(in: store) })
                }
            case .capContracts:
                if let model = store.proManagement {
                    CapContractsView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onAction: { action in
                            Task { await store.actOnProManagement(action) }
                        },
                        onClose: { closeCareer(in: store) }
                    )
                }
            case .contractNegotiation:
                if let model = store.proManagement {
                    ContractNegotiationView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onAction: { action in
                            Task { await store.actOnProManagement(action) }
                        },
                        onClose: { closeCareer(in: store) }
                    )
                }
            case .rosterCutsTransactions:
                if let model = store.proManagement {
                    RosterCutsTransactionsView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onAction: { action in Task { await store.actOnProManagement(action) } },
                        onClose: { closeCareer(in: store) }
                    )
                }
            case .staffRoom:
                if let model = store.staffRoom {
                    StaffRoomView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { closeCareer(in: store) }
                    )
                }
            case .staffMarketProfile:
                if let model = store.staffRoom {
                    StaffMarketProfileView(model: model, statusMessage: failure ?? store.statusMessage,
                                           onClose: { closeCareer(in: store) })
                }
            case .schemeBook:
                if let model = store.gamePlan {
                    SchemeBookView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onSelect: { plan in Task { await setGamePlan(plan, in: store) } },
                        onClose: { closeCareer(in: store) }
                    )
                }
            case .personnelPackages:
                if let model = store.depthChart {
                    PersonnelPackagesView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onSelect: { plan in Task { await setPersonnelPlan(plan, in: store) } },
                        onClose: { closeCareer(in: store) }
                    )
                }
            case .aftermath:
                if let model = store.aftermath {
                    AftermathView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onContinue: { Task { await returnToHQ(store) } },
                        onOpenBoxScore: {
                            navigate(.gameDetailBoxScore, in: store)
                            Task { await persistOrReport(store) }
                        }
                    )
                }
            case .gameDetailBoxScore:
                if let model = store.aftermath {
                    GameDetailBoxScoreView(
                        model: model,
                        onClose: { navigate(.aftermath, in: store) }
                    )
                }
            case .careerHub:
                if let model = store.careerHub {
                    CareerHubView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onClose: { closeCareer(in: store) },
                        focus: screen,
                        onNavigate: { navigate($0, in: store) },
                        onAcceptOpportunity: { id in
                            Task { await acceptCareerOpportunity(id, in: store) }
                        },
                        onResign: { Task { await resignCareer(in: store) } },
                        onContinue: { Task { await advance(store) } }
                    )
                }
            case .jobBoard:
                if let model = store.careerHub {
                    JobBoardView(model: model, statusMessage: failure ?? store.statusMessage,
                                 onClose: { closeCareer(in: store) },
                                 onNavigate: { navigate($0, in: store) },
                                 onAcceptOpportunity: { id in Task { await acceptCareerOpportunity(id, in: store) } },
                                 onResign: { Task { await resignCareer(in: store) } },
                                 onContinue: { Task { await advance(store) } })
                }
            case .offer:
                if let model = store.careerHub {
                    OfferView(model: model, statusMessage: failure ?? store.statusMessage,
                              onClose: { closeCareer(in: store) },
                              onNavigate: { navigate($0, in: store) },
                              onAcceptOpportunity: { id in Task { await acceptCareerOpportunity(id, in: store) } },
                              onResign: { Task { await resignCareer(in: store) } },
                              onContinue: { Task { await advance(store) } })
                }
            case .appointment:
                if let model = store.careerHub {
                    AppointmentView(model: model, statusMessage: failure ?? store.statusMessage,
                                    onClose: { closeCareer(in: store) },
                                    onNavigate: { navigate($0, in: store) },
                                    onAcceptOpportunity: { id in Task { await acceptCareerOpportunity(id, in: store) } },
                                    onResign: { Task { await resignCareer(in: store) } },
                                    onContinue: { Task { await advance(store) } })
                }
            case .jobSecurity:
                if let model = store.careerHub {
                    JobSecurityView(
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
                }
            case .stakeholders:
                if let model = store.careerHub {
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
                }
            case .promotionDecision:
                if let model = store.careerHub {
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
                }
            case .coachingCarousel:
                if let model = store.careerHub {
                    CoachingCarouselView(
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
            case .rankingsPlayoffPicture:
                if let model = store.competitionOverview {
                    RankingsPlayoffPictureView(
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
            case .bracketPostseason:
                if let model = store.competitionOverview {
                    BracketPostseasonView(
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
            default:
                if let model = store.coachingHQ {
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
                        showsProOffseason: store.proOffseason != nil,
                        showsDraftRoom: store.proOffseason?.phase == .draft,
                        showsCareer: store.careerHub != nil,
                        showsSigningDay: store.collegeOffseason?.cyclePhase == .signing,
                        showsCollegeOffseason: store.collegeOffseason != nil,
                        showsProManagement: store.proManagement != nil,
                        showsContractNegotiation: store.proManagement != nil,
                        showsRecruitingBoard: store.recruitingBoard != nil
                    )
                }
            }
        }
        .disabled(store.isWorking)
        .overlay { if store.isWorking { working } }
    }

    private func navigate(_ destination: CoachWorldScreenID, in store: CoachWorldStore) {
        if destination != .teamHealth && destination != .inbox {
            store.setPresentationReturnRoute(nil)
        }
        switch destination {
        case .coachingHQ:
            screen = .coachingHQ
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .roster where store.roster != nil:
            screen = .roster
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .inbox where store.inbox != nil:
            inboxOrigin = screen == .roster ? .roster : .coachingHQ
            store.setPresentationReturnRoute(String(inboxOrigin.rawValue))
            screen = .inbox
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .opponentReportFilmRoom where store.opponentFilm != nil:
            screen = .opponentReportFilmRoom
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .news where store.news != nil:
            screen = .news
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .recordBook where store.legacyHistory != nil,
             .rivalries where store.legacyHistory != nil,
             .careerLine where store.legacyHistory != nil,
             .coachingTree where store.legacyHistory != nil:
            screen = destination
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .statisticsLeaders where store.statisticsLeaders != nil:
            screen = .statisticsLeaders
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .awardsHonours where store.awardsHonours != nil:
            screen = .awardsHonours
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .realignmentEvent where store.realignment != nil:
            screen = .realignmentEvent
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .gameDetailBoxScore where store.aftermath != nil:
            screen = .gameDetailBoxScore
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .aftermath where store.aftermath != nil:
            screen = .aftermath
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .recruitingBoard where store.recruitingBoard != nil:
            screen = .recruitingBoard
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .prospectProfile where store.recruitingBoard != nil:
            screen = .prospectProfile
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .shortlist where store.recruitingBoard != nil:
            screen = .shortlist
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .classOverview where store.recruitingBoard != nil,
             .contactVisitPlanner where store.recruitingBoard != nil:
            screen = destination
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
        case .developmentPlan where store.roster != nil:
            screen = .developmentPlan
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .teamHealth where store.teamHealth != nil:
            teamHealthOrigin = screen == .roster ? .roster : .coachingHQ
            store.setPresentationReturnRoute(String(teamHealthOrigin.rawValue))
            screen = .teamHealth
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .proOffseason where store.proOffseason != nil:
            screen = .proOffseason
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .draftBoard where store.proOffseason != nil,
             .freeAgency where store.proOffseason != nil,
             .proScoutingBoard where store.proOffseason != nil:
            screen = destination
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .draftRoom where store.proOffseason?.phase == .draft:
            screen = .draftRoom
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .staffRoom where store.staffRoom != nil,
             .staffMarketProfile where store.staffRoom != nil:
            screen = destination
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .schemeBook where store.gamePlan != nil,
             .personnelPackages where store.depthChart != nil:
            screen = destination
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .collegeOffseason where store.collegeOffseason != nil:
            screen = .collegeOffseason
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .portalHub where store.collegeOffseason != nil,
             .retentionDecisions where store.collegeOffseason != nil,
             .portalMarket where store.collegeOffseason != nil,
             .nilAllocation where store.collegeOffseason != nil:
            screen = destination
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .signingDay where store.collegeOffseason?.cyclePhase == .signing:
            screen = .signingDay
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .capContracts where store.proManagement != nil,
             .contractNegotiation where store.proManagement != nil,
             .rosterCutsTransactions where store.proManagement != nil:
            screen = destination
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .careerHub where store.careerHub != nil:
            screen = .careerHub
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .jobBoard where store.careerHub != nil,
             .offer where store.careerHub != nil,
             .appointment where store.careerHub != nil:
            screen = destination
            store.setPresentationRoute(String(destination.rawValue))
            failure = nil
        case .jobSecurity where store.careerHub != nil,
             .stakeholders where store.careerHub != nil,
             .promotionDecision where store.careerHub != nil,
             .coachingCarousel where store.careerHub != nil:
            screen = destination
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

    private func closeCareer(in store: CoachWorldStore) {
        navigate(store.coachingHQ == nil ? .careerHub : .coachingHQ, in: store)
    }

    private var title: some View {
        TitleContinueView(
            failure: failure,
            isStarting: isStarting,
            isRestoring: isRestoring,
            recoveryRequired: recoveryRequired,
            onRetry: {
                hasAttemptedRestore = false
                recoveryRequired = false
                Task { await restoreExistingCareer() }
            },
            onUseBackup: { Task { await recoverFromBackup() } },
            onNewCareer: { Task { await beginNewCareerSetup() } },
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
        if store.careerHub != nil, store.coachingHQ == nil {
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
