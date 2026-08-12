# AI and Delegation Architecture

## 1. AI is a game system, not automation glue

A Football Manager-like game depends on the rest of the world behaving credibly.

Required AI roles:
- coordinator AI
- opponent game-plan AI
- roster AI
- recruiting AI
- portal/NIL AI
- free-agency AI
- draft AI
- trade AI
- staff-hiring AI
- job-market AI

Each AI must have:
- goals
- knowledge limits
- resources
- personality/tendency
- deterministic decision policy
- quality tests

---

## 2. Coach brain model

A coach/GM AI decision should be:

```text
perceived state
+ scheme/preferences
+ roster needs
+ risk tolerance
+ organizational goals
+ uncertainty
→ scored candidate actions
→ deterministic choice under seeded tie-breaking
```

Do not build a general LLM agent into the simulation.

All authoritative decisions must be deterministic and offline.

---

## 3. Delegation model

The player sets:
- responsibilities
- standing instructions
- escalation thresholds
- trust

Example:
```text
Recruiting coordinator:
- autonomously contact 3-star-or-lower regional fits
- ask before using >15% of weekly points on one player
- always escalate QB offers
```

Match example:
```text
Defensive coordinator:
- call defense within game plan
- escalate 4th down
- escalate red zone
- escalate if opponent tendency confidence >70% contradicts plan
```

This solves the core management-game throughput problem:
**depth without compulsory grind**.

---

## 4. AI explainability

Every significant recommendation must produce reasons.

Example:
```text
Recommendation: Cover 2 Man
Why:
+ opponent is 2/8 vs man pressure
+ WR1 is off field
- CB2 fatigue is high
Confidence: 72%
```

Reasons are generated from actual scoring features, not fabricated prose.

---

## 5. AI quality tests

### Coordinator
- uses legal calls
- follows game plan
- responds to score/time
- does not repeat dominated calls endlessly
- adapts when evidence crosses threshold

### Recruiting
- fills positional needs
- obeys scholarship/resource limits
- values fit and information uncertainty
- does not chase impossible targets indefinitely

### Roster
- produces legal depth chart
- preserves minimum positional coverage
- considers development and future departures

### Pro front office
- remains cap legal
- avoids obviously dominated contracts
- prices positional scarcity
- drafts with needs/value uncertainty

### Career/job market
- vacancies occur for explainable reasons
- reputation affects opportunities
- carousel never dead-ends

All AI tests should compare distributions and invariants rather than demand one exact “correct” choice.
