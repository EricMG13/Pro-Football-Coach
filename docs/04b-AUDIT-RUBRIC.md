# 04b — Product UI Audit Rubric

Owner-approved correction, 2026-08-11. This rubric replaces the reconstructed five-dimension audit
and the later Nielsen-only reference scorecards. Those methods found accessibility defects but still
certified a mechanically consistent, generic application shell as production-grade.

The unit of review is one complete screen family in its real career context, not an isolated card or
component specimen.

## 1. Gate

Eight dimensions score 0–5 for a total of 40.

- **Pass:** at least 31/40, no P0/P1, and no automatic design-specificity rejection.
- **Revise:** 24–30/40 or any P2 that materially weakens the dominant task.
- **Reject:** below 24/40, any P0/P1, or any automatic rejection condition.

A high mechanical score cannot offset a generic-game failure. A beautiful still cannot offset an
inoperable or dishonest surface.

## 2. The eight dimensions

| # | Dimension | Question |
|---:|---|---|
| 1 | Football fantasy | Does the first glance feel like coaching this team at this moment? |
| 2 | Task-specific composition | Does the football object determine the layout rather than a reusable app template? |
| 3 | Information hierarchy | Is density shaped around one dominant judgement, object or decision? |
| 4 | World identity and continuity | Are team, opponent, people, time, place and prior consequence coherent? |
| 5 | Decision and control | Are cost, uncertainty, consequence, deadline, inspection and recovery understandable? |
| 6 | Accessibility and readability | Can the same task be completed with AX5, VoiceOver, Reduce Motion and either sensor orientation? |
| 7 | Truthfulness | Does every displayed fact map to a real read model or an explicitly external reference fixture? |
| 8 | Craft and resilience | Is the surface polished, responsive, performant and free of visual/system drift? |

## 3. Score anchors

The anchors apply to every dimension.

| Score | Meaning |
|---:|---|
| 0 | Absent or actively contradictory. |
| 1 | A stated intention with a fundamental failure in the rendered task. |
| 2 | Partial system; repeated defects or one severe weakness dominate. |
| 3 | Competent and usable; noticeable specificity or polish debt remains. |
| 4 | Strong, coherent and verified across the required matrix. |
| 5 | Exceptional: the screen teaches or deepens the game while remaining robust. |

### 3.1 Football fantasy

- **0:** could be any business application after noun replacement.
- **3:** football vocabulary and data are present, but the fantasy is mostly copy.
- **4:** team, competition, time and stakes shape the screen.
- **5:** the surface creates attachment, anticipation or pressure without explanation.

### 3.2 Task-specific composition

- **0:** universal dashboard shell or card-grid template.
- **3:** task is visible but shares too much chassis with unrelated work.
- **4:** dominant representation follows the task: field, chronology, board, dossier, ledger or map.
- **5:** composition makes the task faster to understand and could not sensibly belong elsewhere.

### 3.3 Information hierarchy

- **0:** everything has equal weight; working text is unreadable.
- **3:** primary path is clear, with some avoidable duplication or crowding.
- **4:** one dominant object and no more than two supporting regions in the initial viewport.
- **5:** expert density and novice comprehension coexist through progressive disclosure.

### 3.4 World identity and continuity

- **0:** contradictory team/week/person data or generic fixtures.
- **3:** coherent current state with weak history or relationship signal.
- **4:** current save identity, people and prior consequences remain consistent.
- **5:** the screen meaningfully advances a persistent career story.

### 3.5 Decision and control

- **0:** required action is hidden, fake, irreversible without warning or contradictory.
- **3:** task can be completed and consequences are stated.
- **4:** inspect, decide, delegate, recover and continue have distinct semantics.
- **5:** choices remain defensible and their later receipts teach the simulation.

### 3.6 Accessibility and readability

- **0:** a supported user cannot complete the task.
- **3:** 12 pt floor, 44 pt targets and basic semantics hold; minor ordering debt remains.
- **4:** exact device/theme/type/sensor matrix passes, including deterministic modal focus.
- **5:** non-visual and reduced-motion forms preserve the same causal understanding.

### 3.7 Truthfulness

- **0:** invented outcome, projection, save or AI authority is presented as simulation truth.
- **3:** data is mapped and fixture disclosure exists outside the game frame.
- **4:** field-level read-model mapping, uncertainty and source ownership are explicit.
- **5:** the surface reveals uncertainty and disagreement in ways that improve decisions.

### 3.8 Craft and resilience

- **0:** clipping, overlap, broken interaction, severe latency or runtime error.
- **3:** clean normal state with minor visual/token debt.
- **4:** all applicable states and exact frames are polished and performant.
- **5:** the screen remains composed under interruption, resume and adverse content without special-case fragility.

## 4. Automatic design-specificity rejection

Any one of these fails the screen regardless of total:

1. The same task-header → card-grid → action-rail composition is used for an unrelated screen.
2. Five or more equal-weight rounded containers dominate the initial viewport.
3. Pills, coloured spines, shadows or generic blue fills supply most of the hierarchy.
4. No dominant football object is visible.
5. No current team, opponent, date/phase, person, place, result or consequence is visible.
6. The screen reads as CRM, analytics SaaS, inbox, project tracker or admin console after noun replacement.
7. Internal reference, fixture, save-simulation or design-system copy appears inside the game frame.
8. A generated verdict omits its staff owner, evidence/sample or uncertainty.
9. A content index or navigation launcher occupies the space where the task should be.
10. The screen borrows Football Manager colours, layout, assets, identities or soccer-specific expression.

## 5. Severity

| Severity | Definition | Gate effect |
|---|---|---|
| **P0** | Data loss, destructive misfire, unusable supported configuration, or simulation outcome changed by presentation. | Reject and stop. |
| **P1** | Primary task cannot be completed or understood; material contradiction; inaccessible mandatory path; automatic rejection. | Reject. |
| **P2** | Task remains possible, but hierarchy, clarity, accessibility or authenticity is materially weakened. | Revise before production. |
| **P3** | Local polish or efficiency debt with no meaningful task loss. | May ship only with recorded follow-up. |

Borderline findings classify upward.

## 6. Required evidence

Each production-grade screen family supplies:

- 844 × 390 (install floor), 852 × 393 (promise floor) and 956 × 440 (ceiling) native frames, per `04` §7 and D15;
- dark and light appearances;
- default and AX5 type;
- sensor-left and sensor-right safe-area ownership;
- normal plus every applicable loading, empty, error, success, disabled, delegated, interrupted and resume state;
- one continuous-save context shared with adjacent screens;
- exact read-model mapping for every visible fact;
- keyboard/focus and VoiceOver order;
- Reduce Motion, sound-off and haptic equivalents;
- screenshot and automated interaction evidence;
- an independent visual review at original pixels.

Reference fixtures are labelled in gallery chrome **outside** the native frame. A production screen
never says `REFERENCE DATA`, `SIMULATED RECEIPT` or equivalent.

## 7. Proof-screen gate

Before production UI begins, Coaching HQ, Recruiting Board and Match Day must pass together. Their
purpose is not to prove reusable components. They must prove that one design language can produce
three visibly different football experiences while preserving shared world truth.

The owner review asks:

1. Does this feel like a serious contemporary football coaching game?
2. Can the current team, week and stakes be understood in two seconds?
3. Is the task itself—week, recruiting board or field—the dominant visual object?
4. Is any part recognisably AI-generated application furniture?
5. Would a screenshot remain identifiable if all explanatory labels outside the device were removed?

All five answers must be satisfactory. A numeric score cannot overrule the owner on questions 1 or 4.

## 8. Production enforcement

The SwiftUI phase must add machine checks for boundaries a test can truthfully own:

- every canonical screen family is registered exactly once;
- every displayed field maps to a named read model;
- no literal authored type below 12 pt;
- interactive targets meet 44 × 44 pt;
- exact landscape frames have no horizontal overflow or hidden mandatory control;
- both appearances meet contrast on composited surfaces;
- all animations have Reduce Motion forms;
- no screen imports engine internals or mutates simulation outcome;
- every unbounded-looking feed has a bound;
- every screen has a deterministic accessibility order.

Visual authenticity, dominant composition and generic-application rejection remain owner and
independent-review gates because a source scanner cannot determine whether a game feels alive.
