# Portal Knowledge Schema Version Two Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make college portal scouting estimate every attribute the match engine rates for a
position — including the receiver carrier attributes `vision` and `elusiveness` — without making
any existing schema-11/12/13 save undecodable.

**Architecture:** `CollegePortalPolicyV1.knowledgeAttributesByPosition` stays byte-identical and
keeps its name. Version two is expressed as a **recorded per-position delta appended to version
one**, not as a second full table: two tables repeating thirteen identical positions can drift by
someone editing one, which is the exact defect this versioning exists to prevent. Because the
delta is appended, version two's array is version one's array plus additions — the first twelve
RNG draws of a receiver's estimate are unchanged and only the two new draws and the trailing
`estimatedPotential` draw move.

`CollegePortalKnowledgeSnapshot.isValid` accepts a snapshot whose attribute key set matches
**either** table for its position. The key set is self-describing — the two tables differ exactly
at `wideReceiver` and `tightEnd` — so no per-snapshot version field is needed. This is the whole
reason the design avoids a version field: `ScoutingState.portalKnowledgeByObserver` is bounded at
`maximumKnowledgeObservers` (134) x `maximumKnowledgePerObserverWindow` (300) x
`portalWindowCount` (2) = 80,400 persisted snapshots, so a `"knowledgeVersion":2` key would add
roughly 20 bytes each against a save the D7 falsifier already measured at 2.3 MB under an 8 MB
ceiling. Set-matching costs zero bytes.

Consequently **no schema version moves**: `GameState.schemaVersion` stays 13 and
`CollegeRules.portalPolicyVersion` stays 1. Bumping `portalPolicyVersion` would be wrong — the
`supports` gate is `policyVersion == version`, so a bump makes every stored offer, intent and
window record from an existing save unsupported, and nothing about the admission or fit formulas
changed.

**Tech Stack:** Swift 5.10+, `FootballSimCore` (pure, no SwiftUI), TestKit executable harness
(`Tests/SimTests`), `scripts/verify.sh` lanes.

**Spec:** `docs/02-GAME-DESIGN.md` section 4.3 (recruiting fog) as amended by Task 1 of this plan;
`docs/03-MATCH-ENGINE.md` section 1.2 (which attributes each matchup reads);
`docs/03b-ARCHITECTURE.md` section 4 (forward-only, one-step save migrations).

## Global Constraints

- Ratings are 40-99 `Int`. Money is integer dollars. No floating-point currency.
- No emoji in code, UI copy, commits or docs.
- Engine code is pure Swift with zero `import SwiftUI`.
- Determinism: a given seed plus a given input state reproduces a match exactly, across processes
  and app launches. Seeds derive from identifier bytes, never `hashValue`.
- TDD for all engine code: every mechanic gets a failing test first.
- One task = one commit, Conventional Commits format.
- Doc-first amendment rule: a gameplay question not answered in canon gets answered in canon
  first, then implemented. Task 1 exists because of this rule and must not be reordered.
- No design-token literals in views; rules constants live in a rules module, never inlined.
- Scope guard: build what this plan specifies. `CollegePortalPolicyV1`'s admission and fit
  formulas, `minimumPlayableRosterByPosition`, and `CollegeRules.portalPolicyVersion` are **out of
  scope** and must not be touched.
- When there is no Swift toolchain: write the code to the same standard, record it in
  `docs/STATUS.md` as **unverified - never compiled** naming the files, and never say "build
  green", "tests pass" or "verified". A gate that depends on a build becomes an escalation.

---

### Task 1: Answer the question in canon

The doc-first amendment rule makes this the first task. `docs/02-GAME-DESIGN.md` describes
recruiting fog for high-school recruits (section 4.3) and the portal (section 4.1) but nowhere
says which attributes portal scouting estimates. Until canon says so, changing the code encodes a
design decision only in code.

**Files:**
- Modify: `docs/02-GAME-DESIGN.md` (insert new section 4.3a after section 4.3, which ends at the
  `---` preceding `## 5. Ratings, progression, development`)
- `docs/DOC-MANIFEST.md` is **not** modified. Its section 4 table is a purpose register with a
  `purpose` column, not a changelog, and its only other row for `02` records the DELETED
  predecessor. `02`'s own heading convention carries amendment dates (`### 4.2a ... added
  2026-08-12`, `### 4.1a ... added 2026-08-13`), and section 4.3a follows it.

- [ ] **Step 1: Insert section 4.3a into `docs/02-GAME-DESIGN.md`**

Insert immediately before the `---` that closes section 4.3:

```markdown
### 4.3a Portal scouting fidelity — added 2026-08-23

Portal scouting estimates **every attribute the match engine rates for that position**, and no
others. The estimate is fogged — each attribute is offset by a draw whose radius narrows with
confidence, exactly as section 4.3's fog works for high-school recruits — but the *set* of
attributes shown is complete. Fog is the information asymmetry; a missing column is not.

This is written down because it was silently false. Commit `3bba7c9` gave receivers and tight ends
`vision` and `elusiveness`, because a receiver with the ball is a carrier and `03` section 1.2's
carrier-versus-pursuit row names both. The portal's frozen estimate table was not updated, so
portal scouting read receivers on 12 of the 14 attributes the engine rates them on. The blind spot
was uniform: a 99-recruiting staff got it identically to a 40, and the two hidden attributes are
precisely what separate a possession receiver from an explosive one. That is a missing column, not
fog.

**The estimate set is versioned, and a stored estimate keeps the set it was taken with.** A
snapshot persisted before this change keeps its 12 attributes and stays readable; a snapshot taken
after it carries all 14. The two sets are distinguishable from the snapshot itself, so nothing has
to be written into the save to tell them apart, and no save is invalidated. A re-scout replaces an
old-set estimate with a current-set one.

The set is **not** derived live from `Position.ratedAttributes` at validation time. Deriving it
live is what broke: a stored record's validity would change whenever a balance pass touched the
rating model, and a save written last month would stop decoding this month.
```

- [ ] **Step 2: Verify no canon conflict**

Run:

```bash
grep -rn "portal" docs/03-MATCH-ENGINE.md docs/OPEN-DECISIONS.md | grep -i "scout\|knowledg\|estimat"
```

Expected: no line that contradicts section 4.3a. If a line does contradict it, **stop and escalate
to the owner** — CLAUDE.md says a canon conflict is a defect to escalate, not to resolve by
picking a winner.

- [ ] **Step 3: Commit**

```bash
git add docs/02-GAME-DESIGN.md
git commit -m "docs: state that portal scouting estimates the full rated set"
```

---

### Task 2: Define the version-two attribute table as a delta over version one

**Files:**
- Modify: `Sources/FootballSimCore/College/CollegePortalPolicyV1.swift` (add after the
  `knowledgeAttributesByPosition` literal ending at line 179, and after the existing
  `ratedAttributes(for:)` at line 376)
- Test: `Tests/SimTests/Suites/PortalContractTests.swift` (the
  `frozen portal policy tables diverge from live rules only where recorded` test added
  2026-08-23, near line 1641)

**Interfaces:**
- Consumes: `CollegePortalPolicyV1.ratedAttributes(for:) -> [Attribute]` (existing, unchanged) and
  `Position.ratedAttributes -> [Attribute]` (existing, unchanged).
- Produces: `CollegePortalPolicyV1.currentRatedAttributes(for position: Position) -> [Attribute]`,
  `package static`. Returns version one's array for that position with the version-two additions
  appended, so `currentRatedAttributes(for:)` is order-equal to `position.ratedAttributes` and has
  `ratedAttributes(for:)` as a prefix. Tasks 3 and 4 both call it.

- [ ] **Step 1: Write the failing test**

Replace the body of the existing test `frozen portal policy tables diverge from live rules only
where recorded` in `Tests/SimTests/Suites/PortalContractTests.swift` so that it now pins version
two against the live rating model instead of recording a divergence. Keep the roster-floor limb
exactly as it is; it is unrelated to this plan and out of scope.

```swift
        test("frozen portal policy tables diverge from live rules only where recorded") {
            // CollegePortalPolicyV1 freezes its own copies of two tables so a schema-six career
            // record stays decodable when a balance pass moves the live rules. A freeze that
            // nothing watches is indistinguishable from a table someone forgot to update, so both
            // sides are enumerated here by construction over Position.allCases: a new position, or
            // a new divergence at an existing one, fails this test naming the position rather than
            // tripping CollegePortalKnowledgeSnapshot's precondition and killing the process.
            //
            // Version one keeps its recorded divergence forever -- that is what makes an existing
            // save readable. Version two is what production writes, and 02 section 4.3a requires
            // it to equal the rated set exactly, in order.
            let versionOneDivergence: [Position: Set<Attribute>] = [
                // 3bba7c9 gave receivers vision and elusiveness because a receiver with the ball is
                // a carrier. Version one was already frozen and cannot gain them.
                .wideReceiver: [.vision, .elusiveness],
                .tightEnd: [.vision, .elusiveness],
            ]
            let knownRosterDivergence: [Position: Int] = [
                // SharedRules raised both floors after the frozen copy was taken: linebacker on
                // 2026-08-20 for the third starter the defence fields, running back on 2026-08-22
                // for the reserve carrier the run resolver picks. Both were raised because nothing
                // compared the constant against the formation -- see the note on
                // SharedRules.minimumPlayableRosterByPosition.
                .runningBack: 1,
                .linebacker: 2,
            ]
            for position in Position.allCases {
                let versionOne = CollegePortalPolicyV1.ratedAttributes(for: position)
                let current = CollegePortalPolicyV1.currentRatedAttributes(for: position)
                let live = position.ratedAttributes
                expect(!versionOne.isEmpty, "\(position) has no frozen knowledge attributes")
                expectEqual(
                    Set(versionOne).subtracting(live),
                    [],
                    "\(position) version one scouts an attribute the engine does not rate"
                )
                expectEqual(
                    Set(live).subtracting(Set(versionOne)),
                    versionOneDivergence[position] ?? [],
                    "\(position) version-one divergence from the rated set changed"
                )
                // 02 section 4.3a: the current set is the rated set, exactly and in order.
                // Array equality rather than set equality, because knowledgeSnapshot draws one
                // rng.int per element in order -- reordering silently rewrites every estimate.
                expectEqual(
                    current,
                    live,
                    "\(position) current knowledge set drifted from the rated set"
                )
                // The append is what keeps version one's draws unchanged.
                expect(
                    current.starts(with: versionOne),
                    "\(position) current set is not version one's order plus additions"
                )
                expectEqual(
                    CollegePortalPolicyV1.minimumPlayableRosterByPosition[position],
                    knownRosterDivergence[position]
                        ?? SharedRules.minimumPlayableRosterByPosition[position],
                    "\(position) frozen roster floor drifted from SharedRules"
                )
            }
        }
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
swift run -c release -Xswiftc -enable-testing SimTests --portal-contracts
```

Expected: FAIL to **compile**, with `type 'CollegePortalPolicyV1' has no member
'currentRatedAttributes'`. A compile failure is the correct red here — the symbol does not exist
yet.

- [ ] **Step 3: Write the minimal implementation**

In `Sources/FootballSimCore/College/CollegePortalPolicyV1.swift`, immediately after the closing
`]` of the `knowledgeAttributesByPosition` literal, add:

```swift
    /// Version two adds the carrier attributes receivers gained in `3bba7c9`, recorded as a delta
    /// over version one rather than as a second full table.
    ///
    /// A second full table would repeat thirteen identical positions, and two tables that repeat
    /// each other drift when somebody edits one -- which is precisely the defect this versioning
    /// exists to prevent, and precisely how the version-one table came to disagree with the rating
    /// model in the first place. A delta cannot drift: it names only what changed.
    ///
    /// Appended, never inserted. `knowledgeSnapshot` draws one `rng.int` per element in array
    /// order, so appending leaves version one's draws bit-identical and moves only the two new
    /// draws and the trailing potential draw. Inserting would silently rewrite every estimate for
    /// the position.
    private static let knowledgeAttributeAdditionsV2: [Position: [Attribute]] = [
        .wideReceiver: [.vision, .elusiveness],
        .tightEnd: [.vision, .elusiveness],
    ]
```

Then, immediately after the existing `ratedAttributes(for:)` function, add:

```swift
    /// The attribute set portal scouting estimates today -- `02` section 4.3a's "every attribute
    /// the match engine rates for that position, and no others".
    ///
    /// `ratedAttributes(for:)` remains the version-one set and stays frozen: an estimate persisted
    /// before this version keeps its own set and stays decodable.
    package static func currentRatedAttributes(for position: Position) -> [Attribute] {
        ratedAttributes(for: position) + (knowledgeAttributeAdditionsV2[position] ?? [])
    }
```

- [ ] **Step 4: Run the test to verify it passes**

Run:

```bash
swift run -c release -Xswiftc -enable-testing SimTests --portal-contracts
```

Expected: PASS, and the suite ends with TestKit's `all passed` summary line. A run that ends
without that line did not complete, whatever its exit code.

- [ ] **Step 5: Commit**

```bash
git add Sources/FootballSimCore/College/CollegePortalPolicyV1.swift Tests/SimTests/Suites/PortalContractTests.swift
git commit -m "feat: define version-two portal knowledge attributes as a delta over version one"
```

---

### Task 3: Accept either attribute set when validating a snapshot

Nothing writes the version-two set yet. This task only widens what decodes, so that Task 4's
production change cannot make an existing save unreadable and cannot kill the test process at a
precondition.

**Files:**
- Modify: `Sources/FootballSimCore/College/CollegePortalState.swift:405-407` (the
  `ratedAttributes` binding and key-set guard inside
  `CollegePortalKnowledgeSnapshot.isValid`)
- Test: `Tests/SimTests/Suites/PortalContractTests.swift` (new test in `runPortalContractTests`)

**Interfaces:**
- Consumes: `CollegePortalPolicyV1.ratedAttributes(for:)` and
  `CollegePortalPolicyV1.currentRatedAttributes(for:)` from Task 2.
- Produces: no new symbols. `CollegePortalKnowledgeSnapshot.init` and `init(from:)` now accept a
  key set equal to either table for the position; every other validity rule is unchanged.

- [ ] **Step 1: Write the failing test**

Add to `runPortalContractTests` in `Tests/SimTests/Suites/PortalContractTests.swift`:

```swift
        test("a knowledge snapshot decodes under either version's attribute set") {
            let openedAt = CalendarState(season: 0, week: SharedRules.inSeasonWeeks)
            func snapshot(
                _ attributes: [Attribute],
                position: Position
            ) -> CollegePortalKnowledgeSnapshot {
                CollegePortalKnowledgeSnapshot(
                    observerProgrammeID: portalContractUUID(70),
                    playerID: portalContractUUID(71),
                    sourceProgrammeID: portalContractUUID(72),
                    targetSeason: 1,
                    window: .postseason,
                    position: position,
                    estimatedOverall: Rating(70),
                    estimatedAttributes: Dictionary(uniqueKeysWithValues:
                        attributes.map { ($0, Rating(70)) }
                    ),
                    estimatedPotential: Rating(75),
                    confidence: 25,
                    lastUpdated: openedAt,
                    evidenceCount: 1
                )
            }

            // Version one: what an existing save holds. Must stay decodable forever.
            let stored = snapshot(
                CollegePortalPolicyV1.ratedAttributes(for: .wideReceiver),
                position: .wideReceiver
            )
            expectEqual(stored.estimatedAttributes.count, 12)
            let storedData = try JSONEncoder.stable().encode(stored)
            expectEqual(try JSONDecoder.stable().decode(
                CollegePortalKnowledgeSnapshot.self, from: storedData
            ), stored)

            // Version two: what production writes after Task 4.
            let fresh = snapshot(
                CollegePortalPolicyV1.currentRatedAttributes(for: .wideReceiver),
                position: .wideReceiver
            )
            expectEqual(fresh.estimatedAttributes.count, 14)
            let freshData = try JSONEncoder.stable().encode(fresh)
            expectEqual(try JSONDecoder.stable().decode(
                CollegePortalKnowledgeSnapshot.self, from: freshData
            ), fresh)

            // Neither set: still rejected. Widening must not become "accept anything".
            var partial = try JSONSerialization.jsonObject(with: freshData) as! [String: Any]
            var attributes = partial["estimatedAttributes"] as! [String: Any]
            attributes.removeValue(forKey: Attribute.vision.rawValue)
            partial["estimatedAttributes"] = attributes
            do {
                _ = try JSONDecoder.stable().decode(
                    CollegePortalKnowledgeSnapshot.self,
                    from: JSONSerialization.data(withJSONObject: partial)
                )
                expect(false, "a snapshot matching neither version's set decoded")
            } catch {
                expect(true)
            }
        }
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
swift run -c release -Xswiftc -enable-testing SimTests --portal-contracts
```

Expected: the process dies with `CollegePortalState.swift:327: Precondition failed`, because
constructing `fresh` with 14 keys trips the version-one key-set check in `isValid`. This is the
red. Note that the whole process dies rather than one check failing — that is what a `precondition`
does, and it is why Task 3 comes before Task 4.

- [ ] **Step 3: Write the minimal implementation**

In `Sources/FootballSimCore/College/CollegePortalState.swift`, inside
`CollegePortalKnowledgeSnapshot.isValid`, replace:

```swift
        let ratedAttributes = CollegePortalPolicyV1.ratedAttributes(for: position)
        guard !ratedAttributes.isEmpty,
              Set(estimatedAttributes.keys) == Set(ratedAttributes) else { return false }
```

with:

```swift
        // 02 section 4.3a: a stored estimate keeps the set it was taken with. The two versions
        // differ only at wideReceiver and tightEnd, so the key set names its own version and
        // nothing has to be written into the save to tell them apart -- which matters, because
        // ScoutingState persists up to maximumKnowledgeObservers x
        // maximumKnowledgePerObserverWindow x portalWindowCount of these and a version field
        // would cost roughly 20 bytes each against D7's 8 MB ceiling.
        let versionOneAttributes = CollegePortalPolicyV1.ratedAttributes(for: position)
        let currentAttributes = CollegePortalPolicyV1.currentRatedAttributes(for: position)
        let keys = Set(estimatedAttributes.keys)
        guard !versionOneAttributes.isEmpty,
              keys == Set(versionOneAttributes) || keys == Set(currentAttributes)
        else { return false }
```

- [ ] **Step 4: Run the test to verify it passes**

Run:

```bash
for f in --portal-contracts --portal-policy --portal-matching --portal-transaction; do swift run -c release -Xswiftc -enable-testing SimTests "$f" || echo "RED: $f"; done
```

One flag per run. `Tests/SimTests/main.swift` dispatches suites through a single `if / else if`
chain, so passing several flags at once silently runs only whichever appears first in that chain
and reports green for suites that never executed.

Expected: every suite PASSes and each run ends with TestKit's `all passed` summary line.

- [ ] **Step 5: Commit**

```bash
git add Sources/FootballSimCore/College/CollegePortalState.swift Tests/SimTests/Suites/PortalContractTests.swift
git commit -m "feat: accept either portal knowledge attribute set when validating a snapshot"
```

---

### Task 4: Produce the version-two set from `knowledgeSnapshot`

This is the behaviour change. Everything before it was preparation.

**Files:**
- Modify: `Sources/FootballSimCore/College/CollegePortalPolicyV1.swift` — the
  `ratedAttributes(for: player.position).map` call inside
  `knowledgeSnapshot(observerProgrammeID:playerID:using:)`. It sits at line 513 today; Task 2's
  additions shift it, so find it by the function name, not the number.
- Test: `Tests/SimTests/Suites/PortalPolicyTests.swift` (new test in `runPortalPolicyTests`)

**Interfaces:**
- Consumes: `CollegePortalPolicyV1.currentRatedAttributes(for:)` from Task 2, and the widened
  `isValid` from Task 3.
- Produces: no new symbols. `knowledgeSnapshot` now returns snapshots whose
  `estimatedAttributes` key set is `currentRatedAttributes(for: player.position)`.

- [ ] **Step 1: Write the failing test**

Add to `runPortalPolicyTests` in `Tests/SimTests/Suites/PortalPolicyTests.swift`:

```swift
        test("portal knowledge estimates every attribute the engine rates") {
            // `base` is the file-level `portalPolicyFixture()` already in scope in
            // runPortalPolicyTests; `portalPolicySnapshot` is the file-level helper the
            // neighbouring tests use. Neither is new.
            let batch = portalPolicySnapshot(base.state)
            var covered: Set<Position> = []
            for intent in batch.intents {
                guard let snapshot = CollegePortalPolicyV1.knowledgeSnapshot(
                    observerProgrammeID: base.observerProgrammeID,
                    playerID: intent.playerID,
                    using: batch
                ) else { continue }
                covered.insert(snapshot.position)
                // 02 section 4.3a: the set is the rated set, not a subset of it.
                expectEqual(
                    Set(snapshot.estimatedAttributes.keys),
                    Set(snapshot.position.ratedAttributes),
                    "\(snapshot.position) estimate omits an attribute the engine rates"
                )
                expectEqual(
                    snapshot.estimatedOverall.value,
                    snapshot.estimatedAttributes.values.reduce(0) { $0 + $1.value }
                        / snapshot.estimatedAttributes.count
                )
            }
            // Without a receiver in the batch every assertion above is vacuous -- the two
            // attributes this whole change is about only exist at these two positions.
            expect(
                covered.contains(.wideReceiver) || covered.contains(.tightEnd),
                "the batch produced no receiver or tight end, so this test asserted nothing"
            )
        }
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
swift run -c release -Xswiftc -enable-testing SimTests --portal-policy
```

Expected: FAIL with `wideReceiver estimate omits an attribute the engine rates` (or the tightEnd
equivalent). Two other outcomes are possible and neither means you may proceed:

- FAIL with `the batch produced no receiver or tight end, so this test asserted nothing` — the
  fixture's batch has no receiver, so the test cannot see the change. Extend it: `base` comes from
  `portalPolicyFixture()`, which forces one player to `.quarterback` at
  `PortalPolicyTests.swift:24`. Add a receiver to the batch the same way rather than weakening the
  assertion, then re-run to see the red above.
- The process dies with `CollegePortalState.swift:327: Precondition failed` — Task 3 was not
  applied, or was applied wrongly. Fix Task 3 first; do not proceed.

- [ ] **Step 3: Write the minimal implementation**

In `knowledgeSnapshot`, change:

```swift
            ratedAttributes(for: player.position).map { attribute in
```

to:

```swift
            currentRatedAttributes(for: player.position).map { attribute in
```

- [ ] **Step 4: Run the test to verify it passes**

Run:

```bash
for f in --portal-policy --portal-contracts --portal-matching --portal-transaction --portal-scheduler; do swift run -c release -Xswiftc -enable-testing SimTests "$f" || echo "RED: $f"; done
```

One flag per run. `Tests/SimTests/main.swift` dispatches suites through a single `if / else if`
chain, so passing several flags at once silently runs only whichever appears first in that chain
and reports green for suites that never executed.

Expected: every suite PASSes and each run ends with `all passed`. If a portal suite fails on a
pinned expected value rather than on a contract, that is a moved pin — leave it failing, note the
suite and the old and new values, and fix it in Task 5. Do not re-pin here.

- [ ] **Step 5: Commit**

```bash
git add Sources/FootballSimCore/College/CollegePortalPolicyV1.swift Tests/SimTests/Suites/PortalPolicyTests.swift
git commit -m "feat: estimate receiver vision and elusiveness in portal scouting"
```

---

### Task 5: Measure the blast radius and re-pin what moved

`knowledgeSnapshot` seeds a fresh `SeededRandom` per (root, season, window, observer, source,
player), so the two extra draws do **not** shift any other player's estimate. Within a receiver's
own snapshot they do move `estimatedPotential` (drawn after the attribute loop) and
`estimatedOverall` (a mean over 14 values, not 12).

`CollegePortalMatchingV1.swift:361` feeds that snapshot straight into
`CollegePortalAdmissionEvidence` and `CollegePortalDestinationEvidence`, so receiver and tight-end
portal offers change, which changes who transfers, which changes rosters, which changes season
results. `observedSchemeFit` reads `knowledge.estimatedAttributes[.schemeFit]`, a **shared**
attribute at a fixed index before the additions, so it is unchanged.

This task measures that rather than predicting it.

**Files:**
- Modify: whichever pinned expectations the lanes report as moved. Likely candidates, to check
  first: `Tests/SimTests/Suites/M3RecruitingCalibrationTests.swift`,
  `Tests/SimTests/Suites/PortalMatchingTests.swift`,
  `Tests/SimTests/Suites/PortalContractTests.swift` (the `[10, 5, 6, 5, 5, -7]` component pin at
  roughly line 880 is quarterback-based and should **not** move; if it does, stop — something is
  wrong with the append order).
- Modify: `docs/STATUS.md`

- [ ] **Step 1: Run every lane and capture the output**

```bash
./scripts/verify.sh --lane core 2>&1 | tee /tmp/lane-core.log
```

```bash
./scripts/verify.sh --lane determinism 2>&1 | tee /tmp/lane-determinism.log
```

```bash
./scripts/verify.sh --lane calibration 2>&1 | tee /tmp/lane-calibration.log
```

```bash
./scripts/verify.sh --lane soaks 2>&1 | tee /tmp/lane-soaks.log
```

The soak lane is a real 20-85 minute run per soak, not a hang. Let it finish.

- [ ] **Step 2: Confirm each run actually completed**

```bash
for f in /tmp/lane-core.log /tmp/lane-determinism.log /tmp/lane-calibration.log /tmp/lane-soaks.log; do printf '%s: ' "$f"; tail -3 "$f" | grep -c 'all passed\|failed check'; done
```

Expected: `1` for each file. A lane whose log ends without TestKit's summary line aborted
silently and its result means nothing — re-run it before reading anything into it. Exit code alone
is not sufficient evidence.

- [ ] **Step 3: Record every moved pin before changing any of them**

For each failing check, write one line to `/tmp/moved-pins.txt` in the form
`<suite> <file>:<line> <old> -> <new>`. Do this for all of them first. Re-pinning one at a time
while running the suite in between makes it impossible to tell a genuine regression from an
expected shift.

- [ ] **Step 4: Re-pin, and justify each one in its own comment**

For each line in `/tmp/moved-pins.txt`, update the expected value and add a comment above it
naming why it moved. For example:

```swift
            // Moved 2026-08-23: portal scouting gained receiver vision and elusiveness (02 section
            // 4.3a), so receiver estimatedPotential draws after two more rng.int calls and
            // receiver transfer decisions differ. Old value: 41.
```

A re-pin with no comment is indistinguishable from a regression somebody silenced.

- [ ] **Step 5: Escalate any band that left its calibration range**

A moved *pin* is expected. A calibration **band** that no longer holds is not — it means receiver
scouting fidelity changed league outcomes beyond the design's stated tolerance. If any band in
`--calibration` or `--m3-recruiting-calibration` fails, **stop and escalate to the owner** with
the band name, its range, and the observed value. Do not widen a band to make it pass.

- [ ] **Step 6: Re-run every lane and confirm green**

```bash
./scripts/verify.sh --lane core && ./scripts/verify.sh --lane determinism && ./scripts/verify.sh --lane calibration && ./scripts/verify.sh --lane soaks
```

Expected: every lane green, every log ending in TestKit's summary line.

- [ ] **Step 7: Update `docs/STATUS.md`**

Add, under the portal/college section, stating only what a machine actually verified:

```markdown
- Portal scouting estimates the full rated attribute set per position as of 2026-08-23
  (`02` section 4.3a). Version-one estimates in existing saves stay decodable and keep their own
  set; `GameState.schemaVersion` and `CollegeRules.portalPolicyVersion` are unchanged. Verified:
  core, determinism, calibration and soak lanes green.
```

- [ ] **Step 8: Commit**

```bash
git add Tests/SimTests/Suites docs/STATUS.md
git commit -m "test: re-pin the expectations receiver portal scouting moved"
```

---

### Task 6: Adversarial review and the phase gate

**Files:**
- Modify: none expected. Fix whatever confirmed findings the review produces.

- [ ] **Step 1: Run the adversarial review on the phase diff**

```bash
git diff main...HEAD
```

Then run the `adversarial-reviewer` skill against that diff. An adversarial review is **not** a
build and must never be reported as one.

- [ ] **Step 2: Fix confirmed findings, dismiss the rest with a reason**

Fix confirmed findings first. For each finding not fixed, record one line saying why it is not a
defect.

- [ ] **Step 3: Assert the machine gates**

Use the `superpowers:verification-before-completion` skill. The gates, from CLAUDE.md:

- build green
- tests green
- calibration bands hold
- cross-process determinism
- the soak
- the two legal tests (name collision, trade dress)
- touched surfaces score >= 31/40 with zero P0/P1 against `docs/04b-AUDIT-RUBRIC.md` (eight
  dimensions, 0-5 each — **not** the older >= 17/20 five-dimension frame, which the owner replaced
  on 2026-08-11; 31/40 is 77.5 percent and 17/20 is 85 percent, so the two bars are not
  equivalent)

This phase touches no UI surface, so the rubric limb applies only if a view changed. If none did,
say so explicitly rather than claiming a score.

- [ ] **Step 4: Confirm no unintended symbol moved**

```bash
node .gitnexus/run.cjs analyze
```

Then run `detect_changes({scope: "compare", base_ref: "main"})` and confirm the changed-symbol
list contains only: `CollegePortalPolicyV1`, `currentRatedAttributes`,
`knowledgeAttributeAdditionsV2`, `knowledgeSnapshot`, `CollegePortalKnowledgeSnapshot.isValid`,
and the test functions. Anything else is scope leakage — revert it.

- [ ] **Step 5: Commit any review fixes**

```bash
git add -A
git commit -m "fix: address adversarial review findings on portal knowledge version two"
```

---

## What this plan deliberately does not do

- **Does not bump `CollegeRules.portalPolicyVersion`.** `CollegePortalPolicyV1.supports` is
  `policyVersion == version`, so a bump makes every stored offer, intent and window record
  unsupported and refuses existing saves. No admission or fit formula changed, so there is nothing
  for a policy version two to mean.
- **Does not bump `GameState.schemaVersion`.** The knowledge key set is self-describing, so
  schema 13 keeps one meaning across both estimate sets. Add a bump when a future change makes an
  old and a new record genuinely indistinguishable on the wire.
- **Does not add a per-snapshot version field.** Roughly 20 bytes x up to 80,400 persisted
  snapshots against a 2.3 MB save under D7's 8 MB ceiling, to encode something the key set already
  encodes.
- **Does not migrate stored estimates.** An existing receiver estimate keeps its 12 attributes
  until the programme re-scouts that player. Rewriting stored estimates would invent scouting the
  coach never paid for.
- **Does not touch `minimumPlayableRosterByPosition`.** The frozen-versus-live split there is real
  and is now pinned by the guard test added 2026-08-23, but it is a separate question with no
  defect behind it.
