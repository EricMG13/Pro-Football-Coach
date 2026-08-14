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
    /// Set before the first `await`, not after it. `.task` can run more than once for one view,
    /// and `store == nil` stays true across every suspension point inside the load — so guarding on
    /// the store alone lets two loads, or two world generations, start side by side.
    @State private var hasAttemptedRestore = false
    @State private var screen: CoachWorldScreenID = .coachingHQ
    @State private var recoveryRequired = false

    @State private var coordinator: SaveCoordinator

    public init(saves: CoachWorldSaveStore = CoachWorldSaveStore()) {
        _coordinator = State(initialValue: SaveCoordinator(storage: saves))
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
                        onDelegate: {},
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
            } else if recoveryRequired {
                Button("Retry restore") {
                    hasAttemptedRestore = false
                    recoveryRequired = false
                    Task { await restoreExistingCareer() }
                }
                Button("Use backup") { Task { await recoverFromBackup() } }
                Button("Replace with a new career") { Task { await startNewCareer() } }
            } else {
                Button("New career") { Task { await startNewCareer() } }
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
        do {
            let outcome = try await coordinator.load()
            guard case let .loaded(document, _) = outcome else {
                if ProcessInfo.processInfo.environment["PROOF_NEW_CAREER"] != nil {
                    await startNewCareer()
                }
                return
            }
            store = try await CoachWorldStore.load(document: document)
            if let restored = Int(document.presentation.route),
               let destination = CoachWorldScreenID(rawValue: restored) {
                screen = destination
            }
        } catch {
            failure = Self.saveErrorMessage(error)
            recoveryRequired = true
        }
    }

    private func recoverFromBackup() async {
        do {
            let document = try await coordinator.recover(using: .useBackup)
            store = try await CoachWorldStore.load(document: document)
            if let restored = Int(document.presentation.route),
               let destination = CoachWorldScreenID(rawValue: restored) {
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
        let document = try await store.saveDocument()
        await coordinator.requestSave(document, reason: .userAction)
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
