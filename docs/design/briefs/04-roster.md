# Claude Design Brief 04 — Roster & Stats

Scope: the four roster-and-numbers surfaces — Team Overview (Team tab root), Depth Chart & Roster, Stats Suite, and Awards & Honors. Paste together with `00-system.md` as one Claude Design session; exports land in `docs/design/mockups/`.

Inherits docs/design/briefs/00-system.md in full: tokens, demo teams (New York Empire NYE #14294B/#C9A227 vs Boston Harbormen BOS #0E3B2E/#C8CFD4), voice registers, staging notation and channel-tag vocabulary, platform physics (Dynamic Type XXXL, 4.5:1 measured contrast, 44×44pt targets, no color-alone state, everything fictional). Do not restate; do not deviate.

---

## Team Overview (Team tab root) — 04 §9

**Job: your program, its identity, its health.**

Content:
- Header band in Empire colors: team mark, "New York Empire", record, Reputation figure, coach line. This is the surface's one team-color band; everything below sits on neutral cards.
- Navigation rows: Schemes · Depth Chart & Roster · Injury Report (count badge; empty state "All players healthy") · Training Focus · Team Stats (opens a DataTable sheet).
- Featured-players strip: the 5 faces carrying your storylines, each with its one-line arc (Reyes first: "Contract year — asking 3 yrs · $9.5M/yr").

Staging notes: no staged moment lives here — the screen renders settled. The Injury Report badge is a count (number + word), never a colored dot alone. Strip faces are initialed circle marks in team colors; no faceless entries.

## Depth Chart & Roster — 04 §10 — PRIMARY

**Job: control — the roster obeys you, and tells you what it costs.**

Content:
- Team card: overall figure, record, Auto-Sort action, Injury Report link; roster counts "53/53 · Practice squad 16" as tabular figures.
- Per-position cards in scroll order: ranked rows = depth-number circle, name, OVR figure in tier color (tier word available to VoiceOver), age + years-pro chips, status pill, injury icon paired with the pill's word.
- Drag to reorder within a position. Swipe actions: elevate / send down (practice squad) and cut.
- Cut opens a confirm sheet built as fact line + consequence line.
- Deep layer: full-roster DataTable one tap away (column picker: contract, morale, dev arrows; density toggle; persistent sort).
- Click budget: any player's cap hit ≤2 taps from this screen.

Staging notes: the cut confirm is the **Cap move (cut/sign/trade)** row of DESIGN §2.3 — "Cap impact" anticipate, dead money then cap space stagger, consequence line, `[HAP negative]`. The dark frame draws this sheet in its settled state. Frames are discrete states — no drawn drag ghosts; annotate reorder with its stock construction (List edit mode / `.onMove`).

## Stats Suite — 04 §15

**Job: the expertise surface — raw numbers one tap deep, never amputated.**

Content:
- Category chips (9 categories, vetted accents) — a selection control; see open question 1.
- Leader cards per category: rank badge, face, key line, team abbreviation.
- Full DataTable per category one tap deep: column picker, Min-G filter, week/season scope, search, direction toggle.
- Team stats twin of the player table.
- Records sheet: single-game / season / career, franchise + league, seeded historical marks, live chase chips (record-pace hooks).

Staging notes: leader cards are the first render; the table lives one tap below — never a wall of figures as the first screenful. Records browse settled; the **Record broken** row of DESIGN §2.3 fires at the moment a mark falls (in the feed or game), not while browsing here. Chase chips are hook chips ("Rushing record pace — 214 yds behind") and take an outcome accent only once resolved.

## Awards & Honors — 04 §16

**Job: the league notices.**

Content:
- Weekly Players of the Week: faces + one-line reason each.
- MVP race tracker: top-5, each a face + key-numbers line; hook chip on the tracked player.
- Season ceremony with reveal staging.
- All-League / All-Rookie teams as position-ordered lists.
- Hall of Fame: inductions staged; career ledgers open from here.

Staging notes: the ceremony follows the **Award** row of DESIGN §2.3 — nominee context, hold, winner reveal, career ledger line appended, `[SND card]`. The exported frame shows the in-season default state (Players of the Week + MVP race), not the ceremony.

## Frame list — six exports

- `04-roster-depth-chart-light.png` — primary, default roster; WR card near top so the Reyes row is visible.
- `04-roster-depth-chart-dark.png` — dark theme; cut-confirm sheet presented, settled state.
- `04-roster-depth-chart-xxxl.png` — the light state at accessibility XXXL; gutters widen, nothing truncates or overlaps.
- `04-roster-team-overview-light.png` — settled tab root.
- `04-roster-stats-light.png` — receiving category selected; Reyes leader card first.
- `04-roster-awards-light.png` — in-season state.

## Demo data

- Anchor context everywhere: 2026 season, Week 13, Empire 9–3 · 1st Liberty East.
- Reuse **Darius Reyes (WR, #11, Empire)**, OVR 87 in Star cobalt, arc "Contract year — asking 3 yrs · $9.5M/yr". He appears as a featured-strip face, WR1 on the depth chart, the receiving leader card (his 2025 league receiving-yards title supplies the ledger line), and an MVP-race entry.
- The dark-frame cut confirm reuses the canonical pair verbatim: "Cutting Reyes saves $3.1M now" / "$6.2M dead through 2028."
- The record chase chip may reuse the hub hook "Rushing record pace — 214 yds behind", pinned to an invented Empire RB.
- Invent every other name freely — neutral, realistic, fictional; never real players, coaches, teams, or networks. Harbormen (BOS) players may fill league-wide leader and award slots.

## Open questions — surface these, do not fill silently

1. Stats category "chips" are selection controls, but DESIGN §7 says a Chip is never a control. Confirm the stock construction (segmented control, filter-button row, or menu) before drawing.
2. The nine stat categories are not enumerated in 04 §15 — confirm the list from 02-GAME-DESIGN rather than inventing it.
3. League-wide surfaces (leaders, All-League, Hall of Fame) need more clubs than the two demo teams, and 00-system forbids inventing teams. May other-club rows use neutral placeholder marks, or does the demo-team lock extend here?
4. Team Overview's "Team Stats" sheet vs. the Stats Suite team twin: the same surface reached twice, or a reduced team-only table?
5. Depth-order accessibility: what is the non-drag reorder alternative (edit mode, row actions) for the VoiceOver and XXXL story?
6. The Reputation figure on the Team Overview band: its scale, and whether it takes tier coloring or stays neutral.
