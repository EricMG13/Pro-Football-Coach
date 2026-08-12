# Simulation Backend Plan

## Phase A — Architectural backbone

### A1. Root `GameState`
Create one authoritative save root.

### A2. World scheduler
Implement deterministic daily/weekly/phase boundaries.

### A3. Domain event ledger
Emit events from all state-changing systems.

### A4. Read-model boundary
Formalize projections consumed by UI.

### A5. Integrity tests
At every boundary:
- all IDs resolve
- roster legality
- no duplicate employment
- money/cap consistency
- schedule consistency
- bounded collections
- deterministic replay

**Do this before adding more management systems.**

---

## Phase B — Competition and statistical world

Build:
- schedule generation
- standings
- rankings
- tiebreakers
- conference championship
- playoffs
- overtime
- awards
- team/player season stats
- record book primitives

Reason: nearly every later system needs actual seasons and credible historical outcomes.

---

## Phase C — Player population and lifecycle

Build:
- full roster generation
- positional distributions
- class/age distributions
- development curves
- playing-time effects
- fatigue
- injury
- retirement/graduation
- player career history

Critical output:
A 20-season world must retain plausible roster sizes, age structures and statistical distributions.

---

## Phase D — Staff population and careers

Build:
- staff generation
- ratings
- scheme identity
- employment
- poaching
- coordinator promotion
- position-coach promotion
- firing
- staff reputation
- coaching tree

This is not polish. Staff are the delegation layer that lets complexity scale without forcing the user to micromanage everything.

---

## Phase E — Scouting and knowledge

Build observer-specific knowledge:
- recruit evaluation
- opponent tendencies
- draft prospect evaluation
- staff recommendations
- confidence/sample size

Never show unknown truth merely because the engine knows it.

---

## Phase F — College ecosystem

Build in dependency order:

1. recruiting pool generation
2. programme/recruit fit factors
3. weekly contact budget
4. evaluation
5. competing AI programmes
6. visits
7. commitment logic
8. scholarship accounting
9. signing day
10. eligibility
11. redshirt
12. portal intent
13. retention
14. transfer destination
15. NIL resource allocation
16. offseason development

Every interaction emits history.

---

## Phase G — Pro ecosystem

Build:
1. contract model
2. cap accounting
3. release/dead money
4. roster cuts
5. free agency market
6. bidding/negotiation
7. draft class
8. scouting
9. draft board
10. AI draft
11. rookie contracts
12. trades
13. practice squad
14. waiver/claim model if included

The pro tier should feel structurally different, while retaining the same UI mental model: **solve roster problems under constraints**.

---

## Phase H — Scheme, playbook and preparation

Separate three layers:

### Scheme
Long-term identity:
- offensive family
- defensive family
- terminology/teaching continuity
- personnel fit

### Playbook
Available concepts/packages:
- formations
- run concepts
- pass concepts
- pressure packages
- coverages
- situational calls

### Weekly game plan
Opponent-specific biases:
- priorities
- keys
- aggression
- tempo
- personnel emphasis
- coverage/front lean
- situational overrides

Changing scheme has long-term cost.
Changing game plan is expected weekly.

---

## Phase I — AI and delegation

See `04-AI-AND-DELEGATION-ARCHITECTURE.md`.

---

## Phase J — Career/stakes/history

Build:
- expectations
- stakeholder dispositions
- inbound events
- reputation
- job security
- firing
- openings
- interviews/offers
- college → pro threshold
- demotion path
- coach records
- career timeline
- former-team relationships
- coaching tree
- rivalry consequences

---

## Phase K — World evolution

Build:
- rivalry strengthening
- programme prestige movement
- resource drift
- conference realignment
- staff pipelines
- historical rankings/records
- generated traditions evolving from events if desired

---

## Phase L — 2D match presentation support

Backend requirements:
- field-coordinate frame data
- formation anchors
- route/run/coverage annotations for selected highlights
- directed-attention tags
- play explanation
- call-in context
- drive summary

Do not build a physics engine for presentation.

Use recorded deterministic outcomes and choreograph the circles to tell the truth of the recorded play.
