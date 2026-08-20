# Handoff — 2026-08-20

Session interrupted mid-verification. This is a self-contained account of what landed, what's
open, and what to do next. Not a canon doc — do not register it in `docs/DOC-MANIFEST.md`; delete
it once its items are closed out.

## What's merged into `main`

**PR [#33](https://github.com/EricMG13/Pro-Football-Coach/pull/33) — Season-boundary property
checks.** Merged at `03df3af`. Four structural properties added, checking things no suite
previously asserted past bootstrap:

- Schedule shape across seasons (`CompetitionTests`, "Season-boundary schedule")
- Slate-vs-post-realignment-map agreement (`RealignmentTests`, "the map the slate is built from")
- Rival-list identity against the rivalry store, across the season boundary (`RivalryOrderTests`)
- Full step ledger + calendar walk correctness, every week (`SeasonRolloverTests`)

Two real defects found and fixed in the process:
1. `ScheduleGenerator.pair` could dead-end and drop a whole tier to `roundRobinFallback`, collapsing
   all 32 pro byes into one week. Fixed with `constrainedPair` (most-constrained-first), then
   further hardened by a concurrent session (`b4b3c9d`, also in this PR) that rotates the balanced
   bye assignment in the fallback itself.
2. Conference realignment landed *after* the next season's slate had already been drawn from the
   old conference map. Fixed by redrawing the slate post-swap.

Verified at merge time: full `SimTests` run, 924 tests / 771,856 checks, all green.

## What's open, not merged

**PR [#42](https://github.com/EricMG13/Pro-Football-Coach/pull/42) — Cap career length at 30
seasons (D7).** Branch `claude/career-length-cap-30`, commit `a1f6766`, rebased cleanly onto current
`main`.

**Why:** investigating the M7 gate showed D7's 8 MB falsifier is breached ~3x by season 20
(26.71 MB measured, compressed). Root cause: `DomainEventLedger.archive: [SeasonHistoryDigest]`
appends one digest per season forever — the one growable-across-seasons collection D7's own bounds
table never listed. `01-RESEARCH.md` already recorded FMM's precedent (cap career length) as input
to D7; only the idea had been adopted, not the mechanism. Canon written first: `02-GAME-DESIGN.md`
§11.3.1 and `OPEN-DECISIONS.md` D7 both carry the ruling.

**What it does:** `SharedRules.maximumCareerSeasons = 30`. `WorldScheduler.advanceWeek` refuses to
advance once `calendar.season >= 30` — the single chokepoint every caller reaches. Seasons 0–29 play
in full; the calendar rests at season 30 week 1, terminal and valid. `CareerSessionError
.careerComplete` gives the player a real message ("Your 30-season career is complete") instead of
the generic refusal fallback.

**Verified green:** `--season-rollover` (8/37, including the new cap test at both the last-playable
season and the terminal one), `--core-contracts` (217/2472), `--architecture-only` (25/222),
`--competition-only` (37/8331), `--realignment` (8/154), `--rivalry-order` (8/34), and critically
`--m7-gate` itself — 1/65, save sizes **byte-identical** to the pre-cap run (s1=6.70MB, s20=26.71MB,
s30=37.11MB). The cap changes what happens after season 30, not anything measured before it.

### Remaining item 1 — finish verifying PR #42

The full no-argument `SimTests` run was never completed for this branch (it was in progress, clean
through realignment/rivalry/college-portal suites with zero failures, when the session was cut
short). Before merging:

```bash
git checkout claude/career-length-cap-30
git pull
swift build -c release -Xswiftc -enable-testing --product SimTests
.build/release/SimTests
```

Expect it to complete in a few minutes (the binary is already built by the time you run the
no-arg suite; `--m7-gate` and the other soaks are excluded from the default run per
[pfc-default-suite-excludes-soaks]). If green, merge #42. If red, the failure is almost certainly
either unrelated pre-existing flake (check against `main` first) or a season-boundary interaction
the targeted suites above didn't cover — bisect from there.

### Remaining item 2 — FSC-003 / the 8 MB ceiling itself

The cap bounds growth (37.11 MB is now the *maximum* a save can ever reach, not an arbitrary point
on an unbounded line) but does not meet the stated 8 MB ceiling. `OPEN-DECISIONS.md` D7 records this
as still open, and frames it as an owner question rather than an engineering one: the 8 MB figure
was inherited from a single-tier 32-team prior build and from Football Manager Mobile's
console-storage cap, neither matching this project's two-tier, 134-programme scope. Do not pick a
resolution unilaterally — the ruling needs to come from the owner, the same way the season cap did.
`docs/FUTURE-SIMULATION-CONTRACT.md` FSC-003 stays a release blocker until that's decided and acted
on.

### Remaining item 3 — a second, unrelated save-size fix exists on another branch

Sibling worktree `claude/codebase-review-confidence-b6b216` (commits `0e6953c`, `fc2cb2c`,
`dfe3b76`) brought season-20 save size down further, to ~14.76 MB, by evicting
`PeopleState.departedPlayers`/`playerCareers` — orthogonal to the digest-archive fix in #42 (roster
retention vs. history retention). Not present on `main` or on #42 as of this handoff. Worth checking
its PR status and merging if it's ready; the two fixes should compose (roster retention bound ×
season cap), but that composition hasn't been measured.

## Repo conventions worth knowing before touching any of this

- **Doc-first amendment rule** (`CLAUDE.md`): a gameplay question not answered in canon gets
  answered in canon first, then implemented. `docs/DOC-MANIFEST.md` is the sole authority on what's
  canon — don't treat a doc as authoritative just because it's in `docs/`.
- **Process is non-negotiable**: plan → build small → adversarial review → verify → commit. TDD for
  all engine code. Never claim "tests pass" without having actually run them.
- **`--m7-gate` needs both `-c release` AND `-Xswiftc -enable-testing`.** Missing either produces a
  misleading failure (a silent ~85-minute debug-speed hang, or an immediate `#ModuleNotTestable`
  compile error) that reads like a bug but isn't. See memory `pfc-m7-gate-debug-mode-trap`.
- **`GameState.bootstrap` starts at season 0.** "Thirty seasons" = season indices 0 through 29,
  calendar resting at season 30 week 1. This convention is already load-bearing in
  `HistoryGateTests.swift` and now in the cap itself — don't introduce an off-by-one against it.
