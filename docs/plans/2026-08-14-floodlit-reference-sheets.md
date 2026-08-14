# Phase 0b — Redraw the reference sheets in Floodlit

**Phase:** prerequisite to Phase 1 (canon P11.4) and to every family in Phase 5 that has no Floodlit
screen to build against. **Scope:** ten self-contained HTML+CSS sheets, plus the manifest and lint
updates that retarget the suite from the eight v3 sheets to these ten.

`superpowers:writing-plans` is unavailable in this container (recorded already in
`docs/plans/2026-08-14-floodlit-canon-amendment.md`); this plan is hand-written in the style of its
neighbours for the same reason.

## Why this phase exists, and why it is not a re-annotation

The owner decided (this session) to redraw rather than re-annotate. Measurement is why: the eight v3
sheets carry **283 contrast figures the amended `04` §6.1 no longer states and 319 references to the
superseded violet palette**, and their CSS still paints that system. The roles changed *meaning*, not
only value — `action.*` moved violet→gold, `state.live` moved green→red — so patching figures in
place would produce sheets that pass `DesignContractTests`' ratio lint while asserting something
false, which is exactly the failure that lint exists to catch (a plausible number in a row of sourced
ones inherits their authority).

The sheets are the only artefact covering **states** — empty, error, interrupted, loading, delegated
— and the density model applied to real content. Floodlit ships five happy-path screens and none of
that. Phase 5's 47 families with no Floodlit screen have no reference without these.

## The ten sheets

Eight groups carry over from the v3 set; two are new because Floodlit added twelve registry entries
(24–35) that no sheet covers.

| # | Sheet | Registry | Renders |
|---|---|---|---|
| 1 | `tokens-v4` | — | `04` §6.1–§6.3: roles on real surfaces with measured ratios, the type ramp through AX5, spacing, the cut-corner shapes, the team trio |
| 2 | `depth-v4` | 24–28 | **new** — the five worlds, the three depth levels (world / standard panel / deep panel), the glass edge, grain, the blur budget, Reduce Transparency flattened |
| 3 | `gauge-v4` | 29–35 | **new** — the proportion vocabulary at all four scales (`ArcGauge`, `ValueRing`, `AttributeDial`, `ShareBar`), plus the drawn marks (`StarRating`, `Pennant`, `TimeoutMarks`) |
| 4 | `chrome-v4` | 1–5 | route button, action styles, desk surface, blank photo plate, world strip |
| 5 | `table-v4` | 7–10, 17, 18 | dense table, column sets, list controls, rating badge, status chips, role tokens |
| 6 | `person-v4` | 6, 11, 12, 16 | identity band, delta marks, confidence tags, form line |
| 7 | `readout-v4` | 13–15 | verdict line with its honest degraded form, meter, opposed bars |
| 8 | `week-v4` | 19 | agenda rows, week grid, load-policy ladder, hub tiles |
| 9 | `broadcast-v4` | 20–22 | score bug, lower third, call-in card, key-moments row |
| 10 | `failure-v4` | 23 | empty, error, interrupted, loading, delegated, inside their owning compositions |

## What every sheet must do (mechanical, lint-checked)

Reproduced from `Tests/SimTests/Suites/DesignContractTests.swift`'s "Design reference sheets" suite,
which this container cannot run but whose logic was replicated in Python and is re-run after each
sheet lands (see Verification):

1. First line exactly `<!-- @dsCard group="<name>" -->`.
2. No `<script`, no `https?://`, no `@font-face`, no `<img>` — self-contained, no CDN, no web font.
3. Every `\d{1,2}\.\d{2}` figure appearing in prose (not inside `<style>`, not inside a `style="..."`
   attribute, not a `×N.NN` dose multiplier) must be a figure `04` §6.1 states. Ratios are quoted,
   never computed at authoring time.
4. No emoji. Every synthetic identity labelled `pending generator output`.

## What every card states about itself (the ten-point contract, plus one)

Inherited from `docs/briefs/2026-08-12-reference-library-plan.md` §4, which `04` §6.5 adopted, plus
the clause Reduce Transparency adds this phase:

both appearances with their measured ratios · all three window widths (852×393, 874×402, 932×430)
plus the 844×390 install floor and 956×440 ceiling, and AX5 · 44 pt targets · every state a family
can be in, not one happy instance · the synthetic team trio (never a real identity) · one VoiceOver
sentence per data row · the reduced form of every animation · a verdict backed by a named engine
computation or carrying its gap ID (`04` §6.1's honest-degraded form) · its density-budget cost in
§4.5's five currencies · no token value not already in `04` · **its Reduce Transparency flattened
form** — every panel at its opaque equivalent, grain dropped, world replaced by `world.page`.

## The shared Floodlit CSS foundation

To keep ten independently-authored sheets from drifting, every sheet's `:root` opens with the same
block of custom properties, copied verbatim from the amended `04` §6.1/§6.2/§6.3 tables (the palette
derivation is `docs/plans/2026-08-14-floodlit-canon-amendment.md`). This is not a build dependency —
each sheet stays self-contained per the lint — it is a copy-paste discipline enforced by review, the
same way the v3 set kept `--dk-*`/`--lt-*` consistent across eight files without a shared stylesheet.

```css
:root{
  /* dark */
  --dk-page:#060A12; --dk-work:#141A26; --dk-raised:#1E2735;
  --dk-c1:#F6FAFF; --dk-c2:#A9BACE; --dk-cq:#8496AC;
  --dk-act:#FFC53D; --dk-destr:#FF8E9C; --dk-live:#FF8E9C; --dk-pos:#7DF0B6;
  --dk-warn:#FFB03A; --dk-info:#9CC8EE; --dk-college:#C79AE4; --dk-pro:#9CC8EE;
  --dk-fill-live:#FF3B54; --dk-fill-pos:#37E08A; --dk-fill-warn:#FFB03A;
  --dk-fill-info:#6FA8DC; --dk-fill-college:#B07BD6; --dk-onfill:#150F02;
  --dk-turf:#1C6E42; --dk-tband:#1F764A; --dk-fline:#F5F7FA;
  --dk-fann:#FFC53D; --dk-flabel:#FFE196; --dk-flive:#C6F24E;
  /* light */
  --lt-page:#EDF1F6; --lt-work:#FAFBFD; --lt-raised:#DCE3EC;
  --lt-c1:#0B111C; --lt-c2:#414B5C; --lt-cq:#566274;
  --lt-act:#7A5200; --lt-destr:#A3202F; --lt-live:#A3202F; --lt-pos:#14653C;
  --lt-warn:#704C00; --lt-info:#1E5A8C; --lt-college:#6A3E9C; --lt-pro:#26608D;
  --lt-turf:#D9E7DD; --lt-tband:#D0E0D5; --lt-fline:#0E1218;
  --lt-fann:#7A5200; --lt-flive:#3F6300;
  /* team trio, synthetic, pending generator output */
  --t1p:#14382A; --t1s:#D9B23C; --t1i:#F2F5F3;   /* dark-primary */
  --t2p:#E9E0C9; --t2s:#6E3038; --t2i:#18202B;   /* light-primary */
  --t3p:#555B66; --t3s:#D9DDE4; --t3i:#FFFFFF;   /* low-chroma */
  /* shape */
  --panel:4px 22px 4px 22px; --row:3px 14px 3px 14px; --action:22px 22px 22px 5px;
  --deep-opacity:0.78;
}
```

## Migration order, so the suite is never red on a second axis

1. Write and render all ten v4 sheets, alongside the v3 files, which stay on disk in the interim.
   **The v3 ratio lint is red right now**, on the suite as it exists today, because canon moved in
   Phase 0 before any sheet did — 283 figures the v3 set quotes are no longer in `04`. This is named
   rather than hidden: it is the accepted cost of moving canon first, chosen because the alternative
   — holding canon back until ten sheets are drawn — blocks Phases 2–5 for longer than the sheets
   take to write.
2. Once all ten exist and render clean: change `designSheets()`'s suffix filter in
   `Tests/SimTests/Suites/DesignContractTests.swift:70` from `-v3.dc.html` to `-v4.dc.html`, and the
   count assertion at `:213` from 8 to 10.
3. Delete the eight v3 files. `git show` recovers them, per the manifest's own no-archive rule.
4. Update `DOC-MANIFEST.md` §4a to name the v4 set and record the v3 supersession.

## Verification

This is the one phase in the whole programme this container can verify past text-matching, because
Chromium is present at `/opt/pw-browsers/chromium` (confirmed working via Playwright, proven against
`tokens-v3.dc.html` before any v4 file was written).

- **Render.** `node render_sheet.js <sheet>.dc.html <out>.png` — 1600 pt wide, full content height,
  screenshotted, matching `docs/proofs/README.md`'s stated recipe (headless Chrome at 1600 pt,
  cropped to content, downscaled to 1280 px for the committed index).
- **Look at it.** Each render is read before the sheet is called done — layout breakage, illegible
  contrast, and CSS mistakes are visible in the screenshot in a way the lint cannot catch.
- **The mechanical lint, replicated.** `docs/plans/2026-08-14-floodlit-canon-amendment.md`'s
  `contrast.py` companion script re-runs the exact ratio-matching regex from
  `DesignContractTests.swift` against each new sheet before it is committed.
- **Owed on the host, not claimable here:** `swift run SimTests --design-contract-only` (or the
  equivalent flag) for the real suite, once Swift is available.

## Gates

G4 (scope) only, same reasoning as Phase 0. G1/G2 are not claimable here. `docs/STATUS.md` records
the v4 sheets as rendered-and-inspected-in-container but not machine-verified against the real Swift
suite until the host runs it.
