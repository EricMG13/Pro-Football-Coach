# Build Roadmap and Gates

## Principle

Backend first. UI feature work should begin only when a truthful read model exists.

---

## Milestone 0 — Architecture hardening
Deliver:
- `GameState`
- scheduler
- domain events
- read-model/intents interfaces
- integrity suite

Exit gate:
- existing match/generation functionality survives
- same seed produces identical result
- one simulated week can run through scheduler deterministically

---

## Milestone 1 — Playable world
Deliver:
- schedule
- standings/rankings
- postseason
- statistics
- roster population
- season advancement

Exit gate:
- 20 college/pro seasons complete headlessly
- no integrity failures
- results statistically plausible enough for continued tuning

---

## Milestone 2 — People lifecycle
Deliver:
- development
- injuries/fatigue
- eligibility/retirement
- staff generation/careers

Exit gate:
- population distributions remain stable for 20 seasons
- staff vacancies always resolve
- development outcomes are explainable and bounded

---

## Milestone 3 — College management game
Deliver:
- scouting
- recruiting
- visits
- commitments
- scholarships
- portal
- NIL
- redshirts

Exit gate:
- one complete college career can run headlessly
- AI fills all rosters legally
- recruiting classes have plausible strength distributions

---

## Milestone 4 — Tactical management game
Deliver:
- scheme
- playbook
- opponent scouting
- weekly game plan
- practice
- coordinator AI
- match call-ins
- game-plan review

Exit gate:
- tactical choices measurably alter outcome distributions
- coordinator decisions are situation-aware
- scouting knowledge changes available confidence, not underlying truth

---

## Milestone 5 — Career and stakes
Deliver:
- inbox
- expectations
- stakeholders
- reputation
- firing
- job market
- staff poaching
- coaching tree
- career timeline

Exit gate:
- no dead-end career
- career histories persist through team changes
- former staff and teams remain queryable

---

## Milestone 6 — Pro management game
Deliver:
- contracts/cap
- free agency
- draft
- trades
- practice squad
- pro job transition

Exit gate:
- 20-season both-tier soak
- every pro team cap legal
- AI roster construction remains credible

---

## Milestone 7 — Living world/history
Deliver:
- rivalries
- records
- awards
- programme evolution
- conference movement
- advanced history/search
- narrative event composition

Exit gate:
- 30+ season history remains useful and performant
- important past events can be surfaced without scanning entire save

---

## Milestone 8 — Production UI

Entry gate before any feature SwiftUI:

- the corrected **Coach's World** design language in the repository's
  `docs/04-UX-AND-DESIGN-SYSTEM.md` is canonical;
- Coaching HQ, Recruiting Board and Match Day have been approved together as interactive native-size
  proofs;
- each proof scores at least 31/40 under `docs/04b-AUDIT-RUBRIC.md`, has no P0/P1 and triggers no
  generic-application rejection;
- the deleted v2, Stitch and 34-screen Film Room artefacts are not build references;
- Film Room remains limited to scouting, tactics and replay.

Deliver:
- Career Start
- HQ
- Team
- Scouting Room
- Game Plan
- Recruiting / Front Office
- League
- Career
- Offseason
- Search
- 2D Match Center

Build all 62 canonical screen families listed in repository `04` §8. The list above names product
areas, not a complete screen count. Each family needs a named read model and a task-specific dominant
football object. Do not introduce a universal task header, two-pane chassis, bottom destination bar,
card grid or fixed action rail.

Each surface binds only to a defined read model.

---

## Milestone 9 — Product completion
- onboarding
- accessibility
- reduced motion
- failure/recovery
- save migrations
- performance tuning
- device testing
- final calibration
- long soak
- release checklist

---

## Scope assessment

### Achievable with current architecture direction
Yes:
- deterministic single-player sim
- two-tier career
- 134-programme abstract world
- deep roster/recruiting/cap systems
- FM-style 2D match visualization
- long-term history
- rich AI delegation

### Not achievable simply by continuing to append modules
The current architecture needs the scheduler/event/history/read-model additions before feature count grows. Without them, systems will become tightly coupled and historical/narrative features will require expensive retrofits.

### Development-tool fit
Swift + SwiftUI + Canvas are adequate.
Zero third-party runtime dependencies are also viable.

The limiting factor is **scope and simulation design**, not language/framework capability.

### Highest technical risks
1. believable AI at scale
2. match-engine calibration
3. long-career save growth/history
4. causal interconnection between systems
5. building enough football-specific tactical depth without creating an every-snap micromanagement game
