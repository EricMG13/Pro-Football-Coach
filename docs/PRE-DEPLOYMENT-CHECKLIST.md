# Pre-Deployment Checklist

What must be true before a build goes out, to TestFlight or to the App Store.

**Authored, not regenerated.** No prior version existed *on the branch this was written against*;
the v3 brief asked for a regeneration of something that was not there. The 2026-08-09 merge made the
absolute form of that claim false: `main` carried a different checklist, from the Broadcast-skin
critique, since deleted; recoverable with `git show`. This file does not inherit
from it.

Nothing here is a judgement call. Each item is either machine-checked or owner-checked, and the
owner-checked ones are owner-checked because no agent in this project's environment can reach them.

---

## 1. Machine gates — all green, on the same commit

- [ ] Build green for both library targets and the app.
- [ ] Full test suite green by D11's mechanism, with the pass/fail counts recorded.
- [ ] All calibration bands hold under TOST, both tiers.
- [ ] `TwoTierConsistencyTests` green — the detailed and abstracted models are statistically
      equivalent on every listed metric.
- [ ] Cross-process determinism proven: same seed, two separate process invocations, identical
      play-by-play hash.
- [ ] The `hashValue` source scan passes.
- [ ] The engine/UI boundary scan passes — zero `import SwiftUI` under `FootballSimCore/`.
- [ ] The design-token scan passes — zero spacing, radius, colour or font-size literals in views.
- [ ] The 20-season soak passes every assertion, at shipping league size.
- [ ] Save size after 20 seasons is under the 8 MB ceiling; every bounded collection verified bounded
      by growth check.
- [ ] Migration fixtures pass at every schema version boundary.
- [ ] All ten accessibility contract tests green, including orientation and the coverage
      meta-assertion.
- [ ] `CommitmentCoverageTest` green — every row in `PRODUCT.md`'s commitment table names a test that
      exists.
- [ ] `ReachabilityTest` green — no unreachable screen ships.
- [ ] `ErrorSurfaceTest` green — no error is captured without being presented.
- [ ] Performance budgets met on a physical **iPhone 15/A16 baseline**: week advance, full season
      sim, frame budget, cold launch, save write.

## 2. Legal gates — non-negotiable

- [ ] **Name-collision test** green: no generated programme, team, city, conference, stadium, player
      or coach name matches the blocklist, across N generated leagues at many seeds.
- [ ] **Trade-dress test** green: no generated primary/secondary colour pair falls within the stated
      ΔE of a real programme's pair.
- [ ] The blocklist has been refreshed for this release.
- [ ] Manual review: no real school, team, player, conference or broadcast identity appears anywhere
      in code, copy, assets, screenshots or store listing.
- [ ] No shipped dataset derived from a licensed source. Calibration inputs were used at design time
      only.
- [ ] Anything flagged for counsel during development has been resolved or removed. Open items:
      statistical/biographical resemblance beyond colour (raised in `01-RESEARCH.md` §6.4), and roster
      import/export (raised in §6.2B and not planned for v1).

## 3. Rubric gate

- [ ] Whole app scores **≥31/40 with zero P0/P1** against `docs/04b-AUDIT-RUBRIC.md`, all eight
      dimensions, and no automatic design-specificity rejection. (The older ≥17/20 five-dimension
      frame was superseded by the owner on 2026-08-11; the bars are not equivalent.)
- [ ] The rubric itself has been re-derived from the tool at least once this release, so `04b` is not
      drifting from the thing it reconstructs.

## 4. Owner gates — no agent may assert these

- [ ] The simulator walkthrough script has been run end to end on a real device or simulator, by the
      owner, and every step behaved as the script says.
- [ ] A fresh install, a new career, a full season, a quit, a relaunch, and a resumed save.
- [ ] Both appearances on the 844 × 390 supported-generation floor and the largest current
      Plus/Pro Max class, using iOS 26.
- [ ] A physical iPhone 15 run plus simulator coverage for any later supported `e`-class floor.
- [ ] The `ios-simulator-skill` evidence bundle retains semantic accessibility trees, AX5
      screenshots, visual diffs, and hang/trace summaries for the release commit.
- [ ] VoiceOver walkthrough of the week loop and the match view.
- [ ] Dynamic Type at AX5 across every screen.
- [ ] Reduce Motion on, through a full match.
- [ ] The D1 timing protocol has been run and the measured season time is inside 6–8 hours.
- [ ] The D9 onboarding protocol has been run with someone who has not seen the game.

## 5. Release hygiene

- [ ] `docs/STATUS.md` is honest: everything unverified is named as unverified, with its files.
- [ ] No file in the repo claims a build or a test run that did not happen.
- [ ] Version and build number incremented; `schemaVersion` correct.
- [ ] Backup/restore path exercised, including a corrupted-save recovery.
- [ ] A newer-schema save is refused with a plain message rather than partially opened.
- [ ] No analytics, no network calls, no accounts, no IAP — verified by inspection, since P3 forbids
      all four and the absence is a feature in the listing.
- [ ] Store listing contains no real identity, and no wink at one.

## 6. The stop rule

If any box in sections 1–4 is unchecked, the build does not go out. "Nearly green" is how the
previous build shipped a phase that had never been compiled.
