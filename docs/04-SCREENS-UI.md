# 04 — Screens & UI Spec (rebuild canon)

Every screen in Pro Football Coach. **Each screen states its emotional job before its fields** — the job is the acceptance test; the fields serve it. Visual and staging language is `DESIGN.md` (Primetime) and is not restated here; hero-surface layouts follow the approved mockup canon in `docs/design/mockups/`. Per-screen Claude Design briefs live in `docs/design/briefs/` and inherit the locked system by reference.

Global rules binding every screen: platform physics (DESIGN §8) · click budgets stated per deep screen (routine fact ≤2 taps from its surface root) · every changing figure is a tabular numeral with `count` · no faceless narrative cards · stock controls · portrait-only except On the Field.

**Navigation skeleton** *(v1, carried)*
- Pre-dynasty: Main Menu → New Game Wizard (4-step) | Load Game | Scenarios | Settings
- In-dynasty tab bar (context-aware): **Season · Schedule · Team · Front Office · Coach** (offseason swaps Season content for the stage hub)
- Sheets: previews, box scores, player cards, skill tree, goals, settings. Push: live game, trophy room. Full-screen: gameday modes, draft day.

---

## 1. Main Menu
**Job: confidence — your dynasty is safe here, and starting a new one feels like a season premiere.**
Hero: mark, "Pro Football Coach", tagline. Rows: **Continue** (most recent save: team mark, season/week, one-line hook — the save greets you mid-story) · **New Game** · **Load Game** · **Scenarios** · **Challenges** (named templates, §02 §11). Gear → Settings. No external links.

## 2. New Game Wizard (4 steps)
**Job: anticipation — picking a team should feel like accepting a job, not filling a form.**
Step 1 League: default-league card (32 teams, 2 conferences). Advanced (v1.5) hidden.
Step 2 Team: search; grouped by division; row = mark, city+name, rating figure, cap-health word+symbol chip, situation tag ("Contender", "Rebuild" — these set expectations and difficulty). Tap = detail peek (last season, best players via face chips, cap space fact+consequence, picks).
Step 3 Coach: name/age; background trait grid (+1 branch point); schemes; GM settings; challenge template (optional); save name.
Step 4 Confirm: summary cards + themed **Start Franchise** CTA. First advance lands the season-opening card stack (the game starts by narrating, Pillar P1).

## 3. Season Hub (tab: Season) — hero surface, mockup canon 02-hub-*
**Job: pull — something is always about to resolve.**
Phase pill · **THIS WEEK card** with occasion treatment (accent + broadcast identity chip per DESIGN §2.7), both marks, records, prediction chip ("Empire by 3 · 61%"), **ADVANCE** (primary verb, bottom-reachable) and **PLAY** actions · **Hooks rail** (≤3 visible: face + line + countdown chip; resolved hooks take outcome accent) · **Card feed** (3–7 salient cards/week, severity-tiered, blocking only with deadline semantics — 02 §11) · segment control: Standings | Power | League News (full lists one tap deep) · quick links Stats/Players/Awards as neutral rows (no raw-color tinting).
Advance runs the two-beat collapse (02 §5): midweek beat surfaces (injury report card, gameplan card, queued dilemma), then gameday, then aftermath — all as the advance-pattern staging (DESIGN §2.2).
Bye/preseason/offseason variants swap THIS WEEK content; the feed and hooks rail persist year-round.

## 4. Gameplan (midweek beat sheet)
**Job: a coach's tradeoff, not homework.**
Opponent tendency card (their identity: scheme, star ability line, tendency note — from real sim stats) · focus pick: 6 options with explicit pro AND con each · practice intensity + reps allocation (dev vs fatigue/injury risk, true numbers) · confirm. One screen, ≤60 seconds, skippable (defaults apply on advance). (MAD-08/09/43.)

## 5. Matchup Preview (sheet)
**Job: stakes made legible.**
Occasion header, records, prediction chip · unit bar comparisons with edge chips · key duel card (their star vs your answer, ability + counter lines) · injury notes · "What's at stake" line (standings/hook implications — always concrete).

## 6. Live Gameday — Call the Plays (full-screen) — hero surface, mockup canon 01-gameday-*
**Job: tension you can feel between snaps — every down a decision with visible stakes.**
Score strip (occasion accent, timeouts, clock) · situation line · field position bar · last-play press-voice line · play panel (6 calls, Suggested, tempo row) · 4th-down/2-pt states swap in the **StakesPanel** (true odds + recommendation, `[HAP stakes]`) · drive log and live box score one tap away · Quick-Sim sheet (speeds, sim-to targets, takeover interrupts — RB-33) · halftime: replay-your-half card + swing chart (broadcast slot 3) · final: score staging → Game Report. Exit rules: leading slot is a real cancel (sim-to-end lives in the trailing confirmation slot — AUDIT fix carried as law).

## 6B. On the Field (full-screen, landscape) *(mode spec: 06-PLAYED-GAME-MODE.md)*
**Job: the same stakes, in your thumb.** Presentation per doc 06 §7 with Primetime staging for scores/finals; scoreboard uses ScoreStrip; all records identical to other modes. Landscape opt-in for this scene only.

## 7. Game Report + Box Score (sheets)
**Job: the verdict, then the receipts.**
Report: final staging (already played) settled at top · quarter chips · Player of the Game (face + line) · columnist one-liner (press voice) · postgame verdict card (broadcast slot 4) · swing chart · "View Box Score".
Box score: team toggle, position-group **DataTable** sections (column picker, persistent sort); defensive drive receipts — each opponent drive shows your call and its effect (simulated-phase receipts, 02 §4). VoiceOver: every stat row reads as a sentence.

## 8. Schedule (tab)
**Job: the season's shape at a glance — where the hard road is.**
18 rows: week badge, occasion chip (DIV/CONF/marquee/playoff), opponent mark+name, power-rank badge, prediction chip (future) or result chip (W/L word+tint), chevron → preview/report. Playoff rounds append. Preseason collapsed. Record chip in header.

## 9. Team (tab) — Team Overview
**Job: your program, its identity, its health.**
Header band: mark, city+name, record, Reputation figure, coach line · rows: Schemes · Depth Chart & Roster · Injury Report (count badge; empty state "All players healthy") · Training Focus · Team Stats (→ DataTable sheet). Featured-players strip: the 5 faces carrying your storylines (02 §3), each with arc line.

## 10. Depth Chart & Roster
**Job: control — the roster obeys you, and tells you what it costs.**
Team card (overall, record, Auto-Sort, Injury Report) · per-position cards: ranked rows = number circle, name, OVR (tier color + spoken tier), age + years-pro chips, status pill, injury icon; drag to reorder; swipe: elevate/send-down (PS), cut (→ dead-money confirm with fact+consequence lines). Roster counts 53/53 + PS 16. Deep layer: full-roster **DataTable** (column picker: contract, morale, dev arrows; density toggle; persistent sort). Click budget: any player's cap hit ≤2 taps from this screen.

## 11. Player Card (sheet) — hero surface, mockup canon 03-player-*
**Job: a person with a story, not a row of stats.**
Identity band · arc strip (live storyline chip+line) · hero OVR (staged only when unseen change; else settled) · star-ability line (90+ players: name, condition, counter) · attribute summary (4 LedgerRows) → "All attributes" DataTable one tap · **career ledger** (season LedgerRows + interleaved milestone lines) · contract block (fact + consequence lines; Extend/Trade-block/Cut where legal) · morale + traits as words with numbers. Prospects: fogged ranges + your recorded scout prediction (02 §8).

## 12. Front Office (tab)
**Job: the long game — money as consequences, not spreadsheets (until you want the spreadsheet).**
Hub rows with badges:
- **Salary Cap:** hero fact card ("$12.4M space · cap $255M") + stacked bar; consequence line for the nearest crunch; year selector; contracts **DataTable** (sort by hit, expiring filter). Click budget: any contract's dead-money figure ≤2 taps.
- **Re-Sign:** expiring list with asks; negotiate sheet (sliders, true accept-probability meter, 3 rounds, promise option — 02 §6); walk-risk stated.
- **Free Agency:** market DataTable (filters, sort); bid sheet with true interest meter; waves ticker cards; street FA in-season with explicit refusal reasons.
- **Trades:** partner picker with AI need hints; asset pickers; true value verdict (Decline/Close/Accept) + counter-offers; deadline banner; AI offers arrive as feed cards.
- **Staff:** OC/DC/STC cards (rating, scheme match ✓/⚠, trait, salary, years); budget bar; hire/renew during carousel; poaching arcs as cards.
- **Owner:** expectation card, patience (word + number), job security %.

## 13. Draft Suite (offseason phase screens)
**Job: draft night is the season's Christmas (FM-08) — scarcity, reveals, and being proven right.**
- **Scouting (in-season weekly + draft stage):** points budget; prospect **DataTable** with fogged ranges; actions (narrow/reveal/full report) as proper buttons with costs; watchlist; your prediction lines recorded per report (02 §8).
- **Draft Day (full-screen):** on-the-clock card, pick ticker, board vs best-available tabs, PICK action (44×44+, confirm), trade-up/down sheet with value chart; **pick-reveal staging** per DESIGN §2.3; war-room grade toast; hyped-prospect rise/fall cards; round selector; UDFA quick-sign step.
- **Scouting accuracy ledger** (post-draft + season-end): how your board graded out.

## 14. Standings (full screen)
**Job: the race, legible.**
Segments: Division | Conference | League | Playoff Picture. DataTables (W-L-T, PCT, DIV, CONF, PF, PA, STRK; persistent sort); playoff picture with clinch chips (letter + word) and "In the hunt"; tiebreaker footnote. Hook-relevant rows carry their countdown chip.

## 15. Stats Suite
**Job: the expertise surface — raw numbers one tap deep, never amputated.**
Category chips (9 categories, vetted accents) · leader cards (rank badge, face, key line, team) · full **DataTable** per category (column picker, Min-G filter, week/season scope, search, direction toggle) · Team stats twin · Records sheet: single-game/season/career, franchise + league, seeded historical marks, **live chase chips** (record pace hooks — 02 §11).

## 16. Awards & Honors
**Job: the league notices.**
Weekly Players of the Week (faces) · MVP race tracker (top-5, hook chip) · season ceremony with reveal staging (DESIGN §2.3 award row) · All-League/All-Rookie teams · Hall of Fame (inductions staged; career ledgers open from here).

## 17. Coach (tab)
**Job: your career is its own save.**
Profile card: team, coach, season/week · rows: My Coach (level, salary, contract, **job security %** with word) · Skill Tree (4 branches, node chains, SP costs; unlocked = accent + icon) · Seasonal Goals (owner-assigned cards with progress + XP) · Job Offers/Team Search (carousel window only) · Trophy Room (push) · Previous Seasons archive · **Season Retrospective** (staged recap + local export artifact — 02 §11) · Franchise Management card: Autosave toggle, Save, Checkpoints (max 5), Settings, Main Menu (destructive-confirmed).

## 18. Offseason Hub (Season tab content in offseason)
**Job: ten doors, opened in order, each one an event.**
Stage cards with lock/check states (v1 ten stages); each opens its screen; Advance Stage CTA. The feed narrates all 31 AI teams through every stage (league evidence — the Weekly runs in offseason form). Carousel stage: firings/hirings cards, your offers (never dead-ended, arc-framed — Pillar P6). Camp stage: progression reveals staged (camp-report cards, arrows). Cutdown: auto-suggest respecting minimums + cap, dead-money consequences stated.

## 19. Trophy Room (push)
**Job: permanence — what the dynasty has won, in one room.**
Collection bar · trophy grid (v1 ten types + challenge completions) · each trophy opens its season context (record, bracket, retrospective link).

## 20. The Weekly (sheet, from hub feed)
**Job: proof the league is alive without you.**
Broadcast slot 5: phase-aware league show — top performances league-wide (faces + lines), race/streak segments, upset card, records watch. Every simmed week produces this, openable — the MAD-41 test surface.

## 21. Settings (sheet)
**Job: control without clutter.**
Appearance: Light/Dark/System · Sound effects toggle (+ respects silent switch, stated) · Haptics toggle · Prediction display (spread ↔ win %) · Confirm advances · Injury popups · Replay tutorial · App info (version, build). No accounts, no links out, no IAP.

## 22. Load Game
**Job: every save greets you mid-story.**
Save cards: mark, save name, coach, season/week, timestamp, one-line active hook. Swipe delete (confirm). Checkpoints restore under Coach tab.

## 23. Scenarios (from menu)
**Job: a dare with a deadline.**
Exactly three (02 §12): Cap Hell · Expansion Franchise · Aging Legend. Card = premise fact + goal + why it's hard. Scenario goals ride the hooks rail in-save.

---

### Screen → brief map

Hero surfaces (03-hub/gameday/player) are locked mockup canon. Remaining briefs in `docs/design/briefs/`: 01-onboarding (screens 1, 2, 22, 23) · 02-gameday-support (5, 7, 20, and 6's non-hero sheets) · 03-season (3 variants, 4, 8, 14, 18) · 04-roster (9, 10, 15, 16) · 05-front-office (12) · 06-draft (13) · 07-coach (17, 19, 21). Every brief inherits `00-system.md` by reference and pre-bakes platform physics.
