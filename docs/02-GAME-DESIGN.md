# 02 — Game Design

The game itself. Canon for gameplay: if a gameplay question is not answered here, it gets answered
here **before** it gets implemented (the doc-first amendment rule in `CLAUDE.md`).

Inherits `docs/OPEN-DECISIONS.md` D1–D14 and the evidence in `docs/01-RESEARCH.md`. Where this
document states a number, the number is a design constant and belongs in a rules module, never
inline in code.

---

## 1. What the player is

A head coach with a career, starting in the college game and — if they earn it — moving to the pro
league on the same save, as the same person. Never a player. There is no direct control of players
during play.

The career is the unit of interest. A season is a chapter; the record book, the rivalries the save
accumulated, and the jobs taken and lost are the story.

---

## 2. The core loop

### 2.1 The week

The week is the heartbeat, and it is where the previous build failed: §6.0 established that its
management week contained **exactly one mandatory decision, and it was a decision about
presentation** — which of three ways to watch the game. Everything below exists to make the week a
place where a coach decides things.

A regular-season week, in order:

| # | Beat | What the player does | Mandatory? | Budget |
|---|---|---|---|---|
| 1 | **Inbox** | Read and answer what arrived: a stakeholder, a recruit, a player, a staffer, a reporter | Yes — at least one item requires an answer | 90 s |
| 2 | **Opponent** | Read the scouting report: tendencies, personnel, what they punish | No | 45 s |
| 3 | **Game plan** | Set offensive and defensive plan: tempo, aggression, a personnel emphasis, a coverage lean, and 2 keys the coordinator will honour | **Yes** | 120 s |
| 4 | **Practice** | Allocate the week's practice between install, conditioning, injury recovery and a position-group focus | **Yes** | 60 s |
| 5 | **Roster** | Depth chart, injuries, redshirt calls, discipline | No | 45 s |
| 6 | **Recruiting** (college) / **Front office** (pro) | Spend the week's contact/scouting budget | **Yes** | 90 s |
| 7 | **The match** | Game plan is live; call-ins arrive at the set rate | — | 630 s |
| 8 | **Aftermath** | Injuries, development flags, one stakeholder reaction | Occasionally | 30 s |

Roughly **6 minutes of management, 10.5 of match**, matching D1's budget. Four mandatory decisions a
week that a reasonable coach could get wrong, plus the inbox, plus ~25 in-match calls.

### 2.2 What makes a decision real

A decision qualifies for the week only if it passes three tests, applied at design time:

1. **Two defensible answers.** If one option is always right, it is a confirmation, not a decision.
2. **A visible consequence** within 3 weeks, attributable to the choice.
3. **A cost.** Choosing one thing must decline another — practice time, contact hours, cap space,
   scholarships, or the player's own attention.

Anything failing these is either cut or automated. This is the standing defence against the
prior build's failure mode, and it belongs in review checklists for every feature.

### 2.3 The season

- **College:** 12 regular-season games, conference championship, then the bracket. ~17 weeks.
- **Pro:** 17 games plus a bye, then the bracket. ~21 weeks.
- **Offseason:** the second half of the game, not an interlude (§4).

---

## 3. The match

### 3.1 The agency model (D1)

The player sets a game plan before the match. The coordinator AI calls plays inside that plan. The
player is pulled in on flagged situations — a **call-in**.

Call-ins fire on: fourth down; red zone; two-minute; third-and-long; the snap after a turnover; when
the opponent has shown a tendency the plan did not anticipate; and when the game plan leaves the
situation genuinely open. Default rate ~25 per game, tunable from ~12 to ~40 as a difficulty and
pacing setting.

A call-in presents **at most three options**, each with what it is trying to do and what it risks,
plus the coordinator's recommendation and the reason for it. The player picks or defers. Deferring is
a real choice — a coach who trusts their coordinator is playing correctly.

Between call-ins the match plays at drive granularity: the field animates, the drive summarises, the
player watches. They may **take over** at any time (raising the call-in rate for the rest of the
drive) or **hand off** (dropping it), which is the fast-forward affordance that lets a season fit.

### 3.2 What the player can change mid-match

Timeouts, challenges, tempo, aggression, personnel packages, and a halftime adjustment that is a
full game-plan edit. Substitutions are automatic within the depth chart, overridable per position.

### 3.3 Why this is not spectating

Per season: ~500 in-match calls, ~340 management decisions, plus the offseason. The previous build
offered roughly 20 in a season. The difference is not tone; it is two orders of magnitude.

---

## 4. The offseason

The offseason carries ~90 minutes of the season budget and is where the two tiers diverge most.

### 4.1 College

1. **Signing day** resolves the recruiting cycle that ran all season.
2. **The portal** opens: departures to manage, arrivals to chase. A retention decision on every
   player with a reason to leave.
3. **NIL budget** allocation across the roster — a scarce pot, distributed. Getting it wrong loses
   players to the portal.
4. **Spring development**: position changes, redshirt decisions resolving, a development focus.
5. **Staff**: coordinators poached, replacements hired, scheme continuity at stake.
6. **The carousel**: the player's own job resolves — extended, courted, or ended.

### 4.2 Pro

1. **Retirements and expiring contracts.**
2. **Cap compliance** — a hard date the player must be legal by.
3. **Free agency** in waves, with competing bidders and a market that reprices as it moves.
4. **The draft**, played pick by pick, with the board reflecting the scouting the player paid for.
5. **Staff and carousel**, as above.

**How this runs when nobody is watching — added 2026-08-12.** The order above is what the *player*
experiences; it says nothing about the thirty-one teams they do not control, or about the seasons
before promotion when no professional team is controlled at all. Without a rule the market simply
never advances: a soak measured two full seasons in which it opened, closed, and produced no draft
pick, signing, waiver or trade, because `beginDraft` and `draft` were reachable only through a
promoted coach's intent.

The rule is the one the college tier already uses — the headless policy drives every seat the player
does not hold, and stops at the one they do:

- The professional offseason advances **one phase per scheduled week**, driven by the roster policy
  that already runs weekly.
- **Free agency** signs while signings remain legal. When a pass makes no signing — the pool is dry
  or every roster is full — the draft begins.
- **The draft** is then made pick by pick in draft order by every AI team, deterministically: the
  best available prospect by rating, ties broken by prospect identity.
- It **pauses when the controlled professional team is on the clock**, because that pick is the
  player's decision and §4.2 sells it as one. Before promotion no professional team is controlled,
  so the draft runs to completion unattended, which is what makes the league the player is promoted
  into a league that has been living without them.

Falsifier: `--pro-soak` fails if a season passes with no `proDraftPick` event.

### 4.2a Roster turnover — what makes beats 1 and 2 real, added 2026-08-12

The driver above is necessary and was not sufficient, and both gates stayed red to say so: bootstrap
filled every professional roster to exactly 53/53 and issued **no contracts**, so nothing expired,
nobody reached free agency, and the draft's first pick hit `activeRosterFull`. Beats 1 and 2 were
prose with nothing behind them.

**Two pressures, and conflating them is what left this stuck.** Headcount and money are different
constraints with different mechanisms, and "what forces cuts to 53" is the wrong question for the
first one:

1. **Headcount is freed by expiry and retirement — beat 1.** This is the turnover engine. A roster
   drops below 53 because contracts ended, not because anyone was cut. It is what makes room for
   free agency and the draft, and it is why beat 1 comes first.
2. **Money is enforced by the cap-compliance date — beat 2.** Cuts happen when the cap binds. A
   team at 48 players and over the cap still cuts; a team at 53 and comfortably under does not.

**Bootstrap issues contracts, with a staggered term spread.** Every bootstrapped professional gets
a contract whose remaining years are drawn deterministically so that **roughly a quarter of each
roster reaches expiry each season**. Without this the league has no expiries until the first
contract signed in play runs out, which is several seasons of a dead market; with a flat term every
roster expires at once, which is a cliff rather than turnover. Salaries are rating-derived and the
bootstrapped total must be cap-legal at generation, in the same way team colours must pass contrast
at generation rather than being fixed up later.

**The draft can never deadlock.** Even with both pressures, a team can reach its pick full. A team
on the clock with a full active roster releases its lowest-value player whose money is not
guaranteed, and makes the pick. A draft that cannot make a pick is a bug, never a legal state.

**Falsifiers, instrumented in advance.**

- `--pro-soak` fails if a season passes with no contract reaching expiry, or if no player reaches
  free agency by way of one.
- `--pro-draft-probe` fails if any pick is refused for `activeRosterFull`. That error is now
  unreachable by construction, so its appearance falsifies the deadlock guard.
- The bootstrapped league is cap-legal for all 32 teams at season 1, asserted at generation.
- Expiry is deterministic: the same seed produces the same expiry schedule across processes.

### 4.2b The news feed — added 2026-08-12

The living world reports itself. `DomainEventPayload` already fixes the mechanism — "Presentation
text is derived by read-model builders, never persisted as the source of truth" — so a headline is
computed from a typed event and a save carries facts, never prose. Wording can then change without
migrating anybody's league.

What is newsworthy is **not a second editorial list**. It is `historicalWeight`, the same rank that
decides which bodies an archived season keeps: a season worth remembering is a season worth
reporting, and a payload scoring zero is weekly bookkeeping that never makes the feed. One
definition of important, used twice.

The feed reads the bounded hot journal **and** the archive's retained bodies, which is what keeps a
championship reportable long after it has left the hot window — the reason M7B keeps bodies at all.
It is bounded, because a feed is a screen and not a census, and ordered newest season first with the
heaviest story leading inside a season: recency alone buries a title under the transactions that
followed it, and weight alone freezes the same headline at the top forever.

Falsifier: a story that has left the hot journal must still reach the feed.

### 4.3 Recruiting, in detail (college)

Recruiting is the college tier's signature system and its throughput problem (D3/D4).

- A class is ~25 signings from a pool the player filters by position, region, rating and interest.
- The player spends a **weekly contact budget** — a scarce resource — on visits, calls and
  evaluations. Contact raises interest; evaluation reduces the fog on a recruit's true ratings.
- **Interest is relational and slow.** A recruit tracks interest in every programme pursuing them,
  moved by contact, programme prestige, playing-time projection, distance from home, scheme fit,
  NIL, and results on the field. Winning recruits; losing un-recruits.
- **Fog:** displayed ratings are an estimate with a visible confidence band that narrows with
  evaluation. The player's read of a recruit is never perfect, and this is the tier's main
  information-asymmetry surface.

**Throughput.** The player never touches more than ~40 recruits a season; the AI runs the other
~133 programmes' classes under D3's abstracted model. The week's recruiting beat is 90 seconds
because the interface is a shortlist with a budget, not a database.

---

## 5. Ratings, progression, development

- Ratings are **40–99 `Int`**. Position-specific attribute sets, plus physical and mental attributes
  shared across positions.
- **Potential** is hidden, estimated, and revealed gradually through practice and play. The estimate
  carries a confidence band, never a letter grade pretending to be certain.
- **Development** is driven by: age curve, practice allocation, playing time, coaching quality at the
  position, scheme fit, and a per-player development trait. It is not random; §6.0 found "progression
  too random" was a top community complaint about the reference title.
- **Decline** begins at position-specific ages and is visible before it is punishing.
- **Traits** are behavioural (durability, temperament, work ethic, clutch) and have mechanical bite
  in specific systems, never as flavour.

---

## 6. Staff and scheme

- Four coordinators and a set of position coaches, each with ratings for development, recruiting,
  game-planning and scheme affinity.
- **Scheme identity** is the spine: the player picks an offensive and defensive scheme, and the
  roster's fit to it modifies every matchup in the engine. Changing scheme is expensive and slow —
  it is the closest thing the game has to a strategic identity.
- Staff are poached by other programmes when they perform. Continuity is a resource.

---

## 7. Stakes (D8)

Pressure is continuous, legible, and comes from named people.

- The AD or general manager sets a **preseason expectation** the player can see. Job security moves
  **weekly** against expectation, not raw record. (The prior build recomputed it once a year, so it
  could not move for ~20 weeks.)
- Four stakeholder groups — the AD/GM, a booster or ownership bloc, the fanbase, the locker room —
  each with a visible disposition and their own triggers.
- **Everything arrives as an inbound event.** §6.0's second finding was that the previous build had
  **zero** of these: the game never initiated a conversation. Here, the inbox is the primary channel
  and always has something requiring an answer.
- Firing can happen in-season. The carousel can never dead-end: there is always at least one offer or
  an explicit year out of the game.

---

## 8. Identity, rivalry and place (D6)

Identity accumulates in the save rather than shipping with it.

- ~14 **programme archetypes** with priors over resources, fanbase volatility, academic constraint,
  recruiting reach and scheme inheritance.
- A generated **map** where distance drives recruiting reach, travel fatigue and rivalry candidacy.
- **Rivalries** seeded by geography and conference, then strengthened by what actually happens —
  close games, upsets, title-deciding meetings. Each carries its own record and narrative line.
- **Traditions** generated from a grammar, each with a mechanical effect: a home-field modifier on a
  given week, a regional recruiting bonus, a morale effect after a specific outcome.
- **Conference realignment** driven by performance, market and geography, so the map changes across a
  career.

**Programme evolution — added 2026-08-12.** Prestige was frozen at generation, so a programme that
won titles for a decade was exactly as prestigious as one that never won — while prestige drives
recruiting pull, AI valuations and which jobs a coach is offered. The final table maps to a *target*
prestige, first at the ceiling and last at the floor, and a programme's prestige steps **one point a
season** toward it.

A target with a step, not a delta, and the difference matters: win-gain/lose-drop has no restoring
force and walks a programme off the scale. This converges when a programme settles at a rank, reaches
the ceiling only by standing there, and lets twenty seasons move a programme twenty points — a
career-length change rather than a whiplash. A season that produced no table moves nobody.

Falsifier: held at a fixed rank, prestige must stop moving. An evolution that never settles is a
random walk wearing a rule's clothes.

All of it fictional and original, guarded by the name-collision and trade-dress tests.

---

## 9. The promotion arc (D5)

A pro job becomes reachable when coach reputation crosses a threshold that also depends on the pro
league's openings that year. Reputation comes from results against expectation, titles, development
record and recruiting record.

Carried across: reputation, scheme identity, a subset of staff, the record book, the career line.
Not carried: players, recruits, college currency.

One-way by default, with a demotion path if the pro job ends badly. Tuned so the move is earned in
4–12 college seasons at median play.

It is a retention device, not the headline — §6.3 found it shipped elsewhere and unrequested by any
community in the research. What sells the game is the first hour, which is a college hour.

---

## 10. Onboarding (D9)

Fifteen minutes, taught through the first real week rather than through cards. Full beat sheet in
`docs/OPEN-DECISIONS.md` D9. By the end the player has chosen a job with visible stakes, met a
stakeholder, set a plan, made ~25 calls, seen a consequence, and been given a reason to advance.

---

## 11. League structure and rules constants

`CLAUDE.md` puts league structure here rather than in itself, and the doc-first amendment rule says a
number gets written down before it is coded. **Added 2026-08-10 by P1**, which needed them and found
them unspecified. Everything below is a design constant and lives in a rules module.

These are rules *of the sport* and structural choices about this game's fictional leagues. No
conference, division, programme or team name appears here — those are generated (§8) and guarded by
the legal tests.

### 11.1 The college tier

| Constant | Value | Why |
|---|---|---|
| Programmes | 134 | D14, with the D3/D4 fallback to 64 if P5's ceiling cannot be met |
| Conferences | 10, of 12 to 16 programmes, summing to 134 | Enough for realignment (§8) to change the map without churning it |
| Regular season | 13 weeks: 12 games and 1 bye | §2.3 |
| Conference championships | week 14 | §2.3 |
| Bracket | 8 teams, 3 rounds, weeks 15 to 17 | §2.3's ~17 weeks, exactly |
| Season length | 17 weeks | The sum of the four rows above |
| Scholarships | 85 | The sport's limit. Soak-asserted per programme (`03` §6) |
| Initial signings per class | 25 | §4.3's "~25 signings" made exact |
| Roster limit | 105 | Scholarship players plus walk-ons |
| Eligibility | 4 seasons of competition within a 5-year clock | The redshirt year is the difference, and §4.1's redshirt decision is what spends it |
| Portal windows | two: after the bracket, and in spring | §4.1 |

### 11.2 The pro tier

| Constant | Value | Why |
|---|---|---|
| Teams | 32 | 2 conferences of 16, each 4 divisions of 4 |
| Regular season | 18 weeks: 17 games and 1 bye | §2.3 |
| Bracket | 8 teams, 4 per conference, 3 rounds, weeks 19 to 21 | §2.3's ~21 weeks, exactly. No first-round bye, so the bracket is a clean three rounds |
| Season length | 21 weeks | The sum of the two rows above |
| Active roster | 53 | Gameday active 48 |
| Practice squad | 16 | P8's cap-laundering defences apply here specifically |
| Salary cap | 255,000,000 integer dollars, growing 7 percent a year | Integer dollars, never floating point |
| Signing-bonus proration | over the contract's length, capped at 5 years | The mechanism dead money comes from |
| Contract length | 1 to 7 years | An upper bound so a corrupt save cannot ask for an unbounded allocation. A contract of zero years carries no signing bonus |
| Draft | 7 rounds of 32 picks, 224 total | |

### 11.2.1 Initial roster position templates

M1 populates the target world before lifecycle systems exist. These are initialization constants,
not permanent depth-chart rules; M2 movement may change the shape while positional-coverage
integrity keeps every roster playable.

| Position | College (105) | Pro active (53) |
|---|---:|---:|
| Quarterback | 4 | 3 |
| Running back | 7 | 4 |
| Wide receiver | 14 | 6 |
| Tight end | 6 | 3 |
| Left tackle | 6 | 2 |
| Guard | 12 | 5 |
| Center | 5 | 2 |
| Right tackle | 6 | 2 |
| Edge rusher | 9 | 4 |
| Defensive tackle | 9 | 4 |
| Linebacker | 11 | 5 |
| Cornerback | 9 | 6 |
| Safety | 5 | 5 |
| Kicker | 1 | 1 |
| Punter | 1 | 1 |

### 11.3 Shared

| Constant | Value | Why |
|---|---|---|
| Rating range | 40 to 99, `Int` | §5 |
| Potential range | 40 to 99, `Int`, hidden | §5 |
| Call-ins per game | 25 default, 12 to 40 tunable | §3.1 |
| Coordinators | 4 | §6 |
| Stakeholder groups | 4 | §7 |
| Programme archetypes | 14 | §8 |
| Rivalries carried per programme | 8, strongest first | §8's rivalry strength accumulates for a whole career, and `CLAUDE.md` requires every collection that grows across seasons to state a bound |

### 11.3.1 The calendar both tiers share

One save runs both leagues at once — the pro league exists and plays while the coach is still in
college, because §9's promotion needs somewhere to be promoted *to*. They therefore share one week
counter rather than each keeping their own.

| Constant | Value |
|---|---|
| In-season weeks | 21, the longer of the two tiers |
| College active | weeks 1 to 17 |
| Pro active | weeks 1 to 21 |

A deliberate simplification: real college and pro calendars overlap with an offset, and this one has
them start together. Nothing in §2 or §3 reads the offset, and one counter is what keeps a save's
calendar unambiguous.

### 11.3.2 Decline ages

`§5` says decline begins at position-specific ages and is visible before it is punishing. The ages:

| Age | Positions | Why |
|---|---|---|
| 27 | Running back | Carries the most contact per snap of any skill position |
| 29 | Cornerback, wide receiver, edge rusher | Live on top-end speed, which goes first |
| 30 | Safety, linebacker, defensive tackle, tight end | Speed matters but leverage and recognition carry more of the job |
| 31 | Every offensive line position | Technique and strength decline slowest of the contact positions |
| 34 | Quarterback | The job is decision and accuracy, and neither is a young attribute |
| 36 | Kicker, punter | Barely a contact position |

### 11.3.3 Traits

`§5` requires every trait to have mechanical bite in a specific system. Eight, each naming its
system, and a trait may not be added without one:

| Trait | System | Effect |
|---|---|---|
| Ironman | Injury | Recovers faster, misses fewer weeks |
| Workhorse | Development | Develops faster from practice allocation |
| Ice in veins | Match resolution | Performs above rating in the fourth quarter and the bracket |
| Front runner | Match resolution | Performs below rating on the road and in hostile venues |
| Mentor | Development | Raises development of younger players at the same position |
| Restless | Retention | Interest decays faster on a loss; enters the portal more readily |
| Adaptable | Scheme fit | Fits a new scheme faster after a change |
| Volatile | Discipline | Draws more penalties and more discipline events |

### 11.3.4 Schemes

`§6` makes scheme identity the spine, so the roster's fit to it modifies every matchup. Six each
side, and every one names the attributes a fit score reads — a scheme that emphasised nothing would
be a label, which §6 explicitly is not.

**Offensive:** pro style, air raid, spread option, west coast, power run, run and shoot.
**Defensive:** four-three, three-four, nickel base, bear front, two deep, press man.

The attribute sets each emphasises live in the rules module with the schemes.

### 11.3.5 The two legal tests, as numbers

`CLAUDE.md` states the guardrail and says both limbs are tests. Neither had a threshold anywhere.
**Added 2026-08-10 by P2**, which needed them.

| Constant | Value | Why |
|---|---|---|
| Colour space for the trade-dress test | CIE L\*a\*b\*, CIE76 ΔE | The cheapest perceptual distance that is not RGB. No dependency, and the choice is stated so it can be argued with |
| Trade-dress collision threshold | ΔE **25**, on *both* members of the pair | A pair collides only when primary *and* secondary are both close. One shared colour is not trade dress — half the sport wears navy |
| Orientation | Checked both ways round | Swapping primary and secondary does not make a pair original |
| Contrast floors for team colours | 4.5:1 for `team.onTeam` on `team.primary`; 3:1 for `team.secondary` on `team.primary` | `04` §2.1's table. Both checked *at generation time*, so a pair that cannot carry legible text is regenerated rather than shipped. Requiring one foreground to work on *both* members was tried first and is unsatisfiable — it rules out every dark-plus-light identity |
| Generation retry budget | 64 attempts per programme, then a deterministic fallback pair | A generator that can loop forever is a hang. The fallback is drawn from a pre-verified set and is itself covered by both tests |
| Leagues the legal tests sweep | 200 | Matches D6's falsifier sample, so one generation run serves both |

**What the blocklist covers, and what it cannot.** Institution names, nicknames and mascots,
conference names, stadium names, city names, and a maintained list of identifiable people. It is
refreshed per release (`docs/PRE-DEPLOYMENT-CHECKLIST.md`).

It is a *denylist*, not a definition of compliance. `01` §7 already records the gap and it is
restated here because P2 is where someone would otherwise assume the tests are the whole guardrail:
**a generated programme whose ratings, conference, geography and history are individually fictional
but jointly identify a real one is trade-dress adjacent, and no test in this package covers
statistical or biographical resemblance.** That is a review obligation on generation content, and an
owner-and-counsel question, not something a threshold settles.

### 11.4 What is deliberately not fixed here

Conference *composition* is generated per league, not listed — a fixed table would make every save's
map identical and defeat §8. The same goes for divisions inside the pro conferences. The rules module
carries the *shape* (10 conferences, sizes 12 to 16, summing to 134) and generation fills it.

---

## 12. What v1 does not include

Stated so scope creep has something to bounce off: no multiplayer, no online anything, no custom
universe import/export in v1 (escalated to counsel in `01-RESEARCH.md` §6.2B §3.2; optional person,
team and venue asset fields remain reserved for a future approved feature), no create-a-school
editor, no historical seasons, no iPad layout, no portrait. (Orientation flipped by the owner on
2026-08-10 — `04` §7.)
