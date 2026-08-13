# Screen mockups — 62 families

Landscape iPhone compositions of every `04` §8 screen family, drawn from the eight owner-approved
`*-v3.dc.html` sheets. **Open `index.html`.**

These files are **not canon**. `docs/04-UX-AND-DESIGN-SYSTEM.md` owns every value. They are **not** a
ninth design-reference sheet and must not sit at repository root as `*-v3.dc.html` —
`DesignContractTests.designSheets()` asserts exactly eight of those. A value appearing only here has
not shipped. Where a mockup and a v3 sheet disagree, the sheet governs; where a sheet and `04`
disagree, `04` governs.

## What this is

Full-screen **844 × 390** (install floor) device frames, self-contained HTML and CSS: no JavaScript,
no CDN, no web font, no images, no emoji. CSS px are read as pt. Dark appearance is the desk
default. The `04` §10 proof-gate trio — Coaching HQ, Recruiting Board, Match Day — also renders
light.

Identities follow `docs/briefs/2026-08-12-reference-shared-world.md`: Week 9, preparation day,
Example State 6-2, next Example Coastal (away), Coach Sample, Coordinator Sample, Player
Fourteen–Fifty-Four. All names are mechanical placeholders pending generator output. Professional
and promotion surfaces use Example Union and the shared-world cap meter as a **labelled second
moment**, not the Week 9 college desk.

## Honest blanks

Inside a frame, empty means empty: no invented correspondence, no G-02 staff verdict, no G-06 play
art, no G-14 seven-day practice grid, no trophy on Awards, no realignment event, no generated news
beyond facts the save already owns. Prototype truth and gap IDs live in gallery chrome outside the
device frame (`04` §4.4).

## Regenerating

```
python3 docs/proofs/screen-mockups/generate.py
```

`generate.py` and `_common.py` are the emitter. The HTML is the deliverable.
