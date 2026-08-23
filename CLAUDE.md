# CLAUDE.md — Pro Football Coach (iOS)

Standing rules for every session working in this repo. Read this first, every time.

**This file owns standing rules only:** what the project is, the document map, process, tech stack,
conventions, the legal guardrail. **It does not own the mission or the definition of done** — those
live in `docs/08-OPUS5-BUILD-PROMPT.md`. The two must not conflict; if they appear to, that is a
defect to escalate to the owner, not to resolve by picking a winner.

The rebuild is governed by `docs/reviews/2026-08-09-spec-prompt-v4.md`. Where an older document in
this repo disagrees with it, the older document is wrong.

## What this project is

A **unified college→pro football coaching career simulator** for iPhone. One save, one coach: you
start in the college game and get promoted to the pro league. The promotion arc is a v1 feature, not
a sequel.

The player is a coach, never a player. There is **no direct control of players during play** — no
arcade mode, no throwing passes. The match is watched in a 2D view and shaped by preparation and
decisions. What the player does instead of pressing buttons is the project's central design problem;
`docs/02-GAME-DESIGN.md` resolves it and `docs/OPEN-DECISIONS.md` records why.

Distribution is TestFlight then paid premium. No IAP, ads, subscriptions, analytics, accounts, or
network of any kind.

## Legal guardrail (absolute)

All schools, teams, conferences, stadiums, players, coaches, marks, logos, colours, fight songs,
traditions and broadcast identities are **fictional and original**. Never use real
school/team/player/conference names or logos. Reference titles are mechanics research only — never
copy protected expression, art, text, audio or UI.

**Real location names are permitted — owner decision 2026-08-12, generator included.** Cities and
regions may be real, in generated worlds as well as in hand-written copy, so a programme can sit in
a real city. This does not extend to venues: "Rose Bowl", "Lambeau" and "Death Valley" are marks
that happen to read as places, and they stay refused.

The line is **what kind of name it is**, not what the string says, because eight real cities are
also refused as institution names — Buffalo, Cincinnati, Houston, Kansas City, Miami, Pittsburgh,
Tulsa, Washington — each because it either is a real programme or contains one. Each is refused as
the name of a *school* and permitted as the name of the *city it plays in*. `Blocklist.blocks` is the institution-kind check and `Blocklist.blocksPlaceName` the
place-kind one; a caller picks by what it holds. Note the risk this leaves standing, which the
blocklist cannot see: a fictional programme in a real city, wearing that city's programme's
colours, can *jointly* identify the real one. The trade-dress test catches the colours; the
combination is a review obligation and a counsel question.

College football raises this bar: school identity, trade dress and player NIL are among the most
aggressively enforced IP in sport. Any route around it — bundled "community" real-name files, a
roster importer pointed at a scraped source, a wink in the store listing — is out of scope and must
not be proposed. If a feature only works with real identities, say so and propose an original
substitute. Flag anything borderline for the owner to take to counsel; never resolve it yourself.

**Two of these are tests, and they must stay green:**

1. **Name collision test** — no generated school, team, conference, stadium, player or coach name
   matches an entry in the maintained blocklist, at any seed, across N generated leagues. Most
   entries are real names. Some are **near-miss coinages nobody registered**, kept because the name
   that gets a project sued is the one a careful person reaches for while trying to be safe — see
   `02` §11.3.5's near-miss rule, and `docs/briefs/2026-08-13-name-equivalents.md` for the review
   that produced it. Generated **place** names are swept too, against the venue and person limbs only, so a
   city called Rose Bowl or Nick Saban is still refused while a city called Columbus is not. The two
   sweeps must partition every generated name between them: a name that belongs to neither kind is
   a name nothing checks, and the suite asserts the partition.
2. **Trade dress test** — no generated primary/secondary colour pair falls within the stated ΔE of a
   real programme's known pair.

Everything else in this guardrail is a review checklist item, not an assertion. Do not describe
prose as if it were a test.

## Documents

`docs/DOC-MANIFEST.md` is the authority on what is canon. Its rule has **two limbs, and quoting only
the first inverts it**: a document carries authority if it is listed there as `RETAINED` **or** is
one of the canon documents listed in its §4. **Anything else carries none**, whatever path it sits
at. **There is no archive as of 2026-08-10** — the superseded documents were deleted rather than kept, because a cold builder who opens one is the failure the manifest exists to prevent. `docs/DOC-MANIFEST.md` records what each was and why; `git show` recovers any of them.

| Doc | Purpose |
|---|---|
| `docs/DOC-MANIFEST.md` | What is canon, what is superseded, what is archived |
| `docs/01-RESEARCH.md` | Reference research, competitive set, community signal, calibration sources |
| `docs/02-GAME-DESIGN.md` | The game: core loop, agency model, both tiers, promotion arc, systems, stakes |
| `docs/03-MATCH-ENGINE.md` | Play resolution, seeding contract, off-screen model, calibration harness, soak |
| `docs/03b-ARCHITECTURE.md` | Module layout, engine/UI boundary, save architecture, test architecture |
| `docs/04-UX-AND-DESIGN-SYSTEM.md` | Design system, screens, match view, the accessibility contract |
| `*-v3.dc.html` (8 root sheets) | **The definitive design references** (owner-approved 2026-08-12): composition and states for the `04` §6.5 registry. Renders and index in `docs/proofs/design-references/`. Five first-example screen mockups (HQ, Roster, Player Profile, Recruiting Board, Match Day): `docs/proofs/screen-mockups/` (not canon, not a ninth sheet, not the full 62). A rendering — `04` still owns every value |
| `docs/04b-AUDIT-RUBRIC.md` | The audit rubric: five dimensions, 0–4 anchors, P0–P3 severities |
| `docs/05-IMPLEMENTATION-PLAN.md` | Phased build with per-phase gates |
| `docs/06-AUDIT-DISPOSITION.md` | Disposition of the prior audit's P0/P1s and systemic patterns |
| `docs/OPEN-DECISIONS.md` | Decision register D1–D14, each with an instrumented falsifier. **D11 closed 2026-08-09** |
| `docs/08-OPUS5-BUILD-PROMPT.md` | Phase-entry prompt. **Owns mission and definition of done** |
| `docs/PRE-DEPLOYMENT-CHECKLIST.md` | What must be true before a build goes out |
| `PRODUCT.md` | Positioning, audience, market gap, v1 scope |
| `docs/STATUS.md` | Honest state of the build: what exists, what is verified, what is not |
| `docs/AUDIT.md` | Prior UI audit — evidence about craft, retained read-only. **Audits a different, portrait build; never a source of design direction** |

**Doc-first amendment rule:** a gameplay question not answered in canon gets answered in canon
first, then implemented. Never encode a design decision only in code.

## Process (non-negotiable)

Plan → build small → adversarial review → verify → commit.

1. **One phase at a time.** Before starting a phase, run `superpowers:writing-plans` against that
   phase's section of `docs/05-IMPLEMENTATION-PLAN.md` to produce a bite-sized task plan. Save it to
   `docs/plans/`. Execute one phase, then stop.
2. **TDD for all engine code** (`superpowers:test-driven-development`). The engine is pure Swift with
   no UI dependency — every mechanic gets a failing test first. Views need not have unit tests but
   must compile.
3. **Frequent small commits.** One task = one commit, Conventional Commits format.
4. **Adversarial review at phase end.** Run `adversarial-reviewer` (or `/code-review`) on the phase
   diff before declaring the phase done. Fix confirmed findings first. An adversarial review is
   **not** a build and must never be reported as one.
5. **Verification before completion** (`superpowers:verification-before-completion`). The agent
   asserts the machine gates: build green, tests green, calibration bands, cross-process
   determinism, the soak, the two legal tests, touched surfaces **≥31/40 with zero P0/P1** against
   `04b` (eight dimensions, 0–5 each — the older ≥17/20 five-dimension frame was replaced by the
   owner on 2026-08-11 and the two bars are not equivalent: 31/40 is 77.5%, 17/20 is 85%). Simulator demonstration is an **owner** action — hand off a written walkthrough script,
   never claim it happened.
6. **Debugging:** `superpowers:systematic-debugging`. No guess-fixes.
7. **Scope guard.** Build what the plan specifies. No unrequested refactors, no opportunistic
   rewrites of code the phase does not touch.
8. **Delegation cap.** At most 6 concurrent subagents, no nested delegation, and no subagent is the
   sole verifier of its own work.

### When there is no Swift toolchain

Agent environments frequently have **no `swift` and no `xcodebuild`**, and the egress policy refuses
`download.swift.org`. Never route around that policy to fetch a toolchain. When it is absent:

- Write the code anyway, to the same standard.
- Record it in `docs/STATUS.md` as **unverified — never compiled**, naming the files.
- Never say "build green", "tests pass" or "verified" about anything a compiler has not seen. Phase
  4C of the prior build shipped uncompiled; the failure was not the missing toolchain, it was the
  claim. A phase gate that depends on a build is then an escalation, not a judgement call.

## Tech stack (owner-fixed — do not relitigate)

- iOS 26+, Swift 5.10+, SwiftUI. **iPhone-only, landscape-only; supported and release-tested on
  iPhone 15-generation hardware and newer.** Offline. **Zero third-party app dependencies.**
  Third-party agent skills are development tooling only and must never be linked into the app.
  - **Changed from portrait-only by the owner on 2026-08-10.** Landscape is what lets the whole
    120-yard field sit in frame at once with no camera pan — the arithmetic is in `04` §5.2 and the
    consequences for every other screen are in `04` §4. It is declared in `App/project.yml` and
    asserted by `OrientationPolicyTest`. Portrait is not a supported orientation.
- The 2D match view renders in **SwiftUI `Canvas` + `TimelineView`**. No SpriteKit, no Metal.
- **Strict engine/UI separation.** The simulation runs headless and contains zero `import SwiftUI`.
- **Determinism.** A given seed plus a given input state reproduces a match exactly, **across
  processes and app launches**. Seeds derive from identifier *bytes*, never from `hashValue`: the
  prior build seeded from `UUID.hashValue`, which is salted per launch, so one save produced a
  different league every app start and no in-process test could see it. A source-scanning test
  forbids reintroduction.
- Module layout, persistence format and test mechanism are decided in `docs/03b-ARCHITECTURE.md`
  (D7, D11). Do not assume the prior build's answers.

## Conventions

- **Coverage boundary ≠ quality boundary.** From `docs/AUDIT.md`: *"The defect is not ignorance of
  contrast; it is that the test's coverage boundary became the quality boundary."* A test that
  checks a class of surfaces must enumerate that class **by construction**, so a new surface is
  covered the day it is added rather than the day someone remembers it. Spot-check tests over
  hand-listed instances are a defect, not coverage.
- League structure for both tiers lives in `docs/02-GAME-DESIGN.md` — never hard-coded in prose here.
- Ratings are 40–99 `Int`. Money is integer dollars (`Int`) — no floating-point currency.
- Rules constants (calendar, cap, eligibility, scholarships, draft order, playoff formats) live in a
  single rules module per tier. Never inline a magic number.
- A design-token literal in a view is a defect: spacings, radii, colours and font sizes come from the
  design system in `docs/04-UX-AND-DESIGN-SYSTEM.md`.
- Every collection that can grow across seasons has a stated bound. Unbounded free-agent pools and
  news feeds took the prior build's saves to 8.3 MB; bounding them brought it to 2.3 MB.
- Files small and focused, split by responsibility (model / engine / feature view).
- Player-facing copy is short and plain, from `docs/04-UX-AND-DESIGN-SYSTEM.md`. No lorem ipsum.
- No emoji in code, UI copy, commits or docs.

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **Pro-Football-Coach** (18859 symbols, 87924 relationships, 300 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> Index stale? Run `node .gitnexus/run.cjs analyze` from the project root — it auto-selects an available runner. No `.gitnexus/run.cjs` yet? `npx gitnexus analyze` (npm 11 crash → `npm i -g gitnexus`; #1939).

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows. For regression review, compare against the default branch: `detect_changes({scope: "compare", base_ref: "main"})`.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `query({search_query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `context({name: "symbolName"})`.
- For security review, `explain({target: "fileOrSymbol"})` lists taint findings (source→sink flows; needs `analyze --pdg`).

## Never Do

- NEVER edit a function, class, or method without first running `impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `rename` which understands the call graph.
- NEVER commit changes without running `detect_changes()` to check affected scope.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/Pro-Football-Coach/context` | Codebase overview, check index freshness |
| `gitnexus://repo/Pro-Football-Coach/clusters` | All functional areas |
| `gitnexus://repo/Pro-Football-Coach/processes` | All execution flows |
| `gitnexus://repo/Pro-Football-Coach/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
