# Duplicate Remake — Batch 04

Status: **candidate review passed; not installed**.

This folder contains the twelve Batch 04 candidates from the Batch 02–11 implementation plan. It does not modify the shipped logo catalogue, manifest, app code, or another batch.

## Contents

- `raw/`: eleven accepted generated sources before 256-pixel palette hardening. The reused Manta source remains at its provenance path.
- `final-candidates/`: twelve exact-name 256×256 RGBA candidates using the current manifest palettes.
- `review/`: six 1120×620, 4×3 review sheets at 20, 32, and 44 points on `#F3F0E8` and `#10151E`.
- `decisions.json`: per-asset provenance, processing, retry counts, and final review outcome.

One exact-subject source was reused: the full-body Danville Manta from the audited Batch 15 style-reset set. The other eleven subjects were generated with the built-in image-generation tool across 24 calls, including 13 targeted retries.

Every final candidate was produced through `Tools/TeamLogos/normalize_candidate.py`. The accepted Thunderbird source also received a source-stage alpha cutoff before normalization to remove generated glow while preserving its broad two-colour geometry.

## Final visual verdicts

| Mark | Verdict | 20-point evidence |
|---|---|---|
| ROC Coronas | PASS | Offset core and three short corona lobes remain one compact solar mass without a comet trail. |
| ONE Mantises | PASS | Full body, triangular head, and two massive scythe hooks remain distinct on both surfaces. |
| DAN Mantas | PASS | Banking diamond silhouette and broad cyan wing cuts remain immediate. |
| WAP Horseshoe Crabs | PASS | Shell, rear lobes, compact abdomen, and short tail retain the top-down species read. |
| CLA Wolverines | PASS | Full-body springing diagonal remains muscular and directional rather than becoming a head badge. |
| MIL Cyclones | PASS | Exactly three interlocked wind blades retain a wide central eye. |
| OAK Black Holes | PASS | The broken accretion band and offset dark well read as one pulled elliptical mass. |
| CAR Griffins | PASS | Open-V wings, eagle point, lion body, and curling tail retain the hybrid dive. |
| RIP Hornets | PASS | Top-down body axis, swept wing kite, striped abdomen, and stinger remain clear. |
| SHA Thunderbirds | PASS | Revised olive chest, broad wing blades, and lightning tail stay complete on charcoal. |
| CRA Geodes | PASS | Three oversized crystals remain enclosed by one visibly split rock. |
| FAL Lodestars | PASS | Exact `FAL` remains legible as a connected forward-leaning wedge. |

## Verification

- Manifest reconciliation: 12/12 exact records, abbreviations, filenames, names, and palettes.
- PNG contract: 12/12 RGBA, 256×256, binary alpha, both literal palette colours, at least 10-pixel clearance, and under 196,608 bytes.
- Review sheets: 6/6 at 1120×620 with required size, surface, nickname, abbreviation, and family labels.
- Meaningful colour regions were inventoried at 2–11 per mark. A test that forced the three highest counts down to six was rejected because it erased mantis, griffin, and hornet anatomy; the retained versions are clean at 20 points and contain no glow, gradients, scenery, or micro-rendered texture.
- Near-duplicate audit: no suspicious silhouette match among the twelve candidates or against 166 shipped marks.

No commit was created.
