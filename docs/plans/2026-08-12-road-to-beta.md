# Road to beta — outstanding items

**Definition of complete: a beta test on a real iPhone.** Not a simulator screenshot, not a green
suite. Everything below is what stands between the current checkpoint and a build a tester can
install and play.

Written 2026-08-12 at commit `fdc3cac`, with `./scripts/verify.sh` green at **673 tests / 747,735
checks**. `docs/STATUS.md` remains the truth for what is verified; this file is the gap list.

---

## 0. The two that decide whether there is a game to test

Everything in §1–§4 is real work. These two are the ones that decide whether a beta tester
experiences the product the design describes.

1. **The player's own match does not run the detailed engine.** `WorldScheduler`'s `userGame` step is
   inactive; every game — including the tester's — resolves through `AbstractGameSimulator`. The P3
   engine exists and is preserved but is not in the career loop. Without this the beta is a
   spreadsheet with a scoreboard, and `02` §3's agency model (call-ins, take over, hand off) has
   nothing to attach to.
2. **No screen can reach the world the engine builds.** Six view files exist against `04`'s 62
   canonical screen families. `NewsFeedReadModel` and `CoachingTreeReadModel` have zero references
   outside their own files; `WorldHistoryReadModel` has one. The living world is real and invisible.

---

## 1. Engine and simulation

| Item | State | Blocked on |
|---|---|---|
| `userGame` scheduler step | Inactive | Integrating the P3 engine into the career loop |
| FSC-011 match render anchors | Absent | Match records explain outcomes but carry no animation anchor stream |
| P4 calibration | **5–6 of 24 bands hold** | Model thinness, not constants — see §2 |
| Professional roster turnover | In progress, another session | Canon `5799344` decided it; bootstrap contracts + cap-compliance cuts |
| `contractExpiry` integrity check | Inactive (1 of 29) | Activates with roster turnover |
| FSC-014 traits | 7 names, no system consumes them | `ironman`, `workhorse`, `iceInVeins`, `frontRunner`, `mentor`, `adaptable`, `volatile` |
| FSC-008 tactical eligibility | Partial | Depth charts and role assignments do not exist |
| `expiringInboundEvents` step | Inactive | **Nothing to expire** — no inbox/correspondence state exists in the engine at all |
| Cross-season semantic narrative | Absent | The feed reports events; nothing narrates across seasons |

**Not a gap, recorded so nobody "fixes" it:** integrity refuses a root whose pending decision
deadline has passed, and nothing expires decisions. That is a hostile-save guard, not a live trap —
`advanceWeek` already refuses while any decision is unresolved, so the deadline cannot pass with one
outstanding.

---

## 2. Calibration, sorted by what each row actually waits on

`01` §6.5 states 24 bands; 16 further rows are unmeasured. They are **not one problem**, and a plan
that treats them as one will fail:

| Waiting on | Rows | Size |
|---|---|---|
| Harness aggregation | points per drive | **Done, unmeasured** — see §5 |
| Play-length accounting | TD 40+ yards, FG% 50+ yards | Small — `PlayRecord` has outcomes, needs distance buckets |
| Per-player stat lines | TE / RB / max receiver target share | **Real engine work** — P3 produces no per-player lines |
| Overtime | overtime rate, college tie rate, OT settled in one period | P6 |
| Schedule context | best-vs-worst, blowout by context (×2), margin by context, title-capable share | P6 |
| Binned distribution | modal combined total | Needs the TVD shape check |
| **Deliberately unset in canon** | college completion %, pass/rush yards, sacks, INTs, points per drive | `01` §4.9 — **not work**, do not count these |

**Sequencing is fixed by canon** (`5799344`): per-drive accounting comes *after* realignment (done)
and *outside* the M8 path, because two large engine changes at once make a red band impossible to
attribute. Tuning attempts against the current model do not count toward D2's five.

---

## 3. Persistence and performance

| Item | State |
|---|---|
| Save size | **Solved.** 306.9 MB → 36.0 MB at season 30 (8.5×); season 1 at 6.6 MB is inside the original 8 MB ceiling |
| **Encode latency** | **Open and beta-relevant.** 12.53 s at season 30 on a development Mac, before an iPhone is involved |
| Chunked / streaming persistence | Not required by size; may be required by latency |
| Save migrations | None. Schema 11 refuses every other version, so any schema change invalidates testers' saves |
| FSC-002 cold bodies | Partial — ranked-notable bodies only, within bounds |

**A beta implication that is easy to miss:** with no migration table, every schema bump destroys
existing beta saves. Either freeze the schema before testers install, or build the migration path
first.

---

## 4. Production UI (M8) — the entry gate is not met

**Entry gate, from `docs/roadmap/06`:** Coaching HQ, Recruiting Board and Match Day approved together
as interactive native-size proofs, each scoring **≥31/40** against `04b` with no P0/P1 and no
generic-application rejection.

Then 62 screen families, each bound to a defined read model, including Career Start, HQ, Team,
Scouting Room, Game Plan, Recruiting / Front Office, League, Career, Offseason, Search and the 2D
Match Center.

---

## 5. Uncommitted and unmeasured at the time of writing

`CalibrationHarness` now aggregates `DriveRecord.pointsScored` and `CalibrationBands.pro` gains
"points per drive" at `1.60 … 1.95` **[Q]**. The engine has always recorded drive points; the row
waited only on the harness summing them, so this is aggregation rather than model widening.

**It has not been measured.** The run was stopped before it reported. The next session should run
the calibration suite and record whether the value falls in band — it is real evidence about model
thinness either way.

---

## 6. Beta readiness (M9) — none of this is started

- Onboarding
- **Accessibility on a physical device** — VoiceOver, Voice Control, Switch Control, haptics and
  audio have **never** been verified on hardware. Simulator proofs do not discharge this
- Reduced motion
- Failure and recovery paths
- Performance tuning on iPhone 15-generation hardware and newer
- Device testing (the supported floor is 844×390; landscape-only is asserted by `OrientationPolicyTest`)
- Long soak
- `docs/PRE-DEPLOYMENT-CHECKLIST.md`, including the per-release blocklist refresh
- TestFlight distribution setup

---

## 7. Process debts

- **Repository-wide confidence review and rewrite tournament**, deferred by owner direction to final
  verification rather than per milestone
- **Simulator demonstration is an owner action.** An agent hands over a written walkthrough script
  and never claims the demonstration happened
- Two sessions commit to `codex/fm-touch-personnel-examples` concurrently. Stage by explicit path,
  never `git add -A`; if the other session's uncommitted work does not compile, build in a worktree
  rather than touching its files
- **Run the full suite before claiming green.** Focused gates missed a determinism pin that hashed
  the save envelope; the full run caught it

---

## Suggested order

1. **Freeze or migrate the schema** — everything else risks testers' saves until this is settled.
2. **`userGame`** — integrate the detailed engine into the career loop. Without it there is no game
   to beta test.
3. **M8 entry gate**, then the screens the loop needs: HQ, Team, Game Plan, Match Center, Career.
4. **Encode latency** on device, measured on the hardware floor rather than a Mac.
5. **Calibration**, in the canon-fixed order: per-player stat lines and play-length accounting before
   any further constant search.
6. **M9 beta readiness**, ending with accessibility on hardware and the pre-deployment checklist.
