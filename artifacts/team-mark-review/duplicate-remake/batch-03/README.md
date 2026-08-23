# Duplicate Remake — Batch 03

Status: **candidate review passed; not installed**.

This folder contains the twelve Batch 03 candidates from the Batch 02–11 implementation plan. It does not modify the shipped logo catalogue, manifest, app code, normalization code, Batch 01, or Batch 02.

## Contents

- `raw/`: the twelve accepted transparent sources before exact-palette hardening and 256-pixel normalization.
- `final-candidates/`: twelve exact-name 256×256 RGBA candidates using the current manifest palettes.
- `review/`: six 1120×620, 4×3 review sheets at 20, 32, and 44 points on `#F3F0E8` and `#10151E`. Review icons are composited at `pt × 3` pixels.
- `decisions.json`: per-asset source provenance, processing, generation/retry counts, and visual outcome.

Eleven final subjects were generated across 50 subject-generation attempts, including 39 rejected retries. The Eclipse reuses one audited exact-subject Batch 15 source and is re-keyed to the current manifest palette. Rejected attempts included baked checkerboards, opaque or glowing fields, illustration-level detail, weak dark-surface connections, scenic geological treatments, and identities that collapsed at 20 points.

Every final candidate was produced through `Tools/TeamLogos/normalize_candidate.py`. The final Scorpion and Dragonfly were regenerated after the strict per-colour region audit found 12 and 7 meaningful regions respectively; their replacements preserve the approved identities while reducing them to 6 and 5. The Cavern, Hydra, Caldera, and Glacier were also regenerated after the full-size football-style review rejected a breaking-wave cave, dense esports hydra, cracked-rock caldera, and dripping glacier.

## Final visual verdicts

| Mark | Verdict | 20-point evidence |
|---|---|---|
| EFF Basilisks | PASS | Full coiled body and wide triangular counter remain distinct on both surfaces. |
| TIT Vortices | PASS | Three broad bands form one asymmetric funnel with a clear eye. |
| SHA Mosasaurs | PASS | Hooked swimming body, flippers, and marine-reptile head read immediately. |
| CHA Scorpions | PASS | Top-down anatomy, massive claws, and crossing tail survive the six-region consolidation. |
| JOH Derechos | PASS | One bow front and two blunt force bands remain separate and directional. |
| LIH Lava Domes | PASS | Blunt dome, broad cracks, and single rising vent read as one cutaway icon. |
| JAN Eclipses | PASS | Offset disc, broken corona, and one flare remain legible and asymmetric. |
| YRE Dragonflies | PASS | Four broad wings attach to one continuous heavy body in five regions. |
| RAN Caverns | PASS | One rock arch and exactly two opposing teeth replace the rejected scene. |
| SUL Hydras | PASS | Exactly three necks interlock around one continuous Y accent without floating detail. |
| LEW Calderas | PASS | Broken top-down crater ring, single core, and central fissure replace the noisy rock. |
| MCC Glaciers | PASS | Solid three-peak ice crown and one deep crevasse replace the dripping-table treatment. |

## Verification

- Manifest reconciliation: 12/12 exact records, abbreviations, filenames, and palettes.
- PNG contract: 12/12 RGBA, 256×256, binary alpha, both literal palette colours, at least 10-pixel clearance, and under 196,608 bytes.
- Genuine source alpha: 12/12 accepted raws isolate the subject after the normalizer's meaningful-alpha threshold; no checkerboard or opaque-field source was accepted.
- Meaningful filled regions: 12/12 at two to six using an eight-connected, 169-pixel minimum-area audit.
- Review sheets: 6/6 at 1120×620, with exact 60-, 96-, and 132-pixel composites for 20, 32, and 44 points at 3×.
- 20-point light/dark review: 12/12 PASS.
- Near-duplicate audit: no suspicious silhouette match among the twelve candidates or against 166 shipped marks.
- Normalizer regression tests: 3/3 PASS.

The remaining visual judgment risk is small. Derecho is intentionally abstract and depends on the two blunt bands to distinguish a bow storm front from a blade; Glacier uses a crown-like three-peak ice mass and depends on its oversized central crevasse for identity. Both remain readable in the final 20-point light/dark sheets.
