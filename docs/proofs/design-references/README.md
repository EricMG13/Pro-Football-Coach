# Design-reference sheets — renders for review

Full-page renders of the ten `*-v4.dc.html` design-reference sheets at the repository root, so
they can be reviewed on a device without opening the HTML. **The HTML files are the deliverable;
these PNGs are a convenience.** Neither is canon — `docs/04-UX-AND-DESIGN-SYSTEM.md` is the only
canonical home, and a value appearing only in a sheet has not shipped.

Rendered 2026-08-14 with headless Chromium at 1600 pt wide, full content height, downscaled to
1280 px. Pinch-zoom to read the contract blocks.

**Supersedes the eight `*-v3-sheet.png` renders**, deleted the same day. The v3 sheets rendered the
retired violet system — action violet, live green — which Floodlit's palette replaced (action gold,
live/negative red) on 2026-08-14; re-annotating the old renders in place would have produced images
that read as sourced while showing colours canon no longer holds, so the set was redrawn instead.
Two sheets are new: `depth-v4` and `gauge-v4`, covering the twelve Floodlit primitives `04` §6.5
registry 24–35 added the same day.

| Sheet | Registry entries | What it covers |
|---|---|---|
| `tokens-v4-sheet.png` | — | The `04` §6.1/§6.2/§6.3 system in both appearances: Floodlit colour roles on their real surfaces with measured ratios, type ramp through AX5, spacing and the `CutCorner` radii to scale, the synthetic team trio, a Reduce Transparency rendition |
| `depth-v4-sheet.png` | 24–28 | **New.** The five `World` backdrops, the three depth levels and the deep-panel contrast rule, `CutCorner` and the glass edge, grain, the blur budget, Reduce Transparency flattening, the `Stage` safe-area diagram |
| `gauge-v4-sheet.png` | 29–35 | **New.** The proportion vocabulary — `ArcGauge`, `ValueRing`, `AttributeDial`, `ShareBar` — at all four scales, plus the drawn marks `StarRating`, `Pennant`, `TimeoutMarks` |
| `chrome-v4-sheet.png` | 1–5 | Route pill, `GoButton` action styles, `coachWorldDeskSurface` as the explicit opaque fallback to `GlassPanel`, blank photo plate, world strip with the advance-affordance state pair |
| `table-v4-sheet.png` | 7–10, 17, 18 | Dense table with `ValueRing` inline, column sets, list controls, rating badge in both quotable and production-fill forms, status-chip vocabulary, role tokens |
| `person-v4-sheet.png` | 6, 11, 12, 16 | Identity band on standard glass, delta marks, confidence tags across four knowledge states, form line with a bounded last-5 |
| `readout-v4-sheet.png` | 13–15 | Verdict line drawn in both the shipping form (slot empty, gap ID in place) and the target form, per the verdict-state rule; meter with over-capacity; opposed bars |
| `week-v4-sheet.png` | 19 | Agenda rows as costed commitments, the week grid, load-policy ladder with its derived-cost region shipped omitted until G-14, hub tiles |
| `broadcast-v4-sheet.png` | 20–22 | Score bug, lower third, call-in card, key-moments row — the Broadcast-marks class (cap 3) |
| `failure-v4-sheet.png` | 23 | Empty, error, interrupted, loading and delegated states inside their owning compositions; the interrupted state's preserved-items line applies the shipping/target pattern to gap G-15 |

Every card states its compliance with the ten-point card contract in
`docs/briefs/2026-08-12-reference-library-plan.md` §4: both appearances with measured contrast
ratios quoted from canon, widths and touch targets, states rather than one happy instance, the
synthetic team trio wherever team colour is touched, one VoiceOver sentence per data row, the
reduced form of every animation, verdict lines naming the engine computation that backs them or the
gap that does not yet, and a density-budget cost in the `04` §4.5 currencies.

All identities are mechanical placeholders labelled *pending generator output*; sample content is
fictional and original per the `CLAUDE.md` legal guardrail.
