# 03 — SESSION-INTENT MODEL

**This supersedes the two-persona brief.** Per [`00`](00-GATE-ZERO.md) §5, the design problem is not
persona segmentation but **transition cost**: how cheaply a player drops from cruise into one
decision and climbs back out without losing context.

**Confidence: low-medium.** The ruling rests on architectural evidence (Grade B/D), not behavioural.
No telemetry, survey or characterised community evidence survived two research passes. This is the
weakest load-bearing model in the dossier and it is instrumented for falsification in §6.

---

## 1. Why intents, not personas

A user-type model would make involvement a setup-time choice — pick "casual" or "deep" once, get a
matching app. Three shipped mechanisms in the reference implementation argue against that (§5 of
`00` states the premises and marks the inferential leap):

- delegation is a **per-area matrix**, not a level (OOTP, 11 areas, stable since 2017);
- there is a **separate temporary layer** over the standing matrix (Vacation Settings);
- automation **hands control back on user-set thresholds** and can be stopped mid-run.

A design serving two fixed types needs none of these. A design serving one player whose involvement
changes repeatedly within a save needs all three.

**Consequence for this product: there is no "simple mode". There is one app, and four intents the
same player moves between, sometimes several times in one sitting.**

---

## 2. The four intents

| | **CRUISE** | **TRIAGE** | **DEEP** | **CEREMONY** |
|---|---|---|---|---|
| **The player is** | advancing time | scanning what needs them | resolving one thing | being paid off |
| **Interaction budget** | ≤3 per week | ≤8 per week | unbounded, on one subject | ≤1 to leave |
| **Density tier** (`06` §3) | COMFORTABLE | COMFORTABLE | DENSE | BROADCAST |
| **Register** (`05`) | DESK | DESK | DESK | BROADCAST |
| **Home surface** | Coaching HQ | Coaching HQ agenda + Inbox | any task surface | 5 named surfaces only |
| **What is delegated** | everything not explicitly owned | nothing new; triage only routes | nothing in the subject | n/a |
| **Ceremony** | ambient only | ambient only | suppressed | is the point |

Budgets are **Grade D** and derived from the `00` §4 density arithmetic plus the ceremony rule, not
from session-length data — that evidence does not exist (`00` §1). They are targets to instrument,
not measurements.

### 2.1 CRUISE

Advancing the week with delegated authority. The default state, and **not a degraded one** — brief
invariant 6. A cruising player sees the same chrome, the same tokens and the same identity as a deep
player; what differs is how much is already decided.

The surface must answer, without a tap: what happened, what is owned by whom, what is unresolved.
The advance control is always visible.

**Entry:** app launch with a settled week; leaving CEREMONY; completing the last TRIAGE item.
**Exit:** an agenda row is tapped (→ DEEP); an interrupt fires (→ TRIAGE); the week ends with a
ceremony trigger (→ CEREMONY).

### 2.2 TRIAGE

Something changed and the player is deciding what deserves them. Distinct from CRUISE because the
player is *scanning*, and distinct from DEEP because they have not yet committed to a subject.

This is where the [`05`](05-COMPONENT-REGISTER.md) `AgendaRow` earns its keep: title, timing, cost,
and state ∈ {pending, complete, **delegated**}. A delegated row is not hidden — seeing what the
delegate is handling is how trust is built (`02` §6).

**Entry:** an interrupt threshold is crossed; opening the Inbox; week rollover with pending items.
**Exit:** every row resolved or accepted-as-delegated (→ CRUISE); a row tapped (→ DEEP).

### 2.3 DEEP

One subject, no budget. The player has chosen to spend forty minutes on a depth-chart decision, and
the UI's only jobs are to show enough and to keep the way back cheap.

**DEEP is scoped to a subject, not to the app.** A player deep in the depth chart is still cruising
everything else. This is the single most important consequence of choosing intents over personas:
**involvement is per-area and simultaneous**, exactly as OOTP's matrix models it.

**Entry:** tapping an agenda row, a table row, or a delegate's report.
**Exit:** the back affordance, which must restore the originating surface's scroll position, filter
state and column set — see §4.

### 2.4 CEREMONY

The payoff. Governed entirely by [`00`](00-GATE-ZERO.md) §6: ambient by default, and **at most five
dedicated surfaces per season**, each costing at most one interaction to leave, each re-reachable
afterwards so leaving is never loss.

**Entry:** only from the closed trigger list in [`04`](04-INFORMATION-ARCHITECTURE.md) §6.
**Exit:** one control, returning to the originating surface.

---

## 3. The state machine

```
                    ┌───────────────────────────────────┐
                    │                                   │
                    v                                   │
   ┌──────────┐  advance   ┌──────────┐             ┌───────────┐
   │  CRUISE  │───────────>│  CRUISE  │─ trigger ──>│ CEREMONY  │
   │  week n  │<───────────│ week n+1 │<── 1 tap ───│  (≤5/yr)  │
   └──────────┘            └──────────┘             └───────────┘
      │    ^                  │    ^
 tap  │    │ all resolved     │    │ back, state restored
 row  │    │                  │    │
      v    │                  v    │
   ┌──────────┐   tap row  ┌──────────┐
   │  TRIAGE  │───────────>│   DEEP   │
   │          │<───────────│ (subject)│
   └──────────┘    back    └──────────┘
        ^                       │
        │  interrupt fires      │
        └───────────────────────┘
```

Every edge is bidirectional. There is no terminal state and no mode the player can get stuck in.

---

## 4. Transition cost — the actual design target

**T-1. Any transition costs ≤2 interactions in each direction.** CRUISE→DEEP is one tap on the
agenda row. DEEP→CRUISE is one tap on back.

**T-2. Returning restores state.** Scroll position, filter, sort, selected column set and expanded
rows all survive a round trip. **This is the concrete lesson of FM26's failure** (`02` §1): reception
collapsed when routine tasks got more expensive, and a lost filter is exactly that kind of tax.

**T-3. Delegation is never a mode.** Entering DEEP on one subject does not revoke delegation
elsewhere; leaving does not grant it. Authority changes only at the delegation-configuration surface
([`04`](04-INFORMATION-ARCHITECTURE.md) §5) or by an explicit per-decision act.

**T-4. No transition is modal.** Nothing blocks the advance control except a CEREMONY surface, and
those are capped at five per season.

**T-5. The way in and the way out are the same edge.** A player who enters the depth chart from the
agenda returns to the agenda, not to a generic home.

---

## 5. Mapping intents to the surface registry

| Intent | Canonical surfaces | Notes |
|---|---|---|
| CRUISE | 8 Coaching HQ | The only true cruise surface. `CareerHubView` is a DEEP destination |
| TRIAGE | 8 Coaching HQ (agenda), 9 Inbox, 13 Team Health | Team Health is triage because injuries are the default interrupt (`02` §6) |
| DEEP | all 47 canonical tasks | Every task surface is a DEEP destination by construction |
| CEREMONY | 29 Signing Day, 39 Draft Room, 49 Awards, 55 Promotion Decision, + championship result | Exactly five. Four are REBUILD in [`01`](01-REPO-UI-INVENTORY.md); the fifth has no registry entry yet |

**Match Day (14) is deliberately unassigned.** It spans DEEP (in-match intervention) and CEREMONY
(the lower-third over the pitch, `02` §2) without being either, and it is the one surface where
BROADCAST register and DESK intent coexist. It is governed by the render-recorded-match contract
rather than by this model.

---

## 6. Falsification

This model is wrong if players choose an involvement level once per save and keep it. Instrument in
TestFlight:

| Metric | Predicts |
|---|---|
| Transitions between delegated and manual authority **per save** | >0 for most saves. **0 for most saves falsifies the model** and reinstates personas |
| The trigger preceding each transition | Concentration on injury/big-match/playoff supports the interrupt design; uniform distribution suggests boredom, which needs a different remedy |
| Interactions per week, distribution not mean | Sets the budgets in §2, which are currently Grade D |
| Round trips per week that lose state | Should be 0. Any non-zero value is a T-2 defect |

See [`08`](08-DECISION-REGISTER.md) **D-002**, and **D-001** for the unclosed interaction budget.
