# 01 — Research: Reference App, Game Family, Community, Prior Sessions

Compiled 2026-08-08 by Fable 5 from: all 68 screenshots in this folder, the GitHub repos, Play Store pages, and r/FootballCoach.

## A. Reference app — "College Football Simulator" (iOS, the screenshots)

Indie iOS app by **Mani Foroughi** (solo dev, SwiftUI, v1.20, £3.99 "God Mode" IAP). It is the modern-iOS reimagining of the college half of this genre and the direct UX template for our pro game. All 68 screenshots cataloged; near-duplicates are scroll states.

### Screen inventory (grouped)

| Area | Screens seen | Key mechanics visible |
|---|---|---|
| Onboarding | Main menu; 4-step wizard (League → Team → Coach → Confirm) w/ dot stepper | 134-team default league; custom league (JSON import/export, r/cfbsimulator community); prestige-ranked team picker w/ P4 tier badges; coach name/age/background trait (+1 skill branch); schemes (Pro, 4-3); recruiting difficulty; playoff format 4/8/12(“REALISTIC”)/16; promotion-relegation toggle; prestige cap slider; save name |
| Custom league creator | Modal w/ Load / Import URL / Save / Export JSON | Conferences, independents, bowls, championship logo, 0/32 subdivision, award renaming |
| Season hub (tab) | Preseason + regular-season variants | Phase pill; THIS WEEK card w/ LINE/WIN %/EDGE betting pills; Advance Week vs PLAY GAME; last-game card; Standings / Top 25 / News segments; Stats/Players/Awards quick links; preseason outlook (proj. record, top-25, impact players) |
| Live game | Coin toss; field view; quick-sim sheet | 2D field w/ LOS + first-down lines; drive-grouped play log w/ clock + tappable colored player names; suggested playcall banner; defense sets Base/Blitz/Nickel/Dime/Contain; timeouts; live win-probability bar; live box score; sim speeds Slow/Normal/Fast/Instant; sim-to targets (possession/Q/half/game) |
| Post-game | Matchup report; box score | Quarter-score chips; winner crown card; team stat table; per-position expandable player stat cards |
| Matchup preview | Pre-game sheet | Overall + O/D/ST bar comparisons w/ Home/Away edge chips; spread ↔ win-prob toggle |
| Schedule (tab) | Season list | WEEK badges, OOC/CONF chips, rank badges, spreads, W/L tinted result rows |
| Team (tab) | Team overview; depth chart; player cards ×10 positions | Prestige; schemes; injury report; auto-sort; starter/backup/reserve tints; OVR color tiers (purple 90+/blue/green/orange/red); class chips FR→RS SR; per-position attribute sets (QB Throw Power/Accuracy … K/P Power/Accuracy); Potential letter grades (A+…F); height/weight; season + game-by-game stats |
| Redshirts (preseason tab) | Planner | Per-position RS quotas (QB 0/2, RB 0/3), eligibility, auto-planner, Pre-RS locks |
| Stats | 9-category leaderboard suite | Passing/Rushing/Receiving/Tackles/Sacks/INT/PD/Kicking/Punting; per-category sort + direction; Min-G filter; week/season scope; search |
| Coach (tab) | Hub; My Coach; skill tree; goals; team search; trophy room; settings; credits; edit team/league | Level/XP; 4 skill branches (Recruiting/Development/Offense/Defense) w/ SP-cost node chains; seasonal goals w/ XP + progress; coach cash + salary + contract + Job Security %; retire→legacy; autosave/save/checkpoints; previous seasons; trophy grid (10 types); Game Center-style leaderboard w/ anon handles; God Mode IAP (£3.99: edit contracts, add SP); tutorial replay; theme-color toggle |

### UX patterns to carry over (proven on-device)

- Floating pill bottom tab bar, context-aware (preseason shows fewer tabs); sheets w/ "Done" pill; push for live game.
- Team-color dynamic theming after team selection; neutral accent pre-dynasty.
- Chips/pills for every metadata token; one concept per card; long scroll > dense tables; color-tiered ratings; empty states with icon + "No X yet"; captions under every setting.
- Betting-style predictor (LINE/WIN %/EDGE) as the hook on the weekly loop.
- Fictional naming: real cities/states + invented mascots (Palmetto State Sabal, Provo Wasatch; conferences Magnolia, Prairie, Rustbelt).

## B. Game family — Achi Jones "Football Coach" lineage

- **footballcoach (2016, Android, open source):** github.com/jonesguy14/footballcoach — Java engine (`CFBsimPack`: League/Conference/Team/Game/Player + position subclasses). 12-game season, 4-team playoff, 46-man roster, OVR/Potential + 3 position ratings, recruiting budget. **License: CC NonCommercial** → our build is a clean-room reimplementation: design inspiration only, zero code reuse. Abandoned Dec 2016.
- **Football Coach 2 (college, 2019, closed):** 60 teams/6 conferences; 4.5★ (1.68K). FC1 delisted.
- **Pro Football Coach (2016→2019, closed):** 4.2★ (1.36K), 100K+ installs, abandoned 2019. Shipped: 32 teams (2 conf × 4 div), 16-game season, playoffs = 4 division winners + 2 wildcards/conference; draft + tradeable picks; trade block with "View Offers" from all 31 AI teams; free agency limited by contract load; **contracts without a real cap** ("for simplicity"); player model = age, OVR, Potential, Durability, Football IQ, 3 position ratings; **no TE**; online leaderboard.
- **Community forks:** antdroidx CFB Coach Career Edition (120 teams, firing, coordinators, transfers, TE/LB/DL positions, editor), KushDingies Playcalling Edition (watch + call plays). Fan roster files hosted on GitHub = custom-content culture.
- **Dev's current path:** Steam. College Dynasty (95% positive, 1.4K reviews) → **Pro Football Dynasty** (Steam EA "late 2026"): realistic cap (proration, guarantees, void years, restructures, tags, dead money), two-tier positions incl. EDGE, ranged scouting, college-save import, Coach/GM/Franchise modes, commissioner mode. **Desktop only.**

## C. Community signal (r/FootballCoach, Play reviews)

Validated demand — each maps to a v1 feature (→ `02-GAME-DESIGN.md`):

| Ask / complaint (source) | Our answer |
|---|---|
| "iOS port?" still asked Jul 2026; Android apps dead since 2019 | **The product**: modern native iOS pro sim — the lane is empty |
| No TE, shallow depth charts (PFC reviews) | Full position set incl. TE; drag depth chart; 53+16 PS |
| No defensive player stats / career stats (PFC reviews) | Full 9-category stat suite + career tables + records book |
| Progression "too random" (PFC review, 200 seasons) | Visible potential letters, age curves, camp reveal w/ arrows, dev traits |
| Contracts "not real cap" (dev's own admission) | Full cap: proration, guarantees, dead money, rookie scale, tags |
| Playcalling demand (KushDingies fork, College Dynasty success) | Live play-by-play with play-calling both sides of ball |
| Mid-season saves impossible in originals | Autosave weekly + checkpoints |
| Custom rosters/universes culture (GitHub roster repos) | JSON league template import/export (v1.5, architecture ready day 1) |
| Fast sim loop, "season in <10 min", free/no-ads ethos | Quick Sim tiers; instant advance; no ads; IAP decision deferred |
| Funny generated names, milestone stories | Name banks + news engine + records chasing |

## D. Prior-session extraction (user's working patterns)

Searched all CCD sessions: no prior football/iOS/game sessions exist — the project is genuinely new. What transfers is **methodology**, extracted from the Credit-OS / Deploy-C / COAS-V2 session history:

1. **Spec → plan → build → adversarial review → verify loop.** Sessions repeatedly ran "audit / critique / rebuild plan" cycles with adversarial reviewers before shipping. → Encoded as mandatory phase gates in `CLAUDE.md` (adversarial review + verification before a phase closes).
2. **Numbered, dependency-ordered work packages with one canonical shared doc.** The user's DEPLOY_C skill pack is `cp-0 … cp-8` modules under a `CANON_SHARED.md`. → Mirrored: numbered docs 00–05 with `02-GAME-DESIGN.md` as canon; phases P0–P8 in the implementation plan.
3. **Harness skills the user has installed and uses** (superpowers TDD/writing-plans/subagent-driven-development, adversarial-reviewer, confidence-review, rewrite-tournament, /code-review ultra). → Named explicitly in `CLAUDE.md` so Opus 5 invokes them instead of ad-hoc process.
4. **Checkpoint/restore mindset** (checkpoints, previous-seasons archives in their systems) → matches the game's own save/checkpoint design; also: commit-per-task discipline.

## E. Competitive positioning (one paragraph)

Modern iOS has a polished college sim (the reference app) but **no modern pro football management sim**: the 2016 PFC is abandoned Android-era, and its successor is Steam-only in late 2026. A SwiftUI pro sim that pairs the reference app's proven UX with the cap/draft/trade depth the community has been requesting for years fills a real, validated gap. Ship v1 focused (fixed 32-team league, full cap, playcalling, coach RPG), keep the community-content pipeline (league JSON) as the v1.5 growth hook.

## F. Legal guardrails

- No NFL/NFLPA/NCAA marks, team names, logos, or real player names/likenesses. All 32 teams fictional (naming table in GDD).
- No code from `jonesguy14/footballcoach` (CC NonCommercial) or forks — clean-room engine, own formulas.
- No asset/text copying from "College Football Simulator" (Mani Foroughi) — UX-pattern inspiration only; distinct branding, palette, icon.
- Betting-style pills present spreads as flavor only — no real-money framing.
