# Screen mockups — five first examples

Landscape iPhone compositions of the five example screens the design system already uses as
proofs: **Coaching HQ**, **Roster**, **Player Profile**, **Recruiting Board**, and **Match Day**.
Drawn from the eight owner-approved `*-v3.dc.html` sheets. **Open `index.html`.**

These files are **not canon**. `docs/04-UX-AND-DESIGN-SYSTEM.md` owns every value. They are **not** a
ninth design-reference sheet and must not sit at repository root as `*-v3.dc.html`. A value
appearing only here has not shipped. This is not the full 62-family inventory.

## What this is

Full-screen **844 × 390** (install floor) device frames, self-contained HTML and CSS: no JavaScript,
no CDN, no web font, no images, no emoji. CSS px are read as pt. Dark appearance is the desk
default. The `04` §10 proof-gate trio — Coaching HQ, Recruiting Board, Match Day — also renders
light.

Identities follow `docs/briefs/2026-08-12-reference-shared-world.md`: Week 9, preparation day,
Example State 6-2, next Example Coastal (away), Coach Sample, Coordinator Sample, Player
Fourteen–Fifty-Four. All names are mechanical placeholders pending generator output.

## Honest blanks

Inside a frame, empty means empty: no G-02 staff verdict, no G-06 play art. Prototype truth and gap
IDs live in gallery chrome outside the device frame (`04` §4.4).

## Screenshots

Dark appearance, 844 × 390 at 2×:

| Family | PNG |
|---|---|
| Coaching HQ | `08-coaching-hq-dark.png` |
| Roster | `16-roster-dark.png` |
| Player Profile | `18-player-profile-dark.png` |
| Recruiting Board | `24-recruiting-board-dark.png` |
| Match Day | `14-match-day-dark.png` |


```
python3 docs/proofs/screen-mockups/generate.py
```

`generate.py` and `_common.py` are the emitter. The HTML is the deliverable.
