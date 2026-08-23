# Surface coverage: what is required, what is built, what is drawn

**2026-08-23.** A working brief, not canon. `docs/DOC-MANIFEST.md` governs what is canon;
nothing here amends a canon document.

The question this answers: **what is missing, against the surfaces the product requires?**

It turns out to be three different questions with three different answers, and collapsing
them is how the honest number gets lost.

| Layer | Authority | Count | State |
|---|---|---|---|
| **Required** | `ScreenRegistry.swift`, enumerated in `Coach World.dc.html` | **62** | fixed |
| **Implemented** | SwiftUI views on `main` | **62 of 62** | complete |
| **Drawn in the design system** | Press Box | **12 of 62** | 19% |

**No registry surface is unimplemented.** Every one of the 62 has a SwiftUI view on `main` —
verified by mapping each registry `sid` to its view file. The gap is not missing screens.

**The gap is that 50 of the 62 are built to a design language Press Box replaced.** They
exist, they route, they compile; they were drawn before the register model, the gold budget,
the measured palette and the accessibility contract existed.

---

## 1. The registry, and what Press Box covers

Registry entries are `[sid, number, name, family]` from `Coach World.dc.html`. All 62 have a
Swift view; the third column is the only one with holes.

### Drawn (12)

| sid | # | Surface | Family | Press Box |
|---|---|---|---|---|
| 1a | 14 | Match day | week | `MatchDayDemo` |
| 6a | 8 | Coaching HQ | week | `ThisWeekDemo` |
| 2a | 16 | Roster | personnel | `PersonnelDemo` |
| 8a | 24 | Recruiting board | recruiting | `RecruitingDemo` |
| 8b | 25 | Prospect profile | recruiting | `DossierDemo` |
| 8f | 29 | Signing day | recruiting | `BroadcastDemo` |
| 9f | 39 | Draft room | pro | `DraftRoomDemo` |
| 10g | 49 | Awards & honours | league | `AwardsDemo` |
| 11b | 55 | Promotion decision | career | `CareerDemo` |
| 11g | 6 | Settings & accessibility | career | `AppearanceDemo` |
| 11a | 54 | Stakeholders | career | `SeasonExpectationsDemo` — **partial** |
| 11h | 1 | Title / Continue | career | `ContinuityDemo` — **partial** |

The two partials are honest mismatches rather than coverage. *Season Expectations* draws the
board's demands; *Stakeholders* is the wider cast including donors, students and press.
*Save & Continuity* draws the save list; *Title / Continue* is also the entry ceremony, which
is a Broadcast moment nothing has drawn.

### Undrawn (50), by family

| Family | Drawn | Undrawn |
|---|---|---|
| **week** | 2/9 | 6b Inbox · 6c Opponent report / Film room · 6d Game plan · 6e Practice plan · 6f Team health · 6g Aftermath · 6h Game detail / Box score |
| **personnel** | 1/8 | 7a Depth chart · 7f Player profile · 7c Development plan · 7d Staff profiles · 4c Staff market & profile · 7e Scheme book · 7b Personnel packages |
| **recruiting** | 3/11 | 8c Shortlist · 8d Contact & visit planner · 8e Class overview · 8g Portal hub · 8h Retention decisions · 8i Portal market · 4d NIL allocation · 8j College offseason |
| **pro** | 1/8 | 9a Cap & contracts · 9b Contract negotiation · 9c Roster cuts & transactions · 9d Pro scouting board · 9e Draft board · 9g Free agency · 9h Pro front office |
| **league** | 1/11 | 10i League map · 10h Team / programme profile · 10a Standings · 10b Schedule · 10c Rankings & playoff picture · 10d Bracket / postseason · 10e Statistics & leaders · 10f News · 10j Realignment event · 10k World search |
| **career** | 4/13 | 4a Job board · 4b Offer · 11k Opportunities · 4e Job security · 4f Coaching carousel · 11d Record book · 11e Rivalries · 11c Career line · 11f Coaching tree |
| **entry** | 0/2 | 11i New career & coach identity · 11j Appointment |

**League is the thinnest at 1 of 11, and it is also the family Press Box has learned least
about.** Ten of its eleven are tables of a kind the system has never drawn: a map, a bracket,
a standings grid, a statistics leaderboard. `WorkPlate` is built for a roster — eight columns
by six rows — and a 12-team standings table with nine numeric columns is a different problem
that will probably force a component, the way Compare forced `Versus`.

**Entry is 0 of 2 and is the riskiest omission for its size.** Both surfaces are the first
thing a player ever sees, and neither has been drawn against the register model at all.

---

## 2. Five surfaces Press Box draws that the registry does not have

These are gaps in the **registry**, found by drawing rather than by reading. Each is argued in
the design system's own `readme.md`.

| Press Box | Why it has no registry entry |
|---|---|
| **While You Were Away** | Automation halts on a threshold and hands control back. Nothing renders what happened in between, and invisible delegation is indistinguishable from a bug. |
| **Responsibilities** | Where delegation is *configured*, as against exercised. Without it every ownership line in the product is unbacked: the game says an assistant handled something, you never said he could, and you cannot take it back. |
| **Compare** | Two players, attribute against attribute. One of the genre's core verbs and **no registry screen performs it.** |
| **Season Review** | A *season* has no ending. Aftermath (6g) is per-match. In a game whose whole arc is college to pro, that is the arc's missing last page. |
| **Championship Result** | The fifth sanctioned ceremony. Bracket / postseason (10d) is a table, not a verdict. |

Adding any of these to `ScreenRegistry.swift` forces a family assignment at compile time,
which is the registry working as designed.

---

## 3. Cross-cutting features, against the sheet's own list

`Coach World.dc.html` states what **every** surface lacked:

> LIGHT APPEARANCE · AX5 TYPE SIZES · SCREEN TRANSITIONS · LOADING AND FAILURE STATES ·
> THE 166 TEAM MARKS

Where each now stands:

| Feature | State | Note |
|---|---|---|
| Light appearance | **Refused, not missing** | Dark-only by decision. Half the tokens are built on lamp and glass and would have to be re-derived rather than re-tinted. A closed decision, not a hole. |
| AX5 type sizes | **Supplied** | `tokens/a11y.css` raises the row and floor tokens; `DataRow` restacks into labelled pairs and `ColumnHead` removes itself. Expands and reflows, never shrinks. |
| Screen transitions | **Missing** | The `--dur-*` scale and one easing curve exist and Reduce Motion nils them, but **nothing specifies what happens between two surfaces.** With family-then-sibling navigation there are only two moves to specify — sibling within a family, and family switch — so this is small and unstarted. |
| Loading and failure states | **Supplied** | The four layers: First Run, Teaching, Failure, System State. The dividing line is whether the surface is still there. |
| The 166 team marks | **Plumbed, not bundled** | Components read `--club-field` / `--club-accent` / `--club-ink` and take a `mark` prop; the marks are repo assets and are owner-adopted. Not a design-system gap. |

### And one the sheet did not list

**Increase Contrast was a sentence on a screen with nothing behind it.** The Appearance
surface reports the OS setting and states its effect — *"rules and hairlines gain weight"* —
which was a claim about behaviour no token implemented. Found by auditing the drawn surfaces
against the tokens rather than by reading either.

Fixed the same day: `tokens/a11y.css` now carries a `prefers-contrast: more` branch. It steps
every hairline up one stop and drops the material, and it deliberately **does not move the
inks** — those already clear 4.5:1 on all four grounds, and lightening ink that passes would
flatten the three-step hierarchy that tells a reader what is a figure and what is a label.

---

## 4. What the design system still owes itself

| Gap | Size |
|---|---|
| 50 undrawn registry surfaces | The bulk of the work |
| Screen transitions | Two moves to specify |
| No scouting-confidence model in the engine | Contract specified in Press Box `readme.md`; blocks nothing drawn, but Compare depends on it to decide which comparisons a screen may *call* |

---

## 5. Branch survey — work that changes this answer

Checked all local and remote branches on both prefixes: **56 local, 26 remote, 11 open PRs.**

Two unmerged bodies of work bear directly on surfaces.

### `codex/mock-reconciliation-vertical-slice` — 43 commits, **local only, never pushed, no PR**

105 files, +6,553 / −810. Its commit subjects are a family-by-family sweep:

```
feat: reconcile all career and entry screens
feat: reconcile all league screens
feat: reconcile all pro management screens
feat: reconcile all recruiting screens
feat: reconcile all personnel screens
docs: make all-screen UI correction canonical
```

It carries `docs/.../2026-08-22-all-screen-shell-and-hierarchy.md` (1,225 lines) and a
270-line amendment. `codex/integrate-mock-reconciliation` is the same lineage at 45 commits,
also local only.

**This is the single most important finding of the survey.** A whole-registry reconciliation
pass exists on this machine and nowhere else — no remote, no PR, no backup. A pruned worktree
takes it with it, and this repo has pruned worktrees mid-session before. It should be pushed
before anything else in this document is acted on.

It also needs reading before drawing the 50: it may already have decided shell and hierarchy
questions that would otherwise be re-litigated surface by surface.

### `claude/missing-game-features-vcrzwz` — 46 commits, on origin, **PR #11 CLOSED unmerged**

A 34-slice gameplay completeness build — not surfaces, but the systems surfaces would read:

```
feat: put ironman and volatile on the players whose systems read them (FSC-014)
feat: make the draft read who owns the pick (G-33 tail)
feat: let difficulty actually change the game (G-42 tail)
feat: let the locker room read the room rather than the table (G-35 tail)
feat: give coaches careers, and let rivals come for them (G-31 tail)
feat: make an injury that ends a player's game actually end it (G-26 tail)
```

Its own last commit records "the run stopped mid-suite", which is presumably why the PR
closed. Whether these slices are wanted is an owner call; they are listed here because
"missing features" in the gameplay sense lives on this branch, and it is not merged.

### Everything else

The other 9 open PRs are docs, tests, portal fixes, logos and CI. None adds a surface.
`claude/implement-landscape-screens-63c2b1` is the branch the Floodlit design system was
built from — reference only, superseded by Press Box.

---

## Method

Registry extracted from the `reg` array in `Coach World.dc.html` (62 rows). Swift presence
established by mapping each `sid` to its view file in `git ls-tree main` (71 view files, 62
matched, the remainder being roots and proofs). Press Box coverage mapped by hand from the
demo exports — the two `partial` calls are judgements and are marked as such. Branch counts
from `git branch` / `git branch -r` after `git fetch --all --prune`; PR states from `gh`.
