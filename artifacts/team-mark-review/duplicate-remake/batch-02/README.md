# Duplicate Remake — Batch 02

Status: **candidate review passed; not installed**.

This folder contains the twelve Batch 02 candidates from the Batch 02–11 implementation plan. It does not modify the shipped logo catalogue, manifest, app code, Batch 01, or normalization code.

## Contents

- `raw/`: the seven accepted generated sources, before palette hardening and 256-pixel normalization.
- `final-candidates/`: twelve exact-name 256×256 RGBA candidates using the current manifest palettes.
- `review/`: six 1120×620, 4×3 review sheets at 20, 32, and 44 points on `#F3F0E8` and `#10151E`.
- `decisions.json`: per-asset source provenance, processing, retry counts, and visual outcome.

Five marks reuse previously audited exact-subject sources: Needlefish, Meteors, Aurora, Nebulae, and Stag Beetles. The Stag Beetle is the explicitly authorized cross-asset reuse of Batch 15 candidate `TeamLogo_A0D5378A462C4791AE53952A79FCCD62`, re-keyed to target asset `TeamLogo_05293748863A41259807C9C4C35E4C11`. Seven subjects were generated across 27 image-generation calls, including 20 retries.

Every final candidate was produced through `Tools/TeamLogos/normalize_candidate.py`. Source-stage palette-role consolidation was used where a generated neutral fill would otherwise collapse to the dark role or where extra small accent regions exceeded the six-region ceiling. Geometry and alpha silhouettes were retained. The Golem received one additional source-stage repair that merged existing shoulder, head, and chest planes into a single broad anatomical accent for charcoal-surface readability.

## Final visual verdicts

| Mark | Verdict | 20-point evidence |
|---|---|---|
| LAU Krakens | PASS | Compact four-tentacle pinwheel; clear on both surfaces. |
| PET Needlefish | PASS | Crescent body and leading beak remain distinct. |
| SED Meteors | PASS | Three fragments and one heavy diagonal trail read immediately. |
| SMI Aurora | PASS | Angular crown and folded ribbons survive region consolidation. |
| RED Paddlefish | PASS | Revised top-down S-turn restores mass, paddle snout, and exact viewpoint. |
| CAN Nebulae | PASS | Compact knot and broken orbit remain asymmetric and legible. |
| ESS Leviathans | PASS | Simplified full-body open coil reads as one sea-dragon mass. |
| IRO Monoliths | PASS | Heavy split wedge stays clear and unique. |
| EDG Stag Beetles | PASS | Mandibles, armored body, and cyan wing case remain visible. |
| EPH Kelpies | PASS | Full-body leaping horse and tight wave curl replace the rejected head-only treatment. |
| NAM Thunderbolts | PASS | Massive fork and counter produce a clean weather silhouette. |
| LOV Golems | PASS | Connected shoulder/head/chest accent keeps the low charge coherent on charcoal without esports clutter. |

## Verification

- Manifest reconciliation: 12/12 exact records, abbreviations, filenames, and palettes.
- PNG contract: 12/12 RGBA, 256×256, binary alpha, both literal palette colours, at least 10-pixel clearance, and under 196,608 bytes.
- Meaningful filled regions: 12/12 at six or fewer using an eight-connected, 169-pixel minimum-area audit, followed by visual gap/feature review.
- Review sheets: 6/6 at 1120×620 with the required size, surface, nickname, abbreviation, and family labels.
- Near-duplicate audit: no suspicious silhouette match among the twelve candidates or against 166 shipped marks.

The remaining visual judgment risk is small: Paddlefish species specificity depends on the long paddle rostrum at 20 points, and Golem depends on the connected pink torso plane for dark-surface definition. Both pass the final light/dark sheets.
