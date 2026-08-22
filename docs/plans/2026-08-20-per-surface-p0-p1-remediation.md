# Per-surface P0/P1 remediation

## Context

`docs/reviews/2026-08-19-full-surface-adversarial-review.md` scored all 62 screen families and found
three system-level defects that produced most of the low scores. A prior plan (executed, merged via
PR #25) fixed those three: S-0 (no Dynamic Type scaling), S-6 (15 dead alias branches in
`career()`), and S-7/S-8/S-1/S-2 (verification gates that checked strings instead of properties). It
explicitly deferred per-surface P0/P1 findings to a later phase. This plan is that phase.

Scope is strictly the confirmed-live P0 and P1 findings. Three research passes (independent source
verification, not just re-reading the review) resolved every open question about what is actually
reachable in the shipped app versus what only describes now-dead code, and found several places
where the review's own citations had drifted from current source or where a smaller/cleaner fix
exists than the review implied. P2/P3 findings and findings confined to unreachable code are listed
at the end, excluded from committed work, so nothing is silently dropped or silently included.

No Swift toolchain exists in this environment. Every change is written to standard, correctness
argued from source reading, and recorded in `docs/STATUS.md` as unverified/never-compiled per
`CLAUDE.md`. CI (`scripts/verify.sh` via `.github/workflows/tests.yml`) is the only real compiler.

## Ground truth: dead vs. live

`CoachWorldScreenID` (`Sources/ProFootballCoachUI/ScreenRegistry.swift`) has 62 cases, 15 of them
aliases whose `routeDisposition` resolves to a canonical destination. The prior phase deleted their
dead `case` branches from `career()`'s render switch. Confirmed by direct source trace (not just the
review) for this new phase:

- **Fully dead, excluded:** `jobSecurity`, `coachingCarousel` — their wrapper views are never
  constructed anywhere, and `CoachWorldAppRootView.swift`'s `navigate(_:in:)` explicitly redirects
  both to `.careerHub` before `CareerHubView`'s `focus` switch could ever see them, even via old-save
  restoration. This makes review findings C-2 and C-3 dead-code descriptions, not live defects.
- **Fully dead, excluded:** `staffMarketProfile`, `schemeBook`, `personnelPackages`, `portalHub`,
  `retentionDecisions`, `portalMarket`, `nilAllocation`, `proScoutingBoard`, `draftBoard`,
  `freeAgency` — wrapper views never constructed, `navigate(_:in:)` collapses straight to the
  canonical destination with no alias-specific state preserved. Each would additionally need a
  genuinely new engine subsystem to become real (a staff-candidate pool, a scheme adoption-cost
  mechanic, a free-agency bidder/wave mechanism) — matching the owner's existing decision
  (`docs/plans/2026-08-19-62-screen-ia-action-truth-redesign.md`) to keep these aliased until that
  data exists. Do not build the underlying subsystems.
- **Nuance, not committed as separate work:** `jobBoard`, `offer`, `appointment` — wrapper views
  dead, but `navigate(_:in:)` does *not* redirect them, so old-save restoration could still land
  `CareerHubView` on their `focus` value, rendering the shared `opportunityWorkspace` composition —
  the same composition the definitely-live `.promotionDecision` route uses every time. Do not revive
  "Offer" as a distinct screen. The one substantive gap here (no decline action) is a genuine open
  design question canon doesn't resolve — flagged at the end, not committed.
- **Bonus hygiene item, folded into Phase 2:** `navigate(_:in:)` has its own, not-yet-fixed set of
  now-unreachable alias sub-patterns, parallel to what the prior phase already fixed in `career()`.

## Phase 1 — Data-correctness fixes

Six fixes that each correct a value the app already computes, but computes wrong or inconsistently
with itself. No new state, no new controls. Single- or two-file, mechanical.

### 1.1 News season contradiction
**File:** `Sources/FootballSimCore/History/NewsFeedReadModel.swift` (not `CoachWorldNewsProvider.swift`
— that file already adds `+ 1` correctly and matches the app-wide convention in
`CoachWorldReadModelProvider.seasonLabel(_:)`). Four case arms in `headline(for:names:)` interpolate
the raw, un-incremented `season` straight into engine-generated prose: `.seasonCompleted` (~line 88),
`.proMarketOpened` (~101), `.proDraftStarted` (~104), `.proMarketClosed` (~106). Change all four to
`season + 1`. Add a test asserting a `.seasonCompleted(season: 0, ...)` payload's headline contains
"Season 1", not "Season 0".

### 1.2 Cap gauge contradicts itself
**File:** `Sources/ProFootballCoachUI/ProManagementView.swift`. `committedShare` (~141-145) clamps
with `min(1, ...)` and that clamped value feeds both the arc gauge's `proportion:` (~118) and the
printed `figure:` percentage (~119), while the "Over the cap" text (~102) correctly uses the
unclamped `remainingCap`. Keep `proportion:` clamped (a ring cannot overflow) but add an unclamped
`committedPercent` computed property and use it for `figure:` only, so an over-cap team can show
"108%" instead of a self-contradicting "100%".

### 1.3 Roster impossible class balance
**File:** `Sources/ProFootballCoachUI/RosterView.swift`. `classBalance` (~780-786) buckets
`["FR","SO","JR","SR"]` from `academicYear`, computed unconditionally — pro rosters (no eligibility
concept, `academicYear` empty) show "FR 0 · SO 0 · JR 0 · SR 0" always, and college rosters silently
drop GR. Gate the whole cell to college rosters (verify the exact tier field/value on
`RosterReadModel` at edit time — likely mirrors the `tier` field other read models already carry) and
add the missing GR bucket when it renders. Confirm the exact `academicYear` string used for
graduate-eligible players before assuming `"GR"` is the literal token.

### 1.4 Three rating-colour scales disagree
**Files:** `Sources/ProFootballCoachUI/DesignTokens.swift`, `Sources/ProFootballCoachUI/CoachWorldVocabulary.swift`.
Canon (`docs/04-UX-AND-DESIGN-SYSTEM.md` §6.4 item 4, plus §6.1c's ink-role naming) is explicit: red
below 70, amber 70-84, green 85+, roles positive/warning/negative. `RosterView.ratingColor`
(`RosterView.swift:754-758`) already matches canon exactly — **do not touch it**, it is the reference.
`DesignTokens.Heat` (`:102-115`) has `steadyFloor = 72` (should be 70) and uses `stateLive`/
`actionPrimary` for the top two bands (should be `statePositive`/`stateWarning`).
`CoachWorldRatingRing.ringColor` (`CoachWorldVocabulary.swift:213-219`) has the same `72` threshold
and uses `actionPrimary` for the middle band (should be `stateWarning`). Fix both to match canon and
`RosterView`. `Heat.color` is already the de facto standard, called from 9 other files (PlayerProfile,
StaffRoom, GameDetailBoxScore, Aftermath, DevelopmentPlan, TeamProgrammeProfile, TeamHealth,
FloodlitPatterns) — they all just consume the returned `Color` and pick up the correction for free.
Add a test iterating every integer 40...99 asserting all three colour sources agree, not three sample
points (coverage-boundary rule).

### 1.5 Team Health inverts fatigue
**File:** `Sources/ProFootballCoachUI/TeamHealthView.swift`. `caseRow`'s single `proportionOf`
parameter (~197-202, definition ~225-241) drives both the bar's fill and its `Heat.color` tint; the
Fatigue call site passes `100 - fatigue` (freshness-framed) to that one parameter while the printed
text and accessibility label both use raw `fatigue` — so the bar visually disagrees with the number
beside it. Add a second, defaulted `heatValue: Int? = nil` parameter to `caseRow` so proportion and
tint can be decoupled; Condition's call site is unaffected (defaults to using `proportionOf` for
both, unchanged behavior); Fatigue's call site becomes
`caseRow("Fatigue", "\(subject.fatigue)%", value: subject.fatigue, heatValue: HealthMetric.fullPercent - subject.fatigue)`
— bar fill and text now agree (more fatigue → fuller, more alarming bar), while the tint still
correctly reads red-when-gassed via the separately-supplied inverted value.

### 1.6 Coaching HQ: "0 of N cleared" and fabricated "SATURDAY"
**File:** `Sources/ProFootballCoachUI/CoachingHQView.swift`. Both need the false claim removed, not a
hidden value found — confirmed no real backing data exists for either, by design, not oversight.

- Line ~262: `"0 of N cleared"` — the obligations array only ever holds currently-open items (a
  cleared decision is removed from the source list entirely, per `CoachWorldReadModelProvider.swift:80`),
  so there is no real cleared-count anywhere to read; the in-file comment at ~261 already documents
  this. Replace with `model.obligations.isEmpty ? "Nothing open this week" : "\(model.obligations.count) awaiting a decision"`.
  A true "N cleared" counter would need new per-week engine state — not committed here.
- Line ~804: `"SATURDAY · OPPONENT"` — the calendar's finest grain is a week; there is no day-of-week
  concept anywhere in the engine (confirmed by the provider's own comment). Change to `"NEXT FIXTURE"`,
  matching the equivalent label already used in this same file's AX5 `identityRail` (~494).

## Phase 2 — Control-behavior and dead-code fixes

Three "the interaction doesn't do what it visually promises" fixes, one DEBUG-only fixture
correction, one dead-code cleanup. No new persisted state.

### 2.1 Contract Negotiation submits superseded terms
**File:** `Sources/ProFootballCoachUI/ContractNegotiationView.swift`. `NegotiationCard`'s `init`
(~211-222) seeds `@State` once from `negotiation.currentOffer`; the parent `ForEach` (~101-107) has
no reseed hook, so after a counter-offer produces a new `currentOffer`, the displayed cost line
updates (it's a plain computed read) but the editable fields and the `counter` sent to the engine
stay on the stale values. `Contract` is already `Equatable`. Add
`.onChange(of: negotiation.currentOffer) { _, newOffer in years = newOffer.years; baseSalary = newOffer.baseSalaryByYear.first ?? 0; signingBonus = newOffer.signingBonus }`
to `NegotiationCard`'s body — the same idiom already used elsewhere in this codebase
(`ProOffseasonView.swift:64-65`, `CareerHubView.swift:85`, `RosterView.swift:72`, `MatchDayView.swift:514`).

### 2.2 Match Day fake three-way picker
**File:** `Sources/ProFootballCoachUI/MatchDayScoreBug.swift`. `ControlDepthSelector` (~329-374)
renders three labelled, individually-`.isSelected`-tagged cells that all call the identical
zero-argument `onSelect` closure. Two in-file/in-repo doc comments confirm the cycle is the
*intentional* design, not a shortcut (`MatchDayScoreBug.swift:323-328`, `ScreenReadModels.swift:1136-1139`
documenting `controlDepthIntentID` as furniture, not one of the five contract-fixed primary
controls). Do not build a real three-way picker (would mean changing `MatchDayReadModel`'s
contract-fixed control shape). Instead restyle to an honest single cycling control — one button
showing the current depth's title with a cycle affordance, single accessibility label/hint — matching
this same file's existing `speedCycleButton` pattern. Presentation-only diff; wiring untouched.

### 2.3 Match Day halftime always shown
**File:** `Sources/ProFootballCoachUI/MatchDayView.swift`. Line ~237, the Tactics control is
permanently labelled `"HALFTIME · PLAN EDIT"` regardless of game state (confirmed by the in-file
comment at ~300: it's a literal port of one static mockup frame). The engine does compute a genuine
halftime signal (`MatchPauseBoundary.halftime`, `MatchReducer.swift:15-23`), but it is a one-shot
transition receipt (`MatchStepReceipt.boundary`) never captured anywhere in `Sources/CoachWorldApp`
and never persisted on `MatchSessionState` — confirmed absent by repo-wide search. Committed fix:
drop the false claim, change the label to `"PLAN EDIT"` (verify whether `presentation.title` for
`.tactics` is itself already an accurate string to reuse instead). Not committed: true
state-conditional gating needs new app-layer plumbing to capture and hold the boundary signal across
the pause point — flag as a follow-up if the owner wants a genuinely state-driven banner.

### 2.4 Dead-control UUID-guard pattern
**File:** `Sources/ProFootballCoachUI/LeagueMapReadModels.swift`. Six views
(`LeagueMapView.swift:539`, `ScheduleView.swift:117`, `StandingsView.swift:110`,
`CompetitionOverviewView.swift:124`, `WorldSearchView.swift:168`, `TeamProgrammeProfileView.swift:214`)
silently no-op when `UUID(uuidString: stableID)` fails to parse. Every production provider populates
`stableID` from `X.id.uuidString` — always valid. The only non-UUID IDs anywhere (`"team-carson"` and
siblings) live in the `#if DEBUG`-gated `CoachWorldLeagueMapSampleData` fixture (~208-336), a
reproducible screenshot-proof cast consumed by `RootView.swift`'s DEBUG-only proof harness — compiled
out of release entirely. Two-part fix:
1. Replace the fixture's slug-style `stableID`s with fixed, valid, still-distinguishable UUID
   literals (not random `UUID()` — the fixture's whole point is a stable, reproducible cast).
2. In all six production views, change the silent-return guard to compute the parsed `id` once and
   apply `.disabled(id == nil)` to the enclosing control — matching this codebase's own existing
   disabled-control idiom (`DepthChartView.swift:321`, `RosterView.swift:227`) — so a malformed id
   (which the type system doesn't rule out, even though production data is always well-formed)
   presents as visibly inert rather than silently inert.

Before editing, confirm via `RootView.swift` which of the six views' DEBUG previews actually consume
this specific fixture versus a sibling sample set.

### 2.5 `navigate()` hygiene cleanup
**File:** `Sources/CoachWorldApp/CoachWorldAppRootView.swift`. `navigate(_:in:)` (~961-1173) opens
with an early-return that canonicalizes and recurses for any alias destination before reaching its
own `switch` — so several case arms below it can never execute, the same defect class already fixed
in `career()`. Delete the fully-dead arms (draftBoard/freeAgency/proScoutingBoard, ~1085-1090;
schemeBook/personnelPackages, ~1101-1105; portalHub/retentionDecisions/portalMarket/nilAllocation,
~1110-1116; jobBoard/offer/appointment, ~1132-1138) and the dead sub-patterns within two partially-live
arms (`.staffMarketProfile` out of the staffRoom arm at ~1097; `.jobSecurity`/`.coachingCarousel` out
of the stakeholders/promotionDecision arm at ~1139-1148 — simplify that arm's body from the
now-always-false ternary to the unconditional `careerFocus = destination`). If the prior phase added
an exhaustiveness/source-scanning test guarding `career()`'s switch against this class of dead code,
extend or mirror it here.

## Phase 3 — New reachable controls

Four fixes that add a genuinely new, reachable interactive surface. Highest-scrutiny phase — these
change what a user can do, not just what a screen says.

### 3.1 DepthChart P0 (`docs/reviews/2026-08-19-full-surface-adversarial-review.md` §6.1)
**File:** `Sources/ProFootballCoachUI/DepthChartView.swift`. `token(_:)` (~168-216) holds the only
writer of `openPositionID`, inside `fieldDiagram` (~115-141), which is unconditionally
`.accessibilityHidden(true)` (~140, at every type size, not only AX) and additionally isn't
constructed at all when `dynamicTypeSize.isAccessibilitySize` (~60-65). `openGroup` (~104-106) falls
back to `visibleGroups.first` — the unit pills reach one group per unit (3 of 15), and nothing
reaches the other 12. Add a genuinely reachable position-group selector — a row of labelled buttons
over `visibleGroups` (label via `DepthPlacement.abbreviation(for:)`, styled like `unitBar`'s
`FloodlitPill` row, ~81-97), setting `openPositionID` on tap — placed immediately above
`positionList` so it renders in **both** the AX and default compositions (both already call
`positionList`, at ~63 and ~70). Mark the open group `.isSelected`, matching `slotRow`/`optionList`'s
existing pattern. Delete or narrow the deferred-scope comment at ~174-181 once this lands. Add a test
confirming the selector is present and reachable in the accessible composition specifically, not only
the standard layout.

### 3.2 Coaching HQ cannot advance the week at AX5
**File:** `Sources/ProFootballCoachUI/CoachingHQView.swift`. Two advance-week controls exist:
`worldStrip`'s `continueButton` (~209-224), reachable from both compositions but only `if chrome ==
nil`; and `supportColumn`'s `FloodlitCommittingAction("Advance", ...)` (~446), reachable
unconditionally but only from the non-AX5 `standardLayout`. Every shipped `CoachingHQView` receives a
real, non-nil `chrome` (confirmed by this file's own doc comments describing `chrome == nil` as the
pre-conversion bare-stage fallback) — so `accessibleLayout` (~452-471) has **no unconditional**
advance control at all, and also never surfaces `model.squadHealth`/`model.stakeholders` or the full
obligations list (those are `supportColumn`/`weekAgendaColumn`-only). Two changes:
1. Add an unconditional `FloodlitCommittingAction("Advance", isEnabled: canAdvance, action: onContinue)`
   directly into `accessibleLayout`'s `VStack`, not gated on `chrome`.
2. `weekAgendaColumn` and `supportColumn` only receive fixed widths at their *call sites* in
   `standardLayout` — call both bare (no `.frame(width:)`) inside `accessibleLayout` so they flow
   full-width, giving AX5 users the full obligations list, squad health, and stakeholders content
   without inventing a new composition.

Re-verify `chrome`'s actual nil-ness at every `CoachingHQView(...)` construction site in
`CoachWorldAppRootView.swift` before finalizing.

### 3.3 Withdraw is destructive with no confirmation
**File:** `Sources/ProFootballCoachUI/RecruitingBoardView.swift` (view-layer only — `CollegeState.withdraw(_:)`
in `Sources/FootballSimCore/College/CollegeState.swift:198-206` needs no change; confirmation is a UI
concern). `actionDesk(_:)` (~775-800) dispatches every choice, including Withdraw, through one
generic button with no per-choice handling, and the withdraw choice is labelled `"No cost"` (~387)
despite discarding accumulated interest, visit, and scholarship state. Mirror `CareerHubView`'s two
existing confirmation idioms: its destructive-role/cancel button pair (`showingResignConfirmation`,
~27, 76-84) for styling and copy convention, and its `.alert(item:)` pattern (`pendingOpportunity`,
~58-75) for carrying which specific prospect is being withdrawn (`RecruitingBoardReadModel.Prospect`
is `Equatable` but not `Identifiable` — add a small view-local `Identifiable` wrapper struct rather
than changing the shared read-model type). Correct the `"No cost"` label to something honest about
the consequence.

### 3.4 Title/Continue never shows a career or offers Continue
**Files:** `Sources/CoachWorldApp/CoachWorldAppRootView.swift`, `Sources/ProFootballCoachUI/TitleContinueView.swift`.
`restoreExistingCareer()` (~1212-1258) sets `store` and, in the same synchronous run, immediately
jumps `screen` into gameplay — `store.careerHub` is already fully populated by that point
(`CoachWorldStore.swift:42`, `rebuildScreens(from:)`), it's just never shown. Add a
`@State private var careerConfirmed = false` gate; change `body`'s dispatch to
`if let store, careerConfirmed { career(store) } else ...`; set `careerConfirmed = true` in
`startNewCareer(...)` (a fresh career needs no redundant confirmation) but *not* automatically inside
`restoreExistingCareer()`. Extend `TitleContinueView` with `restoredCareer: CareerHubReadModel?` and
`onContinue: () -> Void`; when a restored career is present and no loading/recovery state applies,
render a summary (coach name, status, current job or "Between appointments", appointment count — the
same fields `CareerHubView.identityColumn` already surfaces) with a primary Continue button and a
secondary destructive "Start a new career instead" reusing the exact warning sentence already present
in `recoveryActions` (~90-93).

## Phase 4 — Read-model/engine extensions

The four largest items — each adds a field sourced either from state the engine already computes and
discards, or from one small new persisted value. Each needs decode-compatibility handling.

### 4.1 Recruiting "Committed" doesn't say to whom
**Files:** `Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift`,
`Sources/ProFootballCoachUI/ScreenReadModels.swift`, `Sources/ProFootballCoachUI/ClassOverviewView.swift`.
`statusLabel(_:in:)` (~214-221) switches on `.phase` alone, so a prospect committed to a rival still
reads "Committed". The same file already has the correct check for the identical situation, at the
withdraw choice's availability (~389-390): `recruitment?.programmeID != programmeID`. Give
`statusLabel` a `programmeID` parameter and apply that same comparison. Rather than leave
`ClassOverviewView.committedProspects` (~91-93) matching the presentation string, add a real
`isCommitted: Bool` field to `RecruitingBoardReadModel.Prospect` (~1031-1066), computed once
alongside `status:`, and filter on that field instead. Check for a second `Prospect` construction
site (a `discovery` list of not-yet-engaged prospects) that would need the field threaded too
(trivially `false` there).

### 4.2 Rankings & Playoff Picture: no seed, cut line, or bid context
**Files:** `Sources/ProFootballCoachUI/ScreenReadModels.swift`,
`Sources/CoachWorldApp/CoachWorldCompetitionProvider.swift`,
`Sources/FootballSimCore/Rules/ProRules/ProRules.swift`. `RankingRow` (~902-917) holds only whole-tier
`rank` — insufficient for pro, whose bracket is top-4 *per conference*
(`PostseasonSystem.swift:82-88`), not top-8 overall, so a team ranked outside the top 8 overall can
still hold a bracket seed. Name the existing raw-literal `4` as a real constant:
`ProRules.playoffSeedsPerConference = 4` (beside `bracketTeams = 8`), used at its two real sites
(`PostseasonSystem.swift:86`, `WorldIntegrity.swift:2183` — not `AbstractGameSimulator.swift:237`,
which is an unrelated top-4-pass-catchers computation). Extend `RankingRow` with `seed: Int`,
`qualifyingSlots: Int`, `isQualifying: Bool`. In `CoachWorldCompetitionProvider`, compute `seed` as
`rank` for college (single group already) and as a per-conference re-index mirroring
`PostseasonSystem`'s own selection logic for pro, so the read model's seed is guaranteed to agree
with what actually determines the bracket. Update the view to print seed/cut-line context. Add a test
enumerating a full pro ranking across both conferences asserting the read model's seed/qualifying
computation matches `PostseasonSystem`'s actual entrant selection for the same state.

### 4.3 Stakeholders panel is a static, contentless sentence (review C-1, live remainder)
**Files:** `Sources/FootballSimCore/Career/CareerArcState.swift`,
`Sources/ProFootballCoachUI/ScreenReadModels.swift`,
`Sources/CoachWorldApp/CoachWorldCareerProvider.swift`, `Sources/ProFootballCoachUI/CareerHubView.swift`.
Of C-1's four originally-cited routes only `.stakeholders` and `.promotionDecision` are live;
`.promotionDecision` already renders a real composition. `.stakeholders`' panel (~231-238) is a
hardcoded sentence. `CareerArcSystem.evaluateWeek`/`evaluateSeasonEnd`
(`CareerArcState.swift:351-360`, `388-397`) already compute a real per-stakeholder signed `bias`
immediately before folding it into `stakeholderSupport` via `applySupport(deltas:)` (~195-210) and
discarding it. `CareerArcState` already uses manual `Codable` (not synthesized) — the established
decode-compat mechanism in this codebase. Add `stakeholderLastMovement: [CareerStakeholder: Int]`
(defaults to `[:]` on decode for old saves), populate it inside `applySupport` with no signature
change (confirmed both production call sites and the one test call site pass deltas the same way).
Add `rationale: String?` to `CareerHubReadModel.SupportRow`, synthesized in
`CoachWorldCareerProvider` as a plain, mechanically-derived sentence from the signed delta (no
invented narrative, matching this codebase's "don't invent evidence" convention). Replace
`CareerHubView`'s hardcoded `.stakeholders` sentence with a per-stakeholder list using this data,
styled like the existing `historyRows` pattern. Note in the commit message that this incidentally
also resolves the excluded, lower-severity C-4 ("Stakeholders adds nothing over Career Hub") as a
side effect — do not scope C-4 separately. Add tests: `applySupport` records exactly the deltas
passed, for arbitrary dictionaries; a decode-compat test for old-save JSON missing the new key.

### 4.4 Settings & Accessibility ships zero actual choices
**Files:** `docs/02-GAME-DESIGN.md` (doc-first note, small), `Sources/FootballSimCore/Intent/IntentResolver.swift`,
`Sources/ProFootballCoachUI/SettingsAccessibilityView.swift`, plus wherever persisted per-save
preferences already live (verify at edit time — likely alongside `CareerPresentationState`/
`CareerSaveMetadata`, not `GameState`/`CareerArcState`, since this is a presentation/pacing
preference, not simulation state). The one concrete, canon-named, buildable setting is the call-in
rate: `docs/02-GAME-DESIGN.md` §3.1 already states a default (~25) and bound (12-40,
`SharedRules.callInsPerGameRange`/`defaultCallInsPerGame`), but nothing stores or lets the player
change a per-save value — the constant is referenced only at its own declaration. Per CLAUDE.md's
doc-first rule: first add a one-line note to §3.1 naming this a per-save, player-adjustable setting
within the existing bound (mechanical — the default/bound are already canon-stated, only
storage-location/scope is new, not an owner-escalation question). Then: a persisted field at whatever
the correct save-schema home turns out to be; a new mutation path (a `CoachIntent` case only if the
value genuinely needs to round-trip through `GameState` — check whether it can live entirely in
save/presentation metadata instead, which would need a simpler non-`CoachIntent` path); a real
`Stepper`/`Slider` control on `SettingsAccessibilityView`, ranged by the existing rules constant (no
magic numbers in the view). Confirm how the chosen rate should flow into a live match's call-in
budget (`CallInBudget` construction near `ScreenReadModels.swift:2225`) before wiring the control.

## Excluded from scope

Listed transparently, not silently dropped.

**P2/P3, even where live and cheap:** A-1 (rating rendered as a proportion arc, `RosterView.swift:510`,
`StaffRoomView.swift:109`); C-4 (Stakeholders — likely incidentally resolved by 4.3, not committed
separately); C-5/C-6/C-7 (all `LegacyHistoryView.swift`: default-case header lie, fixed-width
no-reflow text, uniform "History" back-label across 4 routes); C-8/C-9 (empty-state-only handling,
defaulted no-op callbacks — both already refuted as live-safe in production by the review itself).

**Dead code, not live defects, no fix needed:** C-2 (Job Security), C-3 (Coaching Carousel), and the
ten fully-dead aliased screens listed above under "Ground truth."

**Genuinely ambiguous, needs a doc-first/owner call before it's even confirmed a defect:** whether an
explicit decline action belongs on the `opportunityWorkspace` composition (review §6.3, "Offer") —
canon doesn't resolve it, and offers already carry an `expires` field, so implicit decline-via-expiry
may be the intended design.

## Verification

No `swift`/`xcodebuild` exists here — nothing below can be run in this environment, and no claim of
"green" may be made from it. CI is the compiler.

1. One phase at a time, per `CLAUDE.md`: implement, adversarially review the diff, fix confirmed
   findings, commit (small, Conventional Commits, one task each), then proceed to the next phase.
2. Where a fix corrects a value that should hold across a whole class of inputs, the test enumerates
   that class by construction (rating colours across 40...99, rankings across a full generated
   league) rather than hand-listing samples — per `CLAUDE.md`'s coverage-boundary rule.
3. Push after each phase and let CI run (`scripts/verify.sh` full lane). Treat any newly-red gate as
   real work, not noise, after re-confirming it isn't a pre-existing/unrelated failure.
4. Record every touched file in `docs/STATUS.md` as unverified — never compiled, per phase.
5. **Owner action, cannot be delegated:** build to a simulator and confirm the four Phase 3 controls
   (DepthChart's new selector, Coaching HQ's AX5 advance control, Withdraw's confirmation, Continue's
   new flow) are actually reachable and behave as designed. Source-level correctness is as far as
   this environment can verify.
