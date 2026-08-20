# Stitch composition studies — 2026-08-13

**These are not canon, not design authority, and not a replacement for anything.** They are eight
machine-generated boards produced by Google Stitch against the eight `*-v3.dc.html` design-reference
sheets, run for **composition and UX ideas only**. Every value in them is untrusted. `04` remains the
only canonical home for a value, and the `*-v3.dc.html` sheets remain the owner-approved (2026-08-12)
definitive references.

The harvest — which ideas are worth adopting, which are rejected, and the errors the tool made that
matter — is `docs/briefs/2026-08-13-stitch-composition-harvest.md`. Read that, not these images, to
decide anything.

| Board | Corresponds to | Verdict |
|---|---|---|
| `sheet1-tokens.png` | `tokens-v3.dc.html` | Best of the set. Three real ideas |
| `sheet2-chrome.png` | `chrome-v3.dc.html` | Weak. Under-filled; one idea |
| `sheet3-table.png` | `table-v3.dc.html` | Strong. Five ideas |
| `sheet4-person.png` | `person-v3.dc.html` | Strong. Four ideas |
| `sheet5-readout.png` | `readout-v3.dc.html` | Half-rendered. Three ideas, one of them the best on the whole run |
| `sheet6-week.png` | `week-v3.dc.html` | Failed. Grid empty, specimens missing. One idea |
| `sheet7-broadcast.png` | `broadcast-v3.dc.html` | Mostly failed. Text rendered near-black on near-black. Two ideas |
| `sheet8-failure.png` | `failure-v3.dc.html` | Rendered in the wrong appearance and invented a networked failure model. Four ideas anyway |

## How they were made

Google Stitch MCP (`stitch.withgoogle.com`, remote MCP server, connected 2026-08-13). A `DESIGN.md`
built from the `04` §6.1–§6.3 production values was uploaded and turned into a Stitch design system
named "Coach World v3" so the boards would sit in roughly the right visual world. Each board was then
generated from a written prompt describing that sheet's registry entries, its composition, and its
density obligation. Prompts are recorded in the Stitch project
(`projects/14845379004702356092`, private).

## What the tool got wrong, at a glance

Do not copy any of this forward:

- **Palette drift.** Stitch re-derived its own Material-style palette on import; the shipped violet
  `#9964E8` renders closer to `#d6baff` in several boards, and the ground drifted to `#11131d`.
- **Fabricated contrast ratios.** `sheet1-tokens.png` prints state-role ratios (9.82, 9.45, 10.12,
  6.54, 7.89) that are **not** the measured values in `04` §6.1 (11.23, 10.77, 12.13, 7.27, 8.37).
- **Invented networked failure states.** `sheet8-failure.png` shows "DATA SYNC FAILURE / Unable to
  fetch remaining 142 prospects / RETRY CONNECTION". The product has no network of any kind. Every
  failure it draws of this class is wrong at the architecture level.
- **Invented authority furniture.** "CONFIDENTIAL", "SYS.VER 4.2.1", "DATE 2023.10.24", "DESK
  REGISTER V2.4" — none of these exist.
- **Mow bands drawn as an information channel** in sheets 1 and 7, at a contrast that reads as data.
  `04` §6.1 requires the opposite.
- **Saturated full-width status bars** in `sheet3-table.png` where the registry calls for compact chips.
- **Density failure** in sheets 2, 5, 6: panels left half empty, which is the exact defect `04` §4.5
  prices.

All names and identities in the boards are fictional placeholders, per the `CLAUDE.md` legal
guardrail. No real programme, club, person or colour pair was supplied to the tool or appears in the
output.
