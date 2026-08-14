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
    /// True while an intent is in flight. Screens disable their commit controls on it.
    public private(set) var isWorking = false
    /// The last receipt or refusal, shown verbatim. Never a guess about what happened.
    public private(set) var statusMessage: String?
    public private(set) var presentationRoute: String

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
        coachingHQ = CoachWorldReadModelProvider.coachingHQ(from: snapshot)
        roster = CoachWorldReadModelProvider.roster(from: snapshot)
        recruitingBoard = CoachWorldReadModelProvider.recruitingBoard(from: snapshot)
    }

    /// Generates a world from `seed` and takes the job with the least prestige in it.
    ///
    /// The choice is deterministic and needs no Job Board: `02`'s career arc starts at the bottom
    /// of the college game, and ties break on the identifier so the same seed always yields the
    /// same first job. Screen 3 replaces this with the player's own choice.
    ///
    /// `nonisolated`, and the generation runs detached, because it is seconds of work on 15,766
    /// players and 2,158 staff. A `@MainActor` static would have run all of it on the main actor
    /// and frozen the title screen — including the progress indicator that exists to say it is
    /// working.
    public nonisolated static func newCareer(seed: UInt64) async throws -> CoachWorldStore {
        let started = try await Task.detached(priority: .userInitiated) {
            let world = GameState.bootstrap(seed: seed)
            let candidates = world.programmes.values.sorted {
                $0.prestige.value == $1.prestige.value
                    ? $0.id.uuidString < $1.id.uuidString
                    : $0.prestige.value < $1.prestige.value
            }
            guard let first = candidates.first else { throw StartError.noProgrammeAvailable }
            return try CareerControlSystem.startCollegeCareer(at: first.id, in: world).state
        }.value
        return try await make(
            from: CoachWorldSaveDocument(
                gameState: started,
                presentation: CareerPresentationState(route: "8"),
                metadata: CareerSaveMetadata(createdFromSeed: seed)
            )
        )
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
        let sequence = mutationGeneration
        guard metadata.generation < UInt64.max else {
            throw SaveDocumentError.generationOverflow
        }
        let nextGeneration = max(metadata.generation + 1, sequence)
        metadata.generation = nextGeneration
        let presentation = self.presentation
        let documentMetadata = metadata
        let snapshot = await session.snapshot()
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

    public func advanceWeek() async {
        await run { try await self.session.resolve(.advanceWeek) }
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
            statusMessage = "\(error)"
        }
        let snapshot = await session.snapshot()
        coachingHQ = CoachWorldReadModelProvider.coachingHQ(from: snapshot)
        roster = CoachWorldReadModelProvider.roster(from: snapshot)
        recruitingBoard = CoachWorldReadModelProvider.recruitingBoard(from: snapshot)
    }
}
