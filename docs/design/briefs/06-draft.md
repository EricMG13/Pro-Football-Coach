# Claude Design Brief 06 — Draft Suite

Scope: the three offseason draft screens — Scouting, Draft Day (full-screen), and the Scouting accuracy ledger (04-SCREENS-UI.md §13).

Inherits docs/design/briefs/00-system.md in full: tokens, demo teams (New York Empire NYE #14294B/#C9A227 vs Boston Harbormen BOS #0E3B2E/#C8CFD4), voice registers, staging notation and channel-tag vocabulary, platform physics (Dynamic Type XXXL, 4.5:1 measured contrast, 44×44pt targets, no color-alone state, everything fictional). Do not restate; do not deviate.

## Suite emotional job (04 §13 — one job, three screens)

**Job: draft night is the season's Christmas (FM-08) — scarcity, reveals, and being proven right.**

The three screens are that sentence in order: Scouting is scarcity (spending a finite budget to thin the fog), Draft Day is the reveal, the accuracy ledger is being proven right — or wrong — in writing.

---

## Screen 1 — Scouting (in-season weekly + draft stage)

Content inventory (04 §13):
- Points budget — the scarce resource, a header figure that visibly depletes as actions are bought.
- Prospect **DataTable** with fogged ranges — a prospect's OVR is a range (±8 fog per 02 §8), two tabular figures, e.g. "68–84". Column picker and persistent sort per the standard DataTable.
- Actions as proper buttons with visible costs: **Narrow** · **Reveal** · **Full report** — each label carries its point cost in system voice.
- Watchlist (pin prospects; watchlisted state must be word/symbol, not tint alone).
- Your prediction lines, recorded per full report (02 §8: range, potential read, comparison line) — shown on the prospect so the player knows the save is keeping receipts for the ledger.

Staging notes: no DESIGN §2.3 row fires here — the screen renders settled. Buying a Narrow/Reveal updates the range via `count`; no hold, no stinger. The drama is budgeted for draft night.

## Screen 2 — Draft Day (full-screen) — PRIMARY

Presented full-screen (04 navigation skeleton), portrait.

Content inventory (04 §13):
- On-the-clock card — pick number, team on the clock, clock figure.
- Pick ticker — recent picks as compact rows (pick number, team mark, name, position).
- **Board** vs **Best available** tabs.
- **PICK** action — ≥44×44pt, with confirm step.
- Trade-up/down sheet with value chart (partner, assets each way, true value verdict).
- War-room grade toast after your pick.
- Hyped-prospect rise/fall cards (press voice, byline chip, face — narrative law applies).
- Round selector.
- UDFA quick-sign step (post-round-7 state).

Staging notes: the pick reveal is the DESIGN §2.3 **"Draft pick"** row, exactly — anticipate: card with pick number, `hold` → resolve: name reveals, then position/college/grade `stagger` → settle: war-room grade + fit line. Channels: `[SND card]`, `[HAP reveal]`. Frames are discrete states; if a frame depicts mid-reveal, label it with its stage name.

Frame states: the **light** frame shows the decision state — Empire on the clock, board tab active, PICK live. The **dark** frame shows the settled reveal — the pick landed (name, position, college, grade), war-room grade toast visible. The **XXXL** frame repeats the light state at accessibility XXXL: ticker rows, range figures, and the PICK confirm must survive without truncation.

## Screen 3 — Scouting accuracy ledger (post-draft + season-end)

Content inventory (04 §13, backed by 02 §8):
- How your board graded out — headline fact in system voice, canonical sample: "Your board hit on 7 of 11 top-100 calls."
- Per-report LedgerRows: your recorded prediction (range, potential read, comparison line) against the revealed truth; hit/miss as word + positive/negative status accent, never tint alone.
- Two moments in the calendar: post-draft (immediate grade) and season-end (how year-one play graded the board).

Staging notes: no §2.3 row exists for grading — render settled unless the open question below resolves otherwise.

---

## Frame list (exports to docs/design/mockups/)

- `06-draft-draftday-light.png` — primary, decision state
- `06-draft-draftday-dark.png` — primary, settled-reveal state
- `06-draft-draftday-xxxl.png` — primary, light state at accessibility XXXL
- `06-draft-scouting-light.png`
- `06-draft-ledger-light.png`

## Demo-data guidance

- Empire is on the clock: "Round 1 · Pick 14 — New York Empire", 2027 class. Harbormen are the counterparty in the trade-up/down sheet — the two demo teams cover every two-team interaction; invent no other teams.
- Reuse Darius Reyes (WR, #11, Empire) as roster context, not as a prospect — e.g. a drafted receiver's fit line: "Slots in behind Darius Reyes on your board."
- Invent prospects freely: neutral realistic names and **fictional colleges** (e.g. "Malik Tanner · QB · Carverton State"). Never real schools, real players, or draft-media lookalikes; bylines on rise/fall cards are fictional per the narrative law.
- Fogged ranges spanning a tier boundary (e.g. 68–84) are the normal case — pick demo ranges that expose the tier-color question below rather than dodge it.

## Open questions (surface, do not fill)

1. Tier color for a fogged range: tier colors are defined for single figures; a range like 68–84 spans tiers. Neutral label color, midpoint tier, or something else?
2. War-room grade scale: letter grades (A–F), word tiers, or a figure? 02 §8 and 04 §13 name the toast but not its scale.
3. Draft-day occasion treatment: 02 §8 calls for "full occasion treatment," but the §2.7 ladder is schedule-based. Which accent and chip does draft night take — marquee gold, a draft-specific fictional broadcast identity, or a new ladder row?
4. Does a trade accepted mid-draft fire the §2.3 "Cap move" staging, or stay unstaged inside the sheet to protect the clock's pacing?
5. Does the season-end accuracy grading earn a staged reveal (it is "being proven right"), which would mean a new §2.3 row — or does it render settled?
6. Does the pick reveal warrant a storyboard sheet export (as the hero surfaces received), or are the discrete light/dark states sufficient canon?
