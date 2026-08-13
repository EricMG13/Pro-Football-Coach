import SwiftUI
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
    /// Set before the first `await`, not after it. `.task` can run more than once for one view,
    /// and `store == nil` stays true across every suspension point inside the load — so guarding on
    /// the store alone lets two loads, or two world generations, start side by side.
    @State private var hasAttemptedRestore = false
    @State private var screen: CoachWorldScreenID = .coachingHQ

    private let saves: CoachWorldSaveStore

    public init(saves: CoachWorldSaveStore = CoachWorldSaveStore()) {
        self.saves = saves
    }

    public var body: some View {
        Group {
            if let store {
                career(store)
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
                        onInspectDevelopment: { _ in }
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
            case .inbox:
                if let model = store.inbox {
                    InboxView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onContinue: { Task { await advance(store) } },
                        onNavigate: { navigate($0, in: store) }
                    )
                }
            case .opponentReportFilmRoom:
                if let model = store.opponentReport {
                    OpponentReportFilmRoomView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onContinue: { Task { await advance(store) } },
                        onNavigate: { navigate($0, in: store) }
                    )
                }
            case .gamePlan:
                if let model = store.gamePlan {
                    GamePlanView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onContinue: { Task { await advance(store) } },
                        onNavigate: { navigate($0, in: store) },
                        onSetPlan: { runPass, tempo, pressure in
                            Task {
                                await store.setGamePlan(
                                    runPass: runPass, tempo: tempo, pressure: pressure
                                )
                                await persistOrReport(store)
                            }
                        }
                    )
                }
            case .practicePlan:
                if let model = store.practicePlan {
                    PracticePlanView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onContinue: { Task { await advance(store) } },
                        onNavigate: { navigate($0, in: store) },
                        onSetPreset: { preset in
                            Task {
                                await store.setPracticePreset(preset)
                                await persistOrReport(store)
                            }
                        }
                    )
                }
            case .teamHealth:
                if let model = store.teamHealth {
                    TeamHealthView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onContinue: { Task { await advance(store) } },
                        onNavigate: { navigate($0, in: store) }
                    )
                }
            case .aftermath:
                if let model = store.aftermath {
                    AftermathView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onContinue: { Task { await advance(store) } },
                        onNavigate: { navigate($0, in: store) }
                    )
                }
            default:
                if let model = store.coachingHQ {
                    CoachingHQView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onCommit: { intentID in Task { await commit(intentID, in: store) } },
                        onInspect: { navigate(.opponentReportFilmRoom, in: store) },
                        onDelegate: {},
                        onContinue: { Task { await advance(store) } },
                        onOpenCorrespondence: { _ in navigate(.inbox, in: store) },
                        onNavigate: { navigate($0, in: store) }
                    )
                }
            }
        }
        .disabled(store.isWorking)
        .overlay { if store.isWorking { working } }
    }

    private func navigate(_ destination: CoachWorldScreenID, in store: CoachWorldStore) {
        let allowed: Set<CoachWorldScreenID> = [
            .coachingHQ, .roster, .recruitingBoard, .inbox, .opponentReportFilmRoom,
            .gamePlan, .practicePlan, .teamHealth, .aftermath,
        ]
        guard allowed.contains(destination) else {
            failure = "\(destination.canonicalName) is not available yet"
            return
        }
        screen = destination
        failure = nil
    }

    private var title: some View {
        TitleContinueView(
            model: TitleContinueReadModel(
                hasExistingSave: saves.hasSave,
                isStarting: isStarting,
                failure: failure
            ),
            onNewCareer: { Task { await startNewCareer() } },
            onContinueCareer: { Task { await retryLoad() } }
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
    private func retryLoad() async {
        hasAttemptedRestore = false
        await restoreExistingCareer()
    }

    private func restoreExistingCareer() async {
        guard !hasAttemptedRestore else { return }
        hasAttemptedRestore = true
        guard saves.hasSave else {
            if ProcessInfo.processInfo.environment["PROOF_NEW_CAREER"] != nil {
                await startNewCareer()
            }
            return
        }
        do {
            store = try await CoachWorldStore.load(from: saves.read())
        } catch {
            failure = "That save could not be opened: \(error)"
        }
    }

    private func startNewCareer() async {
        isStarting = true
        defer { isStarting = false }
        do {
            let started = try await CoachWorldStore.newCareer(seed: CoachWorldStore.defaultSeed)
            try await persist(started)
            store = started
            failure = nil
        } catch {
            failure = "The world could not be built: \(error)"
        }
    }

    private func advance(_ store: CoachWorldStore) async {
        await store.advanceWeek()
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
        try saves.write(await store.save())
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
