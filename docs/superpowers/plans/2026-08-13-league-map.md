# League Map (screen family 41) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the production League Map screen so the shipped navigation bar's `League` route lands on a truthful screen instead of "League Map is not available yet".

**Architecture:** Three layers, matching the boundary `Package.swift` already enforces. A pure-data
`LeagueMapReadModel` in `ProFootballCoachUI` (no imports, `String` identifiers); a
`CoachWorldReadModelProvider.leagueMap(from:)` in `CoachWorldApp` that is the only code allowed to
see both `GameState` and the read model; and `LeagueMapView` in `ProFootballCoachUI`, which names no
engine type. The map is a `ZStack` of positioned `Button`s over a `GeometryReader`, **not** a
`Canvas` — hit-testing and VoiceOver come free that way, and canon reserves `Canvas` for the match
view, not for every drawing. A single small `Canvas` under the markers draws rivalry links for the
selected place only, and is `accessibilityHidden` because every fact it depicts is also stated in
the detail rail.

**Tech Stack:** Swift 5 language mode, SwiftUI, iOS 26, landscape-only iPhone. No third-party
dependencies. Tests run through the hand-rolled harness in `Tests/SimTests/TestKit.swift`.

## Global Constraints

Every task's requirements implicitly include this section. Values are copied verbatim from canon.

- **Landscape-only iPhone.** Promise window `852 x 393` through `956 x 440`; **install floor `844 x 390`** (`04` §7). Every surface renders un-clipped at the install floor.
- **The engine/UI boundary.** `FootballSimCore` imports no UI. A file that imports SwiftUI/UIKit/AppKit may not contain the bare token `GameState` (`ContractTests.swift:504-549`) — this holds **file by file** inside `CoachWorldApp`, not just per target. A provider file therefore must not import SwiftUI.
- **`04` §4.4 truthfulness.** A field the engine cannot back ships empty or `nil`, with a comment naming the register gap that would fill it. Never an invented value.
- **No design-token literals in a view.** `ContractTests.swift:641-655` fails a bare number after `.padding(`, `.cornerRadius(`, `spacing:`, `cornerRadius:`, `size:`, `radius:`, `lineWidth:`. Use `CoachWorldTokens.Space.{xxs,xs,sm,md,lg,xl}` = `4,6,8,12,16,20`, `CoachWorldTokens.Shape.{hairline,controlRadius,rowRadius,surfaceRadius,minimumTarget,broadcastRadius}` = `1,8,8,10,44,0`. Non-token geometry goes in a `private enum LeagueMapMetric` at the bottom of the view file.
- **No colour outside the palette.** Adding a `0xRRGGBB` to `DesignTokens.swift` requires writing it into `04` §6.1 first (`DesignContractTests.swift:122-141`). **This plan adds no token.**
- **Symbol register (`04` §6.6).** Only registered symbols may be drawn. This screen uses **none**; its empty state uses `list.number`, which is a registered empty-state mark.
- **AX5 contract.** `AccessibilityReflowTests` resolves `leagueMap` -> `LeagueMapView.swift` by convention, so the file enters the contract the day it appears. It **must** contain the literal substrings `dynamicTypeSize.isAccessibilitySize` and `accessibilitySortPriority` or the suite goes red.
- **VoiceOver sort priorities**, matching the five shipped screens: dominant object `100`, evidence `80`, world strip `50`, local sub-navigation `40`.
- **No emoji** in code, copy, commits or docs. Player-facing copy is short and plain.
- **Legal guardrail.** Every place, programme and venue name is generated. This screen introduces no authored name.

---

## What the engine actually holds, and what it does not

Written down here because every field below is traceable to it, and because two of the absences are
the reason this plan builds one screen rather than two.

**The join is by identifier, never by name.** `TeamIdentity.homeCityID: UUID`
(`Sources/FootballSimCore/Generation/LeagueGenerator.swift:101`) is authoritative;
`Programme.cityName` is a display string. The engine itself joins this way
(`CollegeRecruitingSystem.swift:20-21`). A name join would be sound at today's scale (570 distinct
generated place names against 166 cities) but collapses silently if `GameMap.swift:93-97`'s
with-replacement fallback ever fires. Use `identities[id]?.homeCityID` -> `map.city(_:)`.

**Available and used by this screen:**

| Datum | Source |
|---|---|
| 166 distinct cities, `x` in `0...1000`, `y` in `0...700`, `marketSize: Rating` | `GameMap.swift:9-33,52-53` |
| 8 regions, `name`, `talentDensity: Rating` | `GameMap.swift:37-48` |
| One city per member, never shared, college indices 0-133 then pro 134-165 | `LeagueGenerator.swift:120-121,142-143,189-190` |
| `ColourPair.primary/.secondary/.onTeam`, all generated, `onTeam` already the legible ink over `primary` | `Colour.swift:104-126` |
| `Rivalry.sideA/.sideB/.origin/.intensity`, `RivalrySeeder.strongest(for:among:)` bounded to 8 | `Rivalry.swift:8-28,157-167` |
| Conference name and membership, both tiers | `League.swift:26-48,109-111` |
| `Programme.prestige`, `venueName` | `Programme.swift:19`, `LeagueGenerator.swift:99` |

**Deliberately absent from this screen, each for a stated reason:**

- **No reach radius.** `Programme.recruitingReach` is dead data — a full source scan finds no consumer outside its own initialiser and the D6 archetype falsifier. Drawing a circle from it invents a grid-unit mapping the engine does not have.
- **No distance in miles or travel time.** Only `squaredDistance` in grid units exists, deliberately (`GameMap.swift:28-33`), and travel fatigue is not implemented despite that file's doc comment naming it.
- **No region outlines.** Regions have centres and members but no polygon or extent. A convex hull would be a UI invention presented as territory.
- **No crest, mark or logo.** `TeamIdentity` carries colours, a venue name, traditions and a city id. A marker is a coloured dot with a text label, and that is the whole honest vocabulary.
- **No `notableMeetings` text.** The stored strings are pre-formatted with a **zero-based** season (`RivalrySystem.swift:69`, `"S0 W7: ..."`) while every other label on screen uses `"Season \(season + 1)"`. Quoting them verbatim would put two different season numbers on one screen. Recorded as a gap; not rendered.

**Why Career Hub (52) is not in this plan.** Its dominant object per `04` §8 is "chronological story
of the coach" and the chronology does not exist: `jobHistory` is empty by construction until a
firing, promotion or resignation (`CareerArcState.swift:229`); `SeasonArchive` keeps champions and
final ranking arrays but **not standings**, and `completeSeason` replaces `CompetitionState`
wholesale (`PostseasonSystem.swift:174-186`), so a past season's record is unrecoverable;
`DomainEventPayload` has no hired/fired/promoted/resigned case and its `historicalWeight` switch is
exhaustive with no `default`, making that absence compiler-enforced rather than an oversight; and
`CareerSession.resolve` throws on `.acceptOpportunity` (`CareerSession.swift:129-131`). Separately,
at a fresh career `careerArc.status == .seeking` and `currentJob == nil` while `career.college`
names a live programme, so a screen rendering the arc verbatim tells an employed coach they are
unemployed. That is engine work behind a doc-first amendment, not a view. Task 5 records it.

---

## File Structure

| File | Responsibility |
|---|---|
| Create `Sources/ProFootballCoachUI/LeagueMapReadModels.swift` | The pure-data read model. No imports, `String` identifiers, hand-written `public init`s. Mirrors the `PersonnelReadModels.swift` precedent of one read-model file per screen group. |
| Create `Sources/CoachWorldApp/CoachWorldLeagueMapProvider.swift` | `GameState` -> `LeagueMapReadModel`. Imports Foundation/FootballSimCore/ProFootballCoachUI and **not** SwiftUI. |
| Create `Sources/ProFootballCoachUI/LeagueMapView.swift` | The screen. Names no engine type. Filename is load-bearing: `AccessibilityReflowTests` derives it from the `leagueMap` registry case. |
| Modify `Sources/CoachWorldApp/CoachWorldStore.swift` | One stored model, set in **both** the private init and `run(_:)`. |
| Modify `Sources/CoachWorldApp/CoachWorldAppRootView.swift` | A `case` in the screen switch and an arm in `navigate(_:in:)`. |
| Modify `Sources/ProFootballCoachUI/RootView.swift` | The DEBUG `--league-map` proof route. |
| Modify `Tests/SimTests/Suites/ReadModelProviderTests.swift` | Provider tests, including the "states nothing it cannot know" pins. |
| Modify `Tests/SimTests/Suites/ContractTests.swift` | Extend the hand-written per-screen block. |
| Modify `docs/STATUS.md`, `docs/plans/2026-08-12-road-to-beta.md` | Honest record, including the Career Hub finding. |

---

### Task 1: The read model and its provider

**Files:**
- Create: `Sources/ProFootballCoachUI/LeagueMapReadModels.swift`
- Create: `Sources/CoachWorldApp/CoachWorldLeagueMapProvider.swift`
- Test: `Tests/SimTests/Suites/ReadModelProviderTests.swift`

**Interfaces:**
- Consumes: `CoachWorldReadModelProvider`'s existing internal helpers — `worldReference(_:)`, `teamReference(_:in:)`, `snapshotID(_:_:_:)`, `recordLabel(_:in:)`, `rankLabel(_:in:)`, `seasonLabel(_:)`, `weekLabel(_:)`, `label(_ role: StaffRole)`.
- Produces: `LeagueMapReadModel` with nested `Place`, `Region`, `Rival`; and `CoachWorldReadModelProvider.leagueMap(from: GameState) -> LeagueMapReadModel?`.

- [ ] **Step 1: Write the failing tests**

Append to `Tests/SimTests/Suites/ReadModelProviderTests.swift`, inside `runReadModelProviderTests()`,
after the existing personnel suite. Seeds `4_07x` are unused today.

```swift
    suite("Read model provider: league map") {
        test("every place is a real member standing on its own generated city") {
            let (state, programme) = try startedCareer(seed: 4_070)
            guard let model = CoachWorldReadModelProvider.leagueMap(from: state) else {
                expect(false, "a started career produced no league map")
                return
            }
            expectEqual(model.provenance, .simulationSnapshot)
            expectEqual(model.gridWidth, GameMap.width)
            expectEqual(model.gridHeight, GameMap.height)
            expectEqual(model.regions.count, GameMap.regionCount)
            // Every member of both tiers, and nothing else.
            expectEqual(model.places.count, state.programmes.count + state.proTeams.count)
            expectEqual(Set(model.places.map(\.stableID)),
                        Set(state.programmes.ids.map(\.uuidString))
                            .union(state.proTeams.ids.map(\.uuidString)))

            for place in model.places {
                let id = UUID(uuidString: place.stableID)!
                // The id join, not the name join: the city is the one the identity names.
                guard let identity = state.identities[id],
                      let city = state.map.city(identity.homeCityID) else {
                    expect(false, "\(place.team.name) resolved to no city")
                    continue
                }
                expectEqual(place.x, city.x)
                expectEqual(place.y, city.y)
                expectEqual(place.cityName, city.name)
                expectEqual(place.marketSize, city.marketSize.value)
                expectEqual(place.venueName, identity.venueName)
                expectIn(place.x, 0...GameMap.width, "\(place.cityName) sits off the grid")
                expectIn(place.y, 0...GameMap.height, "\(place.cityName) sits off the grid")
            }
        }

        test("no two places share a city, and the controlled programme is the only one marked") {
            let (state, programme) = try startedCareer(seed: 4_071)
            guard let model = CoachWorldReadModelProvider.leagueMap(from: state) else {
                expect(false, "a started career produced no league map")
                return
            }
            // One city per member is a generation property (LeagueGenerator walks one cursor);
            // asserting it here is what would catch a provider that resolved two members to one.
            let coordinates = model.places.map { "\($0.x),\($0.y)" }
            expectEqual(Set(coordinates).count, coordinates.count,
                        "two members were placed on one point")
            expectEqual(model.places.filter(\.isControlled).count, 1)
            expectEqual(model.places.first(where: \.isControlled)?.stableID,
                        programme.id.uuidString)
        }

        test("rivals are the engine's own strongest, and pro teams are not given college rivals") {
            let (state, _) = try startedCareer(seed: 4_072)
            guard let model = CoachWorldReadModelProvider.leagueMap(from: state) else {
                expect(false, "a started career produced no league map")
                return
            }
            let rivalries = state.rivalries.values
            for place in model.places {
                let id = UUID(uuidString: place.stableID)!
                let expected = RivalrySeeder.strongest(for: id, among: rivalries)
                expectEqual(place.rivals.map(\.stableID), expected.map(\.uuidString),
                            "\(place.team.name) shows a rival order the engine did not choose")
                expect(place.rivals.count <= SharedRules.rivalriesPerProgramme,
                       "\(place.team.name) shows \(place.rivals.count) rivals, above the bound")
                for rival in place.rivals {
                    let otherID = UUID(uuidString: rival.stableID)!
                    guard let rivalry = rivalries.first(where: {
                        $0.involves(id) && $0.involves(otherID)
                    }) else {
                        expect(false, "\(rival.name) is not a recorded rivalry")
                        continue
                    }
                    expectEqual(rival.intensity, rivalry.intensity.value)
                    // Both sides of a rivalry are in the same tier (LeagueGenerator seeds within
                    // a tier), so a college place can never name a professional rival.
                    expectEqual(model.places.first { $0.stableID == rival.stableID }?.tierLabel,
                                place.tierLabel)
                }
            }
        }

        test("the map states nothing it cannot know") {
            let (state, _) = try startedCareer(seed: 4_073)
            guard let model = CoachWorldReadModelProvider.leagueMap(from: state) else {
                expect(false, "a started career produced no league map")
                return
            }
            // Each of these is empty because the engine holds nothing behind it. Filling one
            // requires deleting the assertion that names the gap justifying it.
            for place in model.places {
                // `Programme.recruitingReach` has no consumer anywhere in the engine, so there is
                // no radius to draw and no unit to draw it in.
                expect(place.reachRadius == nil,
                       "\(place.team.name) claims a recruiting reach the engine does not consume")
                for rival in place.rivals {
                    // `Rivalry.notableMeetings` stores a zero-based season inside a formatted
                    // string, contradicting every "Season N+1" label elsewhere on screen.
                    expect(rival.notableMeetings.isEmpty,
                           "a notable meeting was rendered with its zero-based season")
                }
            }
            // Regions have centres and members, never an extent.
            for region in model.regions {
                expectIn(region.talentDensity, SharedRules.ratingRange,
                         "\(region.name) reports a talent density off the rating scale")
            }
        }

        test("the same seed builds the same map") {
            let (first, _) = try startedCareer(seed: 4_074)
            let (second, _) = try startedCareer(seed: 4_074)
            expectEqual(CoachWorldReadModelProvider.leagueMap(from: first),
                        CoachWorldReadModelProvider.leagueMap(from: second))
        }
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
swift run SimTests --screen-read-models
```

Expected: compile failure, `cannot find 'LeagueMapReadModel' in scope` and
`type 'CoachWorldReadModelProvider' has no member 'leagueMap'`.

- [ ] **Step 3: Write the read model**

Create `Sources/ProFootballCoachUI/LeagueMapReadModels.swift`. No imports — read models in this
target are pure Swift value types and every identifier is a `String`.

```swift
/// The League Map's read model (`04` §8 family 41: place, distance, regions and rivalry context).
///
/// Coordinates arrive in the engine's own integer grid units rather than in points, because the
/// grid is where distance is *comparable* — `MapCity.squaredDistance` is integer-squared precisely
/// so the comparison cannot drift across platforms. Turning grid units into points is the view's
/// job and depends on the frame it is given; doing it here would bake one viewport into the model.
public struct LeagueMapReadModel: Sendable, Equatable {
    public struct Region: Sendable, Equatable, Identifiable {
        public let stableID: String
        public let name: String
        /// Rating scale. The engine's only consumer is prospect population, so this is a truthful
        /// "this region produces more talent" and nothing more.
        public let talentDensity: Int

        public var id: String { stableID }

        public init(stableID: String, name: String, talentDensity: Int) {
            self.stableID = stableID
            self.name = name
            self.talentDensity = talentDensity
        }
    }

    public struct Rival: Sendable, Equatable, Identifiable {
        public let stableID: String
        public let name: String
        /// Why the rivalry exists, worded from `Rivalry.Origin`. Wording an enum the engine holds
        /// states no fact the root does not.
        public let originLabel: String
        public let intensity: Int
        /// Always empty in v1. The engine stores each meeting as a pre-formatted string carrying a
        /// zero-based season, which would contradict the "Season N+1" labels used everywhere else.
        public let notableMeetings: [String]

        public var id: String { stableID }

        public init(
            stableID: String,
            name: String,
            originLabel: String,
            intensity: Int,
            notableMeetings: [String] = []
        ) {
            self.stableID = stableID
            self.name = name
            self.originLabel = originLabel
            self.intensity = intensity
            self.notableMeetings = notableMeetings
        }
    }

    public struct Place: Sendable, Equatable, Identifiable {
        public let stableID: String
        public let team: CoachWorldTeamReference
        public let cityName: String
        public let regionID: String
        public let regionName: String
        public let conferenceName: String?
        public let tierLabel: String
        public let isControlled: Bool
        public let x: Int
        public let y: Int
        public let marketSize: Int
        public let prestige: Int
        public let venueName: String
        public let rivals: [Rival]
        /// Always nil. `Programme.recruitingReach` exists on the model but no engine system reads
        /// it, so there is no grid-unit mapping to draw a radius from.
        public let reachRadius: Int?

        public var id: String { stableID }

        public init(
            stableID: String,
            team: CoachWorldTeamReference,
            cityName: String,
            regionID: String,
            regionName: String,
            conferenceName: String?,
            tierLabel: String,
            isControlled: Bool,
            x: Int,
            y: Int,
            marketSize: Int,
            prestige: Int,
            venueName: String,
            rivals: [Rival],
            reachRadius: Int? = nil
        ) {
            self.stableID = stableID
            self.team = team
            self.cityName = cityName
            self.regionID = regionID
            self.regionName = regionName
            self.conferenceName = conferenceName
            self.tierLabel = tierLabel
            self.isControlled = isControlled
            self.x = x
            self.y = y
            self.marketSize = marketSize
            self.prestige = prestige
            self.venueName = venueName
            self.rivals = rivals
            self.reachRadius = reachRadius
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
    public let gridWidth: Int
    public let gridHeight: Int
    public let regions: [Region]
    public let places: [Place]

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
        gridWidth: Int,
        gridHeight: Int,
        regions: [Region],
        places: [Place]
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
        self.gridWidth = gridWidth
        self.gridHeight = gridHeight
        self.regions = regions
        self.places = places
    }
}
```

- [ ] **Step 4: Write the provider**

Create `Sources/CoachWorldApp/CoachWorldLeagueMapProvider.swift`. Note the imports: **no SwiftUI**,
because `ContractTests.swift:531-549` fails any file that holds `GameState` and imports a UI
framework.

```swift
import Foundation
import FootballSimCore
import ProFootballCoachUI

/// `GameState` -> `LeagueMapReadModel`, per `04` §8 family 41.
///
/// The join throughout is `TeamIdentity.homeCityID`, never `Programme.cityName`. Names would work
/// today — 570 generated place names against 166 cities — but `GameMap`'s with-replacement fallback
/// exists for a smaller name pool, and if it ever fired a name join would silently collapse two
/// cities into one and put a programme in the wrong place. The engine joins by id for the same
/// reason (`CollegeRecruitingSystem`'s fit cache).
public extension CoachWorldReadModelProvider {
    /// Nil when no career is under control, which is the only state this cannot describe.
    static func leagueMap(from state: GameState) -> LeagueMapReadModel? {
        guard let control = state.career.college,
              let programme = state.programmes[control.programmeID],
              let coach = state.staff[control.coachID] else { return nil }

        let calendar = state.calendar
        let citiesByID = Dictionary(
            uniqueKeysWithValues: state.map.cities.map { ($0.id, $0) }
        )
        let regionsByID = Dictionary(
            uniqueKeysWithValues: state.map.regions.map { ($0.id, $0) }
        )
        let conferencesByID = Dictionary(
            uniqueKeysWithValues: state.league.conferences.map { ($0.id, $0) }
        )
        // One array, read many times. `EntityStore.values` is sorted by uuidString, so this is a
        // deterministic order and every downstream sort inherits it.
        let rivalries = state.rivalries.values

        var places: [LeagueMapReadModel.Place] = []
        places.reserveCapacity(state.programmes.count + state.proTeams.count)

        for member in state.programmes.values {
            places.append(place(
                id: member.id,
                tierLabel: "College",
                conferenceID: member.conferenceID,
                prestige: member.prestige.value,
                isControlled: member.id == programme.id,
                in: state,
                citiesByID: citiesByID,
                regionsByID: regionsByID,
                conferencesByID: conferencesByID,
                rivalries: rivalries
            ))
        }
        for member in state.proTeams.values {
            places.append(place(
                id: member.id,
                tierLabel: "Professional",
                conferenceID: member.conferenceID,
                prestige: member.prestige.value,
                isControlled: false,
                in: state,
                citiesByID: citiesByID,
                regionsByID: regionsByID,
                conferencesByID: conferencesByID,
                rivalries: rivalries
            ))
        }

        return LeagueMapReadModel(
            snapshotID: snapshotID("map", programme.id, calendar),
            provenance: .simulationSnapshot,
            world: worldReference(state),
            team: teamReference(programme.id, in: state),
            coach: CoachWorldPersonReference(
                stableID: coach.id.uuidString,
                name: coach.fullName,
                role: label(coach.role)
            ),
            seasonLabel: seasonLabel(calendar),
            weekLabel: weekLabel(calendar),
            recordLabel: recordLabel(programme.id, in: state),
            rankLabel: rankLabel(programme.id, in: state),
            gridWidth: GameMap.width,
            gridHeight: GameMap.height,
            regions: state.map.regions.map {
                LeagueMapReadModel.Region(
                    stableID: $0.id.uuidString,
                    name: $0.name,
                    talentDensity: $0.talentDensity.value
                )
            },
            places: places
        )
    }

    // MARK: - One place

    /// A member is dropped rather than guessed at when its identity or city is missing. That cannot
    /// happen in a generated world — `LeagueGenerator` writes an identity for all 166 members — but
    /// a hostile save is not a generated world, and an invented coordinate would be a fact.
    private static func place(
        id: UUID,
        tierLabel: String,
        conferenceID: UUID?,
        prestige: Int,
        isControlled: Bool,
        in state: GameState,
        citiesByID: [UUID: MapCity],
        regionsByID: [UUID: MapRegion],
        conferencesByID: [UUID: Conference],
        rivalries: [Rivalry]
    ) -> LeagueMapReadModel.Place? {
        guard let identity = state.identities[id],
              let city = citiesByID[identity.homeCityID] else { return nil }
        let region = regionsByID[city.regionID]

        return LeagueMapReadModel.Place(
            stableID: id.uuidString,
            team: teamReference(id, in: state),
            cityName: city.name,
            regionID: city.regionID.uuidString,
            regionName: region?.name ?? "Region not set",
            conferenceName: conferenceID.flatMap { conferencesByID[$0]?.name },
            tierLabel: tierLabel,
            isControlled: isControlled,
            x: city.x,
            y: city.y,
            marketSize: city.marketSize.value,
            prestige: prestige,
            venueName: identity.venueName,
            rivals: rivals(of: id, in: state, among: rivalries)
        )
    }

    /// The engine's own ordering, by calling the engine's own function. Re-sorting here would be a
    /// second definition of "strongest" that could drift from the one the world is built with.
    private static func rivals(
        of id: UUID,
        in state: GameState,
        among rivalries: [Rivalry]
    ) -> [LeagueMapReadModel.Rival] {
        RivalrySeeder.strongest(for: id, among: rivalries).compactMap { otherID in
            guard let rivalry = rivalries.first(where: {
                $0.involves(id) && $0.involves(otherID)
            }) else { return nil }
            return LeagueMapReadModel.Rival(
                stableID: otherID.uuidString,
                name: teamReference(otherID, in: state).name,
                originLabel: label(rivalry.origin),
                intensity: rivalry.intensity.value
            )
        }
    }

    static func label(_ origin: Rivalry.Origin) -> String {
        switch origin {
        case .geography: return "Neighbours"
        case .conference: return "Conference"
        case .both: return "Conference neighbours"
        }
    }
}
```

Note the `-> LeagueMapReadModel.Place?` return with `places.append(...)`: change the two append
sites to `if let made = place(...) { places.append(made) }` so a dropped member does not become an
optional in the array.

- [ ] **Step 5: Run the tests to verify they pass**

```bash
swift run SimTests --screen-read-models
```

Expected: `Read model provider: league map — 5 tests`, all passing, and every previously passing
suite in that run unchanged.

- [ ] **Step 6: Commit**

```bash
git add Sources/ProFootballCoachUI/LeagueMapReadModels.swift Sources/CoachWorldApp/CoachWorldLeagueMapProvider.swift Tests/SimTests/Suites/ReadModelProviderTests.swift
git commit -m "feat: build the League Map read model from the authoritative root"
```

---

### Task 2: The screen

**Files:**
- Create: `Sources/ProFootballCoachUI/LeagueMapView.swift`

**Interfaces:**
- Consumes: `LeagueMapReadModel` from Task 1; `CoachWorldTokens`, `CoachWorldRouteButton`, `CoachWorldActionButtonStyle`, `coachWorldDeskSurface(fill:border:)`, `CoachWorldTeamIdentity`, `CoachWorldScreenID`.
- Produces: `public struct LeagueMapView: View` with `public init(model:statusMessage:onContinue:onNavigate:)`.

**Composition, against `04` §4.5's density budget.** One dominant object: the map surface, taking the
working width less a fixed detail rail — at the 852 pt promise floor that is roughly 592 pt of 852,
which is 69%. One secondary region: the detail rail. That is one under the two-region allowance.
The grid is fitted to the surface preserving aspect, because distance is a mechanic (D6) and
stretching the grid would misstate it; the leftover margin is the map's own empty space, which is
what a map has.

**Why not `Canvas` for the markers.** A `Canvas` gives no hit-testing and no VoiceOver, so a map
drawn in one needs 166 hand-computed hit rectangles and a hand-built accessibility tree. Positioned
`Button`s give both for free, and 166 lightweight views is well inside what this app already does
(a college roster list is 105 rows). `Canvas` is used for exactly one thing here — the rivalry
links, which are ≤8 lines and carry no information the detail rail does not also state in words.

**AX5.** The spatial layout is replaced by the same places as a list grouped by region. No datum is
dropped: region grouping *is* the spatial structure the map draws, and city, conference, tier,
market size, prestige and rivals are all carried into the rows. A 166-dot map in a single AX5
column would be unreadable, which is the reflow this branch exists to perform.

- [ ] **Step 1: Write the view**

```swift
import SwiftUI

/// League Map, `04` §8 family 41 — place, distance, regions and rivalry context.
///
/// Team colour appears only at mark scale here, which is what `04` §5's restraint rules permit: a
/// marker is a chip, not a fill. Territory takes no team tint — the identity sheet that would price
/// a territory tint has not landed, and until it does §5 says a territory surface uses the neutral
/// map grammar. So regions are named, never washed.
public struct LeagueMapView: View {
    public let model: LeagueMapReadModel
    public let statusMessage: String?
    public let onContinue: () -> Void
    public let onNavigate: (CoachWorldScreenID) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedPlaceID: String
    @State private var tier: TierFilter = .college

    private enum TierFilter: String, CaseIterable {
        case college = "College"
        case professional = "Professional"
    }

    public init(
        model: LeagueMapReadModel,
        statusMessage: String? = nil,
        onContinue: @escaping () -> Void,
        onNavigate: @escaping (CoachWorldScreenID) -> Void
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onContinue = onContinue
        self.onNavigate = onNavigate
        _selectedPlaceID = State(
            initialValue: model.places.first(where: \.isControlled)?.stableID
                ?? model.places.first?.stableID
                ?? ""
        )
    }

    private var palette: CoachWorldTokens.Palette {
        colorScheme == .dark ? CoachWorldTokens.dark : CoachWorldTokens.light
    }

    public var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibleLayout
            } else {
                VStack(spacing: .zero) {
                    worldStrip
                    standardLayout
                }
            }
        }
        .foregroundStyle(palette.contentPrimary.color)
        .background(palette.page.color.ignoresSafeArea())
        .onChange(of: tier) {
            let ids = Set(visiblePlaces.map(\.stableID))
            if !ids.contains(selectedPlaceID) {
                selectedPlaceID = visiblePlaces.first?.stableID ?? ""
            }
        }
    }

    // MARK: - Data

    private var visiblePlaces: [LeagueMapReadModel.Place] {
        model.places.filter { $0.tierLabel == tier.rawValue }
    }

    private var selectedPlace: LeagueMapReadModel.Place? {
        model.places.first { $0.stableID == selectedPlaceID }
    }

    private var identity: CoachWorldTeamIdentity? {
        CoachWorldTeamIdentity(
            team: model.team,
            behind: palette.raised,
            inks: [palette.contentPrimary, palette.page]
        )
    }

    private var selectionColour: CoachWorldTokens.ColorValue {
        identity?.selectionRule(on: palette.work) ?? palette.collegeIdentity
    }

    private var worldContextLine: String {
        "\(model.seasonLabel) · \(model.weekLabel) · \(model.recordLabel)"
            + (model.rankLabel.map { " · \($0)" } ?? "")
    }

    // MARK: - World strip

    private var worldStrip: some View {
        HStack(spacing: CoachWorldTokens.Space.xs) {
            HStack(spacing: CoachWorldTokens.Space.xs) {
                uniformMark
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                    Text(model.team.name.uppercased())
                        .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                        .lineLimit(1)
                    Text(statusMessage ?? worldContextLine)
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(
                            (identity?.onField ?? palette.contentSecondary).color
                        )
                        .lineLimit(1)
                }
            }
            .foregroundStyle(identity?.onField.color ?? palette.contentPrimary.color)
            .padding(.horizontal, CoachWorldTokens.Space.xs)
            .frame(maxHeight: .infinity)
            .background(identity?.field.color ?? palette.raised.color)
            .overlay(alignment: .trailing) {
                if identity?.needsBoundary == true { verticalSeam }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(model.team.name), \(statusMessage ?? worldContextLine)")

            Divider().overlay(palette.contentQuiet.color)

            HStack(spacing: .zero) {
                route("Office", screen: .coachingHQ)
                route("Team", screen: .roster)
                route("Recruit", screen: .recruitingBoard)
                route("League", screen: .leagueMap, current: true)
                route("Career", screen: .careerHub)
            }
            .frame(maxWidth: .infinity)

            Button(action: onContinue) {
                Label("Continue", systemImage: "forward.end.fill")
            }
            .buttonStyle(CoachWorldActionButtonStyle(role: .primary, palette: palette))
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .frame(height: LeagueMapMetric.worldStripHeight)
        .background(palette.raised.color)
        .overlay(alignment: .bottom) { seam }
        .accessibilitySortPriority(50)
    }

    private var uniformMark: some View {
        Text(model.team.abbreviation)
            .font(CoachWorldTokens.TypeRole.caption.weight(.black))
            .foregroundStyle(markInk.color)
            .padding(.horizontal, CoachWorldTokens.Space.xxs)
            .frame(minWidth: LeagueMapMetric.markWidth, minHeight: LeagueMapMetric.markHeight)
            .background(
                (identity?.accent.color ?? palette.collegeIdentity.color),
                in: RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius)
            )
            .accessibilityHidden(true)
    }

    private var markInk: CoachWorldTokens.ColorValue {
        guard let accent = identity?.accent else { return palette.page }
        return accent.mostLegibleInk(from: [palette.page, palette.contentPrimary]) ?? palette.page
    }

    private func route(
        _ title: String,
        screen: CoachWorldScreenID,
        current: Bool = false
    ) -> some View {
        CoachWorldRouteButton(
            title: title,
            isCurrent: current,
            palette: palette,
            selection: selectionColour,
            action: { onNavigate(screen) }
        )
    }

    // MARK: - Standard layout

    private var standardLayout: some View {
        HStack(spacing: .zero) {
            mapSurface
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilitySortPriority(100)
            Divider().overlay(palette.contentQuiet.color)
            detailRail
                .frame(width: LeagueMapMetric.railWidth)
                .accessibilitySortPriority(80)
        }
    }

    private var mapSurface: some View {
        VStack(spacing: CoachWorldTokens.Space.xs) {
            tierControl
            if visiblePlaces.isEmpty {
                ContentUnavailableView(
                    "No places to show",
                    systemImage: "list.number",
                    description: Text("Programmes appear here when a world is loaded.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                GeometryReader { frame in
                    let layout = MapLayout(
                        bounds: frame.size,
                        gridWidth: model.gridWidth,
                        gridHeight: model.gridHeight
                    )
                    ZStack(alignment: .topLeading) {
                        rivalryLinks(layout)
                        ForEach(model.regions) { region in
                            regionLabel(region, layout: layout)
                        }
                        ForEach(visiblePlaces) { place in
                            marker(place, layout: layout)
                        }
                    }
                    .frame(width: frame.size.width, height: frame.size.height)
                }
            }
        }
        .padding(CoachWorldTokens.Space.sm)
        .accessibilityLabel("League map, \(visiblePlaces.count) \(tier.rawValue) places")
    }

    private var tierControl: some View {
        Picker("Tier", selection: $tier) {
            ForEach(TierFilter.allCases, id: \.self) { value in
                Text(value.rawValue).tag(value)
            }
        }
        .pickerStyle(.segmented)
        .accessibilitySortPriority(40)
    }

    /// The one `Canvas` on this screen: at most eight lines from the selected place to its rivals.
    /// Hidden from VoiceOver because the rail speaks every rival by name, origin and intensity —
    /// the line adds direction on a fictional grid, which is not a fact a sentence can carry.
    private func rivalryLinks(_ layout: MapLayout) -> some View {
        let origin = selectedPlace
        let targets = origin.map { place in
            place.rivals.compactMap { rival in
                model.places.first { $0.stableID == rival.stableID }
            }
        } ?? []
        return Canvas { context, _ in
            guard let origin else { return }
            let start = layout.point(x: origin.x, y: origin.y)
            for target in targets {
                var path = Path()
                path.move(to: start)
                path.addLine(to: layout.point(x: target.x, y: target.y))
                context.stroke(
                    path,
                    with: .color(selectionColour.color.opacity(0.45)),
                    lineWidth: CoachWorldTokens.Shape.hairline
                )
            }
        }
        .accessibilityHidden(true)
    }

    private func regionLabel(_ region: LeagueMapReadModel.Region, layout: MapLayout) -> some View {
        // Placed at the mean of the region's own cities. That is label placement, not a claim about
        // an extent: regions have members and centres in the engine, never a boundary.
        let members = model.places.filter { $0.regionID == region.stableID }
        let centre = layout.centre(of: members)
        return Text(region.name.uppercased())
            .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
            .foregroundStyle(palette.contentQuiet.color)
            .position(centre)
            .accessibilityHidden(true)
            .opacity(members.isEmpty ? 0 : 1)
    }

    private func marker(_ place: LeagueMapReadModel.Place, layout: MapLayout) -> some View {
        let isSelected = place.stableID == selectedPlaceID
        let fill = CoachWorldTokens.ColorValue(hexString: place.team.primaryColorHex ?? "")
        return Button(action: { selectedPlaceID = place.stableID }) {
            Circle()
                .fill(fill?.color ?? palette.contentSecondary.color)
                .frame(width: LeagueMapMetric.markerSize, height: LeagueMapMetric.markerSize)
                // Canon 6.1: every team fill carries a hairline boundary, because a generated
                // colour can land arbitrarily close to the surface behind it.
                .overlay { Circle().stroke(palette.page.color, lineWidth: CoachWorldTokens.Shape.hairline) }
                .overlay {
                    // Selection takes a boundary, never a fill (`04` §5).
                    if isSelected {
                        Circle()
                            .stroke(selectionColour.color, lineWidth: LeagueMapMetric.selectedRing)
                            .frame(
                                width: LeagueMapMetric.selectedRingSize,
                                height: LeagueMapMetric.selectedRingSize
                            )
                    }
                }
                .overlay {
                    if place.isControlled {
                        Circle()
                            .stroke(palette.contentPrimary.color, lineWidth: CoachWorldTokens.Shape.hairline)
                            .frame(
                                width: LeagueMapMetric.controlledRingSize,
                                height: LeagueMapMetric.controlledRingSize
                            )
                    }
                }
                .frame(
                    width: CoachWorldTokens.Shape.minimumTarget,
                    height: CoachWorldTokens.Shape.minimumTarget
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .position(layout.point(x: place.x, y: place.y))
        .accessibilityLabel(accessibilityLabel(place))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Detail rail

    @ViewBuilder
    private var detailRail: some View {
        if let place = selectedPlace {
            ScrollView {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
                    Text(place.team.name)
                        .font(CoachWorldTokens.TypeRole.title)
                    Text("\(place.cityName) · \(place.regionName)")
                        .font(CoachWorldTokens.TypeRole.body)
                        .foregroundStyle(palette.contentSecondary.color)
                    fact("Venue", place.venueName)
                    fact("Conference", place.conferenceName ?? "Independent")
                    fact("Tier", place.tierLabel)
                    fact("Prestige", "\(place.prestige)")
                    fact("Market", "\(place.marketSize)")
                    fact("Talent in region", talentDensityLabel(place))
                    rivalSection(place)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(CoachWorldTokens.Space.sm)
            }
        } else {
            ContentUnavailableView(
                "No place selected",
                systemImage: "list.number",
                description: Text("Choose a programme on the map to read its place.")
            )
        }
    }

    private func fact(_ name: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Space.xs) {
            Text(name.uppercased())
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentQuiet.color)
            Spacer(minLength: .zero)
            Text(value)
                .font(CoachWorldTokens.TypeRole.body.weight(.bold))
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(value)")
    }

    private func talentDensityLabel(_ place: LeagueMapReadModel.Place) -> String {
        model.regions.first { $0.stableID == place.regionID }
            .map { "\($0.talentDensity)" } ?? "Not recorded"
    }

    @ViewBuilder
    private func rivalSection(_ place: LeagueMapReadModel.Place) -> some View {
        Text("Rivals".uppercased())
            .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
            .foregroundStyle(palette.contentQuiet.color)
        if place.rivals.isEmpty {
            Text("No rivalry recorded")
                .font(CoachWorldTokens.TypeRole.body)
                .foregroundStyle(palette.contentSecondary.color)
        } else {
            ForEach(place.rivals) { rival in
                Button(action: { selectedPlaceID = rival.stableID }) {
                    HStack(spacing: CoachWorldTokens.Space.xs) {
                        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                            Text(rival.name)
                                .font(CoachWorldTokens.TypeRole.body.weight(.bold))
                                .lineLimit(1)
                            Text(rival.originLabel)
                                .font(CoachWorldTokens.TypeRole.caption)
                                .foregroundStyle(palette.contentQuiet.color)
                        }
                        Spacer(minLength: .zero)
                        Text("\(rival.intensity)")
                            .font(CoachWorldTokens.TypeRole.body.weight(.bold))
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    "\(rival.name), \(rival.originLabel), intensity \(rival.intensity)"
                )
            }
        }
    }

    // MARK: - Accessibility-size layout

    /// AX5 drops the spatial rendering and keeps every datum, grouped by region — which is the
    /// structure the map draws. A 166-marker map in one column is not readable at accessibility
    /// sizes, and `04` §4.5 asks the composition to reflow rather than to shrink.
    private var accessibleLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .zero) {
                worldStrip
                tierControl
                    .padding(CoachWorldTokens.Space.sm)
                ForEach(model.regions) { region in
                    let members = visiblePlaces.filter { $0.regionID == region.stableID }
                    if !members.isEmpty {
                        Text("\(region.name) · talent \(region.talentDensity)")
                            .font(CoachWorldTokens.TypeRole.headline)
                            .padding(CoachWorldTokens.Space.sm)
                        ForEach(members) { place in
                            Button(action: { selectedPlaceID = place.stableID }) {
                                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                                    Text(place.team.name)
                                        .font(CoachWorldTokens.TypeRole.body.weight(.bold))
                                    Text(placeSummary(place))
                                        .font(CoachWorldTokens.TypeRole.caption)
                                        .foregroundStyle(palette.contentSecondary.color)
                                }
                                .frame(
                                    maxWidth: .infinity,
                                    minHeight: CoachWorldTokens.Shape.minimumTarget,
                                    alignment: .leading
                                )
                                .padding(CoachWorldTokens.Space.sm)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(accessibilityLabel(place))
                        }
                    }
                }
                if let place = selectedPlace {
                    Text("Rivals of \(place.team.name)")
                        .font(CoachWorldTokens.TypeRole.headline)
                        .padding(CoachWorldTokens.Space.sm)
                    rivalSection(place)
                        .padding(.horizontal, CoachWorldTokens.Space.sm)
                }
            }
        }
        .accessibilitySortPriority(100)
    }

    private func placeSummary(_ place: LeagueMapReadModel.Place) -> String {
        "\(place.cityName) · \(place.conferenceName ?? "Independent") · prestige \(place.prestige)"
    }

    private func accessibilityLabel(_ place: LeagueMapReadModel.Place) -> String {
        var parts = [place.team.name, place.cityName, place.regionName]
        parts.append(place.conferenceName ?? "Independent")
        parts.append("prestige \(place.prestige)")
        parts.append("market \(place.marketSize)")
        if place.isControlled { parts.append("your programme") }
        return parts.joined(separator: ", ")
    }

    // MARK: - Hairlines

    private var seam: some View {
        Rectangle()
            .fill(palette.contentQuiet.color.opacity(0.38))
            .frame(height: CoachWorldTokens.Shape.hairline)
            .accessibilityHidden(true)
    }

    private var verticalSeam: some View {
        Rectangle()
            .fill(palette.contentQuiet.color.opacity(0.38))
            .frame(width: CoachWorldTokens.Shape.hairline)
            .accessibilityHidden(true)
    }
}

/// Grid units to points, aspect preserved and centred.
///
/// Aspect is preserved because distance is a mechanic (D6) and stretching the grid to fill a
/// 2.17:1 landscape frame would misstate which programmes are near each other. The leftover margin
/// is the map's own empty space.
private struct MapLayout {
    let scale: CGFloat
    let offsetX: CGFloat
    let offsetY: CGFloat

    init(bounds: CGSize, gridWidth: Int, gridHeight: Int) {
        let width = max(CGFloat(gridWidth), 1)
        let height = max(CGFloat(gridHeight), 1)
        scale = min(bounds.width / width, bounds.height / height)
        offsetX = (bounds.width - width * scale) / 2
        offsetY = (bounds.height - height * scale) / 2
    }

    func point(x: Int, y: Int) -> CGPoint {
        CGPoint(x: offsetX + CGFloat(x) * scale, y: offsetY + CGFloat(y) * scale)
    }

    func centre(of places: [LeagueMapReadModel.Place]) -> CGPoint {
        guard !places.isEmpty else { return CGPoint(x: offsetX, y: offsetY) }
        let sumX = places.reduce(0) { $0 + $1.x }
        let sumY = places.reduce(0) { $0 + $1.y }
        return point(x: sumX / places.count, y: sumY / places.count)
    }
}

private enum LeagueMapMetric {
    static let worldStripHeight: CGFloat = 48
    static let markWidth: CGFloat = 34
    static let markHeight: CGFloat = 22
    static let railWidth: CGFloat = 260
    static let markerSize: CGFloat = 10
    static let selectedRing: CGFloat = 2
    static let selectedRingSize: CGFloat = 20
    static let controlledRingSize: CGFloat = 16
}
```

- [ ] **Step 2: Build, and confirm the AX5 contract now covers the new file**

```bash
swift build 2>&1 | tail -20
```

Expected: `Compiling ProFootballCoachUI LeagueMapView.swift`, build succeeds.

```bash
swift run SimTests --design-contracts
```

Expected: `AX5 contract: 6 landed, 56 pending` (was 5 and 57), and the three clause tests pass —
the file contains `dynamicTypeSize.isAccessibilitySize` and `accessibilitySortPriority`.

- [ ] **Step 3: Confirm the token, symbol and boundary scans**

```bash
swift run SimTests --contracts
```

Expected: pass. In particular "no view contains a design-token literal" and the `04` §6.6 symbol
register scan — `forward.end.fill` and `list.number` are both registered, and the screen draws no
other symbol.

- [ ] **Step 4: Commit**

```bash
git add Sources/ProFootballCoachUI/LeagueMapView.swift
git commit -m "feat: add the League Map screen"
```

---

### Task 3: Wire it into the shipped app and the DEBUG proof route

**Files:**
- Modify: `Sources/CoachWorldApp/CoachWorldStore.swift`
- Modify: `Sources/CoachWorldApp/CoachWorldAppRootView.swift`
- Modify: `Sources/ProFootballCoachUI/RootView.swift`

**Interfaces:**
- Consumes: `CoachWorldReadModelProvider.leagueMap(from:)` (Task 1), `LeagueMapView` (Task 2).
- Produces: `CoachWorldStore.leagueMap: LeagueMapReadModel?`, and a reachable `League` route.

- [ ] **Step 1: Add the stored model to the store**

In `Sources/CoachWorldApp/CoachWorldStore.swift`, beside the existing `public private(set) var`
screen models, add:

```swift
    public private(set) var leagueMap: LeagueMapReadModel?
```

Then set it in **both** places the other models are set — the private init and `run(_:)`. Missing
either leaves the screen stale after an intent, which is the defect the two-site pattern exists to
make obvious:

```swift
        leagueMap = CoachWorldReadModelProvider.leagueMap(from: snapshot)
```

- [ ] **Step 2: Route to it in the shipped root**

In `Sources/CoachWorldApp/CoachWorldAppRootView.swift`, add a case to the `switch screen` in
`career(_:)`, before `default:`:

```swift
            case .leagueMap:
                if let model = store.leagueMap {
                    LeagueMapView(
                        model: model,
                        statusMessage: failure ?? store.statusMessage,
                        onContinue: { Task { await advance(store) } },
                        onNavigate: { navigate($0, in: store) }
                    )
                }
```

and an arm to `navigate(_:in:)`, before `default:`:

```swift
        case .leagueMap where store.leagueMap != nil:
            screen = .leagueMap
            failure = nil
```

`Continue` calls the same `advance(store)` path every other screen uses, so a pending decision
refuses identically here — the screen-dependent-Continue defect recorded in `docs/STATUS.md` for
Roster and Recruiting Board is not reintroduced.

- [ ] **Step 3: Add the DEBUG proof route**

In `Sources/ProFootballCoachUI/RootView.swift`, add to the `entries` array in
`DebugCoachingHQRoot.init`:

```swift
            ("--league-map", "map", .leagueMap),
```

and a branch in `body`, before the final `else`:

```swift
            } else if currentScreen == .leagueMap {
                LeagueMapView(
                    model: leagueMap,
                    statusMessage: statusMessage,
                    onContinue: { statusMessage = "No later event is available yet" },
                    onNavigate: navigate
                )
```

with the sample model as a stored property beside the others:

```swift
    private let leagueMap = CoachWorldSampleData.leagueMap
```

and widen `navigate` to admit it:

```swift
        guard screen == .coachingHQ || screen == .recruitingBoard || screen == .roster
            || screen == .leagueMap else {
```

- [ ] **Step 4: Add the DEBUG sample data**

In `Sources/ProFootballCoachUI/LeagueMapReadModels.swift`, at the bottom, inside `#if DEBUG`. It
declares `provenance: .sample` — that is what the "SAMPLE CAREER" flag reads, and a fixture must
never claim to be a snapshot. The cast is the one `04` §10 fixes for every proof: Carson Tech, head
coach Eric Mercer, Week 9, Southern State as opponent.

```swift
#if DEBUG
public enum CoachWorldLeagueMapSampleData {
    public static let leagueMap = LeagueMapReadModel(
        snapshotID: "map-sample",
        provenance: .sample,
        world: CoachWorldReference(stableID: "world-sample", name: "Football Universe"),
        team: CoachWorldTeamReference(
            stableID: "team-carson",
            name: "Carson Tech",
            abbreviation: "CAR",
            primaryColorHex: "2F6DB5",
            secondaryColorHex: "E8B23A"
        ),
        coach: CoachWorldPersonReference(
            stableID: "coach-mercer",
            name: "Eric Mercer",
            role: "Head Coach"
        ),
        seasonLabel: "Season 1",
        weekLabel: "Week 9",
        recordLabel: "6-2",
        rankLabel: "#18",
        gridWidth: 1000,
        gridHeight: 700,
        regions: [
            LeagueMapReadModel.Region(
                stableID: "region-north",
                name: "Kessel Reach",
                talentDensity: 71
            ),
            LeagueMapReadModel.Region(
                stableID: "region-south",
                name: "Marlow Basin",
                talentDensity: 84
            ),
        ],
        places: [
            LeagueMapReadModel.Place(
                stableID: "team-carson",
                team: CoachWorldTeamReference(
                    stableID: "team-carson",
                    name: "Carson Tech",
                    abbreviation: "CAR",
                    primaryColorHex: "2F6DB5",
                    secondaryColorHex: "E8B23A"
                ),
                cityName: "Carson Hollow",
                regionID: "region-north",
                regionName: "Kessel Reach",
                conferenceName: "Northern Reach Conference",
                tierLabel: "College",
                isControlled: true,
                x: 320,
                y: 240,
                marketSize: 62,
                prestige: 68,
                venueName: "Carson Hollow Grounds",
                rivals: [
                    LeagueMapReadModel.Rival(
                        stableID: "team-southern",
                        name: "Southern State",
                        originLabel: "Conference neighbours",
                        intensity: 78
                    )
                ]
            ),
            LeagueMapReadModel.Place(
                stableID: "team-southern",
                team: CoachWorldTeamReference(
                    stableID: "team-southern",
                    name: "Southern State",
                    abbreviation: "SOU",
                    primaryColorHex: "8E3B4F",
                    secondaryColorHex: "D9D2C4"
                ),
                cityName: "Marlow Flats",
                regionID: "region-south",
                regionName: "Marlow Basin",
                conferenceName: "Northern Reach Conference",
                tierLabel: "College",
                isControlled: false,
                x: 470,
                y: 430,
                marketSize: 74,
                prestige: 81,
                venueName: "Marlow Flats Field",
                rivals: [
                    LeagueMapReadModel.Rival(
                        stableID: "team-carson",
                        name: "Carson Tech",
                        originLabel: "Conference neighbours",
                        intensity: 78
                    )
                ]
            ),
        ]
    )
}
#endif
```

Reference it in `RootView.swift` as `CoachWorldLeagueMapSampleData.leagueMap`.

- [ ] **Step 5: Build and run the full suite**

```bash
swift build 2>&1 | tail -5
```

Expected: build succeeds.

```bash
./scripts/verify.sh
```

Expected: build green, and the suite green at its previous count **plus the five new tests** from
Task 1. Record the exact figure — it goes into `docs/STATUS.md` in Task 5 and must be measured, not
estimated.

- [ ] **Step 6: Commit**

```bash
git add Sources/CoachWorldApp/CoachWorldStore.swift Sources/CoachWorldApp/CoachWorldAppRootView.swift Sources/ProFootballCoachUI/RootView.swift Sources/ProFootballCoachUI/LeagueMapReadModels.swift
git commit -m "feat: route the League tab to the League Map"
```

---

### Task 4: Extend the per-screen contract block

**Files:**
- Modify: `Tests/SimTests/Suites/ContractTests.swift:716-824`

**Interfaces:**
- Consumes: `LeagueMapView.swift` and `CoachWorldLeagueMapProvider.swift` on disk.
- Produces: no new symbols; extends an existing suite.

The per-screen assertions in `ContractTests.swift` are a **hand-written list**, so a new screen is
outside them until someone adds it. `CLAUDE.md`'s coverage-boundary rule makes adding it the
expected move rather than an optional one.

- [ ] **Step 1: Write the failing test**

Add inside the existing per-screen suite in `ContractTests.swift`:

```swift
        test("League Map is a read-model surface with no engine type and no invented reach") {
            guard let view = swiftFiles(under: "Sources/ProFootballCoachUI")
                .first(where: { $0.path.hasSuffix("/LeagueMapView.swift") }) else {
                expect(false, "LeagueMapView.swift not found")
                return
            }
            expect(view.text.contains("public struct LeagueMapView"),
                   "the family's view must be the public type named for it")
            expect(view.text.contains("let model: LeagueMapReadModel"),
                   "the screen reads an injected read model, never a global")
            expect(!view.text.contains("onTapGesture"),
                   "a tappable place is a Button, so it is focusable and has a spoken label")
            expect(view.text.contains("CoachWorldRouteButton"),
                   "world routes use the shared control, not a screen-local copy")
            expect(view.text.contains("CoachWorldActionButtonStyle"),
                   "Continue uses the shared action style")
            expect(view.text.contains("monospacedDigit"),
                   "numerals that carry a value are tabular")

            guard let provider = swiftFiles(under: "Sources/CoachWorldApp")
                .first(where: { $0.path.hasSuffix("/CoachWorldLeagueMapProvider.swift") }) else {
                expect(false, "CoachWorldLeagueMapProvider.swift not found")
                return
            }
            // The join that matters. `cityName` is a display string; two members could share one
            // after the with-replacement fallback, and the map would then place one of them wrong.
            expect(provider.text.contains("homeCityID"),
                   "the provider must join a member to its city by identifier")
            expect(!provider.text.contains("recruitingReach"),
                   "no engine system reads recruitingReach, so no radius may be drawn from it")
        }
```

- [ ] **Step 2: Run it and watch it pass against the work already done**

```bash
swift run SimTests --contracts
```

Expected: pass. If any assertion fails, the defect is in Task 2's view or Task 1's provider — fix
there, not by weakening the assertion.

- [ ] **Step 3: Verify the assertions can fail**

Temporarily change `homeCityID` to `cityName` in the provider and re-run:

```bash
swift run SimTests --contracts
```

Expected: FAIL with "the provider must join a member to its city by identifier". Revert the change
and re-run to green. A scan that has never failed is not known to be a scan.

- [ ] **Step 4: Commit**

```bash
git add Tests/SimTests/Suites/ContractTests.swift
git commit -m "test: bring League Map inside the per-screen contract block"
```

---

### Task 5: Record what landed, and what this slice proved cannot land yet

**Files:**
- Modify: `docs/STATUS.md`
- Modify: `docs/plans/2026-08-12-road-to-beta.md`

**Interfaces:**
- Consumes: the measured suite total from Task 3 Step 5.
- Produces: no code.

- [ ] **Step 1: Write the STATUS entry**

Add a dated section to `docs/STATUS.md`, in the same register as the entries around it — measured
figures, and the negative findings stated rather than smoothed. It must carry:

1. **What landed.** `LeagueMapView`, its read model and provider; the `League` route reaching a real screen; the measured suite total; that the AX5 contract now reports 6 landed / 56 pending.
2. **The join, and why it is by identifier.** Name lookup would work at today's 570-names-to-166-cities margin and break silently if `GameMap`'s with-replacement fallback ever fired.
3. **The three things the screen deliberately does not draw** — reach radius (`recruitingReach` has no engine consumer), region outlines (regions have centres and members, no extent), notable meetings (stored with a zero-based season that contradicts every other label on screen).
4. **Career Hub, and why it did not land.** The chronology does not exist: `jobHistory` empty by construction, no per-season standings retained past a rollover, no career-arc domain event of any kind with the absence compiler-enforced by an exhaustive `historicalWeight` switch, `CareerSession.resolve` throwing on `.acceptOpportunity`, and a fresh career reporting `status == .seeking` while `career.college` names a live programme. State plainly that the **Career tab is still a dead end**, and that this is an engine and canon question rather than a view one.
5. **What was not done.** No simulator run is claimed unless one was performed; if it was, report only what the screenshots show. No device.

- [ ] **Step 2: Update the road-to-beta register**

In `docs/plans/2026-08-12-road-to-beta.md`, amend the `U-6` row (§4) from "Not started" to name
League Map as the first landed family with its date, and 55 of 62 families still without a view.
Add the Career Hub blockers to §6 as a new owner decision — whether to build the career-arc event
and per-season record retention that families 52, 53, 54 and 55 all sit on — because it is
milestone-sized engine work and canon does not answer it.

- [ ] **Step 3: Commit**

```bash
git add docs/STATUS.md docs/plans/2026-08-12-road-to-beta.md
git commit -m "docs: record the League Map, and why Career Hub cannot follow it yet"
```

---

## Phase-end gates

Not steps in a task — the phase is not done until all of these hold, per `CLAUDE.md`'s process.

- [ ] `./scripts/verify.sh` green: build plus the full default suite, with the exact counts recorded.
- [ ] `swift run SimTests --design-contracts` green, reporting 6 landed / 56 pending.
- [ ] Adversarial review (`adversarial-reviewer` or `/code-review`) run on the phase diff, confirmed findings fixed first. A review is not a build and is never reported as one.
- [ ] `confidence-review` run over the new code, each doubt investigated to root cause.
- [ ] `rewrite-tournament` run in post-edit mode over `leagueMap(from:)`, `place(id:...)` and `MapLayout`.
- [ ] Touched surfaces scored against `04b`: eight dimensions, at least 31/40, zero P0/P1. **AX5 may not be scored above 3** — `04` §7.1 forbids it on the strength of a suite with no view host.
- [ ] Owner walkthrough script updated if the screen is to be demonstrated. **A simulator run is the owner's to perform**; if this session runs one, report only what the screenshots show and never describe it as a device run.

## Self-review

**Spec coverage.** `04` §8 family 41's dominant object is "place, distance, regions and rivalry
context": place is the city marker and the rail's city/venue/conference; distance is the
aspect-preserved grid, stated as the honest thing it is rather than converted to invented miles;
regions are named, labelled at their members' mean and carry real `talentDensity`; rivalry context
is the link layer plus the rail's origin and intensity, from the engine's own `strongest`. §4.5's
budget: one dominant object at ~69% of width, one secondary region, no status glyphs, no verdict
line, popouts to depth zero. §5's restraint rules: team colour at mark scale only, selection as a
boundary, hairline on every team fill, no territory tint. §7's VoiceOver order and AX5 reflow are
both implemented and both mechanically checked.

**Placeholders.** None: every step carries the code it changes, every command carries its expected
output, and the two "modify" tasks quote the exact insertion text.

**Type consistency.** `LeagueMapReadModel.Place.rivals` is `[Rival]` in the model, the provider, the
view and the tests. `reachRadius` is `Int?` and always `nil`, pinned by the "states nothing it
cannot know" test and by Task 4's source scan. `MapLayout.point(x:y:)` takes `Int` grid units
everywhere it is called. `CoachWorldLeagueMapSampleData.leagueMap` is the name used in both the
sample data and `RootView`.

**One gap found and closed during review:** Task 1 Step 4's `place(...)` returns
`LeagueMapReadModel.Place?` while the loops call `places.append(...)`; the step now states the
`if let` at both call sites explicitly rather than leaving it to be discovered at compile time.
