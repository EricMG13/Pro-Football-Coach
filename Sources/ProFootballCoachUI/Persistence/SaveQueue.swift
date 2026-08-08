import Foundation
import FootballSimCore

/// Serialises franchise writes off the main actor, and coalesces bursts.
///
/// `AppState.mutate` persists after every state change, so a draft round or an offseason stage
/// queues dozens of writes in a second — each one a 2–3 MB encode plus a backup copy and an
/// atomic write. Only the newest snapshot is worth writing, so this keeps exactly one write in
/// flight and one pending, and discards everything in between.
///
/// This is a plain actor rather than `@MainActor` on purpose: the blocking file I/O runs on the
/// actor's own executor, which is the entire point.
public actor SaveQueue {

    /// A franchise frozen at the moment it was queued, so later mutations cannot alter a write
    /// that is already in flight.
    public struct Snapshot: Sendable {
        public let league: League
        public let id: UUID
        public let name: String

        public init(league: League, id: UUID, name: String) {
            self.league = league
            self.id = id
            self.name = name
        }
    }

    private let store: SaveStore
    private var pending: Snapshot?
    private var isDraining = false
    private var drainWaiters: [CheckedContinuation<Void, Never>] = []

    /// Writes actually performed. Coalescing means this is normally far below the enqueue count.
    public private(set) var writeCount = 0
    private var failure: String?

    public init(store: SaveStore) {
        self.store = store
    }

    public func enqueue(_ snapshot: Snapshot) {
        pending = snapshot
        guard !isDraining else { return }
        isDraining = true
        Task { await self.drain() }
    }

    private func drain() async {
        while let snapshot = pending {
            pending = nil
            do {
                _ = try store.save(snapshot.league, id: snapshot.id, name: snapshot.name)
                writeCount += 1
            } catch {
                failure = "Could not save: \(error.localizedDescription)"
            }
        }
        isDraining = false
        let waiters = drainWaiters
        drainWaiters = []
        for waiter in waiters { waiter.resume() }
    }

    /// Waits until nothing is queued or in flight. Used before closing a franchise or
    /// backgrounding the app, so a dynasty is never lost to a write that never finished.
    public func flush() async {
        guard isDraining else { return }
        await withCheckedContinuation { drainWaiters.append($0) }
    }

    public func list() -> [SaveMeta] { store.list() }

    /// Returns the last write failure and clears it, so one failure is surfaced once.
    public func takeError() -> String? {
        defer { failure = nil }
        return failure
    }
}
