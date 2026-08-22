# FM-Touch Personnel Examples Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build connected, FM-density Roster and Player Profile SwiftUI examples for iPhone 17 Pro Max in landscape.

**Architecture:** Add immutable personnel projections beside the existing screen read models, then render them with two task-specific views that reuse Coach World tokens, route buttons, action styles and the blank-photo treatment. `RosterView` owns only selection, sorting and contextual sheet presentation; `PlayerProfileView` receives one profile projection and callbacks. The DEBUG root supplies fixed sample data and launch flags without exposing `GameState` to SwiftUI.

**Tech Stack:** Swift 5.10 language mode, SwiftUI, iOS 26, the existing `TestKit` executable suite, Xcode iOS Simulator, and zero third-party runtime dependencies.

## Global Constraints

- Primary proof device: iPhone 17 Pro Max simulator, landscape.
- Minimum OS: iOS 26.
- Preserve the existing 844 x 390 landscape floor as a regression check.
- Keep the app iPhone-only and landscape-only.
- Use Football Manager Touch only as a density and information-behaviour reference; copy no protected asset, identity, color system or trade dress.
- Keep `FootballSimCore` free of UI imports and keep `GameState` out of `ProFootballCoachUI`.
- Use semantic `Button` controls, 44-point action targets, Dynamic Type reflow, deterministic VoiceOver order and number-plus-color rating communication.
- Use the existing tokens and shared controls before adding code; add no package or runtime dependency.
- Preserve all pre-existing working-tree changes and stage only files changed by this plan.
- Before editing any existing symbol, run GitNexus `impact` in the upstream direction and report direct callers, affected processes and risk.
- After non-trivial code edits, run `rewrite-tournament` in no-argument post-edit mode; before completion run `confidence-review` and GitNexus `detect_changes` against `main`.

---

## File map

- Create `Sources/ProFootballCoachUI/PersonnelReadModels.swift`: immutable personnel projections, stable identities, deterministic roster sorting and DEBUG sample roster.
- Create `Sources/ProFootballCoachUI/RosterView.swift`: world strip, personnel routes, summary ribbon, sortable roster table, selected-player inspector and contextual dossier presentation.
- Create `Sources/ProFootballCoachUI/PlayerProfileView.swift`: person-led identity band, profile routes, attribute groups, evidence rail, position diagram and contextual actions.
- Modify `Sources/ProFootballCoachUI/RootView.swift`: DEBUG launch flags and navigation for `.roster` and `.playerProfile` only.
- Modify `Tests/SimTests/Suites/ContractTests.swift`: model, sorting, source-contract and sample-fixture assertions.
- Create four proof captures under `docs/proofs/personnel/`: Roster and Player Profile in light/default and dark/AX5 on iPhone 17 Pro Max landscape.

### Task 1: Personnel projections and deterministic sorting

**Files:**
- Create: `Sources/ProFootballCoachUI/PersonnelReadModels.swift`
- Modify: `Tests/SimTests/Suites/ContractTests.swift:652`

**Interfaces:**
- Consumes: `CoachWorldDataProvenance`, `CoachWorldReference`, `CoachWorldTeamReference`, `CoachWorldPersonReference`.
- Produces: `RosterReadModel`, `PlayerProfileReadModel`, `RosterSortField`, and `RosterSortDescriptor.sorted(_:) -> [RosterReadModel.PlayerRow]`.

- [ ] **Step 1: Add the failing projection and sorting contract**

Add these assertions inside the existing `#if DEBUG` contract test block:

```swift
test("personnel projections keep stable identities and deterministic sorting") {
    let roster = CoachWorldSampleData.roster
    expectEqual(roster.provenance, .sample)
    expectEqual(Set(roster.players.map(\.stableID)).count, roster.players.count)
    expect(roster.players.allSatisfy { $0.person.photo == nil })
    expect(roster.players.allSatisfy { player in
        player.overall >= 0 && player.overall <= 99
            && player.development >= 0 && player.development <= 99
            && player.condition >= 0 && player.condition <= 100
    })
    expect(roster.players.allSatisfy { player in
        player.profile.attributeGroups.count == 3
            && player.profile.attributeGroups.flatMap(\.attributes).allSatisfy {
                $0.value >= 0 && $0.value <= 99
            }
    })

    let descending = RosterSortDescriptor(field: .overall, isAscending: false)
        .sorted(roster.players)
    expectEqual(descending.map(\.overall), descending.map(\.overall).sorted(by: >))

    let ascending = RosterSortDescriptor(field: .name, isAscending: true)
        .sorted(roster.players)
    expectEqual(ascending.map { $0.person.name }, ascending.map { $0.person.name }.sorted())
}
```

- [ ] **Step 2: Run the contract test and verify the new types are missing**

Run:

```bash
swift run SimTests --core-contracts
```

Expected: compilation fails because `CoachWorldSampleData.roster`, `RosterSortDescriptor`, and the personnel projection types do not exist.

- [ ] **Step 3: Add the immutable projection types and sorter**

Create `Sources/ProFootballCoachUI/PersonnelReadModels.swift` with these exact public contracts:

```swift
public struct PlayerProfileReadModel: Identifiable, Sendable, Equatable {
    public struct Attribute: Identifiable, Sendable, Equatable {
        public let stableID: String
        public let label: String
        public let value: Int
        public let confidence: String
        public var id: String { stableID }

        public init(stableID: String, label: String, value: Int, confidence: String) {
            self.stableID = stableID
            self.label = label
            self.value = value
            self.confidence = confidence
        }
    }

    public struct AttributeGroup: Identifiable, Sendable, Equatable {
        public let stableID: String
        public let title: String
        public let attributes: [Attribute]
        public var id: String { stableID }

        public init(stableID: String, title: String, attributes: [Attribute]) {
            self.stableID = stableID
            self.title = title
            self.attributes = attributes
        }
    }

    public struct FormEntry: Identifiable, Sendable, Equatable {
        public let stableID: String
        public let opponent: String
        public let rating: Int
        public var id: String { stableID }

        public init(stableID: String, opponent: String, rating: Int) {
            self.stableID = stableID
            self.opponent = opponent
            self.rating = rating
        }
    }

    public let stableID: String
    public let person: CoachWorldPersonReference
    public let number: Int
    public let position: String
    public let academicYear: String
    public let hometown: String
    public let rosterRole: String
    public let availability: String
    public let condition: Int
    public let schemeFit: String
    public let staffSummary: String
    public let strengths: [String]
    public let concern: String
    public let attributeGroups: [AttributeGroup]
    public let recentForm: [FormEntry]
    public var id: String { stableID }

    public init(
        stableID: String,
        person: CoachWorldPersonReference,
        number: Int,
        position: String,
        academicYear: String,
        hometown: String,
        rosterRole: String,
        availability: String,
        condition: Int,
        schemeFit: String,
        staffSummary: String,
        strengths: [String],
        concern: String,
        attributeGroups: [AttributeGroup],
        recentForm: [FormEntry]
    ) {
        self.stableID = stableID
        self.person = person
        self.number = number
        self.position = position
        self.academicYear = academicYear
        self.hometown = hometown
        self.rosterRole = rosterRole
        self.availability = availability
        self.condition = condition
        self.schemeFit = schemeFit
        self.staffSummary = staffSummary
        self.strengths = strengths
        self.concern = concern
        self.attributeGroups = attributeGroups
        self.recentForm = recentForm
    }
}

public struct RosterReadModel: Sendable, Equatable {
    public struct PlayerRow: Identifiable, Sendable, Equatable {
        public let stableID: String
        public let person: CoachWorldPersonReference
        public let number: Int
        public let position: String
        public let academicYear: String
        public let rosterRole: String
        public let overall: Int
        public let development: Int
        public let schemeFit: String
        public let condition: Int
        public let availability: String
        public let profile: PlayerProfileReadModel
        public var id: String { stableID }

        public init(
            stableID: String,
            person: CoachWorldPersonReference,
            number: Int,
            position: String,
            academicYear: String,
            rosterRole: String,
            overall: Int,
            development: Int,
            schemeFit: String,
            condition: Int,
            availability: String,
            profile: PlayerProfileReadModel
        ) {
            self.stableID = stableID
            self.person = person
            self.number = number
            self.position = position
            self.academicYear = academicYear
            self.rosterRole = rosterRole
            self.overall = overall
            self.development = development
            self.schemeFit = schemeFit
            self.condition = condition
            self.availability = availability
            self.profile = profile
        }
    }

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let world: CoachWorldReference
    public let team: CoachWorldTeamReference
    public let coach: CoachWorldPersonReference
    public let seasonLabel: String
    public let weekLabel: String
    public let recordLabel: String
    public let rankLabel: String?
    public let rosterLimit: Int
    public let injuryCount: Int
    public let openNeedCount: Int
    public let players: [PlayerRow]

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        world: CoachWorldReference,
        team: CoachWorldTeamReference,
        coach: CoachWorldPersonReference,
        seasonLabel: String,
        weekLabel: String,
        recordLabel: String,
        rankLabel: String?,
        rosterLimit: Int,
        injuryCount: Int,
        openNeedCount: Int,
        players: [PlayerRow]
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.world = world
        self.team = team
        self.coach = coach
        self.seasonLabel = seasonLabel
        self.weekLabel = weekLabel
        self.recordLabel = recordLabel
        self.rankLabel = rankLabel
        self.rosterLimit = rosterLimit
        self.injuryCount = injuryCount
        self.openNeedCount = openNeedCount
        self.players = players
    }
}

public enum RosterSortField: String, CaseIterable, Sendable, Equatable {
    case number, name, position, overall, development, condition
}

public struct RosterSortDescriptor: Sendable, Equatable {
    public let field: RosterSortField
    public let isAscending: Bool

    public init(field: RosterSortField, isAscending: Bool) {
        self.field = field
        self.isAscending = isAscending
    }

    public func sorted(_ players: [RosterReadModel.PlayerRow]) -> [RosterReadModel.PlayerRow] {
        players.sorted { lhs, rhs in
            switch field {
            case .number:
                if lhs.number == rhs.number { return lhs.stableID < rhs.stableID }
                return isAscending ? lhs.number < rhs.number : lhs.number > rhs.number
            case .name:
                if lhs.person.name == rhs.person.name { return lhs.stableID < rhs.stableID }
                return isAscending
                    ? lhs.person.name < rhs.person.name
                    : lhs.person.name > rhs.person.name
            case .position:
                if lhs.position == rhs.position { return lhs.stableID < rhs.stableID }
                return isAscending ? lhs.position < rhs.position : lhs.position > rhs.position
            case .overall:
                if lhs.overall == rhs.overall { return lhs.stableID < rhs.stableID }
                return isAscending ? lhs.overall < rhs.overall : lhs.overall > rhs.overall
            case .development:
                if lhs.development == rhs.development { return lhs.stableID < rhs.stableID }
                return isAscending
                    ? lhs.development < rhs.development
                    : lhs.development > rhs.development
            case .condition:
                if lhs.condition == rhs.condition { return lhs.stableID < rhs.stableID }
                return isAscending ? lhs.condition < rhs.condition : lhs.condition > rhs.condition
            }
        }
    }
}
```

- [ ] **Step 4: Add fixed DEBUG sample data**

Add `public extension CoachWorldSampleData` in the same file. Define `static let roster` with seven fictional rows covering QB, RB, WR, OT, EDGE, MLB and CB. Each row must have a unique stable ID, a nil photo, three attribute groups named `Athletic`, `Technical`, and `Mental`, three recent-form entries, ratings in `0...99`, condition in `0...100`, and exact strings for strengths, concern, staff summary, scheme fit and availability. Use a private local `makePlayer(...)` helper inside the `static let roster` closure so the sample stays compact and deterministic.

```swift
#if DEBUG
public extension CoachWorldSampleData {
    static let roster: RosterReadModel = {
        func makePlayer(
            id: String,
            number: Int,
            name: String,
            position: String,
            year: String,
            role: String,
            overall: Int,
            development: Int,
            fit: String,
            condition: Int,
            availability: String,
            hometown: String,
            strengths: [String],
            concern: String,
            summary: String,
            athletic: [Int],
            technical: [Int],
            mental: [Int],
            form: [Int]
        ) -> RosterReadModel.PlayerRow {
            let person = CoachWorldPersonReference(stableID: "\(id)-person", name: name, role: position)
            func group(_ key: String, _ title: String, _ labels: [String], _ values: [Int])
                -> PlayerProfileReadModel.AttributeGroup {
                .init(
                    stableID: "\(id)-\(key)",
                    title: title,
                    attributes: zip(labels, values).enumerated().map { index, pair in
                        .init(
                            stableID: "\(id)-\(key)-\(index)",
                            label: pair.0,
                            value: pair.1,
                            confidence: "Known"
                        )
                    }
                )
            }
            let profile = PlayerProfileReadModel(
                stableID: "\(id)-profile",
                person: person,
                number: number,
                position: position,
                academicYear: year,
                hometown: hometown,
                rosterRole: role,
                availability: availability,
                condition: condition,
                schemeFit: fit,
                staffSummary: summary,
                strengths: strengths,
                concern: concern,
                attributeGroups: [
                    group("athletic", "Athletic", ["Speed", "Strength", "Stamina"], athletic),
                    group("technical", "Technical", ["Technique", "Position Skill", "Ball Security"], technical),
                    group("mental", "Mental", ["Decisions", "Awareness", "Leadership"], mental),
                ],
                recentForm: zip(["SOU", "WST", "MET"], form).enumerated().map { index, pair in
                    .init(stableID: "\(id)-form-\(index)", opponent: pair.0, rating: pair.1)
                }
            )
            return .init(
                stableID: id,
                person: person,
                number: number,
                position: position,
                academicYear: year,
                rosterRole: role,
                overall: overall,
                development: development,
                schemeFit: fit,
                condition: condition,
                availability: availability,
                profile: profile
            )
        }

        return RosterReadModel(
            snapshotID: "sample-roster-snapshot",
            provenance: .sample,
            world: world,
            team: homeTeam,
            coach: headCoach,
            seasonLabel: "2027 season",
            weekLabel: "Week 9",
            recordLabel: "6–2",
            rankLabel: "#19",
            rosterLimit: 85,
            injuryCount: 2,
            openNeedCount: 3,
            players: [
                makePlayer(id: "sample-roster-bishop", number: 12, name: "Andre Bishop", position: "QB", year: "SR", role: "Captain · Starter", overall: 91, development: 78, fit: "Elite", condition: 96, availability: "Available", hometown: "Columbus, Ohio", strengths: ["Deep accuracy", "Pressure control"], concern: "Late movement can hold the ball too long", summary: "Commands the offense and protects high-leverage downs.", athletic: [82, 76, 88], technical: [92, 94, 89], mental: [91, 93, 90], form: [88, 91, 86]),
                makePlayer(id: "sample-roster-ward", number: 24, name: "Jalen Ward", position: "RB", year: "JR", role: "Starter", overall: 88, development: 86, fit: "Strong", condition: 91, availability: "Available", hometown: "Macon, Georgia", strengths: ["Contact balance", "Cut timing"], concern: "Pass protection remains inconsistent", summary: "Creates efficient early downs without wasting carries.", athletic: [91, 87, 90], technical: [86, 90, 84], mental: [85, 87, 79], form: [90, 84, 89]),
                makePlayer(id: "sample-roster-okafor", number: 6, name: "Miles Okafor", position: "WR", year: "SO", role: "Rotation", overall: 84, development: 92, fit: "Strong", condition: 100, availability: "Available", hometown: "Baltimore, Maryland", strengths: ["Release burst", "Open-field acceleration"], concern: "Boundary route detail is unfinished", summary: "The highest-upside receiver on the roster.", athletic: [94, 72, 86], technical: [83, 85, 80], mental: [79, 82, 68], form: [82, 87, 80]),
                makePlayer(id: "sample-roster-alvarez", number: 72, name: "Tomas Alvarez", position: "OT", year: "SR", role: "Starter", overall: 87, development: 74, fit: "Elite", condition: 88, availability: "Limited", hometown: "El Paso, Texas", strengths: ["Pass anchor", "Length"], concern: "Ankle limits lateral recovery", summary: "Reliable blind-side protection when healthy.", athletic: [76, 93, 82], technical: [90, 91, 88], mental: [86, 89, 84], form: [85, 88, 83]),
                makePlayer(id: "sample-roster-webb", number: 87, name: "Darius Webb", position: "EDGE", year: "JR", role: "Starter", overall: 89, development: 88, fit: "Elite", condition: 94, availability: "Available", hometown: "Gary, Indiana", strengths: ["First step", "Counter timing"], concern: "Can lose run leverage chasing pressure", summary: "Changes passing downs and forces protection help.", athletic: [93, 86, 89], technical: [88, 92, 81], mental: [84, 86, 78], form: [92, 89, 90]),
                makePlayer(id: "sample-roster-reed", number: 55, name: "Marcus Reed", position: "MLB", year: "SR", role: "Captain · Starter", overall: 90, development: 76, fit: "Strong", condition: 97, availability: "Available", hometown: "Nashville, Tennessee", strengths: ["Run fits", "Communication"], concern: "Man coverage range is ordinary", summary: "Sets the front and prevents alignment errors.", athletic: [84, 89, 91], technical: [87, 90, 82], mental: [94, 95, 93], form: [89, 90, 91]),
                makePlayer(id: "sample-roster-brooks", number: 9, name: "Elijah Brooks", position: "CB", year: "SO", role: "Nickel", overall: 82, development: 94, fit: "Good", condition: 99, availability: "Available", hometown: "Newark, New Jersey", strengths: ["Press timing", "Recovery speed"], concern: "Route recognition varies snap to snap", summary: "Already playable inside with outside-corner upside.", athletic: [95, 70, 87], technical: [82, 84, 79], mental: [76, 78, 71], form: [81, 85, 83]),
            ]
        )
    }()
}
#endif
```

- [ ] **Step 5: Run the contract suite**

Run:

```bash
swift run SimTests --core-contracts
```

Expected: `All tests passed` and no compiler warnings from `PersonnelReadModels.swift`.

- [ ] **Step 6: Commit Task 1**

Stage only the two Task 1 files and commit:

```bash
git add Sources/ProFootballCoachUI/PersonnelReadModels.swift Tests/SimTests/Suites/ContractTests.swift
git commit -m "feat: add personnel screen projections"
```

### Task 2: Dense Roster workspace

**Files:**
- Create: `Sources/ProFootballCoachUI/RosterView.swift`
- Modify: `Tests/SimTests/Suites/ContractTests.swift:665`

**Interfaces:**
- Consumes: `RosterReadModel`, `RosterSortDescriptor`, `CoachWorldRouteButton`, `CoachWorldActionButtonStyle`, `CoachWorldBlankPhotoPlate`, `CoachWorldTokens`.
- Produces: `public struct RosterView` with callbacks for continue, world navigation and opening the selected profile.

- [ ] **Step 1: Add the failing source contract**

Extend the production UI source-contract test with:

```swift
let roster = uiFiles.first { $0.path.hasSuffix("/RosterView.swift") }?.text ?? ""
expect(roster.contains("public struct RosterView"))
expect(roster.contains("let model: RosterReadModel"))
expect(roster.contains("Button("))
expect(!roster.contains("onTapGesture"))
expect(roster.contains("monospacedDigit"))
expect(roster.contains("accessibilitySortPriority"))
expect(roster.contains("dynamicTypeSize.isAccessibilitySize"))
expect(roster.contains("CoachWorldRouteButton"))
expect(roster.contains("CoachWorldActionButtonStyle"))
```

- [ ] **Step 2: Run the contract test and verify the screen is missing**

Run `swift run SimTests --core-contracts`.

Expected: failure at `RosterView.swift must expose the production roster screen` after adding an explicit message to the first assertion.

- [ ] **Step 3: Implement `RosterView`**

Create `Sources/ProFootballCoachUI/RosterView.swift` with this public interface and owned state:

```swift
import SwiftUI

public struct RosterView: View {
    public let model: RosterReadModel
    public let statusMessage: String?
    public let onContinue: () -> Void
    public let onNavigate: (CoachWorldScreenID) -> Void
    public let onOpenProfile: (PlayerProfileReadModel) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var workspaceGap = CoachWorldTokens.Space.xs
    @State private var selectedPlayerID: String
    @State private var sort = RosterSortDescriptor(field: .overall, isAscending: false)

    public init(
        model: RosterReadModel,
        statusMessage: String? = nil,
        onContinue: @escaping () -> Void,
        onNavigate: @escaping (CoachWorldScreenID) -> Void,
        onOpenProfile: @escaping (PlayerProfileReadModel) -> Void
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onContinue = onContinue
        self.onNavigate = onNavigate
        self.onOpenProfile = onOpenProfile
        _selectedPlayerID = State(initialValue: model.players.first?.stableID ?? "")
    }
}
```

Implement the body with these exact branches:

```swift
public var body: some View {
    Group {
        if dynamicTypeSize.isAccessibilitySize {
            accessibleLayout
        } else {
            VStack(spacing: .zero) {
                worldStrip
                personnelRoutes
                standardLayout
            }
        }
    }
    .foregroundStyle(palette.contentPrimary.color)
    .background(palette.page.color.ignoresSafeArea())
    .onChange(of: model.players.map(\.stableID), initial: true) { _, stableIDs in
        if !stableIDs.contains(selectedPlayerID) {
            selectedPlayerID = stableIDs.first ?? ""
        }
    }
}
```

The remaining private views must implement the approved composition with no new public abstraction:

- `worldStrip`: team and coach context, Office/Team/Recruit/League/Career routes, and Continue.
- `personnelRoutes`: Roster selected; Depth, Development and Staff are disabled semantic buttons.
- `summaryRibbon`: `players.count/rosterLimit`, injury count, open needs and class balance.
- `standardLayout`: use `GeometryReader`; table width is `availableWidth * 0.64`, inspector receives the rest.
- `comparisonTable`: a header plus `ScrollView`/`LazyVStack(spacing: .zero)` over `visiblePlayers` using stable `PlayerRow.id`.
- `sortButton`: Number, Player, Position, OVR, DEV and COND headings toggle the matching `RosterSortField`; repeat activation reverses direction.
- `rosterRow`: a 44-point `Button`; visible content is 28 points tall; selected state is reinforced by leading stroke and `isSelected` accessibility trait.
- `ratingCell`: show the exact number with `.monospacedDigit()` and use positive for 85+, warning for 70–84, negative below 70.
- `inspector`: blank photo, identity, role, strengths, concern, availability and `Open dossier` action that calls `onOpenProfile(selected.profile)`.
- `accessibleLayout`: one `ScrollView` ordered as summary, roster rows, selected inspector, world routes and Continue.
- Empty roster: one `ContentUnavailableView("No players on the roster", systemImage: "person.3", description: Text("Players appear here when a career roster is available."))`.

Every row must expose one combined accessibility label in this order: number, name, position, year, role, overall, development, fit, condition, availability. Sort buttons must expose `accessibilityValue("Ascending")` or `accessibilityValue("Descending")` for the active field.

- [ ] **Step 4: Run build and contracts**

Run:

```bash
swift build
swift run SimTests --core-contracts
```

Expected: both commands succeed and `All tests passed` appears.

- [ ] **Step 5: Commit Task 2**

```bash
git add Sources/ProFootballCoachUI/RosterView.swift Tests/SimTests/Suites/ContractTests.swift
git commit -m "feat: add dense roster workspace"
```

### Task 3: Player Profile dossier

**Files:**
- Create: `Sources/ProFootballCoachUI/PlayerProfileView.swift`
- Modify: `Sources/ProFootballCoachUI/RosterView.swift`
- Modify: `Tests/SimTests/Suites/ContractTests.swift:665`

**Interfaces:**
- Consumes: `PlayerProfileReadModel`, `CoachWorldActionButtonStyle`, `CoachWorldBlankPhotoPlate`, and `CoachWorldTokens`.
- Produces: `public struct PlayerProfileView` presented through `RosterView.presentedProfile`.

- [ ] **Step 1: Add the failing profile source contract**

Add:

```swift
let profile = uiFiles.first { $0.path.hasSuffix("/PlayerProfileView.swift") }?.text ?? ""
expect(profile.contains("public struct PlayerProfileView"))
expect(profile.contains("let model: PlayerProfileReadModel"))
expect(profile.contains("Button("))
expect(!profile.contains("onTapGesture"))
expect(profile.contains("monospacedDigit"))
expect(profile.contains("accessibilitySortPriority"))
expect(profile.contains("dynamicTypeSize.isAccessibilitySize"))
expect(profile.contains("CoachWorldBlankPhotoPlate"))
expect(profile.contains("model.attributeGroups"))
```

- [ ] **Step 2: Verify the contract fails**

Run `swift run SimTests --core-contracts`.

Expected: failure naming the absent `PlayerProfileView`.

- [ ] **Step 3: Implement the dossier**

Create this public shell:

```swift
import SwiftUI

public struct PlayerProfileView: View {
    public let model: PlayerProfileReadModel
    public let onClose: () -> Void
    public let onInspectDevelopment: (String) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var activeRoute = ProfileRoute.overview

    public init(
        model: PlayerProfileReadModel,
        onClose: @escaping () -> Void,
        onInspectDevelopment: @escaping (String) -> Void
    ) {
        self.model = model
        self.onClose = onClose
        self.onInspectDevelopment = onInspectDevelopment
    }
}

private enum ProfileRoute: String, CaseIterable {
    case overview = "Overview"
    case attributes = "Attributes"
    case development = "Development"
    case history = "History"
}
```

Implement the body as:

```swift
public var body: some View {
    Group {
        if dynamicTypeSize.isAccessibilitySize {
            ScrollView { accessibleLayout }
        } else {
            VStack(spacing: .zero) {
                identityBand
                routeBar
                GeometryReader { proxy in
                    HStack(spacing: ProfileMetric.workspaceGap) {
                        attributeBody.frame(width: proxy.size.width * ProfileMetric.attributeFraction)
                        evidenceRail.frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, CoachWorldTokens.Space.xs)
                }
                actionArea
            }
        }
    }
    .foregroundStyle(palette.contentPrimary.color)
    .background(palette.page.color.ignoresSafeArea())
}
```

Use `ProfileMetric.attributeFraction = 0.68`. Implement:

- `identityBand`: 64 x 72 blank photo, number, name, position/year, hometown, role, availability and condition.
- `routeBar`: Overview selected; the other three route buttons are visible and disabled in this example.
- `attributeBody`: `HStack` of the three groups at default type size; each group contains aligned label/value rows. Values use monospaced digits and the same 85+/70–84/below-70 states as Roster.
- `evidenceRail`: compact position diagram, scheme fit, recent form, staff summary, strengths and concern.
- `positionDiagram`: a field-shaped `ZStack` with semantic yard-line decoration and one labeled marker derived from `model.position`; hide decorative lines from accessibility.
- `actionArea`: primary `Review development` button calls `onInspectDevelopment(model.stableID)`; secondary `Close` calls `onClose`.
- `accessibleLayout`: identity, attributes, evidence and actions in one deterministic vertical order.

Each attribute row's accessibility label must be `"<label>, <value>, <confidence> confidence"`. Recent form must be one chronological accessibility element. Long identity strings may truncate visually but must remain complete in accessibility labels.

Replace Roster's temporary `onOpenProfile` callback with its final contextual-presentation state:

```swift
public let onInspectDevelopment: (String) -> Void
@State private var presentedProfile: PlayerProfileReadModel?

public init(
    model: RosterReadModel,
    statusMessage: String? = nil,
    onContinue: @escaping () -> Void,
    onNavigate: @escaping (CoachWorldScreenID) -> Void,
    onInspectDevelopment: @escaping (String) -> Void
) {
    self.model = model
    self.statusMessage = statusMessage
    self.onContinue = onContinue
    self.onNavigate = onNavigate
    self.onInspectDevelopment = onInspectDevelopment
    _selectedPlayerID = State(initialValue: model.players.first?.stableID ?? "")
}
```

Change the inspector action to `presentedProfile = selected.profile`, then attach:

```swift
.sheet(item: $presentedProfile) { profile in
    PlayerProfileView(
        model: profile,
        onClose: { presentedProfile = nil },
        onInspectDevelopment: onInspectDevelopment
    )
}
```

- [ ] **Step 4: Verify sheet state restoration and contracts**

Add one source assertion proving Roster owns presentation state:

```swift
expect(roster.contains(".sheet(item: $presentedProfile)"),
       "the dossier must preserve roster selection and sort state")
```

Run:

```bash
swift build
swift run SimTests --core-contracts
```

Expected: both succeed and `All tests passed` appears.

- [ ] **Step 5: Commit Task 3**

```bash
git add Sources/ProFootballCoachUI/PlayerProfileView.swift Sources/ProFootballCoachUI/RosterView.swift Tests/SimTests/Suites/ContractTests.swift
git commit -m "feat: add player profile dossier"
```

### Task 4: DEBUG routing and direct proof entry

**Files:**
- Modify: `Sources/ProFootballCoachUI/RootView.swift:18-140`
- Modify: `Tests/SimTests/Suites/ContractTests.swift:700`

**Interfaces:**
- Consumes: `CoachWorldSampleData.roster`, `RosterView`, `PlayerProfileView`, `.roster`, `.playerProfile`.
- Produces: `--roster`, `--player-profile`, `PROOF_SCREEN=roster`, and `PROOF_SCREEN=player` DEBUG entry paths.

- [ ] **Step 1: Run required blast-radius analysis**

Run:

```text
impact({repo: "Pro-Football-Coach", target: "DebugCoachingHQRoot", direction: "upstream"})
impact({repo: "Pro-Football-Coach", target: "navigate", file_path: "Sources/ProFootballCoachUI/RootView.swift", direction: "upstream"})
```

Report risk, direct callers and affected processes before editing. Stop for user confirmation if either result is HIGH or CRITICAL.

- [ ] **Step 2: Add the failing root contract**

Extend the existing root assertions:

```swift
expect(root.contains("CoachWorldSampleData.roster"))
expect(root.contains("--roster") && root.contains("PROOF_SCREEN") && root.contains("roster"))
expect(root.contains("--player-profile") && root.contains("player"))
expect(root.contains("RosterView(") && root.contains("PlayerProfileView("))
```

Run `swift run SimTests --core-contracts` and expect those assertions to fail.

- [ ] **Step 3: Wire the two DEBUG destinations**

Add:

```swift
private let roster = CoachWorldSampleData.roster
```

In `init()`, resolve flags before assigning `_currentScreen`:

```swift
let proofScreen = ProcessInfo.processInfo.environment["PROOF_SCREEN"]
let opensPlayer = CommandLine.arguments.contains("--player-profile") || proofScreen == "player"
let opensRoster = CommandLine.arguments.contains("--roster") || proofScreen == "roster"
_currentScreen = State(
    initialValue: opensPlayer ? .playerProfile
        : (opensRoster ? .roster
            : (opensMatch ? .matchDay
                : (opensRecruiting ? .recruitingBoard : .coachingHQ)))
)
```

Add these branches before Recruiting Board:

```swift
} else if currentScreen == .playerProfile, let profile = roster.players.first?.profile {
    PlayerProfileView(
        model: profile,
        onClose: { currentScreen = .roster },
        onInspectDevelopment: inspectDevelopment
    )
} else if currentScreen == .roster {
    RosterView(
        model: roster,
        statusMessage: statusMessage,
        onContinue: { statusMessage = "No later personnel event is available yet" },
        onNavigate: navigate,
        onInspectDevelopment: inspectDevelopment
    )
```

Add:

```swift
private func inspectDevelopment(_ playerID: String) {
    guard let player = roster.players.first(where: { $0.stableID == playerID }) else {
        statusMessage = "That player profile is no longer available"
        return
    }
    statusMessage = "Development evidence opened for \(player.person.name) · no changes made"
}
```

Allow `.roster` in `navigate`; keep `.playerProfile` reachable only from the direct DEBUG flag or Roster's sheet so world navigation stays shallow.

- [ ] **Step 4: Run package verification**

Run:

```bash
swift build
swift run SimTests --core-contracts
./scripts/verify.sh
```

Expected: build succeeds, contract suite prints `All tests passed`, and the repository verification script exits 0.

- [ ] **Step 5: Commit Task 4**

```bash
git add Sources/ProFootballCoachUI/RootView.swift Tests/SimTests/Suites/ContractTests.swift
git commit -m "feat: wire personnel proof screens"
```

### Task 5: Simulator, accessibility and visual proof

**Files:**
- Create: `docs/proofs/personnel/roster-light-default-iphone17promax.png`
- Create: `docs/proofs/personnel/roster-dark-ax5-iphone17promax.png`
- Create: `docs/proofs/personnel/player-light-default-iphone17promax.png`
- Create: `docs/proofs/personnel/player-dark-ax5-iphone17promax.png`

**Interfaces:**
- Consumes: the launchable app target, DEBUG flags from Task 4, the project-local accessibility matrix, `ios-simulator-skill`, `swiftui-expert-skill`, and `ios-accessibility`.
- Produces: four owner-viewable screen proofs plus semantic-tree and interaction verification notes.

- [ ] **Step 1: Load and follow implementation skills**

Read the complete current instructions for `swiftui-expert-skill`, `ios-accessibility`, `ios-simulator-skill`, and `verify-ios-accessibility-matrix`. Consult SwiftUI references for latest APIs, layout, lists, sheets/navigation, text and accessibility before changing code in response to simulator findings.

- [ ] **Step 2: Build and launch on the exact device**

Use the simulator skill to select `iPhone 17 Pro Max`, boot only that resolved simulator if needed, generate the Xcode project from `App/project.yml`, build the `ProFootballCoach` scheme, install it, and launch in landscape with `--roster`.

Expected: the app opens Roster with seven stable sample players, the world strip visible, and the first row selected.

- [ ] **Step 3: Verify interactions and semantics**

On Roster, activate OVR twice and verify descending then ascending announcements; select a different player; open and dismiss the dossier; verify selection and sorting remain unchanged. Inspect the accessibility tree for complete row labels and named sort values. On Player Profile, verify the identity band, all three attribute groups, recent form, Review development and Close are reachable in deterministic order.

- [ ] **Step 4: Capture the four screenshots**

Use the simulator skill to capture Roster and Player Profile at light/default and dark/AX5 in landscape. Save them to the four exact paths listed for this task. AX5 may reflow vertically and is not judged as the density reference.

- [ ] **Step 5: Run the local accessibility matrix**

Run the `verify-ios-accessibility-matrix` workflow for `.roster` and `.playerProfile`. Verify light/dark, default/AX5, VoiceOver ordering, Differentiate Without Color, Increase Contrast and Reduce Motion states that the skill can automate. Record physical-device-only VoiceOver, Voice Control, Switch Control, haptic and audio checks as owner verification, not agent-pass claims.

- [ ] **Step 6: Run required post-edit reviews**

Run `rewrite-tournament` in no-argument post-edit mode on changed functions. Then run `confidence-review`: enumerate uncertain layout, sorting, state-restoration, accessibility and simulator assumptions; investigate each to root cause; patch confirmed bugs; rerun the smallest failing check after every patch.

- [ ] **Step 7: Run final verification and change detection**

Run:

```bash
swift build
swift run SimTests --core-contracts
./scripts/verify.sh
```

Then run:

```text
detect_changes({repo: "Pro-Football-Coach", scope: "compare", base_ref: "main", worktree: "/Users/ericguei/Documents/Pro-Football-Coach"})
```

Expected: only the planned personnel read models, screens, DEBUG routing, contract assertions and proof images are attributable to this implementation. Existing professional-management and other UI work remains unstaged.

- [ ] **Step 8: Commit the verified proof artifacts**

Stage only the four new images plus any source fixes made during this task, then commit:

```bash
git add docs/proofs/personnel/roster-light-default-iphone17promax.png docs/proofs/personnel/roster-dark-ax5-iphone17promax.png docs/proofs/personnel/player-light-default-iphone17promax.png docs/proofs/personnel/player-dark-ax5-iphone17promax.png
git commit -m "test: capture personnel screen proofs"
```

Do not push unless the user asks.
