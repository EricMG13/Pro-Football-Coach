# 01 — Research: Reference App, Game Family, Community, Prior Sessions

Compiled 2026-08-08 by Fable 5 from: all 68 screenshots in this folder, the GitHub repos, Play Store pages, and r/FootballCoach.

> **Extended 2026-08-09 for the college→pro rebuild.** Sections A–H below are the original research
> and carry forward unchanged. Sections §6.0–§6.5 are new. Two annotations, so that nothing is
> dropped silently: **§E** is superseded in place by §6.3, which argues the market gap as an output
> rather than asserting it, and is kept because its reasoning is still the shortest statement of the
> lane; **§G** was written to feed the now-archived `06-PLAYED-GAME-MODE.md`, and its role has
> changed — it is now evidence about the **arcade pole of the competitive set** (§6.2), not a spec
> input, because direct player control is cut.
>
> **Sourcing convention.** Every claim below carries a source or is labelled **[ASSUMPTION]**. All
> assumptions are collected in §6.6 so the owner can see in one place what the design rests on.
>
> **Tooling note.** `/deep-research` was not available in the executing session. §6.1–§6.5 were
> researched manually with ordinary web search and are **labelled as manually produced** per the
> brief's §10 fallback. The depth is correspondingly shallower than a dedicated research pass, and
> §6.6 says where that shows.

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

## G. Retro Bowl mechanics research (for doc 06)

Sources: Wikipedia, official store pages, retro-bowl fan wiki (CC-BY-SA, cross-verified), Poki, Pocket Gamer/Pocket Tactics reviews, Rob's mechanics guides. Key verified facts driving `06-PLAYED-GAME-MODE.md`:

- **Offense-only control**: player controls offensive snaps, FG/XP kick meter (two taps: power bar, sweeping aim arrow vs wind), and kick returns (mobile paywalls returns behind $0.99 IAP); own kickoffs/punts and the entire defense are simulated — opponent drives resolve as rapid text boxes. No onside kicks; sudden-death OT.
- **Throwing**: drag back from QB = aim with dotted landing arc, release = throw; second-finger tap toggles lob ↔ bullet; **QB Accuracy controls how much of the arc is rendered**, Arm Strength caps distance (~15→25+ yds), Stamina degrades arm over a game. No free pocket movement: throw, scramble (drag forward), or tap-handoff.
- **Carrier control**: auto-run upfield at stat speed; swipe up/down jukes (lane-based), swipe forward dive, swipe back stall; **no sprint button, no spin** — stiff-arms auto-trigger from Strength.
- **Player model**: exactly 4 attributes per position + star rating + hidden potential + condition + morale (7 tiers; low morale → fumbles/missed tackles); injuries rolled post-game weighted by usage/condition/age.
- **Plays**: no playbook — one dealt hybrid run/pass play per snap; audibles reroll it, count = QB level (1–5). Most-criticized design choice.
- **Meta→field**: coordinators (star-rated, with traits like Physio/Motivator/Scout) passively boost their side; facilities (stadium/training/rehab, levels 1–10, decay) move XP/morale/condition; salary cap ~$150M; Coaching Credits currency; fan-approval fail-state.
- **Structure/feel**: 1/2/3-min quarters, full game 5–10 min; landscape side-scroll pixel presentation; difficulty Easy→Extreme (Extreme = stat cheat) + Dynamic (auto-tunes); snow slows players, wind deflects kicks.
- **Community consensus**: loved — one-thumb skill throw, always-on-offense pacing, stats you can *feel*, franchise loop. Complained — defense is a dice-roll you watch, no real play-calling, too easy for veterans, FG meter disproportionately hard, returns paywalled. Retro Bowl College kept the engine, added college meta (recruiting, GPA, 250 teams, 12-team playoff).
- **Our responses** (doc 06): keep full playbook (their #1 strategy complaint), animate defensive possessions with your playcall instead of text boxes (#1 overall complaint), difficulty via AI reaction/closing not stat cheats, returns free, original presentation (no scanlines/CRT framing, our palette+fonts).

## H. Reference-app user comments mined (App Store + r/cfbsimulator, Aug 2026)

App = "CFB Simulator" (id 6752640167), 4.78★/625 US ratings; 86 reviews + full subreddit archive (395 posts, 1,312 comments) analyzed. Solo dev replies to 42% of posts, median 2.2 h — responsiveness itself earns 5★ reviews and IAP purchases. IAP: God Mode $3.99, scenario packs $2.99, **paid checkpoint tokens (= crash insurance)**.

**Complaint/request league table (→ what our design does):**

| Rank | Theme (share) | Our answer |
|---|---|---|
| 1 | **Crashes/save corruption/softlocks** — 34% of reviews; corruption ~season 8; end-of-game clock hangs, double-sim injuries, endless OT; users buy checkpoint tokens as crash insurance | Stability is a feature: atomic writes + rolling backup + migration fixtures (03 §5), soak-test gates (05 P7), hardened end-of-game state machine called out as top risk (00), **checkpoints free** |
| 2 | **Job-market dead ends** — contract expiry with zero offers = dead save | Invariant in 02 §10: carousel always yields ≥1 offer or explicit "unemployed year" path; poaching + proactive applications |
| 3 | **Sim believability** — "90 OVR struggling vs 76", late-game difficulty collapse, stat oddities (safeties, blocked kicks 10× too common, no long TDs, dead Q4, TE unused); **watched vs simmed games diverge** (dev-confirmed weighting bug; community meta = "watch games to get good results") | **One engine, one distribution** — parity test simmed-vs-played-retention in P2 gate; extended calibration bands (02 §4); AI teams rebuild so year-10 stays hard |
| 4 | **History/records/HoF** — top-upvoted request class; college dev blocked by save bloat ("100s of MB") | Records/HoF in v1; storage plan: aggregates in history, play-by-play trimmed (03 §9) |
| 5 | **Staff management** — hire/fire OC/DC/ST, scheme fit, start-as-coordinator | Coordinators v1 (02 §10); coordinator career mode backlog |
| 6 | Recruiting UX friction (filters, sort, undo, interest %) — loop itself loved | Same list-UX lessons applied to FA/draft/scouting screens (04 §11–12) |
| 7 | **Modding = community engine** (~86 posts share league JSONs via raw URLs); want in-app browser | JSON import/export v1.5; in-app community browser added to backlog |
| 8 | Stats presentation (benchmark: Pocket GM 3), prediction lines | Stats suite + records + spread pills in v1 |
| 9 | **Game-day control suite**: clock management/tempo ("chew clock"), smarter AI EV decisions, XP-after-expiring-TD sequencing, usage sliders, sit/play injured | Tempo toggle + fixed sequencing added to 02 §4; EV-driven AI; usage sliders backlog |
| 10 | Immersion: reacting social feed (signature feature), press conferences, awards | News engine v1; social-style feed + pressers = backlog candidates |

**Pro-version demand:** explicit but low-volume ("I hope you guys make a pro version!!", direct Reddit ask to dev, Pocket GM 3 cited twice as the pro benchmark, users hacking NFL leagues into the college app via custom JSON). Dev's family has **no pro title** — lane confirmed empty.

**Arcade-mode reality check:** in this community *nobody* requested joystick/arcade play — they want coach-brain control, speed options, trustworthy outcomes. Retro-style demand lives in a different (much larger, more casual) market. Hence doc 06's positioning: On-the-Field is one of three modes, never required, and the sim/playcall paths must stay first-class.

**Meta-lessons to copy:** ship fast + changelog posts to community, TestFlight beta, polls, answer within hours; monetize (if ever) via editor + scenario packs, never ads, never paid crash insurance.

## F. Legal guardrails

- No NFL/NFLPA/NCAA marks, team names, logos, or real player names/likenesses. All 32 teams fictional (naming table in GDD).
- No code from `jonesguy14/footballcoach` (CC NonCommercial) or forks — clean-room engine, own formulas.
- No asset/text copying from "College Football Simulator" (Mani Foroughi) — UX-pattern inspiration only; distinct branding, palette, icon.
- Betting-style pills present spreads as flavor only — no real-money framing.

---

# Part 2 — Rebuild research (2026-08-09)

## §6.0 Playing the build that exists — engagement post-mortem

The audit measured craft and scored it 9/20. Nothing has ever measured **engagement**. This section
was supposed to be the primary evidence in the whole package: the app runs, so play it.

### What actually happened, stated before anything is concluded from it

**The executing session could not run the build.** `swift` is absent from the container, there is no
Xcode, no simulator, and `download.swift.org` is refused by the egress policy — the same conditions
`STATUS.md` records for the session that shipped Phase 4C uncompiled. So the play session did not
happen, and **every engagement number below is derived from reading the source, not from playing.**

This is a genuine contradiction inside the brief that commissioned this document: §6.0 says "it is
cheap: the app builds and runs", and §8 says "this container has no `swift` and no `xcodebuild`".
Both cannot be true of the same session. It is logged as **[BLOCKING-2]** in
`docs/OPEN-DECISIONS.md` and the protocol below is handed to the owner as an owner-verifiable
instrument.

What follows is therefore split honestly:

- **§6.0a** — the protocol, stated in advance, for the owner to run on a machine with Xcode.
- **§6.0b** — a *static decision-surface census*, which is a real measurement of a real thing (how
  many decisions the code offers per week) and is **not** a measurement of attention, fun, or the
  point at which a player puts the phone down. It cannot disconfirm the owner's diagnosis by itself.

### §6.0a Protocol — for the owner, on a machine with Xcode

State the protocol before running it; report against it including the parts that disconfirm.

1. Build and launch. Start a new franchise. **Start a stopwatch and do not stop it.**
2. Play **six consecutive in-game weeks** without reading any documentation.
3. For each week record, in a table:
   - wall-clock for the week, split **match time** vs **management time**;
   - **meaningful decisions** — ones where a reasonable coach could have gone the other way — versus
     **confirmations** (buttons whose only sensible answer is "yes, continue");
   - every screen opened, tagged *opened-and-acted*, *opened-and-read*, or *opened-once-never-again*.
4. Note the wall-clock time at which attention first drops — the first moment you want to skip,
   check your phone, or stop — and **write down what you were looking at**.
5. Then play one game in each of the three modes (Sim, Call Plays, On the Field) and record which
   one you would choose on week 7 if nobody were watching.
6. Report against every numbered item above, **including the parts that disconfirm the diagnosis.**
   If the game was more engaging than "a bland application", say so.

**Thresholds fixed in advance**, so the result can falsify rather than illustrate:

| Metric | Threshold | Reading if missed |
|---|---|---|
| Meaningful decisions per in-season week | **≥ 5** | The week is empty; blandness is an agency-density problem |
| Confirmations per meaningful decision | **≤ 2:1** | The loop is administration, not coaching |
| Wall-clock per week | 12–22 min | Outside P4's budget in one direction or too thin in the other |
| Attention drop | not before week 4 | Something is wrong before the systems even open up |
| Mode chosen unobserved at week 7 | — | If *On the Field*, the tactile layer is load-bearing (see §3 of the brief) |

### §6.0b Static decision-surface census — what the code offers

Measured by reading `Sources/ProFootballCoachUI/`, commit `47ac105`. This counts **affordances**,
which is an upper bound on decisions and says nothing about their weight.

**The in-season week, as built.** `SeasonHubView.swift` is the entire weekly loop. Its interactive
surface, in full:

| Control | Kind |
|---|---|
| Segmented picker: Standings / Top-25 / News | inspection |
| Matchup preview sheet | inspection |
| **Sim** / **Call Plays** / **On the Field** | **1 decision** — how to experience the game |
| Advance Week | confirmation |
| One `NavigationLink` to the last game | navigation |

Everything else in the app sits behind four other tabs — Schedule, Team, Front Office, Coach — and
is overwhelmingly **reporting**: standings, stats leaderboards, record book, hall of fame, trophy
room, news feed, player cards, power rankings. These are the screens the audit found aggregating
2,208 players' careers inside a view body: expensive to render, and read-only by nature.

The recurring in-season **actions** that do exist:

| Action | Where | Frequency | Note |
|---|---|---|---|
| Depth chart reorder | Team | any week | An **Auto-Sort** button exists, which converts the one recurring roster decision into a confirmation for any player who trusts it |
| Street free agency | Front Office | any week | Real, but only bites after injuries |
| Practice squad elevate / demote | Team | any week | Real, narrow |
| Trades | Front Office | **until week 9 only** | The deadline removes this from 9 of 18 weeks |
| Scouting spend | Front Office | draft prep | Points are per-season, so this is a few decisions, not weekly |

**The finding.** On the most generous count the built week offers roughly **1–3 decisions**, only
one of which is offered every week, against a threshold of ≥5. On the strict count — decisions that
change what happens on Sunday rather than what you look at — it offers **one**: which of three ways
to watch. The offseason, by contrast, is dense: re-signing, free agency, a seven-round draft played
pick by pick, cuts, training camp, the carousel.

**The diagnosis this supports is narrower and more useful than "a bland application".** The prior
build was not short of systems. It had a full salary cap with proration and dead money, a scouting
fog, a coaching carousel, a records book, 224 tests and a ten-season soak that held. What it was
short of was **anything to do on a Tuesday.** Depth was real and it was almost entirely stacked into
the offseason, which the player reaches after eighteen weeks of pressing Advance.

### §6.0c The arcade layer — what it was substituting for

Two pieces of evidence point in opposite directions and reconcile into one conclusion.

- `STATUS.md` records that "On the Field" is the part the owner **actually played on device** — the
  kick meter, the drag-to-aim, a 51-yard field goal made through the meter. It is also the only part
  of the app whose touch targets were consciously sized (`minHeight: 44`, per `AUDIT.md`'s positive
  findings), which is what care looks like in a diff.
- §H of this document records that in the reference app's community, **nobody requested arcade
  play**: "they want coach-brain control, speed options, trustworthy outcomes."

The reconciliation: the arcade mode was not satisfying a demand for twitch gameplay. It was the only
place in the app where the player's input changed an outcome in the next ten seconds. **It was
substituting for weekly agency, not for a joystick.**

This is load-bearing for the rebuild and it cuts both ways:

- Removing direct control is defensible — the community signal says the demand isn't there, and the
  owner's own play pattern is explained by agency density rather than by tactility.
- **But removing it while leaving the week at one decision produces a strictly worse game than the
  one being replaced.** The arcade layer was carrying the entire moment-to-moment loop. If the
  rebuild deletes it and the Tuesday is still empty, the result is the "better-looking bland
  application" the brief warns about, and this time with nothing to fall back on.

Which is why §4's agency model is gate zero, and why the design's answer is to move agency **into
the week and into the sideline**, not to compensate with presentation.

### §6.0d What this section cannot tell you

Stated plainly so it is not over-read:

- It cannot tell you when attention drops. That requires a human and a stopwatch.
- It cannot tell you whether the *quality* of the offseason decisions compensated for the emptiness
  of the week. A count of affordances is not a measure of weight.
- It cannot confirm or refute "bland". It can only say **where** in the calendar the agency isn't.
- It has not measured wall-clock per week at all, so P4's budget is currently unvalidated against
  any real build. §6.0a is the instrument that would fix that.

---

## §6.1 Football Manager Mobile — specifically, not desktop FM

*Manually researched; primary sources are Sports Interactive's own in-game manuals.*

The single most useful thing FM Mobile does for this project is that it has already solved the
problem §4 poses, and it solved it with **presentation controls rather than by reducing the
simulation**:

- **Two match views**: a *Full* view following the action from a horizontal full-pitch viewpoint,
  and *Commentary Only*, which displays text summaries of moments. ([SI manual,
  FM24 Mobile Matchday](https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2024/matchday-r5239/))
- **Highlight granularity is a player setting**: *Extended* highlights versus *Key moments* only.
  ([SI manual, FM26 Mobile Match
  Day](https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/match-day-r5263/))
- **Two independent speed sliders**: one for how fast commentary progresses, and one for **how
  quickly the clock moves when there is no action to show**. ([SI manual, FM23 Mobile
  Matchday](https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2023/matchday-r4945/))
- The 2D pitch shows the **classic dot representation** rather than 3D models. (ibid.)

**What this means for us.** FM Mobile does not ask the player to watch 90 minutes. It asks them to
watch *the moments*, at a speed they choose, and it separates "time when something is happening"
from "time when nothing is". That is exactly the term §4 calls **presentation time**, exposed as a
control instead of a constant. American football is *better* suited to this than soccer, because the
sport is already discretised into snaps and drives — a natural highlight unit exists without having
to detect one.

The mobile game is described as clearly less detailed than desktop, closer to an older era of FM
([TouchArcade, FM24 review across
platforms](https://toucharcade.com/2023/11/14/football-manager-2024-review-touch-vs-mobile-vs-ps5-vs-pc-steam-deck-features-save-controller-console/)),
and its interface is deliberately simplified so players can get into matches and transfers quickly
([Charlie
INTEL](https://www.charlieintel.com/games/football-manager-2024-mobile-new-features-explained-282061/)).
**What it removed was breadth of management, not the match.** It kept the thing you watch and cut
the things you administer. A rebuild that does the opposite — keeps a deep front office and thins
the match — is copying the wrong half.

**Why FM's players stay engaged** (the §3 question). The literature and long-form commentary
converge on four mechanisms, none of which is "depth":

1. **Emergent narrative with real consequences** — a different story every save, where the terms of
   winning are largely set by the player. ([loudpoet, *Is Football Manager the greatest RPG
   ever?*](https://loudpoet.com/2023/09/23/is-football-manager-the-greatest-rpg-ever-tldr-yes/))
2. **Attachment and identity** — FM functions as a persuasive game for social-identity formation;
   players bond with the club and with their own managerial persona.
   ([ResearchGate](https://www.researchgate.net/publication/344045316_Football_Manager_as_a_Persuasive_Game_for_Social_Identity_Formation))
3. **Ownership** — players become attached to individuals they developed themselves, with traits and
   histories that accumulate. ([Talavera, *The psychology behind Football Manager
   addictions*](https://clubfutboltalavera.com/the-psychology-behind-football-manager-addictions-more-than-just-a-game/))
4. **Jeopardy** — the match can go wrong while you watch, and you can do something about it *during*.

Depth is the **substrate** these run on, not the cause. A system the player cannot affect, cannot
narrativise and cannot lose to produces no engagement however deep it is. This is the direct answer
to §3: *the previous build had (1) partially, via news and records; had (3) via the draft and
progression; and had almost none of (4) in-season, because there was nothing to do while the game
was happening.*

---

## §6.2 The real competitive set

*Manually researched. The competitive set for this product is not Football Manager.*

### Draft Day Sports (Wolverine Studios) — Pro Football and College Football

- **Loop**: deep front-office management; DDS:CF 2026 lets you start as a **coordinator** and rise
  to head coach, building playbooks, recruiting, managing team cohesion against "adaptive AI".
  ([Steam](https://steamcommunity.com/app/3914070))
- **Agency model**: game-planning and roster construction, with a 3D/2D game view to watch.
- **What its community complains about**: **stability first** — crashing during gameplay, season
  processing freezes; a specific report of crashes when playing as Offensive Coordinator during the
  first game of a season. Also presentation requests as basic as a "follow the ball" option in the
  3D view. ([Steam
  discussions](https://steamcommunity.com/app/3914070/discussions/))
- **Platform**: Windows desktop. **Monetisation**: annual paid release.

### Football Coach: College Dynasty (Steam)

The closest analogue to our college tier, and the most instructive.

- **Reception**: ~95% positive across ~1,474 reviews — a genuine success.
  ([Steam](https://store.steampowered.com/app/2151290/Football_Coach_College_Dynasty/))
- **Loop**: exclusively sim-based, in the FM / OOTP mould. **Recruiting and roster management are
  the biggest piece**, with NIL as a featured mechanic. ([Operation Sports
  review](https://www.operationsports.com/football-coach-college-dynasty-review-a-sports-sim-with-training-wheels-for-better-and-worse/))
- **What its community complains about** — and this is the most valuable paragraph in this section:
  - it reads as a **"college football recruiting simulator" rather than a coaching simulator**, with
    "pretty limited in-game decisions" and limited substitution settings;
  - recruiting is the only *meaningful* system, and it "lacks real variation and can become boring";
  - program upgrades are linear levels rather than real micromanagement;
  - perceived **rubber-band AI** — "anti-upset cheese", sudden defensive breakdowns that read as the
    game having decided you should lose despite good game planning.
  ([Steam negative
  reviews](https://steamcommunity.com/app/2151290/negativereviews/?browsefilter=toprated),
  [general
  discussions](https://steamcommunity.com/app/2151290/discussions/0/689744580780942089/))

**Read that against §6.0b.** The most successful game in our exact genre is criticised for *the same
defect the previous build has*: the in-game decision surface is thin, and the depth lives somewhere
else (there, recruiting; here, the offseason). This is not a coincidence and it is not a solved
problem in the market. It is the gap.

The rubber-band complaint is equally load-bearing: it is a **fairness-perception** failure, not a
difficulty failure, and it is what D10 (AI quality) has to avoid. Players will forgive losing; they
will not forgive being *decided against*.

### Front Office Football (Solecismic) — the pure-text pole

- The elder statesman of the genre; deep enough that it is still the benchmark for front-office
  fidelity.
- **Presentation is its known weakness**: the UI is "clean and functional but not much more", text
  small and bland, trailing OOTP and FM on presentation
  ([GM Games review of FOF7](https://gmgames.org/front-office-football-fof-7/review/)); and the
  much-quoted framing that "if Madden's visuals are a Cray Supercomputer, then FOF is a typewriter"
  — you watch the play-by-play scroll past ([Football
  Outsiders](https://www.footballoutsiders.com/reviews/2007/game-review-front-office-football)).
- **The lesson**: a great simulation with no presentation layer stays a niche within a niche. FOF
  proves depth alone does not broaden appeal, which is the §3 warning stated by a shipped product
  with a 25-year history.

### Retro Bowl / Retro Bowl College — the arcade pole

Full mechanics research is in **§G** above and carries forward. The three facts that matter here:

- It is enormously more popular than anything else in this list, and it is **offence-only direct
  control** with no playbook — one dealt hybrid play per snap, which is also its most-criticised
  design choice (§G).
- Its community's complaints are exactly the ones a management sim answers: "defense is a dice-roll
  you watch", "no real play-calling" (§G).
- **It is a different market.** §H's arcade-mode reality check found that the coach-sim community
  does not ask for it.

### The pro-side reference apps (§B carries forward)

The Achi Jones lineage: `footballcoach` (2016, CC-NC, abandoned), Football Coach 2, **Pro Football
Coach** (2016→2019, 4.2★/1.36K, 100K+ installs, abandoned — shipped *contracts without a real cap*
"for simplicity", and no TE), and the dev's current desktop-only path to **Pro Football Dynasty**
(Steam EA "late 2026"). See §B for the full detail.

### Summary table

| Title | Platform | Agency model | Match presentation | Money | Chief community complaint |
|---|---|---|---|---|---|
| FM Mobile | iOS/Android | Pre-match tactics + in-match adjust | 2D dots, highlight-filtered, speed sliders | Netflix / paid | Thinner than desktop |
| DDS: CF / PF | Windows | Game plan, recruiting, coordinator career | 2D/3D watchable | Annual paid | **Stability**; presentation basics |
| FC: College Dynasty | Windows | Recruiting-led, sim-only | Sim + text | Paid | **Limited in-game decisions**; rubber-band AI |
| Front Office Football | Windows | Front office, deep | Text play-by-play | Paid | Presentation |
| Retro Bowl (College) | Mobile | **Direct control**, offence only | Side-scroll pixel arcade | F2P + IAP | No playbook; defence is a watched dice-roll |
| Pro Football Coach (2016) | Android †  | Front office | Text | Free | No real cap; no TE; abandoned |
| Reference college app (§A) | iOS | Playcall + management | 2D field + play log | £3.99 IAP | **Crashes/save corruption (34%)**; job dead-ends; sim believability |

† delisted / abandoned since 2019.

---

## §6.3 The market gap — argued, not assumed

This is an **output** of §6.0–§6.2, not a premise.

**Three facts, each sourced above:**

1. **The mobile lane is empty on the pro side and thin on the coaching side.** The only modern,
   polished mobile entry in this family is the college reference app (§A, §H); the pro entries are
   abandoned Android-era products (§B); the credible modern competition — DDS, FC:CD, FOF, Pro
   Football Dynasty — is **all Windows desktop** (§6.2). Demand for a pro version is explicit in the
   reference app's community but low-volume (§H).
2. **The genre's best-reviewed title is criticised for having too few in-game decisions** (§6.2,
   FC:CD). That is not a stability bug or a content gap; it is a *design* gap, and it is the same
   gap §6.0b found in our own prior build.
3. **The market's reliability bar is on the floor.** 34% of the reference app's reviews concern
   crashes, save corruption around season 8, and softlocks — to the point that users buy checkpoint
   tokens as crash insurance (§H). DDS's own forum leads with crashes and freezes (§6.2).

**The gap, stated as a product:**

> A native iPhone career simulator in which **the in-season week is the dense part**, the match is
> watched from the sideline at a speed the player controls, the career spans college and pro in one
> save, and it **does not break** — no corruption, no dead-end saves, no rubber-band AI.

Each clause is doing work, and each is defended by a fact above rather than by taste:

- *Native iPhone* — the competition is desktop; the one mobile success proves the audience is there.
- *Dense in-season week* — the #1 design complaint about the best game in the genre, and the
  measured defect in our own build.
- *Speed the player controls* — FM Mobile's solved answer to the same arithmetic problem (§6.1).
- *College and pro in one save* — nobody in this list does it. FC:CD is college-only; DDS ships them
  as two separate products; Pro Football Dynasty offers a college-save *import*, which is the
  seam this design removes.
- *Does not break* — the single largest complaint class in the entire competitive set, and the
  cheapest one to win on, because it is a matter of engineering discipline rather than invention.

**What would falsify this gap claim**: if the owner's §6.0a play session finds the built week
already engaging at 1–3 decisions, then clause 2 is wrong and the gap is presentation-only, which
would be a materially different product. Instrument: §6.0a, thresholds fixed above.

---

## §6.4 Statistical calibration targets

**Start from what is already asserted.** The prior build's suite calibrates a 600-game sample and
these bands are the most reusable artifact in the repo. Captured verbatim from
`Tests/SimTests/Suites/GameSimulatorTests.swift`, commit `47ac105`:

| Metric | Band (per team-game unless noted) |
|---|---|
| Points | 20–26 |
| Pass yards | 195–245 |
| Completion % | 61–67 |
| Rush yards | 100–130 |
| Interceptions | 0.6–1.1 |
| Sacks | 2.0–3.1 |
| Field goal % | 80–90 |
| Overtime rate | 0.008–0.14 |
| Home win rate | 0.50–0.60 |
| Offensive plays | 55–72 |
| Q4 share of points | 0.22–0.32 |
| Explosive plays (25+ yd), per game | 3–9 |
| Long TDs (40+ yd), per game | 0.2–1.2 |
| Safeties per game | ≤ 0.05 |
| TE target share | 0.15–0.26 |
| RB target share | 0.10–0.28 |
| Max single-receiver share | ≤ 0.45 |

Two design notes worth carrying forward with them. The home-win band is deliberately wide because
600 games gives ~2pp of standard error and a tighter band would fail on sampling noise rather than
on a regression — **band width is a statistical decision, not a taste decision**. And the safety and
long-TD bounds exist because the reference app's community specifically complained about freak
events being an order of magnitude too common (§H, rank 3).

**The genuine gap is college.** The bands above are pro-shaped and do not transfer:

| Dimension | Why it differs | Status |
|---|---|---|
| Plays per game | College tempo runs far above the pro game; the pro band of 55–72 is wrong for college | **Needs a college band** |
| Points per game | Higher, and far wider variance | **Needs a college band** |
| Talent dispersion | The defining difference. A pro league is 32 teams inside a narrow band; a ~134-programme college league spans blowout-level mismatches. **A single-distribution model calibrated on pro data will produce college games that are far too close** | **Needs an explicit dispersion model, not just a band** |
| Completion %, sacks | Directionally similar, different centres | Needs re-centring |
| Kicking | Materially worse than pro at range | **Needs a college band** |

**Sources and their licensing — the two postures, stated explicitly as the brief requires:**

- **At design and calibration time**, aggregate published statistics (national per-game averages and
  distributions from public statistical references such as
  [TeamRankings](https://www.teamrankings.com/college-football/stat/plays-per-game) and
  [ESPN team stats](https://www.espn.com/college-football/stats/team)) are used to *choose band
  centres and widths*. What is taken is a handful of scalar targets — "plays per game centres near
  X" — which is the use of facts, not the copying of a database.
- **At ship time, none of it is bundled.** No dataset, no table, no per-team or per-player real
  statistics are compiled into the app or shipped as a resource. The app contains fictional teams
  and generated players; the only trace of the research is the *numeric band in a test file*.
- **Flagged for counsel, not resolved here**: whether even test-file band constants sourced from a
  commercial statistics provider's presentation of public data carry any contractual restriction
  from that provider's terms of use. The underlying facts are not copyrightable in the US; a
  provider's compiled presentation may still be governed by its terms. **The safe path, and the
  recommended one, is to source band centres from a primary official-statistics publication rather
  than a commercial aggregator, and to record the source next to each band in the test file.**
  Logged in `docs/OPEN-DECISIONS.md`.

**Instrument.** Every band above becomes an assertion in the calibration suite, with the college
bands gated behind the phase that introduces the college tier. The harness is specified in
`docs/03-MATCH-ENGINE.md`.

---

## §6.5 2D match presentation without direct control

*Manually researched, plus direct evidence from this repo's own Phase 4C.*

**What comparable titles do.** FM Mobile's answer is the **classic dot representation** with
highlight filtering and speed control (§6.1) — the deliberate choice of dots over models is what
makes it legible on a phone and cheap to render. DDS offers a watchable 3D view, and its community's
request is revealing: *a "follow the ball" option* (§6.2). Even with a full 3D presentation, the
thing players actually wanted was **help knowing where to look**. FOF sits at the other pole — pure
scrolling play-by-play text — and is the genre's standing proof that a simulation with no
presentation stays niche (§6.2).

**What makes a dot view legible rather than noise.** Synthesising the above with the spatial work
already done in `docs/archive/plans/2026-08-09-arcade-all22.md`:

1. **Draw the answer, not the physics.** 22 dots moving plausibly is noise. 22 dots where the
   *relevant* three are emphasised is a sentence. The engine already resolves *which matchup decided
   the play*; the renderer's job is to make that one legible.
2. **Anchor to the football's structural furniture.** Line of scrimmage, line to gain, hash marks,
   the down-and-distance. These do more for comprehension than any amount of motion fidelity, and
   they are free to draw.
3. **The last frame must be the truth.** Phase 4C's `Choreographer` pinned the last frame of the
   animation to the engine's recorded yardage. That constraint is what stops the picture and the box
   score disagreeing — the failure the reference app's community named as *watched vs simmed games
   diverge* (§H, rank 3), which was serious enough there that the community meta became "watch games
   to get good results".
4. **Highlight granularity is a setting, not a constant** (§6.1). Snap-level, drive-level, or
   key-moments-only.
5. **Text is a first-class channel, not a fallback.** The play-by-play line is what a player reads
   when the dots have moved on, and it is also the accessible representation (D12). Write it first;
   the animation illustrates it.

**Legibility risk, named.** American football's all-22 is *denser* than soccer's: 22 players in a
53⅓-yard width, most of the meaningful action inside five yards of the line, on a ~390pt-wide
portrait phone screen. A faithful all-22 at that scale is unreadable, and the previous build's field
view was never compiled, so nobody has ever looked at it. **Presentation legibility is a design
risk, not a rendering risk**, and it is D2's problem to answer with camera framing, selective
emphasis and zoom — not with more pixels.

---

## §6.6 Assumptions — what this design rests on that is not sourced

Collected here so the owner can see them in one place, as the brief requires.

| # | Assumption | Where it bites | How it would be tested |
|---|---|---|---|
| A1 | The owner's 6–8 h season budget (P4) describes *desired* pacing, not observed behaviour — no build has ever been timed against it | §4 arithmetic, D4 | §6.0a step 3, then a timing harness on the rebuild |
| A2 | The prior build's low weekly agency, rather than its craft defects, is what made it feel bland | The entire §4 premise | §6.0a: if attention holds through week 6 at 1–3 decisions/week, A2 is wrong |
| A3 | ~1.2 s of compressed animation per snap is watchable and comprehensible | The whole presentation budget in §4 | A timing + legibility check on device; owner protocol in `04` |
| A4 | Players will accept not calling defence per-snap if defensive identity is set in the game plan | D1 | Owner play session; the fallback is a defensive call-in on high-leverage snaps only |
| A5 | Recruiting AI for ~134 programmes fits inside the week-advance budget on an iPhone 12-class device | D3, D4 | A benchmark harness, gated in the phase that adds the college tier |
| A6 | Procedurally seeded rivalries can carry real emotional weight without authored history | D6, D13 | Owner play session at season 5+; the fallback is authored anchor rivalries |
| A7 | A single unified college→pro save is more compelling than two separate modes | P2, D5 | Not testable pre-release under P5. **Owner conviction; logged as such.** |
| A8 | The 2016-era pro reference app's abandonment reflects developer attrition, not absent demand | §6.3 clause 1 | Not testable. Mitigated by §H's explicit pro-version requests |
| A9 | College statistical dispersion can be modelled as a widened talent distribution over the same engine | §6.4, D3 | A calibration band on blowout frequency, in the college phase |

**Where the manual research is thinner than a dedicated pass would be** (§10 fallback, declared):
FM Mobile's actual per-match wall-clock is not published and was not measured — §6.1's argument
rests on the *existence* of its speed and highlight controls, which is documented, rather than on
timings, which are not. Community-complaint mining for DDS and FC:CD is drawn from search summaries
of Steam discussions rather than a full archive read of the kind §H represents for the reference
app. §H remains the deepest community evidence in this document, and it is about the college
reference app, not the pro market.
