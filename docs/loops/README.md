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

Twenty-one aspects, nineteen loops. `scripts/check-loops.mjs` asserts the partition — every aspect names
at least one loop, and every loop is named by at least one aspect. This mirrors the legal suite's own
rule, that the institution-kind and place-kind sweeps must partition every generated name between them,
because a name that belongs to neither kind is a name nothing checks.

| # | Loop | Category | Aspect covered |
|---|---|---|---|
| 901 | Determinism drift hunt | engineering | Determinism and seeding |
| 902 | World generation invariant widening | engineering | World generation and identity |
| 903 | Legal partition sweep | evaluation | Legal guardrail |
| 904 | Match engine oracle widening | engineering | Play resolution, clock, anchors |
| 905 | Calibration band tightening | evaluation | Calibration bands |
| 906 | Two-tier agreement gate | evaluation | Detailed vs abstracted consistency |
| 907 | Season transition fuzz | engineering | Season structure and competition |
| 908 | College acquisition legality sweep | engineering | Recruiting, portal, eligibility, scholarships |
| 909 | Pro front office legality sweep | engineering | Cap, contracts, draft, depth chart |
| 910 | People lifecycle drift watch | evaluation | Progression, decline, injury, tenure |
| 911 | Career arc continuity hunt | engineering | Career arc, promotion, stakes |
| 912 | Architecture boundary scan widening | engineering | Architecture boundaries |
| 913 | Save durability hunt | engineering | Persistence and migration |
| 914 | Soak horizon extension | evaluation | Long-horizon soak and bounds |
| 915 | Performance budget instrumentation | evaluation | Performance budgets |
| 916 | Accessibility matrix widening | design | Accessibility contract |
| 917 | Design token discipline sweep | design | Design system discipline |
| 918 | Surface truthfulness audit | design | Read-model truthfulness; screen reachability |
| 919 | Release gate traceability loop | operations | Gate traceability; documentation truthfulness |

## Where to start

The loops are independent, but three of them close gaps that are visible in the tree right now rather
than hypothetical, so they are the ones with something concrete to bite on:

- **919** — `SuiteCatalog.runner` returns `nil` for four registered gates: `AgencyBudgetTests`,
  `PerformanceBudgetTests`, `TwoTierConsistencyTests` and `SmallestDeviceLayoutTest`. Three of those are
  named in `PRODUCT.md`'s commitment table. `CommitmentCoverageTest` asserts both that every commitment
  names a gate with a runnable command and that no registered gate lacks one, so on a plain reading of
  the source the `--commitment-coverage` suite should be failing today. That reading has not been run
  here — see the caveat below.
- **906** and **915** build two of those four runners.

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
  run. `scripts/check-loops.mjs` is Node and was run: 19 loops, 21 aspects, schema and partition clean,
  and it was negative-tested against a dangling reference, an empty aspect, an unmapped loop, a drifted
  register and an over-length field, failing correctly on each.
- **The published Loop Library catalog was never read** — the domain is egress-blocked. Overlap with
  published loops is therefore unchecked, and these are project-local records, not published entries.
  The `901`–`919` block is a local numbering; Loop Library numbers are assigned at publication.
- **The failing-gate reading in "Where to start" is a reading of the source, not a test result.**
