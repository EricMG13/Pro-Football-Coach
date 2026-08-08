# 04 — Screens & UI Spec

Every screen in Pro Football Coach v1. Derived from the 68-screenshot inventory of the college reference app (`01-RESEARCH.md`), converted to pro. Visual language: native iOS light+dark, white cards / large corner radii, SF Pro (rounded heavy for display), pill chips for metadata, floating pill tab bar, sheet modals with "Done" pill, team-color theming after team selection. One concept per card; long scroll over dense tables.

**Navigation skeleton**

- Pre-dynasty: Main Menu → New Game Wizard (4-step) | Load Game | Scenarios | Settings
- In-dynasty tab bar (context-aware, like reference app): **Season · Schedule · Team · Front Office · Coach**
  (Preseason/offseason phases swap "Season" content for the current phase's hub.)
- Sheets: previews, box scores, player cards, skill tree, goals, settings
- Push: live game, trophy room, edit team/league

---

## 1. Main Menu
Hero: app icon, "Pro Football Coach", tagline "Run the franchise. Call every down."
Rows (icon + title + subtitle + chevron): **New Game** "Start a new franchise" · **Load Game** "Continue your saved franchises" · **Scenarios** "Unique franchise challenges" · **Community** "Connect with coaches on Reddit" (external). Gear top-right → Settings. Soft gradient background.

## 2. New Game Wizard (4-step, dot progress stepper, Back pill)
**Step 1 — League Setup.** "RECOMMENDED" card: *Start with Default League* — "32 built-in pro teams, 2 conferences, 8 divisions". Advanced options list (v1.5+, show disabled with "Coming soon" or hide): Import League from URL · Load Saved League · Create Custom League · Community Leagues.
**Step 2 — Team Selection.** Search field; teams grouped by division (e.g. "Atlantic East"). Row: logo, city+name, division sublabel, right "Rating: NN" + tiny cap-health chip (🟢 healthy / 🟡 tight / 🔴 cap hell) + situation tag ("Contender", "Rebuild"). Team detail peek on tap: last season record, best players, cap space, draft picks. Difficulty comes from team choice — surface it.
**Step 3 — Coach Setup.** Themed "YOUR FRANCHISE" summary card (logo, city+name, division, rating). Coach Information: first/last name fields, age slider (30–65), toggles "Disable Coach Firing", "Enable Coordinators". **Coach Background** trait grid (2×2, +1 starting point in that branch): *Former Player* → Development · *Talent Evaluator* → Scouting & Draft · *Playcaller* → Offense · *Defensive Mind* → Defense. Team Schemes dropdowns: Offense (West Coast / Vertical / Spread / Power Run / Balanced), Defense (4-3 / 3-4 / Nickel-base). GM Settings: Trade Difficulty Easy/Medium/Hard; toggle "Owner Patience" Low/Normal/High. Save Name field (optional). Advanced Settings accordion: Playoff Format (14-team "REALISTIC" default / 12 / 16), Salary Cap on/off (on default), Injuries on/off, Season Length 17 (fixed v1).
**Step 4 — Confirm.** Summary cards (Team / Coach / GM Settings / Advanced) + themed "Start Franchise" CTA.

## 3. Season Hub (tab: Season)
Status card: "2026 Season · Week N" + phase pill (Preseason / Regular Season / Playoffs).
**THIS WEEK card:** "Week N", HOME/AWAY chip, logos + records + OVR chips, predictor pills: LINE (e.g. "NYE -3.0"), WIN %, EDGE (green/red). Footer "Tap for full matchup preview ›". Buttons: gray **Advance Week** · themed **PLAY GAME**.
**Your Last Game** card: result, score, W/L chip → opens Game Report.
Segmented pills: **Standings | Power Rankings | News**. Quick links: Stats (blue) · Players (green) · Awards (yellow).
- Standings segment: division mini-tables (#, TEAM, W-L-T, DIV), playoff-line separator, "Full standings ›".
- Power Rankings segment: 1–32 list (rank, logo, city+name, W-L, rating, ▲▼ movement). Replaces college Top 25 poll.
- News segment: feed cards (injuries, signings, trades, milestones, firings) with week stamps.
Preseason state variant: hero "KICKOFF OUTLOOK" (rating, projected record, division odds), Preseason Power Rankings, "Impact Players" top-5, KICKOFF button. Bye-week variant: "BYE — rest week" + Advance only.

## 4. Matchup Preview (sheet)
Hero gradient card both team colors: WEEK chip, logos, records, HOME/AWAY. "Team Comparison": Overall with spread chip; bar-meter cards Offense / Defense / Special Teams with "Home +N"/"Away +N" chips. "Team Stats" side-by-side cards (PPG, YPG, pass/rush splits, takeaways). "Key Matchup" row (best WR vs best CB etc.). Injury notes. Setting toggles spread ↔ win-probability display.

## 4B. Pre-game mode picker + On the Field
Pre-game sheet gains a mode row: **Quick Sim · Call the Plays · On the Field** (cards with 1-line descriptions; remembers last choice). On-the-Field screen spec lives in `06-PLAYED-GAME-MODE.md` §3/§7 (landscape SpriteKit field, HUD scoreboard, aim arc, kick meter, animated defense resolution). Halftime sheet allows switching down-stack only.

## 5. Live Game — Call the Plays (push, core screen)
- **Coin toss dialog:** both full team names, quarter graphic, Heads/Tails.
- **Scoreboard card:** team rows (logo, record, 3 timeout dots, quarter score boxes in team colors), state row "Q1 15:00 · 1st & 10 · NYE 25".
- **Last Play box:** text with team-colored tappable player names.
- **Field graphic:** horizontal 2D field, end zones in home colors, yard numbers, midfield logo, ball marker + direction arrow, blue LOS + yellow first-down line.
- **Playbook card** (possession-aware): offense sets (Inside Run · Outside Run · Short Pass · Deep Pass · Play Action · Screen; situational: FG, Punt, QB Kneel, Spike, 2-pt, Onside Kick) / defense sets (Base · Blitz · Nickel · Dime · Contain · Prevent · Hands Team). **Tempo chip row: Normal / Hurry-Up / Chew Clock.** Green "Suggested: X" banner (OC/DC suggestion; auto-call toggle). 4th-down decision prompts with EV hint.
- **Play Log:** grouped by drive, newest first, clock stamps.
- **Win Probability:** two-color stacked bar, live.
- **Bottom bar:** Simulate · Timeout · Stats (live box score sheet).
- **Quick Sim action sheet:** speed chips Slow/Normal/Fast/Instant; Sim to Next Possession / to end of Q / to Halftime / to End of Game.
- End: Game Report sheet; XP toast ("+40 XP — Win").

## 6. Game Report + Box Score (sheets)
Report: hero w/ final records, "Final Score" quarter chips per team, winner card highlighted (crown), Game Statistics table (Total/Pass/Rush Yards, Turnovers, ToP, First Downs, Sacks, Penalties), "View Box Score" button, Player of the Game card.
Box Score: header "Week N · FINAL/LIVE · score", team toggle pills, Scoring Breakdown quarter chips, position-group sections with expandable player cards (QB: RTG, C/A, %, YDS, TD, INT · RB: CAR, YDS, AVG, TD · WR/TE: REC, YDS, AVG, TD, + expanded YAC/targets · DEF: TKL, SACK, INT, PD, FF · K: FG, XP · P: punts, avg).

## 7. Schedule (tab)
Header: "2026 Schedule", Season Record chip, current-week pill. Full 18-row list (17 games + BYE): WEEK badge + type chip (DIV blue / CONF teal / INTER orange), opponent logo+name w/ power-rank badge, betting line (future) or result chip (green W / red L tint), HOME/AWAY chip, chevron → preview/report. Playoff rounds append when clinched. Preseason section (3 games, collapsed, optional play).

## 8. Team (tab) — Team Overview
Header card: logo, city+name, division+conference, "HC: <name> ›", record, team color dots, **Reputation NN** (replaces college Prestige). Rows: Team Schemes · Team Stats → analytics sheet · Depth Chart & Roster · Injury Report (count badge; "All players healthy" empty state) · Training Focus (weekly XP allocation: Balanced / Offense / Defense / Youth). Schedule preview list below (reference-app pattern).

## 9. Depth Chart & Roster
Header: "2026 Season", team chip, Reputation. Team card: Overall (e.g. 76.5), record, collapsible schemes row, orange **Auto-Sort**, red **Injury Report**. Sections Offense (count chip) / Defense / Special Teams; per-position cards ("QB — 3 players"): ranked rows = number circle, name, OVR (color-tiered: purple 90+ / blue 86–89 / green 73–85 / orange 60–72 / red <60), age chip + years-pro chip (replaces college class/RS), status pill STARTER (green tint) / BACKUP (yellow) / reserve, injury icon. Drag to reorder within position. Roster count "53/53" + practice squad section "PS — 16" (elevate/send-down actions). Cut player action (→ dead-money confirm dialog, Front Office rules).

## 10. Player Card (sheet — one template, position-driven)
Header: avatar (cartoon, diverse, seeded), name, jersey #, position, team.
**Basic Information:** Position, Age, Years Pro, Height, Weight, College (generated), Draft origin ("R1 P12 2024" / "UDFA").
**Contract card (pro-new):** years left, salary/yr, signing bonus, guaranteed, cap hit this year, dead money if cut. Buttons where legal: Extend · Trade block toggle · Cut.
**Season Statistics** (position stat set, "Game-by-Game ›" link) + **Career** table by year.
**Player Attributes** 2-col tile grid: Potential letter (A+…F, color-coded; scouting-fogged for rookies), Overall, Speed/Strength/Agility/Awareness core, then position set — QB: Throw Power, Throw Accuracy · RB: Catch, Break Tackle, Vision · WR/TE: Catch, Route Running, Break Tackle (+TE Block Shed) · OL: Run Block, Pass Block, Strength-weighted · DL: Tackle, Block Shed, Pass Rush · LB: Tackle, Coverage, Block Shed · CB/S: Coverage, Tackle · K/P: Kick/Punt Power + Accuracy, Awareness.
Traits chips (e.g. "Clutch", "Injury Prone", "Locker-room Leader"). Morale meter.

## 11. Front Office (tab — pro-new, the big addition)
Hub rows with badges:
- **Salary Cap:** hero card "Cap Space $12.4M / Cap $255M", stacked bar (spent / dead money / space), top-51 note off (v1 simple: all count). List: contracts by player sorted by cap hit; columns NAME · POS · AGE · CAP HIT · YRS. Year selector to preview future caps.
- **Re-Sign:** expiring-contract list w/ player ask ("3 yrs · $8.5M/yr"), negotiate sheet (years/salary sliders, accept-probability meter), player responses.
- **Free Agency:** (offseason) market list with filters by POS, sort by OVR/age/ask; bid sheet = years+salary sliders, interest meter (money, contender status, role, reputation), daily AI signings ticker. In-season: street free agents (cheap fill-ins).
- **Trades:** trade center — pick partner team (AI need hints), asset pickers both sides (players + picks 2 drafts out), value meter (Decline / Close / Accept), counter-offers; deadline week banner. AI-initiated offers arrive as news/inbox items.
- **Draft:** see §12.
- **Staff:** three coordinator cards (OC/DC/STC): name, rating, scheme chip (match ✓ / mismatch ⚠ halves bonus), trait chip, salary, years left; staff-budget bar; hire/renew actions live only during carousel stage (otherwise informational + "expiring" badges). Vacancy card if poached.
- **Team Finances (light):** owner expectation card ("Make playoffs within 2 years"), job security %.

## 12. Draft Suite (offseason phase screens)
- **Scouting (in-season, weekly):** points budget (skill-tree boosted); prospect board with fogged ratings ("OVR 68–84"), scout actions narrow ranges + reveal potential letter; positional needs hints; watchlist stars.
- **Draft Class list:** 224 prospects (7 rounds × 32), searchable, filter by POS; combine blurbs (40 time etc. flavor from ratings).
- **Draft Day:** on-the-clock card (pick timer optional off), pick ticker feed, your Big Board vs Best Available tabs, PICK button + trade-up/down sheet (value chart), war-room grade toast after each of your picks, round selector. Results feed into news + Rookie Report card.
- **UDFA quick-sign** step after round 7.

## 13. Standings (full screen from hub)
Segments: Division | Conference | League | Playoff Picture. Division tables (W-L-T, PCT, DIV, CONF, PF, PA, STRK); Playoff Picture: 7 seeds per conference with clinch chips (x, y, z, *), "In the hunt" section, tiebreaker footnote.

## 14. Stats Suite
Header "Player Statistics · 2026" + week/season scope toggle. Color-coded category chip carousel: Passing · Rushing · Receiving · Tackles · Sacks · Interceptions · Passes Defended · Kicking · Punting. Sort dropdown per category + direction toggle + "Min G" chip + search. Leader cards: rank badge (gold/silver/bronze), name, POS chip, team link, key stat rows, OVR. Team Stats twin screen (offense/defense league tables). Records sheet (single-season + career franchise records, seeded from history).

## 15. Awards & Honors
Weekly: Players of the Week (conf offense/defense/ST). Season: MVP race card (top-5 tracker), season awards ceremony (MVP, OPOY, DPOY, OROY, DROY, Coach of the Year), All-League 1st/2nd teams, All-Rookie team. Ring of Honor / Hall of Fame (retired greats, 5-season wait, induction news).

## 16. Coach (tab)
Top: God-mode-style IAP card **omitted v1** — replaced by "Franchise Editor" (free, in Settings).
**Profile & Franchise** card: Current Team, Coach, Season, Week; rows: My Coach ($ badge) · Skill Tree · Seasonal Goals · Job Offers/Team Search (134→32 teams list w/ openings at season end).
**My Coach sheet:** avatar, level/age badges; Finances (cash, salary); Contract (team, years·$/yr, total, **Job Security %** amber/green/red); Career Stats (record, titles, playoffs, teams); Retire → Legacy screen (career grade, trophies, records).
**Skill Tree sheet:** Skill Points + Level/XP bar header; 4 branch tabs — **Scouting** (better fog reduction, cheaper scouting, draft-steal odds) · **Development** (faster player XP, vet longevity, camp boosts) · **Offense** (scheme boosts, playcall suggestions, 4th-down analytics) · **Defense** (same, defensive). Vertical node chains, SP costs 1→5, locked gray, unlocked colored + icon.
**Seasonal Goals sheet:** owner-assigned goal cards (emoji icon, XP reward, progress bar): "Win 10+ games" · "Make playoffs" · "Top-10 defense" · "Rookie class avg OVR +3 by year 2" · END OF SEASON chips. XP → levels → skill points.
**Franchise Management** card: Autosave toggle · Save Franchise · Checkpoints (restore points, count badge) · Settings · red "Back to Main Menu".
**Customization** card: Edit Team & League (names, colors, conferences realign) · Enable Theme Color toggle.
**Achievements** card: Trophy Room · Previous Seasons archive.

## 17. Trophy Room (push)
Gold/sepia theme. "Collection N%" bar; stat row (Total, Score, Types, Seasons). Locked/unlocked grid: Champion, Conference Champion, Playoff Berth, Division Title, Undefeated Regular Season, Perfect Season, #1 Seed, Draft Gem (R5+ pick → All-League), Comeback Win 21+, Dynasty (3 titles in 5 yrs).

## 18. Offseason Hub (replaces Season tab content in offseason; stepper of stages)
Ordered stage cards with lock/check states, each opens its screen, "Advance Stage" CTA:
1. Season Review (record, goal results, XP summary, awards recap)
2. Coaching Carousel (league firings/hirings news; your job offers if any)
3. Retirements (list w/ tributes; HoF inductions)
4. Contract Expiry & Re-sign window
5. Franchise Tags (1 tag, optional simple v1: skip)
6. Free Agency (3 "waves" = days)
7. Draft (scout → draft day → UDFA)
8. Training Camp (progression results reveal: arrows ▲▼ per player, breakout/regression stories)
9. Roster Cutdown to 53 (+16 PS)
10. Preseason (3 optional games) → New Season kickoff
League-wide AI runs every stage for 31 other teams; news feed narrates.

## 19. Scenarios (from Main Menu)
Card list: "Cap Hell" (contender, $-30M future cap) · "Expansion Team" (all-rookie roster, extra picks) · "Aging Legend" (win now, 38-yo star QB) · "Draft King" (no FA signings allowed) · each = preset league + modified rules + special goal set. v1: ship 3, engine-driven, no bespoke code paths beyond config.

## 20. Settings (sheet)
Appearance: Color Scheme Light/Dark/System. Toggles w/ captions: Injury Popup · Long-Press Quick Actions · Prediction Line View (spread ↔ win %) · Confirm Advances. Tutorial: Replay Tutorial (step-by-step overlay on first launch). Leaderboards row (Game Center, anonymized handle) — v1.5. App Information: Version/Build/Bug Reports (mailto). Credits screen (developer card, socials, "Made with ♥ for football fans"). No IAP v1.

## 21. Load Game
Save-slot cards: team logo+colors, save name, coach, season year, week, timestamp; swipe delete (confirm), tap continue. Checkpoint restore inside Coach tab, not here.

---

### College → Pro conversion map (what replaces what)

| College reference | Pro version |
|---|---|
| 134 teams, P4/non-power tiers, conferences | 32 teams, 2 conferences × 4 divisions |
| Recruiting + in-season recruiting | Draft + scouting + UDFA |
| Transfer portal | Free agency + trades |
| Redshirt planner (per-pos quotas) | Practice squad (16, elevate/send) |
| Class FR→RS SR | Age + Years Pro; age curves |
| Top 25 poll | Power Rankings 1–32 |
| Bowl games + 4/8/12/16 playoff | 14-team playoff (12/16 options), Championship game |
| Prestige | Franchise Reputation + Owner Expectations |
| Conference movement (promotion) | — (fixed divisions; realignment only via editor) |
| 56-man roster | 53 + 16 practice squad |
| Recruiting skill branch | Scouting skill branch |
| God Mode IAP | Free Franchise Editor (v1); IAP decision deferred |
| Scholarship-style budget | Salary cap + contracts + dead money |
