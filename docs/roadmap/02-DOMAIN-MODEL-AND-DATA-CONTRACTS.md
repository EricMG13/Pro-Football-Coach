# Domain Model and Data Contracts

## 1. Root state

```swift
struct GameState: Codable, Sendable {
    var schemaVersion: Int
    var worldSeed: UInt64
    var calendar: CalendarState
    var coachCareer: CoachCareer

    var programmes: EntityStore<Programme>
    var proTeams: EntityStore<ProTeam>
    var players: EntityStore<Player>
    var staff: EntityStore<Staff>
    var prospects: EntityStore<Prospect>

    var competitions: CompetitionState
    var rosters: RosterState
    var college: CollegeState
    var pro: ProState
    var health: HealthState
    var development: DevelopmentState
    var scouting: ScoutingState
    var tactics: TacticsState
    var relationships: RelationshipState
    var stakeholders: StakeholderState
    var history: HistoryState

    var pending: PendingQueues
}
```

The exact implementation may differ, but the ownership boundaries should not.

---

## 2. Required new domain concepts

### Person identity
Players and staff require persistent identity independent of employment/team.

Minimum:
- ID
- generated name
- birth/age data
- origin region
- traits/personality
- relationship keys
- career start/end

### Player career record
Separate from current player state:
- season-by-season team
- usage
- honors
- key games
- transactions
- recruiting history
- draft history
- records

### Staff career record
- employment history
- roles
- scheme history
- results
- promotions
- firings
- relationships
- coaching-tree parent/children

### Knowledge model
Truth and observed belief must be separate.

```swift
struct Knowledge<T> {
    var estimate: T
    var confidence: Confidence
    var lastUpdatedWeek: Int
    var evidenceCount: Int
}
```

Use for:
- recruit ratings
- potential
- opponent tendencies
- draft prospects
- injury uncertainty if desired

### Relationship edges
```text
Coach ↔ Player
Coach ↔ Staff
Programme ↔ Recruit
Programme ↔ Programme
Coach ↔ Programme
Player ↔ Programme
```

Edges carry:
- affinity
- trust
- history flags
- last meaningful interaction
- reasons

Do not attempt a fully general social graph in v1. Use typed relationships.

### Domain events
Event payloads contain stable IDs and context at the time of occurrence.

Never store only rendered strings.

---

## 3. Match output contract

The current match engine already records play outcomes and matchups. Expand its output rather than allowing UI to infer.

Required:
- possession
- formation/personnel
- field coordinates for all relevant actors at key frames
- assignment/matchup IDs
- pre-snap state
- post-snap state
- play concept
- coverage/front
- result
- EPA-like internal value if supported
- injury/fatigue effects
- call-in trigger
- explanation tags

For the FM-style 2D display, the engine should expose **recorded animation anchors**, not raw physics.

```swift
struct MatchFrame {
    let gameTime: GameClock
    let ball: FieldPoint
    let actors: [ActorFrame] // ID, side, position label/number, point, emphasis
    let phase: FramePhase
    let annotations: [FrameAnnotation]
}
```

Rendering interpolates between anchors. It never resolves football.

---

## 4. Read model contract

Every major screen receives a purpose-built immutable projection.

Examples:
- `HQView`
- `ScoutingRoomView`
- `GamePlanView`
- `DepthChartView`
- `PlayerProfileView`
- `RecruitingBoardView`
- `MatchView`
- `CareerView`
- `OffseasonView`
- `LeagueView`
- `SearchResultsView`

Do not expose the entire `GameState` to SwiftUI.

Benefits:
- performance
- stable UI contracts
- fog-of-war enforcement
- simpler testing
- no accidental simulation logic in views

---

## 5. Intent contract

All writes are explicit intents.

Examples:
```text
SetPracticeAllocation
SetGamePlanKey
MoveDepthChartPlayer
ContactRecruit
ScheduleVisit
OfferNILAllocation
RetainPortalPlayer
HireStaff
ReleasePlayer
OfferContract
SubmitDraftPick
AcceptJobOffer
ChooseCallInOption
ChangeMatchTempo
DelegateMatchControl
```

Each intent has:
- validation
- cost
- deterministic resolution
- emitted events
- returned read-model delta or new snapshot
