# UI Adversarial Audit — Latest Design Pass

## Owner disposition — 2026-08-11

The rendered direction reviewed below and the later 34-screen Film Room library are **rejected as
product direction**. Both made a desktop management application smaller and more consistent without
solving the game fantasy. The later library improved accessibility and mechanics but repeated the
same task-header, split-pane, verdict and action-rail composition across unrelated football work.

The canonical replacement is **The Coach's World** in the repository's
`docs/04-UX-AND-DESIGN-SYSTEM.md`:

- Film Room is only scouting, tactics and replay;
- Office, Personnel, Acquisition, Front Office, League/Media, Career/Legacy, Broadcast and Ceremony
  use task-specific football objects and spatial languages;
- the universal bottom navigation bar and 38/62 chassis are removed;
- the complete inventory is 62 player-facing screen families;
- Coaching HQ, Recruiting Board and Match Day are the mandatory proof set;
- the proof set uses a continuous fictional save and neutral blank person-photo plates.

The analysis below remains useful as evidence of failure modes. It is not a build specification and
must not be used to reconstruct the reviewed board.

## Overall judgement

**Direction: strong. Production readiness: low.**

The latest board finally looks like one coherent management game, and the face-card + 2D-circle match decision is materially better than the prior human-portrait/full-visual approach.

However, the board still behaves like a **desktop dashboard squeezed into landscape iPhone**. The largest risk is not aesthetics; it is that too much information has equal visual weight. Football Manager succeeds through information density, but density only works when hierarchy, drill-down, filtering, context and repeated navigation patterns are extremely disciplined.

### Scores
| Dimension | Score | Notes |
|---|---:|---|
| Product identity | 8/10 | clearly a serious football management game |
| Information hierarchy | 5/10 | too many equal-weight boxes |
| iPhone legibility | 4/10 | text/tables are unrealistically small |
| Football specificity | 8/10 | 2D field, matchups, game-plan structure strong |
| Decision clarity | 6/10 | some surfaces explain decisions; others are databases |
| Long-career storytelling | 5/10 | career/history remains too table-like |
| Cross-surface consistency | 6/10 | common visual language, inconsistent navigation model |
| Accessibility potential | 3/10 | current density would fail larger text quickly |
| Backend truthfulness | 4/10 | many displayed insights require systems not yet built |

---

# Surface 1 — Career Start / Job Market

### Strong
- First decision is meaningful.
- Programme comparison immediately establishes career strategy.
- Expectations/resources/fit are the right categories.

### Problems
- Looks like a recruitment CRM.
- Six programmes in a dense table means the user compares numbers rather than imagining a career.
- “Schedule interview” creates procedural friction without gameplay unless interviews themselves contain consequential decisions.
- No current-roster age/depth profile.
- No staff situation.
- No location/recruiting territory visualization.
- Fit score is dangerously reductive.

### Redesign
Use a shortlist of 3–4 offers with a large selected-programme pane.

Selected pane answers:
1. Why do they want me?
2. What is broken?
3. What do they expect?
4. What resources do I inherit?
5. What does success look like in Year 1?
6. What is the upside of this job?

Add “Save identity” labels such as:
- rebuild
- sleeping giant
- win-now pressure
- development programme

These are summaries of real data, not hard-coded classes.

---

# Surface 2 — Coaching HQ

### Strong
This is the best surface.

- week is visible
- pressure is visible
- priorities are visible
- inbox is visible
- preparation has state

### Problems
- `ADVANCE TO GAME DAY` is too powerful. It implies skipping unresolved obligations.
- Calendar strip consumes space without communicating cost.
- Stakeholder panel shows status but not movement/reason.
- Inbox and priorities overlap conceptually.
- Too many small cards.

### Redesign
Use one dominant **Next Decision** card.

Example:
> Tuesday — Practice allocation  
> 3 hours remain  
> DC recommends run-fit work after last week's missed fits.

Below it:
- Week plan
- Pressure
- Inbox
- Opponent
- Team health

Replace “Advance to Game Day” with **Continue**.
Continue resolves only when mandatory actions are set or explicitly delegated.

---

# Surface 3 — Scouting Room

### Strong
- AI verdict is excellent.
- Key matchups are directly football-relevant.
- confidence is shown.

### Problems
- Tendency stats lack sample sizes.
- “Run rate 59%” is nearly meaningless without down/distance/personnel context.
- No split between observed facts and staff interpretation.
- Injuries are tiny despite potential game-plan significance.

### Redesign
Two explicit columns:

**Film/Data**
- what happened
- sample size
- situational splits
- personnel

**Staff Interpretation**
- what we think it means
- confidence
- recommended response
- disagreement between staff if relevant

Make every key matchup open into evidence.

---

# Surface 4 — Game Plan

### Strong
- offense/defense/situational separation
- weekly plan is distinct from roster
- keys at bottom hint at strategic intent

### Problems
This surface is currently the most “spreadsheet slider” part of the game.

- too many continuous sliders imply fake precision
- star ratings beside concepts look like optimality scores
- players will optimize numbers rather than express football philosophy
- little visible opportunity cost

### Redesign
Replace most sliders with discrete choices plus tradeoffs.

Example:
**Tempo**
- Slow: fewer possessions, protects tired defense
- Balanced
- Fast: more possessions, higher fatigue/error risk

Weekly keys become the primary control:
- establish outside zone
- stress MLB with play action
- protect football
- attack CB2 deep

Behind each key, coordinators adjust lower-level tendencies.

Advanced players may open “Detailed Tendencies,” but the default surface should be strategic.

---

# Surface 5 — Team Hub / Depth Chart

### Strong
- field-based depth chart is excellent
- circle representation matches match-view language
- offense/defense lists flank spatial structure

### Problems
- player numbers alone are not enough for unfamiliar fictional rosters
- current field does not show packages/roles clearly
- no future-year projection
- no fatigue/injury/eligibility context
- exact ratings dominate the visual hierarchy

### Redesign
Add display toggle:
- jersey number
- position ID
- initials

Add tabs:
- Base
- Nickel/Dime
- Goal Line
- 3rd Down
- Special Teams

Add **Now / Next Year / +2 Years** roster projection.

This is a cornerstone “one more season” screen.

---

# Surface 6 — Player Profile

### Strong
- blank face card is correct
- scheme fit/status/development are well placed
- history tab exists
- progression chart helps attachment

### Problems
- three columns of exact attributes make OVR optimization too easy
- potential estimate still looks too deterministic
- no role description
- no game/recruiting story
- traits are tiny pills with insufficient consequence
- no comparison with depth-chart competition

### Redesign
Top question:
**What is this player to my team?**

Show:
- current role
- expected role next year
- strengths
- weaknesses
- development trend
- confidence
- key relationships
- competition for snaps
- career/recruiting milestones

Attributes remain available one tap deeper.

---

# Surface 7 — Recruiting Board

### Strong
- dense board is appropriate for expert users
- points budget is visible
- confidence/interest exist
- pipeline concept is promising

### Problems
- still looks like a ranked spreadsheet
- exact interest percentages imply false precision
- map is too small to be useful
- no clear “why he likes us”
- no battle dynamics
- no future roster need integration

### Redesign
Default board organizes by **need**:
QB Future
OL Immediate
CB Development

Each recruit row:
- estimated quality range
- confidence
- relationship state
- strongest motivation
- top competitor
- recommended next action

A separate Recruit Profile handles detailed battle.

---

# Surface 8 — Match Center

### Strong
This is directionally the right solution.

- top-view football field
- circles instead of human models
- numbers/position IDs
- field-state readability
- FM-like abstraction
- score bug is compact

### Problems
- huge vertical team-name end panels waste field width
- circles are too small for iPhone
- 22 actors + labels + yard marks will become visually noisy
- no stadium context despite request for top-view stadium
- no explicit LOS/first-down line
- no event feed / commentary
- no distinction between normal drive view and key highlight
- bottom controls are too many tiny buttons
- no selected-player or matchup emphasis

### Redesign
Use stadium-bowl framing around the field, not team-name walls.

Default drive view:
- simplified motion
- larger circles
- position IDs
- ball
- LOS
- first-down line
- only 2–3 emphasized actors

Key highlight:
- pause before snap
- show assignment/route/pressure arrows briefly
- play animation
- show causal outcome
- return to drive summary

Controls:
**Speed | Pause | Key Moments | Take Over | Tactics**

Everything else goes in a drawer.

Allow:
`Position IDs / Jersey Numbers` toggle.

---

# Surface 9 — Career Hub

### Strong
- profile/reputation/security/achievements are useful
- career timeline exists
- record book call-to-action exists

### Problems
- a six-season career still reads like a spreadsheet
- coaching tree tab is missing from the visible content
- major moments are awards only
- former teams/rivals/assistants are not emotionally present

### Redesign
Primary surface is chronological story cards.

Example:
**2031 — Canyon Tech**
- Conference Champion
- upset #2 Northern Valley
- OC Marcus Bell left for Riverside
- signed QB Avery Stone
- finished 12–2

Record/ratings stay as secondary statistics.

---

# Surface 10 — Offseason Command Center

### Strong
- recognizes college and pro need separate systems

### Problems
This is currently the weakest production surface.

It is a tile launcher, not an offseason.

No urgency.
No sequencing.
No deadlines.
No consequence preview.
No dominant current problem.

### Redesign
Make offseason a timeline.

College:
`Staff → Portal Window → Recruiting Finish → Signing Day → Spring Development → Carousel`

Pro:
`Contracts → Cap Deadline → Free Agency → Draft → Roster Cutdown → Camp`

Each phase has:
- deadline
- unresolved decisions
- resource state
- irreversible actions
- delegated actions

The player should feel time moving.

---

## Cross-surface defects

### 1. Text is too small
The board is visually impressive at desktop scale but does not represent an actual iPhone landscape layout.

### 2. Excessive card nesting
Most surfaces use boxes inside boxes inside boxes.
This destroys priority.

### 3. Too many simultaneous navigation patterns
Some screens use left rail, some top tabs, some bottom tabs, some tile launchers.

Define one global model:
- global destinations
- local tabs
- contextual drawer

### 4. Purple is doing too many jobs
It currently means:
- brand
- selection
- action
- team identity

Reserve one semantic interaction accent. Team colors should be data, not navigation chrome.

### 5. Ratings are overexposed
Exact numbers everywhere undermine uncertainty and promote spreadsheet optimization.

### 6. Too little causal explanation
Whenever a value moves, the player should be able to answer:
**Why?**

### 7. Too little history
The board contains a lot of current-state data but insufficient “how we got here.”

### 8. Too little delegation
A management game this deep needs “do this for me unless…” controls on every high-volume system.

---

## Final UI recommendation

Keep:
- dark serious presentation
- blank portrait cards
- top-down circle-based depth chart
- FM-like 2D match
- HQ concept
- scouting verdict concept
- five-destination philosophy
- dense expert-level secondary screens

Change:
- dramatically reduce dashboard fragmentation
- increase type size
- show fewer things at once
- make history, causality and uncertainty first-class
- use discrete strategic choices before detailed sliders
- make offseason sequential
- make career narrative-first
- make 2D match highlight-driven and spatially readable
