# Figma treatment pool — 2026-08-13

**Not canon.** A pool of alternative treatments for three registry entries, built so a choice can be
made by comparison rather than by argument. `04` remains the only canonical home for a value; the
eight `*-v3.dc.html` sheets remain the owner-approved references. Nothing here has been adopted.

Source file: `https://www.figma.com/design/keOb2L6KS9jPdJkN3cNvRi` (Eric Sea's team, drafts).

## What is in it

| Board | Registry | Variants |
|---|---|---|
| `pool-verdictline.png` | 13 `VerdictLine` | V1 band · V2 card · V3 split · V4 shipping/target pair |
| `pool-densetable-row.png` | 7 `DenseTable` | R1 text chip + floating status · R2 leading swatch + fixed status column · R3 chip carrying its own value · R4 selection pair |
| `pool-confidencetag.png` | 12 `ConfidenceTag` | C1 separate chip · C2 fill-width confidence · C3 range-as-value · C4 four-state escalation strip |

Every variant is drawn at the true **852 pt** composition width on **26 pt** tracks, and carries a
one-line note stating what it costs and what it buys. The notes are arguments, not conclusions.

## Why this was built in Figma rather than generated

The one thing Figma does that Google Stitch could not: **every fill is bound to a variable holding
the exact `04` §6.1 production value.** Two collections exist — `Coach World Dark` and
`Coach World Light` — 30 roles each, 60 variables, scoped by purpose (`TEXT_FILL` for content roles,
`FRAME_FILL`/`SHAPE_FILL` for surfaces, and so on). Nothing on these boards is a guessed hex. The
Stitch run drifted the palette on import and printed fabricated contrast ratios; this file cannot,
because the colours are not typed in at the point of use.

## Constraints hit, recorded so nobody re-discovers them

The account is a **View seat on a Starter team**. Three limits shaped the result:

1. **One mode per variable collection.** Dark and Light could not be two modes of one collection, so
   they are two collections. A component cannot therefore be flipped between appearances by switching
   a mode — the light boards would have to be built separately.
2. **Three pages per file.** The ConfidenceTag pool sits on the renamed default page because a fourth
   could not be created. Further pools need a second file.
3. **Page backgrounds cannot be variable-bound.** Each page background is a literal `#080A14`; the
   board frame inside it is bound to `world/page` and is the surface that matters.

Also: Figma has no SF Pro, so the boards render in **Inter**. The type ramp is right by size, weight
and leading, and wrong by family. The native render stays authoritative — the same caveat the v3
sheets already carry about `font-stretch` in desktop Chrome.

## Standing survey of what else can generate samples

Checked 2026-08-13. The MCP registry returns **no** other design-generation connectors — searches for
design, UI generation, mockup, prototype, component library, Penpot and Framer all came back empty.
What is actually available:

| Tool | Good for | Not good for |
|---|---|---|
| **Google Stitch** (connected) | Fast idea generation; unexpected compositions | Any value. Drifts palettes, fabricates ratios, assumes a networked product |
| **Figma** (connected) | Token-bound variants, true-width comparison, anything that must be exact | Volume — every board is hand-built in the Plugin API |
| **Headless Chrome + the `.dc.html` sheets** | The existing pipeline; exact control; already how the v3 sheets render | Ideation — it only draws what is already decided |
| **Artifact** | Publishing a comparison page for review on a phone | Design fidelity at 852 pt |
| **iOS Simulator** | The only source of a *real* proof, once the app builds | Anything pre-implementation |

The division that held on this run: **Stitch proposes, Figma disambiguates, Chrome renders canon.**

All names and identities are fictional placeholders per the `CLAUDE.md` legal guardrail.
