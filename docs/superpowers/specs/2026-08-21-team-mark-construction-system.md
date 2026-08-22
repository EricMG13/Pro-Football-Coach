# Team Mark Construction System

**Date:** 2026-08-21
**Status:** Proposed to the owner; governs how a team mark is built, not what it depicts

## Why this exists

`2026-08-20-team-logo-set-design.md` governs the pipeline, the packaging, the legal screen and the
verification. It does not govern the drawing. Its visual direction section grants permissions —
"allow unrestricted outer silhouettes", "breadth rather than imitation" — and sets no constraint a
mark can be measured against.

Two generated sets have now failed on exactly what a constraint would have caught:

| What broke | The rule that was missing |
|---|---|
| The 2026-08-20 set was mush at 20 pt, the size the app draws most | A minimum feature size |
| 117 of 13,695 pairs in that set sit within four bits of each other under an honest perceptual hash | A distinctness floor |
| The 2026-08-21 vector attempt drifted in weight and density mark to mark | One keyline weight, one shape budget |

Every number below is derived from a measurement taken on the shipped set, not chosen for neatness.

## The governing distinction

**Constrain the treatment. Leave the subject free.**

A real league is visually heterogeneous and that is not a defect: each mark was drawn separately,
decades apart, and each is famous on its own. A set generated in one run has neither advantage, so
what holds it together has to be craft discipline rather than a shared look. A system that also
dictated silhouette vocabulary would produce 166 pieces of clip art from one kit — which is exactly
how the vector attempt failed.

So: this document fixes weight, size, spacing, colour roles and legibility. It says nothing about
what a mark may depict beyond what the nickname already decides.

## Construction rules

The canvas is 256 x 256. The app draws the mark at 20, 32 or 44 points, which on a 3x display is 60,
96 or 132 device pixels. **20 pt is the design size.** A mark that only works at 44 pt is unfinished.

| Rule | Value | Where it comes from |
|---|---|---|
| Safe area | The mark fits inside the middle 92 per cent; at least 4 per cent transparent margin on every side | The asset suite reads an opaque edge as a cropped mark, and a rotated mark reached the edge during the vector attempt |
| Minimum feature | No filled shape and no gap narrower than 5 per cent of the canvas, about 13 px at 256 | At a 60 px draw, 5 per cent is 3 px — the floor at which a feature still reads rather than smearing |
| Keyline | One weight for the whole mark, 2 to 2.5 per cent of the canvas, about 5 to 6 px at 256 | Below 2 per cent it disappears at 20 pt; above 2.5 per cent it eats the shape it is outlining |
| Filled regions | At most six, keyline excluded | Six is roughly what a 60 px draw can separate; the rejected set ran to dozens |
| Colour roles | The darker of the two team colours carries the dominant silhouette, the brighter is the accent. Black or white only for a keyline or a separation | A light-dominant mark loses its shape against the light page; the rule falls out of which surfaces the mark sits on |
| Distinctness | Aim for 16 or more differing bits against every other mark on the per-channel difference hash; below 8 is a failure | The shipped set's closest pair measures 10 of 192, and 8 is the threshold `TeamLogoTests` enforces |

## What is deliberately not specified

- **The silhouette.** The nickname decides the subject; the six motif families decide the
  composition. Neither belongs here.
- **A shared palette.** Team colours are generated and screened for trade dress. This system uses
  them; it does not choose them.
- **A house shape language.** No mandated corner radius, angle set or grid. Two marks that obey
  every rule above and look nothing alike is the intended outcome.

## How it is enforced

Four of the six rules are already machine-checked in `Tests/SimTests/Suites/TeamLogoTests.swift`:
the safe area by the transparent-edge scan, the canvas by the pixel bound, the file weight by the
byte budget, and distinctness by the colour difference hash. Two are review obligations rather than
assertions, and this document does not pretend otherwise:

- **Minimum feature size** and **filled-region count** are judgements about a raster. They are read
  off the 20 pt specimen at review, and a mark that fails either is rejected there.
- Do not describe those two as tests. `CLAUDE.md` is explicit that prose is a checklist item, not an
  assertion, and the last set shipped partly because a guard that could not tell the marks apart
  reported green anyway.

## Sequencing

This is written before the next generation run rather than after it. Two runs have now been spent
discovering these constraints by producing 166 images that violate them, and a third would cost the
same. `CLAUDE.md`'s doc-first amendment rule already requires the design answer to land in canon
before it lands in output.

The starting prompt at `Tools/TeamLogos/claude-design-prompt.md` carries the house style in prose
for the generating surface; this document is where the numbers behind it live.
