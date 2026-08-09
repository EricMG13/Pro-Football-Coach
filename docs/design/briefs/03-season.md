# Claude Design Brief 03 — Season Surfaces

Scope: the four surfaces that give the season its shape — the Gameplan midweek sheet, the Schedule, Standings, and the Offseason Hub (this brief's primary surface). Paste whole into a Claude Design session; exports land in `docs/design/mockups/`. All frames are iPhone portrait 393×852pt.

Inherits docs/design/briefs/00-system.md in full: tokens, demo teams (New York Empire NYE #14294B/#C9A227 vs Boston Harbormen BOS #0E3B2E/#C8CFD4), voice registers, staging notation and channel-tag vocabulary, platform physics (Dynamic Type XXXL, 4.5:1 measured contrast, 44×44pt targets, no color-alone state, everything fictional). Do not restate; do not deviate.

---

## 1. Gameplan — midweek beat sheet (04 §4)

**Job: a coach's tradeoff, not homework.**

Content:
- Opponent tendency card — their identity: scheme, star-ability line (name, condition, counter), one tendency note drawn from real sim stats.
- Focus pick: 6 options, each stating an explicit pro AND con (system voice: fact line, consequence line — e.g. "Protect the pocket — Sack risk −18%. Deep-shot rate −12%.").
- Practice intensity + reps allocation: development gain vs fatigue/injury risk, true numbers shown.
- Confirm action. One screen, ≤60 seconds to read and decide, skippable — defaults apply on advance.

Staging notes: no DESIGN §2.3 moment fires here — this is a decision surface, rendered settled on entry. The pro/con pairs are the fact-then-consequence layout rule applied to buttons, not a staged reveal. Selection state must carry a word or symbol, never tint alone.

## 2. Schedule (04 §8)

**Job: the season's shape at a glance — where the hard road is.**

Content:
- Record chip in header. 18 week rows (17 games + one bye row); playoff rounds append below; preseason collapsed above.
- Row anatomy: week badge · occasion chip (DIV / CONF / marquee / playoff) · opponent mark + name · power-rank badge · prediction chip (future weeks) or result chip (past weeks, W/L word + tint) · chevron to preview/report. Rows ≥52pt.

Staging notes: rendered settled; no §2.3 moment. Occasion chips and accent rules follow the 00-system occasion ladder exactly — the marquee row takes the 2pt gold rule + "SUNDAY PRIME" chip; division-rival rows take the 2pt opponent-color rule + "RIVALRY" chip. Result chips carry the W/L word so tint is never alone.

## 3. Standings (04 §14)

**Job: the race, legible.**

Content:
- Segment control: Division | Conference | League | Playoff Picture.
- DataTables — columns W-L-T, PCT, DIV, CONF, PF, PA, STRK; persistent sort; tabular numerals throughout.
- Playoff Picture segment: clinch chips (letter + word, e.g. "x · Playoff berth"), "In the hunt" grouping.
- Tiebreaker footnote (canon order: head-to-head, then division record, then conference record, then points for).
- Hook-relevant rows carry their countdown chip.

Staging notes: rendered settled; no §2.3 moment fires on this screen — clinches celebrate in the hub feed (DESIGN §2.6 tier 2); Standings shows only the already-settled clinch chip. Clinch letters always pair with their word.

## 4. Offseason Hub (04 §18) — PRIMARY

**Job: ten doors, opened in order, each one an event.**

Content:
- Phase pill in offseason form (e.g. "2027 · Offseason — Camp").
- Ten stage cards with lock/check states, in canon order: Review → Carousel → Retirements → Re-sign → Tag → FA waves → Draft → Camp → Cutdown → Preseason. Completed = check + word "Done"; current = active card, opens its screen; future = lock symbol + word "Locked". Never state by color alone.
- **Advance Stage** CTA — the offseason's primary verb, large, bottom-reachable (mirrors ADVANCE on the season hub).
- Card feed below: the league's other 31 clubs narrated through every stage (the Weekly in offseason form) — every card a face, a headline number, a consequence line; press-voice cards carry byline chips.
- Carousel stage content: firing/hiring cards and your offers, arc-framed, never dead-ended. Camp stage: staged progression reveals. Cutdown: auto-suggest respecting roster minimums + cap, dead-money consequences stated.

Staging notes: frames are discrete settled states — staged moments appear frozen in their settled state, per the hub canon. Cite by name: the camp feed card is the §2.3 **Camp reveal (OVR/potential)** row settled (arrow + new rating landed, consequence line visible); cutdown consequence cards are the §2.3 **Cap move (cut/sign/trade)** row settled ("…leaves $X.XM dead through YYYY"); re-sign/tag/FA feed cards follow the §2.3 **Contract signed** row. Advance Stage runs the advance pattern (tick → resolve → settle); annotate the CTA with `[HAP advanceTick]` `[SND tick]` in the sheet gutter.

## Frames and export names

Six frames. Offseason Hub is primary (light + dark + XXXL); the other three are light only.

| File | Depicts |
|---|---|
| `03-season-gameplan-light.png` | Week 13 midweek vs Harbormen: tendency card, focus grid, intensity/reps, Confirm |
| `03-season-schedule-light.png` | Mid-season viewport (~weeks 9–16): results above, bye row, marquee week 13 centered, rivalry week 14, future predictions |
| `03-season-standings-light.png` | Division segment: Liberty East four-club DataTable, hook chip on the Empire row, tiebreaker footnote |
| `03-season-offseason-hub-light.png` | Camp stage current (stages 1–7 done, 9–10 locked); Reyes camp card settled in feed |
| `03-season-offseason-hub-dark.png` | Cutdown stage current (1–8 done, Preseason locked); cap-move consequence card settled in feed |
| `03-season-offseason-hub-xxxl.png` | The light Camp state at accessibility XXXL — nothing truncates, gutters widen, stage cards reflow intact |

## Demo data

- In-season frames anchor to the locked hub canon: 2026 · Week 13, Empire 8–3 with the bye taken, home vs Harbormen, marquee occasion, prediction chip "Empire by 3 · 61%". Read the 00-system canon as a home-and-home: week 13 vs BOS (marquee, "SUNDAY PRIME"), week 14 at BOS (division rival, "RIVALRY") — the schedule frame shows both treatments.
- Offseason frames are the following spring: "2027 · Offseason".
- Reuse Darius Reyes (WR, #11, Empire) wherever a player is needed: the camp feed card reuses his canonical reveal settled ("85 → 87 · Star", "Now the #2 receiver on your board — trade value rising"); his re-signed deal ("Signed · 3 yrs") may appear in Review/Re-sign context.
- Standings and schedule need more clubs than the two demo teams: use canon league names only — Liberty East is New York Empire, Boston Harbormen, Philadelphia Founders, Washington Sentinels; further opponents come from the canon 32 (e.g. Chicago Blizzard, Miami Tides, Detroit Motors). Only NYE and BOS have locked colors — render all other clubs as neutral marks (initialed circle in label/secondaryLabel), no invented color pairs.
- Cutdown demo cut is an invented veteran (e.g. "LB Marcus Webb — cutting saves $2.4M now. $1.1M dead through 2027."). Invent additional fictional player and coach names freely; never real ones.
- Standings example row (Empire): 8-3-0 · .727 · DIV 3-1 · CONF 6-2 · PF 289 · PA 231 · W4; Empire lead Boston on division record. Countdown chip: "Division lead — this week".

## Open questions (surface, do not fill)

1. Does the marquee occasion bleed into midweek surfaces — an accent on the Gameplan tendency card — or do occasion treatments live only on score-strip/game-card surfaces per the 00-system ladder?
2. The six gameplan focus options have no canon names yet — placeholders are fine in frames, but where is their source of truth recorded (02-GAME-DESIGN)?
3. Non-demo clubs: should the other 30 canon teams receive locked color pairs and abbreviations now, or stay neutral marks in mockups until a league-identity pass?
4. Standings Playoff Picture segment (clinch chips, "In the hunt", seeds) is specced but gets no frame here — does it need one in a later pass?
5. 04's screen→brief map also assigns the Season Hub's bye/preseason THIS WEEK variants to this brief; they received no frames — copy-spec only, or add frames?
6. Stage-to-stage advance uses the advance pattern here; is entering the offseason itself (season end → Review) a `turn` chapter transition, fired once?
