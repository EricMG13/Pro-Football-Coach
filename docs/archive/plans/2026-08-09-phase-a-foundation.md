# Phase A — Foundation Implementation Plan

> **For agentic workers:** Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land every look-independent audit fix and the Almanac token foundation, with no visible
redesign of any surface yet.

**Architecture:** Franchise writes move off the main actor behind a coalescing `SaveQueue` actor.
Failures become visible. The Almanac grounds/ink/rule/type tokens join `DesignSystem.swift` beside
the existing rating ladder, verified by an extended contrast suite before any view adopts them.

**Tech Stack:** Swift 5.10, SwiftUI, iOS 17, zero dependencies. Tests: hand-rolled `TestKit`
executable (`swift run -c release SimTests`).

## Global Constraints

- Ratings 40–99 ints; money integer dollars.
- No third-party dependencies. No image assets.
- iPhone only. Portrait app; only the arcade screen may go landscape.
- Every colour verified ≥4.5:1 against every surface it is drawn on, both themes, by test.
- Zero shadows. Text styles only — no hard-coded point sizes in anything this phase touches.
- Fictional identity everywhere.

---

### Task 1: SaveQueue actor

**Files:** Create `Sources/ProFootballCoachUI/Persistence/SaveQueue.swift`; Test
`Tests/SimTests/Suites/SaveQueueTests.swift`; Modify `Tests/SimTests/TestKit.swift`,
`Tests/SimTests/main.swift`

**Produces:** `SaveQueue` actor with `Snapshot(league:id:name:)`, `enqueue(_:)`, `flush()`,
`list()`, `takeError()`, `writeCount`.

- [ ] **Step 1: Add async test support to TestKit**

```swift
/// Runs an async test body to completion. Never use for `@MainActor` work — this blocks the
/// calling thread, and a main-actor hop would deadlock.
static func testAsync(_ name: String, _ body: @escaping @Sendable () async throws -> Void) {
    currentTest = name
    testsRun += 1
    let done = DispatchSemaphore(value: 0)
    Task {
        do { try await body() } catch { record("threw \(error)") }
        done.signal()
    }
    done.wait()
}
```
Plus a free function `func testAsync(_ name: String, _ body: @escaping @Sendable () async throws -> Void) { TestKit.testAsync(name, body) }` and `import Dispatch`.

- [ ] **Step 2: Write the failing test**

```swift
func runSaveQueueTests() {
    suite("SaveQueue") {
        testAsync("a burst of writes coalesces and the last one wins") {
            let dir = FileManager.default.temporaryDirectory
                .appendingPathComponent("sq-\(UUID().uuidString)", isDirectory: true)
            let store = SaveStore(directory: dir)
            let queue = SaveQueue(store: store)
            let id = UUID()
            let base = LeagueFactory.makeDefaultLeague(seed: 7, userTeamIndex: 0, coach: .stub())

            for year in 2026...2030 {
                var league = base
                league.year = year
                await queue.enqueue(.init(league: league, id: id, name: "Test"))
            }
            await queue.flush()

            let loaded = try store.load(id: id)
            expectEqual(loaded.year, 2030, "the newest snapshot must win")
            let writes = await queue.writeCount
            expect(writes >= 1 && writes <= 5, "coalesced to \(writes) writes")
            let listed = await queue.list()
            expectEqual(listed.count, 1, "one save on disk")
            try? FileManager.default.removeItem(at: dir)
        }

        testAsync("flush returns immediately when nothing is queued") {
            let dir = FileManager.default.temporaryDirectory
                .appendingPathComponent("sq-\(UUID().uuidString)", isDirectory: true)
            let queue = SaveQueue(store: SaveStore(directory: dir))
            await queue.flush()
            let writes = await queue.writeCount
            expectEqual(writes, 0, "no writes")
            try? FileManager.default.removeItem(at: dir)
        }
    }
}
```

- [ ] **Step 3: Run to verify it fails** — `swift run -c release SimTests` → "cannot find 'SaveQueue'"

- [ ] **Step 4: Implement SaveQueue**

```swift
import Foundation
import FootballSimCore

/// Serialises franchise writes off the main actor, coalescing bursts.
///
/// `AppState.mutate` persists after every change, so a draft or an offseason stage can queue
/// dozens of writes a second. Only the newest snapshot is worth keeping: this holds exactly one
/// in flight and one pending and drops everything in between. The blocking file IO runs on this
/// actor's executor, never on the main thread — a 2–3 MB encode there was the app's worst hitch.
public actor SaveQueue {
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
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private var failure: String?
    public private(set) var writeCount = 0

    public init(store: SaveStore) { self.store = store }

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
                try store.save(snapshot.league, id: snapshot.id, name: snapshot.name)
                writeCount += 1
            } catch {
                failure = "Could not save: \(error.localizedDescription)"
            }
        }
        isDraining = false
        let resuming = waiters
        waiters = []
        for waiter in resuming { waiter.resume() }
    }

    /// Waits until nothing is queued or in flight.
    public func flush() async {
        guard isDraining else { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    public func list() -> [SaveMeta] { store.list() }

    public func delete(id: UUID) { store.delete(id: id) }

    /// Returns the last write failure and clears it.
    public func takeError() -> String? {
        defer { failure = nil }
        return failure
    }
}
```

- [ ] **Step 5: Register and run** — add `runSaveQueueTests()` to `main.swift`; expect PASS.

- [ ] **Step 6: Commit** — `perf: coalesce franchise writes onto a background actor`

---

### Task 2: AppState uses the queue

**Files:** Modify `Sources/ProFootballCoachUI/AppState.swift`

- [ ] **Step 1:** Replace `private let store: SaveStore` with both, keeping `store` for reads:

```swift
private let store: SaveStore
private let queue: SaveQueue

public init(store: SaveStore = SaveStore()) {
    self.store = store
    self.queue = SaveQueue(store: store)
    saves = store.list()
}
```

- [ ] **Step 2:** Rewrite `persist()` — the main thread now only builds a snapshot:

```swift
/// Queues the current franchise for writing. Returns immediately; the encode and the file IO
/// happen on `SaveQueue`.
public func persist() {
    guard let league, let saveID else { return }
    let snapshot = SaveQueue.Snapshot(league: league, id: saveID, name: saveName)
    Task {
        await queue.enqueue(snapshot)
        await queue.flush()
        saves = await queue.list()
        if let failure = await queue.takeError() { lastError = failure }
    }
}

/// Waits for pending writes. Called when a franchise closes and when the app backgrounds.
public func flushSaves() async {
    await queue.flush()
    saves = await queue.list()
    if let failure = await queue.takeError() { lastError = failure }
}
```

- [ ] **Step 3:** `closeFranchise()` keeps persisting before clearing (the snapshot is captured
  first, so clearing immediately is safe):

```swift
public func closeFranchise() {
    persist()
    league = nil
    saveID = nil
    draftSession = nil
}
```

- [ ] **Step 4:** `delete(id:)` routes through the queue and refreshes:

```swift
public func delete(id: UUID) {
    store.delete(id: id)
    if saveID == id { league = nil; saveID = nil }
    saves = store.list()
}
```
(unchanged — `store` is still the read/delete path; only writes moved.)

- [ ] **Step 5: Run tests** — `swift run -c release SimTests`; expect all pass.

- [ ] **Step 6: Commit** — `perf: take the franchise save off the main actor`

---

### Task 3: Stop the load path parsing twice and rewriting

**Files:** Modify `Sources/ProFootballCoachUI/Persistence/SaveStore.swift`,
`Sources/ProFootballCoachUI/AppState.swift`

- [ ] **Step 1: Write the failing test** in `Tests/SimTests/Suites/PersistenceTests.swift`:

```swift
test("a future-version save is refused without a full parse") {
    let data = Data(#"{"version":99999}"#.utf8)
    var threw = false
    do { _ = try SaveMigrator.migrate(data: data, decoder: JSONDecoder.stable()) }
    catch { threw = true }
    expect(threw, "a future version must be refused")
}
```

- [ ] **Step 2:** Replace `JSONSerialization` with a cheap probe:

```swift
/// Only the version is needed before deciding how to decode, and running a full
/// `JSONSerialization` pass over a multi-megabyte save just to read one integer doubled the
/// cost of opening a franchise.
private struct VersionProbe: Decodable { let version: Int }

public static func migrate(data: Data, decoder: JSONDecoder) throws -> League {
    guard let probe = try? decoder.decode(VersionProbe.self, from: data) else {
        throw MigrationError.unreadable
    }
    guard probe.version <= League.currentVersion else {
        throw MigrationError.futureVersion(probe.version)
    }
    return try decoder.decode(League.self, from: data)
}
```

- [ ] **Step 3:** In `AppState.load(id:)`, only write back when the load actually changed
  something:

```swift
public func load(id: UUID) {
    do {
        var loaded = try store.load(id: id)
        var seededGoals = false
        if loaded.seasonGoals.isEmpty, !loaded.phase.isOffseason {
            var rng = loaded.rng
            loaded.seasonGoals = CoachEngine.makeSeasonGoals(for: loaded, rng: &rng)
            loaded.rng = rng
            seededGoals = true
        }
        league = loaded
        saveID = id
        saveName = saves.first { $0.id == id }?.name ?? "Franchise"
        draftPicks = TradeEngine.makePicks(for: loaded)
        // Opening a franchise used to rewrite it immediately. Only persist when the load
        // actually repaired something.
        if seededGoals { persist() }
    } catch {
        lastError = "That save could not be opened. The file has not been changed."
    }
}
```

- [ ] **Step 4: Run tests** — expect PASS.
- [ ] **Step 5: Commit** — `perf: read a save's version without parsing the whole file`

---

### Task 4: Make failures visible

**Files:** Modify `Sources/ProFootballCoachUI/Features/RootView.swift`

- [ ] **Step 1:** Bind an alert to `lastError` at the root, so every path that sets it surfaces:

```swift
public struct RootView: View {
    @State private var app = AppState()
    @Environment(\.scenePhase) private var scenePhase

    public init() {}

    public var body: some View {
        Group {
            if app.league == nil { MainMenuView() } else { FranchiseShell() }
        }
        .environment(app)
        .environment(\.teamTheme, app.theme)
        .tint(app.theme.tint)
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { app.lastError != nil },
                set: { if !$0 { app.lastError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { app.lastError = nil }
        } message: {
            Text(app.lastError ?? "")
        }
        .onChange(of: scenePhase) { _, phase in
            // A backgrounded app can be killed at any moment; get the queued write down first.
            if phase != .active { Task { await app.flushSaves() } }
        }
    }
}
```

- [ ] **Step 2:** `LoadFranchiseView` stops dismissing unconditionally:

```swift
Button {
    app.load(id: save.id)
    if app.lastError == nil { dismiss() }
} label: { ... }
```

- [ ] **Step 3: Build** — `swift build`; expect success.
- [ ] **Step 4: Commit** — `fix: surface save and load failures instead of swallowing them`

---

### Task 5: Confirm before destroying a franchise

**Files:** Modify `Sources/ProFootballCoachUI/Features/RootView.swift`

- [ ] **Step 1:** Replace the bare `.onDelete` with a confirmation naming what is lost:

```swift
struct LoadFranchiseView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var pendingDeletion: SaveMeta?
    ...
    .onDelete { offsets in
        guard let index = offsets.first else { return }
        pendingDeletion = app.saves[index]
    }
    ...
    .confirmationDialog(
        "Delete this franchise?",
        isPresented: Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        ),
        titleVisibility: .visible
    ) {
        Button("Delete \(pendingDeletion?.name ?? "")", role: .destructive) {
            if let target = pendingDeletion { app.delete(id: target.id) }
            pendingDeletion = nil
        }
        Button("Keep", role: .cancel) { pendingDeletion = nil }
    } message: {
        if let target = pendingDeletion {
            Text("\(target.teamName) — \(String(target.year)), \(target.phaseLabel). "
                 + "This cannot be undone.")
        }
    }
}
```

- [ ] **Step 2: Build and commit** — `fix: confirm before a franchise is deleted for good`

---

### Task 6: Let the job-offer sheet be left

**Files:** Modify `Sources/ProFootballCoachUI/Features/CoachViews.swift`

- [ ] **Step 1:** The sheet must not be a trap. Keep `interactiveDismissDisabled` (the decision is
  real) but add an explicit way out that does not auto-reopen:

```swift
.navigationTitle("Job Offers")
.toolbar {
    ToolbarItem(placement: .cancellationAction) {
        Button("Decide Later") { dismiss() }
    }
}
```
And in `CoachView`, stop re-presenting on every change — only present when the count rises from
zero:

```swift
.onChange(of: offers.count) { previous, count in
    if previous == 0, count > 0 { showingOffers = true }
}
```

- [ ] **Step 2: Build and commit** — `fix: give the job-offer sheet a way out`

---

### Task 7: Declare the orientation policy

**Files:** Modify `App/project.yml`

- [ ] **Step 1:** iPhone only, portrait only. The arcade screen opts in per-view later.

```yaml
INFOPLIST_KEY_UISupportedInterfaceOrientations: "UIInterfaceOrientationPortrait"
TARGETED_DEVICE_FAMILY: "1"
```

- [ ] **Step 2:** Regenerate — `xcodegen generate --spec App/project.yml`
- [ ] **Step 3: Commit** — `fix: declare the app portrait and iPhone-only`

---

### Task 8: Resolve the dead arcade view

**Files:** Modify `Sources/ProFootballCoachUI/Features/SeasonHubView.swift`

- [ ] **Step 1:** `ArcadeGameView` is unreachable because the only `LiveGameView(` call site passes
  `arcade: false`. The mode exists and is built; wire it to the picker rather than delete it.

```swift
case .onField: LiveGameView(game: game, arcade: true)
```
(Add the case to the mode picker if absent; keep `.callPlays` and `.quickSim` as they are.)

- [ ] **Step 2: Build, run in the simulator, confirm the arcade screen appears.**
- [ ] **Step 3: Commit** — `fix: reach the on-field mode that was built but never wired up`

---

### Task 9: A Settings surface

**Files:** Create `Sources/ProFootballCoachUI/Features/SettingsView.swift`; Modify
`RootView.swift`, `CoachViews.swift`

- [ ] **Step 1:** Appearance is a stored preference the root applies.

```swift
import SwiftUI

/// Where the appearance and the confirmations live. Spec §20.
public enum Appearance: String, CaseIterable, Identifiable, Sendable {
    case system, light, dark
    public var id: String { rawValue }
    public var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

struct SettingsView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearance") private var appearance = Appearance.system

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $appearance) {
                        ForEach(Appearance.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    Toggle("Autosave", isOn: Binding(
                        get: { app.autosaveEnabled },
                        set: { app.autosaveEnabled = $0 }
                    ))
                } footer: {
                    Text("Your franchise is written after every change. Turning this off means "
                         + "only manual saves are kept.")
                }
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    Text("Every team, player and league in this game is fictional.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
```

- [ ] **Step 2:** Apply it in `RootView` — `.preferredColorScheme(appearance.colorScheme)` with a
  matching `@AppStorage("appearance")`.
- [ ] **Step 3:** Present it from the Coach tab's Franchise Management card and from the main menu
  gear.
- [ ] **Step 4: Build, run, toggle Light/Dark in the simulator.**
- [ ] **Step 5: Commit** — `feat: a settings surface with a working appearance control`

---

### Task 10: Almanac grounds, ink and rules

**Files:** Modify `Sources/ProFootballCoachUI/Theme/DesignSystem.swift`,
`Tests/SimTests/Suites/DesignSystemTests.swift`

**Verified values** (computed against the composited chip tint, both themes):

| Token | Light | Dark |
|---|---|---|
| page | `#F2EFE8` | `#000000` |
| card | `#FBF8F2` | `#1C1C1E` |
| ink | `#1A1714` | `#F5F2EC` |
| rule hairline | `#D9D3C7` | `#3A3A3C` |

`RatingTier.star` light moves `#1665C0` → `#155CB0`: on paper the old value measures 4.43:1 on its
own chip tint, and the new one 5.04:1. Every other tier and all dark values pass unchanged.

- [ ] **Step 1: Write the failing test** — extend the existing suite to the new grounds:

```swift
test("almanac grounds and ink clear AA") {
    let pairs: [(String, String, String)] = [
        ("ink on card", Almanac.inkLight, Almanac.cardLight),
        ("ink on page", Almanac.inkLight, Almanac.pageLight),
        ("ink on card dark", Almanac.inkDark, Almanac.cardDark),
        ("ink on page dark", Almanac.inkDark, Almanac.pageDark),
    ]
    for (name, fore, back) in pairs {
        let ratio = contrast(fore, back)
        expect(ratio >= 4.5, "\(name): \(String(format: "%.2f", ratio)):1")
    }
}

test("every rating tier clears AA on the almanac grounds") {
    for tier in RatingTier.allCases {
        for (theme, hex, card, page) in [
            ("light", tier.lightHex, Almanac.cardLight, Almanac.pageLight),
            ("dark", tier.darkHex, Almanac.cardDark, Almanac.pageDark),
        ] {
            for (surface, background) in [
                ("card", card), ("page", page), ("chip", composite(hex, over: card, alpha: 0.14)),
            ] {
                let ratio = contrast(hex, background)
                expect(ratio >= 4.5,
                       "\(tier) on \(theme) \(surface): \(String(format: "%.2f", ratio)):1")
            }
        }
    }
}
```

- [ ] **Step 2: Run to verify it fails** — "cannot find 'Almanac'".

- [ ] **Step 3: Implement**

```swift
/// The Almanac's grounds. Paper by day, night edition after dark.
///
/// Hexes rather than semantic system colours because paper is the identity: `systemGroupedBackground`
/// is neutral grey and cannot express it. Every value is verified against every surface it is drawn
/// on by `DesignSystemTests`, which is the trade that makes leaving the semantic set acceptable.
public enum Almanac {
    public static let pageLight = "#F2EFE8"
    public static let pageDark = "#000000"
    public static let cardLight = "#FBF8F2"
    public static let cardDark = "#1C1C1E"
    public static let inkLight = "#1A1714"
    public static let inkDark = "#F5F2EC"
    public static let ruleLight = "#D9D3C7"
    public static let ruleDark = "#3A3A3C"

    public static var page: Color { Color(light: pageLight, dark: pageDark) }
    public static var card: Color { Color(light: cardLight, dark: cardDark) }
    public static var ink: Color { Color(light: inkLight, dark: inkDark) }
    public static var rule: Color { Color(light: ruleLight, dark: ruleDark) }
}
```
And correct the star tier: `case .star: "#155CB0"`.

- [ ] **Step 4: Run tests** — expect PASS.
- [ ] **Step 5: Commit** — `feat: the almanac's grounds, verified against every surface`

---

### Task 11: Type roles

**Files:** Modify `Sources/ProFootballCoachUI/Theme/DesignSystem.swift`

- [ ] **Step 1:** Text styles only, so Dynamic Type is free.

```swift
/// The Almanac's voice. New York carries the record; SF carries the chrome; figures are tabular
/// so columns never dance.
public extension Font {
    /// Mastheads and edition plates.
    static var almanacDisplay: Font { .system(.largeTitle, design: .serif, weight: .bold) }
    /// Player names, record lines, chapter heads.
    static var almanacTitle: Font { .system(.title2, design: .serif, weight: .semibold) }
    /// Running record prose.
    static var almanacBody: Font { .system(.body, design: .serif) }
    /// Table heads and section chrome.
    static var almanacLabel: Font { .caption.weight(.semibold) }
    /// Any figure that changes.
    static var almanacFigure: Font { .system(.title3, design: .default).monospacedDigit() }
}
```

- [ ] **Step 2: Build and commit** — `feat: the almanac's typographic roles`

---

### Task 12: Rule, Stamp and Ledger row

**Files:** Modify `Sources/ProFootballCoachUI/Theme/DesignSystem.swift`

- [ ] **Step 1:** The printed rule replaces the card as the primary separator; the stamp replaces
  the chip as the metadata token; the ledger row is the almanac's list line.

```swift
/// A printed rule. The Almanac separates with rules, not with a card around everything.
public struct Rule: View {
    public enum Weight { case hair, heavy }
    let weight: Weight

    public init(_ weight: Weight = .hair) { self.weight = weight }

    public var body: some View {
        Rectangle()
            .fill(weight == .hair ? Almanac.rule : Almanac.ink)
            .frame(height: weight == .hair ? 0.5 : 1.5)
            .accessibilityHidden(true)
    }
}

/// A small printed mark for one piece of metadata. The Chip's successor: squared rather than
/// capsule, and used sparingly rather than on every token.
public struct Stamp: View {
    let text: String
    var color: Color

    public init(_ text: String, color: Color = Almanac.ink) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text.uppercased())
            .font(.almanacLabel)
            .tracking(0.6)
            .padding(.horizontal, Layout.tight)
            .padding(.vertical, 3)
            .foregroundStyle(color)
            .overlay(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(color.opacity(0.45), lineWidth: 0.8)
            )
    }
}

/// One line of the ledger: a label, a leader, and a figure that lines up with its neighbours.
public struct LedgerRow<Trailing: View>: View {
    let label: String
    let trailing: Trailing

    public init(_ label: String, @ViewBuilder trailing: () -> Trailing) {
        self.label = label
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(.almanacBody)
            Spacer(minLength: Layout.small)
            trailing.font(.almanacFigure)
        }
        .padding(.vertical, Layout.tight)
    }
}
```

- [ ] **Step 2: Build and commit** — `feat: rule, stamp and ledger row`

---

### Task 13: motionAware

**Files:** Modify `Sources/ProFootballCoachUI/Theme/DesignSystem.swift`

- [ ] **Step 1:** One modifier so Reduce Motion can never be forgotten again — the audit found
  zero checks in the whole layer.

```swift
private struct MotionAware<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}

public extension View {
    /// Animates unless the reader asked the system for less motion.
    func motionAware<V: Equatable>(_ animation: Animation = .snappy, value: V) -> some View {
        modifier(MotionAware(animation: animation, value: value))
    }
}
```

- [ ] **Step 2:** Replace the three existing raw animations:
  `ArcadeGameView.swift:123` → `.motionAware(.easeInOut(duration: 0.35), value: ballFraction)`;
  `NewFranchiseWizard.swift:255` → `.motionAware(.snappy, value: current)`;
  `TutorialView.swift:99` `withAnimation { page += 1 }` → guarded by the environment value.

- [ ] **Step 3: Build and commit** — `feat: honour reduce motion everywhere, by construction`

---

### Task 14: The new DESIGN.md

**Files:** Modify `DESIGN.md`

- [ ] **Step 1:** Replace the Coordinator's Clipboard with the Almanac: frontmatter tokens from
  Task 10–12, the seven earned edition surfaces, the rules-not-cards doctrine, the anti-references
  (including the retired Clipboard), and the known-drift list carried forward.
- [ ] **Step 2: Commit** — `docs: DESIGN.md becomes the Almanac`

---

## Phase gate

- `swift run -c release SimTests` green, including the new SaveQueue and grounds suites.
- App builds and runs on the simulator; Light/Dark toggled from Settings; a franchise deleted with
  confirmation; a load failure shows an alert.
- No visible redesign of any surface yet — that is Phase B onward.
