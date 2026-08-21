# FM-proxy proof screens

These screenshots are DEBUG reference fixtures, not simulation outcomes or final art.
They demonstrate the desktop-class density target: desktop-style information density adapted to
landscape iPhone, using original fictional identities and native controls rather than copied assets.
The standard-size reference target uses 10–12 pt dense type; AX5 proofs reflow and scale.

**The definitive design references are the eight `*-v3.dc.html` sheets at the repository root**
(owner-approved 2026-08-12; renders and index in `docs/proofs/design-references/`). These proof
screenshots are evidence of what the build renders today, not a design authority; where a proof and
a sheet disagree, the sheet governs, and where a sheet and `04` disagree, `04` governs.

Older proof variants were captured at the 844×390 landscape viewport; the supported window is now
844 × 390 (install floor) through 956 × 440 (ceiling) per `04` §7 and D15. Light/default renders at
2× and dark/AX5 at 3×. AX5 is an accessibility reflow proof, not a density reference.
The canonical component rules are `04-UX-AND-DESIGN-SYSTEM.md` §6.4: 10–12 pt micro-type, tabular
numbers, zero-inset 24–28 pt rows, adaptive data tiles, heatmap badges and context-preserving
popovers or detented sheets.

| Proof | Light / standard | Dark / AX5 |
|---|---|---|
| Coaching HQ | `coaching-hq-light-standard.png` | `coaching-hq-dark-ax5.png` |
| Recruiting Board | `recruiting-board-light-standard.png` | `recruiting-board-dark-ax5.png` |
| Match Day | `match-day-light-standard.png` | `match-day-dark-ax5.png` |

## Coaching HQ production read-model proofs — iPhone 17e

These dated captures replace the older Coaching HQ sample frames as production-render evidence:

| State | Proof |
|---|---|
| Dark / default Dynamic Type | `coaching-hq-production-dark-default-iphone17e-2026-08-21.png` |
| Dark / AX5 | `coaching-hq-production-dark-ax5-iphone17e-2026-08-21.png` |

Both were captured from the DEBUG production root using `PROOF_NEW_CAREER=424242` and
`PROOF_SCREEN_NUMBER=8`. That seam starts the same deterministic career and immutable simulation
read models as the interactive new-career path; it does not route to `RootView` sample data and is
intentionally non-persistent. The app was rebuilt from the current source and installed on an
iPhone 17e simulator running iOS 26.5. The AX5 image is the top of the screen's scrolling
accessibility composition.

Simulator appearance and content-size readback confirmed `dark` and
`accessibility-extra-extra-extra-large`. IDB was not installed, so no semantic accessibility-tree
audit is claimed. Physical-device VoiceOver, Voice Control, Switch Control, sound and haptic checks
remain `manual-required`.

## Personnel proofs — iPhone 17 Pro Max

`personnel/` holds the Roster and Player Profile pair at the 956 x 440 landscape
viewport of an iPhone 17 Pro Max, captured from the DEBUG `--roster` and
`--player-profile` entry paths against the fixed sample roster.

| Proof | Light / default | Dark / AX5 |
|---|---|---|
| Roster | `personnel/roster-light-default-iphone17promax.png` | `personnel/roster-dark-ax5-iphone17promax.png` |
| Player Profile | `personnel/player-light-default-iphone17promax.png` | `personnel/player-dark-ax5-iphone17promax.png` |

`simctl` writes the framebuffer in device-portrait while the app renders
landscape-only, so each capture is rotated 90 degrees after the fact. The
geometry is the app's own landscape layout, not a resize. AX5 reflows both
screens to one scrolling column, so those two frames show the top of that
column rather than the whole screen; they are accessibility evidence, not the
density reference.

Personnel and player imagery uses the shared blank-photo treatment. Match Day depicts one recorded frame: all 22 actors,
model-owned field direction, line of scrimmage, first-down line, score context,
causal commentary, and exactly five primary controls.

The base game does not fetch procedural portraits, team marks, stadium imagery,
or fonts. A future custom-universe importer may accept validated local media while
preserving the blank fallback, offline saves, accessibility, and deterministic identity.

Physical-device VoiceOver, Voice Control, Switch Control, haptic, and audio checks
remain release verification work; these images do not claim those manual checks.
