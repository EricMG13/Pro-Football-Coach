# Codex handoff — the cities changed, your work did not

Snapshot: 2026-08-21, Europe/London. Continuation memo, not canon. `docs/STATUS.md`, `CLAUDE.md`
and `docs/DOC-MANIFEST.md` remain authoritative.

Branch `agent/floodlit-injury-evidence`. We are both committing to it, so read this before
reconciling.

## The headline: nothing of yours is invalidated

Every one of the 166 team names now carries a different city. **Your review artifacts are
unaffected**, and that is checked rather than assumed:

- All 166 **stable IDs** are byte-identical before and after.
- All 166 **nicknames** are byte-identical before and after.
- All 166 **asset names and filenames** are unchanged.
- `artifacts/team-mark-review/**/decisions.json` is keyed by `assetName`, not by team name.
- A sweep of every `.md` and `.json` under `artifacts/` found **zero** references to an old city
  name.

So every accept/replace decision you have recorded still points at the right mark, and every mark
still depicts the nickname it was drawn for. Only the city half of the public name moved.

## What changed and why

`realAmericanPlaces` had been read out of a gazetteer alphabetically and cut at 570. **375 entries
began with A and 109 with B** — 85 per cent of the pool, with six letters absent outright. The
sampling was faithful, which is what made it a defect rather than a bug: a world's 166 members
reproduced that distribution exactly, so two thirds of every league was named after an A-town.

The pool is now 570 real places across 25 initials, weighted toward real US place-name frequency.
A+B falls to 12 per cent of the pool and 8 per cent of a world's teams.

The count is held at **exactly 570** on purpose. `distinctPlaceNames` shuffles the array and a
Fisher-Yates shuffle costs one draw per element, so adding or removing even one entry would move
every id generated afterwards and de-key the entire logo catalogue. Entries were substituted, never
added or dropped. If you touch that array, keep the count.

## What this does affect

**Four pinned values were re-pinned deliberately.** If you hold a branch with the old ones you will
conflict here:

| Pin | File |
|---|---|
| `PINNED_WORLD_BYTES`, `PINNED_WORLD_DIGEST` | `Tests/SimTests/Suites/GenerationTests.swift` |
| `pinnedRootFingerprint`, `pinnedAdvancedRootFingerprint` | `Tests/SimTests/Suites/ArchitectureTests.swift` |

Take the new values; they are the deliberate-change case, not an ordering defect. The world is
byte-identical run to run.

## One thing you must re-run if you regenerate a mark

All 166 marks now carry a dark keyline and a chalk halo, applied by
`Tools/TeamLogos/apply_keyline.py`.

That was not cosmetic. The delivered set drew in exactly two team colours with no outline, so where
the darker colour formed the outer contour it vanished against the dark register: **64 of 166
measured under 1.6 contrast against `#07111F`, the worst at 1.03**, which is invisible. The app's
primary register is dark.

**Any mark you regenerate arrives without the rings.** Re-run the pass afterwards:

```bash
python3 Tools/TeamLogos/apply_keyline.py
```

It is idempotent — a mark already carrying a chalk ring is skipped — so running it after every batch
is safe and cheap. It also scales each mark down by exactly what the rings grow it, so the
transparent-edge guarantee the asset suite enforces still holds; it refuses to write anything that
would touch the canvas edge.

## Still open, and it is yours

Your batch READMEs say the candidates were "generated with the built-in image generator". That means
there is no reusable generator to commit, and the repo cannot regenerate the set: nothing under
`Tools/` draws these marks, and a sweep of every ref, all worktrees and the agent scratch
directories found nothing.

The consequence is that the two remaining defects can only be fixed by redrawing, not by re-running:

1. **Style drift by batch.** Internal edge density is 0.068 in batch 1 against 0.106 to 0.138 across
   batches 4 to 13, roughly double, from thin internal strokes and extra contour detail. Batch 14
   recovers only to 0.087. Batch 1 is the cleanest reference. Your own review reached the same
   conclusion by a different measure, so this is corroborated, not disputed.
2. **abstractMotion fragments at the design size.** It averages 2.5 separate blobs at a 20 pt draw
   against 1.0 for every other family, and four marks reach 6 to 9 — all crossed-tool subjects
   (Quarrymen, Wreckers, Coopers, Smelters). Crossed thin shafts break into confetti at 60 device
   pixels.

`docs/superpowers/specs/2026-08-21-team-mark-construction-system.md` carries the numbers those
should be redrawn against.

## Housekeeping

`a547404` removed `exports/vector-mark-experiment-2026-08-21/generate_logos.swift`, which `11805ed`
had swept in as an untracked file. It was a rejected experiment of mine that draws the crude marks
reverted in `8fadba2` — not the generator for the shipped set. Its header claimed otherwise, which
would have misled the next person looking for the source.

Please do not `git add -A` on this branch; it picks up scratch directories and large export
artifacts. Stage by explicit path.
