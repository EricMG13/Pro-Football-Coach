# Duplicate Remake — Batch 05

Status: **candidate review passed; not installed**.

This folder contains the twelve Batch 05 candidates from the Batch 02–11 implementation plan. It does not modify the shipped logo catalogue, manifest, app code, another batch folder, or normalization code.

## Contents

- `raw/`: the nine accepted generated sources before 256-pixel normalization and palette hardening.
- `final-candidates/`: twelve exact-name 256×256 RGBA candidates using the current manifest palettes.
- `review/`: six 1120×620, 4×3 review sheets at 20, 32, and 44 points on `#F3F0E8` and `#10151E`.
- `decisions.json`: per-asset source provenance, processing, retry counts, and visual outcome.

Three marks reuse audited exact-subject Batch 15 sources: Squalls, Pulsars, and Sailfins. Squalls and Pulsars are explicit cross-asset geometry reuse, re-keyed to the Batch 05 targets; Sailfins retain the same asset identity. Nine subjects were generated across 20 image-generation calls, including 11 retries.

Every final candidate was produced through `Tools/TeamLogos/normalize_candidate.py`. Broad source-region consolidation was used for Grizzlies and Tarantulas. Avalanche received one post-normalization interior-plane consolidation: a 268-pixel isolated violet fracture was merged into the surrounding sand snow plane, reducing the mark from seven to six meaningful regions without changing its silhouette or two-slab construction.

## Final visual verdicts

| Mark | Verdict | 20-point evidence |
|---|---|---|
| PEC Grizzlies | PASS | Low full-body charge, planted forequarters, and bear head remain distinct without crude empty facets. |
| HAL Squalls | PASS | Compact cloud and three broad hooked wind bands read on both surfaces. |
| WIL Pulsars | PASS | Dense core and opposing beams remain a clean celestial axis. |
| ELK Sailfins | PASS | Tall dorsal sail, forked tail, and full fish profile remain exact. |
| WAH Tarantulas | PASS | Top-down body and four heavy leg pairs form one compact spider. |
| BAG Avalanches | PASS | Revised pair of blunt broken snow masses replaces rejected comet, wave, and helmet reads. |
| CAR Millwrights | PASS | Exact CAR interlock remains readable; no fake or extra glyphs. |
| EAS Reapers | PASS | Exact rising EAS remains clear. |
| WEI Wainwrights | PASS | Exact WEI and wide center counter survive at 20 points. |
| SPR Lodestars | PASS | Exact SPR remains compact with a forward terminal. |
| WIL Lodestars | PASS | Exact WIL, wide base, and rising terminal remain visible on charcoal. |
| WAI Spires | PASS | Three fused basalt columns and a connected magenta plane remain coherent on charcoal. |

## Verification

- Manifest reconciliation: 12/12 exact filenames and palettes.
- PNG contract: 12/12 RGBA, 256×256, binary alpha, both literal palette colors, at least 10-pixel clearance, and under 196,608 bytes.
- Meaningful filled regions: 12/12 at six or fewer using an eight-connected, 169-pixel minimum-area audit, followed by visual feature review.
- Review sheets: 6/6 at 1120×620 with the required size, surface, proposed nickname or approved abbreviation, and family label.
- Exact letterforms: CAR, EAS, WEI, SPR, and WIL are visually exact at 20 and 44 points.
- Near-duplicate audit: no suspicious silhouette match among the twelve candidates or against 166 shipped marks.

The remaining visual judgment risk is Avalanche: as an abstract weather mark, its identity depends on the label more than the animal, fish, and letter marks do. It nevertheless passes because the final treatment clearly uses two blunt broken masses and no longer resembles the rejected comet or wave variants.
