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

### 3.4 The conversion — added 2026-08-13

A touchdown is six points and then a decision, and the decision is the point of adding it: the kick
is nearly free and worth one, the two-point try is a snap from the two and worth two. It passes all
three of §2.2's tests — two defensible answers, a consequence inside the same game, and a cost
measured in the point you did not simply take.

*Recorded because the engine scored a touchdown as seven points and never asked.* `extraPointPoints`
was added to `touchdownPoints` unconditionally, so the kick could not miss, the two-point try did not
exist, and one of the sport's few genuinely famous coaching decisions was absent.

- **The kick** is a field goal from the fifteen, resolved through the same kicker matchup as every
  other kick rather than through a special-cased probability. A kicker who cannot kick can miss one,
  which is what makes carrying a bad kicker a roster cost rather than a rounding error.
- **The two-point try** is one snap from the two, resolved by the same snap resolver. Reaching the
  goal line converts; everything else is nothing. A caller that answers a try with a punt or a field
  goal has its call replaced by a run, because the try is a scrimmage down by definition.
- **Neither consumes game clock.** The clock is stopped for the try and restarts at the kickoff,
  which under this engine's touchback model burns nothing. Charging a few seconds here would move
  plays-per-game, which is a calibrated band in `03` §5.1, for no gain in truth.
- **The try is not a scrimmage play.** It is recorded beside the drive, never inside its play list,
  because a box score that counted conversions as offensive snaps would corrupt every per-play rate
  the calibration harness measures.

**When to go for two is a rules-module chart, not a coordinator's taste**, because it is arithmetic
rather than judgement: with the touchdown already on the board, a deficit of 2, 5, 10, 12, 16 or 18
is one that two points changes the shape of. Outside the final quarter the kick is taken, which is
what real charts do — a two-point try in the first quarter buys a margin the remaining three
quarters will erase. `MatchupRules.twoPointIsIndicated` owns the chart, the coordinator reads it, and
the player overrides it through the same call-in surface as any other decision.

Falsifier: across a calibrated season both choices occur, the kick's success rate exceeds the two-
point try's, and no conversion appears in any drive's play list.

### 3.5 Penalties — added 2026-08-13

`03` §1.1 listed "penalty" among the consequences a snap can produce and nothing produced one. There
was no penalty type, constant or code path in the engine, and `§11.3.3`'s `volatile` trait named a
Discipline system that did not exist — a trait pointing at nothing, which is the dead capability this
project's build prompt names as its first failure mode.

**Seven kinds, each of which has to change a decision or a drive.** False start, delay of game and
offensive holding against the offence; offside, defensive holding, pass interference and a personal
foul against the defence. A kind whose enforcement is identical to another's is the same kind wearing
a different name, so there is no eighth.

- **The flag is drawn before the snap resolves, for every snap, whether or not it lands.** Drawn
  first, a penalty cannot shift the random stream the snap's own resolution reads; drawn
  unconditionally, its presence cannot change how many draws a snap consumes. Both are determinism
  properties, not style.
- **Pre-snap flags replace the play**; the others modify it. That is the whole difference between the
  two groups, and it is why they are distinguished at all.
- **The down is replayed, never advanced.** A defensive foul that carries an automatic first down
  resets the chains instead. Enforcement moves the ball and adjusts the distance; the yard line is
  clamped to the field rather than modelling half-the-distance, which is a simplification stated here
  rather than discovered later.
- **Accept or decline is resolved optimally for the side that holds the decision.** A defence keeps a
  takeaway over ten yards; an offence keeps a touchdown over fifteen. This is deliberately a
  simplification: a real coach can decline badly, and one day this is a call-in with the two options
  and their consequences on it. Modelling it as always-accept would be wrong in a specific and
  visible way — a defence would take ten yards instead of the sack it just earned.
- **A declined flag is still recorded**, with zero enforced yards, because a box score that hid them
  would lose the record of a play that nearly did not count.
- **A flag during the play does not call back a kick.** None of the seven kinds are kicking-game
  fouls, and enforcing a scrimmage foul on a field goal would produce a kick that scores and is
  simultaneously wiped out.

**`volatile` bites here, and it bites on the player rather than the team.** A volatile player is
three times likelier to be the one flagged, and a roster full of them draws flags somewhat more
often. Who committed the foul is recorded, because a trait a player carries should show up on that
player's line and not only in a team rate.

**The rate is not calibrated and is not pretending to be.** `03` §5.1 has no penalty band, because no
source for one has been retrieved; the harness now measures accepted penalties per game so a later
session can band it from evidence rather than from the engine that produced it.

Falsifier: every kind occurs across a season; a penalty never advances the down; accepted penalty
yardage never appears in a team's offensive yards; and a defence never accepts a flag that would give
back a turnover it just made.

### 3.6 Kickoffs, returns and the onside kick — added 2026-08-13

Every possession in this game began at a constant. The opening kick, halftime, and every kick after
a score all spotted the ball at the same yard line, so there was no return game, no field-position
variance, and no onside kick — which removes the trailing team's last mechanism and, with it, most
of what makes the final three minutes of a football game worth watching. The special-teams
coordinator on every staff had nothing to coordinate.

- **A deep kick is a touchback or a return.** Leg strength buys touchbacks, which is why a kicker's
  leg is rated apart from their accuracy: it is field position, bought before the ball is fielded.
- **A return is one matchup**, the returner's speed against the coverage unit's best tackler, and it
  can reach the end zone. A return touchdown scores six and takes the try through the same path
  every other touchdown does.
- **The kickoff after a return touchdown is a touchback by rule.** A chain of return touchdowns is an
  unbounded loop guarding a play that happens about once a season. The bound is stated here rather
  than discovered in a hang.
- **An onside kick is a flat chance, not a duel.** It is a scramble among ten players for a bouncing
  ball; naming two of them and resolving a matchup would be a false causal record, and `04` §5.3
  reads that record. Recovering one is the only way a kickoff does not change possession.
- **It is attempted only when it could matter**: the final quarter, trailing, inside three minutes of
  the half, and by a deficit an onside kick can still save. Outside that the kicking team kicks deep
  and trusts its defence, which is what real teams do and what keeps recovering one an event.
- **The kickoff is attached to the drive that received it**, not the one that scored, because it is
  what explains that drive's starting field position — and because the opening kickoff belongs to no
  scoring drive at all.

Falsifier: across a season, touchbacks, returns, at least one return touchdown and at least one
recovered onside kick all occur; a kickoff never leaves the ball with a team that did not legally get
it; and a game's drive points plus its kickoff points equal the scoreboard.

### 3.7 Overtime — added 2026-08-13

A played game ended at the end of regulation whatever the score, and recorded the tie.
`ClockRules.overtime` had declared `alternatingPossessions` for college and `timedPeriod` for pro
since the engine was built, and nothing read it — so the tier difference `01` §4.7 calls "a
structural rule difference, not a band" was a value with no consumer.

- **College plays alternating possessions.** Each side starts twenty-five yards from the goal line
  with one timeout, and the period ends when both have had the ball. There is no game clock, so the
  drive loop — which is clock-driven — is handed more seconds than a possession can consume rather
  than being taught a second way to end.
- **Pro plays a timed period.** Ten minutes, opened by a kickoff, drives as usual, and whoever leads
  when it expires wins. Still level at the end and the game is a tie, which is an honest outcome; an
  unbounded loop is not.
- **The toss comes from the game's seed**, so a replay tosses the same way.
- **Eight alternating periods is the bound.** `01` §6.5's college tie band is exactly zero, so if
  that bound is ever reached the model is wrong upstream and the band is what says so.

This closes three rows that `CalibrationBands.unimplementedMetrics` listed as waiting on overtime:
the overtime rate, the college tie rate, and the share settled in a single period. The first two now
carry bands transcribed from `01` §6.5 with its grades attached — the overtime rate is still an
owner-set assumption and says so.

Falsifier: no game ends level in the college tier; the pro overtime rate sits inside its band; and a
game that reaches overtime has at least one drive in a quarter past regulation.

### 3.8 Injuries in play — added 2026-08-13

Injuries were produced only by the weekly draw in `PeopleLifecycleSystem`, which runs at scheduler
step 2 — **before** the week's games at steps 10 and 11. A player's knee went in the middle of the
week, from accumulated workload, and nobody was ever hurt during a match. In a sport where an injury
changes the game being played, that is a missing mechanic and not a missing detail.

- **The candidates are the players the snap involved** — the matchups it recorded and whoever handled
  the ball — not all twenty-two. The engine already records who was in the collision, `04` §5.3 draws
  the play from that record, and an injury attributed to a player standing on the far hash would
  contradict the picture beside it.
- **Durability decides who**, the same way `volatile` decides who draws a flag. A rating that only
  moved a team-wide rate would never be visible on the player carrying it.
- **`ironman` decides how long**, which is the second half of the sentence `§11.3.3` writes for it.
  Recovery, the first half, stays where recovery is.
- **The severity ladder is shared with the weekly draw**, in the rules module. It was four literals
  inline in the lifecycle system; two hand-copied ladders that nothing asserts agree is worse than
  one constant.
- **The engine reports and never applies.** `SnapResolver` cannot reach league state and must not: a
  resolver that mutated it could not be replayed. The season layer applies these when the detailed
  match is integrated, in the same `PlayerInjury` vocabulary.
- **Anything past a knock forces the player out of the game.** Honouring that needs a depth chart,
  which does not exist yet; the flag is recorded now so the substitution work has something truthful
  to read rather than inventing its own.

Falsifier: across a season injuries occur in play, land on players who were in the snap that produced
them, fall more often on the least durable, and never appear on a snap that a pre-snap penalty
cancelled.

### 3.9 Timeouts and the clock — added 2026-08-13

`Situation.timeoutsRemaining` was written at the kickoff, reset at halftime, and **decremented
nowhere**. A timeout was a number on a scoreboard, while §3.2 sells it as one of the five things a
coach may change mid-match.

- **Both sides are asked after every snap that left the clock running, defence first.** The side that
  usually needs the clock stopped is the one without the ball; asking the offence first would let it
  spend the timeout the defence was about to.
- **Only a trailing side spends one**, and only inside its own window: a defence from two and a half
  minutes, an offence from under a minute. The defence's window is wider because it is buying
  possessions rather than seconds.
- **The rule is the coordinator's default, not a law.** It lives in the caller, so a coordinator
  personality can be worse than arithmetic and the player can override it — which is what makes it a
  decision rather than a simulation detail.
- **A spent timeout is visible in the situation**, so the determinism fingerprint already sees it and
  a match view can read the count without the engine keeping a second record of the same fact.

**Challenges are deliberately not built here, and §3.2's promise is outstanding rather than
withdrawn.** A challenge is a bet on a fact — was the ball out before the knee — and this engine does
not record facts at that resolution: it resolves a snap to an outcome and a set of duels, with no
notion of a spot that could have been wrong. Building one would mean inventing a truth beneath the
outcome so a review could contradict it, which is a modelling decision the owner should take rather
than one that arrives inside a clock-management change. Recorded as open work in `docs/STATUS.md`;
the alternative is to strike challenges from §3.2, which is also the owner's call.

Falsifier: timeouts are spent in real games, only by a trailing side, never below zero, and a half
that ends with a trailing team holding all three inside the last minute is a defect in the rule.

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
a contract whose remaining years are drawn deterministically so that **roughly a fifth of each
roster reaches expiry each season** — terms of one to five years, spread evenly.

*A fifth rather than a quarter, and the reason is a bound rather than a preference.* The free-agent
pool is capped at 512 entries (`ProMarketState.maximumFreeAgentIDs`, which `03b` requires so the
pool cannot grow across seasons). Thirty-two rosters of 53 is 1,696 professionals; a quarter of them
is 424 expiries in one offseason, which fits the bound only if every prior year's unsigned player
has already left it. A fifth is roughly 339, which leaves real headroom for carryover, and still
turns over about eleven players per roster per season. Without this the league has no expiries until the first
contract signed in play runs out, which is several seasons of a dead market; with a flat term every
roster expires at once, which is a cliff rather than turnover. Salaries are rating-derived and the
bootstrapped total must be cap-legal at generation, in the same way team colours must pass contrast
at generation rather than being fixed up later.

**Cuts are forced by the compliance date, and by nothing else — owner decision, 2026-08-12.** The
alternative on the table was letting incoming draft picks force a corresponding release, and it is
rejected: a pick is not a cut instrument, and a league where the draft quietly releases players
makes the draft the place roster decisions happen instead of the place talent arrives. Beat 2 owns
cutting. A team over the cap on the compliance date releases until it is legal; a team under it
cuts nobody, whatever its headcount.

**The AI-facing half is built — `ProManagementSystem.enforceCapCompliance`, added 2026-08-13.**
Every professional team except the one the player controls is released down to cap-legal at the
week-21 boundary, cheapest dead money first, entirely within the same `advanceWeek` transition that
already runs beat 1's expiry — so no *persisted* root is ever over the cap, the same guarantee
`docs/PORT-LOG.md`'s cap-laundering defences already protect. `WorldIntegrity.checkProfessionalCap`
is untouched: it stays exactly as strict as it has always been, checking the final state only. It
sits immediately after expiry and before anything downstream takes the season-projected view of the
root — the college portal's postseason commit does, later in the same step — because the same D-1
lesson applies here that applied to expiry itself: a hand-built fixture that put one team over the
cap and skipped this step surfaced as `portalCommitFailed(.postseason)`, not as a cap error, until
compliance was wired at the right point.

**The controlled team's own cap choice is deliberately not built here.** Every other consequential
choice in this game — a redshirt, a portal decision, an NIL allocation, a recruiting action — is the
player's to make through a mandatory decision, never automated out from under them. Forcing releases
on the player's own roster the same way the AI's are forced would break that pattern, so this pass
skips the controlled team entirely: if it is ever over cap, the week does not advance until the
player resolves it themselves, the same behaviour as before this change. A mandatory-decision surface
for that case is real remaining work, not built here, and needs its own design pass before it is.

Under today's generation this mechanism has no reachable trigger: every signing path already refuses
anything that would exceed the cap, and every contract this project generates is flat-salaried
against a cap that only grows, so no current game state can produce an over-cap team at all — proven
by `--pro-market-root-probe` finding zero, and unchanged by this addition. What legitimate mechanic
would ever put a team over the cap remains an open question this document does not answer.

**The draft can never deadlock, and that is an assertion rather than a mechanism.** Expiry frees
headcount before the draft opens, so a team arriving at its pick with no room is a bug in beat 1,
not a case for the draft to work around. `--pro-draft-probe` is the instrument: it fails if any
pick is refused for `activeRosterFull`. *An earlier draft of this section had the pick itself
release the lowest-value non-guaranteed player. That was written before the owner's decision above
and was never implemented; it is recorded here as rejected so it is not reintroduced as an
obvious-looking fix.*

**The last body at a position is re-signed, not held on a dead deal — added 2026-08-13.** A 53-man
roster carries exactly one kicker and one punter, so expiring every run-out contract can leave a
club with nobody who can play the position. The club keeps that player. What it does *not* do is
keep the expired contract: a deal whose term has run out is over, and leaving it attached to the
player is a lie about the books that the cap invariant correctly refuses — a contract is valid only
while the season is inside its term. The club **re-signs** the player instead, one year at their
last base salary and no signing bonus, so the deal carries no dead money if the club moves on the
following year.

*Recorded because the first version held the expired deal and cost two defects.* Eleven of thirty-two
teams became permanently illegal the moment the root was projected into the next season, and since
the college portal's commit is what takes that projection, a professional contract rule surfaced as
`portalCommitFailed(.postseason)` — the defect register's D-1, whose attribution was open. No team
was ever over the cap. Both are fixed by expiry running at the right point in the week and by this
rule.

**Falsifiers, instrumented in advance.**

- `--pro-soak` fails if a season passes with no contract reaching expiry, or if no player reaches
  free agency by way of one.
- No professional contract survives its own term: at every season boundary, every contract attached
  to a rostered player has a term that still contains the season about to start.
- `--pro-draft-probe` fails if any pick is refused for `activeRosterFull`. That error is now
  unreachable by construction, so its appearance falsifies the deadlock guard.
- The bootstrapped league is cap-legal for all 32 teams at season 1, asserted at generation.
- Expiry is deterministic: the same seed produces the same expiry schedule across processes.

### 4.1a Jersey numbers — added 2026-08-13

A number is a **roster-scoped derivation, not a stored field**, and the reason is where uniqueness
lives. Numbers are unique within a team and meaningless outside one, so storing one on the player
would put a team's invariant on an object that changes teams — every transfer, draft pick, signing
and walk-on would have to reassign and resolve collisions, and any path that forgot would produce
two of the same number with nothing to catch it. Derived per roster, uniqueness holds by
construction and there is no path to forget.

The rule, in order:

1. Each player has a **preferred number**, drawn from their identifier bytes into the band their
   position wears. Identifier bytes, never a salted hash — the same clause `03` §3 states for seeds,
   for the same reason: a per-launch hash gives the same player a different number each launch.
2. **Uniqueness is per unit, not per roster**, because what a number has to distinguish is two
   players who could be on the field together. This is also the only rule that can be satisfied: a
   college roster is 105 players and there are 100 legal numbers, so a roster-wide constraint is not
   merely stricter than the real one, it is unsatisfiable. Offence, defence and special teams each
   number independently.
3. Within a unit, ties are settled by identifier, lowest first. The winner keeps the preferred
   number; the loser takes the next free number in its band, wrapping.
4. A band that fills spills into the general range, so a unit can always be numbered.

**The ceiling, stated rather than discovered:** a player's number can change when a *teammate*
leaves, because the collision order shifts. Real squads renumber rarely and deliberately. If that
becomes visible — a number moving in a screenshot a player took last week — the fix is to persist
the assignment per roster, and that is a schema change with a migration, not a tweak.

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

**The weekly contact budget is built — `ProgrammeRecruitingState.contactPointsRemaining`, reset to
`CollegeRules.weeklyRecruitingContactPoints` (100) every week by `WorldScheduler`.** `contact` and
`evaluate` spend it directly; `scheduleVisit` draws `CollegeRules.visitContactCost` (30) from the
same pool rather than a separate visits counter, so `RecruitingBoardReadModel.Capacity`'s "hours"
field reads the pool and its "visits" field is the pool divided by the visit cost — a real derived
count, not an invented one. Confirmed live in the shipped app: `HOURS 100h` and `VISITS 3` at week
one on the bootstrapped default seed, moving when a `contact` action is committed.

*Recorded because the first pass through this section got it wrong.* A search for "budget" and
"weekly hours" missed the resource under its actual name, and G-01's Recruiting Board provider
briefly shipped `Capacity.weeklyHoursRemaining`/`officialVisitsRemaining` as `Int?` under a "G-18:
not built" note — asserting a gap that did not exist. The wrong finding had already reached
`docs/STATUS.md`, `docs/OWNER-WALKTHROUGH.md` and the plan's own gap register before a closer read
of `CollegeState.swift` caught it; all three carry a same-day correction rather than a silent edit,
since a mistake that already shipped a claim is not the same as one caught before it did.

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

**How realignment moves the map — added 2026-08-12.** It is a **swap**, not a migration. Each season
at most `CollegeRules.realignmentSwapsPerSeason` pairs of programmes exchange conferences.

*A swap rather than a move, and the reason is structural rather than stylistic.* A conference holds
12 to 16 programmes summing to 134 (§11.1), and schedule generation, standings, tiebreaks and
whole-root topology integrity all read that shape. A one-way move makes one conference 11 and
another 17, so every one of those has to cope with a size that the rules forbid. A swap leaves every
conference exactly the size it was, so the map changes while nothing downstream can observe a size
it was not built for.

The pair chosen is the one that most improves **geographic fit**: each programme is scored by the
distance from its city to the centroid of its conference's cities, and a swap is taken only when it
lowers the total. Performance and market enter through prestige, which already follows the table
(§8) and already moves a programme's standing in the sport. Ties break on programme identity, so the
same world realigns the same way on every run.

Falsifier: after a swap, every conference still holds a legal number of programmes, and every
programme still belongs to exactly one.

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
