# Claude Design Brief 02 — Gameday Support Sheets

Scope: the three sheets that surround a played or simmed game — Matchup Preview (before), Game Report + Box Score (after), and The Weekly (the league around it). None is a hero surface; all must feel like segments of the same broadcast the hero mockups established.

Inherits docs/design/briefs/00-system.md in full: tokens, demo teams (New York Empire NYE #14294B/#C9A227 vs Boston Harbormen BOS #0E3B2E/#C8CFD4), voice registers, staging notation and channel-tag vocabulary, platform physics (Dynamic Type XXXL, 4.5:1 measured contrast, 44×44pt targets, no color-alone state, everything fictional). Do not restate; do not deviate.

All frames depict the marquee occasion: Empire vs Harbormen, game of the week, "SUNDAY PRIME" chip, gold accent rule. These are sheets (modal, swipe-dismissable) — draw the standard sheet grabber and a Done affordance; content is a single column of cards.

---

## Screen 1 — Matchup Preview (sheet; 04 §5)

**Job: stakes made legible.**

Content, top to bottom:
- Occasion header: both team marks, records, "SUNDAY PRIME" chip, prediction chip ("Empire by 3 · 61%").
- Unit bar comparisons with edge chips (offense vs defense units; each edge stated as word + symbol, never tint alone).
- Key duel card: their star vs your answer, ability + counter lines.
- Injury notes (status accents with word + symbol).
- "What's at stake" line — standings/hook implications, always concrete (e.g. "Win and the Empire hold 1st in Liberty East for week 14 in Boston.").

Staging notes: nothing stages here — this is broadcast slot 1 (pregame framing); every figure renders settled. No DESIGN §2.3 row fires on this sheet. The key duel card obeys the narrative law: two faces (initialed circle marks in each team's colors), a headline number per player, a consequence line.

## Screen 2 — Game Report (sheet; 04 §7) — PRIMARY

**Job: the verdict, then the receipts.**

Content, top to bottom:
- Final staging settled at top: the game is already played, so the **Final score** row of DESIGN §2.3 appears in its settled state only — final figures large (Display type), record update + next-hook consequence line beneath ("9–3 · 1st Liberty East" / "Division lead on the line next week in Boston"). Do not draw anticipate/hold states on this sheet; that staging fired in live gameday.
- Quarter chips (per-quarter line score, tabular figures).
- Player of the Game: face + one line.
- Columnist one-liner in press voice with byline chip.
- Postgame verdict card (broadcast slot 4): the columnist's judgment of your decisions, fact then consequence.
- Swing chart: retrospective win-probability line for the full game — per DESIGN §2.3, swing charts appear only retrospectively at half and final, never live. Two team-colored lines with direct labels (NYE/BOS abbreviations at line ends, not color alone).
- "View Box Score" row (chevron, ≥44pt).

## Screen 3 — Box Score (sheet from Game Report; 04 §7)

**Job: the verdict, then the receipts.** (Shared with the report — this sheet is the receipts.)

Content:
- Team toggle (NYE | BOS segment control).
- Position-group DataTable sections: passing, rushing, receiving, defense; column picker affordance, persistent sort indicator, tabular figures, ≥52pt rows, horizontal overflow scrolling within the table.
- Defensive drive receipts: one row per opponent drive showing your call and its effect ("Blitz heavy — sack, drive died at the NYE 44"). Simulated-phase receipts; system voice.
- Annotation on the frame: every stat row reads to VoiceOver as a sentence.

Staging notes: none — pure settled data. No §2.3 row fires.

## Screen 4 — The Weekly (sheet, from hub feed; 04 §20)

**Job: proof the league is alive without you.**

Content: broadcast slot 5, the phase-aware league show. Top to bottom:
- Show identity header: original fictional show chip + week line ("Week 13 edition").
- Top performances league-wide: 2–3 cards, each face + stat line + team, press voice.
- Race/streak segment: division race lines with tabular records.
- Upset card: winner, loser, score, one press-voice line with byline chip.
- Records watch: chase line(s) with pace figures. If a league record fell in a simmed game, the item borrows the **Record broken** row of DESIGN §2.3 in settled state only — old mark struck through, new mark + holder line; no reveal staging inside a digest.

Staging notes: cards render landed (the `settle` motion's end state); The Weekly never interrupts. All narrative cards keep the narrative law: face, headline number, consequence line.

## Frame list (6 exports, exact filenames)

- `02-gameday-support-report-light.png` — Game Report, light, default type
- `02-gameday-support-report-dark.png` — Game Report, dark, default type
- `02-gameday-support-report-xxxl.png` — Game Report, light, accessibility XXXL (nothing truncates; gutters widen)
- `02-gameday-support-matchup-light.png` — Matchup Preview, light
- `02-gameday-support-boxscore-light.png` — Box Score, light (NYE toggle active)
- `02-gameday-support-weekly-light.png` — The Weekly, light

## Demo data

One continuous fiction across all four sheets — the frames must not contradict each other:
- The game: Empire 27, Harbormen 20 at Empire Field. Empire record settles to 9–3 · 1st Liberty East; next-hook line "Division lead on the line next week in Boston." Suggested quarter line: 7-10-3-7 vs 3-7-7-3.
- Darius Reyes (WR, #11, Empire) is Player of the Game (suggested line: 9 catches, 141 yards, 2 TD) and headlines The Weekly's top performances. In the Matchup Preview key duel he is "your answer" to an invented Harbormen shutdown corner.
- Invent all other player names, bylines, and the columnist freely — fictional, neutral-realistic, never real people. Byline pattern per system brief ("M. Okafor — League Wire").
- The Weekly's non-demo teams: use league-canon names as text only (e.g. Chicago Blizzard, Miami Tides, Denver Summit, Philadelphia Founders, Seattle Evergreens, Kansas City Stampede) — no marks, no colors for them; their players' face chips render neutral monochrome (label color on card fill).

## Open questions — surface these, do not fill silently

1. Non-demo team rendering in The Weekly: the system brief locks NYE/BOS as the only drawn teams. Is neutral-monochrome treatment for other teams' faces/rows acceptable canon, or do more team palettes get defined later?
2. The Weekly needs a durable fictional show name (its identity chip recurs every week, all phases). Propose candidates; use a plain "THE WEEKLY" chip in frames until one is chosen.
3. Swing chart construction: no chart primitive exists in DESIGN §7. Propose its stock-SwiftUI form (Swift Charts line chart?) and its no-color-alone treatment beyond end labels.
4. Drive-receipt row anatomy: LedgerRow variant or its own component? Include the VoiceOver sentence template you assume.
5. Box score default column sets per position group are unspecified in 04 — mock plausible columns and flag them as proposals, not canon.
6. Scope note for the orchestrator: 04's screen→brief map also assigns live gameday's non-hero sheets (drive log, live box score, Quick-Sim, halftime card) to this brief; they are not in this frame list. Confirm whether they ride the Box Score/DataTable patterns or need frames of their own.
