# Codex handoff — calibration continuation

Updated 2026-08-20 after a fresh isolated calibration lane. Stay calibration-only. Do not stop or
kill Swift or simulator processes belonging to other sessions. Treat stale executables as no
evidence. Use an isolated scratch path and one compiler job when a manual build is needed.

## Verified in this continuation

`./scripts/verify.sh --lane calibration` passed from a fresh release build:

- calibration: 21 tests / 169 checks;
- M3 recruiting calibration: 20 tests / 412 checks;
- M3 first/repeat runtime: 61.600 s / 67.098 s;
- projected class target range/median: 12...25 / 21.0;
- signed class range/median/mean: 5...25 / 16.0 / 15.61;
- fill rate range/median/mean: 28...100% / 84.0% / 76.85%;
- aggregate fill/nonempty classes: 75% / 134 of 134;
- signed/released/walk-ons: 2,092 / 0 / 37;
- durable save / JSON bytes: 6,488,456 / 42,401,898.

The M3 failure was a scheduler boundary defect, not a calibration-band result. The final open
recruiting week is `CollegeRules.signingDayWeek - 1` (week 20). `WorldScheduler` now runs one
terminal recruiting-market pass after that week's AI step, so the last AI investment can create a
commitment before signing week. Week 21 keeps its ordinary pre-AI market pass; the redundant second
pass was removed. The M3 causal-order test now advances week 20 and then the week-21 signing
rollover, matching `docs/02-GAME-DESIGN.md` §4.1 and `SeasonRolloverTests`.

Changed files:

- `Sources/FootballSimCore/Scheduling/WorldScheduler.swift` — week-20 terminal market boundary;
- `Tests/SimTests/Suites/M3RecruitingCalibrationTests.swift` — two-transition signing assertion;
- this handoff and `docs/STATUS.md` — evidence only.

## Current holdout calibration baseline

Fresh core-only holdout measurement, using the current model and exact TOST confidence intervals:

| band | estimate | TOST CI90 | canonical band | result |
| --- | ---: | ---: | ---: | --- |
| college favourite win | 0.8189 | [0.7978, 0.8400] | [0.70, 0.78] | fails upper bound |
| pro favourite win | 0.8800 | [0.8622, 0.8978] | [0.62, 0.72] | fails upper bound |
| pro blowout | 0.6960 | [0.6721, 0.7199] | [0.17, 0.26] | fails upper bound |
| pro points per drive | 2.1454 | [2.1111, 2.1796] | [1.60, 1.95] | fails upper bound |

The other 21 of 25 bands hold. No canonical band was amended or widened. Do not replace a failed
band with a wider margin. If a further justified model change cannot tighten a band honestly, leave
the measured margin documented and stop. Ask the owner before changing a band in canon.

## Already rejected hypotheses

The following were screened and not retained because they either moved the wrong metric, failed to
close the TOST interval, or lacked a justified model basis: general rating-weight reduction,
run-only rating reduction, ladder scans, fixed/shared/fresh roster variants, shared-shape variants,
tier-specific ladder candidates, per-attribute team-mean normalization, position-level
normalization, and extending the pro field-goal decision range to 45 yards.

## Owner decisions before further model work

1. Should the calibration ladder represent the real league favourite gap (roughly +2), or remain the
   current stress-test ladder (average gap +5.75)?
2. Does each ladder rung hold aggregate talent constant, and if so how?
3. What is the authoritative points-per-drive definition: all drives including zero-point drives,
   or scoring drives only? The current estimator includes all drives, including drive splits with
   zero points.

Do not make a ladder, roster-generation, points-per-drive, or canonical-band change without the
owner's answer. The next safe action is to review these measurements and decisions, not to widen a
band to make a gate pass.
