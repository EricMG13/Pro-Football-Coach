# 02 — Game Design: Pro Football Coach

The game. Canon for gameplay: if a mechanic is not here, it is not agreed, and it gets written here
before it gets built.

Evidence is in `01-RESEARCH.md`. Decisions and their falsifiers are in `OPEN-DECISIONS.md`. The
match engine that implements §3 is in `03-MATCH-ENGINE.md`.

---

## 1. Vision

> You are a football coach. You start at a college programme nobody rates, and if you are good
> enough, you finish in the pro league. One save, one career, one coach.

Three pillars, each of which is a constraint on everything below:

1. **The week is the game.** Not the offseason, not the draft — the seven days between kickoffs.
   This is a direct response to §6.0b, which measured the prior build's in-season week at *one*
   branching decision, and to §6.2, where the genre's best-reviewed title is criticised for
   "pretty limited in-game decisions".
2. **You coach, you never play.** No direct control of any athlete, ever. Your inputs are a game
   plan, personnel, tempo, and the calls a coach actually makes on a Sunday.
3. **It remembers.** Rivalries, records, grudges, the player you developed from a two-star, the
   programme that fired you. A career that accumulates is the thing FM players are actually
   attached to (§6.1), and it is nearly free to build if designed in from the start.

**The anti-goal.** A better-looking version of what came before: a beautiful, deep, deterministic
simulation with an empty Tuesday. Everything in §3 exists to prevent it.

---

## 2. The shape of a career

One save. One coach. A career runs:

```
College tier                                        Pro tier
──────────────────────────────────────────────────  ─────────────────────────────
Low-major programme → build → win → get noticed  →  Coordinator or head coach offer
   recruiting, portal, NIL, eligibility               draft, cap, free agency, trades
   ~134 programmes, 12 + championship + playoff       32 teams, 17 + bye + playoffs
```

The promotion is **the** narrative arc of v1, not a v2 addition (P2). Details in §7.

---

## 3. Gate zero — the agency model

> **Agency density versus season throughput.**

This is the most consequential decision in the project. It is resolved with arithmetic, and the
arithmetic is shown.

### 3.1 The budget

P4 fixes a full season at **6–8 hours**. Working figure **7 h = 420 min**.

A season is ~20 in-season weeks in both tiers (college: 12 games + conference championship +
playoff ≈ 16–17 weeks with byes; pro: 17 games + bye + playoffs ≈ 21 weeks). The offseason is real
time and gets a real allocation: **60 min**.

```
420 min − 60 min offseason = 360 min ÷ 20 weeks = 18 minutes per week, inclusive of the match
```

**18 min/week is the number every option below has to survive.** It is tighter than the brief's
own 21 min because the offseason has been priced rather than folded in.

### 3.2 Terms, declared rather than assumed

| Term | Value | Note |
|---|---|---|
| **Snaps** | Pro **130**/game (65 offensive + 65 defensive). College **150–180**, working figure **170** | This is snaps your team is on the field for |
| **Does the player call defence?** | **No, not per snap.** Defensive identity is set in the game plan and adjusted at drive boundaries | This is the single largest lever in the whole calculation — calling both sides doubles the decision surface |
| **Decision time** | 8 s per discrete in-match intervention | Includes reading the situation, not just the tap |
| **Presentation time** | **1.2 s per snap** at default speed; 5 s per snap at full fidelity | The load-bearing number. See §3.5 |
| **Attention share** | **1.0** | There is exactly one game per week that is yours. The other ~15 (pro) or ~65 (college) are simulated off-screen and never watched. Attention share here is a *presentation-speed* choice, not a game-skipping one |
| **Season length** | Pro 21 weeks, college 16–17 | Both near 20 |

### 3.3 The options considered

**Option A — every-snap play-calling, both sides of the ball.**

```
130 snaps × (4 s decide + 5 s watch) = 1,170 s = 19.5 min/game   (pro)
170 snaps × 9 s                      = 1,530 s = 25.5 min/game   (college)
```

The match alone exceeds the 18-minute weekly budget before a single management decision. To fit, the
attention share must fall to ~0.5 and week management must compress to ~4 min — i.e. you build a
match mode that is skipped half the time, wrapped around a management game with nothing in it.
**Rejected on arithmetic.**

**Option A′ — every-snap play-calling, offence only.**

```
 65 × 9 s =  585 s =  9.8 min/game  (pro)     → 8.2 min left for the week
 90 × 9 s =  810 s = 13.5 min/game  (college) → 4.5 min left for the week
```

Pro survives; **college fails**, and college is the tier the budget must be derived from. It also
concedes half the sport: the defence becomes a dice-roll you watch, which is precisely Retro Bowl's
most-cited complaint (§G) and the reference app's rank-3 complaint class (§H). **Rejected.**

**Option B — pure spectate, halftime and weekly adjustment only.**

```
130 × 6 s = 13.0 min/game watching, ~2 decisions
```

72% of the weekly budget spent to deliver almost no agency. This is the "better-looking bland
application" the brief warns about, made literal. **Rejected.**

**Option C — situational call-ins, coordinator AI handles the rest.**

```
12 call-ins × 10 s = 2.0 min decisions
118 snaps × 1.2 s  = 2.4 min compressed presentation
 12 snaps × 6 s    = 1.2 min at full fidelity
                   ≈ 5.6 min/game
```

Survives the arithmetic. Its defect is **narrative, not numeric**: the player never sets a plan, so
every decision arrives cold. You are a fireman, not a coach — and there is no way to be *right in
advance*, which is where a coaching game's satisfaction actually lives. **Rejected, but its
call-in mechanic is absorbed into D.**

**Option D — the Sideline Model. CHOSEN.**

Pre-match game plan (set during the week) + drive-level watching + discrete high-leverage
interventions + in-drive adjustments + opt-in snap-level fidelity.

### 3.4 The chosen model, priced

**Pro:**

| Term | Working | Minutes |
|---|---|---|
| Baseline presentation | 130 snaps × 1.2 s | 2.6 |
| Discrete interventions | 14 × 8 s | 1.9 |
| Opt-in full-fidelity drives | 2 drives × 6 snaps × 5 s | 1.0 |
| Possession changes, scores, halftime | — | 0.7 |
| **Match total** | | **6.2** |
| Week management | game plan 3 · development 2 · roster & injury 2 · inbox 1 | 8.0 |
| **Week total** | | **14.2** vs 18 budget |

**College — the binding case:**

| Term | Working | Minutes |
|---|---|---|
| Baseline presentation | 170 snaps × 1.2 s | 3.4 |
| Discrete interventions | 16 × 8 s | 2.1 |
| Opt-in full-fidelity drives | 2 × 6 × 5 s | 1.0 |
| Transitions | — | 0.7 |
| **Match total** | | **7.2** |
| Week management | game plan 3 · **recruiting 3** · development 2 · roster 1 · inbox 1 | 10.0 |
| **Week total** | | **17.2** vs 18 budget |

**Season check:**

```
College: 16 wk × 17.2 = 275 min + 60 offseason = 5.6 h   ✓ inside 6–8 h
Pro:     21 wk × 14.2 = 298 min + 60 offseason = 6.0 h   ✓ inside 6–8 h
```

College clears the weekly budget by **48 seconds**. That is not comfortable, and it is stated
plainly rather than rounded away: **the college week is the design's tightest constraint, and
recruiting is the term most likely to break it.** D13 (content volume) and D3 (off-screen model)
both inherit that pressure.

### 3.5 Sensitivity — the number the whole model rests on

Everything above depends on **1.2 s of compressed animation per snap** being watchable and
comprehensible. It is assumption **A3** and it has never been tested on a device.

| If a snap really needs… | College match | College week | College season + offseason |
|---|---|---|---|
| 1.2 s (design target) | 7.2 min | 17.2 min | 5.6 h ✓ |
| 2.0 s | 9.5 min | 19.5 min | 6.2 h ✓ |
| 3.0 s | 12.3 min | 22.3 min | 6.9 h ✓ (at the edge) |
| 6.0 s (the naive figure) | 22.5 min | 32.5 min | **9.3 h ✗ fails P4** |

The model degrades gracefully to ~3 s/snap and **breaks outright at 6 s**. So the design's real
requirement is not "build a 2D field" — it is **build a 2D field that reads at roughly 1 second per
snap**, which is a legibility problem (§6.5), not a rendering one. If the owner's play session finds
the floor is above 3 s, the fallback is stated in `OPEN-DECISIONS.md` D1: drop the default
presentation to **drive-summary** granularity, where the unit animated is the drive's decisive play
rather than every snap.

### 3.6 Week-level throughput

Against the §6.0a threshold of **≥5 meaningful decisions per week** (the prior build measured 1–3):

| Decision | Count | Meaningful because |
|---|---|---|
| Offensive identity vs this opponent | 1 | Trades expected yards against turnover risk |
| Defensive identity — what you take away | 1 | You cannot stop everything; choosing is the game |
| Practice focus | 1 | Development vs sharpness vs health, and it compounds over a season |
| Snap allocation at a contested spot | 1 | Veteran now vs rookie development |
| Availability calls on injured players | 0–2 | Play him hurt and risk the rest of the season |
| Inbox — recruiting contacts, trade feelers, staff | 1–3 | Real trade-offs with real costs |
| **In-match interventions** | **14–16** | 4th downs, timeouts, tempo, adjustments, aggression |

**Management decisions: 5–9. In-match: 14–16.** Clears the threshold with room, and — critically —
the decisions are spread across the week rather than stacked in the offseason.

### 3.7 What the player actually does during a match

| Layer | When | Examples |
|---|---|---|
| **Game plan** (set during the week) | Before kickoff | Run/pass lean, tempo, blitz rate, coverage shell, what to take away, 4th-down aggression, red-zone identity |
| **Drive-boundary adjustment** | Between possessions | Change the shell, dial pressure up, go tempo, switch a matchup |
| **Discrete high-leverage calls** | When they arise | 4th down, timeouts, clock management, two-point, challenge, kick or go, sit an injured starter |
| **In-drive adjustment** | When the opponent shifts | The AI tells you *what changed*; you decide whether to answer it |
| **Fidelity control** | Any time | Key moments / drive / snap-level, and a speed slider — FM Mobile's solved answer to this exact problem (§6.1) |

**You never choose the individual play.** The coordinator calls it, from your plan. When you dislike
what he is calling, you change the plan — that is the loop. This is the single decision that makes
130 snaps affordable, and it is the one most likely to be argued with; the falsifier is in
`OPEN-DECISIONS.md` D1.

---

## 4. The weekly loop

```
        ┌──────────────────────────────────────────────────────┐
        │  MONDAY   review · injuries · development · inbox     │
        │  TUESDAY  scout the opponent · build the game plan    │
        │  THURSDAY practice focus · availability · personnel   │
        │  SATURDAY / SUNDAY  the match                         │
        └──────────────────────────────────────────────────────┘
```

The days are a **presentation of grouping**, not four separate screens to march through — the whole
week is one hub, and a player who wants to advance fast presses one button. But the grouping is what
makes 5–9 decisions feel like a week rather than a form.

**Fast paths are first-class, not an afterthought** (§H: "speed options"):

| Path | Cost | For |
|---|---|---|
| Full | ~15 min | The default |
| Key moments only | ~4 min | Most weeks, most players |
| Instant result | ~10 s | Bye weeks, blowouts, the tenth season |
| Delegate the week | ~30 s | Coordinator sets the plan; you review |

Delegation is a **real** option that costs you something: a delegated plan is competent and generic,
and against a good opponent generic loses. That is the jeopardy that makes the fast path a choice
rather than a free win.

---

## 5. The college tier

~134 programmes. 12 regular-season games + conference championship + a 12-team playoff.

### 5.1 Roster and eligibility

| Rule | Value |
|---|---|
| Scholarship limit | 85 |
| Total roster | 105 including walk-ons |
| Eligibility | 4 seasons of play within 5 years |
| Redshirt | 1 per career; ≤4 games played preserves it |
| Class progression | FR → RS FR → SO → … → RS SR |

### 5.2 Recruiting

The system most likely to eat the week's budget, so it is designed around a **cap on attention, not
a cap on depth**.

- **Interest, not points.** Each recruit has a hidden interest score in your programme, moved by
  contact, campus visits, playing time promises, your record, scheme fit, distance from home, and
  NIL. The player sees a coarse band (Cold / Warm / Leaning / Committed), not a number.
- **A weekly budget of contacts**, not an unlimited list. Typically 5–8 actions/week, which is what
  keeps recruiting inside its 3-minute slice of the college week (§3.4).
- **A board of ~25 targets**, filtered and sorted; the AI manages the tail.
- **Signing day** is an event with an outcome you watch, not a form you submit.
- **The counter-design to FC:CD's complaint** (§6.2: "recruiting lacks real variation and can become
  boring"): recruits have *stories* — a legacy whose father played for your rival, a local kid you
  can lose by neglect, a five-star who will only come if you promise a starting job you may not be
  able to keep. Promises are tracked and broken promises cost you, which turns recruiting from an
  optimisation into a series of small bets.

### 5.3 The transfer portal

Two-way and load-bearing for jeopardy: win and you gain from it; lose or bury a good player on the
bench and he leaves. Portal windows open after the regular season and after spring. A player whose
promised playing time did not materialise enters the portal **at a much higher rate** — the direct
mechanical consequence of §5.2's promises.

### 5.4 NIL

A programme-level pool, not a salary cap: you allocate to positions and to individuals, it moves
recruiting interest and portal retention, and it is bounded by programme prestige and booster
support. It is deliberately *not* a second salary cap — the pro tier already has one, and doubling
it would make the two tiers feel identical.

---

## 6. The pro tier

32 teams, 2 conferences × 4 divisions × 4 teams. 17 games + 1 bye + playoffs.

Carried forward from the prior build's design, which was calibrated and soak-tested and is the most
reusable design knowledge in the repo (`archive/02-GAME-DESIGN-pro-only.md`, `STATUS.md`):

| System | Shape |
|---|---|
| Roster | 53 active + 16 practice squad |
| Salary cap | Hard cap, year-one $260M, growth 5–8%/yr |
| Contracts | Proration ≤5 years, guarantees, dead money, rookie scale |
| Practice squad | Stipend-funded, with a positional floor. **A squad place requires squad money; dead money follows the contract, not a flag; a call-up is paid for.** These three rules exist because their absence made the squad a cap-laundering machine in the prior build |
| Draft | 7 rounds, scouting fog, tradeable picks |
| Free agency | Open market plus in-season street free agency |
| Trades | Deadline at week 9 |

**Cap hell is real but bounded**: accelerated proration can leave a team briefly over the cap because
it cannot be cut away. The soak allows a small overage and fails on a large one.

---

## 7. The promotion arc (D5)

The v1 feature that nothing else in the market has.

### 7.1 What triggers an offer

A **reputation** score, accumulated from: wins above programme expectation, conference and national
titles, players developed and drafted, and the prestige of the programme you did it at. Pro teams
have their own coaching needs; when your reputation clears a team's bar and they have a vacancy,
an offer appears in the carousel.

Offers arrive first as **coordinator** roles at good teams and **head coach** roles at bad ones —
the real choice, and a genuinely hard one: coordinate for a contender, or rebuild a disaster with
your name on the door.

### 7.2 What carries across

| Carries | Does not carry |
|---|---|
| Reputation (converted, not reset) | Your roster, obviously |
| Scheme identity and its mastery level | Recruiting relationships |
| Staff who accept the move — and some will not | Programme facilities and boosters |
| Your record, trophies, and the players you developed — permanently, in the almanac | NIL pool |

**Players you developed appear in the pro league.** The three-star you turned into a first-round pick
shows up on someone's roster, and you can trade for him. This is the single highest-value payoff of
a unified save and it costs almost nothing to build, because the same player model spans both tiers.

### 7.3 Is the move one-way?

**No.** Getting fired in the pro league puts college jobs back in your carousel, at a prestige
matching your (now damaged) reputation. A one-way door would make the college tier a tutorial; a
two-way door makes it a place you can end up, which is a much better story and a much better
failure state (§8).

---

## 8. Difficulty, jeopardy and failure (D8)

**What losing looks like.** Job security is a visible band (Safe / Warm / Hot / Gone), moved by
results against expectation, not by raw record. Winning 8 games at a programme expected to win 4 is
a good year; winning 8 where 11 was expected is not.

**Getting fired.** End of season, with warning: the band moves through the year and the athletic
director or GM says so, in the inbox, before it happens.

**The non-negotiable, carried from the prior build**: *the carousel can never dead-end.* A coach
whose contract expires always has at least one offer or an explicit "year out of the game" path.
This exact situation soft-locks saves in the reference app and is its **rank-2 complaint class**
(§H). It is an invariant with a test (`03-MATCH-ENGINE.md` §9).

**Difficulty comes from AI quality, never from stat cheats.** This is D10 and it is also a direct
response to §6.2's rubber-band complaint about FC:CD — "anti-upset cheese", games that feel decided
against you. Higher difficulty means opponents scheme better, adjust faster and exploit your
tendencies harder. **It never means their players get better ratings than the ones shown.** A
difficulty setting that lies about ratings is the one thing that would break the trust the whole
design rests on.

---

## 9. Onboarding — the first fifteen minutes (D9)

By the end of them, the player has understood **four things**, and the sequence exists to teach
exactly those:

| Minute | What happens | What it teaches |
|---|---|---|
| 0–2 | Pick a programme from three, each with a one-line situation ("rebuild", "win now", "keep the seat warm") | Expectation is the thing you're judged against |
| 2–5 | Meet your roster through *three players*, not 85 — a star, a project, a problem | People, not spreadsheets |
| 5–9 | Build one game plan against a scouted opponent, with the trade-off stated in plain language | **The week is the game** |
| 9–14 | Play the match at default fidelity, with 3–4 interventions surfaced as they arise | You steer, you don't play |
| 14–15 | The result, and one consequence — a recruit's interest moves | Everything connects |

No tutorial modal wall. The first week *is* the tutorial, with a coach-assistant voice in the inbox
that stops appearing once the player stops needing it. Replayable from settings.

---

## 10. Staff

Head coach (you) + offensive coordinator + defensive coordinator + special teams + position coaches
+ (college) a recruiting coordinator.

Coordinators matter because of D1: **your coordinator calls the plays inside your plan.** A good OC
executes your intent; a bad one drifts from it under pressure. That gives the staff market real
stakes and makes "why did he call that" a mechanic rather than a bug.

Staff have: a scheme they know, a development specialty, a recruiting/scouting rating, and ambition —
good ones leave for head-coaching jobs, which is both a loss and a badge.

---

## 11. Fictional identity (D6)

Original IP is a **design opportunity**, not a compliance tax. College football's emotional payload
is rivalry, tradition and place, and it has to be manufactured.

- **Regional geography.** Programmes sit in a fictional map with real-feeling regional character —
  distance matters for recruiting, and neighbours become rivals naturally.
- **Archetypes, not one-offs.** Each programme is built from a small set of authored archetypes
  (state flagship, private academic, service academy, commuter school, small-town powerhouse) that
  determine prestige ceiling, recruiting reach, facilities, fan expectation and tone.
- **Rivalries seed and then accumulate.** Each starts from geography and conference; then the save
  writes its own history — the year you lost on a blocked kick becomes a line the game remembers
  and brings up. **This is the mechanic that makes season 8 better than season 1**, and it is cheap:
  it is a record of things that already happened.
- **Traditions have mechanical consequence.** A trophy game, a rivalry week that moves recruiting
  interest, a home-field tradition worth a real edge. A tradition with no mechanic is set dressing.
- **Conference politics.** Realignment happens; programmes get invited and dropped, and being the
  one left behind is a real, survivable disaster.

**Both legal tests apply to every generated name and colour pair** (see `CLAUDE.md`), and they run
in the generation phase's gate.

---

## 12. Content volume (D13)

The difference between a two-week and a two-month task, so it is budgeted here rather than
discovered later.

| Content | Authored | Generated | Authoring budget |
|---|---|---|---|
| Programme archetypes | 8 | — | 6 h |
| Programmes (~134) | ~24 anchor programmes with hand-written identity | ~110 from archetype × region | 20 h |
| Conferences | 10, authored | — | 4 h |
| Traditions | 20 authored, assigned by archetype | — | 8 h |
| Rivalry seeds | — | Generated from geography + conference | 2 h (rules) |
| Rivalry history | — | **Accumulated from actual play** | 0 |
| Name banks (first/last/city/mascot) | Curated lists + blocklist | Combined at runtime | 12 h |
| Pro teams (32) | All 32 authored | — | 10 h |
| News/story templates | ~120 | Filled at runtime | 14 h |
| **Total** | | | **~76 h** |

That is roughly **two solo working weeks of authoring**, spread across phases rather than paid up
front. The 24 anchor programmes carry the identity load; the other 110 exist to make the league feel
big and are allowed to be thinner.

---

## 13. Explicitly out of v1

Ordered by likely demand. Each is out because it costs week-budget or scope, not because it is bad.

1. **Any direct control of a player.** Permanently out — it is a Tier A constraint, not a backlog item.
2. Custom league / roster JSON import-export (architecture stays ready; §H rank 7 wants it)
3. Coordinator-only career start (§H rank 5)
4. Press conferences and a social feed (§H rank 10)
5. Online leaderboards, any networking
6. iPad and landscape
7. Commissioner / god mode editing
8. Multiple simultaneous saves beyond 3 slots

---

## 14. Numbers that live in code, not here

Everything in this document that is a constant belongs in `LeagueRules.swift` (pro) and
`CollegeRules.swift` (college): roster sizes, cap figures, week counts, playoff shapes, eligibility
clocks, recruiting contact budgets, portal windows. **A magic number at a call site is a defect.**
