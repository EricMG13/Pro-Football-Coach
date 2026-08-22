# 04 — INFORMATION ARCHITECTURE

---

## 1. The READOUT / DESTINATION question — answered

**The split the brief instructs us to validate does not exist in this repository.** Zero occurrences
in `Sources/ProFootballCoachUI/`. It cannot be validated, revised, or confirmed as surviving, because
there is nothing there to survive.

**But the distinction it names is real, and it is shipped elsewhere.** Madden's Connected Franchise
navigates `HOME · NEWS · ACTIONS · TEAM · LEAGUE` (Grade A, `02` §3): three destinations telling you
*what is happening* and one — **ACTIONS** — telling you *what you must do*. EA has held this
separation for 13+ years and restated it for Madden 27 as a Roster Management centre plus an
always-one-control-away News Center.

**Ruling: adopt the distinction, reject the naming, and do not introduce a parallel taxonomy.**
This repository already has a working IA primitive — `CoachWorldScreenID` with
`CoachWorldSurfaceFamily` — and bolting a second classification onto it would create exactly the
kind of doc/code disagreement `CLAUDE.md` treats as a defect. Instead the readout/action distinction
is expressed as an **attribute of what a surface carries**, per §4, not as a new type.

---

## 2. Top-level topology — the registry survives

`CoachWorldScreenID` (62 screens, 47 canonical + 15 aliases) and `CoachWorldSurfaceFamily`
(7 families) are **KEEP**. Three properties justify this against the benchmarks:

1. **Coverage by construction.** `family` is *derived* from the screen in a `switch`, so a new case
   cannot compile without being assigned a family. This is exactly the anti-pattern `CLAUDE.md`
   demands — *"a test that checks a class of surfaces must enumerate that class by construction"*.
2. **Aliases already do the consolidation the benchmarks arrived at.** Madden 27 consolidates roster,
   depth chart, free agency, scouting and trades into one Roster Management centre (B). This
   repository reached the same place first: `proScoutingBoard`, `draftBoard` and `freeAgency` are
   already aliases of `proOffseason`. The alias table is the consolidation mechanism, and it
   preserves deep links and old saves while doing it.
3. **Seven families against FM26's six top-level destinations** is within one of the closest
   comparable. No restructuring is warranted by the evidence.

**One change.** `entry` is not a peer family — it is a pre-career phase whose surfaces carry no
sideways navigation, as the registry's own comment states. It stays in the enum for exhaustiveness
but is excluded from the family rail. That is already the behaviour of `showsIconRail`; this document
just makes the intent explicit.

---

## 3. The two persistent surfaces

The strongest topological finding in the research is a **pairing**, not a menu (Madden 27, Grade B,
corroborated by Axios): one consolidated management destination, plus one omnipresent filterable
narrative feed *"always one button away"*, plus a persistent ticker on every screen.

Mapped here:

| Role | Surface | Reachable from |
|---|---|---|
| **The consolidated management destination** | 8 Coaching HQ | The icon rail, from every non-entry surface |
| **The omnipresent feed** | 50 News + 9 Inbox | One control, from every non-entry surface |
| **The ambient ticker** | `NewsTicker` (`05`, new) | Rendered by `FloodlitChrome`, so it is on every DESK surface by construction |

**The ticker is how the ceremony rule is honoured** (`00` §6.3): it is the zero-interaction default
channel. Present in every Madden generation observed since 2012 (A).

---

## 4. What a surface carries — the readout/action attribute

Every canonical surface declares, in the design, which of three it is. This replaces the
non-existent READOUT/DESTINATION split without adding a type.

| Attribute | Meaning | Carries | Density tier |
|---|---|---|---|
| **READOUT** | State you look at | No committing controls | DENSE permitted |
| **ACTION** | Decisions you make | ≥1 `DecisionCard` or committing control | COMFORTABLE required |
| **MIXED** | Readout with a committing control in it | Both, with the control visually separated | COMFORTABLE |

**Rule A-1.** An ACTION surface may not exceed the COMFORTABLE tier. A decision taken at DENSE
density is a decision taken by mistake.
**Rule A-2.** On a MIXED surface, committing controls use `FloodlitCommittingAction` and are never
inside a scrolling table row. The 44 pt interactive row floor applies (`00` §4.4 R-D3).
**Rule A-3.** READOUT surfaces may be reached in CRUISE. ACTION surfaces are DEEP by definition.

Assignments: Standings, Schedule, Statistics, Box Score, League Map, Record Book, Career Line,
Rankings, Bracket → **READOUT**. Game Plan, Practice Plan, Depth Chart, Contract Negotiation, NIL
Allocation, Retention, Roster Cuts, Contact & Visit Planner, Promotion Decision → **ACTION**.
Coaching HQ, Roster, Recruiting Board, Team Health, Player Profile, Prospect Profile, Staff Room,
Inbox → **MIXED**.

---

## 5. Delegation: configured in one place, exercised everywhere

Both reference implementations separate these, and this product must too.

**Configured — a new surface, `Responsibilities`.** FM26 carries "Responsibilities" as its own
top-level destination (A). OOTP's `Team Control Settings` is an 11-row matrix, each row choosing
between the human and a **named** staff member (B). This product has no such surface. It is
[`07`](07-GAP-REGISTER.md) **GAP-05**, and it belongs in the `career` family beside Staff Room.

Its contract:

- **One row per delegable area**, enumerated by construction from a `DelegationArea` enum so a new
  area cannot ship unassigned.
- **Every row resolves to a named person**, never to "auto". The name is the trust surface (`02` §6).
- **Every row prints the delegate's competence** using `DelegateAssignmentCard`'s rate line — the
  MLB The Show pattern of stating the yield where you make the assignment.
- **A temporary layer**, per OOTP's Vacation Settings: a second column that overrides for a bounded
  span without rewriting the standing matrix.
- **No area may resolve to nobody.** This is the trap OOTP's own documentation volunteers (`02` §6).
  Enforced as a compile-time exhaustive switch plus a runtime assertion, not a UI validation.

**Exercised — inline, at the point of the decision.** `FloodlitStaffVoice` already exists; it gains
the FM Dugout contract (A): a suggestion with a primary accept and a secondary decline, the decline
carrying a **stated** cost. See [`05`](05-COMPONENT-REGISTER.md) `DecisionCard`.

**Interrupts — where cruise ends.** OOTP's six triggers with two configurable thresholds (B) are
adopted wholesale, translated to this sport:

| Trigger | Threshold | Default |
|---|---|---|
| Injury | none → out ≥2 weeks | out ≥1 week |
| Availability drop | none → ≥30% | ≥30% |
| Recruiting: commitment gained or lost | on/off | on |
| Contract or eligibility deadline | on/off | on |
| Staff or board message | on/off | on |
| Incoming trade or transfer approach | on/off | on |

Configured on the same `Responsibilities` surface. **Defaults are on**, matching OOTP, whose docs
warn that disabling all exits means *"you might miss critical news or opportunities."*

---

## 6. Where ceremony sits — the closed list

Per [`00`](00-GATE-ZERO.md) §6.3, **exactly five** dedicated ceremony surfaces per season. Adding a
sixth is a decision-register amendment.

| # | Moment | Surface | State |
|---|---|---|---|
| 1 | Championship result | *no registry entry* | **NEW** — [`07`](07-GAP-REGISTER.md) GAP-10 |
| 2 | Promotion decision | 55 `PromotionDecisionView` | REBUILD (60 lines) |
| 3 | Signing day | 29 `SigningDayView` | REBUILD (65 lines) |
| 4 | Draft night | 39 `DraftRoomView` | REBUILD (63 lines) |
| 5 | Awards & honours | 49 `AwardsHonoursView` | REBUILD (126 lines) |

All five use the **BROADCAST** register. Each costs one control to leave. Each remains reachable
afterwards from its family, so leaving is never loss. **Every other week — including every regular
season match week — gets zero dedicated ceremony and zero dismissals.**

The draft-night contract is specified by observation (`02` §6, Grade A): on-the-clock header with a
live countdown, "Up Next", a filling pick list, and **a queue** so the clock can run without the
player. That is ceremony and throughput in one frame.

---

## 7. The advance loop

```
CRUISE ── Coaching HQ ──────────────────────────────────────────┐
   │                                                            │
   │  agenda: N rows, each {title, timing, cost, state}         │
   │  ticker: ambient, zero cost                                │
   │  advance control: always visible, never blocked            │
   │                                                            │
   ├─ tap row ──> DEEP (subject) ── back, state restored ───────┤
   │                                                            │
   ├─ interrupt ──> TRIAGE ── resolved ─────────────────────────┤
   │                                                            │
   └─ advance ──> [simulate] ──> ceremony trigger? ─── no ──────┘
                                        │
                                       yes
                                        │
                                        v
                            CEREMONY (1 of 5) ── 1 tap ── back to CRUISE
```

**Loop invariants.**
- **L-1.** The advance control is reachable in ≤1 interaction from every CRUISE and TRIAGE surface.
- **L-2.** Advancing never requires visiting an ACTION surface. Unvisited decisions resolve to their
  delegated or pre-populated default — Madden's stated model (B): the loadout *"will be automatically
  filled with suggested abilities"*, so **the no-action path is a designed state, not a null state**.
- **L-3.** Every delegated resolution is reported back on the next CRUISE surface as a `delegated`
  agenda row. Silent delegation is indistinguishable from a bug.
- **L-4.** No interrupt blocks the advance. An interrupt adds a TRIAGE row; it does not seize control.

---

## 8. Deep-dive entry and exit from every cruise surface

| From | Entry | Exit restores |
|---|---|---|
| HQ agenda row | tap → the row's task surface | agenda scroll position, expanded state |
| HQ delegated row | tap → the delegate's report, then the task | as above |
| Inbox item | tap → the subject surface | inbox scroll, read state, active filter |
| Ticker item | tap → News, scrolled to the item | prior surface entirely |
| Any table row | tap → the row's profile | **scroll, sort, filter and column set** |
| Team Health entry | tap → Player Profile | list scroll and filter |

The last row is the one that fails most often and matters most. **FM26's reception collapsed on
exactly this class of cost** (`02` §1, Grade C). It is invariant **T-2** in
[`03`](03-SESSION-INTENT-MODEL.md) and is testable.

---

## 9. What this IA does not change

The icon rail, the identity header and its sibling row, the seven families, the alias table, the
`showsIconRail` exemptions, and the world backdrop are all **unchanged**. The additions are: one new
configuration surface (`Responsibilities`), one new ceremony surface (championship result), one new
chrome component (`NewsTicker`), and the readout/action attribute in §4. Everything else is a
refactor of surfaces that already exist.
