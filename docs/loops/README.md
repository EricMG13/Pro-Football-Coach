# Loop series — hunting unknown faults

A series of repeatable agent loops covering every aspect of the game, each designed to find and patch
faults that **no current assertion is shaped to detect**.

**These files carry no canon authority.** `docs/DOC-MANIFEST.md` is the authority on what is canon, and
nothing here amends a design decision. A loop that turns out to need one stops and escalates.

| File | What it is |
|---|---|
| `LOOPS.md` (repository root) | The register an agent reads: name, summary, exact prompt, per loop |
| `docs/loops/catalog.json` | The full records — steps, verification, rationale — in the Loop Library publication schema |
| `docs/loops/aspects.json` | The aspect map, as data, so the validator and a reader enumerate the same list |
| `scripts/check-loops.mjs` | Validates the schema, the references and the partition; `--write-register` regenerates `LOOPS.md` |

## What a loop is

Method and record format follow the Loop Library at <https://signals.forwardfuture.com/loop-library/>
(Forward Future, MIT). A loop is not a prompt run once. It is a bounded feedback cycle — observe,
choose, act, verify, record, repeat or stop — with an **observable acceptance check** and a **named
terminal state**, so the agent knows when the work is actually finished instead of running until
someone notices.

The published catalog was unreachable from this environment: `signals.forwardfuture.com` and
`signals.forwardfuture.ai` are both refused by the network egress policy. The schema and the design
rules below were taken from the project's public source, `Forward-Future/loop-library` at commit
`75966cb` — `loop-library/worker/src/loop-schema.js` for the record shape, `skills/loopy/SKILL.md` and
`skills/loopy/references/` for the feedback-cycle and grounding rules.

## Why these loops widen the detector before running it

The brief was **unknown** faults, and that constrains the design more than it first appears.

Running `./scripts/verify.sh` finds faults the suite already knows how to see. By definition, an unknown
fault is one that sits outside the current coverage boundary — so no number of passes over the existing
gates will reach it. The only pass that can is one that **moves the boundary first**.

Every loop in this series therefore has the same spine:

> widen the oracle by construction → run it → patch what it exposes → re-run → stop when a pass widens
> coverage and finds nothing, twice.

That gives an honest no-progress stop, and it is this project's own stated convention rather than an
imported one. From `docs/AUDIT.md`, quoted in `CLAUDE.md`:

> The defect is not ignorance of contrast; it is that the test's coverage boundary became the quality
> boundary.

A loop that only re-runs a gate cannot fail this way because it never claimed to look anywhere new. A
loop that widens can, which is exactly why the widening has to be proved: several loops require adding a
deliberately violating input, watching the check fail, and removing it. A check that passes both before
and after has not been widened.

## Coverage

Twenty-eight aspects, twenty-five loops. `scripts/check-loops.mjs` asserts the partition — every
aspect names at least one loop, and every loop is named by at least one aspect. This mirrors the legal suite's own
rule, that the institution-kind and place-kind sweeps must partition every generated name between them,
because a name that belongs to neither kind is a name nothing checks.

| # | Loop | Category | Aspect covered |
|---|---|---|---|
| 901 | Determinism drift hunt | engineering | Determinism and seeding |
| 902 | World generation invariant widening | engineering | World generation and identity |
| 903 | Legal partition sweep | evaluation | Legal guardrail |
| 904 | Match engine oracle widening | engineering | Play resolution, clock, anchors |
| 905 | Calibration band tightening | evaluation | Calibration bands; two-tier holdout |
| 907 | Season transition fuzz | engineering | Season structure and competition |
| 908 | College acquisition legality sweep | engineering | Recruiting, portal, eligibility, scholarships |
| 909 | Pro front office legality sweep | engineering | Cap, contracts, draft, depth chart |
| 910 | People lifecycle drift watch | evaluation | Progression, decline, injury, tenure |
| 911 | Career arc continuity hunt | engineering | Career arc, promotion, stakes |
| 912 | Architecture boundary scan widening | engineering | Architecture boundaries |
| 913 | Save durability hunt | engineering | Persistence and migration |
| 914 | Soak horizon extension | evaluation | Long-horizon soak and bounds |
| 915 | Performance budget potency | evaluation | Performance budgets |
| 916 | Accessibility matrix widening | design | Accessibility contract |
| 917 | Design token discipline sweep | design | Design system discipline |
| 918 | Surface truthfulness audit | design | Read-model truthfulness; screen reachability |
| 919 | Release gate traceability loop | operations | Gate traceability; documentation truthfulness |
| 920 | End-to-end journey walk | engineering | End-to-end player journeys |
| 921 | Dead control sweep | design | Control liveness |
| 922 | Gate potency sweep | evaluation | Gate potency |
| 923 | CI lane routing audit | operations | Continuous integration routing |
| 924 | Packaging and submission readiness | operations | Packaging and submission |
| 925 | Branch integration convergence | operations | Branch integration |
| 926 | Owner gate evidence pack | operations | Owner gate evidence |

**906 was retired on 2026-08-23, and the gap in the numbering is deliberate.** It existed because
`TwoTierConsistencyTests` was registered with no runner. Codex built the runner in `6fb24da`: real TOST,
`expect(result.passed, …)`, tuning and holdout seeds asserted disjoint, and an empty `uncoveredMetrics`
list. The loop's premise no longer holds, so the loop is gone rather than reworded. Its aspect now points
at 905, which shares the instrument, and at 922, which checks the gate still bites. Numbers are
identifiers; renumbering the rest would break every reference to make the sequence tidy.

## Companion runs

Six loops carry a **companion prompt**: 905, 907, 910, 914, 915 and 920. Their verification is a soak, a
sweep or a timing run measured in tens of minutes — the history lane alone runs up to about an hour and a
half — and an agent that sits through one has spent the pass waiting rather than widening.

The companion is a second prompt on the same record, not a loop of its own. It names the exact commands,
takes the commit as an argument, and **reports without fixing**, so the parent loop can keep working while
it runs and the two halves cannot race on the same tree. Companion prompts also carry the two traps this
project has already been caught by: `-c release` is required or the figures are meaningless, and a run is
complete only when it prints the suite summary line, because a lane can abort mid-run, print nothing and
exit with an ordinary non-zero status that reads as an honest failure.

A companion never widens a detector, so it can be handed to a cheaper agent, queued behind other work, or
run overnight. What it must not do is report a lane it did not watch finish.

## Where to start

The loops are independent, but four of them close gaps that are visible in the tree right now rather than
hypothetical, so they are the ones with something concrete to bite on:

- **922** — the only loop that checks whether a green gate means anything. Two registered gates cannot
  fail today: `PerformanceBudgetTests` prints `no pass/fail threshold` and asserts only the league size,
  while week advance measures over its own 2.0 s ceiling; and the calibration lane validates TOST
  mechanics, seed separation and result counts without asserting that any band holds. A third pattern
  sits in `LegalTests.swift:246-247`, where a set is compared to its own definition.
- **924** — three submission resources are absent from the tree, and none is a code change: no
  `AppIcon.appiconset`, no `PrivacyInfo.xcprivacy`, no `ITSAppUsesNonExemptEncryption`. `App/project.yml`
  also sets `sources: [.]`, which packages build databases and compiler artefacts into the app.
- **923** — `.github/workflows/tests.yml` is one job running `./scripts/verify.sh` with no lane. The
  `soaks`, `calibration`, `accessibility`, `archive`, `release` and `app` lanes all exist and none of them
  is ever scheduled, so the soaks backing the 8 MB save commitment have never run in CI.
- **925** — this series was written on a branch that fell 359 commits behind the trunk, which is how three
  of its original loops came to open on premises that had already been closed. Two agents also built the
  same two-tier gate twice, on separate branches, and only one landed.

**These four are confirmed against the tree, not inferred.** They were re-checked on 2026-08-23 against
`main`, which is also when 906 was retired and 915 re-aimed for the same reason: the tree had moved and
the loops had not.

## Running one

```
node scripts/check-loops.mjs          # validate the series
sed -n '/^### 906/,/^### 907/p' LOOPS.md   # read one loop's prompt
```

Hand the prompt to an agent with the repository in scope. The standing rules at the top of `LOOPS.md`
apply to every loop and do not need repeating in the request.

## What has not been verified

- **No Swift toolchain and no `xcodebuild` in this environment**, and the egress policy refuses
  `download.swift.org`. Not one loop in this series has been executed, and no claim here rests on a test
  run. `scripts/check-loops.mjs` is Node and was run: 25 loops, 28 aspects, schema and partition clean,
  and it was negative-tested against a dangling reference, an empty aspect, an unmapped loop, a drifted
  register and an over-length field, failing correctly on each.
- **The published Loop Library catalog was never read** — the domain is egress-blocked. Overlap with
  published loops is therefore unchecked, and these are project-local records, not published entries.
  The `901`–`926` block is a local numbering; Loop Library numbers are assigned at publication.
- **The findings in "Where to start" are read from the tree, not from a test run.** Absent files, the
  workflow's contents, `sources: [.]` and the two vacuous gate bodies were each read at `main` on
  2026-08-23. That a gate cannot fail is a reading of its source; 922 exists to *prove* it by deliberate
  violation, and that proof has not been performed.
- **No companion run has been executed.** The commands they name are the ones the lanes already accept,
  but no soak, sweep or timing run in this series has been watched to its summary line from here.
