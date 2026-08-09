# Claude Design Brief 00 — Primetime: System Foundation & Three Hero Surfaces

**How to use this file:** paste it, whole, as the prompt for a Claude Design session. It is self-contained — no repository access is assumed. Exported frames become visual canon in `docs/design/mockups/`. This brief locks the design system; per-screen briefs (01+) inherit it by reference and may not restate or alter it.

---

## Mission

You are designing the visual and staging identity for **Pro Football Coach**, a premium, offline, text-first pro-football franchise simulator for iPhone. The player is a head coach/GM of a fictional 32-team league: sim games, manage the salary cap, draft, trade, build a dynasty for decades.

The product's identity is **a broadcast, done in text**. A professional telecast is confident and plainspoken; its drama comes from staging — pacing, the cutaway, the stat card fired at the earned moment, the held beat before a number lands. Your job: make three high-stakes surfaces *sing* under this identity. If the system can't make these three work, it fails here, cheaply — that is this brief's purpose.

This is a design-system stress test, not production UI. But the build target is native SwiftUI with stock controls, so every element you draw must be plausibly buildable that way: no hand-rolled navigation, no custom tab bars, no glassmorphism, no 3D.

## The system (locked tokens — use exactly these)

**Color.**
- Page: iOS `systemGroupedBackground` (#F2F2F7 light / #000000 dark). Cards: `secondarySystemGroupedBackground` (#FFFFFF light / #1C1C1E dark). Text: `label` / `secondaryLabel`. Hairlines: `separator`.
- Team color appears as **one band per surface** — a header band above the content it labels — never as a body background. The band may carry a subtle two-stop gradient of the team's two colors, **but the gradient may shift at most 20% toward the secondary color wherever text sits on it, so white text passes 4.5:1 everywhere on the band.**
- Demo teams (use these two everywhere; invent no others):
  - **New York Empire (NYE)** — the player's team. Primary #14294B (navy), secondary #C9A227 (gold). White on the navy measures ~14.5:1 — safe.
  - **Boston Harbormen (BOS)** — the opponent in every two-team frame. Primary #0E3B2E (deep harbor green), secondary #C8CFD4 (fog silver). White on the green is safe.
- Rating tiers (text color on white card / dark card): Elite 90+ #6B4BC4/#C3A6FF · Star 84–89 #155CB0/#6BB3FF · Starter 74–83 #22661F/#67D77A · Rotational 64–73 #8A5000/#F5A93C · Fringe <64 #AB2A1E/#FF8A80. A rating is always the number in its tier color — never a colored dot alone.
- Status accents (never raw iOS green/red): positive #1E6B34/#5FD08A · negative #A8322A/#FF8A80 · caution #8A5000/#F5A93C · info #155CB0/#6BB3FF. A **resolved** storyline hook takes positive or negative per its outcome.
- Flat depth: no shadows, no gradients on body surfaces, no blur panels.

**Type.** SF Pro. Display = SF Pro Rounded Heavy at largeTitle (scores, hero numbers). Title = title3 Semibold. Body = body Regular. Label = caption Semibold (chips, column heads). Figures = Semibold with **tabular (monospaced) numerals** — every number that can change. Sentence case everywhere; no ALL-CAPS except 2–3-letter team abbreviations.

**Layout.** iPhone portrait, 393×852pt frame. Single column of cards, 20pt corner radius, 16pt padding, 6/10/16/24 spacing scale, rows ≥52pt. Every tappable element ≥**44×44pt** (both dimensions); adjacent targets ≥8pt apart. Number gutters are type-size-driven — they widen as text scales; never draw a fixed-width gutter that clips a scaled number. Content respects safe areas.

**LedgerRow (component).** The standard data row: label in Body on the left; one or more figures in tabular numerals right-aligned, each in its own right-aligned gutter; row height ≥52pt; hairline separator below; figures carry tier or status color only when the value has one.

**Voice.** Two registers:
- *System voice* (labels, buttons, data): short declaratives, real numbers, no exclamation marks. Pattern: fact line, then consequence line — "Cutting Reyes saves $3.1M now" / "$6.2M dead through 2028."
- *Press voice* (narrative cards, game commentary): personality allowed — a dry beat writer, an opinionated columnist. May exclaim. Attributed with a fictional byline chip (e.g. "M. Okafor — League Wire").

**Narrative law.** Every narrative card shows: a **face** (player/coach identity — render as an initialed circle mark in team colors, no photos), a **headline number**, and a **consequence line**. No faceless cards; no number without its meaning.

**Prediction chips.** Matchup predictions read system-voice: "**Empire by 3 · 61%**" (favorite + margin + win probability). No betting-book notation.

**Staging notation (for storyboards).** Two named patterns:
1. **Reveal pattern** (big numbers): **anticipate** (context line, card dimmed) → **hold** (300ms beat) → **resolve** (figures land in sequence, ~550ms) → **settle** (consequence line appears).
2. **Advance pattern** (the week advance): **tick** (advance acknowledged, feed dims) → **resolve** (new cards land top-down, staggered) → **settle** (hooks rail counters update; any resolved hook takes its outcome accent).

Channel tags annotate frames from this closed vocabulary — sounds: `[SND tick]`, `[SND card]`, `[SND up]`, `[SND down]`, `[SND sting-final]`, `[SND fanfare]`; haptics: `[HAP advanceTick]`, `[HAP cardLand]`, `[HAP reveal]`, `[HAP positive]`, `[HAP negative]`, `[HAP stakes]`, `[HAP milestone]`, `[HAP championship]`. Tags sit in the sheet gutter beneath the frame they annotate. Do not draw fake motion blur; storyboard frames are discrete states.

**Occasions.** The schedule creates presentation occasions. The ladder, concretely — an occasion changes only these three things:

| Occasion | Score-strip / game-card accent | Occasion chip |
|---|---|---|
| Standard | none (neutral hairline) | none |
| Division rival | 2pt accent rule in the *opponent's* primary color + "Rivalry week" label chip | "RIVALRY" |
| **Marquee (game of the week)** | 2pt gold accent rule (#C9A227) + fictional broadcast identity chip | e.g. "SUNDAY PRIME" (invent original names; never real networks or lookalikes) |
| Playoffs | info-accent rule + round chip | "WILD CARD" etc. |
| Championship | full gold treatment on the band only | "CHAMPIONSHIP" |

All mockups in this brief depict the **marquee** occasion (Empire vs Harbormen, game of the week, "SUNDAY PRIME").

## Platform physics (non-negotiable in every frame)

- Dynamic Type: design at default size; produce one stress frame per surface at accessibility XXXL — nothing truncates, nothing overlaps, number gutters widen with the type.
- Contrast ≥4.5:1 for all text against its actual composited background, both themes.
- Touch targets ≥44×44pt.
- No state carried by color alone — every colored value pairs with a number, word, or symbol.
- Everything fictional: team names, player names (invent neutral realistic names), show identities, bylines. No NFL/real-network/real-player references.

## The three surfaces

### Surface 1 — Live Gameday (Call the Plays)

**Emotional job: tension you can feel between snaps — every down is a decision with visible stakes.**

Content (portrait, one column, thumb-reach priority to the bottom): a compact **score strip** pinned at top (NYE and BOS abbreviations with team marks, score, quarter, clock, timeouts as dots, marquee accent + "SUNDAY PRIME" chip); situation line ("3rd & 4 — NYE 42, 2:11 Q4"); a **field position bar** (thin horizontal strip, ball marker, first-down tick — not a full field drawing); **last-play narration** in press voice, one line; the **play call panel** at the bottom: six offense play chips in a 2×3 grid (Inside Run, Outside Run, Short Pass, Deep Pass, Play Action, Screen), a "Suggested: Play Action" affordance, tempo row (Normal / Hurry-up / Chew clock). Drive log and box score exist as one-tap-away affordances, not on the main frame.

**Frame states:** the **light** frame shows the 3rd-down state above. The **dark** frame shows the **4th-down state**: the play panel is replaced by the **stakes panel** — "Go: 46% · FG (52 yd): 61% · Punt" with true percentages and a one-line recommendation, `[HAP stakes]`. The **XXXL** frame repeats the light state at accessibility XXXL.

Storyboard (reveal pattern, 3 states): the final-score staging — anticipate ("FINAL — Empire Field" strip, frame dimmed) → resolve (scores count up, winner's figure lands last, `[SND sting-final]` `[HAP milestone]`) → settle (record updates "9–3 · 1st Liberty East", next-hook line "Division lead on the line next week in Boston").

### Surface 2 — Season Hub

**Emotional job: something is always about to resolve — the save pulls you forward.**

Content: phase pill ("2026 · Week 13"); **THIS WEEK card** with marquee treatment (gold accent rule, "SUNDAY PRIME" chip, NYE and BOS marks, records, prediction chip "Empire by 3 · 61%", PLAY and ADVANCE actions — advance is the primary verb, large, bottom-reachable); a **hooks rail** — three compact cards, each a face + one line + a countdown chip ("Reyes contract — 2 wks", "Rushing record pace — 214 yds behind", "Hot seat: 71% security"); the **card feed** below — 3 visible narrative cards, severity-tiered: one big camp-breakout card **frozen in its settled state** (arrow and new rating landed, consequence line visible), two small league-news cards in press voice with bylines; a standings/power segment control as a one-tap affordance.

Storyboard (advance pattern, 3 states): tick (ADVANCE pressed, button state changes, feed dims, `[HAP advanceTick]` `[SND tick]`) → resolve (new cards land top-down staggered, `[SND card]` per card, `[HAP cardLand]`) → settle (hook countdown chips decrement; the Reyes contract hook resolves **positive** — chip flips to the positive accent with "Signed · 3 yrs").

### Surface 3 — Player Card

**Emotional job: a person with a story, not a row of stats.**

Content: identity band in Empire colors (initialed circle mark "DR", name "Darius Reyes", #11 · WR · New York Empire, age/height/weight line); an **arc strip** directly under the band — the player's live storyline as one chip+line ("Contract year — asking 3 yrs · $9.5M/yr"); the **hero figure**: overall 87 in Star cobalt with tier word "Star" and a small trend arrow — rendered settled in the default frames; attribute summary (4 headline attributes as LedgerRows with tier-colored figures) with "All attributes" as a one-tap affordance; **career ledger** — season-by-season LedgerRows (year, team, catches, yards, TD) plus milestone lines interleaved ("2025 — League receiving-yards leader"); contract block: fact line ("2 yrs · $7.2M/yr · $4.1M guaranteed") + consequence line ("Cut now: $6.2M dead through 2028"); morale/traits as words with numbers ("Morale 78 — Settled", "Clutch").

Storyboard (reveal pattern, 3 states): the camp reveal — anticipate ("Camp report — WR Darius Reyes", card dimmed, `[HAP reveal]`) → resolve (arrow and new rating land: "85 → 87", `[SND up]`) → settle (tier word updates to "Star", consequence line "Now the #2 receiver on your board — trade value rising").

## Deliverables and export

Per surface, four exports: light default, dark default, XXXL stress (light theme), and a storyboard sheet.

**Storyboard sheet canvas:** three full-size 393×852 states side by side with 40pt gutters (total ≈ 1339×932); channel tags sit in a strip beneath each state; label each state with its pattern-stage name (anticipate/hold/resolve/settle or tick/resolve/settle).

**The twelve filenames, exactly:**
`01-gameday-light.png` · `01-gameday-dark.png` · `01-gameday-xxxl.png` · `01-gameday-storyboard.png`
`02-hub-light.png` · `02-hub-dark.png` · `02-hub-xxxl.png` · `02-hub-storyboard.png`
`03-player-light.png` · `03-player-dark.png` · `03-player-xxxl.png` · `03-player-storyboard.png`

These land in `docs/design/mockups/` and become visual canon.

## Rules of engagement

- Prototype ≠ implementation. The build is stock-first SwiftUI; if a drawn element has no plausible stock construction, it must carry an annotation proposing its native equivalent — otherwise the builder will adjudicate against the brief, not the pixels.
- Motion, sound, and haptics cannot be mocked — they appear only as the closed tag vocabulary above. Never draw fake blur/glow to imply motion.
- Do not invent new tokens, colors, teams, or type roles. Gaps in this brief are design decisions you should surface as questions at the end of the session, not fill silently.
- Success test: a genre-literate player glancing at each surface should feel, in order — *stakes* (gameday), *pull* (hub), *attachment* (player card) — while every number stays legible, sober, and true.
