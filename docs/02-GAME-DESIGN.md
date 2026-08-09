# 02 — Game Design Document: Pro Football Coach

The gameplay source of truth. UI belongs in `04-SCREENS-UI.md`; code shape in `03-ARCHITECTURE.md`. Every tunable number here lands in `LeagueRules.swift` as a named constant.

## 1. Vision & pillars

Run a pro football franchise for decades: call the plays on Sunday, run the front office all week. Text/2D sim — depth over graphics, sessions in minutes, dynasties over years.

1. **Every down is a decision.** Play-calling matters; a game takes 3–8 minutes (binding budget: PRODUCT.md pillar 3), or 10 seconds simmed.
2. **The cap is the boss fight.** College's constraint was recruiting; pro's is money. Contracts, dead money, and the draft are the long game.
3. **Stories emerge from numbers.** Busts, steals, dynasties, cap hell — the sim generates them; news + records surface them.
4. **Respect the player's time.** Advance a week in two taps; nothing grinds.

## 2. League structure

- **32 fictional teams** (original names/logos; never NFL marks), 2 conferences × 4 divisions × 4:

| Liberty Conference | Frontier Conference |
|---|---|
| **East:** New York Empire, Boston Harbormen, Philadelphia Founders, Washington Sentinels | **East:** Baltimore Admirals, Cincinnati Riverhawks, Indianapolis Racers, Nashville Rhythm |
| **North:** Chicago Blizzard, Detroit Motors, Cleveland Forge, Pittsburgh Ironmen | **North:** Minneapolis Loons, Milwaukee Barons, Denver Summit, Salt Lake Peaks |
| **South:** Miami Tides, Atlanta Firebirds, Charlotte Aviators, New Orleans Revelers | **South:** Phoenix Scorchers, San Antonio Defenders, Las Vegas Highrollers, Oklahoma City Twisters |
| **West:** Dallas Lonestars, Houston Wildcatters, Kansas City Stampede, St. Louis Archers | **West:** Los Angeles Stars, San Diego Armada, San Francisco Fog, Seattle Evergreens |

Each team: city, name, 3-letter abbrev, primary/secondary colors, geometric logo (SF-Symbol-composed or simple shapes), stadium name, AI GM personality (`winNow / balanced / rebuilder / capHawk`), owner patience (1–5), franchise **Reputation 1–100** (drives FA interest + coach-job desirability; moves with success).

- **Schedule (17 games / 18 weeks + bye):** 6 division games (home/away × 3 rivals), 4 vs a rotating division in-conference, 4 vs a rotating division cross-conference, 2 same-place finishers vs remaining in-conference divisions, 1 cross-conference same-place extra (17th, alternates home). Bye weeks 5–14. Preseason: 3 optional games (no injuries by default, stats discarded, rookies get camp XP boost if played).
- **Playoffs (default "REALISTIC" 14):** 7 seeds/conference; #1 bye; wild-card round 2v7, 3v6, 4v5; reseed each round; Conference Championships; **Continental Championship** (neutral site). Options: 12 or 16 teams.
- **Standings tiebreakers (ordered):** head-to-head → division record → conference record → points for. (`ponytail:` common-games/SoV omitted; add if users notice.)

## 3. Players

- **Positions & roster template (53 active + 16 practice squad):** QB3, RB4, WR6, TE3, OL9, DL8, LB7, CB6, S5, K1, P1 (target counts; min 1 per position enforced at cutdown).
- **Identity:** generated name (weighted first/last banks incl. international), age 21–40, height/weight by position distribution, college (independently generated fictional bank — clean-room rule: no name may be sourced from or match the reference app's strings), draft origin, jersey #, seeded diverse cartoon avatar.
- **Attributes (40–99):** core Speed, Strength, Agility, Awareness (K/P: Awareness only) + position set:
  - QB: ThrowPower, ThrowAccuracy · RB: Catch, BreakTackle, Vision · WR: Catch, RouteRunning, BreakTackle · TE: + BlockShed · OL: RunBlock, PassBlock · DL: Tackle, BlockShed, PassRush · LB: Tackle, Coverage, BlockShed · CB/S: Coverage, Tackle · K: KickPower, KickAccuracy · P: PuntPower, PuntAccuracy
- **OVR:** per-position weighted mean (weights table in `LeagueRules`; e.g. QB = .30 ThrowAccuracy, .20 ThrowPower, .25 Awareness, .10 Agility, .10 Speed, .05 Strength — all positions defined in code, sum 1.0).
- **Potential:** letter A+…F (hidden dev ceiling + speed multiplier ×1.6…×0.6). Fully visible for your roster; **scouting-fogged for prospects**.
- **Traits (0–2 per player, 25% of players):** Clutch (+3 effective OVR in Q4 within one score), Injury Prone (×1.6 injury odds), Iron Man (×0.5), Locker-room Leader (+morale aura), Mercenary (money-only FA decisions), Loyal (−20% ask to re-sign), Late Bloomer (dev ×1.3 after 26), Boom-Bust (play variance ×1.4).
- **Morale (0–100):** inputs — winning, role vs OVR (starter/backup), contract satisfaction, team reputation. Effects: ±3 effective OVR at extremes; low morale FA discount to leave, re-sign ask +.
- **Ages & curve:** development to peak, plateau, decline. Peak windows: QB 26–32, RB 23–27, WR/CB 24–29, OL/DL/LB/TE/S 25–30, K/P 25–36. Post-peak: −1…−3 OVR/yr accelerating; Speed/Agility decay first.
- **Injuries:** per-play chance scaled by position + fatigue + Injury Prone; severity tiers (1–2 wks / 3–6 / 8+ / season). In-game: player out, next man up from depth chart. IR slot optional v1: cut = simple. League average ~2.5 significant injuries/team/season.
- **Retirement:** probability from age + OVR decline + injuries (QB/K play longest); farewell news; HoF scoring on career stats/accolades, induction 5 seasons later.

## 4. Game simulation (play-by-play)

- **Loop:** coin toss → drives → plays until 0:00 ×4 (OT: modified sudden death, both teams possess unless first score TD; playoff untied repeats).
- **Play resolution:** offense playcall (user or AI) × defense playcall → matchup table (e.g. Deep Pass vs Blitz: big-play ↑, sack ↑; vs Prevent: completion ↓ but check-down yards). Outcome = base(playType) + k·(unitOff − unitDef) + situational modifiers (scheme familiarity, home field +1.5 net pts equivalent, weather v1.5) + seeded noise (mixture: mostly modest gains, fat tail for explosives). Produces yards, clock burn, events (sack, INT, fumble, penalty, injury, TD).
- **Units:** Offense rating = weighted position group OVRs vs Defense rating likewise; special teams from K/P + returner speed.
- **Clock:** realistic burn per play type + hurry-up/kill-clock automatically by score+time; timeouts (3/half) user-controlled + AI logic.
- **Penalties:** ~11 combined/game, weighted types (hold, PI w/ spot foul, false start, offsides); accept/decline auto by expected value.
- **4th downs & kicks:** AI uses simple EV chart (go/FG/punt by distance-to-go, field position, score, time). FG% curve from KickAccuracy/Power vs distance (~85% league avg; 50+ yd ≈ 60%).
- **Playcalls:** Offense — Inside Run, Outside Run, Short Pass, Deep Pass, Play Action, Screen (+FG, Punt, Kneel, Spike, 2-pt, **Onside Kick** after scores). Defense — Base, Blitz, Nickel, Dime, Contain, Prevent (+Hands Team vs expected onside). **Tempo toggle** on offense: Normal / Hurry-Up / Chew Clock (affects play clock burn + slight efficiency tradeoffs); AI uses it correctly late. "Suggested" banner = OC/DC AI pick (quality scales with coordinator rating); auto-call toggle available.
- **Sequencing correctness (hard requirements from reference-app bug mining):** TD as time expires still awards the try; end-of-game state machine (0:00 edge cases, kneel-outs, untimed downs after defensive penalty, OT caps) gets exhaustive unit tests — this is the #1 crash locus in the reference app. OT is capped (max 2 OT regular season → tie; playoffs repeat until decided).
- **Game modes:** every user game offers Quick Sim, Call the Plays (this engine, text/2D), or **On the Field** (arcade control of offensive snaps/kicks/returns — full spec `06-PLAYED-GAME-MODE.md`). All modes emit identical records; calibration bands apply to engine-resolved games only.
- **Win probability:** logistic on (score diff, time remaining, possession, field position, pregame ratings edge) — computed per play. **Superseded presentation (DESIGN.md §2.3, R2 T5): never shown as an always-on live figure; surfaces as retrospective swing charts at half and final, and as per-decision true odds in the StakesPanel.**
- **Player of the Game**, box scores per position group, drive-grouped play log with clock stamps and tappable player names.
- **Calibration bands (asserted by tests, per simulated season):** team PPG 20–26 · pass yds/team/gm 195–240 · rush 100–130 · comp% 61–67 · INT/gm 0.7–1.0 · sacks/gm 2.0–2.9 · FG% 82–88 · ~8% of games OT · home win% 54–58%. **Believability bands (added from reference-app complaint mining):** Q4 scoring share 22–30% of points · plays of 25+ yds: 3–6/game · TDs of 40+ yds: ~0.5/game · safeties ≤ 0.03/game · blocked kicks ≤ 2% · TE target share 15–25% of team targets · no single receiver > 40% of targets (barring extreme roster) · **ratings predictiveness: 12+ OVR gap → favorite wins ≥ 72%** · **mode parity: retainPlays true vs false produces statistically identical distributions (same seeds, same aggregate outcomes — one engine, one truth).**

## 5. Season calendar

Preseason (3 wks, optional) → Weeks 1–18 (17 games + bye; trade deadline end of Wk 9; weekly awards, power rankings, injuries heal, weekly training XP) → Playoffs (4 rounds) → Offseason stages, in order:

1. **Season Review** — goals scored, XP granted, awards ceremony, All-League teams
2. **Coaching Carousel** — AI firings/hirings; user fired if job security hits 0 (unless disabled) → job-offer list (reputation-gated); voluntary Team Search at this stage only; **coordinator market** (hire/renew OC/DC/STC from generated pool, poaching resolves — §10)
3. **Retirements** + HoF inductions
4. **Re-sign window** — your expiring contracts; AI teams re-sign theirs
5. **Franchise Tag** (optional toggle, 1 tag = 120% of position top-5 avg salary, 1 yr)
6. **Free Agency** — 3 waves (see §7)
7. **Draft** — 7 rounds × 32 + UDFA (see §8)
8. **Training Camp** — progression reveal (▲▼ arrows, breakout stories)
9. **Cutdown** — to 53 + 16 PS (auto-suggest respects position minimums + cap)
10. **Preseason games** → next season kickoff; cap year rolls, contracts tick down

## 6. Salary cap & contracts

- **Cap:** $260M year 1, grows 5–8%/yr (seeded). All 53 + PS count (no top-51 rule — `ponytail:` simplification, note in UI).
- **Contract:** years (1–5), salary/yr array (flat or +5%/yr riser), signing bonus (prorated evenly over years, max 5), guaranteed years count. Cap hit = salary + bonus proration. **Dead money on cut/trade** = remaining proration + remaining guaranteed salary (all accelerates into current year; `ponytail:` no June-1 split).
- **Rookie scale (slotted, 4 yrs):** R1P1 $9.5M/yr declining smoothly to R7P32 $0.9M/yr (table in code); R1 has team option yr-5 at position-avg (toggle; default on).
- **Minimum salary:** $0.9M (age <26) / $1.2M vet. Practice squad $0.25M each.
- **Re-sign ask model:** market value = f(OVR, age vs peak, position premium (QB 2.2× > WR/CB/DL ~1.2× > RB/S ~0.9× > K/P 0.35×), recent production, morale, Loyal/Mercenary traits, team success). Negotiation: sliders for years/salary/bonus; accept-probability meter; each failed lowball −5 morale; walk risk after 3 rounds.
- **Cap floor for AI:** AI teams must spend ≥ 89% cap across 3 years — keeps FA market liquid.

## 7. Free agency

- Wave structure: 3 waves per offseason (each = 1 "day"): stars sign early. AI bids from need + cap + personality. Offer = years/salary/bonus; **interest meter** = money (55%) + contender status (20%) + role/depth-chart fit (15%) + franchise reputation (10%), Mercenary/Loyal skew. Losing bids generate news ("Stars sign CB Ryan Evans, 4 yrs $72M").
- In-season street FA pool: unsigned leftovers, OVR mostly <72, 1-yr min deals; signing needs cap space + roster spot.

## 8. Draft & scouting

- **Class generation:** 224 draftable + ~80 UDFA pool. OVR bell curve by round expectation with noise; potential letters correlated to draft slot but with engineered **steals** (~6/class: R4+ with A/B potential) and **busts** (~5/class: R1–2 with D/F). Position distribution matches roster needs league-wide. Rookie ages 21–23.
- **Scouting fog:** unscouted prospects show OVR *range* (±8) + hidden potential. **Scouting points:** 120/season (skill tree +). Costs: narrow range −3 (10 pts), reveal potential (25 pts), full report (40 pts: exact OVR + traits). Weekly in-season scouting screen + full access during draft stage.
- **Draft day:** snake-free standard order = reverse record (SoS tiebreak), playoff teams by exit round, champion 32nd. 7 rounds. AI picks = need × best-available × personality (rebuilder drafts younger/high potential). **Pick trades** live during draft (value chart: JJ-style — pick 1 = 3000 pts … pick 224 ≈ 2; future picks −20%/yr out). War-room grade toast per pick; class grades in news next morning.
- **UDFA:** quick-sign list post-draft, min deals, PS-eligible.

## 9. Trades

- Assets: players + picks (current + next 2 drafts). **Trade value:** player = f(OVR curve by age, potential, position premium, contract quality (cheap > fair > albatross), morale); pick = chart value × (1 − uncertainty discount).
- AI accept when received ≥ 105% of given (personality-adjusted: winNow overpays for vets, rebuilder for picks); counter-offers within 15% gap; 3-round negotiation max.
- Constraints: post-trade cap legality both sides (dead money applies), roster min/max, no trades weeks 10–18 (deadline end of week 9) or during playoffs.
- AI-to-AI trades happen at deadline + draft (2–6/season) → news. AI sends user offers for tradeblock'd players.

## 10. Coach RPG & staff (carried from college, re-skinned)

### Coordinators (v1-light staff system)

Three hireable slots: **OC, DC, STC.** Each `StaffMember` = name, age, rating 40–99, scheme specialty, salary, contract years (1–3), 0–1 trait (Developer +camp XP ·  Motivator +morale · Recruiter-of-Coaches cheaper hires). Effects:

1. **Unit ratings:** OC adds +0…+3 to offense unit, DC to defense, STC to special teams (linear from rating 60→95; scheme mismatch with team scheme halves it).
2. **Suggested-play quality:** playcall AI accuracy scales with the relevant coordinator's rating (visible in Call-the-Plays and On-the-Field modes). OC ≥ 80 grants +1 audible in On-the-Field.
3. **Development:** OC/DC add up to +15% camp XP for their side's players.
4. **Poaching pipeline:** coordinators earn hidden HC-candidacy score from team success; top ones get hired away at the coaching carousel (news story, succession pressure).

**Staff budget:** owner-set $14–30M/yr by patience/reputation. Hiring happens at offseason stage 2 (carousel): generated market pool, offers = salary + years; AI teams compete (reputation-weighted). Firing mid-contract owes remaining salary against staff budget. AI teams always staff all three slots. The old "Enable Coordinators" toggle now governs **auto-call only** — staff always exists.

- **XP:** win +40 · division win +10 bonus · playoff win +80 · Championship +200 · weekly goals ticking (see below) · season goals 80–100 · draft steal hits +50. Level = XP/100 compounding ×1.15/level; +1 Skill Point per level.
- **Skill trees (4 branches × 6 nodes; costs 1/2/3/4/5/6 SP; linear chains):**
  - **Scouting:** Sharper Eye I/II (fog ±6/±4), Extra Scouts (+40 pts), Combine Insider (free potential on R1 grades), Sleeper Radar (steals flagged ★), Draft-Day Trader (AI accepts at 102%)
  - **Development:** Position Coaches I/II (camp XP +10%/+20%), Vet Mentors (decline −1/yr slower), Youth Program (age <25 dev ×1.15), Breakout Culture (+1 breakout/camp), Iron Regimen (injury odds −15%)
  - **Offense:** Scheme Guru I/II (offense unit +1/+2), Red-Zone Package (RZ TD% +5), Two-Minute Drill (hurry-up +10%), Explosive Plays (fat-tail ×1.15), Fourth-Down Analytics (better suggested calls)
  - **Defense:** mirror of Offense (unit +1/+2, 3rd-down stop +5%, Turnover Chain (takeaway +10%), Blitz Architect, Bend-Don't-Break)
- **Coach finances:** salary from contract ($1.5–12M/yr scaling with reputation); cash is score/flavor (v1: no spend sink — displayed + leaderboard; `ponytail:` spending (houses/donations) only if users ask).
- **Contract & job security:** 0–100%; moves on results vs owner expectations (patience-scaled). <20% = hot seat news; 0% = fired at carousel (unless disabled). Fired/retired → job offers filtered by reputation. **No-dead-end invariant (reference-app lesson): the carousel ALWAYS yields ≥1 offer (floor: a rebuilding team takes a flyer) or an explicit "sit out a year" option that re-enters the market with a reputation tick — a save can never softlock on unemployment.** Contract expiry mid-success → extension negotiation before market.
- **Seasonal goals (owner-assigned, 4–6/season, XP-bearing):** templates — "Win N+ games", "Make playoffs", "Win division", "Top-10 offense/defense", "Rookie class avg +3 OVR by camp", "Stay under cap with $5M+ space", "Beat rival twice". END-OF-SEASON chip where applicable.
- **Retire → Legacy screen:** career grade (titles, win%, playoff record, HoF players drafted), permanent leaderboard entry.

## 11. Meta systems

- **News engine:** templated items with team colors/logos — game recaps, injuries, signings (amounts), trades, milestones (400-yd games), streaks, hot seat, awards, retirements, draft grades. 6–12 items/week league-wide; user-team items pinned first.
- **Awards:** weekly Players of the Week (per conference O/D/ST); season MVP, OPOY, DPOY, OROY, DROY, Coach of Year (voting = weighted stats + team success); All-League 1st/2nd; All-Rookie.
- **Records book:** single-game/season/career, franchise + league, seeded with fictional historical records that current players chase (news when broken).
- **Trophy Room (10):** Champion · Conference Champion · Division Title · Playoff Berth · #1 Seed · Undefeated Regular Season · Draft Gem (R5+ → All-League) · 21+ Comeback · Dynasty (3 titles/5 yrs) · Perfect Season (undefeated + title).
- **Previous Seasons archive:** per year — standings, playoff bracket, awards, your record, champion.
- **Checkpoints:** manual restore points (max 5, ring buffer), plus autosave.

## 12. Scenarios (v1 ships 3)

1. **Cap Hell** — contender roster (88 OVR) but −$38M effective space next year, aging core. Goal: title within 3 yrs without bottoming out.
2. **Expansion Franchise** — new 33rd-team fiction implemented as a stripped 60-OVR roster + extra picks (2 per round, 2 drafts). Goal: playoffs by yr 4.
3. **Aging Legend** — 38-yo 96-OVR QB, 2-yr window, thin roster behind him. Goal: win it all before he retires (retirement forced at yr 3).
Config-driven (modified league JSON + goal set) — no bespoke engine paths.

## 13. Difficulty & settings

- Trade difficulty (AI acceptance 100/105/112%), owner patience, coach-firing toggle, injuries toggle, playoff format, franchise tag toggle, prediction display (spread ↔ win %), confirm-advance, injury popups. Tutorial overlay on first launch, replayable.

## 14. Explicitly out of v1 (design debt, ordered by community demand)

Custom league creator + JSON import/export (v1.5 — architecture supports from day one) · **in-app community league browser** (kills the "go to Reddit for files" friction) · weather · compensatory picks · in-season IR/designated-return · contract restructures/June-1 cuts · position coaches & staff skill trees (coordinators themselves ARE v1, §10) · coordinator career mode (start as OC/DC) · controllable post-snap defense in On-the-Field · dynamic difficulty · per-player usage sliders · social-media-style reacting feed + AI press conferences (news engine covers v1) · multiplayer/leaderboards beyond Game Center basic · expansion drafts · relocation. Monetization if ever: editor + scenario packs, never ads, never paid crash insurance (checkpoints stay free).
