# M7B — Historical Aggregate Archive Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make an event that falls out of the bounded hot journal leave a durable, bounded trace, so a past season can be surfaced without scanning the save.

**Architecture:** `DomainEventLedger` keeps its bounded hot journal and gains an **archive**: one `SeasonHistoryDigest` per season, holding that season's archived-event count and the bodies of its notable events. Overflowing events fold into the digest for the season they occurred in, instead of vanishing into a single global counter. This is the "historical aggregate archive" already named in `docs/roadmap/05-PERSISTENCE-PERFORMANCE-TESTING.md` §2, sitting between the bounded journal and the rebuildable indexes.

**Tech Stack:** Swift 5 language mode, no third-party dependencies, `Tests/SimTests` hand-rolled TestKit harness.

## Global Constraints

- Engine is pure Swift; `Sources/FootballSimCore` contains zero `import SwiftUI`.
- Determinism across processes. Never seed from `hashValue`; never let a `Set` or `Dictionary` iteration order reach output.
- Every collection that grows across seasons carries a stated bound. This plan adds two: notable events per season, and archived seasons retained.
- Every dictionary key type in the engine must be `CodingKeyRepresentable` — `ContractTests` enumerates them and will reject a `Hashable` struct key.
- **This plan changes a persisted root type, so `GameState.schemaVersion` goes 10 → 11.** Decoding rejects any other version; there is no migration path today and none is added here.
- No magic numbers: bounds live as named static constants.
- TDD; Conventional Commits; one task per commit.
- Another agent commits to this branch concurrently. Stage by explicit path, never `git add -A`.

---

## Why this shape, and what was rejected

**Rejected: a cold log of every archived event.** It is unbounded by construction, and `CLAUDE.md` requires a stated bound on anything that grows across seasons. Saves are already 84.66 MB at season 20.

**Rejected: counting archived events by payload kind.** It reads well but needs a 45-case mapping from payload to a stable persisted key, and the exit gate does not ask for it. The gate asks that important past events be *surfacable*; bodies do that, and a per-season count carries the volume signal for free. Cut until something needs it.

**Kept: `isNotable` as an exhaustive switch on the payload, with no `default`.** The compiler then refuses to build when a new payload case is added without deciding whether it is historically notable. That is the by-construction coverage `CLAUDE.md` demands, in the one place where a judgement genuinely has to be made.

---

## File map

| File | Responsibility |
|---|---|
| `Sources/FootballSimCore/History/SeasonHistoryDigest.swift` | **New.** One season's archived-event count and bounded notable bodies, with decode bounds. |
| `Sources/FootballSimCore/History/DomainEvent.swift` | `DomainEventPayload.isNotable`; `DomainEventLedger` gains the bounded archive and folds overflow into it. |
| `Sources/FootballSimCore/World/GameState.swift` | Schema version 10 → 11. |
| `Sources/FootballSimCore/Integrity/WorldIntegrity.swift` | Whole-root check that the archive is ordered, bounded, and agrees with `archivedCount`. |
| `Tests/SimTests/Suites/HistoryArchiveTests.swift` | **New.** Focused suite. |
| `Tests/SimTests/main.swift` | Registers `--history-archive` and adds the suite to the default run. |
| `Tests/SimTests/Suites/ArchitectureTests.swift` | Re-pin the root and one-week fingerprints, which the schema bump moves. |

---

## Task 1: The season digest

**Files:**
- Create: `Sources/FootballSimCore/History/SeasonHistoryDigest.swift`
- Create: `Tests/SimTests/Suites/HistoryArchiveTests.swift`
- Modify: `Tests/SimTests/main.swift`

**Interfaces:**
- Consumes: `DomainEvent`, `CalendarState`.
- Produces: `SeasonHistoryDigest(season:archivedCount:notableEvents:)`, `SeasonHistoryDigest.maximumNotableEvents`, and a `recording(_:)` mutator that folds one archived event in.

- [ ] **Step 1: Write the failing test**

Assert, in `Tests/SimTests/Suites/HistoryArchiveTests.swift`:

- a digest records an ordinary event by incrementing `archivedCount` and keeping no body;
- a digest records a notable event by incrementing `archivedCount` **and** keeping the body;
- notable bodies stop at `SeasonHistoryDigest.maximumNotableEvents` while `archivedCount` keeps rising, because the count is the volume signal and the bodies are the bounded sample;
- the bodies kept are the **earliest** notable ones, so a season's digest does not change under later events;
- decoding a digest whose `notableEvents` exceed the bound throws;
- decoding a digest whose `archivedCount` is less than `notableEvents.count` throws, because a kept body is by definition an archived event;
- decoding a digest with a negative season or count throws.

- [ ] **Step 2: Register the suite and run it to verify it fails**

Add to `Tests/SimTests/main.swift` a `--history-archive` branch calling `runHistoryArchiveTests()`, and add the same call to the default run immediately after `runCoachingTreeTests()`.

Run `swift run SimTests --history-archive`. Expected: compile failure, `SeasonHistoryDigest` not in scope.

- [ ] **Step 3: Write the digest**

`season`, `archivedCount`, `notableEvents`, all `private(set)`. `recording(_ event: DomainEvent, isNotable: Bool)` increments the count and appends the body only while under the bound. The decode initialiser enforces every bound the tests name, in the same style as `DomainEventLedger.init(from:)`.

- [ ] **Step 4: Run the suite and the contract gate**

```bash
swift run SimTests --history-archive
swift run SimTests --core-contracts
```

Expected: both print `all passed`. `--core-contracts` is not optional here: it owns the dictionary-key and engine-boundary scans.

- [ ] **Step 5: Commit**

```bash
git add Sources/FootballSimCore/History/SeasonHistoryDigest.swift Tests/SimTests/Suites/HistoryArchiveTests.swift Tests/SimTests/main.swift
git commit -m "feat: add the bounded season history digest"
```

---

## Task 2: Notability, and folding overflow into the archive

**Files:**
- Modify: `Sources/FootballSimCore/History/DomainEvent.swift`
- Modify: `Sources/FootballSimCore/World/GameState.swift`
- Modify: `Tests/SimTests/Suites/HistoryArchiveTests.swift`

**Interfaces:**
- Consumes: `SeasonHistoryDigest`, `DomainEventLedger.append(contentsOf:)`.
- Produces: `DomainEventPayload.isNotable`, `DomainEventLedger.archive: [SeasonHistoryDigest]`, `DomainEventLedger.maximumArchivedSeasons`, `DomainEventLedger.digest(forSeason:)`.

- [ ] **Step 1: Run the required blast-radius analysis**

```text
impact({repo: "Pro-Football-Coach", target: "DomainEventLedger", direction: "upstream"})
```

`append(contentsOf:)` is on the scheduler's hot path and `archivedCount` is read by integrity. If GitNexus has no node for it, grep every reference instead and record the impact set before editing.

- [ ] **Step 2: Write the failing test**

Assert:

- events that overflow the retention limit land in the digest for **their own** `occurredAt.season`, not the current one;
- a season's digest survives later seasons overflowing;
- `archivedCount` on the ledger stays equal to the sum of the digests' counts, so the two accountings cannot disagree;
- notable overflow keeps its body and ordinary overflow does not;
- the archive is ordered by season ascending and bounded at `maximumArchivedSeasons`, dropping the **oldest** season when it overflows — with `archivedCount` unchanged by that drop, because the events still happened;
- two identical append sequences produce identical archives;
- `isNotable` is true for `seasonCompleted` and false for `integrityChecked`, as the two ends of the judgement.

- [ ] **Step 3: Add `isNotable`**

An exhaustive `switch` over `DomainEventPayload` with **no `default`**, so a new payload cannot be added without deciding. Notable: season and postseason completion, championships, awards and records, hires and departures, transfers, draft picks and signings. Not notable: per-week bookkeeping — `integrityChecked`, `weekAdvanced`, `playerRecovered`, `playerDeveloped`, scouting observations.

- [ ] **Step 4: Fold overflow into the archive**

In `append(contentsOf:)`, the events that fall out of the retention window are exactly the prefix that `nextRecent` drops. Fold each into `archive` for its own season before discarding it, keeping the archive sorted and bounded. Leave `archivedCount` arithmetic as it is — it is already overflow-checked and the tests pin it against the digests.

- [ ] **Step 5: Bump the schema and re-pin the fingerprints**

Set `GameState.schemaVersion = 11`. Run `swift run SimTests --architecture-only`, read the two fingerprints it reports, and write them into `ArchitectureTests.swift` with a comment saying the schema bump moved them. Then run it twice in separate processes and confirm the same values, because that pin exists to catch cross-process drift and a value taken from one run has not been tested for it.

- [ ] **Step 6: Run the gates**

```bash
swift run SimTests --history-archive
swift run SimTests --core-contracts
swift run SimTests --architecture-only
swift run SimTests --portal-scheduler
```

Expected: all pass. `--portal-scheduler` is the two-season byte-identical replay and is the only gate that exercises the archive under the real scheduler.

- [ ] **Step 7: Commit**

```bash
git add Sources/FootballSimCore/History/DomainEvent.swift Sources/FootballSimCore/World/GameState.swift Tests/SimTests/Suites/HistoryArchiveTests.swift Tests/SimTests/Suites/ArchitectureTests.swift
git commit -m "feat: archive overflowing events into season digests"
```

---

## Task 3: Whole-root integrity for the archive

**Files:**
- Modify: `Sources/FootballSimCore/Integrity/WorldIntegrity.swift`
- Modify: `Tests/SimTests/Suites/HistoryArchiveTests.swift`

**Interfaces:**
- Consumes: `GameState.history`, the existing `IntegrityIssue` enum and its `description`.
- Produces: `IntegrityIssue.invalidHistoryArchive`.

- [ ] **Step 1: Write the failing test**

A root whose archive is out of season order, exceeds its bound, repeats a season, holds a digest whose notable bodies exceed the digest bound, or whose digest counts do not sum to `archivedCount`, must produce `.invalidHistoryArchive`. A bootstrapped root and a root advanced a week must produce no issue.

- [ ] **Step 2: Add the check**

Add the case, its `description` string, and a `checkHistoryArchive` alongside the existing checks, registered in the same list the other checks are registered in. Follow `checkProfessionalMarket`'s shape: compute the conditions, then one `guard` that appends a single issue.

- [ ] **Step 3: Run the gates**

```bash
swift run SimTests --history-archive
swift run SimTests --architecture-only
swift run SimTests --core-contracts
```

- [ ] **Step 4: Commit**

```bash
git add Sources/FootballSimCore/Integrity/WorldIntegrity.swift Tests/SimTests/Suites/HistoryArchiveTests.swift
git commit -m "feat: validate the history archive on the whole root"
```

---

## Task 4: The 30-season gate

**Files:**
- Create: `Tests/SimTests/Suites/HistoryGateTests.swift`
- Modify: `Tests/SimTests/main.swift`

**Interfaces:**
- Consumes: `WorldScheduler.advanceWeek`, `WorldHistoryReadModel.build`, `SaveEnvelope.encode`, `GameState.history.archive`.
- Produces: a `--m7-gate` run that reports measured numbers.

This is `docs/roadmap/06-BUILD-ROADMAP-AND-GATES.md`'s M7 exit gate: *30+ season history remains useful and performant*, and *important past events can be surfaced without scanning the entire save*.

- [ ] **Step 1: Write the gate**

Advance a bootstrapped root 30 seasons. Then assert and **print** measurements rather than only asserting them, the way `--portal-scheduler` prints its characterization line:

- the archive holds at most `maximumArchivedSeasons` digests and every retained season is contiguous and ascending;
- every retained season's digest has at least one notable event, so 30 seasons of history is not 30 empty rows;
- surfacing a past season reads only that season's digest — assert `digest(forSeason:)` is what the caller needs and that it does not touch `recent`;
- whole-root integrity holds at the end;
- save size and encode time at seasons 1, 5, 20 and 30, printed, because `docs/roadmap/05` §2 names exactly those measurements and the number is the deliverable.

The gate is slow, so it gets its own flag and is **not** in the default run — `--m3-soak` and `--m2-soak` set that precedent.

- [ ] **Step 2: Run it and record the real numbers**

```bash
swift run -c release SimTests --m7-gate
```

Release, not debug: the performance half of the gate is meaningless in a debug build.

- [ ] **Step 3: Commit**

```bash
git add Tests/SimTests/Suites/HistoryGateTests.swift Tests/SimTests/main.swift
git commit -m "test: add the 30-season history gate"
```

---

## Task 5: Record it

**Files:**
- Modify: `docs/STATUS.md`, `docs/FUTURE-SIMULATION-CONTRACT.md`

- [ ] **Step 1: Run the full gates**

```bash
./scripts/verify.sh
swift run -c release SimTests --m7-gate
```

Takes upwards of thirty minutes. Record the printed numbers; write no number that was not read off a run.

- [ ] **Step 2: Update the documents**

STATUS gains the M7B entry with measured counts and the four save-size readings. FSC-002 moves from "no cold-storage persistence layer" to naming what now exists and what does not: bodies are retained for notable events only, within bounds, and full cold storage of every archived event body remains out of scope. FSC-010 loses cold event bodies from its missing-dependency column, keeping generated news and cross-season semantic narratives.

- [ ] **Step 3: Commit**

```bash
git add docs/STATUS.md docs/FUTURE-SIMULATION-CONTRACT.md
git commit -m "docs: record the M7B historical aggregate archive"
```

---

## Not in this plan

- **Generated news and semantic narratives.** They compose over the archive this plan builds. Planning them first would design a feed over a store that does not exist.
- **Compression and chunked persistence (FSC-003).** The archive is bounded so it does not make the save-size problem worse, but 84.66 MB at season 20 is the snapshot, not the history, and it is M9 work.
- **Real geography in the generator.** Permitted by the owner on 2026-08-12 and not yet built; it touches D6's geography-driven rivalry seeding and belongs in canon first.
