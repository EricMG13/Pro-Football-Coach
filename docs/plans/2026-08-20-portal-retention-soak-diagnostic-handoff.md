# Handoff: portal-touched retention fix — open A/B diagnostic

Branch `claude/hopeful-liskov-37edb2`, worktree `.claude/worktrees/hopeful-liskov-37edb2`,
[PR #39](https://github.com/EricMG13/Pro-Football-Coach/pull/39) (open, **not merged** — marked
do-not-merge pending the item below). Work stopped here on explicit request before the diagnostic
finished; this document is the exact state and the exact next step, not a summary written after the
fact.

## What's done and verified

- Fix: [`Sources/FootballSimCore/People/SeasonLifecycleSystem.swift:150-196`](../../Sources/FootballSimCore/People/SeasonLifecycleSystem.swift).
  `retainedIdentityIDs` used to protect any career that ever touched the transfer portal, forever,
  which is why `departedPlayers` grew past `PeopleRules.departedPlayerRetentionLimit` (10,199 vs
  8,192 by season 20 in the soak that first found this). It now protects a career only while a
  surviving `.portalWindowCompleted` event in `state.history.recent` (a bounded ~4096-event FIFO)
  still names one of its (season, window) pairs — because
  `WorldIntegrity.checkPortalEvents`' `.portalWindowCompleted` case
  ([`Sources/FootballSimCore/Integrity/WorldIntegrity.swift:1618-1650`](../../Sources/FootballSimCore/Integrity/WorldIntegrity.swift))
  recounts every entrant of that window — retained and returned entrants included, not just
  transfers — from `playerCareers`, and that event's `referencedEntityIDs` is empty, so the generic
  event-reference protection loop never covered those entrants on its own.
- A cruder "current season only" narrowing was tried before this session and is independently known
  to be wrong: it broke the same recount for a window still resident in the journal and failed at
  season 4 with `portalCommitFailed(.postseason)`. **Do not reintroduce either shape** (blanket
  "ever touched," or "current season only") — both are confirmed-wrong, not untried.
- TDD test: [`Tests/SimTests/Suites/PortalTransactionTests.swift:1291-1373`](../../Tests/SimTests/Suites/PortalTransactionTests.swift),
  covers both directions (stays protected while the window's completion event is live; becomes
  evictable once it ages out of the journal). Green.
- Full default suite (`swift build -c release -Xswiftc -enable-testing --product SimTests && .build/release/SimTests`,
  no flags — everything except the soaks): **948 tests, 775,603 checks, all passed, no
  regressions.**

## What's NOT resolved — the actual remaining item

`.build/release/SimTests --m2-soak` (20 seasons) does not run clean. It hits three repeats of an
already-known, separately-owned test-timing bug, then aborts early (49 checks total, nowhere near a
full 20-season run) on:

```
threw portalCommitFailed(FootballSimCore.CollegePortalWindow.postseason)
```

That is the *exact* failure signature the earlier wrong "current season only" narrowing produced.
**Whether this fix causes it, or it's downstream of the pre-existing unrelated bug below, was not
isolated before work stopped.** A controlled A/B was set up and killed mid-run:

1. `cp Sources/FootballSimCore/People/SeasonLifecycleSystem.swift <scratch>/SeasonLifecycleSystem.swift.myfix`
   (back up the fix).
2. `git stash push -- Sources/FootballSimCore/People/SeasonLifecycleSystem.swift` (revert to the
   original blanket-protection code on disk; the working tree currently has the fix committed on
   this branch, so use `git show af2b3f5:Sources/FootballSimCore/People/SeasonLifecycleSystem.swift
   > Sources/FootballSimCore/People/SeasonLifecycleSystem.swift` instead, `af2b3f5` being the parent
   commit before this fix — check `git log --oneline -5` to confirm that's still the immediate
   parent).
3. `swift build -c release -Xswiftc -enable-testing --product SimTests`
4. `.build/release/SimTests --m2-soak`
5. Compare against the with-fix run above.
   - **If `portalCommitFailed` still occurs without this fix**: it's pre-existing and unrelated.
     Proceed to the roster-count bug below — it likely needs to be fixed first before *any* clean
     20-season run is possible, with or without this PR.
   - **If it does NOT occur without this fix**: this fix has a real bug that only manifests over a
     real multi-season run, which the hand-built unit test didn't reach. Use
     `superpowers:systematic-debugging` (this repo's own process rule — no guess-fixes). Starting
     points: is there a *second* place besides `WorldIntegrity.checkPortalEvents` that reads
     `playerCareers[id].portalWindows` and needs a longer retention window than "the completion
     event is still in `state.history.recent`" gives it — check
     `Sources/FootballSimCore/College/CollegePortalMatchingV1.swift` (the `alreadyTransferred` check
     around line 317) and `Sources/FootballSimCore/College/CollegePortalPolicyV1.swift` (lines
     ~426, ~437) for reads that could hit a *just-evicted* career during a real season transition
     that the isolated fixture-based unit test never exercises (e.g. timing between the once-per-
     season prune in `SeasonLifecycleSystem.advance` and multiple portal-window commits — postseason
     then spring — that happen around the same season boundary).
   - Restore the fix afterward: `git checkout HEAD -- Sources/FootballSimCore/People/SeasonLifecycleSystem.swift`
     (or reapply from the scratch backup) before touching anything else.

Do not merge PR #39, and do not report this fix as verified, until a clean `--m2-soak` run confirms
`state.people.departedPlayers.count <= PeopleRules.departedPlayerRetentionLimit` holds through
season 20. That is the exact invariant this fix exists to restore.

## The separately-owned roster-count bug (do not fix here — context only)

`Tests/SimTests/Suites/PeopleLifecycleTests.swift:591-599` samples college roster counts at week 1,
one week before `CollegeCycleSystem.addWalkOns(for: .springRosterFill, ...)` tops rosters back up to
105 (`.awaitingSpring` is a deliberate one-week gap for the coach's spring portal decisions) — a test
sampling-timing bug, not (as best understood) real engine corruption. As of 2026-08-20 ~10:00, a
fix for this (peek one week ahead before asserting the exact count; widen the pro/college age-range
assertion from `18...21`/fixed to `17...23`) existed **uncommitted** in a different worktree
(`.claude/worktrees/world-gen-property-assert-b8a302`, branch `claude/sad-heisenberg-45fed4`) — that
session became unreachable (stale peer socket) partway through this one and its status since is
unknown. Check whether that fix has landed on `main` or that branch by now; if not and it's needed
to get a clean soak run, either wait for it or read that worktree's uncommitted diff directly
(`cd .claude/worktrees/world-gen-property-assert-b8a302 && git diff`) and replicate it — it is
test-only, touches `PeopleLifecycleTests.swift`, and does not touch anything this fix depends on.

## Key files

- `Sources/FootballSimCore/People/SeasonLifecycleSystem.swift:150-196` — the fix.
- `Sources/FootballSimCore/Rules/PeopleRules.swift:17` — `departedPlayerRetentionLimit = 8_192`.
- `Sources/FootballSimCore/Integrity/WorldIntegrity.swift:1250-1470` (`checkPortalState`),
  `:1533-1651` (`checkPortalEvents`), `:1653-` (`checkPortalKnowledge`) — the invariant the fix
  protects.
- `Sources/FootballSimCore/College/CollegePortalTransactionV1.swift:237` — where `WorldIntegrity.check`
  runs inside a portal commit and a blocking issue makes `commit()` return `nil`.
- `Sources/FootballSimCore/Scheduling/WorldScheduler.swift:1043` — where a `nil` commit becomes the
  thrown `portalCommitFailed`.
- `Tests/SimTests/Suites/PortalTransactionTests.swift:1291-1373` — the new TDD test, and
  `portalTransactionFixture()`/`projectedPostseasonTransition()` above it — reusable fixtures for
  building a real, validated portal-window commit without a multi-season simulation.
- `docs/STATUS.md` — 2026-08-20 entry starting "the bound above still leaked, through the one
  category it deliberately protected forever."
