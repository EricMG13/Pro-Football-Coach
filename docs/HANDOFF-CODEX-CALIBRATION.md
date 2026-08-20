# Codex handoff — the remaining calibration bands

Checkpoint from a Claude session, 2026-08-20, merged to main as PR [#44](https://github.com/EricMG13/Pro-Football-Coach/pull/44)
(squash commit `3bba7c9`). This file is a pointer, not a substitute — `docs/STATUS.md`'s dated
entries under "P4 — calibration harness and bands" carry every measurement. This is a separate item
from `docs/HANDOFF-CODEX.md` (PR #9's re-pin), which is still open and unrelated.

## Where things stand

The holdout ladder held 6 of 24 bands at the start of that session and held **21 of 24** at its
checkpoint. The current `origin/main` contains one additional measurable pro band, `points per
drive`, so the live count is **21 of 25**. The current holdout result, measured with the TOST
confidence interval rather than a point estimate, is:

- college favourite win rate: **0.8189**, CI90 **[0.7978, 0.8400]**, band 0.70–0.78 — fail high;
- pro favourite win rate: **0.8800**, CI90 **[0.8622, 0.8978]**, band 0.62–0.72 — fail high;
- pro blowout rate: **0.6960**, CI90 **[0.6721, 0.7199]**, band 0.17–0.26 — fail high;
- pro points per drive: **2.1454**, CI90 **[2.1111, 2.1796]**, band 1.60–1.95 — fail high.

Run this to see the live state when the release build is available:

```bash
swift run -c release -Xswiftc -enable-testing SimTests --calibration-gate
```

The four currently failing bands are the two `favourite win rate` rows, pro `blowout rate`, and pro
`points per drive`. The first three were investigated to the point of a proof, not a guess, and the
session stopped there rather than force them green by reshaping the test instrument. The points-per-
drive failure is a newer measurement exposed by the merged harness change and must not be silently
dropped from the count. The prior `docs/STATUS.md` 2026-08-20 entry
("the same three, re-examined after a stop-hook challenge...") has the full arithmetic. Short
version:

- A **fixed, evenly-drawn** roster pair produces a game-to-game margin standard deviation of 12.7–13.2
  points against a real value of about 13.5 — **the engine's own variance is correct.**
- A **freshly drawn** pair at the same nominal skill produces a standard deviation of 20–21 points.
  The roster-draw component alone is 15–17 points, larger than the game itself contributes, because
  `CalibrationRoster.team(skill:seed:)` scatters every rated attribute independently by ±18 and the
  engine reads only a handful of those attributes on a handful of players per snap.
- The engine lands inside `01-RESEARCH.md` §6.5's favourite-win band at a per-player rating gap of
  roughly **+2**. `CalibrationHarness.talentLadder`'s twelve pairs average a gap of **+5.75**.

Four mechanisms were tried and measured as ineffective (raising `leverageNoise` to canon's ceiling,
red-zone leverage compression at two strengths, score-aware fourth-quarter play calling, narrowing
the roster scatter) — each cost bands elsewhere and none closed the gap. One real engine defect
*was* found and fixed along the way (the throw's accuracy term outweighed openness and pressure
combined by 3:1 — see the `throwAccuracyWeight` commit, `63d9d46`), which is why the count went from
8 of 24 to 21 of 24 rather than stalling earlier. A follow-up attempt to fix the ladder directly
(smaller, more realistic gaps) was tried and made things **worse** — it dropped four bands that were
already holding — and was reverted; that revert is itself evidence, recorded in STATUS, that this is
a real tension between the harness's sampling and the bands it is scored against, not a tuning gap.

## The two questions that block the three coupled rate bands

Both are `docs/OPEN-DECISIONS.md`-shaped: they need an answer recorded in canon before more code
changes, per `CLAUDE.md`'s doc-first rule. Neither was answered by this session.

**1. What per-player rating gap should `talentLadder` use?**
`01-RESEARCH.md` §6.5's favourite-win band describes real betting favourites. The current ladder
(`Sources/FootballSimCore/Calibration/CalibrationHarness.swift`, `talentLadder(matchup:)`) uses gaps
from 0 to 9, averaging 5.75 — a schedule of mismatches, not a league. The engine reaches the band at
about +2. A prior version of this ladder used gaps up to 26 and was already narrowed once for the
same reason (see the doc comment above `talentLadder` for that history). A second narrowing attempt
this session (0–5, averaging 1.75) undershot college's floor and overshot pro's blowout ceiling in
the other direction — so the answer is not simply "smaller," and needs someone to decide what the
ladder is actually supposed to represent: the spread of a real league's matchups, or a stress test
of the model's talent response, because those are different distributions and only one of them will
sit inside `01` §6.5's bands as currently written.

**2. Should a `CalibrationRoster` rung hold aggregate talent constant, and how?**
Right now "skill 72" means every one of ~23 rated attributes across ~23 players is independently
scattered ±18 around 72 — so two "skill 72" teams can differ by a full standard deviation of margin
before a single leverage draw happens. A rung is supposed to hold talent level fixed and let the
*game* supply the variance; currently it doesn't. Options worth putting in front of the owner:
tightening the scatter (tried at ±9 and ±12 this session — both improved blowout and worsened
favourite-win, because they also flatten the *nominal* gap's signal-to-noise ratio); scattering
per-position-group rather than per-attribute (so a team's talent is spiky by position rather than by
individual number); or leaving the scatter as-is and treating it as a deliberate roster-generation
model that the harness should measure honestly rather than fight. This is a design question about
what "one rung of the talent ladder" means, not a bug.

## What NOT to do

- Don't retune `leverageNoise`, `leverageScale`, red-zone terms, or the play-caller to chase these
  three rate bands further — all four were tried and measured as either ineffective or actively harmful
  to other bands. Re-trying them without a new hypothesis just repeats this session's work.
- Don't touch `talentLadder` or `CalibrationRoster`'s scatter without an owner decision on the two
  questions above recorded in `docs/OPEN-DECISIONS.md` or `01-RESEARCH.md` first. Both were tried
  ad hoc this session and both attempts were reverted because they cost other bands.
- Don't widen a band in `CalibrationBands.swift` to make one of these bands pass. `03-MATCH-ENGINE.md`
  §5.2 is explicit that this is the one universally wrong response to a red band, and it's the reason
  this whole harness exists in its current TOST form.

## What's safe to pick up independently

Everything else in `docs/STATUS.md`'s P4 section is settled and stable — the run model, the pass
model, per-tier home advantage/field-goal/run-spread constants, the clock fix, the percentage-rate
TOST fix. If you're looking for unrelated work, `docs/STATUS.md`'s other open items (per-drive
accounting, target shares, overtime — all listed in `CalibrationBands.unimplementedMetrics`) are
independent of this handoff and don't touch the same code.

## Verification note

The prior session's final commits were verified with `--engine`, `--core-contracts`, `--calibration`,
`--competition-only`, `--architecture-only`, and `--commitment-coverage`, all green after re-pinning
five fingerprints that moved from merging two independently-diverged root schema changes (see the
merge commit `e420c36`, squashed into `3bba7c9`). The current continuation rebuilt the core
calibration target in an isolated scratch path with one compiler job and reproduced the four results
above. The full release lane was attempted but the Swift build was killed by the operating system
before the suite ran; no stale executable was treated as evidence. `--m3-recruiting-calibration`
therefore remains unverified in this continuation and must be run from a successful fresh build
before shipping further calibration changes. Worth running before trusting this checkpoint fully:

```bash
./scripts/verify.sh --lane calibration
./scripts/verify.sh --lane core
swift run -c release -Xswiftc -enable-testing SimTests --match-reducer
swift run -c release -Xswiftc -enable-testing SimTests --m3-recruiting-calibration
```
