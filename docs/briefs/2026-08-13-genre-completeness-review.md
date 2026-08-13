# Genre completeness review — what most games in this genre have and this one does not

**Destination:** `docs/briefs/2026-08-13-genre-completeness-review.md`. **Working input, not canon.**
Nothing in canon was edited. Where an entry proposes a canon change, it says which document owns it.

**The question this answers is narrower than the gap register's.**
`docs/briefs/2026-08-12-gap-register.md` asks *what does this build's own design need that it does
not have*. This asks *what does a player arriving from any comparable game expect to find, and is it
here* — the football-management and career-mode staples, plus the things every shipped iPhone game
carries. The two lists overlap by design; where an item is already registered, the entry says so and
does not claim to have found it.

**Grounding rule, inherited from the gap register.** Every `Today` names a path in the tree as it
exists at `fe16860`, or says `nothing`. `docs/STATUS.md` and the plans were treated as testimony and
checked against the tree; disagreements are recorded in §5.

**Method and its limit.** This session had **no Swift toolchain** (`swift: command not found`), so
nothing was compiled, no test was run, and no measurement here is new. Every claim is a source read
and can be checked by opening the named file. Where a claim is about absence, it is an absence
across `Sources/`, `Tests/`, `App/` and `docs/` together, not a failure to find one name — the
`G-18` false gap of 2026-08-13 is the standing warning.

**Numbering.** `docs/plans/2026-08-12-road-to-beta.md` §8 states the next gap number to issue is
G-18. These continue from there. If a concurrent session issued G-18 first, renumber this file, not
that one.

---

## 1. The three that matter most

Ordered ahead of the register because they are not features at the margin — they are the parts of
the game the design documents lead with, and each has **no runtime path at all**.

**1. You cannot play a match.** `GameEngine.play` has exactly one caller in the whole tree:
`Sources/FootballSimCore/Calibration/CalibrationHarness.swift:57`. The scheduler's `userGame` step is
declared (`Sources/FootballSimCore/Scheduling/WorldScheduler.swift:11`) and falls through to
`default → .inactive` at `:634`, so every game in a career — including the coach's own — is resolved
by `Abstracted/AbstractGameSimulator.swift`, whose team strength is average rating adjusted for
fatigue, blended four-to-one with prestige. `docs/STATUS.md` records the detailed engine as not
integrated; what is not recorded is that this makes the 630 seconds of `02` §2.1's week — 64 % of the
weekly budget — unreachable. It is absent from `docs/plans/2026-08-12-road-to-beta.md`'s consolidated
list.

**2. Nobody ever asks you anything.** `02` §7 makes the inbox the primary channel and names §6.0's
diagnosis of the prior build — "**zero** inbound events; the game never initiated a conversation" —
as the thing being fixed. Today: `WorldScheduler.expiringInboundEvents` is inactive, and
`Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:69` says so in a comment. The only thing
that asks the player for anything is `Career/MandatoryDecision.swift`, whose four subjects are
recruiting, portal retention, redshirt and NIL allocation — all college, all roster paperwork. No
stakeholder, player, staffer or reporter initiates anything, so D8's continuous pressure has no
delivery mechanism.

**3. The match's decision layer is built, tested, and connected to nothing.**
`Tactical/TacticalCallIn.swift`'s `TacticalCallInSystem.proposal` returns exactly what `02` §3.1
specifies — at most three options, each with rationale and risk, plus the coordinator's
recommendation. It is unit-tested at `Tests/SimTests/Suites/TacticalManagementTests.swift:98`. It has
**no production caller**, there is no match session to pause, and no `CoachIntent` case answers one.
`02` §3.3 sells ~500 in-match calls a season against the prior build's ~20; the current count is
zero.

These three are one finding wearing three hats: **the week that `02` §2 describes is not the week the
engine runs.** Four of its eight beats — inbox, opponent report, the match, aftermath — have no
runtime.

---

## 2. The register

Same eight-field shape as `docs/briefs/2026-08-12-gap-register.md` where it earns it; compressed to a
table where the entry is small. `Registered` names any canon or plan document that already carries
the item, so nothing here is claimed as a discovery when it is not.

### 2A. The loop

| Field | G-18 |
|---|---|
| Requirement | A played match: the coach's game resolved by the detailed engine, watchable, with the call-in loop live |
| Today | `GameEngine.play` called only from `Calibration/CalibrationHarness.swift:57`; `WorldScheduler`'s `userGame` step inactive (`:634`); career games resolve in `Abstracted/AbstractGameSimulator.swift` |
| Delta | A match session on the `CareerSession` boundary that runs the detailed engine for the controlled team's fixture, surfaces call-ins, accepts answers, and writes the same `GameRecord` the abstract path writes |
| Owner doc | `03` for the session contract; `03b` for where it sits relative to the actor |
| Registered | Partially — `docs/STATUS.md` says the detailed match "remains the preserved P3 engine rather than being integrated". Not on the road-to-beta list |
| Blocks | G-19, G-06 anchors, G-11 stat lines, Match Day (screen 14), D1's entire time budget |

| Field | G-19 |
|---|---|
| Requirement | Call-ins delivered to the player and answered — D1's agency model |
| Today | `Tactical/TacticalCallIn.swift` builds proposals and is tested; zero production callers; no `CoachIntent` case; `Engine/DriveEngine.swift:208` computes triggers inside the engine only calibration runs |
| Delta | The intent case and the session state that pauses a match at a flagged snap, plus take-over and hand-off (`02` §3.1) |
| Owner doc | `03`, `03b` |
| Registered | `nothing` |
| Blocks | The answer to "what does the player do instead of pressing buttons" |

| Field | G-20 |
|---|---|
| Requirement | Inbound events and an inbox — beat 1 of every week, and D8's delivery mechanism |
| Today | `nothing`. `WorldScheduler.expiringInboundEvents` inactive; `CoachWorldReadModelProvider.swift:69` records the absence; `MandatoryDecision` covers four college roster subjects and no correspondence |
| Delta | A typed inbound-event model with senders (`02` §7's four stakeholder groups plus recruits, players, staff, press), an expiry rule the scheduler step already reserves, and at least one answer-requiring item per week |
| Owner doc | `02` §7 states the requirement; `03b` owns the model and bound |
| Registered | `docs/STATUS.md:282` names it open. Not on the road-to-beta list, not in the gap register |
| Blocks | Inbox (screen 9), Stakeholders (54), Job Security (53), the week's first 90 seconds |

| Field | G-21 |
|---|---|
| Requirement | The in-match controls `02` §3.2 promises: timeouts, challenges, tempo, packages, halftime adjustment, substitution override |
| Today | `Engine/Situation.swift:30` holds `timeoutsRemaining`; it is written at kickoff and reset at halftime (`GameEngine.swift:118`, `:155`) and **decremented nowhere**. No challenge type exists anywhere. Depth-chart substitution is unbuilt (FSC-008) |
| Delta | Clock-management consumption of timeouts inside the engine and as a player action; a challenge model, or a canon amendment removing the promise |
| Owner doc | `02` §3.2, `03` |
| Registered | Depth charts yes (FSC-008); timeouts and challenges `nothing` |
| Blocks | Two-minute play, which `02` §3.1 lists as a call-in trigger |

### 2B. Football the model does not contain

Each row is table stakes in every competitor named in `01-RESEARCH.md` §6.

| ID | Missing | Today | Registered |
|---|---|---|---|
| G-22 | **Penalties** | `03` §1 lists "penalty" as a consequence and `02` §11.3.3 gives `Volatile` the Discipline system; there is no penalty type, constant, event or code path. `SnapOutcome` has eleven cases, none a flag. `03` §5.1's band list has no penalty rate | Trait activation only (FSC-014). The mechanic itself: `nothing` |
| G-23 | **Special teams beyond the kick/punt binary** | Kickoffs resolve as a constant (`MatchupRules.kickoffTouchbackYardLine`, `GameEngine.swift:114`, `:158`); `OffensivePlayType` is run/pass/punt/fieldGoal/kneel. No returns, no onside kick, no blocks, no fakes. No returner in `02` §11.2.1's fifteen positions. `Staff.swift:8` employs a special-teams coordinator with nothing to coordinate | `nothing` |
| G-24 | **PAT and the two-point conversion** | A touchdown adds `MatchupRules.touchdownPoints + extraPointPoints` unconditionally (`DriveEngine.swift:238`). The kick cannot miss and the two-point option does not exist | `nothing` |
| G-25 | **Overtime in a played match** | `GameEngine` stops at the end of regulation and records the tie (`:145`–`:165`); `ClockRules.overtime` formats exist but only `AbstractGameSimulator.swift:48` resolves one, as a 0.72/0.52 pair of coin flips | Named as P6's in a code comment; no plan row |
| G-26 | **Injuries during a game** | `injuriesAndRecovery` is scheduler step 2, before the games at steps 10–11 (`WorldScheduler.swift:5`), so injury is a weekly roll on accumulated workload. No player is ever hurt in a match, and no substitution follows | `nothing` |
| G-27 | **Weather and conditions** | One mention, as an input to the kick row of `03` §1.2. No state, no generation, no effect | `nothing` |

### 2C. What a career remembers

| Field | G-28 |
|---|---|
| Requirement | A statistical record that covers the whole roster |
| Today | `Competition/Statistics.swift`: `PlayerGameStatistics` is passing yards, rushing yards, receiving yards, touchdowns. `TeamGameStatistics` is points, yards, pass, rush, turnovers. There are **no defensive statistics of any kind**, no kicking or return production, and no attempts, completions, receptions or carries — so no rate statistic can be computed at all |
| Delta | A stat vocabulary covering both sides of the ball and the specialists, in the abstract model first (it is what generates the whole world's history), then the detailed engine under G-11 |
| Owner doc | `03` owns what the models produce; `02` §5 owns what a career is judged on |
| Registered | G-11 registers *detailed-engine* per-player lines. The vocabulary itself being offence-only is `nothing` |
| Blocks | Statistics & Leaders (48), Game Detail / Box Score (47), Awards (49), Record Book (57), any valuation of a defender, half of G-02's verdicts and all of G-04's form |

| Field | G-29 |
|---|---|
| Requirement | Honours a long save accumulates |
| Today | `SeasonAwardKind` has three cases: `champion`, `topOffense`, `playerOfTheYear` (`Competition/RecordsAndAwards.swift:3`). No all-conference or all-region team, no positional awards, no weekly honours, no coach of the year, no hall of fame |
| Delta | An award set per tier in the rules module, computed from G-28's statistics; hall of fame is separable and larger |
| Owner doc | `02` (which honours exist), rules module (the constants) |
| Registered | Hall of Fame yes, as deferred (`docs/roadmap/07-FUTURE-SIMULATION-CONTRACT.md`). The rest `nothing` |
| Blocks | Awards & Honours (49); the reason to keep a good player rather than a good roster |

### 2D. Management staples

| ID | Missing | Today | Registered |
|---|---|---|---|
| G-30 | **Depth chart — who actually plays** | No depth-chart type anywhere; the abstract model uses whole-unit averages (`AbstractGameSimulator.swift:128`), so a starter and a fifth-stringer contribute equally | Yes — FSC-008, and screen 17 exists |
| G-31 | **Staff as a managed resource** | `CoachIntent` has seven cases and none concerns staff, so the player can neither hire nor fire anyone; vacancies resolve deterministically inside `jobAndStaffMarkets`. Staff carry no salary or contract (`Model/Staff.swift` has no money field), so "poached" has no currency. Staff ratings are set at generation (`StaffPopulationGenerator.swift:47`, `:96`) and are never changed by any system — including the player's own head-coach record, which is a `Staff` with `role == .headCoach` (`WorldIntegrity.swift:1737`). A twenty-season career ends with exactly the coach it started with | `02` §6 and §4.1 promise it; screens 20–21 exist; no plan row |
| G-32 | **Scheme fit and traditions having mechanical bite** | `SnapResolver.swift:75` and `:101` pass `schemeFit: 0` literally; `AbstractGameSimulator.profile` carries the scheme into `TeamProfile` and the strength function never reads it. No consumer anywhere reads a `TraditionEffect` — `TraditionGrammar` generates home-field, recruiting and morale effects that nothing applies | `02` §6 calls scheme identity "the spine"; §8 requires every tradition to have a mechanical effect. Neither is registered as unbuilt |
| G-33 | **Draft picks as assets, and real trades** | `ProMarketState.draftOrder` is `[UUID]` of teams; there is no pick entity and no future picks. `ProMarketSystem.trade` is a strict one-player-for-one-player swap. No trade deadline, no pick trading, no multi-asset deal, no undrafted free agents after the 224 picks | `nothing` — "draft pick trade" returns zero hits across all of `docs/` |
| G-34 | **Contract negotiation** | `acquire`/`signFreeAgent` take a fully-formed `Contract`; there is no asking price, no competing-bid resolution, no extension, restructure, tag, holdout or agent. `02` §4.2 sells "free agency in waves, with competing bidders and a market that reprices as it moves" | Deferred forms registered in `docs/roadmap/07` ("Advanced pro negotiation", "Agent system"); the canon promise is not marked unbuilt. Screen 35 exists |
| G-35 | **Player morale** | `People/PeopleState.swift` carries health, development and career; no morale, happiness or satisfaction field. `CareerStakeholder.lockerRoom` is one team-level integer. College dissatisfaction is modelled only as portal intent; a professional is never unhappy about anything | `nothing` |
| G-36 | **Discipline and off-field events** | `02` §2.1 beat 5 lists discipline as a weekly roster action and `Volatile`'s named system is Discipline; no incident, suspension or discipline state exists | FSC-014 names the trait dependency; the system `nothing` |
| G-37 | **Money beyond the cap and NIL** | No revenue, operating budget, facilities, booster funds, staff wages or stadium economics anywhere in `Sources/`. The pro cap and the college NIL pot are the only money in the game | `nothing` |

### 2E. The shape of a season

| ID | Missing | Today | Registered |
|---|---|---|---|
| G-38 | **A postseason tail** | `02` §11.1 gives college ten conference championships and an eight-team bracket. For **126 of 134 programmes the season simply stops.** `01-RESEARCH.md:4204` reaches the opposite conclusion explicitly — "Bowl games as a wide tail of small prizes / Most seasons end in a minor reward rather than nothing / **Yes.** → D8: the tail is what keeps the other 129 playing" — and D8 as written contains no tail | Adopted in research, dropped in canon. Not registered as a gap |
| G-39 | **Preseason or camp** | The shared calendar is 21 in-season weeks (`02` §11.3.1). "Preseason" appears once in canon, as the AD's expectation. No camp, no position battles, no exhibition | `nothing` |

### 2F. The things every shipped game has

| ID | Missing | Today | Registered |
|---|---|---|---|
| G-40 | **Audio — all of it** | Zero occurrences of any audio API or asset in `Sources/`, `App/` or the repo. Canon mentions sound twice, both times as an accessibility *fallback*: `04` §7 "Sound and haptics have visual and spoken equivalents" and `04b`:141 scores "sound-off and haptic equivalents". The rubric scores the fallback for a thing that does not exist. `docs/PRE-DEPLOYMENT-CHECKLIST.md` has no audio row | `nothing` |
| G-41 | **Haptics** | Same two mentions, same absence | `nothing` |
| G-42 | **Difficulty** | The entire difficulty model is one sentence — `02` §3.1's call-in rate "tunable from ~12 to ~40 as a difficulty and pacing setting" — and it is not implemented as a setting anywhere. `SharedRules.callInsPerGameRange` exists and nothing reads it as a preference. Screen 6 promises "device, match and accessibility choices" and the match choices are unspecified | `nothing` beyond that sentence |
| G-43 | **Advancing more than one week** | `CoachIntent.advanceWeek` is the only advance. No sim-to-date, no continue-until-something-happens, no offseason fast-forward. At the measured 2.83 s/week (B-4) an offseason is a sequence of taps with a wait behind each | `nothing` |
| G-44 | **In-game help or glossary** | `nothing`. `docs/briefs/2026-08-12-density-model.md` T4 records that the reference product itself needed an in-game glossary and calls that "the failure bound made visible"; 62 dense families ship with nowhere to look up a glyph. Onboarding (D9/P15) teaches the first week, not the vocabulary in season nine |
| G-45 | **Shipping assets and store metadata** | `App/` contains two files: `ProFootballCoachApp.swift` and `project.yml`. No asset catalog, **no app icon**, no launch-screen asset (`INFOPLIST_KEY_UILaunchScreen_Generation: YES` generates one), no localization catalog, and **no `PrivacyInfo.xcprivacy`** — which Apple requires for App Store submission and which must declare required-reason API use; `CoachWorldSaveStore` touches file-timestamp APIs that are on that list. `PRE-DEPLOYMENT-CHECKLIST.md` §5 has rows for version numbers and backup/restore and none for icon, screenshots, privacy manifest or age rating | B-2 covers signing and TestFlight only |

---

## 3. Checked, and present — do not re-raise these

Recorded because the cost of the 2026-08-13 false gap was a wrong claim reaching three documents.
Each of these looked like a likely gap and is not one.

- **Waivers, trades, practice squad, contract expiry** — all live in `Pro/ProMarketSystem.swift`
  (`placeOnWaivers`, `claimWaiver`, `resolveExpiredWaivers`, `moveToPracticeSquad`,
  `promoteFromPracticeSquad`, `trade`). The gap is what a trade may contain (G-33), not that trading
  exists.
- **Delegation of responsibilities** — `Career/CareerControlState.swift` gives each of the four
  college responsibilities an owner that is `.user` or `.delegated(staffID:)`. FM-style
  responsibilities are built for college. The pro equivalents (draft, free agency, cap) have no
  responsibility set, which is a smaller gap than it first appears and is folded into G-31.
- **Weekly recruiting budget** — `ProgrammeRecruitingState.contactPointsRemaining`, reset by
  `WorldScheduler`. This is the resource the earlier false gap missed.
- **Redshirts, eligibility clocks, the portal in two windows, NIL as one conserved ledger,
  scholarship conservation** — all in `College/`, all tested.
- **Rivalries that strengthen from results, coaching trees, a news feed, programme prestige
  evolution, conference realignment** — M7A–M7D, all in `History/` and `Competition/`.
- **Jersey numbers** — `Model/JerseyNumbers.swift`, derived per unit rather than stored.
- **Injuries, fatigue, development with named causes, retirement, graduation** — M2, in `People/`.
- **Save compression and one backup generation** — `03b` §4; 306.9 MB to 36.0 MB at season 30.
- **Coach attributes** — the player's coach is a real `Staff` record with the four `CoachAttribute`
  ratings. What is missing is that they never change (G-31), not that they do not exist.

---

## 4. Deliberate exclusions, confirmed rather than proposed

These are genre-common and **out of scope by owner decision**; they appear here so the register is
not read as recommending them. `02` §12: no multiplayer, no online anything, no universe
import/export, no create-a-school editor, no historical seasons, no iPad, no portrait. `CLAUDE.md`:
one save and one coach, so no slot management. `PRODUCT.md` and the checklist: no analytics, no
network, no accounts, no IAP.

Two consequences worth stating rather than assuming:

1. **Achievements and any long-term goal tracking** are absent. Game Center needs an account, which
   is refused, but an offline achievement set is not refused by anything — it is simply unconsidered.
   The Record Book (57) is the nearest thing in the inventory. Low priority; listed for completeness.
2. **No cloud save or user-facing export** follows from the same policy. On a phone, a twenty-season
   career then lives in exactly one place. `docs/roadmap/07` registers cloud saves as a product-policy
   change. Worth an owner decision before beta rather than after the first lost save.

---

## 5. Tree-versus-document discrepancies found while grounding

Reported, not fixed.

1. `02` §6 states scheme fit "modifies every matchup in the engine". `SnapResolver.swift:75` and
   `:101` pass `schemeFit: 0`, and the abstract model never reads scheme at all. The claim is
   currently false in both models (G-32).
2. `02` §8 requires every generated tradition to carry a mechanical effect. The effects are
   generated; nothing consumes them (G-32).
3. `02` §3.2 lists timeouts and challenges among what the player may change mid-match. Timeouts are
   never spent and challenges do not exist (G-21).
4. `04b`:141 scores "sound-off and haptic equivalents" as an accessibility dimension. There is no
   sound and there are no haptics, so the dimension currently scores an equivalence to nothing
   (G-40, G-41).
5. `01-RESEARCH.md`:4204 records the bowl tail as adopted (`→ Yes → D8`); D8 in
   `docs/OPEN-DECISIONS.md` contains no tail and `02` §11.1 has no such competition (G-38).
6. `docs/plans/2026-08-12-road-to-beta.md` presents itself as "the single aggregated list of
   everything outstanding". The played match (G-18), the inbox (G-20) and the call-in loop (G-19) are
   not on it, though `docs/STATUS.md` names the first and third obliquely and the second at line 282.

---

## 6. Return as questions — the owner list

1. **The match.** Is a played, watchable match in the v1 beta, or is the beta a management-only
   build with abstract results? Everything in §1 and much of §2B follows from that one answer, and it
   is the largest unscheduled item in the project.
2. **The week's shape.** If the inbox (G-20) is not built, `02` §2.1's week has four of eight beats
   and `02` §7's stakes have no channel. Build the inbox, or amend `02` to describe the week the
   engine actually runs? Canon and code should not disagree about the core loop.
3. **Football completeness floor.** Which of penalties, kick returns, the two-point decision,
   overtime and in-match injuries (G-22 to G-26) are in v1? Recommend penalties and the PAT/two-point
   decision first: penalties because their absence is visible in every drive chart and they are the
   most-complained-about failure in the reference titles, the conversion because it is a genuine
   coaching decision that passes `02` §2.2 and costs almost nothing.
4. **Defensive statistics.** G-28 is the cheapest large win in this list: it is a data-model change in
   the abstract model, and without it no defender in the world has a record, which quietly caps
   awards, records, scouting and half of the density model's readouts.
5. **The postseason tail.** Accept the research's own conclusion and add a bowl tier (G-38), or record
   in `02` that the tail was considered and rejected, so it stops being an open contradiction.
6. **Audio.** Ship silent, or budget a sound pass? If silent, `04` §7 and `04b`'s accessibility
   dimension should say so explicitly rather than scoring an equivalence to nothing.
7. **Store readiness.** G-45's items are small individually and each one blocks submission. Should the
   pre-deployment checklist gain a section 0 for them, ahead of B-2?
