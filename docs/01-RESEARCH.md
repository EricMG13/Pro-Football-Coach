# 01 — Research: the evidence base

> **Visual-reference boundary (owner correction, 2026-08-12):** §6.1 studies Football Manager
> Mobile as market evidence; it is not the UI target. Management UI follows the owner-supplied
> desktop Football Manager captures and the Football Manager Touch interpretation locked in
> `docs/04-UX-AND-DESIGN-SYSTEM.md`.

**What this document is.** The single evidence base for the ground-up rebuild specified in
`docs/reviews/2026-08-09-spec-prompt-v4.md`. It is Deliverable 1 of that brief. `02-GAME-DESIGN.md`,
`03-MATCH-ENGINE.md`, `03b-ARCHITECTURE.md`, `04-UX-AND-DESIGN-SYSTEM.md`, `PRODUCT.md` and
`docs/OPEN-DECISIONS.md` all cite it. Nothing in those documents should assert a fact about the
market, the sport, a competitor or the previous build that does not trace to a section here.

**It is deliberately long.** It is not a summary and must not be compressed into one. Where a
downstream document needs a number, it cites the section and inherits that section's evidence grade.

**Compiled:** Part One 2026-08-08; Part Two 2026-08-09. Both by Fable 5.

---

## Reader's guide — the two halves

This document has two halves that were produced under different conditions and carry different
evidence grades. Read the half you need, and read its method section before quoting it.

**Part One — prior research, carried forward (2026-08-08).** The original `01-RESEARCH.md`. It is
the reference-app screen inventory, the Achi Jones game-family lineage, the community signal mined
from the App Store and r/FootballCoach, the owner's working patterns, the legal guardrails, and a
deep mining of user comments on the closest shipping competitor. Tier B of the governing brief
carries sections **A, B, C, D, F and H forward verbatim or with additions only** — they are not
superseded by Part Two and must not be dropped. Sections **E and G are superseded**; they are
retained in place, annotated with a pointer to what replaced them, and must not be cited as current.

**Part Two — v4 research (2026-08-09), §6.0–§6.5.** Seven research parts written to answer §6 of the
governing brief. They are longer, sourced per claim, and each opens with a method section stating
exactly what its evidence can and cannot support. §6.0 is repo-primary (source-level census, every
claim carrying a `file:line`). §6.1–§6.3 and §6.5 are search-layer-derived — real pages, surfaced by
search, **not read in full**, because the container's egress proxy refuses direct page fetch. §6.4
mixes repo-primary extraction with search-layer public data. §6.3 contains no new research at all;
it is an argument assembled from the others.

**The two halves disagree in places, and the disagreements are the interesting part.** Part One §E
concludes the modern pro-sim lane on iOS is empty; Part Two §6.2B §5.1 found a shipping iOS
incumbent nobody had found, and §6.3 rebuilds the positioning claim around a quality gap instead of
a category gap. Part One §H concludes that nobody in the college-sim community asks for arcade play;
Part Two §6.2B §2 establishes the scale of the audience that does. Part One §G's "our responses"
column is void, because direct player control is out of scope under the v4 mission. Where the halves
conflict, **Part Two wins on market and competitor facts, Part One wins on the reference app and the
community it serves**, and the conflict is named at the point of use.

### Section map

| § | Title | Half | Grade | Status |
|---|---|---|---|---|
| A | Reference app — "College Football Simulator" (iOS) screen inventory | One | Primary (68 screenshots) | Carried forward |
| B | Game family — Achi Jones "Football Coach" lineage | One | Secondary | Carried forward |
| C | Community signal (r/FootballCoach, Play reviews) | One | Secondary | Carried forward; extended by §6.2A §7 |
| D | Prior-session extraction (owner's working patterns) | One | Primary (session history) | Carried forward |
| E | Competitive positioning | One | Secondary | **SUPERSEDED by §6.3** |
| G | Retro Bowl mechanics research | One | Secondary | **SUPERSEDED by §6.2B §2–3** |
| H | Reference-app user comments mined (App Store + r/cfbsimulator) | One | Secondary, high volume | Carried forward; extended by §6.2A §7, §6.2B §6 |
| F | Legal guardrails | One | Constraint | Carried forward; extended by §6.2A §5.5, §6.4 §7 |
| 6.0 | Engagement post-mortem on the build that exists | Two | **Repo-primary**, `file:line` throughout | Static half complete, experiential half **not run** |
| 6.1 | Football Manager Mobile, specifically | Two | Search-layer | Complete |
| 6.2A | The deep-sim competitive pole (DDS, FOF, Wolverine) | Two | Search-layer | Complete |
| 6.2B | The arcade pole and the mobile-native competition | Two | Search-layer | Complete |
| 6.3 | The market gap, argued as an output | Two | Derived from 6.0–6.2, 6.5 | Complete |
| 6.4 | Statistical calibration targets, both tiers | Two | Repo-primary + search-layer | Complete; college gaps named, not guessed |
| 6.5 | 2D match presentation without direct control | Two | Search-layer + two READMEs read in full | Complete; four items unrun |
| 6.6 | Football Manager UI reference read (owner-supplied screenshots) | Two | **Primary (18 screenshots)**, provenance unverified | Complete; settles AS-6.5-07 against the assumption |

### What each Part Two section is *for*

- **§6.0** is the only primary evidence about the actual failure. It is what §3 (attack the
  diagnosis) and §4 (gate zero) argue from. Its headline: the management week contains exactly one
  mandatory decision, nothing ever arrives asking the player to decide, jeopardy updates once a
  season, and the arcade layer held ~99% of the build's decision volume.
- **§6.1** answers why FM Mobile is not called bland despite being a menu-driven application, and
  contains the non-transferability table (soccer's continuous flow versus American football's
  per-snap surface) that gate zero turns on.
- **§6.2A** tests D10's premise and finds it half-right: AI is the dominant *ceiling* complaint;
  presentation, performance and stability are the dominant *entry* complaints. It also locates the
  sharpest unclaimed design position found in this research — delegation as an assistant coach with
  standing instructions and escalated exceptions, rather than grind-or-abdicate.
- **§6.2B** is the cross-title pattern set: watched-without-input possessions are universally
  disliked even inside beloved games; AI decision quality fails credibly in four independent
  products; player-paced advance at snap granularity is the throughput mechanism that works.
- **§6.3** is the positioning argument, and it argues *against* two things the project assumed.
- **§6.4** is the input to the calibration harness `03-MATCH-ENGINE.md` must contain. It extracts
  the inherited bands verbatim from the test source, names four structural defects in that harness,
  refines the pro tier, and builds the college tier from scratch.
- **§6.5** is the rendering specification input: what a dot-based view can honestly draw, how many
  moving marks a viewer can follow, the field geometry arithmetic, and what the `Canvas` becomes
  under Reduce Motion and VoiceOver. **Its §6 was written against a portrait constraint the owner
  lifted on 2026-08-10; §6.5 carries the correction and `04` §5.2 carries the current numbers.**

### Standing caveats that apply to the whole of Part Two

1. **No competing product was installed or played, on any platform, by anyone.** Nothing in Part Two
   is a play impression of any competitor. **Amended 2026-08-09 by §6.6:** still true of *played*,
   no longer true of *seen* — §6.6 reads eighteen owner-supplied Football Manager screenshots
   directly. Everything outside §6.6 remains unsighted.
2. **No page was read in full** except two GitHub READMEs (§6.5) and the repository's own source.
   `WebFetch` is refused by the egress proxy for every domain this research needed. All external
   content arrived through the search-summarisation layer. Every bracketed quotation must be
   re-verified against its URL on an unrestricted machine before it appears in `PRODUCT.md`,
   `02-GAME-DESIGN.md` or a store listing.
3. **Reddit is unreachable from this environment.** r/FootballCoach and r/cfbsimulator were both
   named in the brief; neither could be reached. Part One §C and §H are therefore the *only* Reddit
   evidence in this document, and they predate v4. §6.2B names this as the one gap in the evidence
   base worth closing.
4. **No Swift toolchain, no Xcode, no simulator.** Verified, not assumed. The build cannot be run
   here, which is why §6.0's experiential half is a protocol handed to the owner rather than a
   result.

---

## Consolidated assumptions register

Every claim in this document that is labelled as something other than sourced, gathered in one
place, per §6 of the governing brief: *"Claims you cannot source are labelled assumption and listed
together so the owner can see what the design rests on."*

**Counts.** 69 register entries. **29 are labelled ASSUMPTION** — a claim with no source, asserted
because the design needs a number. The other 40 carry weaker labels:

| Label | Count | Meaning |
|---|---|---|
| ASSUMPTION | 29 | No source. The design rests on a number nobody checked. |
| UNVERIFIED / UNVERIFIED [U] | 14 | Believed true; single-source, unconfirmable, or reached only through the search-summarisation layer. |
| DERIVED | 9 | Arithmetic or logic performed here, inputs cited. Falsifiable by re-doing the arithmetic. |
| UNRUN | 4 | Research the search budget cut off. Not a claim — an absence. |
| NOT-RETRIEVED | 3 | A named corpus the environment could not reach (Reddit, twice; one stats page). |
| UNSOURCED-CARRIED | 2 | Part One material that predates the per-claim sourcing convention. |
| NEGATIVE-RESULT | 2 | "We looked and found nothing." Weak by construction. |
| UNRESOLVED | 2 | Sources conflict and were not adjudicated. |
| NOT-RUN | 1 | A specified protocol that has not been executed. |
| INFERRED | 1 | A reason attributed to a third party from a pattern, not from their statement. |
| NOT-MEASURED | 1 | No competitor was played, by anyone. |
| UNSET | 1 | A band deliberately left empty rather than guessed. |

Three entries (AS-6.3-01, AS-6.3-02, AS-6.3-07) are the same underlying claim inherited into a later
section, so the number of **distinct** non-sourced claims is **66**.

**How to read the label column.** ASSUMPTION is the one that should make the owner uncomfortable —
it means the design rests on a number nobody checked. DERIVED means the inputs are cited and the
arithmetic is shown; it is falsifiable by re-doing the arithmetic. NOT-RETRIEVED and NOT-RUN are
work that was not done, not claims that were made.

### Part One — carried-forward material

| ID | Label | Claim | Where it bites | How to settle |
|---|---|---|---|---|
| CF-1 | UNSOURCED-CARRIED | Part One carries **no per-claim source URLs**. It was compiled from 68 screenshots, the GitHub repos, Play Store pages and r/FootballCoach, but individual figures (star ratings, install counts, version numbers, review shares) are not individually cited. | Any Part One number quoted into `PRODUCT.md` or `02-GAME-DESIGN.md`. | Re-verify each number at point of use; do not bulk-import. |
| CF-2 | UNSOURCED-CARRIED | §H's quantitative mining — 4.78★/625 US ratings, 86 reviews, 395 posts, 1,312 comments, 34% crash share, 42% dev reply rate, median 2.2 h — is an analysis whose corpus is not reproducible in this container and was not re-run for v4. | §H's complaint league table, which drives four v1 features. | Re-run the mining on a machine with Reddit and App Store access. |
| CF-3 | NEGATIVE-RESULT | §D's *"no prior football/iOS/game sessions exist"* is a negative from a session search. Absence of evidence in a partially-searchable corpus. | Only §D's own framing; low stakes. | None needed. |

### §6.0 — Engagement post-mortem

| ID | Label | Claim | Where it bites | How to settle |
|---|---|---|---|---|
| AS-6.0-00 | NOT-RUN | **The experiential half of §6.0 has not been run.** No Swift toolchain exists in this container, so nothing in §6.0 is a play impression; every claim is derived from reading source with a `file:line` citation. Worse, the arcade code in `HEAD` is not the code the owner played — the all-22 rewrite landed after `AUDIT.md`'s commit — so a protocol run against `HEAD` measures a third thing nobody has ever run. | Everything §3 and §4 of the brief argue from. It is the single largest hole in the evidence base. | Run §6.0 §8's protocol on the owner's Xcode machine and report against it, including the disconfirming parts. |
| AS-6.0-01 | ASSUMPTION | ~65 offensive snaps per game in the existing engine. | §6.0 §3.3's decision arithmetic and the §4 season-time budget both scale on it. | Instrument `GameRecord.plays` on a real run; §4 must declare the figure anyway. |
| AS-6.0-02 | ASSUMPTION | The player checks `Job security` more than once per season. | §6.0 §5.1's "frozen gauge" conclusion assumes it is looked at. | §6.0 §8 Probe P4. |
| AS-6.0-03 | ASSUMPTION | An honest player does not voluntarily re-do depth-chart work with no feedback. | Underpins §6.0 §4.2's "not done" verdict on consequence visibility. | §6.0 §8 probe B4. |
| AS-6.0-04 | ASSUMPTION | 4C (`HEAD`) has still never been compiled since `STATUS.md` was written. | Governs whether the §8 protocol can run against `HEAD` at all. | §6.0 §8 Probe P7b — one command. |
| AS-6.0-05 | ASSUMPTION | The repeated season-goal XP payout actually fires at runtime and is not suppressed by something the census missed. | Would change the progression-curve conclusion in §6.0 §4.4. | §6.0 §8 Probe P6's level check. |

### §6.1 — Football Manager Mobile

| ID | Label | Claim | Where it bites | How to settle |
|---|---|---|---|---|
| AS-6.1-01 | ASSUMPTION | Taps and decisions per week in FMM. No published count exists; §6.1 §1.3 is derived from the manual's surface list, the delegation options and community descriptions of the routine loop. | The week-throughput comparison that gate zero uses as a benchmark. | Owner plays FMM for one season and counts. |
| AS-6.1-02 | ASSUMPTION | Intervention rate during an FMM match is ~3–6 acts. Derived in §6.1 §3.4 from community advanced guidance; no published figure. | The "how often should the game ask the player something" target. | Same play session. |
| AS-6.1-03 | ASSUMPTION | An FMM "Key moments" match contains 8–15 highlights. Not published; used only as a comparison and flagged at the point of use. | §6.1 §8's highlight-filter argument. | Same play session. |
| AS-6.1-04 | DERIVED | Per-match wall-clock of ~4–13 min, computed from player-reported season times (3–10 h+) divided by an assumed ~46-fixture English season. Both inputs approximate. | §6.1 §2.3's inversion of the project's session-length assumption. | Re-do with a measured fixture count. |
| AS-6.1-05 | INFERRED | The reasons given in §6.1 §5's removal table. Only rows 3, 4 (partially), 11 and 14's counterpart have community- or SI-stated reasoning; the rest is inference from the pattern. | Any argument of the form "SI removed X because Y, so we should too." | Read SI's own release notes on an unrestricted machine. |
| AS-6.1-06 | UNVERIFIED | Evidence-quality caveat: no page was read in full. Forum claims cannot be attributed to a named poster or date, and paraphrase context may be lost. | Any §6 or §7 claim in §6.1 that would move a decision on its own. | Owner re-verifies the specific claim against its URL. |
| AS-6.1-07 | NOT-RETRIEVED | Reddit is entirely absent from §6.1 — the search tool is blocked from `reddit.com`. Player voice is FMM Vibe and the SI forums only. | The breadth of the player-voice sample. | Re-run on a machine with Reddit access. |

### §6.2A — The deep-sim pole

| ID | Label | Claim | Where it bites | How to settle |
|---|---|---|---|---|
| AS-6.2A-01 | UNVERIFIED [U] | **Mobile availability of Draft Day Sports.** TapTap carries "for Android/iOS" listings for DDS:CFB 2024 and DDS:PF 2025 and gmgames' publisher profile lists iOS; the Steam listings are Windows. Neither store could be reached to adjudicate. | Do **not** use "there is no deep sim on iOS" as a positioning claim until this is checked — it is exactly the claim a reviewer will test. Also §6.3 §1(b) and §4.1. | Owner checks the App Store directly for the publisher. |
| AS-6.2A-02 | UNVERIFIED [U] | DDS:PF 2025's 46% / 13-review score as a quality signal. At n=13 this is noise; reported for completeness only. | Must not appear in `PRODUCT.md`. | Ignore, or wait for a larger n. |
| AS-6.2A-03 | UNVERIFIED [U] | *"The community for the game is dead"* (DDS:PF single-player criticism). Single source, unverifiable, and contradicted by an active phpBB board and annual releases. | Any claim about competitor abandonment. | Discard unless corroborated. |
| AS-6.2A-04 | UNVERIFIED [U] | The exact wording of the FOF "500–1,000 hours" engagement wall. The substance — a stated engagement ceiling discussed alongside multiplayer-league support — is what is relied on. | D8's long-run-engagement argument. | Re-verify before the number is quoted in canon. |
| AS-6.2A-05 | ASSUMPTION | Recruiting costs hours per season at full fidelity in DDS:CFB. Derived from 15–16 allocation passes × a multi-screen pass each. No measured figure found. | §6.2A §4, and through it the college-tier P4 budget. | Time a season in DDS:CFB, or accept the order of magnitude. |
| AS-6.2A-06 | ASSUMPTION | The "entry-killer versus ceiling-killer" split is the author's synthesis. The individual complaints are sourced; the two-bucket model and the ordering claim (*a solo developer dies of the entry-killers first*) are an argument, not a finding. | D10's sequencing, and therefore what gets cut when the schedule slips. | Treat as an argument; test by shipping order. |
| AS-6.2A-07 | ASSUMPTION | The A1 > A4 > A2 > A3 triage ordering for the four AI systems. Argued from the recurrence of valuation complaints and the exploitability argument; not measured. | D10's build order. | Instrument each AI system separately, then re-rank. |
| AS-6.2A-08 | NEGATIVE-RESULT | *"Bound For Glory" does not exist as a football management title.* A sourced negative, and negatives are weak; Bowl Bound College Football was substituted. | Only the completeness of the competitive set. | Owner supplies a developer or store link, and §6.2A §1.4 is redone. |
| AS-6.2A-09 | UNVERIFIED | Every bracketed quotation in §6.2A reached the author through the search-summarisation layer, not from the source page. | Any quotation reused in `PRODUCT.md`, `02-GAME-DESIGN.md` or a store listing. | Re-verify against the URL on an unrestricted machine. |

### §6.2B — The arcade pole and mobile-native competition

| ID | Label | Claim | Where it bites | How to settle |
|---|---|---|---|---|
| AS-6.2B-01 | DERIVED | Retro Bowl season time ≈ 2.6–3.7 h. Arithmetic from a sourced ≤8 min/game, a 17+1-week season and a 14-team playoff. Management time per week is an estimate, not sourced. | The P4 comparison — what a shipped mobile football season actually costs. | Time a season. |
| AS-6.2B-02 | DERIVED | Retro Bowl offensive snaps per game ≈ 20–30. Inferred from game length, quarter length and offence-only play; no source states a snap count. Lower confidence than the time figure. | The presentation-time term in the §4 arithmetic. | Count snaps in one game. |
| AS-6.2B-03 | DERIVED | Retro Bowl College season time ≈ 2.0–2.4 h, from the sourced 14-game season plus playoff/bowls at the same per-game length. | Same as AS-6.2B-01, college tier. | Time a season. |
| AS-6.2B-04 | DERIVED | *The animation must be cuttable at snap granularity.* Inferred from FC:CD's play-paced advance plus the presentation-time term. No source states it. | §6.5 rendering rule 13, and the `Canvas` architecture. | It is a design rule, not a fact; validate by owner timing protocol. |
| AS-6.2B-05 | ASSUMPTION | Retro Bowl College's rivalries have no mechanical effect. Store and press copy describe them as *"historic rivalries that add excitement and intensity"*; no source describes a mechanical consequence — but absence of evidence in marketing copy is weak. | D6, if it leans on "nobody has made rivalry mechanical on mobile." | Play the game. |
| AS-6.2B-06 | ASSUMPTION | Football Coach: Winning Tradition has no 2D field view. No screenshot description or review in any surfaced source mentions one, and the developer's copy is management-oriented. | §6.3 §3.4's category claim — that a 2D match view on a phone in this genre is unoccupied. | Open the App Store listing's screenshots. |
| AS-6.2B-07 | UNRESOLVED | Retro Bowl's "Auto Play" option. Third-party guides reference an autoplay toggle; the Fandom Options page content surfaced did not confirm it, and one source doubts it exists in the base game. **Do not cite it.** Per-game simulate from the schedule screen *is* confirmed. | The delegation-affordance comparison. | Play the game. |
| AS-6.2B-08 | UNRESOLVED | Winning Tradition rating counts. Two snapshots surfaced (4.6★/25 and 4.5★/53), presumably different storefronts or dates. Treat as "small and growing", not a precise figure. | §6.3 §6 leg 6, and how urgent the iOS lane is. | Check both storefronts on one date. |
| AS-6.2B-09 | NOT-RETRIEVED | Reddit. r/RetroBowl and r/FootballCoach were both named in the brief; neither is reachable. Community signal is from stores, Metacritic, Steam, Operation Sports and enthusiast press instead. **Named as the one gap in the evidence base worth closing.** | Breadth of the community-complaint corpus, which is the highest-value secondary signal available. | Re-run the query with Reddit access. |
| AS-6.2B-10 | NOT-RETRIEVED | FC:CD median hours played. `byhoursplayed.com` and `gamalytic.com` both index it and would give a real throughput distribution instead of the developer's "<1 hour or a whole week" range. Both surfaced, neither readable. | The season-throughput evidence for the closest design comparable. | Fetch either page on an unrestricted machine. |

### §6.3 — The market gap

| ID | Label | Claim | Where it bites | How to settle |
|---|---|---|---|---|
| AS-6.3-01 | ASSUMPTION (inherited — same claim as AS-6.2B-06) | Winning Tradition has no 2D field view. | §6.3 §3.4 weakens if wrong. | Open the App Store listing. |
| AS-6.3-02 | UNVERIFIED (inherited — same claim as AS-6.2A-01) | Draft Day Sports' mobile availability. | §6.3 §1(b) and §4.1. | Search the App Store for the publisher. |
| AS-6.3-03 | DERIVED | **The demand signal for a unified college→pro career is close to absent.** A negative drawn from four community corpora that were themselves reached through a search layer, with Reddit unreachable. Absence of evidence in a partially-sampled corpus is weak evidence. | **P2 directly.** This is the evidence behind escalating the promotion arc as a scope question. | Re-run against r/FootballCoach and r/cfbsimulator with Reddit access. |
| AS-6.3-04 | DERIVED | *The gap is a quality gap at an intersection, not a category gap.* The central synthesis of §6.3. Each occupancy row in §6.3 §1 is sourced; the conclusion that the **conjunction** is what is unoccupied is an argument. | `PRODUCT.md`'s entire positioning. | It is an argument; attack it, do not measure it. |
| AS-6.3-05 | DERIVED | The three-persona segmentation in §6.3 §2. The complaints are sourced verbatim from review corpora; grouping them into three players with distinct current products is a construction. No segmentation study exists, and under P5 none will. | `PRODUCT.md`'s audience section. | Accept as a design fiction, labelled. |
| AS-6.3-06 | ASSUMPTION | Winning Tradition's rating count (25–53) indicates a *young* product rather than a *rejected* one. | If it is instead a product the market has seen and declined, §6.3 §6 leg 6 weakens considerably and §6.3 §1(a) is less urgent. | Watch the rating count over a month. |
| AS-6.3-07 | UNVERIFIED (inherited — same claim as AS-6.2A-09) | Every bracketed quotation reached its author through the search-summarisation layer. | Any quotation reused downstream. | Re-verify against the URL. |
| AS-6.3-08 | NOT-MEASURED | Nothing in §6.3 is a play impression of any competitor. No competing product was installed or played, on any platform, by anyone. | Every comparative quality judgement in the document. | Buy and play the three closest competitors. |

### §6.4 — Statistical calibration

| ID | Label | Claim | Where it bites | How to settle |
|---|---|---|---|---|
| AS-6.4-01 | ASSUMPTION | NFL overtime rate is ~5–6% of games; band set `0.03…0.09`. | Band #8, §6.4 §3.7. | One page-load: `pro-football-reference.com/years/2024/`. |
| AS-6.4-02 | ASSUMPTION | College offensive plays per team-game is `67…75` on the scrimmage convention. | §6.4 §4.2, and through it **P4** and **D4** — the college week-advance budget. | `sports-reference.com/cfb/years/2024-team-offense.html`. |
| AS-6.4-03 | ASSUMPTION | The 175-vs-127.5 plays-per-game discrepancy in the sources is a counting-convention difference. | §6.4 §4.2. If wrong, the college tempo band is wrong by ~35%. | Same page-load; compare definitions. |
| AS-6.4-04 | ASSUMPTION | College sample context mix is 25% non-conference / 65% conference / 10% postseason. | §6.4 §6.1 — the sample specification the whole harness draws from. | Count a real season's schedule. |
| AS-6.4-05 | ASSUMPTION | Non-power-conference margin band `12…18`. | §6.4 §4.5 — the blowout/dispersion calibration. | Compute from a season of FBS results. |
| AS-6.4-06 | ASSUMPTION | The best-versus-worst ceiling of 0.88, and the TE/RB/max-receiver target shares. | §6.4 §6.5's band tables. | Compute from public play-by-play. |
| AS-6.4-07 | ASSUMPTION | The bin edges and τ values in §6.4 §6.3 are **designed, not fitted** to any published binning. | The total-variation-distance test's pass/fail threshold — i.e. whether the distributional test can fail at all. | Fit against a real distribution once one is loaded. |
| AS-6.4-08 | UNVERIFIED [U] | NFL rush yards, completion %, sacks and INTs per game — retained from the inherited test suite, unverified. | Four pro bands ship unverified. | One page-load. |
| AS-6.4-09 | UNSET | College completion %, pass/rush yards, sacks, INTs and points per drive are **unset, not guessed**. | The college harness is incomplete by construction; `03-MATCH-ENGINE.md` must not pretend otherwise. | One page-load. The gap is named deliberately. |
| AS-6.4-10 | UNVERIFIED [U] | The exact season the college two-minute warning was adopted. | The clock model's start date, not its shape. | One page-load. |
| AS-6.4-11 | UNVERIFIED [U] | Whether the FBS field-goal figure is 75.6% or 77% (different game-sets; immaterial to the band as set). | Nothing material. | Ignore. |

### §6.5 — 2D match presentation

| ID | Label | Claim | Where it bites | How to settle |
|---|---|---|---|---|
| AS-6.5-01 | ASSUMPTION | iPhone logical point dimensions (390 × 844 base, 320 wide on SE). From memory. | Every geometry number in §6.5 §6. | Measure in Xcode; replace in `04`. |
| AS-6.5-02 | ASSUMPTION | ~500 pt of available canvas height after chrome. A design estimate, not a measurement. | **Every number in §6.5 §6.2 scales linearly with it** — the pt/yd scale, the visible-yard window, the mark sizes. | Measure a real layout. |
| AS-6.5-03 | ASSUMPTION | Offensive line splits of ~1–1.3 yd centre to centre. Order of magnitude only; varies by scheme. | §6.5 §6.3's conclusion (line players cannot carry jersey numbers) — which survives anything in the 0.7–2 yd range. | Low stakes; conclusion is robust. |
| AS-6.5-04 | ASSUMPTION | A legible two-digit numbered circle needs ~20–22 pt diameter at 11 pt font. Typographic rule of thumb, not tested. | The Class-1 mark budget. | Test on device at the smallest Dynamic Type size. |
| AS-6.5-05 | ASSUMPTION | The dwell defaults in §6.5 §9 (1.2–2.5 s resolution, 0.8 s post-play, 0.6 s flashed). **Proposals to be tuned against an owner timing protocol, not findings.** | The presentation-time term in the §4 arithmetic — the single term most likely to blow P4. | Owner timing protocol with a stated threshold. |
| AS-6.5-06 | ASSUMPTION | The 25/105 high-leverage split in §6.5 §9's second budget. Illustrative arithmetic; the real number is an output of D1's leverage filter. | The season-time budget. | Falls out of D1 once the leverage filter is specified. |
| AS-6.5-07 | **SETTLED — against the assumption** (§6.6 §2) | FM Mobile draws its pitch **landscape**, full-bleed, goals at the screen edges; the device is rotated for the match. There is no portrait precedent in FM. | **Reversed again 2026-08-10, and now it points at the app as a whole.** The owner set the app landscape and reports FMM is landscape *throughout*, menus included — testimony, not capture. FM is therefore a live precedent again, though a soccer one for a sport with the opposite field ratio; `04` §5.2 leans on its own arithmetic instead. | Settled by direct observation of two owner-supplied FM Mobile captures. Two residuals: both read `FM23 MOBILE`, so this is FMM23, not the current SKU (see §6.6 §2); and the management-screen claim is owner testimony with no capture behind it. |
| AS-6.5-08 | UNVERIFIED | Apple's 44 × 44 pt minimum touch target. Long-standing HIG guidance; `developer.apple.com` returns no readable body through the proxy. | D12's touch-target floor. | Read the HIG on an unrestricted machine. |
| AS-6.5-09 | UNVERIFIED | Apple's exact HIG wording on Reduce Motion, including whether cross-fade is recommended in those words. Same cause. | D12's Reduce Motion contract. | Same. |
| AS-6.5-10 | UNVERIFIED | The precise SwiftUI API surface for suppressing `TimelineView` scheduling under Reduce Motion. The environment key is documented; the "assert on a seam" test in §6.5 §7.1 is written that way *because* SwiftUI internals could not be verified as observable. | How the Reduce Motion test is written — the mechanism, not the requirement. | Write the test against a real toolchain. |
| AS-6.5-11 | UNRUN — **and worth more since 2026-08-10, not less** | How other mobile sports titles orient the field. **Retro Bowl's orientation specifically could not be sourced, and it is the highest-value missing data point in the document** — it is the most-played football game on the platform. Originally scoped to portrait; the app is now landscape and the question is the same one, asked without a preferred answer. | `04` §5.2's landscape decision, which rests on arithmetic plus a soccer precedent and runs against FM's vertical-legibility finding. | Open Retro Bowl. |
| AS-6.5-12 | UNRUN | Whether any shipping title animates all 22 players in a 2D top-down football view. None found in the competitive set, but "found none" under an exhausted search budget is weaker than "there is none." | §6.5 §3.1's claim, and the novelty argument for the match view. | Broader search. |
| AS-6.5-13 | UNRUN | Direct evidence on legible mark sizes at phone scale. There is a data-visualisation literature on minimum discriminable mark size and small-multiple density that was not reached; §6.5 §6.3 rests on arithmetic and a typographic rule of thumb instead. | The ≤4-individuated-marks rule's numeric basis. | Literature search. |
| AS-6.5-14 | UNRUN | Blood Bowl and OOTP community complaints about presentation legibility specifically. Both are represented by review and manual text, not player voice. | The breadth of the presentation-legibility evidence. | Forum search. |
| AS-6.5-15 | DERIVED | Arithmetic or logic performed in §6.5 with cited inputs: §4.4 (the five-state read and the minimum vocabulary), §5.3 (capacity overshoot table, Class 1/Class 2 rule), §5.4 (fixed camera), §6.2 (877.5 pt, 68.4 yd, 7.3125 pt/yd), §6.3 (8.4 pt line spacing, 3.5% ink coverage), §6.4 (8 tap targets), §9 (all budgets), §3.2 (drive chart as ambient mode). | The rendering rules in §6.5 §10, which `04-UX-AND-DESIGN-SYSTEM.md` inherits. | Re-do the arithmetic with measured inputs (see AS-6.5-01, AS-6.5-02). |

### The five that matter most

If the owner reads only part of this register, read these. They are the ones where a wrong
assumption changes a deliverable rather than a sentence.

1. **AS-6.0-00 (NOT-RUN)** — nobody has played the build. The diagnosis the whole rebuild responds
   to is still, strictly, unmeasured.
2. **AS-6.5-02 and AS-6.5-05** — the canvas height and the dwell defaults. Together they set the
   presentation-time term, which is the term most likely to blow P4 on its own.
3. **AS-6.4-02 / AS-6.4-09** — college tempo is assumed and five college bands are unset. The
   college tier's calibration harness cannot pass or fail until these are loaded.
4. **AS-6.3-03** — almost nobody asks for the unified college→pro career. P2 is fixed by the owner,
   but this is the evidence that it is a scope multiplier rather than a differentiator.
5. **AS-6.2A-01** — whether Draft Day Sports ships on iOS. One App Store search decides whether the
   positioning claim survives a reviewer's first check.

---

## Consolidated sources

### How to read this list

The sources divide into five corpora with materially different grades:

1. **Repository-primary** — the project's own source and test files, read directly, cited by
   `file:line`. Used by §6.0 (the UI and engine census) and §6.4 §1 (the inherited calibration
   bands, extracted verbatim from the test source). This is the strongest evidence in the document.
2. **Read in full** — two GitHub READMEs (`nfl-football-ops/Big-Data-Bowl`, `asonty/ngs_highlights`)
   in §6.5. Everything else external was not.
3. **Official documentation and vendor copy** — Sports Interactive's FMM manual, footballmanager.com,
   Wolverine Studios, Solecismic, New Star Games, On Paper Sports, Apple's HIG and developer
   documentation, NCAA rules announcements. Reliable as to what the vendor claims; not independent.
4. **Community and player voice** — FMM Vibe, the SI forums, Steam discussions and reviews,
   Operation Sports forums, the Draft Day Sports phpBB board, App Store and Play Store reviews,
   Metacritic user reviews, fan wikis. **The highest-value secondary signal in the genre**, and the
   corpus most damaged by the Reddit block (AS-6.1-07, AS-6.2B-09).
5. **Press, statistics and academic** — Pocket Tactics, TouchArcade, Pocket Gamer, gmgames.org,
   CBS Sports, ESPN, PFF, betting-analytics sites for calibration figures, and the
   multiple-object-tracking literature in §6.5 §5.

**Every URL below was surfaced by search; with the two exceptions in (2), none was fetched in full.**
URLs marked ⛔ in §6.2A's own source list were additionally attempted by direct fetch and refused by
the egress proxy. Licensing for the data sources is treated separately in §6.4 §7, which
distinguishes *using public data at design and calibration time* from *shipping any of it*, and
flags the borderline cases for counsel rather than resolving them.

### Index of every source cited, by host

Generated from the citation blocks of Part Two. The section tags say which research part cites the
host; the full URLs, with their per-claim context, live in each section's own sources block
(§6.1 §10, §6.2A §9, §6.2B §9, §6.3 §9, §6.4 §9, §6.5 §12). Part One carries no URLs (CF-1).

| Host | Unique URLs | Cited by |
|---|---|---|
| `steamcommunity.com` | 32 | §6.2A, §6.2B, §6.3, §6.5 |
| `fmmvibe.com` | 31 | §6.1, §6.3, §6.5 |
| `community.sports-interactive.com` | 28 | §6.1, §6.5 |
| `gmgames.org` | 24 | §6.1, §6.2A, §6.2B, §6.3 |
| `apps.apple.com` | 13 | §6.1, §6.2B, §6.3, §6.5 |
| `operationsports.com` | 13 | §6.1, §6.2A, §6.2B, §6.3, §6.5 |
| `retro-bowl.fandom.com` | 12 | §6.2B, §6.3 |
| `store.steampowered.com` | 12 | §6.2A, §6.2B, §6.3, §6.5 |
| `footballmanager.com` | 8 | §6.1, §6.3, §6.5 |
| `play.google.com` | 8 | §6.1, §6.2B, §6.3 |
| `wolverinestudios.com` | 8 | §6.2A, §6.5 |
| `cbssports.com` | 7 | §6.4 |
| `developer.apple.com` | 7 | §6.5 |
| `en.wikipedia.org` | 6 | §6.2A, §6.2B, §6.5 |
| `espn.com` | 6 | §6.4 |
| `github.com` | 6 | §6.4, §6.5 |
| `draftdaysports.com` | 5 | §6.2A |
| `metacritic.com` | 5 | §6.2A, §6.2B, §6.3 |
| `wolverinestudios.freshdesk.com` | 5 | §6.2A |
| `forums.operationsports.com` | 4 | §6.2A, §6.2B, §6.3, §6.5 |
| `onpapersports.com` | 4 | §6.2A, §6.2B, §6.3 |
| `solecismic.com` | 4 | §6.2A |
| `zengm.com` | 4 | §6.5 |
| `boydsbets.com` | 3 | §6.4 |
| `collegefootballdata.com` | 3 | §6.4 |
| `pff.com` | 3 | §6.4 |
| `sports-reference.com` | 3 | §6.4 |
| `taptap.io` | 3 | §6.2A, §6.2B |
| `americanfootballiq.com` | 2 | §6.5 |
| `apple.com` | 2 | §6.2B, §6.3 |
| `bleacherreport.com` | 2 | §6.4, §6.5 |
| `ea.com` | 2 | §6.2B |
| `footballmanagerblog.org` | 2 | §6.5 |
| `forbes.com` | 2 | §6.2A, §6.4 |
| `forumsold.operationsports.com` | 2 | §6.2A |
| `grokipedia.com` | 2 | §6.2B |
| `kodeco.com` | 2 | §6.5 |
| `manuals.ootpdevelopments.com` | 2 | §6.5 |
| `ncaa.com` | 2 | §6.4 |
| `ncaa.org` | 2 | §6.4 |
| `nfl.com` | 2 | §6.5 |
| `operations.nfl.com` | 2 | §6.5 |
| `playbite.com` | 2 | §6.2B |
| `pmc.ncbi.nlm.nih.gov` | 2 | §6.5 |
| `pocketgamer.com` | 2 | §6.1, §6.2B |
| `pockettactics.com` | 2 | §6.1, §6.2B, §6.3 |
| `robwritesaboutwhatever.com` | 2 | §6.2B |
| `steambase.io` | 2 | §6.2A, §6.2B |
| `swiftwithmajid.com` | 2 | §6.5 |
| `youtube.com` | 2 | §6.2B, §6.3 |
| `actionnetwork.com` | 1 | §6.4 |
| `amazon.science` | 1 | §6.5 |
| `aol.com` | 1 | §6.4 |
| `appbrain.com` | 1 | §6.2B, §6.3 |
| `apprank.io` | 1 | §6.2B, §6.3 |
| `athletesuntapped.com` | 1 | §6.5 |
| `avanderlee.com` | 1 | §6.5 |
| `bcftoys.com` | 1 | §6.4 |
| `betting.us` | 1 | §6.4 |
| `beyondthescoresports.substack.com` | 1 | §6.4 |
| `bigbossbattle.com` | 1 | §6.5 |
| `biorxiv.org` | 1 | §6.5 |
| `byhoursplayed.com` | 1 | §6.2B |
| `campus2canton.com` | 1 | §6.4 |
| `cgmagonline.com` | 1 | §6.5 |
| `conormclaughlin.net` | 1 | §6.4 |
| `covers.com` | 1 | §6.4 |
| `createwithswift.com` | 1 | §6.5 |
| `cultofmac.com` | 1 | §6.2B |
| `dash.harvard.edu` | 1 | §6.5 |
| `deque.com` | 1 | §6.5 |
| `dknetwork.draftkings.com` | 1 | §6.4 |
| `espnfrontrow.com` | 1 | §6.5 |
| `espnpressroom.com` | 1 | §6.5 |
| `esports-news.co.uk` | 1 | §6.5 |
| `ethw.org` | 1 | §6.5 |
| `feeds.bbci.co.uk` | 1 | §6.1 |
| `football.championsimleague.com` | 1 | §6.2A |
| `footballfoundation.org` | 1 | §6.4 |
| `forum.greydogsoftware.com` | 1 | §6.2A |
| `gamalytic.com` | 1 | §6.2B |
| `game-solver.com` | 1 | §6.2B |
| `gamefaqs.gamespot.com` | 1 | §6.5 |
| `gamegou.helpshift.com` | 1 | §6.5 |
| `gamerant.com` | 1 | §6.2A |
| `gamesbuilds.org` | 1 | §6.2A |
| `gamingonphone.com` | 1 | §6.1 |
| `grandstandcentral.com` | 1 | §6.2A |
| `grantland.com` | 1 | §6.5 |
| `greydogsoftware.com` | 1 | §6.2A |
| `handwiki.org` | 1 | §6.2B |
| `imore.com` | 1 | §6.1 |
| `inreviewcritics.com` | 1 | §6.2B, §6.3 |
| `invent.org` | 1 | §6.5 |
| `jov.arvojournals.org` | 1 | §6.5 |
| `kslsports.com` | 1 | §6.4 |
| `lindyssports.com` | 1 | §6.4 |
| `link.springer.com` | 1 | §6.5 |
| `loudpoet.com` | 1 | §6.2A |
| `matausch.itch.io` | 1 | §6.2A |
| `medium.com` | 1 | §6.2A |
| `mentalfloss.com` | 1 | §6.5 |
| `nbcnews.com` | 1 | §6.4 |
| `ncsasports.org` | 1 | §6.2A |
| `netflix.com` | 1 | §6.1 |
| `newstargames.com` | 1 | §6.2B |
| `nextgenstats.nfl.com` | 1 | §6.5 |
| `nflanalytic.com` | 1 | §6.4 |
| `nflfastr.com` | 1 | §6.4 |
| `nflverse.nflverse.com` | 1 | §6.4 |
| `nintendolife.com` | 1 | §6.2B |
| `nxtbets.com` | 1 | §6.4 |
| `ootpdevelopments.com` | 1 | §6.5 |
| `pcgamer.com` | 1 | §6.2A |
| `press.disneyplus.com` | 1 | §6.5 |
| `primegamesarena.com` | 1 | §6.1 |
| `pubmed.ncbi.nlm.nih.gov` | 1 | §6.5 |
| `purenintendo.com` | 1 | §6.2B |
| `realsport101.com` | 1 | §6.1 |
| `researchgate.net` | 1 | §6.5 |
| `retrobowl.college` | 1 | §6.2B |
| `samhoppen.substack.com` | 1 | §6.4 |
| `saturdaydownsouth.com` | 1 | §6.4 |
| `sciencedirect.com` | 1 | §6.5 |
| `semanticscholar.org` | 1 | §6.5 |
| `skysports.com` | 1 | §6.1 |
| `slideshare.net` | 1 | §6.5 |
| `sncfl.us` | 1 | §6.2A |
| `sportico.com` | 1 | §6.4 |
| `sports.betmgm.com` | 1 | §6.4 |
| `sports.yahoo.com` | 1 | §6.4 |
| `sportsenthusiasts.net` | 1 | §6.4 |
| `sportspro.com` | 1 | §6.1 |
| `sportsvideo.org` | 1 | §6.5 |
| `stampedeblue.com` | 1 | §6.4 |
| `statmuse.com` | 1 | §6.4 |
| `steamdb.info` | 1 | §6.2A |
| `steamspy.com` | 1 | §6.2A |
| `techradar.com` | 1 | §6.1 |
| `thehighertempopress.com` | 1 | §6.1 |
| `thephinsider.com` | 1 | §6.5 |
| `toucharcade.com` | 1 | §6.1 |
| `twoplaymakers.com` | 1 | §6.1 |
| `vsin.com` | 1 | §6.4 |
| `walterfootball.com` | 1 | §6.4 |
| `whatifsports.com` | 1 | §6.2B |
| `whats-on-netflix.com` | 1 | §6.1 |
| `wolfsports.com` | 1 | §6.5 |
| `x.com` | 1 | §6.4 |

**Totals: 410 unique URLs across 149 hosts.** Plus the repository-primary sources, which are not URLs: the test suites `Tests/SimTests/Suites/GameSimulatorTests.swift`, `SeasonTests.swift`, `DynastyTests.swift`, `GenerationTests.swift`, `ArcadeTests.swift` and `TestKit.swift`; `Sources/FootballSimCore/Rules/LeagueRules.swift`; the whole of `Sources/ProFootballCoachUI/` (53 SwiftUI view types, 6,861 lines) and the reachable paths of `Sources/FootballSimCore/` (12,274 lines); and `docs/STATUS.md` and `docs/AUDIT.md`.

### Full URL list

**`steamcommunity.com`** — §6.2A, §6.2B, §6.3, §6.5

- https://steamcommunity.com/app/2151290
- https://steamcommunity.com/app/2151290/discussions/0/3826425639848612057/
- https://steamcommunity.com/app/2151290/discussions/0/4205868123787946936
- https://steamcommunity.com/app/2151290/discussions/0/4205868583241554711/
- https://steamcommunity.com/app/2151290/discussions/0/594013679434942086/
- https://steamcommunity.com/app/2151290/negativereviews/?browsefilter=toprated
- https://steamcommunity.com/app/2151290/reviews/?browsefilter=toprated
- https://steamcommunity.com/app/2163800/reviews/?browsefilter=toprated
- https://steamcommunity.com/app/2252570/discussions/0/3879346999814247173/
- https://steamcommunity.com/app/2625350/reviews/?browsefilter=toprated
- https://steamcommunity.com/app/2633170/discussions/0/4032473436328480481/
- https://steamcommunity.com/app/2633170/discussions/0/4356746036670287329/
- https://steamcommunity.com/app/2633170/discussions/0/5513030395222850839/
- https://steamcommunity.com/app/3154850/discussions/
- https://steamcommunity.com/app/3154850/reviews/?browsefilter=toprated
- https://steamcommunity.com/app/3323590/
- https://steamcommunity.com/app/3323590/discussions/0/4638240322751683981/
- https://steamcommunity.com/app/3323590/discussions/0/595150188903958973/
- https://steamcommunity.com/app/3440610/reviews/?browsefilter=toprated
- https://steamcommunity.com/app/3551340/discussions/0/506216918921930920/
- https://steamcommunity.com/app/3551340/discussions/0/506217282369896496/
- https://steamcommunity.com/app/3914070/discussions/
- https://steamcommunity.com/app/3914210/reviews/?browsefilter=toprated
- https://steamcommunity.com/app/398640/reviews/?browsefilter=toprated
- https://steamcommunity.com/app/4041080/
- https://steamcommunity.com/app/547900/discussions/0/1489992080520563191/
- https://steamcommunity.com/app/547900/reviews/?browsefilter=toprated
- https://steamcommunity.com/app/782510/discussions/0/1700541698679858770/
- https://steamcommunity.com/app/782510/reviews?browsefilter=toprated
- https://steamcommunity.com/app/878710/discussions/0/1736594593603384294
- https://steamcommunity.com/sharedfiles/filedetails/?id=3386721954
- https://steamcommunity.com/sharedfiles/filedetails/?id=3431824694

**`fmmvibe.com`** — §6.1, §6.3, §6.5

- https://fmmvibe.com/files/file/1489-tactics-by-pinuccio-update-0331/
- https://fmmvibe.com/forums/topic/40357-how-do-you-play-without-getting-bored/
- https://fmmvibe.com/forums/topic/40919-the-difficulty-debate/
- https://fmmvibe.com/forums/topic/41790-the-poll-do-you-ever-play-with-attribute-masking-on/
- https://fmmvibe.com/forums/topic/42363-mid-level-challenge/
- https://fmmvibe.com/forums/topic/43226-opinion-what-is-the-point-of-fmm/
- https://fmmvibe.com/forums/topic/43393-30-seasons/
- https://fmmvibe.com/forums/topic/44777-30-seasons/
- https://fmmvibe.com/forums/topic/44855-how-to-play-football-manager-mobile-more-realistically/
- https://fmmvibe.com/forums/topic/45387-attributes-vs-scoutcoach-rating/
- https://fmmvibe.com/forums/topic/45397-discussion-is-fmm-too-easy/
- https://fmmvibe.com/forums/topic/46052-help-i%E2%80%99m-getting-bored-quickly/
- https://fmmvibe.com/forums/topic/46347-how-to-not-get-bored-of-playing-fm/
- https://fmmvibe.com/forums/topic/48088-the-impossible-challenge-completed-s30-%E2%80%A2bonus-round%E2%80%A2/
- https://fmmvibe.com/forums/topic/48496-different-report-of-scout-and-coach/
- https://fmmvibe.com/forums/topic/48873-realistic-careers-and-how-to/
- https://fmmvibe.com/forums/topic/48906-self-imposed-hard-mode/
- https://fmmvibe.com/forums/topic/49699-mini-guide-general-advice-on-fmm-tactics/
- https://fmmvibe.com/forums/topic/49730-mentalities/
- https://fmmvibe.com/forums/topic/50005-longest-game-time/
- https://fmmvibe.com/forums/topic/50213-where-do-you-find-so-much-time-to-play-fm/
- https://fmmvibe.com/forums/topic/50520-fmm26-tactics-quick-guideindex/
- https://fmmvibe.com/forums/topic/50529-poll-do-you-think-fmm26-is-too-easy-vs-too-difficult/
- https://fmmvibe.com/forums/topic/50626-negative-feedback/
- https://fmmvibe.com/forums/topic/50673-beginners-guide-in-progress/
- https://fmmvibe.com/forums/topic/50684-advanced-guide/
- https://fmmvibe.com/forums/topic/50691-%E2%80%A2-broken-game-%E2%80%A2/
- https://fmmvibe.com/forums/topic/50827-fm26-mobile-is-the-worst-fm-mobile-game-ever/
- https://fmmvibe.com/forums/topic/50942-fm-26-mobile-is-too-difficult/
- https://fmmvibe.com/forums/topic/51038-skip-days/
- https://fmmvibe.com/forums/topic/7800-the-2d-pitch/

**`community.sports-interactive.com`** — §6.1, §6.5

- https://community.sports-interactive.com/forums/topic/403839-30-season-limit/
- https://community.sports-interactive.com/forums/topic/499028-2d-matchday-pitch-view/
- https://community.sports-interactive.com/forums/topic/501933-instant-result-option/
- https://community.sports-interactive.com/forums/topic/567945-how-do-i-change-view-for-matches/
- https://community.sports-interactive.com/forums/topic/569604-instant-result/
- https://community.sports-interactive.com/forums/topic/585022-suggestion-instant-result-for-fm-mobile/
- https://community.sports-interactive.com/forums/topic/590274-instant-result-3-options-including-what-already-exists-in-game/
- https://community.sports-interactive.com/forums/topic/591889-what%E2%80%99s-your-go-to-camera-angle-match-view-setup/
- https://community.sports-interactive.com/forums/topic/593192-whats-new-in-fmm26/
- https://community.sports-interactive.com/forums/topic/593877-2d-camera/
- https://community.sports-interactive.com/forums/topic/594339-2d-match-engine-poor-quality/
- https://community.sports-interactive.com/forums/topic/594444-football-manager-26-mobile-tactics/
- https://community.sports-interactive.com/forums/topic/595327-official-football-manager-26-mobile-feedback-thread/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2024/matchday-r5239/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2024/tactics-r5227/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2024/you-the-manager-r5238/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/main-menu-r5243/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/match-day-r5263/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/options-r5264/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/starting-a-new-game-r5244/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/tactics-r5249/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/team-report-r5251/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/the-home-screen-r5246/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/the-interface-r5245/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/training-r5253/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/you-the-manager-r5260/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/your-team-r5248/

**`gmgames.org`** — §6.1, §6.2A, §6.2B, §6.3

- https://gmgames.org/2020/06/11/ootp-developments-and-solecismic-software-part-ways/
- https://gmgames.org/2021/02/20/fof9-scrapped-jim-gindin-sells-algorithmic-code-and-pursues-different-format-of-game/
- https://gmgames.org/2025/08/01/draft-day-sports-college-football-26-released-for-windows-pc/
- https://gmgames.org/2025/09/19/draft-day-sports-pro-football-2026-expands-coaching-roles-smarter-ai-and-custom-leagues/
- https://gmgames.org/2025/11/14/draft-day-sports-pro-basketball-26-tips-off-with-smarter-ai-new-archetypes-and-a-modernized-gm-experience/
- https://gmgames.org/2026/03/04/draft-day-sports-college-basketball-26-adds-nil-options-transfer-portal-settings-and-updated-game-presentation/
- https://gmgames.org/bowl-bound-college-football/
- https://gmgames.org/college-football-coach-career-edition/
- https://gmgames.org/developer/jim-gindin/
- https://gmgames.org/developer/sports-interactive/
- https://gmgames.org/draft-day-sports-college-football-2023/review/
- https://gmgames.org/draft-day-sports-college-football-2025/review/
- https://gmgames.org/draft-day-sports-pro-football-2022/review/
- https://gmgames.org/football-coach-college-dynasty/
- https://gmgames.org/football-coach-college-dynasty/user-reviews/
- https://gmgames.org/front-office-football-8-fof8/review/
- https://gmgames.org/front-office-football-9-fof9/
- https://gmgames.org/pocket-gm-3-football/
- https://gmgames.org/publisher/wolverine-studios/
- https://gmgames.org/section/american-football-nfl-college-manager-simulator-games/
- https://gmgames.org/section/iphone/
- https://gmgames.org/top/
- https://gmgames.org/ultimate-football-gm/
- https://gmgames.org/winning-tradition-football/

**`apps.apple.com`** — §6.1, §6.2B, §6.3, §6.5

- https://apps.apple.com/gb/app/football-manager-26-mobile/id6446123740?see-all=reviews&platform=iphone
- https://apps.apple.com/us/app/college-football-coach/id1095701497
- https://apps.apple.com/us/app/football-manager-26-mobile/id6446123740
- https://apps.apple.com/us/app/nfl-retro-bowl-26/id6476767864
- https://apps.apple.com/us/app/pocket-gm-3-football-sim/id1645791169
- https://apps.apple.com/us/app/pocket-gm-3-football-sim/id1645791169?see-all=reviews&platform=iphone
- https://apps.apple.com/us/app/retro-bowl-college/id1632904520
- https://apps.apple.com/us/app/retro-bowl-college/id1632904520?see-all=reviews
- https://apps.apple.com/us/app/retro-bowl/id1478902583
- https://apps.apple.com/us/app/retro-bowl/id6446029554
- https://apps.apple.com/us/app/ult-college-football-coach/id6532596535
- https://apps.apple.com/us/app/ultimate-pro-football-gm/id1530542938
- https://apps.apple.com/us/app/winning-tradition-football/id6743344615

**`operationsports.com`** — §6.1, §6.2A, §6.2B, §6.3, §6.5

- https://www.operationsports.com/draft-day-sports-college-football-26-first-access-begins-on-august-1/
- https://www.operationsports.com/draft-day-sports-college-football-27-first-access-available-now/
- https://www.operationsports.com/draft-day-sports-pro-football-22-review-another-solid-entry-in-the-series/
- https://www.operationsports.com/football-coach-college-dynasty-review-a-sports-sim-with-training-wheels-for-better-and-worse/
- https://www.operationsports.com/football-manager-26-adds-instant-result-option-for-matches/
- https://www.operationsports.com/front-office-football-8-review-pc/
- https://www.operationsports.com/games/nfl-retro-bowl-26/
- https://www.operationsports.com/new-star-games-releases-updates-for-all-three-retro-bowl-games
- https://www.operationsports.com/out-of-the-park-baseball-24-review-still-making-worthwhile-improvements/
- https://www.operationsports.com/pro-football-dynasty-coming-soon-to-steam/
- https://www.operationsports.com/retro-bowl-college-update-addresses-balancing-issues-with-gpa-rankings-and-more/
- https://www.operationsports.com/retro-bowl-college-updates-conferences-adds-12-team-playoff-and-more/
- https://www.operationsports.com/retro-bowl-review-a-mobile-game-that-transcends-the-platform/

**`retro-bowl.fandom.com`** — §6.2B, §6.3

- https://retro-bowl.fandom.com/wiki/Coaching_Credits
- https://retro-bowl.fandom.com/wiki/Dilemmas
- https://retro-bowl.fandom.com/wiki/Exhibition_Game
- https://retro-bowl.fandom.com/wiki/Front_Office
- https://retro-bowl.fandom.com/wiki/Gameplay
- https://retro-bowl.fandom.com/wiki/List_of_teams
- https://retro-bowl.fandom.com/wiki/Options
- https://retro-bowl.fandom.com/wiki/Playoff
- https://retro-bowl.fandom.com/wiki/Quarters
- https://retro-bowl.fandom.com/wiki/Schedule
- https://retro-bowl.fandom.com/wiki/Staff_Hires
- https://retro-bowl.fandom.com/wiki/Unlimited_Version

**`store.steampowered.com`** — §6.2A, §6.2B, §6.3, §6.5

- https://store.steampowered.com/app/2151290/Football_Coach_College_Dynasty/
- https://store.steampowered.com/app/2633170/Front_Office_Football_Nine/
- https://store.steampowered.com/app/3154850/Draft_Day_Sports_College_Football_2025/
- https://store.steampowered.com/app/3323590/Draft_Day_Sports_Pro_Football_2025/
- https://store.steampowered.com/app/3914070/Draft_Day_Sports_College_Football_2026/
- https://store.steampowered.com/app/3914210/Draft_Day_Sports_Pro_Basketball_2026/
- https://store.steampowered.com/app/398640/Bowl_Bound_College_Football/
- https://store.steampowered.com/app/4041080/Draft_Day_Sports_Pro_Football_2026/
- https://store.steampowered.com/app/4769350/Pro_Football_Dynasty/
- https://store.steampowered.com/app/547900/Front_Office_Football_Eight/
- https://store.steampowered.com/app/782510/Draft_Day_Sports_Pro_Football_2018/
- https://store.steampowered.com/search/?publisher=Wolverine+Studios

**`footballmanager.com`** — §6.1, §6.3, §6.5

- https://www.footballmanager.com/compare-games
- https://www.footballmanager.com/features/fm24-mobile
- https://www.footballmanager.com/features/football-manager-2024-mobile-new-features-revealed
- https://www.footballmanager.com/fm26/features/football-manager-26-mobile-new-features-showcase
- https://www.footballmanager.com/fm26/features/introducing-womens-football
- https://www.footballmanager.com/fm26/features/mobile
- https://www.footballmanager.com/fm26/features/where-storytelling-evolves-fm26s-match-day-experience
- https://www.footballmanager.com/news/football-manager-26-out-now-across-platforms

**`play.google.com`** — §6.1, §6.2B, §6.3

- https://play.google.com/store/apps/details?id=antdroid.cfbcoach&hl=en_US
- https://play.google.com/store/apps/details?id=com.atomic.collegefootball&hl=en_US
- https://play.google.com/store/apps/details?id=com.cbanfiel.OnPaperSportsFootball24
- https://play.google.com/store/apps/details?id=com.gmz2rk.ucfc&hl=en_US
- https://play.google.com/store/apps/details?id=com.gmz2rk.ufgm&hl=en_US
- https://play.google.com/store/apps/details?id=com.netflix.NGP.FootballManagerMobile
- https://play.google.com/store/apps/details?id=com.newstargames.retrobowlcollege
- https://play.google.com/store/apps/details?id=com.onpapersports.WinningTraditionFootball

**`wolverinestudios.com`** — §6.2A, §6.5

- https://wolverinestudios.com/
- https://wolverinestudios.com/10-reasons-draft-day-sports-college-football-27-is-the-ultimate-game-for-college-football-dynasty-builders/
- https://wolverinestudios.com/games/draft-day-sports-college-football/
- https://www.wolverinestudios.com/draft-day-sports-college-football-simulation/
- https://www.wolverinestudios.com/games/draft-day-sports-pro-football
- https://www.wolverinestudios.com/post/featurefriday-building-plays-in-draft-day-sports-pro-football-2020
- https://www.wolverinestudios.com/post/new-features-coming-in-draft-day-sports-pro-football-26
- https://www.wolverinestudios.com/post/work-your-way-up-the-coaching-ladder-in-draft-day-sports-college-football-26

**`cbssports.com`** — §6.4

- https://www.cbssports.com/college-football/news/blue-chip-ratio-2025-the-college-football-teams-that-have-done-less-with-more-talent/
- https://www.cbssports.com/college-football/news/college-football-scoring-average-increases-to-highest-ever-in-2016-season
- https://www.cbssports.com/college-football/news/college-footballs-offensive-explosion-continued-in-2018-with-more-new-records-set
- https://www.cbssports.com/college-football/news/despite-running-fewer-plays-college-football-games-are-actually-getting-longer-so-whos-to-blame/
- https://www.cbssports.com/college-football/news/is-the-college-football-playoff-delivering-on-its-promise-blowouts-lack-of-upsets-suggest-otherwise
- https://www.cbssports.com/college-football/news/ncaa-changes-college-football-overtime-rules-2-point-tries-required-in-second-ot-then-2-point-shootouts/
- https://www.cbssports.com/college-football/news/yes-college-kickers-are-getting-better-data-shows-theyre-scoring-more-from-farther-away-than-ever/

**`developer.apple.com`** — §6.5

- https://developer.apple.com/design/human-interface-guidelines/motion
- https://developer.apple.com/documentation/accessibility/audio-graphs
- https://developer.apple.com/documentation/accessibility/representing-chart-data-as-an-audio-graph
- https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion
- https://developer.apple.com/videos/play/wwdc2021/10119/
- https://developer.apple.com/videos/play/wwdc2021/10122/
- https://developer.apple.com/videos/play/wwdc2022/110340/

**`en.wikipedia.org`** — §6.2A, §6.2B, §6.5

- https://en.wikipedia.org/wiki/1st_%26_Ten_(graphics_system)
- https://en.wikipedia.org/wiki/2025_NCAA_Division_I_FCS_football_season
- https://en.wikipedia.org/wiki/Bound_for_Glory_Series
- https://en.wikipedia.org/wiki/List_of_NCAA_Division_I_FBS_football_programs
- https://en.wikipedia.org/wiki/Next_Gen_Stats
- https://en.wikipedia.org/wiki/Retro_Bowl

**`espn.com`** — §6.4

- https://www.espn.com/college-football/insider/story/_/id/40836337/college-football-2024-preseason-sp+-rankings-takeaways
- https://www.espn.com/college-football/insider/story/_/id/43509845/college-football-sp+-rankings-cfp-championship-game
- https://www.espn.com/college-football/story/_/id/36255797/ncaa-approves-rule-change-run-clock-first-downs
- https://www.espn.com/college-football/story/_/id/39111711/what-ncaa-college-football-rules
- https://www.espn.com/college-football/story/_/id/42213830/2024-college-football-kickers-history-making-field-goals
- https://www.espn.com/espn/betting/story/_/id/43235257/nfl-betting-favorites-verge-completing-historic-season

**`github.com`** — §6.4, §6.5

- https://github.com/asonty/ngs_highlights
- https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityRepresentation.md
- https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Images.md
- https://github.com/nfl-football-ops/Big-Data-Bowl
- https://github.com/nflverse/nflfastR/blob/master/LICENSE.md
- https://github.com/zengm-games/zengm

**`draftdaysports.com`** — §6.2A

- https://www.draftdaysports.com/board/viewforum.php?f=268
- https://www.draftdaysports.com/board/viewforum.php?f=392
- https://www.draftdaysports.com/board/viewtopic.php?f=336&t=34456
- https://www.draftdaysports.com/board/viewtopic.php?f=380&t=37400
- https://www.draftdaysports.com/board/viewtopic.php?f=386&t=37570

**`metacritic.com`** — §6.2A, §6.2B, §6.3

- https://www.metacritic.com/game/draft-day-sports-pro-football-2025/
- https://www.metacritic.com/game/football-coach-college-dynasty/
- https://www.metacritic.com/game/front-office-football-eight/
- https://www.metacritic.com/game/retro-bowl/
- https://www.metacritic.com/game/retro-bowl/user-reviews/

**`wolverinestudios.freshdesk.com`** — §6.2A

- https://wolverinestudios.freshdesk.com/support/solutions/articles/44002010920-draft-day-sports-pro-football-user-guide-legacy-
- https://wolverinestudios.freshdesk.com/support/solutions/articles/44002010924-draft-day-sports-pro-football-game-plan-guide
- https://wolverinestudios.freshdesk.com/support/solutions/articles/44002148051-draft-day-sports-college-football-recruiting-guide
- https://wolverinestudios.freshdesk.com/support/solutions/articles/44002148052-draft-day-sports-college-football-scouting-guide
- https://wolverinestudios.freshdesk.com/support/solutions/articles/44002582595-dds-football-user-guide

**`forums.operationsports.com`** — §6.2A, §6.2B, §6.3, §6.5

- https://forums.operationsports.com/fofc/showthread.php?p=3391873
- https://forums.operationsports.com/forums/forum/football/ea-sports-college-football-and-ncaa-football/947333-does-anyone-do-auto-recruiting-in-dynasty
- https://forums.operationsports.com/forums/forum/football/ea-sports-college-football-and-ncaa-football/947541-how-to-identify-coverages-pre-snap-in-madden-25-and-college-football-25
- https://forums.operationsports.com/forums/forum/football/other-football-games/26874046-winning-tradition-football-released-today

**`onpapersports.com`** — §6.2A, §6.2B, §6.3

- https://www.onpapersports.com/
- https://www.onpapersports.com/blog/best-college-football-management-games
- https://www.onpapersports.com/blog/best-football-management-games
- https://www.onpapersports.com/winning-tradition-football

**`solecismic.com`** — §6.2A

- http://www.solecismic.com/documentation/dokuwiki/doku.php?id=faq
- http://www.solecismic.com/documentation/dokuwiki/doku.php?id=updates
- http://www.solecismic.com/frontofficefootball.php
- http://www.solecismic.com/reviews.php

**`zengm.com`** — §6.5

- https://zengm.com/
- https://zengm.com/blog/2023/11/football-drive-chart/
- https://zengm.com/blog/2023/11/play-by-play-redesign/
- https://zengm.com/blog/tag/live-sim/

**`boydsbets.com`** — §6.4

- https://www.boydsbets.com/college-football-home-field-advantage/
- https://www.boydsbets.com/key-numbers-for-college-football-totals/
- https://www.boydsbets.com/scoring-by-quarter-in-the-nfl/

**`collegefootballdata.com`** — §6.4

- https://collegefootballdata.com/api-tiers
- https://collegefootballdata.com/key
- https://collegefootballdata.com/terms

**`pff.com`** — §6.4

- https://www.pff.com/news/college-football-most-least-explosive-offenses-of-the-last-five-years
- https://www.pff.com/news/nfl-explosive-plays-and-re-thinking-offensive-success
- https://www.pff.com/news/nfl-home-field-advantage-pff-data

**`sports-reference.com`** — §6.4

- https://www.sports-reference.com/bot-traffic.html
- https://www.sports-reference.com/data_use.html
- https://www.sports-reference.com/termsofuse.html

**`taptap.io`** — §6.2A, §6.2B

- https://www.taptap.io/app/260894
- https://www.taptap.io/app/33599573
- https://www.taptap.io/app/33769262

**`americanfootballiq.com`** — §6.5

- https://americanfootballiq.com/blogs/news/football-coverages-101-the-ultimate-beginners-guide
- https://americanfootballiq.com/blogs/news/how-to-read-a-defense-a-step-by-step-guide-for-high-school-qbs

**`apple.com`** — §6.2B, §6.3

- https://www.apple.com/newsroom/2024/08/apple-arcade-launches-three-new-games-in-september-including-nfl-retro-bowl-25/
- https://www.apple.com/newsroom/2025/08/apple-arcade-exclusive-nfl-retro-bowl-26-launching-september-4/

**`bleacherreport.com`** — §6.4, §6.5

- https://bleacherreport.com/articles/1242852-all-22-available-for-all-nfl-fans-how-to-use-it-to-your-advantage
- https://bleacherreport.com/articles/1584737-why-college-football-teams-have-the-biggest-home-field-advantage-in-sports

**`ea.com`** — §6.2B

- https://www.ea.com/games/ea-sports-college-football/college-football-mobile
- https://www.ea.com/games/ea-sports-college-football/college-football-mobile/news/cfb-27-mobile-available-now

**`footballmanagerblog.org`** — §6.5

- https://www.footballmanagerblog.org/2025/09/fm26-match-day-experience-broadcast-mode-dynamic-highlights.html
- https://www.footballmanagerblog.org/2025/12/fm26-2d-camera-vs-3d-nostalgia-tactics.html

**`forbes.com`** — §6.2A, §6.4

- https://www.forbes.com/sites/barrycollins/2025/11/08/football-manager-26-is-it-as-bad-as-the-steam-reviews-suggest/
- https://www.forbes.com/sites/giovannimalloy/2024/12/04/college-football-strength-and-parity-sec-depth-big-ten-top-heavy/

**`forumsold.operationsports.com`** — §6.2A

- https://forumsold.operationsports.com/reviews/127/bowl-bound-college-football/
- https://forumsold.operationsports.com/reviews/853/front-office-football-eight/

**`grokipedia.com`** — §6.2B

- https://grokipedia.com/page/New_Star_Games
- https://grokipedia.com/page/Retro_Bowl

**`kodeco.com`** — §6.5

- https://www.kodeco.com/31561694-ios-accessibility-in-swiftui-create-accessible-charts-using-audio-graphs
- https://www.kodeco.com/books/swiftui-by-tutorials/v4.0/chapters/12-accessibility

**`manuals.ootpdevelopments.com`** — §6.5

- https://manuals.ootpdevelopments.com/index.php?man=ootp22&page=game_log
- https://manuals.ootpdevelopments.com/index.php?man=ootp23&page=game_log

**`ncaa.com`** — §6.4

- https://www.ncaa.com/news/football/2025-01-01/how-college-football-overtime-works
- https://www.ncaa.com/news/football/article/2023-08-25/fewer-clock-stoppages-first-downs-and-more-2023-college-football-rule-changes

**`ncaa.org`** — §6.4

- https://www.ncaa.org/news/2023/3/3/media-center-timing-rules-changes-proposed-in-football.aspx
- https://www.ncaa.org/news/2023/4/21/media-center-football-timing-rules-approved-for-divisions-i-ii.aspx

**`nfl.com`** — §6.5

- https://www.nfl.com/news/nfl-com-to-offer-fans-coaches-film-with-nfl-game-rewind-09000d5d82ac698a
- https://www.nfl.com/news/nfl-week-2-plays-to-rewatch-with-all-22-on-nfl-pro

**`operations.nfl.com`** — §6.5

- https://operations.nfl.com/game-operations-logistics/technology/performance-tracking-data-next-gen-stats
- https://operations.nfl.com/gameday/analytics/big-data-bowl

**`playbite.com`** — §6.2B

- https://www.playbite.com/q/how-to-change-plays-in-retro-bowl
- https://www.playbite.com/q/how-to-sim-retro-bowl-season

**`pmc.ncbi.nlm.nih.gov`** — §6.5

- https://pmc.ncbi.nlm.nih.gov/articles/PMC2430981/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC3181432/

**`pocketgamer.com`** — §6.1, §6.2B

- https://www.pocketgamer.com/football-manager-2025-mobile/cancelled/
- https://www.pocketgamer.com/retro-bowl/review/

**`pockettactics.com`** — §6.1, §6.2B, §6.3

- https://www.pockettactics.com/football-manager-2020-mobile/review
- https://www.pockettactics.com/retro-bowl/review

**`robwritesaboutwhatever.com`** — §6.2B

- https://robwritesaboutwhatever.com/2021/04/15/robs-complete-guide-to-retro-bowl-part-1-how-to-build-a-winning-front-office/
- https://robwritesaboutwhatever.com/2021/04/27/robs-complete-guide-to-retro-bowl-winning-football-games/

**`steambase.io`** — §6.2A, §6.2B

- https://steambase.io/games/football-coach-college-dynasty/steam-charts
- https://steambase.io/publishers/wolverine-studios

**`swiftwithmajid.com`** — §6.5

- https://swiftwithmajid.com/2021/09/01/the-power-of-accessibility-representation-view-modifier-in-swiftui/
- https://swiftwithmajid.com/2021/09/29/audio-graphs-in-swiftui/

**`youtube.com`** — §6.2B, §6.3

- https://www.youtube.com/watch?v=feeKPLPHd0I
- https://www.youtube.com/watch?v=mjnV5TDU-JA

**`actionnetwork.com`** — §6.4

- https://www.actionnetwork.com/ncaaf/explosiveness-isoppp-definition-college-football

**`amazon.science`** — §6.5

- https://www.amazon.science/blog/a-decade-of-nfl-next-gen-stats-innovation

**`aol.com`** — §6.4

- https://www.aol.com/articles/college-football-picks-discussion-turned-160452073.html

**`appbrain.com`** — §6.2B, §6.3

- https://www.appbrain.com/app/retro-bowl/com.newstargames.retrobowl

**`apprank.io`** — §6.2B, §6.3

- https://apprank.io/retro-bowl

**`athletesuntapped.com`** — §6.5

- https://athletesuntapped.com/blog/deciphering-the-defense-mastering-football-coverage-recognition/

**`avanderlee.com`** — §6.5

- https://www.avanderlee.com/swiftui/accessibility-uikit-developers/

**`bcftoys.com`** — §6.4

- https://bcftoys.com/all-drives

**`betting.us`** — §6.4

- https://www.betting.us/blog/nfl-blowout-stats-revealed/

**`beyondthescoresports.substack.com`** — §6.4

- https://beyondthescoresports.substack.com/p/breaking-down-home-field-advantage

**`bigbossbattle.com`** — §6.5

- https://bigbossbattle.com/review-blood-bowl-2-legendary-edition/

**`biorxiv.org`** — §6.5

- https://www.biorxiv.org/content/10.1101/2022.09.08.507113.full.pdf

**`byhoursplayed.com`** — §6.2B

- https://www.byhoursplayed.com/game.php?siteid=2151290

**`campus2canton.com`** — §6.4

- https://campus2canton.com/college-football-betting-101-the-fundamentals/

**`cgmagonline.com`** — §6.5

- https://www.cgmagonline.com/review/game/blood-bowl-2-legendary-edition-pc-review-gridiron-goblin/

**`conormclaughlin.net`** — §6.4

- https://conormclaughlin.net/2025/01/visualizing-nfl-kicker-accuracy-trends-1999-2024/

**`covers.com`** — §6.4

- https://www.covers.com/nfl/home-field-advantage

**`createwithswift.com`** — §6.5

- https://www.createwithswift.com/making-charts-accessible-with-swift-charts/

**`cultofmac.com`** — §6.2B

- https://www.cultofmac.com/news/apple-arcade-adds-nfl-retro-bowl-26

**`dash.harvard.edu`** — §6.5

- https://dash.harvard.edu/handle/1/41056876

**`deque.com`** — §6.5

- https://www.deque.com/blog/swiftui-accessibility-goodies-gotchas-part-2/

**`dknetwork.draftkings.com`** — §6.4

- https://dknetwork.draftkings.com/2023/4/21/23692944/ncaa-football-rules-changes-2023-game-clock-runs-on-first-down-no-stoppage

**`espnfrontrow.com`** — §6.5

- https://www.espnfrontrow.com/2013/09/virtual-yellow-1st-and-ten-line-debuted-on-espn-15-years-ago-today/

**`espnpressroom.com`** — §6.5

- https://espnpressroom.com/feature/virtual-yellow-1st-and-ten-line-debuted-on-espn-15-years-ago-today/

**`esports-news.co.uk`** — §6.5

- https://esports-news.co.uk/2025/09/25/football-manager-26-upgraded-match-day-experience-gameplay-revealed/

**`ethw.org`** — §6.5

- https://ethw.org/The_Making_of_Football%27s_Yellow_First-and-Ten_Line

**`feeds.bbci.co.uk`** — §6.1

- https://feeds.bbci.co.uk/news/articles/ckg0pm8k49ro

**`football.championsimleague.com`** — §6.2A

- https://football.championsimleague.com/college/HTML/Teams/112.html

**`footballfoundation.org`** — §6.4

- https://footballfoundation.org/news/2024/8/22/important-rule-changes-for-the-2024-college-football-season.aspx

**`forum.greydogsoftware.com`** — §6.2A

- https://forum.greydogsoftware.com/forum/40-bowl-bound-college-football-general-discussions/

**`gamalytic.com`** — §6.2B

- https://gamalytic.com/game/2151290

**`game-solver.com`** — §6.2B

- https://game-solver.com/the-program-college-football/

**`gamefaqs.gamespot.com`** — §6.5

- https://gamefaqs.gamespot.com/ps4/213591-blood-bowl-2-legendary-edition/faqs/78266/gameplay

**`gamegou.helpshift.com`** — §6.5

- https://gamegou.helpshift.com/hc/en/3-top-football-manager/faq/298-can-i-switch-between-2d-and-3d-matches/

**`gamerant.com`** — §6.2A

- https://gamerant.com/football-manager-26-steam-reviews-mostly-negative/

**`gamesbuilds.org`** — §6.2A

- https://www.gamesbuilds.org/News/college-football-26-why-auto-recruiting-is-still-the-most-underwhelming-feature.html

**`gamingonphone.com`** — §6.1

- https://gamingonphone.com/miscellaneous/football-manager-touch-vs-football-manager-mobile-difference/

**`grandstandcentral.com`** — §6.2A

- https://grandstandcentral.com/2018/sports/esports/the-momentous-rise-of-sports-management-games/

**`grantland.com`** — §6.5

- https://grantland.com/features/the-film-launch-thousand-questions-sources-offseason-stories/

**`greydogsoftware.com`** — §6.2A

- https://greydogsoftware.com/title/bowl-bound-college-football/

**`handwiki.org`** — §6.2B

- https://handwiki.org/wiki/Software:Retro_Bowl

**`imore.com`** — §6.1

- https://www.imore.com/gaming/ios-games/football-manager-2024-mobile-first-impressions

**`inreviewcritics.com`** — §6.2B, §6.3

- https://inreviewcritics.com/2023/10/23/top-5-biggest-differences-between-retro-bowl-college-and-retro-bowl/

**`invent.org`** — §6.5

- https://www.invent.org/inductees/stan-honey

**`jov.arvojournals.org`** — §6.5

- https://jov.arvojournals.org/article.aspx?articleid=2121950

**`kslsports.com`** — §6.4

- https://kslsports.com/500700/ncaa-college-football-clock-first-down-rule-change/

**`lindyssports.com`** — §6.4

- https://lindyssports.com/college-football/college-football-overtime-rules

**`link.springer.com`** — §6.5

- https://link.springer.com/article/10.1007/s10339-020-00954-y

**`loudpoet.com`** — §6.2A

- https://loudpoet.com/2026/01/18/my-newest-data-informed-obsession-ootp26/

**`matausch.itch.io`** — §6.2A

- https://matausch.itch.io/bound-for-glory

**`medium.com`** — §6.2A

- https://medium.com/@parkergoss/sports-management-games-and-simulators-arent-going-away-anytime-soon-c4ad39e32da7

**`mentalfloss.com`** — §6.5

- https://www.mentalfloss.com/article/27009/explaining-magic-yellow-first-down-line

**`nbcnews.com`** — §6.4

- https://www.nbcnews.com/sports/nfl/nfl-scoring-2024-season-offense-passing-down-rcna171985

**`ncsasports.org`** — §6.2A

- https://www.ncsasports.org/football/scholarships

**`netflix.com`** — §6.1

- https://www.netflix.com/tudum/articles/football-manager-26-mobile-game-news

**`newstargames.com`** — §6.2B

- https://www.newstargames.com/retro-bowl-college

**`nextgenstats.nfl.com`** — §6.5

- https://nextgenstats.nfl.com/highlights/play/type/team/season/week/playerId/2019092209/2375

**`nflanalytic.com`** — §6.4

- https://nflanalytic.com/explainer-one-score-games.html

**`nflfastr.com`** — §6.4

- https://nflfastr.com/

**`nflverse.nflverse.com`** — §6.4

- https://nflverse.nflverse.com/

**`nintendolife.com`** — §6.2B

- https://www.nintendolife.com/reviews/switch-eshop/retro-bowl

**`nxtbets.com`** — §6.4

- https://nxtbets.com/most-consistent-nfl-betting-trends-for-2025/

**`ootpdevelopments.com`** — §6.5

- https://www.ootpdevelopments.com/out-of-the-park-baseball-home/

**`pcgamer.com`** — §6.2A

- https://www.pcgamer.com/games/sim/football-manager-26-launches-straight-into-a-relegation-battle-as-steam-reviews-plummet-to-mostly-negative-been-playing-since-1993-and-this-is-the-worst-one/

**`press.disneyplus.com`** — §6.5

- https://press.disneyplus.com/news/monsters-funday-football

**`primegamesarena.com`** — §6.1

- https://primegamesarena.com/football-manager-review/

**`pubmed.ncbi.nlm.nih.gov`** — §6.5

- https://pubmed.ncbi.nlm.nih.gov/17997642/

**`purenintendo.com`** — §6.2B

- https://purenintendo.com/review-retro-bowl-nintendo-switch/

**`realsport101.com`** — §6.1

- https://realsport101.com/football-manager/fm-24-mobile-vs-touch-whats-the-difference/

**`researchgate.net`** — §6.5

- https://www.researchgate.net/publication/5848550_How_many_objects_can_you_track_Evidence_for_a_resource-limited_tracking_mechanism

**`retrobowl.college`** — §6.2B

- https://retrobowl.college/retro-bowl-college-teams

**`samhoppen.substack.com`** — §6.4

- https://samhoppen.substack.com/p/how-should-we-define-an-explosive

**`saturdaydownsouth.com`** — §6.4

- https://www.saturdaydownsouth.com/news/college-football/recruiting-expert-identifies-8-sec-teams-with-blue-chip-ratio-to-compete-for-national-championship/

**`sciencedirect.com`** — §6.5

- https://www.sciencedirect.com/science/article/abs/pii/S0010027708000097

**`semanticscholar.org`** — §6.5

- https://www.semanticscholar.org/paper/How-many-objects-can-you-track-Evidence-for-a-Alvarez-Franconeri/cbf6415cada79bd310b618743b6177b300c979e6

**`skysports.com`** — §6.1

- https://www.skysports.com/football/news/11095/13304515/football-manager-2025-sports-interactive-cancel-release-of-popular-game

**`slideshare.net`** — §6.5

- https://www.slideshare.net/slideshow/10qbreads/3018071

**`sncfl.us`** — §6.2A

- https://www.sncfl.us/Index.html

**`sportico.com`** — §6.4

- https://www.sportico.com/leagues/football/2024/nfl-stats-kickers-brandon-aubrey-1234800530/

**`sports.betmgm.com`** — §6.4

- https://sports.betmgm.com/en/blog/college-football/how-often-do-favorites-win-college-football-betting-ncaaf-bm06/

**`sports.yahoo.com`** — §6.4

- https://sports.yahoo.com/article/college-football-picks-average-winning-184434064.html

**`sportsenthusiasts.net`** — §6.4

- https://sportsenthusiasts.net/2024/08/30/is-the-two-minute-warning-impacting-college-football-game-length/

**`sportspro.com`** — §6.1

- https://www.sportspro.com/news/football-manager-2025-fm-sega-sports-interactive-video-game-february-2025/

**`sportsvideo.org`** — §6.5

- https://www.sportsvideo.org/2025/12/17/espn-to-debut-mnf-playbook-with-next-gen-stats-a-new-ai-driven-nfl-data-altcast/

**`stampedeblue.com`** — §6.4

- https://www.stampedeblue.com/2019/8/12/18256932/drive-success-rate-and-other-stats-i-love-points-per-drive-efficiency-td-fg-rate

**`statmuse.com`** — §6.4

- https://www.statmuse.com/nfl/ask/nfl-league-average-points-per-game-by-year-2001-to-2024

**`steamdb.info`** — §6.2A

- https://steamdb.info/publisher/Wolverine+Studios/

**`steamspy.com`** — §6.2A

- https://steamspy.com/app/2633170

**`techradar.com`** — §6.1

- https://www.techradar.com/gaming/football-manager-2025-canceled-as-sports-interactive-say-were-too-far-away-from-the-standards-you-deserve-and-releasing-the-game-in-its-current-state-would-not-be-the-right-thing-to-do

**`thehighertempopress.com`** — §6.1

- https://www.thehighertempopress.com/2024/09/is-football-manager-mobile-as-good-as-the-desktop-version/

**`thephinsider.com`** — §6.5

- https://www.thephinsider.com/2016/6/27/12039106/football-101-defensive-cover-schemes-aka-how-a-quarterback-reads-a-defense

**`toucharcade.com`** — §6.1

- https://toucharcade.com/2023/11/14/football-manager-2024-review-touch-vs-mobile-vs-ps5-vs-pc-steam-deck-features-save-controller-console/

**`twoplaymakers.com`** — §6.1

- https://twoplaymakers.com/how-many-seasons-can-you-play-in-football-manager/

**`vsin.com`** — §6.4

- https://vsin.com/college-football/determining-college-football-true-home-field-advantage/

**`walterfootball.com`** — §6.4

- https://walterfootball.com/nflmargins.php

**`whatifsports.com`** — §6.2B

- https://www.whatifsports.com/gd/

**`whats-on-netflix.com`** — §6.1

- https://www.whats-on-netflix.com/news/netflix-games/football-manager-2026-will-join-netflix-games-on-mobile-in-november-2025/

**`wolfsports.com`** — §6.5

- https://wolfsports.com/nfl/the-new-all-22-with-nfl-pro-is-a-positive-for-football-fans/

**`x.com`** — §6.4

- https://x.com/ESPN_BillC/status/1882050684255961275

---

# Part One — Prior research, carried forward

*Original document: "01 — Research: Reference App, Game Family, Community, Prior Sessions".
Compiled 2026-08-08 by Fable 5 from: all 68 screenshots in this folder, the GitHub repos, Play Store
pages, and r/FootballCoach.*

**Status under the v4 brief.** Tier B of `docs/reviews/2026-08-09-spec-prompt-v4.md` carries
sections **A, B, C, D, F and H** forward *verbatim or with additions only*. They are not superseded
by Part Two and must not be dropped. Sections **E and G are superseded** by the §6.2 and §6.3 work;
they are retained here in place, each annotated with a pointer to what replaced it and why. Nothing
has been deleted. Section order is as it was in the original file (A, B, C, D, E, G, H, F).

**Grade.** Part One carries no per-claim source URLs (register entry CF-1). Its reference-app
inventory (§A) is primary evidence — 68 screenshots of a shipping product. Its market and community
claims are secondary and, in two places, now contradicted by Part Two.

## A. Reference app — "College Football Simulator" (iOS, the screenshots)

Indie iOS app by **Mani Foroughi** (solo dev, SwiftUI, v1.20, £3.99 "God Mode" IAP). It is the modern-iOS reimagining of the college half of this genre and the direct UX template for our pro game. All 68 screenshots cataloged; near-duplicates are scroll states.

### Screen inventory (grouped)

| Area | Screens seen | Key mechanics visible |
|---|---|---|
| Onboarding | Main menu; 4-step wizard (League → Team → Coach → Confirm) w/ dot stepper | 134-team default league; custom league (JSON import/export, r/cfbsimulator community); prestige-ranked team picker w/ P4 tier badges; coach name/age/background trait (+1 skill branch); schemes (Pro, 4-3); recruiting difficulty; playoff format 4/8/12(“REALISTIC”)/16; promotion-relegation toggle; prestige cap slider; save name |
| Custom league creator | Modal w/ Load / Import URL / Save / Export JSON | Conferences, independents, bowls, championship logo, 0/32 subdivision, award renaming |
| Season hub (tab) | Preseason + regular-season variants | Phase pill; THIS WEEK card w/ LINE/WIN %/EDGE betting pills; Advance Week vs PLAY GAME; last-game card; Standings / Top 25 / News segments; Stats/Players/Awards quick links; preseason outlook (proj. record, top-25, impact players) |
| Live game | Coin toss; field view; quick-sim sheet | 2D field w/ LOS + first-down lines; drive-grouped play log w/ clock + tappable colored player names; suggested playcall banner; defense sets Base/Blitz/Nickel/Dime/Contain; timeouts; live win-probability bar; live box score; sim speeds Slow/Normal/Fast/Instant; sim-to targets (possession/Q/half/game) |
| Post-game | Matchup report; box score | Quarter-score chips; winner crown card; team stat table; per-position expandable player stat cards |
| Matchup preview | Pre-game sheet | Overall + O/D/ST bar comparisons w/ Home/Away edge chips; spread ↔ win-prob toggle |
| Schedule (tab) | Season list | WEEK badges, OOC/CONF chips, rank badges, spreads, W/L tinted result rows |
| Team (tab) | Team overview; depth chart; player cards ×10 positions | Prestige; schemes; injury report; auto-sort; starter/backup/reserve tints; OVR color tiers (purple 90+/blue/green/orange/red); class chips FR→RS SR; per-position attribute sets (QB Throw Power/Accuracy … K/P Power/Accuracy); Potential letter grades (A+…F); height/weight; season + game-by-game stats |
| Redshirts (preseason tab) | Planner | Per-position RS quotas (QB 0/2, RB 0/3), eligibility, auto-planner, Pre-RS locks |
| Stats | 9-category leaderboard suite | Passing/Rushing/Receiving/Tackles/Sacks/INT/PD/Kicking/Punting; per-category sort + direction; Min-G filter; week/season scope; search |
| Coach (tab) | Hub; My Coach; skill tree; goals; team search; trophy room; settings; credits; edit team/league | Level/XP; 4 skill branches (Recruiting/Development/Offense/Defense) w/ SP-cost node chains; seasonal goals w/ XP + progress; coach cash + salary + contract + Job Security %; retire→legacy; autosave/save/checkpoints; previous seasons; trophy grid (10 types); Game Center-style leaderboard w/ anon handles; God Mode IAP (£3.99: edit contracts, add SP); tutorial replay; theme-color toggle |

### UX patterns to carry over (proven on-device)

- Floating pill bottom tab bar, context-aware (preseason shows fewer tabs); sheets w/ "Done" pill; push for live game.
- Team-color dynamic theming after team selection; neutral accent pre-dynasty.
- Chips/pills for every metadata token; one concept per card; long scroll > dense tables; color-tiered ratings; empty states with icon + "No X yet"; captions under every setting.
- Betting-style predictor (LINE/WIN %/EDGE) as the hook on the weekly loop.
- Fictional naming: real cities/states + invented mascots (Palmetto State Sabal, Provo Wasatch; conferences Magnolia, Prairie, Rustbelt).

## B. Game family — Achi Jones "Football Coach" lineage

- **footballcoach (2016, Android, open source):** github.com/jonesguy14/footballcoach — Java engine (`CFBsimPack`: League/Conference/Team/Game/Player + position subclasses). 12-game season, 4-team playoff, 46-man roster, OVR/Potential + 3 position ratings, recruiting budget. **License: CC NonCommercial** → our build is a clean-room reimplementation: design inspiration only, zero code reuse. Abandoned Dec 2016.
- **Football Coach 2 (college, 2019, closed):** 60 teams/6 conferences; 4.5★ (1.68K). FC1 delisted.
- **Pro Football Coach (2016→2019, closed):** 4.2★ (1.36K), 100K+ installs, abandoned 2019. Shipped: 32 teams (2 conf × 4 div), 16-game season, playoffs = 4 division winners + 2 wildcards/conference; draft + tradeable picks; trade block with "View Offers" from all 31 AI teams; free agency limited by contract load; **contracts without a real cap** ("for simplicity"); player model = age, OVR, Potential, Durability, Football IQ, 3 position ratings; **no TE**; online leaderboard.
- **Community forks:** antdroidx CFB Coach Career Edition (120 teams, firing, coordinators, transfers, TE/LB/DL positions, editor), KushDingies Playcalling Edition (watch + call plays). Fan roster files hosted on GitHub = custom-content culture.
- **Dev's current path:** Steam. College Dynasty (95% positive, 1.4K reviews) → **Pro Football Dynasty** (Steam EA "late 2026"): realistic cap (proration, guarantees, void years, restructures, tags, dead money), two-tier positions incl. EDGE, ranged scouting, college-save import, Coach/GM/Franchise modes, commissioner mode. **Desktop only.**

## C. Community signal (r/FootballCoach, Play reviews)

> **The "Our answer" column is HISTORICAL and carries no authority.** The left column — the mined
> community signal — carries forward as evidence under Tier B. The right column was written against
> the superseded pro-only scope and now conflicts with the fixed owner parameters in four places:
> "IAP decision deferred" contradicts **P3** (paid premium, no IAP); "the lane is empty" is
> contradicted by this document's own §6.2B §5.1; "live play-by-play with play-calling both sides of
> the ball" pre-resolves **gate zero**, which §4 must decide with arithmetic; and "JSON league
> template import/export" is escalated to counsel in §6.2B §3.2 rather than committed. Read the
> right column as a record of what was once intended, never as a specification.

Validated demand — each maps to a v1 feature (→ `02-GAME-DESIGN.md`):

| Ask / complaint (source) | Our answer *(historical — see banner)* |
|---|---|
| "iOS port?" still asked Jul 2026; Android apps dead since 2019 | **The product**: modern native iOS pro sim — the lane is empty |
| No TE, shallow depth charts (PFC reviews) | Full position set incl. TE; drag depth chart; 53+16 PS |
| No defensive player stats / career stats (PFC reviews) | Full 9-category stat suite + career tables + records book |
| Progression "too random" (PFC review, 200 seasons) | Visible potential letters, age curves, camp reveal w/ arrows, dev traits |
| Contracts "not real cap" (dev's own admission) | Full cap: proration, guarantees, dead money, rookie scale, tags |
| Playcalling demand (KushDingies fork, College Dynasty success) | Live play-by-play with play-calling both sides of ball |
| Mid-season saves impossible in originals | Autosave weekly + checkpoints |
| Custom rosters/universes culture (GitHub roster repos) | JSON league template import/export (v1.5, architecture ready day 1) |
| Fast sim loop, "season in <10 min", free/no-ads ethos | Quick Sim tiers; instant advance; no ads; IAP decision deferred |
| Funny generated names, milestone stories | Name banks + news engine + records chasing |

## D. Prior-session extraction (user's working patterns)

Searched all CCD sessions: no prior football/iOS/game sessions exist — the project is genuinely new. What transfers is **methodology**, extracted from the Credit-OS / Deploy-C / COAS-V2 session history:

1. **Spec → plan → build → adversarial review → verify loop.** Sessions repeatedly ran "audit / critique / rebuild plan" cycles with adversarial reviewers before shipping. → Encoded as mandatory phase gates in `CLAUDE.md` (adversarial review + verification before a phase closes).
2. **Numbered, dependency-ordered work packages with one canonical shared doc.** The user's DEPLOY_C skill pack is `cp-0 … cp-8` modules under a `CANON_SHARED.md`. → Mirrored: numbered docs 00–05 with `02-GAME-DESIGN.md` as canon; phases P0–P8 in the implementation plan.
3. **Harness skills the user has installed and uses** (superpowers TDD/writing-plans/subagent-driven-development, adversarial-reviewer, confidence-review, rewrite-tournament, /code-review ultra). → Named explicitly in `CLAUDE.md` so Opus 5 invokes them instead of ad-hoc process.
4. **Checkpoint/restore mindset** (checkpoints, previous-seasons archives in their systems) → matches the game's own save/checkpoint design; also: commit-per-task discipline.

## E. Competitive positioning (one paragraph) — SUPERSEDED

> **SUPERSEDED — retained for the record, do not cite as current.** Replaced by **§6.3 (The market
> gap, argued as an output)**, with the underlying evidence in **§6.2A** and **§6.2B**. Two of this
> paragraph's load-bearing claims are now contradicted. (i) *"no modern pro football management sim"
> on iOS* — §6.2B §5.1 found **Football Coach: Winning Tradition** (On Paper Sports) shipping on the
> App Store, and §6.2B §5.2 documents **Pocket GM 3** in the same lane; the lane is not empty.
> (ii) The framing of the opportunity as a **category** gap — §6.3 argues every category slot in
> this market is occupied, and that the real opening is a **quality gap at an intersection**: nobody
> has shipped a football management sim on a phone that the player still believes in after twenty
> seasons. The v1 scope named here (*"fixed 32-team league"*, no college tier) is separately
> superseded by owner parameter **P2**, the unified college→pro career.

Modern iOS has a polished college sim (the reference app) but **no modern pro football management sim**: the 2016 PFC is abandoned Android-era, and its successor is Steam-only in late 2026. A SwiftUI pro sim that pairs the reference app's proven UX with the cap/draft/trade depth the community has been requesting for years fills a real, validated gap. Ship v1 focused (fixed 32-team league, full cap, playcalling, coach RPG), keep the community-content pipeline (league JSON) as the v1.5 growth hook.

## G. Retro Bowl mechanics research (for doc 06) — SUPERSEDED

> **SUPERSEDED — retained for the record, do not cite as current.** The Retro Bowl mechanics
> research is replaced by **§6.2B §2 (Retro Bowl)** and **§6.2B §3 (Retro Bowl College)**, which add
> the scale of the audience, session-length and throughput figures, the off-field agency inventory,
> the college-identity analysis that feeds D6, and a sourced community-complaint set. More
> importantly, this section's final bullet — *"Our responses (doc 06)"* — is **void**: it specifies
> direct player control (a full playbook, aimed throws, animated defensive possessions under the
> player's playcall), and the v4 mission removes all direct control of players during play.
> `docs/06-PLAYED-GAME-MODE.md` is retired accordingly; see `docs/DOC-MANIFEST.md`. What survives
> here is mechanical description of a competitor, which §6.2B §2.2–2.7 supersedes with sourced
> detail. Note also §H's arcade-mode reality check below, which remains correct about the *college
> sim* community and is completed by §6.2B §2.1 on the size of the audience that does want it.

Sources: Wikipedia, official store pages, retro-bowl fan wiki (CC-BY-SA, cross-verified), Poki, Pocket Gamer/Pocket Tactics reviews, Rob's mechanics guides. Key verified facts driving `06-PLAYED-GAME-MODE.md`:

- **Offense-only control**: player controls offensive snaps, FG/XP kick meter (two taps: power bar, sweeping aim arrow vs wind), and kick returns (mobile paywalls returns behind $0.99 IAP); own kickoffs/punts and the entire defense are simulated — opponent drives resolve as rapid text boxes. No onside kicks; sudden-death OT.
- **Throwing**: drag back from QB = aim with dotted landing arc, release = throw; second-finger tap toggles lob ↔ bullet; **QB Accuracy controls how much of the arc is rendered**, Arm Strength caps distance (~15→25+ yds), Stamina degrades arm over a game. No free pocket movement: throw, scramble (drag forward), or tap-handoff.
- **Carrier control**: auto-run upfield at stat speed; swipe up/down jukes (lane-based), swipe forward dive, swipe back stall; **no sprint button, no spin** — stiff-arms auto-trigger from Strength.
- **Player model**: exactly 4 attributes per position + star rating + hidden potential + condition + morale (7 tiers; low morale → fumbles/missed tackles); injuries rolled post-game weighted by usage/condition/age.
- **Plays**: no playbook — one dealt hybrid run/pass play per snap; audibles reroll it, count = QB level (1–5). Most-criticized design choice.
- **Meta→field**: coordinators (star-rated, with traits like Physio/Motivator/Scout) passively boost their side; facilities (stadium/training/rehab, levels 1–10, decay) move XP/morale/condition; salary cap ~$150M; Coaching Credits currency; fan-approval fail-state.
- **Structure/feel**: 1/2/3-min quarters, full game 5–10 min; landscape side-scroll pixel presentation; difficulty Easy→Extreme (Extreme = stat cheat) + Dynamic (auto-tunes); snow slows players, wind deflects kicks.
- **Community consensus**: loved — one-thumb skill throw, always-on-offense pacing, stats you can *feel*, franchise loop. Complained — defense is a dice-roll you watch, no real play-calling, too easy for veterans, FG meter disproportionately hard, returns paywalled. Retro Bowl College kept the engine, added college meta (recruiting, GPA, 250 teams, 12-team playoff).
- **Our responses** (doc 06): keep full playbook (their #1 strategy complaint), animate defensive possessions with your playcall instead of text boxes (#1 overall complaint), difficulty via AI reaction/closing not stat cheats, returns free, original presentation (no scanlines/CRT framing, our palette+fonts).

## H. Reference-app user comments mined (App Store + r/cfbsimulator, Aug 2026)

App = "CFB Simulator" (id 6752640167), 4.78★/625 US ratings; 86 reviews + full subreddit archive (395 posts, 1,312 comments) analyzed. Solo dev replies to 42% of posts, median 2.2 h — responsiveness itself earns 5★ reviews and IAP purchases. IAP: God Mode $3.99, scenario packs $2.99, **paid checkpoint tokens (= crash insurance)**.

> **The "Our answer" column is HISTORICAL and carries no authority** — same banner as §C above. The
> mined complaint data is evidence; the response column was written against the superseded pro-only
> scope, cites documents since deleted, and commits to features that either contradict
> **P3** or are pending counsel review. Read it as a record of intent, never as a specification.

**Complaint/request league table (→ what our design does):**

| Rank | Theme (share) | Our answer *(historical — see banner)* |
|---|---|---|
| 1 | **Crashes/save corruption/softlocks** — 34% of reviews; corruption ~season 8; end-of-game clock hangs, double-sim injuries, endless OT; users buy checkpoint tokens as crash insurance | Stability is a feature: atomic writes + rolling backup + migration fixtures (03 §5), soak-test gates (05 P7), hardened end-of-game state machine called out as top risk (00), **checkpoints free** |
| 2 | **Job-market dead ends** — contract expiry with zero offers = dead save | Invariant in 02 §10: carousel always yields ≥1 offer or explicit "unemployed year" path; poaching + proactive applications |
| 3 | **Sim believability** — "90 OVR struggling vs 76", late-game difficulty collapse, stat oddities (safeties, blocked kicks 10× too common, no long TDs, dead Q4, TE unused); **watched vs simmed games diverge** (dev-confirmed weighting bug; community meta = "watch games to get good results") | **One engine, one distribution** — parity test simmed-vs-played-retention in P2 gate; extended calibration bands (02 §4); AI teams rebuild so year-10 stays hard |
| 4 | **History/records/HoF** — top-upvoted request class; college dev blocked by save bloat ("100s of MB") | Records/HoF in v1; storage plan: aggregates in history, play-by-play trimmed (03 §9) |
| 5 | **Staff management** — hire/fire OC/DC/ST, scheme fit, start-as-coordinator | Coordinators v1 (02 §10); coordinator career mode backlog |
| 6 | Recruiting UX friction (filters, sort, undo, interest %) — loop itself loved | Same list-UX lessons applied to FA/draft/scouting screens (04 §11–12) |
| 7 | **Modding = community engine** (~86 posts share league JSONs via raw URLs); want in-app browser | JSON import/export v1.5; in-app community browser added to backlog |
| 8 | Stats presentation (benchmark: Pocket GM 3), prediction lines | Stats suite + records + spread pills in v1 |
| 9 | **Game-day control suite**: clock management/tempo ("chew clock"), smarter AI EV decisions, XP-after-expiring-TD sequencing, usage sliders, sit/play injured | Tempo toggle + fixed sequencing added to 02 §4; EV-driven AI; usage sliders backlog |
| 10 | Immersion: reacting social feed (signature feature), press conferences, awards | News engine v1; social-style feed + pressers = backlog candidates |

**Pro-version demand:** explicit but low-volume ("I hope you guys make a pro version!!", direct Reddit ask to dev, Pocket GM 3 cited twice as the pro benchmark, users hacking NFL leagues into the college app via custom JSON). Dev's family has **no pro title** — lane confirmed empty.

**Arcade-mode reality check:** in this community *nobody* requested joystick/arcade play — they want coach-brain control, speed options, trustworthy outcomes. Retro-style demand lives in a different (much larger, more casual) market. Hence doc 06's positioning: On-the-Field is one of three modes, never required, and the sim/playcall paths must stay first-class.

**Meta-lessons to copy:** ship fast + changelog posts to community, TestFlight beta, polls, answer within hours; monetize (if ever) via editor + scenario packs, never ads, never paid crash insurance.

## F. Legal guardrails

- No NFL/NFLPA/NCAA marks, team names, logos, or real player names/likenesses. All 32 teams fictional (naming table in GDD).
- No code from `jonesguy14/footballcoach` (CC NonCommercial) or forks — clean-room engine, own formulas.
- No asset/text copying from "College Football Simulator" (Mani Foroughi) — UX-pattern inspiration only; distinct branding, palette, icon.
- Betting-style pills present spreads as flavor only — no real-money framing.

---

# Part Two — v4 research, §6.0–§6.5

*Compiled 2026-08-09 by Fable 5 against §6 of `docs/reviews/2026-08-09-spec-prompt-v4.md`.*

Seven research parts, merged here unchanged apart from heading depth (each part's headings are
demoted one level so its sections nest under this document). Every part opens with its own method
section stating what its evidence can and cannot support; read that before quoting the part.
Every part closes with its own assumptions block and its own sources block — both are reproduced in
full below, and both are additionally consolidated at the top of this document.

The parts appear in the brief's order. §6.2 is two documents because the deep-sim pole and the
arcade / mobile-native pole are different competitive sets with different evidence: §6.2A covers
Draft Day Sports, Front Office Football and the Wolverine Studios catalogue; §6.2B covers Retro
Bowl, Retro Bowl College, Football Coach: College Dynasty and every other mobile-native American
football management sim found on the App Store and Play Store.

**Ordering matters and was followed.** The brief mandates §6.0 → §6.1 → §6.2 → §4, because gate zero
(agency density versus season throughput) must not be decided before the research that informs it.
§6.3 is an output argued from §6.0–§6.2 and §6.5, not an input.

**Cross-references.** The parts were written as separate files in `docs/research-parts/`, which no
longer exists — its content is here. References of the form `§6.2B §5.1` point at a section of this
document. References of the form `01-RESEARCH §C` or `docs/01-RESEARCH.md §H` point at **Part One
of this document**.

## §6.0 — Engagement post-mortem on the build that exists

**Status:** static half complete; experiential half specified but **not run**.
**Method:** source-level census of `Sources/ProFootballCoachUI/` (53 SwiftUI view types, 6,861 lines)
and the reachable engine paths in `Sources/FootballSimCore/` (12,274 lines).
**Governing brief:** `docs/reviews/2026-08-09-spec-prompt-v4.md` §6.0.
**Author's constraint:** see §0 immediately below. It is not a caveat, it is a boundary on what
this document is allowed to claim.

---

### 0. What this document cannot do, and why

**I cannot play the build.** Verified in this container, not assumed:

```
$ for t in swift swiftc xcodebuild xcrun simctl; do command -v "$t" || echo "NOT FOUND"; done
swift: NOT FOUND      swiftc: NOT FOUND     xcodebuild: NOT FOUND
xcrun: NOT FOUND      simctl: NOT FOUND
$ uname -a
Linux vm 6.18.5-fc-v20 ... x86_64 GNU/Linux
$ ls -d /usr/lib/swift /usr/share/swift /opt/swift
ls: cannot access '/usr/lib/swift': No such file or directory   (× 3)
```

No Swift toolchain, no Xcode, no simulator, Linux host. This matches `docs/STATUS.md:75-79`, which
records the same absence historically and adds that `download.swift.org` is refused by egress
policy. Therefore:

- Every claim below is derived from **reading source**, and carries a `file:line` citation.
- Nothing below is a play impression. Where I reason past the code to a probable player
  experience, the sentence is prefixed **INFERENCE** and the reasoning is shown.
- Where I cannot source a claim at all, it is prefixed **ASSUMPTION**.
- The experiential half is handed off as §8, a protocol written **before** it is run so it cannot
  be rationalised afterwards.

**One further boundary, and it is the most important sentence in this document.** The arcade code
in `HEAD` is **not the code the owner played** (§6.4). `docs/AUDIT.md` was generated against commit
`71a9d46`; the all-22 arcade rewrite (`ebb9e4e` … `47ac105`) landed afterwards. So the audit
describes a superseded arcade, and `STATUS.md`'s "played on device" line describes a superseded
arcade. Any protocol run against `HEAD` is measuring a third thing that nobody has ever run.

---

### 1. Headline findings, ranked by how much they should change a design decision

| # | Finding | Evidence |
|---|---------|----------|
| 1 | **The management week contains exactly one mandatory decision, and it is a decision about presentation, not about the team.** | §3 |
| 2 | **Zero inbound events. Nothing ever arrives asking the player to decide.** The game never initiates a conversation. | §3.4 |
| 3 | **"Call the Plays" calls no plays.** The whole game is simulated on `onAppear`; the buttons only reveal a finished log. | §2.2, §3.2 |
| 4 | **Jeopardy is frozen for an entire season.** `updateJobSecurity` runs once a year; the % shown to the player literally cannot move for ~20 weeks. | §5 |
| 5 | **2 of 24 coach skill nodes have a reachable effect.** 14 have no effect function at all; 5 have one no caller invokes; 3 are gated behind an unreachable loop. | §4.3 |
| 6 | **Scouting is unspendable.** The draft class does not exist until the draft room generates it, and the draft room has no scout button. 120 points/season with nothing to buy. | §6.2 |
| 7 | **The AI reads true ratings; the player reads a fog.** The only information asymmetry in the game runs *against* the player. | §6.1 |
| 8 | **Season-goal XP is paid repeatedly**, every week from completion onward, with no "already paid" flag. | §4.4 |
| 9 | **The arcade held ~99% of the build's decision volume.** `AUDIT.md` is right that `ArcadeGameView` is dead, and that fact has been used to describe a system that is very much alive. | §6.4 |
| 10 | **Trade proposals are free, unlimited and instantly adjudicated**, so the accept boundary is brute-forceable. | §6.3 |

---

### 2. Screen inventory

53 `View` types. I classify them as **2 shells**, **11 shared components**, **40 screens**.

A **DESTINATION** is a place you go to decide something: it mutates franchise state in a way a
reasonable coach could have chosen differently. A **READOUT** is a place you go to look at
something: it mutates nothing, or mutates only view-local presentation state (filters, segments,
pagination).

#### 2.1 Shells and components (not screens)

Shells: `RootView` (RootView.swift:5), `FranchiseShell` (RootView.swift:44).
Components: `CardBackground`, `Chip`, `EmptyStateView`, `PlayerRow`, `Rule`, `Stamp`,
`StepIndicator`, `SummaryRow`, `TeamBadge` (Theme/), plus `FieldCanvas`
(Features/FieldCanvas.swift:—, a pure renderer) and `MatchupPredictionRow`
(LiveGameView-adjacent, SeasonHubView.swift:269).

#### 2.2 The 40 screens

| # | Screen | File:line | Shows | Class |
|---|--------|-----------|-------|-------|
| 1 | `MainMenuView` | RootView.swift:80 | New / Load / Scenarios | **DESTINATION** (once per save) |
| 2 | `LoadFranchiseView` | RootView.swift:182 | Save list, delete | **DESTINATION** (once per save) |
| 3 | `NewFranchiseWizard` | NewFranchiseWizard.swift:5 | Team, coach, background, 7 rule toggles | **DESTINATION** (once per save) |
| 4 | `ScenarioPickerView` | LegacyViews.swift:5 | 3 preset challenges | **DESTINATION** (once per save) |
| 5 | `SettingsView` | SettingsView.swift:26 | Appearance, autosave, version | **DESTINATION** (preferences, not gameplay) |
| 6 | `TutorialView` | TutorialView.swift:8 | 5 cards, shown once | READOUT |
| 7 | `SeasonHubView` | SeasonHubView.swift:5 | Phase, matchup, last result, standings/power/news | **DESTINATION** (the whole week) |
| 8 | `MatchupPreviewSheet` | LiveGameView.swift:360 | 4 rating bars, home vs away | READOUT |
| 9 | `LiveGameView` | LiveGameView.swift:9 | Scoreboard + play-by-play list | READOUT (see below) |
| 10 | `GameReportView` | LiveGameView.swift:204 | Quarter scores, 6 team stats, box score | READOUT |
| 11 | `ArcadeFieldView` | ArcadeFieldView.swift:14 | All-22 field, playbook, defensive read | **DESTINATION** (densest in the app) |
| 12 | `ArcadeGameView` | ArcadeGameView.swift:14 | Side-on ball, drive log | **UNREACHABLE** — §6.4 |
| 13 | `ScheduleView` | LeagueViews.swift:141 | 18 rows, opponent + result | READOUT |
| 14 | `DivisionStandingsCard` | LeagueViews.swift:5 | 8 division tables | READOUT |
| 15 | `PowerRankingsCard` | LeagueViews.swift:58 | 1–32 with OVR | READOUT |
| 16 | `NewsFeedCard` | LeagueViews.swift:105 | Last 40 headlines | READOUT |
| 17 | `TeamView` | TeamViews.swift:5 | Identity, 3 rating bars, schemes, 4 nav rows | READOUT + hub |
| 18 | `DepthChartView` | TeamViews.swift:121 | Roster by position, reorderable | **DESTINATION** |
| 19 | `PlayerCardView` | TeamViews.swift:269 | Identity, contract, stats, attributes, traits | READOUT + **one** action (release) |
| 20 | `InjuryReportView` | TeamViews.swift:490 | Injured list | READOUT |
| 21 | `StaffView` | TeamViews.swift:522 | Budget, 4 coordinators, scheme fit | READOUT — **no hire, no fire** |
| 22 | `StatsView` | ArcadeGameView.swift:195 | 7 leaderboard categories | READOUT |
| 23 | `FrontOfficeView` | FrontOfficeViews.swift:5 | Cap bar, owner patience, job security, 4 nav rows | READOUT + hub |
| 24 | `ContractsView` | FrontOfficeViews.swift:118 | Roster sorted by cap hit | READOUT |
| 25 | `FreeAgencyView` | FrontOfficeViews.swift:154 | Market, position filter | **DESTINATION** |
| 26 | `OfferSheet` | FrontOfficeViews.swift:225 | Years, salary, PS toggle, interest bar | **DESTINATION** |
| 27 | `TradeCenterView` | FrontOfficeViews.swift:334 | Partner picker, two multi-selects | **DESTINATION** |
| 28 | `DraftBoardView` | FrontOfficeViews.swift:442 | Prospects + 3 scouting actions | **DESTINATION** — inert, §6.2 |
| 29 | `CoachView` | CoachViews.swift:5 | Level, XP, career, contract, 8 nav rows | READOUT + hub |
| 30 | `SkillTreeSheet` | CoachViews.swift:188 | 4 branches × 6 nodes | **DESTINATION** — mostly inert, §4.3 |
| 31 | `SeasonGoalsSheet` | CoachViews.swift:272 | Goal progress bars | READOUT |
| 32 | `HistoryView` | CoachViews.swift:320 | Past seasons, champions, awards | READOUT |
| 33 | `OffseasonHubCard` | CoachViews.swift:356 | 8-stage pipeline + advance | **DESTINATION** (offseason only) |
| 34 | `JobOffersSheet` | CoachViews.swift:461 | Offers when out of work | **DESTINATION** (offseason only) |
| 35 | `DraftDayView` | DraftDayView.swift:8 | Board, on-the-clock, picks so far | **DESTINATION** (offseason only) |
| 36 | `ReSignView` | DraftDayView.swift:234 | Expiring contracts + asking price | **DESTINATION** (offseason only) |
| 37 | `NegotiationSheet` | DraftDayView.swift:294 | Years, salary, acceptance bar | **DESTINATION** (offseason only) |
| 38 | `TrophyRoomView` | LegacyViews.swift:— | Titles, conference finals, awards | READOUT |
| 39 | `RecordsView` | LegacyViews.swift:— | Season + career record book | READOUT |
| 40 | `HallOfFameView` | LegacyViews.swift:— | Inductees | READOUT |

**Count: 19 destinations, 20 readouts, 1 unreachable.**

That ratio is not itself damning — readouts are what a management game is made of. What is damning
is **when** the destinations are available:

- 5 destinations are **setup only** (#1–5): touched once per save, never again.
- 5 destinations are **offseason only** (#33–37).
- 1 destination is **structurally inert** (#28, `DraftBoardView` — §6.2).
- 1 destination opens only when `coach.skillPoints > 0` (#30).

**That leaves 7 destinations reachable during a normal in-season week**: `SeasonHubView`,
`ArcadeFieldView`, `DepthChartView`, `FreeAgencyView` + `OfferSheet`, `TradeCenterView`, and the
release button on `PlayerCardView`. Against **20 readouts** that are available every single week and
change only their numbers.

#### 2.3 The readout that is dressed as a destination

`LiveGameView` (#9) is labelled **"Call the Plays"** on the button that opens it
(SeasonHubView.swift:164-168). It calls no plays. `LiveGameView.play()` runs on `.onAppear`:

```swift
// LiveGameView.swift:66-72
private func play() {
    guard record == nil, let league = app.league else { return }
    var rng = league.rng
    let result = GameSimulator.simulate(game: game, in: league, rng: &rng, retainPlays: true)
    app.mutate { $0.rng = rng }
    record = result
}
```

The entire game — all four quarters — resolves before the first frame is drawn. The controls that
follow are `Next Play` (+1), `Drive` (+8), `Quarter` (+35) and `Sim to End`
(LiveGameView.swift:170-180, 43-51), all of which only move `revealedPlays`, an index into an
already-final array. The screen's own file comment concedes the design
(LiveGameView.swift:64-65: *"Runs the game once, up front… The result is identical whichever mode
they picked."*).

**INFERENCE** (reasoning: a control labelled with a verb that does not perform that verb is the
textbook shape of a "bland application" complaint). The most prominent, `borderedProminent`,
team-tinted button on the home screen promises agency and delivers a pager. If a single UI element
explains the owner's diagnosis, this is my candidate. It is testable in §8 (Probe P3).

---

### 3. Decisions per in-game week

#### 3.1 Walking the week-advance path

Entry: `SeasonHubView.body` → `matchupCard(game)` (SeasonHubView.swift:128-179). Three buttons:

```swift
// SeasonHubView.swift:156-175
Button { app.advanceWeek() }            label: { Label("Sim Week", …) }        // .bordered
Button { playMode = .callPlays }        label: { Label("Call the Plays", …) }  // .borderedProminent
Button { playMode = .onField }          label: { Label("On the Field", …) }    // .bordered, orange
```

Routing (SeasonHubView.swift:53-60): `.callPlays → LiveGameView(game:, arcade: false)`;
`.onField → ArcadeFieldView(game:)`.

- **Sim Week** → `AppState.advanceWeek()` (AppState.swift:205) → `SeasonEngine.advanceWeek`
  (SeasonEngine.swift:39) → `advanceRegularSeasonWeek` simulates every unplayed game in the week
  including the user's (SeasonEngine.swift:67-80), applies injuries, heals, drifts morale, appends
  news, advances the phase. **One tap. Zero decisions.**
- **Call the Plays** → §2.3. **Zero decisions.** Terminates in `finish()` →
  `advanceWeek(userGameResult:)`.
- **On the Field** → `ArcadeFieldView` → `ArcadeGameModel` → `InteractiveGame`. This is the only
  branch containing decisions, and it is enumerated in §3.3.

On a bye: `byeCard` offers a single `Advance Week` button (SeasonHubView.swift:200). In preseason:
a single `Kick Off the Season` button (SeasonHubView.swift:99).

#### 3.2 The census

**Mandatory decisions (must be resolved to advance the week): 1.**

> Which of the three play modes to use.

And it is worth being precise about what kind of decision that is. `Sim Week` and `Call the Plays`
produce **the same result from the same seed** — `LiveGameView` simulates with the league RNG and
hands the record back (`advanceWeek(userGameResult: record)`, LiveGameView.swift:75), and
`STATUS.md:121-123` records a test asserting that retaining the play-by-play cannot change a
result. Only `On the Field` changes the outcome distribution, via `PlayExecution`
(PlayExecution.swift:13-41). So the mandatory weekly decision is:

> *How many minutes do I want to spend, and do I want to influence the result?*

That is a decision about the player's own time budget. It is not a coaching decision. **A
management game whose week contains one mandatory decision, and whose one mandatory decision is
about pacing, is bland by arithmetic.**

**Optional decisions (player must go looking; nothing prompts them): 7.**

| Decision | Where | Reversible? | Visible consequence? |
|---|---|---|---|
| Reorder depth chart at a position | `DepthChartView` `.onMove` → `AppState.moveDepthChart` (AppState.swift:424) | Yes | **No** — nothing on screen reports the effect |
| Auto-sort by rating | `AppState.autoSortDepthChart` (AppState.swift:416) | Effectively yes | No |
| Elevate / demote a practice-squad player | `CapEngine.elevate/demote` (AppState.swift:380, 390) | Yes, cap and floor permitting | Yes — refusal strings name the exact door (AppState.swift:398-414) |
| Release a player | `AppState.cut` (AppState.swift:362) | **No** — dead money | **Yes** — `cutMessage` prices it *before* confirming (TeamViews.swift:301-308) |
| Sign a street free agent | `AppState.sign` (AppState.swift:367) | **No** | **Yes** — live interest bar + refusal reason (FrontOfficeViews.swift:261-269, 315-330) |
| Propose a trade | `TradeEngine.evaluate/execute` (FrontOfficeViews.swift:416-438) | **No** once accepted | **Yes** — verdict string |
| Unlock a skill node | `CoachEngine.unlock` (AppState.swift:436) | **No** — no respec path exists | **Nominally** — node text; but see §4.3 |

**Confirmations (not decisions): 10+.** `Advance Week` (bye), `Finish Week`, `Kick Off the Season`,
`Next Play` / `Drive` / `Quarter` / `Sim to End`, `Tap for full matchup preview`, the
standings/power/news segment picker, `OK` on refusal alerts, `Save Franchise`, the autosave toggle,
`Continue` in the draft room.

#### 3.3 The one branch that is dense

`ArcadeFieldView` + `ArcadeGameModel`, per **user offensive snap**:

- Play call: 6 options (`OffensivePlay.standardCalls` = insideRun, outsideRun, shortPass, deepPass,
  playAction, screen — PlayMatrix.swift:18-19), rendered as a 3-column grid
  (ArcadeFieldView.swift:245-256).
- On 4th down: `Field Goal` (if in range) and `Punt` added (ArcadeFieldView.swift:259-279).
- Live: drag-to-aim + release, or scramble (flick forward), or `Hand Off`, or `throwTo(target)` from
  the receivers list (ArcadeFieldView.swift:186-221, 302, 309-327).
- `Audible`, limited to `min(4, max(1, 1 + (awareness-60)/10)) + (coordinator ≥ 80 ? 1 : 0)` per
  game (ArcadeGameModel.swift:79-81).
- Carrier: juke left/right, dive, stall (ArcadeFieldView.swift:201-212).
- Kick: two timed taps, power then aim (ArcadeFieldView.swift:352-387).

Per **opposition snap**: defensive call from 6 (`DefensivePlay.allCases`, PlayMatrix.swift:39-40),
coverage shade from 5 (`CoverageShade.allCases`, DefensiveInputs.swift:4-5), plus `Skip Ahead`
(ArcadeFieldView.swift:406-447).

**INFERENCE** (reasoning: arithmetic on the above, not observation). A full arcade game at ~65
offensive snaps offers ≥65 play calls plus 1–3 in-snap inputs each, and ~65 defensive snaps offering
a call and a shade. Even discounting the defensive side entirely and counting only the play call,
that is **~65 decisions in the arcade week against 1 in the management week** — roughly two orders
of magnitude. This is the single most decision-relevant number in this document and it is developed
in §6.4.

#### 3.4 The finding that is not a count: nothing ever arrives

I searched for any code path that presents the player with a decision they did not go looking for.

- **Inbound trade offers:** none. `TradeEngine.evaluate` and `TradeProposal(` have exactly one
  call site outside the engine — `TradeCenterView.propose()` (FrontOfficeViews.swift:416-424),
  which is user-initiated. The AI never proposes.
- **Contract disputes / holdouts:** no such concept in the model.
- **Owner messages:** `ownerPatience` is a static `Int` per team, set once at generation
  (`rng.int(in: 2...5)`, LeagueFactory.swift:102) and rendered as bullets
  (FrontOfficeViews.swift:88). It never changes and it never speaks.
- **Injury replacement prompts:** `applyInjuries` writes `injuryWeeksRemaining` directly
  (SeasonEngine.swift:262-270); nothing surfaces a decision. `InjuryReportView` is a list.
- **Staff changes:** `runCoachingCarousel` (OffseasonEngine.swift:144) hires and fires
  coordinators *for* the player, with no consultation. `StaffView` has no hire/fire control —
  a grep for `hire` in `ProFootballCoachUI/` returns nothing.
- **Job offers:** the one genuine inbound event, and it fires at most once per season, only in the
  offseason, and only if the player has been sacked or run out of contract (§5).

**So the week has one mandatory decision and zero inbound events.** The player must self-start
every optional interaction, on screens whose layout is identical every week and whose numbers move
by small amounts. **INFERENCE** (reasoning: no prompt, no novelty, no state change the player is
told about): the well-documented failure mode of that shape is that the player stops opening those
screens after the first two or three weeks. This is exactly what §8 Probe P2 measures.

---

### 4. Reversibility, commitment and visible consequence

#### 4.1 There is no undo, and every mistake is persisted instantly

`AppState.mutate` is the single funnel for state change and it calls `autosave()` unconditionally
(AppState.swift:196-201), which calls `persist()` (AppState.swift:166). There is no undo stack, no
confirm-then-commit staging, no "revert week". The only rollback is `Load Franchise` — and by then
autosave has already written.

**INFERENCE** (reasoning: risk that cannot be walked back usually *increases* engagement; risk that
is also unannounced and unpriced usually just produces resentment). The build gets the commitment
right on three of four committing decisions — release, sign and trade all price themselves before
the player commits. It gets it wrong on the fourth, `unlockSkill`, which is irreversible, unpriced
and, per §4.3, mostly inert.

#### 4.2 Consequence visibility, decision by decision

**Well done, and worth carrying forward:**

- `cutMessage` (TeamViews.swift:301-308) states dead money and cap saving **in the confirmation
  dialog**, before the button is pressed.
- `OfferSheet` shows a live `FreeAgencyEngine.interest` bar as the player moves the slider
  (FrontOfficeViews.swift:261-269, 296-304) and disables the button below 0.45.
- `AppState.describe(_:RosterMoveError)` (AppState.swift:398-414) turns every refusal into a
  sentence naming the specific constraint, including the exact shortfall
  (`"Calling him up costs \(Format.money(short)) more than you have in space."`).
- `NegotiationSheet` shows a live acceptance bar and a plain-English verdict
  (DraftDayView.swift:328-334, 366-373).

**Not done:**

- **Depth chart.** The most-repeated weekly decision reports nothing. Reordering starters changes
  who the simulator uses, but `DepthChartView` displays no team rating, no before/after, no
  projection. The player is asked to do work whose effect is invisible at the point of doing it.
- **Skill tree.** §4.3.
- **Season goals.** `SeasonGoalsSheet` is a readout of bars; goals are set by
  `CoachEngine.makeSeasonGoals` (CoachEngine.swift:214-275) with no player input and no negotiation.

#### 4.3 The progression system is almost entirely inert

`SkillTrees.nodes(for:)` defines **4 branches × 6 nodes = 24 nodes** (CoachEngine.swift:24-74), each
with a name and a promise ("Explosive Plays — Big plays come more often", "Turnover Chain —
Takeaways come more often", "Fourth-Down Analytics — Sharper go-for-it recommendations").

Every `hasUnlocked(branch:node:)` call site in the entire engine
(`grep -rn "hasUnlocked(branch:" Sources/FootballSimCore/`, minus the two guards inside `unlock`
itself):

| Node | Effect function | Is the effect function ever called? |
|---|---|---|
| development 0, 1 | `developmentBonus` (CoachEngine.swift:134) | **Yes** — `ProgressionEngine.swift:51` |
| scouting 0, 1 | `scoutingFogReduction` (CoachEngine.swift:161) | Yes — `DraftEngine.swift:147` (but see §6.2) |
| scouting 2 | `scoutingPoints` (CoachEngine.swift:155) | Yes — `AppState.swift:92, 273` (but see §6.2) |
| offense 0, 1 | `offenseRatingBonus` (CoachEngine.swift:141) | **No call site anywhere** |
| defense 0, 1 | `defenseRatingBonus` (CoachEngine.swift:148) | **No call site anywhere** |
| development 5 | `injuryRateMultiplier` (CoachEngine.swift:168) | **No call site anywhere** |
| the other **14** nodes | — | **No effect function exists** |

So of 24 purchasable nodes:

- **2** have a live, reachable, experienceable effect (development 0 and 1: +10% each to training-camp
  gains).
- **3** have a wired effect gated behind a loop the player cannot reach (§6.2).
- **5** have an effect function that no caller ever invokes — dead code.
- **14** are text.

**The entire coach career — XP, levels, skill points, four themed branches, a dedicated tab and a
dedicated sheet — resolves to a ±20% modifier on one offseason stage.** This is not a polish gap;
it is the reward half of the progression loop being absent. `AUDIT.md` could not see this because
its scope was `Sources/ProFootballCoachUI/` only (`AUDIT.md:3-5`), and the defect is a missing
*engine* call site.

#### 4.4 Season-goal XP is paid repeatedly (likely bug, engagement-relevant)

`AppState.advanceWeek` calls `refreshGoals()` after every week (AppState.swift:205-210), which calls
`CoachEngine.settleGoals` (AppState.swift:221-228). `settleGoals` recomputes each goal's progress
and then:

```swift
// CoachEngine.swift:315-318
if goals[index].isComplete {
    award(.goalCompleted(goals[index].experienceReward), to: &league.coach)
    completed.append(goals[index])
}
```

`SeasonGoal` has no `hasBeenPaid` field (CoachEngine.swift:175-210) and `settleGoals` sets no flag.
So a *"Win 9+ games"* goal (100 XP) that completes in week 12 pays **again in weeks 13–18 and every
playoff round**. `.capSpace` and `.topDefense` goals are re-evaluated weekly and pay on every week
they happen to read true.

**INFERENCE** (reasoning: `award` loops `while experience >= experienceForNextLevel`, granting a
skill point per level — CoachEngine.swift:104-111): levels and skill points inflate several-fold
against the intended curve. Combined with §4.3, the loop is *earn inflated currency → spend it on
nodes that mostly do nothing*. Flagged for runtime confirmation as §8 Probe P6, because I cannot
execute the code.

---

### 5. Where jeopardy lives, and how often it can bite

Jeopardy in this build is one number: `coach.jobSecurity` (Staff.swift:186, default 50 at :207).

#### 5.1 It updates once per season

`grep -rn "updateJobSecurity" Sources/` returns exactly one non-definition call site:
`OffseasonEngine.swift:430`, inside `case .seasonReview` — the **first** of eight offseason stages.
`settleHeadCoachJob` likewise has exactly one call site: `OffseasonEngine.swift:436`, inside
`case .coachingCarousel`.

**Consequence:** across an 18-week regular season (`LeagueRules.seasonWeeks = 18`) plus up to 4
playoff weeks, `jobSecurity` **cannot change**. The `ProgressView` on `CoachView`
(CoachViews.swift:164) and the one on `FrontOfficeView` (FrontOfficeViews.swift:90) are the app's
only pressure gauges, they are shown prominently, and they are **constants for ~22 consecutive
weeks**. The warning text `"The owner is losing patience."` (CoachViews.swift:167) either shows all
season or none of it.

**INFERENCE** (reasoning: a gauge that does not move is not a gauge). A player who checks job
security in week 3, week 6 and week 9 and sees the identical number learns that the screen is not
worth opening. This is directly measurable — §8 Probe P4.

#### 5.2 How hard it actually bites

```swift
// CoachEngine.swift:331-343
let expected = max(0.30, min(0.70, (team.overallRating - 58) / 34))
let actual   = record.winPercentage
let patience = Double(team.ownerPatience)          // rng.int(in: 2...5), LeagueFactory.swift:102
var swing    = (actual - expected) * 120 / max(1, patience * 0.6)
if champion  { swing += 45 }
if playoffs  { swing += 12 }
league.coach.jobSecurity = min(100, max(0, jobSecurity + Int(swing.rounded())))
```

Firing test: `let sacked = league.settings.coachFiringEnabled && league.coach.jobSecurity <= 12`
(CoachEngine.swift:402). Taking a new job resets security to 55 (CoachEngine.swift:377).

Worked example — a genuinely bad season (4-13 = 0.235) on an average roster (expected 0.50), at
median patience 3 (divisor 1.8, multiplier 66.7):

| Season | Swing | Security after | Fired? |
|---|---|---|---|
| start | — | 50 | |
| 1 | −17.7 | 32 | no |
| 2 | −17.7 | 14 | no |
| 3 | −17.7 | 0 (floored) | **yes** |

At patience 5 (multiplier 40) the same catastrophic run takes **5 seasons**. Under P4 (6–8 hours per
season), that is **18–40 hours of play before the game's central stake can resolve against the
player** — and it resolves in a single offscreen call inside an offseason stage the player advances
with a button labelled `Run Season Review`.

#### 5.3 What the carousel does right

Credit where the code earns it. `CoachEngine.jobOffers` (CoachEngine.swift:455-497) guarantees a
non-empty list: if no team clears the openness and reputation filters, the lowest-reputation team in
the league makes an offer anyway (:479-494). `OffseasonHubCard` blocks the pipeline while offers
are outstanding (CoachViews.swift:371-382), `AppState.advanceOffseasonStage` guards on it
(AppState.swift:258), and `JobOffersSheet` is `.interactiveDismissDisabled()` (CoachViews.swift:506)
so a stray swipe cannot decide a career. `STATUS.md:124-125` records this as a deliberate answer to
a soft-lock in the reference game. **This is a Tier B lesson and it should survive the rebuild
verbatim.**

#### 5.4 Nothing else threatens the player

- Losing a game costs: standings position, −3 morale league-wide (SeasonEngine.swift:288), news
  headlines. No cash, no owner reaction, no player reaction, no staff reaction.
- Cap trouble is enforced automatically for AI teams (`settleRostersAndCap`,
  OffseasonEngine.swift:322) and blocked at the point of signing for the player. It cannot become a
  crisis the player has to dig out of during a season.
- Injuries reduce ratings and heal on a timer. There is no decision attached to them.
- The `coachFiringEnabled` toggle in the wizard (NewFranchiseWizard.swift:159) lets the player turn
  the *only* jeopardy in the game off at setup, before understanding what it is.

---

### 6. Information asymmetry

#### 6.1 What each side knows

**The player knows, for free, about every team in the league:**

- Every team's `overallRating` — `PowerRankingsCard` lists all 32 with OVR (LeagueViews.swift:94-96);
  `ScheduleView` chips the opponent's OVR on every row (LeagueViews.swift:198-200);
  `matchupCard` shows both teams' OVR plus a computed win probability and point spread
  (SeasonHubView.swift:188, 269-307).
- Every player's exact `overall`, on any roster — `TradeCenterView` lists the partner's roster with
  overalls (FrontOfficeViews.swift:365-370); `StatsView` links to `PlayerCardView` for any player on
  any team, which renders the **full attribute grid** (TeamViews.swift:437-463).
- Every free agent's exact overall **and potential grade** (FrontOfficeViews.swift:190).
- The exact acceptance probability of any contract offer, live, before committing — `interest`
  (FrontOfficeViews.swift:296) and `acceptance` (DraftDayView.swift:361) are both rendered as
  `ProgressView`s that update as the sliders move.

**The player does not know:** a draft prospect's true overall (fogged to a `scoutedLow…scoutedHigh`
band of ±6…9, DraftEngine.swift:80-89) and his potential grade until revealed
(DraftEngine.swift:160-162).

**The AI knows:** everything the player knows, plus **the prospects' true ratings**:

```swift
// DraftEngine.swift:250-252  — DraftEngine.aiSelection
let scored = prospects.map { prospect -> (DraftProspect, Double) in
    var score = Double(prospect.trueOverall)          // ← not the scouted band
```

The AI's only handicap is `rng.gaussian(mean: 0, sd: 3.5)` of evaluation noise
(DraftEngine.swift:256-257). The player's handicap is a ±6…9 band he cannot clear (§6.2).

**So the one fog in the game is applied to the player and not to the opponent.** That is
asymmetry pointing the wrong way. In the games this genre competes with, the player's edge over the
AI *is* the reason to do the work; here the work is unavailable and the edge is negative.

#### 6.2 The scouting loop cannot be executed

`DraftBoardView` (FrontOfficeViews.swift:442) is reachable from the Front Office tab every week of
the year and offers three real actions with real costs (`narrow` 10, `revealPotential` 25,
`fullReport` 40 — DraftEngine.swift:115-120) against a real budget
(`scoutingPointsPerSeason = 120`, LeagueRules.swift:71).

It renders `app.draftClass`, which is `league.draftClass`. Tracing every write to that property:

| Site | Effect |
|---|---|
| `AppState.startNewFranchise` :93 | `new.draftClass = []` |
| `AppState.beginDraftIfNeeded` :284-285 | populates **if empty**, called from `DraftDayView.onAppear` (DraftDayView.swift:35) |
| `AppState.completeDraftStage` :328 | `$0.draftClass = []` |
| `OffseasonEngine.advanceStage` `.draft` :467-470 | generates prospects, runs the whole draft, then `signUndrafted` calls `prospects.removeAll()` (DraftEngine.swift:343) |

There is **no path that populates `draftClass` before the draft stage**. Therefore:

1. For the entire regular season and playoffs, `DraftBoardView` shows the empty state
   *"No draft class yet — Prospects appear once the season reaches the draft."*
   (FrontOfficeViews.swift:447-452).
2. At the `.draft` offseason stage, `OffseasonHubCard` presents `Enter the Draft Room`
   (CoachViews.swift:405-410) → `DraftDayView` → `.onAppear { app.beginDraftIfNeeded() }`, which
   generates the class **and immediately** calls `session.advanceToUserPick(league:)`
   (AppState.swift:288-289), running every AI pick up to the player's slot in the same frame.
3. `DraftDayView` itself has **no scouting control** — it renders `prospect.scoutedRange`
   (DraftDayView.swift:97) and offers only `Draft`, `Let the Staff Pick`, `Continue` and
   `Sim Rest of Draft`.

**The class comes into existence already on the clock.** 120 scouting points per season are granted
(AppState.swift:92, 273) and can never be spent. Two skill-tree nodes that improve scouting
(`Sharper Eye I/II`) and one that grants +40 points (`Extra Scouts`) are purchases against a
currency with no market.

**INFERENCE** (reasoning: the draft is the one event `DraftSession`'s own doc comment calls *"the
one day a year a franchise game should slow down"*, DraftSession.swift:43-44). The build has a fog
model, a points economy, a three-action scouting menu, a sleeper detector
(`ScoutingEngine.sleepers`, DraftEngine.swift:175-179 — also never called from the UI) and a steal/bust
generator (DraftEngine.swift:60-68), and the player reaches none of it. The most interesting system
in the codebase is walled off by a data-lifecycle ordering bug.

#### 6.3 Negotiation and trade have no hidden information at all

- `OfferSheet` and `NegotiationSheet` both display the acceptance probability live as the player
  drags the slider. The player can dial to exactly the threshold. The only uncertainty left is the
  roll itself (`AppState.reSign` :343-358 rolls `rng.chance(chance)`; free agency gates hard at
  `interest < 0.45`, FrontOfficeViews.swift:277).
- `TradeCenterView.propose()` is free, instantaneous, unlimited and stateless — no counter, no
  cooldown, no per-week limit, no relationship cost. `TradeEngine.evaluate` returns
  `.accepted` / `.rejected(reason)` immediately (FrontOfficeViews.swift:424-437). The player can
  toggle checkboxes and re-propose until the boundary is found.

**INFERENCE** (reasoning: a search problem with a free oracle is not a decision). Trade and
contract negotiation are the two places a management game normally hides its best information, and
here both are solved by brute force in seconds.

#### 6.4 The arcade layer: establishing what is actually true

The brief asks this to be *tested rather than assumed in either direction*. Four separate claims are
in play and they resolve differently.

**Claim 1 — `AUDIT.md` says `ArcadeGameView` is dead code whose only gate is statically false.
VERDICT: TRUE.** Verified independently of the audit:

```
$ grep -rn "LiveGameView(" Sources/
Sources/ProFootballCoachUI/Features/SeasonHubView.swift:57:  case .callPlays: LiveGameView(game: game, arcade: false)
$ grep -rn "ArcadeGameView(" Sources/
Sources/ProFootballCoachUI/Features/LiveGameView.swift:26:   ArcadeGameView(
```

One call site, passing `arcade: false`; `isFinished` initialises to `false`
(LiveGameView.swift:19); the gate is `if arcade && !isFinished` (LiveGameView.swift:25). Statically
false. `ArcadeGameView` (330 lines) can never be constructed. `AUDIT.md:796-798` and its own
adversarial appendix at `:926` reach the same conclusion by the same route.

**Claim 2 — therefore "the arcade layer" is dead. VERDICT: FALSE, and this is the substantive
correction.** The audit's finding is scoped to one file. The arcade *system* is live and it is the
largest single feature in the repo:

| Component | Lines | Reachable? |
|---|---|---|
| `Sources/FootballSimCore/Arcade/` (10 files: `SnapKernel`, `Choreographer`, `Coverage`, `DefensiveInputs`, `FieldGeometry`, `Formations`, `Openness`, `Pocket`, `Routes`, `RunLanes`) | 2,376 | Yes |
| `ArcadeFieldView.swift` | 504 | **Yes** — SeasonHubView.swift:56, unconditional button |
| `ArcadeGameModel.swift` | 469 | Yes |
| `FieldCanvas.swift` | 208 | Yes |
| `ArcadeGameView.swift` | 330 | **No** |
| **Total arcade** | **3,887** | 3,557 live / 330 dead |

3,887 lines — **~21% of the whole codebase** (19,135 lines across both targets) — and the
"On the Field" button that reaches it sits on the home screen's matchup card with no gate, no
setting and no unlock (SeasonHubView.swift:170-175).

**Claim 3 — `STATUS.md` says this was the part the owner actually played on device.
VERDICT: TRUE, BUT NOT OF THIS CODE.** `STATUS.md:56` records *"Play calling, aiming and the kick
meter played on device — a 51-yard field goal made through the meter."* But `STATUS.md:70-79` states
that Phase 4C — the all-22 field, i.e. `SnapKernel` + the current `ArcadeFieldView` — **has never
been compiled**. Both cannot describe the same build. Git resolves it:

```
47ac105 Merge pull request #1 — Arcade mode: the all-22 field (Phase 4C)   ← 4C lands
...
6ef0d0b feat(arcade): render and play the all-22 field
5b4d433 feat(arcade): spatial kernel for the all-22 field
ebb9e4e docs: redesign On the Field around a live all-22 2D field         ← 4C begins
...
b4bd2df docs: native audit                                                 ← AUDIT.md committed
71a9d46 docs: replace .impeccable.md with PRODUCT.md and DESIGN.md         ← AUDIT.md's target
```

`AUDIT.md:3` states it was generated against `71a9d46`. Corroborating evidence that the audit
describes the *pre*-4C arcade: it cites `startPocketClock`, `pocketFraction`, `carryFraction`,
`"Secure It"`, `"Fight for Yards"` and `"Pass protection remaining"`
(`AUDIT.md:383-387, 342, 549`). **None of those symbols or strings exist anywhere in `HEAD`.**

So there are three distinct arcades in this project's history:
1. the 4B aim-and-throw arcade — **played on device, audited**;
2. `ArcadeGameView` — a side-on presentation-only view, **dead**, and its comment concedes the
   design (`"Every mode runs the same simulation — playing it out never changes the result."`,
   ArcadeGameView.swift:179-181);
3. the 4C all-22 arcade in `HEAD` — **never compiled, never audited, never played**.

**This is the load-bearing caveat for the whole of §6.0.** The owner's engagement memories attach
to (1). The audit's findings attach to (1). The code a play-session protocol would run attaches
to (3). §8 is written to keep these separate.

**Claim 4 — what was the arcade substituting for? VERDICT: it was carrying the decision density
the management layer never had.**

The interface between them is deliberately narrow and deliberately capped. `PlayExecution`
(PlayExecution.swift:13-41) is four axes centred on zero, and its doc comment states the contract:
*"zero means 'as well as the AI would have done it', so a player who never touches the controls
gets the simulated game."* The caps (ArcadeTuning.swift:234-240):

```swift
completionSwing = 0.20   // most a perfect snap adds to completion probability
yardsSwing      = 6.0    // most execution adds or removes, in yards
kickSwing       = 0.18
defensiveSwing  = 0.10
```

with the comment at :228-231 that these are *"deliberately still short of 'thumbs beat scouting'"*.

So the arcade was **not** substituting for roster quality — it was explicitly bounded so it could
not. What it substituted for is:

1. **Decision volume.** ~65 play calls per game against 1 mandatory decision per management week
   (§3.3). It is the only surface in the app where the player makes a choice more than once a week.
2. **Presentation.** Without it the match is a `List` of `Text` rows (LiveGameView.swift:85-106).
3. **Moment-to-moment jeopardy.** Season-level jeopardy is frozen for 22 weeks (§5.1); the sack
   warning (`sackWarningActive`, ArcadeFieldView.swift:290-295) and the closing coverage window are
   the only tension the build generates on any timescale shorter than a year.
4. **Making ratings legible.** `ArcadeTuning.indicatorLatency` (:83-85) maps awareness 40→0.90 s and
   99→0.15 s of delay before the openness colour updates, with the comment *"The colour is never a
   lie; a poor passer simply learns about it late."* `visibleArcFraction` (:111-113) truncates the
   drawn ball flight for an inaccurate passer. These are the only places in the build where an
   attribute is expressed as something other than a number in a grid.

**The design consequence, stated without recommending direct control.** P1 and the mission remove
direct player control. That removal deletes the surface carrying ~99% of the build's decision volume
and all four functions above. Nothing in `Tier C`'s discarded design replaces them. **If the rebuild
removes the arcade and does not deliberately re-source those four functions in the management layer,
it reproduces the blandness at higher fidelity.** That is the §3/§4 argument, and it is an argument
from arithmetic (65 vs 1), not from taste. Whether the replacement is per-snap agency, high-leverage
situational call-ins, or something else entirely is §4's job — but §4 must clear a stated decision-
volume bar, not merely assert that depth produces engagement.

---

### 7. Two more things worth knowing before §4 is decided

#### 7.1 Dead settings in the setup wizard

`LeagueSettings.autoCallPlays` is exposed as a toggle labelled **"Coordinators call plays"**
(NewFranchiseWizard.swift:162). `grep -rn "autoCallPlays" Sources/` returns only its declaration
(League.swift:144, 155, 164) and that toggle. **Nothing reads it.** A player who turns it on gets no
change. Meanwhile `AppState.isBusy` is declared and never read or written
(AppState.swift:54) — the app has no loading state despite `AUDIT.md:77` measuring 84–112 ms
synchronous saves on the main actor.

Every other wizard setting is genuinely wired: `salaryCapEnabled` (CapEngine ×4),
`injuriesEnabled` (GameSimulator :503), `tradeDifficulty` (TradeEngine :163),
`showPredictionLine` (SeasonHubView :145), `playoffFormat` (SeasonEngine ×2,
StandingsCalculator :151), `coachFiringEnabled` (CoachEngine :402, 409).

#### 7.2 A clock-management lever exists in the engine and is never surfaced

`Tempo` (`normal`, `hurryUp`, `chewClock`, PlayMatrix.swift:—) is threaded through
`PlayResolver` (×4 call sites) and `GameSimulator` (×2), and is chosen entirely by
`PlayCaller.tempo(situation:)` (PlayCaller.swift:305-306). No UI in `ProFootballCoachUI/` references
it. Clock management — one of the four discrete high-leverage decision families §4 must consider —
is already modelled in the engine and simply never handed to the player.

**Same for schemes.** `team.offensiveScheme` / `defensiveScheme` are displayed as chips
(TeamViews.swift:79-80), used for staff scheme-fit chips (Staff.swift:147-148), and **never
settable** — there is no write site outside `Team.init`. Scheme identity, which the mission names as
a core pillar, is a read-only label.

---

### 8. Hand-off: the owner play-session protocol

**Stated before it is run. Do not amend after running it — amend it in a separate revision with a
dated note, so any post-hoc rationalisation is visible.**

#### 8.0 Preconditions

1. Machine with Xcode 26.6+ and an iOS 26 simulator or iPhone 15-generation-or-newer device.
2. `brew install xcodegen && xcodegen generate --spec App/project.yml`, then
   `swift build && swift run -c release SimTests` (per `STATUS.md:23-32`).
3. **Record which build you are running.** Note the commit SHA. If it is `HEAD` (post-`47ac105`),
   you are running the 4C all-22 arcade, which has never compiled — **expect build failures and
   record them as data, not as an obstacle.** If it does not build, run the protocol against
   `71a9d46` instead and label the session `4B-ARCADE` throughout. Sessions against different
   arcades must never be pooled.
4. Have a stopwatch that logs laps, and a notebook (paper is fine). **Do not use the app to record
   the app.**

#### 8.1 What to do, in order

**Session A — cold first session (target 45 min, stop at 60 regardless).**

| Step | Action | Record |
|---|---|---|
| A1 | Launch, `New Franchise`. Choose any team. **Do not read the tutorial cards; skip.** | Wall-clock from launch to franchise created |
| A2 | Advance to the season hub. Before touching anything, write down in one sentence what you think you are supposed to do this week. | The sentence, verbatim |
| A3 | Play weeks 1–3 using **Sim Week** only. Do not open other tabs unless you genuinely want to. | Per week: wall-clock; every tab opened; every decision taken |
| A4 | Play weeks 4–6 using **Call the Plays**. | Same, plus: at what point did you stop pressing `Next Play` and press `Sim to End`? |
| A5 | Play weeks 7–9 using **On the Field**. | Same, plus: snaps played before you pressed `Sim to Final` |
| A6 | Stop. Do not continue into the offseason in this session. | Total elapsed |

**Session B — the maintenance loop (target 40 min).** Fresh sitting, same save.

| Step | Action | Record |
|---|---|---|
| B1 | Weeks 10–18, your choice of mode each week, chosen honestly. | Per week: mode chosen and **why**, in three words |
| B2 | Each week, before advancing, open Front Office → note `Job security`. | The number, every week |
| B3 | Each week, open the Draft Board once. | What it says |
| B4 | Any week you feel the urge to do roster work, do it and note it. Any week you don't, note that too. | Weeks with roster work vs without |

**Session C — the offseason (target 60 min).**

| Step | Action | Record |
|---|---|---|
| C1 | Run the offseason stage by stage. At each stage, before pressing the button, write what you expect it to do. | Expectation vs what happened |
| C2 | At `Re-Sign Window`, negotiate with at least three players. | Did you ever offer *less* than the acceptance bar recommended? |
| C3 | At `Draft`, enter the draft room. | Whether you were able to scout anyone before your first pick; scouting points remaining at the end of the draft |
| C4 | After `Season Review`, check `Job security`. | Before and after |
| C5 | Open the Skill Tree, buy a node, and try to detect its effect over the following season. | Which node; whether any effect was ever observable |

**Session D — the honest continuation (uncapped, stop when you want to stop).**

Play on. **The instruction is to stop when you actually want to stop, not at a milestone.** Note
the wall-clock time and what was on screen at that moment.

#### 8.2 What to record, precisely

For every in-game week, one row:

```
week | mode | wall-clock (mm:ss) | match time | mgmt time | screens opened |
decisions offered | decisions taken | confirmations pressed | one-line note
```

Definitions, fixed in advance so they cannot drift:

- **Decision offered** — a control that changes franchise state and where a reasonable coach could
  have chosen otherwise. `Advance Week`, `Finish Week`, `OK`, `Continue`, `Next Play`, `Drive`,
  `Quarter`, `Sim to End` are **confirmations**, not decisions.
- **Decision taken** — one you actually made, not one that was merely available.
- **Screen opened** — a distinct view pushed or presented. Count each **first** open per week.
- **Match time** — from entering a play mode to returning to the hub.
- **Management time** — everything else in that week.

Plus, once per session:

- **Attention-drop minute.** The first moment you notice you are going through motions,
  reaching for your phone, or skipping a step you'd previously done. **Record the minute and what
  was on screen.**
- **Last thing that held it.** The most recent moment before that where you were genuinely
  interested. Name the screen and the reason.
- **Screens opened once and never again.** At the end of every session, list every screen you
  opened in an earlier session and did not open in this one.

#### 8.3 Six specific probes, each with a stated threshold

Written now so the result cannot be reinterpreted later.

| Probe | Question | Confirms blandness if… | Disconfirms if… |
|---|---|---|---|
| **P1** Decision density | How many genuine decisions per in-season week? | Median **≤ 2** across weeks 10–18 | Median **≥ 5** |
| **P2** Screen abandonment | How many of the 20 readouts are opened in week 3 and never again? | **≥ 12 of 20** abandoned by week 10 | **≤ 5** abandoned |
| **P3** The mislabelled button | Does "Call the Plays" read as agency? | You press `Sim to End` within **90 s** on ≥ 2 of the 3 weeks in A4, **and** describe the mode as "watching" | You play ≥ 2 full games through the play-by-play by choice |
| **P4** Frozen jeopardy | Does the pressure gauge do anything? | The week-by-week `Job security` log (B2) is a **constant**, and you stop checking it before week 15 | The number moves, or you keep checking because it feels live |
| **P5** Mode preference | Which mode does an honest player choose? | You choose `Sim Week` on **≥ 7 of 9** weeks in B1 | You choose `On the Field` on **≥ 4 of 9** |
| **P6** Progression legibility | Is the reward loop felt? | You cannot name a single observable effect of any skill node after a full season (C5), **and** your coach level after one season exceeds **6** (which would corroborate §4.4's repeated-payout finding) | You can name an effect you actually observed |

**Composite verdict rule, fixed in advance:** blandness is **confirmed** if **P1 and P2 both trip**,
regardless of the others — those two are the arithmetic. It is **partially disconfirmed** if P1 or
P2 clears; in that case the diagnosis is not "too few decisions" and §4 must look elsewhere,
most likely at presentation and feedback rather than agency density.

#### 8.4 The arcade question, kept separate

The brief asks whether the arcade was holding attention and what it substituted for. §6.4 answers
the *what it substituted for* half from source. The *was it holding attention* half needs one extra
probe, and it must **not** be run on `HEAD` without labelling:

| Probe | Question | Threshold |
|---|---|---|
| **P7a** | On the 4B build (`71a9d46`), does the arcade hold attention longer than the management layer? | Compare A5's per-week wall-clock and the attention-drop minute against A3/A4. Arcade is load-bearing if its attention-drop minute is **≥ 2×** the management layer's. |
| **P7b** | On `HEAD`, does the 4C arcade build and run at all? | Binary. Record the failure output. This also settles `STATUS.md`'s unverified-4C gap and D11. |

**P7 is the only probe that can be run against two different arcades, so it is the only one that
must record its build SHA in every row.** If P7a shows the arcade held attention roughly twice as
long, that is evidence a tactile layer was load-bearing — which §3 explicitly invites the package to
argue, and which must then be reconciled against P1 (the mission's ban on direct control) rather
than resolved by preference.

#### 8.5 Reporting rule

Report against this protocol **including the parts that disconfirm the diagnosis**. If P1 or P2
clears, say so in the first paragraph. A post-mortem that only finds what it went looking for is
worth less than no post-mortem, because it launders an assumption as evidence.

---

### 9. Assumptions register

Everything the analysis rests on that I could not source:

| # | Assumption | Why it matters | How to settle |
|---|---|---|---|
| A1 | ~65 offensive snaps per game in this engine | §3.3's decision arithmetic and §4's budget both scale on it | Instrument `GameRecord.plays` on a real run; §4 must declare it anyway |
| A2 | The player checks `Job security` more than once per season | §5.1's "frozen gauge" conclusion assumes it is looked at | §8 Probe P4 |
| A3 | An honest player does not voluntarily re-do depth-chart work with no feedback | Underpins §4.2's "not done" verdict | §8 B4 |
| A4 | 4C (`HEAD`) has still never been compiled since `STATUS.md` was written | Governs whether §8 can run against `HEAD` at all | §8 Probe P7b — one command |
| A5 | The repeated goal-XP payout (§4.4) actually fires at runtime and is not suppressed by something I missed | Would change the progression-curve conclusion | §8 Probe P6's level check |

### 10. What this contributes to the decisions downstream

- **§4 (gate zero)** now has a floor to clear, not a vibe to satisfy: whatever agency model is
  chosen must beat **1 mandatory decision per week**, and must supply the four functions the arcade
  was carrying (§6.4). It should state its own decisions-per-week figure and defend it.
- **D8 (jeopardy)** must move job security off an annual cadence. A stake that resolves once every
  18–40 hours is not a stake. Keep the never-dead-end carousel (§5.3) exactly as it is.
- **D10 (AI quality)** has a concrete first requirement: the AI must not read through fog the player
  cannot clear (§6.1).
- **D9 (onboarding)** should note that the first fifteen minutes currently contain a five-card
  tutorial promising *"Call the play, drag to aim the throw"* (TutorialView.swift:—) about a mode
  reached by a button the tutorial never names, and a home screen whose most prominent button
  performs none of the verb on its face.
- **D13 (content volume)** gets a warning from §4.3: 24 authored skill-node strings, 2 of which do
  anything, is the cost profile to avoid. Authored content without a wired effect is not content.

---

## §6.1 — Football Manager Mobile (specifically)

Research part for `docs/reviews/2026-08-09-spec-prompt-v4.md` §6.1. Scope is **Football Manager
Mobile (FMM)** — the phone SKU — not desktop FM, not FM Touch, not FM Console. Where a claim is
about desktop FM it is marked as such, because conflating the two is the main way this research
question gets answered wrongly.

---

### 0. Method, and what limits this document

**Tooling constraint, stated up front.** In the executing environment, direct page fetch
(`WebFetch`) is refused by the egress policy for every domain attempted — `community.sports-interactive.com`,
`fmmvibe.com`, `toucharcade.com`, `en.wikipedia.org`, `thehighertempopress.com`, `reddit.com`. All
content below therefore arrived via `WebSearch`, which returns page-derived text from the indexed
pages. Every URL in §9 is a real page whose content was surfaced; **none of them was read in full.**

Consequences the owner should hold in mind:

- Quoted phrasing is page-derived and reliable as to substance, but I cannot guarantee I have the
  surrounding qualification of any individual forum post, and I cannot attribute forum claims to a
  named poster or a date.
- Reddit is not retrievable at all (the search agent is blocked from `reddit.com`). The
  player-voice evidence in §6 and §7 comes from **FMM Vibe** and the **Sports Interactive
  community forums** instead, which are the two largest FMM-specific communities and are arguably
  better sources for this question than r/footballmanagergames (which is desktop-dominated).
- Anything I could not source is labelled **ASSUMPTION** or **DERIVED** inline and collected in §8.
  Nothing is presented as sourced that is not.

**Version scope.** Two builds matter:

- **FM24 Mobile (FMM24)**, launched November 2023, Netflix-exclusive.
- **FM26 Mobile (FMM26)**, launched **4 November 2025**, Netflix-exclusive, iOS + Android.
  ([Netflix Tudum](https://www.netflix.com/tudum/articles/football-manager-26-mobile-game-news),
  [What's on Netflix](https://www.whats-on-netflix.com/news/netflix-games/football-manager-2026-will-join-netflix-games-on-mobile-in-november-2025/))

There is **no FM25 Mobile**: SEGA and Sports Interactive cancelled Football Manager 2025 on all
platforms in February 2025, explicitly including the Netflix mobile version, saying the game was
"too far away from the standards you deserve".
([Pocket Gamer](https://www.pocketgamer.com/football-manager-2025-mobile/cancelled/),
[Sky Sports](https://www.skysports.com/football/news/11095/13304515/football-manager-2025-sports-interactive-cancel-release-of-popular-game),
[BBC](https://feeds.bbci.co.uk/news/articles/ckg0pm8k49ro),
[TechRadar](https://www.techradar.com/gaming/football-manager-2025-canceled-as-sports-interactive-say-were-too-far-away-from-the-standards-you-deserve-and-releasing-the-game-in-its-current-state-would-not-be-the-right-thing-to-do))
So FMM24 was the live product for two years, and FMM26 is a two-year development. That matters for
§5: the FMM24→FMM26 delta is the clearest available signal of what SI thinks a mobile management
sim needs, because they had two years to decide.

One structural fact colours everything: **FM26 Mobile is the only edition of FM26 not rebuilt in
Unity.** FM26, FM26 Touch and FM26 Console moved to the new engine and new UI; Mobile did not.
([footballmanager.com — Game Comparison](https://www.footballmanager.com/compare-games),
[FM26 Mobile features](https://www.footballmanager.com/fm26/features/mobile))
FMM is a separate, older, deliberately narrower codebase — not a settings-reduced build of the
desktop game. Treat it as a distinct product designed under mobile constraints, which is exactly
why it is the right reference for this project.

---

### 1. The actual turn loop — what a week consists of

#### 1.1 The primitive is the **day**, not the week

There is one advance control. `[Continue]` sits **in the top-right corner, next to the current
date**; selecting it advances the game.
([SI manual, FMM26 — The Interface](https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/the-interface-r5245/),
[The Home Screen](https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/the-home-screen-r5246/))

The clock therefore runs in **days**, and the player taps through them. FMM players discuss
"skipping days" and whether they "skip months or play every game" as a normal part of how they
play. ([FMM Vibe — Skip days](https://fmmvibe.com/forums/topic/51038-skip-days/))

There is **no instant-result button in FMM**. Years of feature requests exist (threads from 2019
through 2025), and the community's standing workaround is to *holiday for one day* — which
produces a result but **does not use your team selection**.
([SI forums — Instant Result: 3 options, including what 'already exists' in-game](https://community.sports-interactive.com/forums/topic/590274-instant-result-3-options-including-what-already-exists-in-game/),
[SI forums — \[Suggestion\] Instant Result for FM Mobile](https://community.sports-interactive.com/forums/topic/585022-suggestion-instant-result-for-fm-mobile/),
[SI forums — Instant Result](https://community.sports-interactive.com/forums/topic/569604-instant-result/))
This is a **deliberate friction**: the fastest legitimate path through a season still routes the
player through the match screen. FM26 *desktop* added an Instant Result option; Mobile did not.
([Operation Sports](https://www.operationsports.com/football-manager-26-adds-instant-result-option-for-matches/))

The escape hatch is **Holiday**, from the Manager panel. You configure what the assistant may do in
your absence (transfers in/out, whether to retain your squad selection and tactics), and you pick
from four durations — one of which is **"Next Match / Next Day"**, i.e. holiday *to the next
fixture*. You can also auto-apply for better jobs while away. Delegating carries the stated risk
of being sacked in your absence.
([SI manual, FMM26 — You, the Manager](https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/you-the-manager-r5260/))

#### 1.2 The surfaces a week can touch

From the FMM26 manual's own section list — Home, Interface, Main Menu, Starting a New Game, Your
Team, Tactics, Team Report, Training, Development Hub, You the Manager, Match Day, Options
([SI manual index, FMM26](https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/)) —
a between-match week can involve:

| Surface | What it is | Delegable? |
|---|---|---|
| **Home / dashboard** | Calendar, finances, fixtures & results, medical centre summary of squad fitness and availability | n/a |
| **Inbox** | Mail icon on the side menu | n/a |
| **Training** | Overview of the club's training programme; **new in FMM26**, per-match preparation, with coaching and scouting staff advising what to prepare for | Yes — Staff Roles |
| **Tactics** | Formation, roles/duties, team instructions, set pieces | No |
| **Squad / Squad Management** | Central page for quick squad actions — listing for transfer or loan | No |
| **Development Hub** | Training, mentoring, squad management and youth development, with backroom advice on the overview | Partly |
| **Team Report / Pre-Match Hub** | Opponent strengths, weaknesses, form, predicted XI, danger men, style of play; media prediction, board expectation, fan mood | n/a |
| **You, the Manager → Staff Roles** | Assign responsibility for training, youth development, reserve team, chief scout; assistant can take friendlies, **match preparation**, squad numbers, mentoring partnerships | — |

([SI manual FMM26: Home Screen, Training, Your Team, Tactics, You the Manager, Options](https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/);
[footballmanager.com — FM24 Mobile new features](https://www.footballmanager.com/features/football-manager-2024-mobile-new-features-revealed))

#### 1.3 Taps and real decisions per week

**No published tap counts exist.** The following is **DERIVED** from the surface list, the
delegation options and the community's description of the routine loop ("set up a tactic, buy your
team, and then progress through the season making occasional changes" —
[FMM Vibe, *Opinion: What Is The Point of FMM?*](https://fmmvibe.com/forums/topic/43226-opinion-what-is-the-point-of-fmm/)):

A steady-state FMM week, with training and match prep delegated, is roughly:

- **~3–6 `[Continue]` taps** to walk the days between fixtures.
- **1 inbox pass**, mostly acknowledgement (injuries, board notes, scout reports).
- **1 Pre-Match Hub read** — genuinely informational, and the main input to the one tactical choice.
- **1 team selection** (drag/tap on Squad or Tactics).
- **0–2 tactical edits** — mentality for this opponent, maybe a role swap.
- **Match.**
- **Post-match hub / team meeting.**

That is on the order of **15–30 taps and 2–4 genuinely two-sided decisions per week** outside
transfer windows. The rest is confirmation. Transfer windows spike this by an order of magnitude
and are where the *real* decision density lives — which is the pattern the owner's own §6.0
post-mortem should be checked against.

**The transferable observation:** FMM does not manufacture weekly decisions to fill the week. It
lets most weeks be nearly empty and concentrates agency in (a) the match, (b) the transfer window,
(c) opponent-specific preparation. It then makes the empty weeks *cost almost nothing to pass*.

---

### 2. Session length

#### 2.1 Marketing copy (labelled as such, not evidence)

- "built for decisive play and quick progress, distilling the drama and deep strategy of soccer
  management into an experience you can pick up and master **in minutes**"
  ([App Store — FM26 Mobile](https://apps.apple.com/us/app/football-manager-26-mobile/id6446123740))
- "the fastest and most-streamlined game flow" of the FM24 family
  ([TouchArcade FM24 review](https://toucharcade.com/2023/11/14/football-manager-2024-review-touch-vs-mobile-vs-ps5-vs-pc-steam-deck-features-save-controller-console/))
- "a lightweight, pick-up-and-play football management simulation experience for those on the move
  or with less time on their hands" ([SI / gmgames developer bio](https://gmgames.org/developer/sports-interactive/))

Discount all of this. It states an intent, not a measurement.

#### 2.2 Player reports (the actual evidence)

**Sitting length.** The FMM community's own answer to "where do you find so much time to play FM?"
is that FMM is designed to be played "on the way to work/school, whilst you have a tea break or
simply any point you have a bit of time spare", and that **"most people play it in bursts of a few
minutes up to an hour or so."** The thread describes the same people playing "a few games whilst
sat on the toilet", others wanting a "realistic and more in depth experience", others playing for
the challenges.
([FMM Vibe — Where do you find so much time to play FM?](https://fmmvibe.com/forums/topic/50213-where-do-you-find-so-much-time-to-play-fm/))

**Season length.** FMM Vibe threads on career length and playtime give a spread: **"probably 10
hours+ to play one season"** at full engagement, against **"a season can be played in a few hours
straight if you wish, or you can play for a few minutes over a tea break at work."**
(Aggregated from [FMM Vibe — Longest game time?](https://fmmvibe.com/forums/topic/50005-longest-game-time/),
[30 Seasons](https://fmmvibe.com/forums/topic/44777-30-seasons/),
[Where do you find so much time to play FM?](https://fmmvibe.com/forums/topic/50213-where-do-you-find-so-much-time-to-play-fm/).
Individual post attribution not verified — see §0.)

**Career length is capped, and the stated reason is save size.** FMM saves end after **30 seasons**,
with a Hall of Fame and career review at the end. The reason given in the community and in
explainers is **save file size against device storage limits** — the console and Touch SKUs share
the cap; desktop FM does not have one.
([SI forums — 30 season limit](https://community.sports-interactive.com/forums/topic/403839-30-season-limit/),
[FMM Vibe — 30 Seasons](https://fmmvibe.com/forums/topic/44777-30-seasons/),
[Two Playmakers](https://twoplaymakers.com/how-many-seasons-can-you-play-in-football-manager/))

#### 2.3 The arithmetic, and why it inverts the project's assumption

**DERIVED.** An English FMM save is ~38 league fixtures plus ~6–10 cup and continental fixtures ≈
**~46 matches per season**.

| Playstyle | Season wall-clock | Per match (inclusive of the surrounding week) |
|---|---|---|
| Engaged | ~10 h+ | **~13 min** |
| Fast ("a few hours") | ~3–4 h | **~4–5 min** |

Now compare the brief's §4 budget: 7 h across ~20 in-season weeks ≈ **21 min per week inclusive of
the match**.

**This project's per-match time budget is larger than FMM's, not smaller.** FMM can afford to make
any single match cost four minutes because there are forty-six of them; the season's weight is
spread thin and no individual fixture has to carry much. American football gives us **12–20
regular-season games**, roughly a third as many, so each one must carry roughly three times the
weight. Copying FMM's "a match is a four-minute thing you do on the bus" would leave the season
feeling like a rounding error.

The binding constraint under P4 is therefore **not total season time** — 21 min/week is generous by
FMM standards. It is **presentation time per snap**, exactly as §4 of the brief warns. FMM's
per-match cheapness is a consequence of match density we do not have and should not imitate.

---

### 3. The match view

#### 3.1 What it renders

- **2D top-down only.** Mobile matches are available only in the top-down 2D view; the 3D engine is
  a Touch/PC/Console feature. Players are dots on the pitch.
  ([RealSport101 — FM24 Mobile vs Touch](https://realsport101.com/football-manager/fm-24-mobile-vs-touch-whats-the-difference/),
  [GamingOnPhone](https://gamingonphone.com/miscellaneous/football-manager-touch-vs-football-manager-mobile-difference/),
  [FMM Vibe — The 2D Pitch](https://fmmvibe.com/forums/topic/7800-the-2d-pitch/))
- **Two view modes:** *Full* — a horizontal full-pitch viewpoint following the action; and
  *Commentary Only* — text summaries of moments, no pitch.
  ([SI manual, FMM24 — Matchday](https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2024/matchday-r5239/);
  [SI manual, FMM26 — Match Day](https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/match-day-r5263/))
- **Highlights only — there is no full-90 option.** The choice is *Extended highlights* or *Key
  moments*. RealSport101 states it plainly: mobile players "can only watch the match as it skips to
  key moments, and not the full-blown 90 mins."
  ([SI manual Match Day](https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/match-day-r5263/),
  [RealSport101](https://realsport101.com/football-manager/fm-24-mobile-vs-touch-whats-the-difference/))
- **Two independent speed controls**, and this is the detail most worth stealing: one slider sets
  how fast the **commentary** progresses, and a *separate* slider sets **how quickly the clock moves
  when there is no action to show**. Dead time and dramatic time are tuned independently.
  ([SI manual, FMM26 — Match Day](https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/match-day-r5263/))
- **Configurable chrome:** show latest scores / match stats / both while the game processes; toggle
  the match timeline logging key events; toggle goal replays and replay speed. (same source)
- **Navigation:** swipe between match screens; other match views via a Bookmarks menu at bottom-right.
  ([SI manual Match Day](https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/match-day-r5263/))

#### 3.2 What the manager can do *during* a match

| Action | Detail | Source |
|---|---|---|
| **Team talks** | Pre-match, **half-time** and full-time. Each delivered as **Demanding / Balanced / Relaxed**. Assistant advises the best approach for each. *New in FMM26.* | [footballmanager.com — FM26 Mobile features](https://www.footballmanager.com/fm26/features/mobile) |
| **Change mentality** | Any time, mid-match | [SI manual Tactics](https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/tactics-r5249/) |
| **Adjust team instructions** | "can be set or changed at any time, both between fixtures and during matches" | [SI manual Tactics](https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/tactics-r5249/) |
| **Substitutions** | Via the tactics screen, or a **quick-sub** control on player profiles along the bottom of the match screen | [SI manual Match Day](https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/match-day-r5263/) |
| **Respond to prompts** | See below | [footballmanager.com — FM24 Mobile new features](https://www.footballmanager.com/features/football-manager-2024-mobile-new-features-revealed) |
| **Post-match team meeting** | Build on the full-time talk, outline positives and negatives, prepare the squad for the days ahead | [footballmanager.com — FM26 Mobile features](https://www.footballmanager.com/fm26/features/mobile) |

#### 3.3 The single most transferable mechanic in FMM: **in-match notifications**

FM24 Mobile introduced notifications that **interrupt the player with a decision** rather than
expecting them to notice a situation:

> "if your star striker has picked up a knock, you'll be given the option to replace him
> immediately — with the player's Current Ability, Morale and Condition helping you to choose the
> best replacement. You'll also be given the chance to send your keeper forward for a late corner or
> to change your penalty taker based on their body language and performance."
> — [footballmanager.com, FM24 Mobile New Features](https://www.footballmanager.com/features/football-manager-2024-mobile-new-features-revealed)

Three properties make this the atomic unit of FMM's match engagement:

1. **The game asks; the player does not have to be vigilant.** Attention is not a prerequisite.
2. **The decision arrives with exactly the data needed to answer it** — CA, morale, condition, body
   language — inline, not on another screen.
3. **It is scarce and situational.** A knock, a late corner, a penalty. Not a per-minute drip.

This is a mobile-native answer to the agency problem, and it does not depend on soccer's continuous
flow. It is the mechanic §4 of the brief should be building on.

#### 3.4 How often is the manager expected to intervene?

**No published figure. DERIVED**, from the community's advanced guidance, which describes
intervention as *episodic and situational*: mentality is chosen by how difficult the fixture is;
with a lead you "set WASTE TIME on defence settings and change team mentality around the 80+ minute
mark"; home/away and stronger/weaker opposition change the approach.
([FMM Vibe — \[ADVANCED GUIDE\]](https://fmmvibe.com/forums/topic/50684-advanced-guide/),
[Mini Guide — General Advice on FMM Tactics](https://fmmvibe.com/forums/topic/49699-mini-guide-general-advice-on-fmm-tactics/))

Estimated real intervention rate: **roughly 3–6 acts per match** — a half-time talk, one or two
subs, one mentality change late, plus any prompts the game raises. Everything else is watching.

---

### 4. Tactical abstraction and how it maps to outcomes

#### 4.1 Granularity

FMM's tactical surface is **discrete named states, mostly two or three options per axis** — not
sliders, not the ~20 team instructions of desktop FM.

**Team instructions**, per the FMM26 manual
([Tactics](https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/tactics-r5249/)):

- **Mentality**, a named ladder. The manual describes, among others: *Contain* ("effectively 'parks
  the bus'… damage-limitation… aiming to prevent goals going in rather than looking to score them");
  *Standard* ("the comfortable middle ground… carefully balances defence and attack and provides the
  foundation upon which tactical adjustments can be made"); a "dynamic forward-thinking" attacking
  mentality; and *Emergency* ("the kitchen sink is figuratively thrown… all defensive thinking going
  out of the window… likely to only be used at the end of matches in which you're trailing").
- **Width** — three states: full use of wide areas / balanced / predominantly central.
- **Tempo** — higher intensity vs. lower speed, "taking the sting out of the match".
- **Pressing** — close down anywhere on the pitch vs. only in your own half; or pick moments.
- **Defensive line** — offside trap on/off; sit deeper and keep play in front.
- **Time wasting** — on/off.
- **Passing style** — short/tiki-taka, mixed, direct.
   ([FMM Vibe — Mentalities](https://fmmvibe.com/forums/topic/49730-mentalities/))

**Per player:** formation slot + **role and duty**. FMM26 adds two roles, *Inverted Full-Back* and
*Wide Centre-Back*. ([footballmanager.com — FM26 Mobile features](https://www.footballmanager.com/fm26/features/mobile))

**Set pieces** *(new in FMM26)*: select Defence or Attack from the bottom options bar, then **tap an
area of the pitch** to bring up available options — a spatial, touch-native way to express a
routine without a spreadsheet.
([SI manual FMM26 — Tactics](https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/tactics-r5249/))

**Not present in Mobile:** the In-Possession / Out-of-Possession split formations FM26 Touch
introduced. ([footballmanager.com Game Comparison](https://www.footballmanager.com/compare-games))

#### 4.2 How it maps to outcomes

The community treats tactics as a **global bias on a statistical match model**, tuned against
context rather than against events:

- Choose mentality by fixture difficulty; adjust for home/away and opponent strength; these "alter
  space management, tempo, pressing intensity and possession control".
- **Formation stability itself is a mechanic** — keeping a consistent formation "strengthens player
  chemistry, preserves relationships between units, and improves automatic interactions."
- **Player connections** are load-bearing in FMM26, and pre-season friendlies (4–5 recommended) are
  how you build them.
   ([FMM Vibe — \[ADVANCED GUIDE\]](https://fmmvibe.com/forums/topic/50684-advanced-guide/),
   [Beginner's Guide (FMM26)](https://fmmvibe.com/forums/topic/50673-beginners-guide-in-progress/))

The abstraction is coarse enough that "which tactic" is a *build* decision made once and revisited
occasionally, not a per-match puzzle. That is why FMM Vibe's culture is dominated by downloadable
tactic files and role guides: the tactic is treated as a solved artefact you install.
([FMM Vibe — FMM26 Tactics Quick Guide/Index](https://fmmvibe.com/forums/topic/50520-fmm26-tactics-quick-guideindex/),
[TACTICS BY PINUCCIO](https://fmmvibe.com/files/file/1489-tactics-by-pinuccio-update-0331/))

**The failure mode is visible in FMM26's reception.** The most negative community thread's core
charge is that "tactics are considered non-existent", with matches decided by AI scoring "stupid
goals" and conceded long shots, and post-match reports repeating "snatched at chances", "poor shot
accuracy", "poor conversion".
([FMM Vibe — FM26 Mobile is the worst FM Mobile game ever](https://fmmvibe.com/forums/topic/50827-fm26-mobile-is-the-worst-fm-mobile-game-ever/),
[Negative feedback](https://fmmvibe.com/forums/topic/50626-negative-feedback/),
[FM 26 Mobile is too difficult](https://fmmvibe.com/forums/topic/50942-fm-26-mobile-is-too-difficult/))
When a coarse tactical model stops legibly *mapping* to results, players do not conclude the model
is subtle — they conclude it is fake. **Legibility of the tactic→outcome link matters more than the
richness of the tactic.** That is a D2/D10 requirement, not a nice-to-have.

---

### 5. What FMM removed from desktop FM — and why

This is the most useful section in this research part: a list of things a shipping mobile management
sim decided it could live without, from a studio that had the desktop feature list in front of it.

| # | Removed / reduced | Evidence | Stated or inferred reason |
|---|---|---|---|
| 1 | **3D match engine** → 2D top-down only | [RealSport101](https://realsport101.com/football-manager/fm-24-mobile-vs-touch-whats-the-difference/), [GamingOnPhone](https://gamingonphone.com/miscellaneous/football-manager-touch-vs-football-manager-mobile-difference/) | Device power; also legibility on a small screen (§7) |
| 2 | **Watching the full 90 minutes** → Extended or Key-moments highlights only | [SI manual Match Day](https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/match-day-r5263/), [RealSport101](https://realsport101.com/football-manager/fm-24-mobile-vs-touch-whats-the-difference/) | Session length. **INFERRED** |
| 3 | **Press conferences / media interaction** — "stripped back to their basics" | [RealSport101](https://realsport101.com/football-manager/fm-24-mobile-vs-touch-whats-the-difference/), [The Higher Tempo Press](https://www.thehighertempopress.com/2024/09/is-football-manager-mobile-as-good-as-the-desktop-version/) | **STATED (community, SI-adjacent):** "very unlikely to be added"; players would delegate them to the assistant anyway because "they get boring and repetitive" ([FMM Vibe](https://fmmvibe.com/forums/topic/43226-opinion-what-is-the-point-of-fmm/)) |
| 4 | **Half-time team talks** — absent in the FMM24 era | [The Higher Tempo Press](https://www.thehighertempopress.com/2024/09/is-football-manager-mobile-as-good-as-the-desktop-version/) | **Re-added in FMM26** — but only compressed to three moods with AI advice. See §5.1 |
| 5 | **Training depth** — "vastly simplified", and delegable | [RealSport101](https://realsport101.com/football-manager/fm-24-mobile-vs-touch-whats-the-difference/), [SI manual Training](https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/training-r5253/) | Weekly-cost control |
| 6 | **Staff depth** — one staff member per role; some roles excluded entirely (Sports Scientist, Data Analyst) | [RealSport101](https://realsport101.com/football-manager/fm-24-mobile-vs-touch-whats-the-difference/) | Screen count and roster of things to manage |
| 7 | **Data Hub / analytics depth** — "less detail in stats" | [RealSport101](https://realsport101.com/football-manager/fm-24-mobile-vs-touch-whats-the-difference/) | Mobile screen budget. **INFERRED** |
| 8 | **Dynamics / social groups** — "less dynamic options" | [RealSport101](https://realsport101.com/football-manager/fm-24-mobile-vs-touch-whats-the-difference/) | Simulation cost + screen cost. **INFERRED** |
| 9 | **World scope** — ~half the playable nations and a bit over half the leagues of Touch | [TouchArcade](https://toucharcade.com/2023/11/14/football-manager-2024-review-touch-vs-mobile-vs-ps5-vs-pc-steam-deck-features-save-controller-console/) | Week-advance cost, save size |
| 10 | **League selection flexibility** — max 3 leagues plus their lower divisions, **fixed at save creation**, cannot be added or changed later | [RealSport101](https://realsport101.com/football-manager/fm-24-mobile-vs-touch-whats-the-difference/) | Off-screen simulation budget. Directly relevant to **D3** |
| 11 | **Unlimited career length** → **30-season cap** | [SI forums](https://community.sports-interactive.com/forums/topic/403839-30-season-limit/), [Two Playmakers](https://twoplaymakers.com/how-many-seasons-can-you-play-in-football-manager/) | **STATED: save-file size vs. device storage limits.** Directly relevant to **D7** |
| 12 | **The Unity rebuild and the new UI** — Mobile is the only FM26 edition not on Unity | [footballmanager.com Game Comparison](https://www.footballmanager.com/compare-games) | Mobile is a separate product line, not a reduced desktop build |
| 13 | **In/Out of Possession formations** (an FM26 Touch feature) | [footballmanager.com Game Comparison](https://www.footballmanager.com/compare-games) | Tactical surface area |
| 14 | **Instant Result** — added to FM26 *desktop*, still absent from Mobile after 6+ years of requests | [Operation Sports](https://www.operationsports.com/football-manager-26-adds-instant-result-option-for-matches/), [SI forums](https://community.sports-interactive.com/forums/topic/590274-instant-result-3-options-including-what-already-exists-in-game/) | **INFERRED:** the match is the product; a skip button hollows it out |

#### 5.1 The most instructive single data point

Half-time team talks were **cut**, then **restored in FMM26 in compressed form**: pre-match,
half-time and full-time, each delivered as **Demanding / Balanced / Relaxed**, with the assistant
recommending which.
([footballmanager.com — FM26 Mobile features](https://www.footballmanager.com/fm26/features/mobile))

The rule this implies — and it should be a design rule for this project:

> A management-sim feature earns a place on mobile when it can be reduced to **one scarce moment, a
> handful of named options, and an advisor opinion attached to the choice.** Features that cannot be
> compressed to that shape (press conferences, staff meetings, full training schedules) stay cut,
> and the reason given is not device power — it is that players delegate anything repetitive.

#### 5.2 What FMM notably did *not* remove

Worth stating, because these are the load-bearing parts:

- The **match**, and the requirement to be present at it (no instant result).
- **Transfers, contracts and finances** — FMM26 *deepened* finances, with financial-regulation
  breaches carrying through to transfer and wage budgets, fines and points deductions.
  ([footballmanager.com](https://www.footballmanager.com/fm26/features/mobile))
- The **career ladder** — job applications, being sacked, holidaying while auto-applying for better
  jobs. ([SI manual — You, the Manager](https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/you-the-manager-r5260/))
- **Opponent-specific preparation** — the Pre-Match Hub, and in FMM26 per-match training prep.
- **Scouting with imperfect information** (see §6.4).

---

### 6. Where engagement actually comes from, according to players

Player voice, from FMM Vibe and the SI FMM forums.

#### 6.1 Relief from complexity is itself the draw

Players say they came to FMM *because* they "grew fed up with the amount of detail and time needed"
for the PC version or FM Touch; FMM "helps them unwind and is not too realistic or difficult". The
loop they describe as fun is: **"set up a tactic, buy their team, and then progress through the
season making occasional changes."**
([FMM Vibe — Opinion: What Is The Point of FMM?](https://fmmvibe.com/forums/topic/43226-opinion-what-is-the-point-of-fmm/))

This is important and uncomfortable: for a large part of FMM's audience, **fewer decisions is the
feature.** "Bland" and "restful" are the same measurement taken by different people.

#### 6.2 Jeopardy is mostly **player-authored**, not game-supplied

The difficulty question has run in the community since at least 2018
([The Difficulty Debate](https://fmmvibe.com/forums/topic/40919-the-difficulty-debate/),
[Discussion: Is FMM too easy?](https://fmmvibe.com/forums/topic/45397-discussion-is-fmm-too-easy/),
[Poll — Do you think FMM26 is too Easy vs too Difficult?](https://fmmvibe.com/forums/topic/50529-poll-do-you-think-fmm26-is-too-easy-vs-too-difficult/)).
The community's settled answer is to manufacture its own stakes:

- **Named community challenges** are the difficulty system. The 1,000-goal challenge ("1kc"); "The
  Impossible Challenge" — win everything in England, Italy and Spain plus one other country, plus
  continental and international honours; lower-league climbs; self-imposed hard mode.
  ([The Impossible Challenge](https://fmmvibe.com/forums/topic/48088-the-impossible-challenge-completed-s30-%E2%80%A2bonus-round%E2%80%A2/),
  [Self Imposed Hard Mode](https://fmmvibe.com/forums/topic/48906-self-imposed-hard-mode/),
  [Mid-Level Challenge](https://fmmvibe.com/forums/topic/42363-mid-level-challenge/))
- Players **explicitly prefer** authoring their own difficulty to the game being made harder — the
  stated reason being that a globally harder game frustrates casual and hardcore players alike.
  ([Discussion: Is FMM too easy?](https://fmmvibe.com/forums/topic/45397-discussion-is-fmm-too-easy/))
- The community notes the difficulty curve is *personal history*, not game state: the first 1kc is
  brutal, later ones are trivial once you have a good tactic.

#### 6.3 Ownership and emergent narrative come from **self-imposed roleplay rules**

A canonical FMM Vibe guide tells players how to make the game feel real by constraining themselves:
start at a club with a stadium under 15,000 (a bigger one implies a fallen giant that demands
instant results); scout only your own region until promoted, widening the radius league by league;
at the bottom, hire only unemployed staff of your club's nationality. It is explicit that these are
optional — "pick and choose which aspects appeal to you to add more immersion and fun to your save."
([FMM Vibe — How to Play Football Manager Mobile More Realistically](https://fmmvibe.com/forums/topic/44855-how-to-play-football-manager-mobile-more-realistically/),
[Realistic careers and how to](https://fmmvibe.com/forums/topic/48873-realistic-careers-and-how-to/))

**Read that as a bug report.** Players are hand-building the pressure gradient and the sense of
place that the game does not supply. Every one of those rules is a mechanic this project could ship
natively — and under **D6** and **D8**, should.

#### 6.4 Information asymmetry exists but is **opt-in**

FMM supports **attribute masking**, and the community's framing is that it is "probably the most
realistic and challenging way of playing the game as no real life manager has the exact information
on every player in the world. It also gives more purpose to scouts and scouting." Scout and coach
estimates disagree with each other — a scout may report five-star potential where the assistant
coach reports three.
([FMM Vibe — The Poll: Do You Ever Play With Attribute Masking On?](https://fmmvibe.com/forums/topic/41790-the-poll-do-you-ever-play-with-attribute-masking-on/),
[Attributes vs Scout/Coach rating](https://fmmvibe.com/forums/topic/45387-attributes-vs-scoutcoach-rating/),
[Different report of scout and coach](https://fmmvibe.com/forums/topic/48496-different-report-of-scout-and-coach/))

But it is a **setting**, and the default is full information. The fact that the community runs polls
about whether people turn it on tells you a lot of them do not.

#### 6.5 One-more-turn comes from **cheap resumption**, not from a cliffhanger

Nothing in the sources describes FMM building tension across a session boundary. What they describe
is that the *cost of the next step is one tap* — day-granular Continue, holiday-to-next-match, and
delegation that removes any obligation you do not want. Bursts of "a few minutes up to an hour"
work because there is always a small, complete unit of progress available.
([FMM Vibe](https://fmmvibe.com/forums/topic/50213-where-do-you-find-so-much-time-to-play-fm/))

#### 6.6 Counter-evidence — do not romanticise FMM

Boredom threads are a permanent fixture of the community: *How do you play without getting bored*,
*How to not get Bored of Playing FM?*, *Help I'm getting bored quickly*.
([2017](https://fmmvibe.com/forums/topic/40357-how-do-you-play-without-getting-bored/),
[2021](https://fmmvibe.com/forums/topic/46347-how-to-not-get-bored-of-playing-fm/),
[2021](https://fmmvibe.com/forums/topic/46052-help-i%E2%80%99m-getting-bored-quickly/))
The advice offered is always "impose a challenge" — never "keep playing, the game will apply
pressure."

FMM26 specifically drew *"the worst FM Mobile game ever"*, *"BROKEN GAME"*, *"Negative feedback"* and
*"too difficult"* threads
([1](https://fmmvibe.com/forums/topic/50827-fm26-mobile-is-the-worst-fm-mobile-game-ever/),
[2](https://fmmvibe.com/forums/topic/50691-%E2%80%A2-broken-game-%E2%80%A2/),
[3](https://fmmvibe.com/forums/topic/50626-negative-feedback/),
[4](https://fmmvibe.com/forums/topic/50942-fm-26-mobile-is-too-difficult/)),
alongside App Store reports of crashes and screen-fitting problems
([App Store — FM26 Mobile reviews](https://apps.apple.com/gb/app/football-manager-26-mobile/id6446123740?see-all=reviews&platform=iphone)).
Being FMM is not automatically sufficient.

---

### 7. The crux: FMM is itself a menu-driven application — why isn't it called bland?

#### 7.1 First, correct the premise: it *is* called bland — by reviewers, not by players

Pocket Tactics on FM20 Mobile is the sharpest statement of exactly the failure mode this project is
trying to escape:

> "tactical options feel limited and the no-frills highlights do little to disguise the fact that
> **this is just an exercise in juggling numbers**" — and the UI is "a labyrinth of information to
> wade through" that makes "even relatively simple actions such as nominating a captain or seeing the
> latest league table more cumbersome than it should be."
> — [Pocket Tactics, FM2020 Mobile review](https://www.pockettactics.com/football-manager-2020-mobile/review)

Press coverage of FM26 Mobile lands in the same place: streamlined and enjoyable, but "the reduced
complexity means experienced PC players may outgrow it quickly"
([Prime Games Arena](https://primegamesarena.com/football-manager-review/)). App Store reviewers ask
for exactly the missing texture — "appointment scenes, press conferences, media reactions and
behind-the-scenes photos"
([App Store reviews](https://apps.apple.com/gb/app/football-manager-26-mobile/id6446123740?see-all=reviews&platform=iphone)).

So the real question is not "why is a menu game not bland?" It is: **what does FMM have that
converts a menu application into a thing people keep on their phone for years, and which of those
things can this project actually obtain?**

#### 7.2 Five answers, ranked by how transferable they are

**1. The real-world referent — and we cannot have it.** *(Non-transferable. Most important finding
in this document.)*
Every row in FMM's tables is a name the player already has feelings about. The dot on the 2D pitch
is a footballer the player has watched. FMM inherits three decades of licensed, researched real
football — the FIFA licence and the Barclays WSL licence in FM26
([footballmanager.com](https://www.footballmanager.com/fm26/features/mobile),
[Introducing Women's Football](https://www.footballmanager.com/fm26/features/introducing-womens-football)) —
and that referent supplies drama for free that the interface never has to generate. **Tier A of this
brief forbids us any of it.** A fictional league starts at zero meaning per name and must
*manufacture* the affect FMM imports. Any reasoning of the form "FMM is menus and it works, so our
menus will work" is invalid precisely here, and this is the failure mode most likely to be assumed
away. It is the argument for **D6** being a first-class design problem with real budget, not a
compliance tax.

**2. Player-authored jeopardy, sustained by a community we won't have at launch.** *(Semi-transferable
— must be internalised.)*
§6.2 and §6.3: the difficulty system, the pressure gradient and the roleplay constraints are all
supplied by FMM Vibe, not by the binary. A new title has no such community on day one. Every
challenge structure FMM outsources — the lower-league climb, the region-locked scouting, the
"unemployed local staff only" start, the win-everything career — **has to ship in the box** as
board expectations, job-market gating, scouting range, and staff availability with mechanical
consequence. That is **D8**, and this evidence says D8 is not optional garnish; it is where FMM's
engagement actually lives.

**3. The game interrupts the player.** *(Directly transferable. Steal this.)*
§3.3. In-match notifications hand the player a decision, with the deciding data inline, at a scarce
and dramatic moment. It costs no vigilance, it does not require the player to be watching, and it
converts spectating into being consulted. This is the single best-evidenced mobile-native answer to
"what does the player do if they don't control anything", and it is the mechanic §4's agency model
should be built around.

**4. Resumption is nearly free.** *(Directly transferable.)*
§6.5 and §1.1. One `[Continue]` in a fixed screen position; day granularity; holiday-to-next-match;
per-role delegation. The player is never more than one tap from a complete unit of progress, and
never obliged to engage with a system they find boring. FMM's answer to "this screen is tedious" is
**delegate it**, not **cut it** — which preserves depth for the people who want it while costing the
others nothing.

**5. Compression discipline as an editorial rule.** *(Directly transferable.)*
§5.1. Everything retained is a scarce moment, 2–4 named options, an advisor opinion. Nothing
retained is a form to fill in. The FMM24→FMM26 team-talk restoration shows the rule being applied in
both directions over a two-year cycle.

#### 7.3 The one-line answer

FMM is not bland to its players because **the menus are not where the game is.** The game is a real
football world the player already cares about, a career ladder with a job to lose, a community
supplying stakes the software doesn't, and a match that occasionally taps the player on the shoulder
and asks them something. The menus are just how you reach those. **This project inherits none of the
first, cannot bootstrap the third, and therefore has to build the second and fourth deliberately and
well.** Copying FMM's interface without building its stakes reproduces the Pocket Tactics verdict:
an exercise in juggling numbers.

---

### 8. Non-transferability: soccer's continuous flow vs. American football's per-snap surface

Called out explicitly, per the brief.

| FMM mechanic | Why it works in soccer | Transfer verdict for American football |
|---|---|---|
| **Watch-and-adjust in-match model** | Soccer has no natural decision points. The manager's intervention is a *bias applied to a continuous process*, and the cost of never intervening is genuinely near zero — the team keeps playing. | **Does not transfer.** American football supplies ~130 natural decision points per game. A player watching a 3rd-and-2 and not being asked anything experiences a *conspicuous absence*, not restful delegation. The "manager biases a flow" framing has no analogue; the absence is felt where soccer's is not. This is the core of Gate Zero. |
| **Highlights-only ("Key moments")** | In soccer, key moments *are* the shots and chances — 8–15 events (**ASSUMPTION**, no published count). Skipping the rest loses nothing the manager could have acted on: the boring parts are boring for the manager too. | **Transfers only after redefinition.** In American football the dramatic events (scores, turnovers, explosives) and the *decision* events (4th down, 2-point, timeout, clock, personnel) are **different sets**, and the decision events live in the "boring" parts. A soccer-style highlight filter would skip past exactly the moments where the player has agency. Our highlight selector must be driven by **leverage** (win-probability swing / decision availability), not by excitement. |
| **Substitutions as scarce in-match acts** | 3–5 per match, each irreversible and consequential — a genuinely good decision object. | **Does not transfer.** Personnel changes in American football are per-snap and automatic; there is no scarce, high-salience substitution act. The nearest analogue is **personnel-package and rotation policy**, which is a pre-set, not an in-match decision. Do not try to build an in-match "sub" button; build a package policy plus injury/fatigue prompts. |
| **Global mentality dial** | One mentality plausibly colours 90 continuous minutes. | **Weakly transfers.** A single global aggressiveness dial will feel inert, because "aggressive" means different, uncorrelated things by situation (4th-down policy, blitz rate, deep-shot rate, two-minute urgency). The soccer-shaped one-dial abstraction must be replaced by a small set of **situational policies** the coach sets pre-game and can override at leverage points. |
| **Time wasting (on/off)** | A minor, binary instruction. | **Transfers, and gets bigger.** Clock management in American football is first-class, discrete and high-leverage: timeouts, hurry-up, kneel, sideline discipline, two-minute drill. FMM's binary is the seed of one of our best decision surfaces. |
| **Team talks (pre / half / full-time, 3 moods, advisor opinion)** | Scarce, discrete, compressible. | **Transfers cleanly and almost unchanged.** Pregame, halftime and postgame are real, scarce and structurally identical. Adopt the FMM26 shape — three moods, assistant recommendation — near-verbatim in form. |
| **Pre-Match Hub** | Opponent report, predicted XI, danger men, style of play, media/board/fan expectations. | **Transfers, and gets bigger.** Weekly opponent preparation is *more* central to American football than to soccer — it is the sport's defining ritual. This is the strongest candidate for the week-level agency the brief needs. |
| **Per-match training preparation (FMM26)** | Prepare for a specific opponent; delegable. | **Transfers well.** Maps directly onto the practice week and game-plan installation, and is a natural home for meaningful weekly decisions that cost little wall-clock. |
| **Two independent speed sliders (commentary vs. dead-clock)** | Separates dramatic time from filler time. | **Transfers, and is more valuable to us.** With ~130 snaps and a presentation-time budget under P4, decoupling "how long a consequential snap is shown" from "how fast routine snaps flow past" is close to mandatory. See §2.3. |
| **In-match notifications** | Game raises a decision with the data inline. | **Transfers, and should be the backbone.** See §3.3 and §7.2. |
| **~46 matches per season, so any one match can be cheap** | Match density spreads the season's weight. | **Inverts.** 12–20 games means each match must carry ~3× the weight. FMM's per-match economy is the wrong target; our per-match budget should be *larger*, and total-season time is not the binding constraint (§2.3). |
| **30-season cap for save-size reasons** | Storage-bounded career length, stated openly. | **Transfers as a precedent.** SI — with far more engineering resource than a solo developer — chose to bound career length rather than solve unbounded save growth. Direct input to **D7**. |
| **Max 3 leagues, fixed at save creation** | Bounds off-screen simulation cost, permanently, at the one moment the player accepts a constraint. | **Transfers as a pattern.** Our college tier is ~134 programmes with recruiting and portal AI (**D3**). "Choose your simulation scope at save creation and live with it" is a shipped, accepted answer to that cost. |

---

### 9. Assumptions and unsourced items

Collected per the brief so the owner can see what the design rests on.

1. **ASSUMPTION — taps and decisions per week in FMM.** No published count. §1.3 is derived from
   the manual's surface list, the delegation options and community descriptions of the routine loop.
2. **ASSUMPTION — intervention rate during an FMM match (~3–6 acts).** Derived in §3.4 from
   community advanced guidance; no published figure exists.
3. **ASSUMPTION — number of highlights in an FMM "Key moments" match (8–15).** Not published. Used
   only in §8 as a comparison and flagged there.
4. **DERIVED — per-match wall-clock in §2.3** (~4–13 min). Computed from player-reported season
   times (3–10 h+) divided by an assumed ~46-fixture English season. Both inputs are approximate.
5. **INFERRED reasons in the §5 removal table** are marked INFERRED in the table. Only rows 3, 4
   (partially), 11 and 14's counterpart have community- or SI-stated reasoning; the rest is
   inference from the pattern.
6. **Evidence-quality caveat.** No page was read in full (§0). Forum claims cannot be attributed to
   a named poster or a date, and paraphrase context may be lost. Any claim in §6 or §7 that is going
   to move a decision on its own should be re-verified by the owner on a machine with unrestricted
   web access before it is written into `02-GAME-DESIGN.md`.
7. **Reddit is entirely absent from this research part** — the search tool is blocked from
   `reddit.com`. Player voice is FMM Vibe + SI forums only.

---

### 10. Sources

**Official — Sports Interactive manual (FM26 Mobile / FM24 Mobile)**
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/the-interface-r5245/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/the-home-screen-r5246/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/main-menu-r5243/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/starting-a-new-game-r5244/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/your-team-r5248/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/tactics-r5249/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/team-report-r5251/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/training-r5253/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/you-the-manager-r5260/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/match-day-r5263/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2026/options-r5264/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2024/matchday-r5239/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2024/tactics-r5227/
- https://community.sports-interactive.com/sigames-manual/football-manager-mobile-2024/you-the-manager-r5238/

**Official — footballmanager.com**
- https://www.footballmanager.com/compare-games
- https://www.footballmanager.com/fm26/features/mobile
- https://www.footballmanager.com/fm26/features/football-manager-26-mobile-new-features-showcase
- https://www.footballmanager.com/features/football-manager-2024-mobile-new-features-revealed
- https://www.footballmanager.com/features/fm24-mobile
- https://www.footballmanager.com/fm26/features/introducing-womens-football
- https://www.footballmanager.com/news/football-manager-26-out-now-across-platforms

**Store listings and user reviews**
- https://apps.apple.com/us/app/football-manager-26-mobile/id6446123740
- https://apps.apple.com/gb/app/football-manager-26-mobile/id6446123740?see-all=reviews&platform=iphone
- https://play.google.com/store/apps/details?id=com.netflix.NGP.FootballManagerMobile
- https://www.netflix.com/tudum/articles/football-manager-26-mobile-game-news
- https://www.whats-on-netflix.com/news/netflix-games/football-manager-2026-will-join-netflix-games-on-mobile-in-november-2025/

**FMM Vibe (community — player voice)**
- https://fmmvibe.com/forums/topic/43226-opinion-what-is-the-point-of-fmm/
- https://fmmvibe.com/forums/topic/50213-where-do-you-find-so-much-time-to-play-fm/
- https://fmmvibe.com/forums/topic/50005-longest-game-time/
- https://fmmvibe.com/forums/topic/44777-30-seasons/
- https://fmmvibe.com/forums/topic/43393-30-seasons/
- https://fmmvibe.com/forums/topic/51038-skip-days/
- https://fmmvibe.com/forums/topic/50673-beginners-guide-in-progress/
- https://fmmvibe.com/forums/topic/50684-advanced-guide/
- https://fmmvibe.com/forums/topic/49699-mini-guide-general-advice-on-fmm-tactics/
- https://fmmvibe.com/forums/topic/49730-mentalities/
- https://fmmvibe.com/forums/topic/50520-fmm26-tactics-quick-guideindex/
- https://fmmvibe.com/files/file/1489-tactics-by-pinuccio-update-0331/
- https://fmmvibe.com/forums/topic/40919-the-difficulty-debate/
- https://fmmvibe.com/forums/topic/45397-discussion-is-fmm-too-easy/
- https://fmmvibe.com/forums/topic/50529-poll-do-you-think-fmm26-is-too-easy-vs-too-difficult/
- https://fmmvibe.com/forums/topic/48088-the-impossible-challenge-completed-s30-%E2%80%A2bonus-round%E2%80%A2/
- https://fmmvibe.com/forums/topic/48906-self-imposed-hard-mode/
- https://fmmvibe.com/forums/topic/42363-mid-level-challenge/
- https://fmmvibe.com/forums/topic/44855-how-to-play-football-manager-mobile-more-realistically/
- https://fmmvibe.com/forums/topic/48873-realistic-careers-and-how-to/
- https://fmmvibe.com/forums/topic/41790-the-poll-do-you-ever-play-with-attribute-masking-on/
- https://fmmvibe.com/forums/topic/45387-attributes-vs-scoutcoach-rating/
- https://fmmvibe.com/forums/topic/48496-different-report-of-scout-and-coach/
- https://fmmvibe.com/forums/topic/40357-how-do-you-play-without-getting-bored/
- https://fmmvibe.com/forums/topic/46347-how-to-not-get-bored-of-playing-fm/
- https://fmmvibe.com/forums/topic/46052-help-i%E2%80%99m-getting-bored-quickly/
- https://fmmvibe.com/forums/topic/50827-fm26-mobile-is-the-worst-fm-mobile-game-ever/
- https://fmmvibe.com/forums/topic/50626-negative-feedback/
- https://fmmvibe.com/forums/topic/50691-%E2%80%A2-broken-game-%E2%80%A2/
- https://fmmvibe.com/forums/topic/50942-fm-26-mobile-is-too-difficult/
- https://fmmvibe.com/forums/topic/7800-the-2d-pitch/

**Sports Interactive community forums**
- https://community.sports-interactive.com/forums/topic/595327-official-football-manager-26-mobile-feedback-thread/
- https://community.sports-interactive.com/forums/topic/403839-30-season-limit/
- https://community.sports-interactive.com/forums/topic/590274-instant-result-3-options-including-what-already-exists-in-game/
- https://community.sports-interactive.com/forums/topic/585022-suggestion-instant-result-for-fm-mobile/
- https://community.sports-interactive.com/forums/topic/569604-instant-result/
- https://community.sports-interactive.com/forums/topic/501933-instant-result-option/
- https://community.sports-interactive.com/forums/topic/593192-whats-new-in-fmm26/
- https://community.sports-interactive.com/forums/topic/594444-football-manager-26-mobile-tactics/
- https://community.sports-interactive.com/forums/topic/567945-how-do-i-change-view-for-matches/

**Press and reviews**
- https://www.pockettactics.com/football-manager-2020-mobile/review
- https://toucharcade.com/2023/11/14/football-manager-2024-review-touch-vs-mobile-vs-ps5-vs-pc-steam-deck-features-save-controller-console/
- https://realsport101.com/football-manager/fm-24-mobile-vs-touch-whats-the-difference/
- https://gamingonphone.com/miscellaneous/football-manager-touch-vs-football-manager-mobile-difference/
- https://www.thehighertempopress.com/2024/09/is-football-manager-mobile-as-good-as-the-desktop-version/
- https://www.imore.com/gaming/ios-games/football-manager-2024-mobile-first-impressions
- https://primegamesarena.com/football-manager-review/
- https://www.operationsports.com/football-manager-26-adds-instant-result-option-for-matches/
- https://twoplaymakers.com/how-many-seasons-can-you-play-in-football-manager/
- https://gmgames.org/developer/sports-interactive/

**FM25 cancellation**
- https://www.pocketgamer.com/football-manager-2025-mobile/cancelled/
- https://www.skysports.com/football/news/11095/13304515/football-manager-2025-sports-interactive-cancel-release-of-popular-game
- https://feeds.bbci.co.uk/news/articles/ckg0pm8k49ro
- https://www.techradar.com/gaming/football-manager-2025-canceled-as-sports-interactive-say-were-too-far-away-from-the-standards-you-deserve-and-releasing-the-game-in-its-current-state-would-not-be-the-right-thing-to-do
- https://www.sportspro.com/news/football-manager-2025-fm-sega-sports-interactive-video-game-february-2025/

---

## §6.2A — The deep-sim competitive pole

**Scope.** Draft Day Sports: Pro Football (DDS:PF), Draft Day Sports: College Football (DDS:CFB),
Front Office Football (FOF, versions Eight and Nine), "Bound For Glory", and the wider Wolverine
Studios catalogue. The arcade pole (Retro Bowl, Retro Bowl College) and the mobile-native pole
(Football Coach: College Dynasty, Pocket GM) are other parts; they appear here only where a
cross-reference is load-bearing.

**Governing brief.** `docs/reviews/2026-08-09-spec-prompt-v4.md` §6.2. Feeds D1, D3, D4, D6, D8,
D10 and `PRODUCT.md` §6.3.

**Relationship to existing repo research.** `docs/01-RESEARCH.md` §C and §H already mine the
*reference college sim* (Mani Foroughi's "CFB Simulator", iOS) and the *Achi Jones lineage*
(Android). This document deliberately does not restate them. §7 below is an explicit delta table
naming what is new here versus what §C/§H already established, and where this evidence
**contradicts** them.

---

### 0. Method, and the honest grade of this evidence

Read this section before quoting anything below into a design doc.

#### 0.1 What I could and could not reach

Direct page fetches were attempted first and **failed on organisation egress policy**, not on my
technique. Verified in this container:

```
$ curl -sS "$HTTPS_PROXY/__agentproxy/status"
  "recentRelayFailures": [ { "kind": "connect_rejected",
    "detail": "gateway answered 403 to CONNECT (policy denial or upstream failure)",
    "host": "store.steampowered.com:443" } ]
```

WebFetch returned `EGRESS_BLOCKED` for every one of: `store.steampowered.com`,
`steamcommunity.com`, `www.draftdaysports.com`, `wolverinestudios.freshdesk.com`,
`forums.operationsports.com`, `gmgames.org`, `www.onpapersports.com`, `steambase.io`,
`www.metacritic.com`, `en.wikipedia.org`. Reddit is refused by the tool itself
(`www.reddit.com`, `old.reddit.com`). Per `/root/.ccr/README.md`, policy denials are to be
reported, not routed around, so I did not attempt a workaround.

**Consequence:** every claim below reached me through the WebSearch tool's own
retrieve-and-summarise layer. That layer reads the page; I read its rendering of the page. So:

| Grade | Meaning | How to treat it |
|---|---|---|
| **[Q]** | Text the search layer returned in apparent quotation form. Very likely near-verbatim. | Usable as a quote **only if** the owner re-verifies against the URL on an unrestricted machine. |
| **[P]** | Paraphrase of a specific sourced page. | Usable as a claim. Cite the URL, not a quotation. |
| **[C]** | Corroborated: the same substantive claim arrived independently from ≥2 unrelated sources. | Strongest grade available here. Safe to build a decision on. |
| **[U]** | Unverified / single weak source / plausibly a search-layer artefact. | Do not build on it. Listed in §8. |
| **[ASSUMPTION]** | Mine, not sourced. | Listed in §8. |

I have graded every substantive claim. Where I could not, I said so rather than smoothing it over.

#### 0.2 The sample-size trap, stated up front

This genre's Steam review counts are tiny. DDS:PF 2025 shows **13 user reviews, 46% positive
("Mixed")** [P]; DDS Pro Basketball 2026 shows **12 reviews, 91% positive** [P]; FOF Eight shows
**275 reviews, 84% positive**; FOF Nine **165 reviews, 79% positive** [P]. For comparison, Football
Coach: College Dynasty — a mobile-adjacent, far simpler college sim — shows **~1,474 reviews, 95%
positive** [P].

A 13-review sample cannot carry a "the community thinks X" claim. Everywhere below that I make a
frequency claim, I am ranking by **recurrence across titles, years and sports**, not by counting
reviews inside one SKU. That is the only defensible aggregation at this sample size, and it is why
§2's verdict is framed as a *taxonomy with a ranking* rather than a percentage.

**The 1,474-vs-13 gap is itself the single most commercially interesting number in this document**
and is picked up in §6.

---

### 1. Title profiles

#### 1.1 Draft Day Sports: Pro Football (Wolverine Studios)

| Axis | Finding | Grade |
|---|---|---|
| **Loop** | Annual GM career: draft, trade, sign free agents, manage cap, set depth chart, build a game plan, play/sim the week, advance. Explicitly billed as "every decision made by you from drafting, trading, signing free agents, right down to creating and calling your own plays". | [Q] |
| **Agency in-match** | **Optional every-snap play-calling.** The player may take over play-calling and watch it resolve in 2D, or hand it to the coordinator AI and let the game plan drive it. Game plan is the abstraction layer: `Attitude` (affects playcalling aggression and 4th-down/onside likelihood), `Tempo` (clock consumption), and passing-range preferences that shift success rates. | [C] |
| **Match presentation** | 2D field view with pan/zoom, play-by-play; DDS:PF 26 added "highlight ribbons", rotating stat displays and improved pan/zoom "to track the ball and follow plays". Not a physics sim rendering — a play-outcome model with a visualisation layer. | [P] |
| **Monetisation** | **Annual paid release, ~$24.99 (2025 edition), no subscription.** Heavy discounting later (50–75% off older editions; grey-market keys ~$4.82). "FirstAccess" early-buy programme before full release. | [C] |
| **Platform** | Windows PC. Mac/mobile listings exist on aggregators (TapTap, gmgames platform tags) but are **not corroborated by the Steam listing** — treat as [U], see §8. | [U] |
| **Community** | Small, forum-centred (own phpBB board + Steam + Operation Sports). The developer is credited with responsiveness: "the developers do an amazing job of understanding community concerns and addressing those concerns … with engine tweaks". | [Q] |

**What its community complains about**, ranked by recurrence across editions 2018→2026:

1. **Performance and UI latency.** "Agonizing lag, with each click between menus taking 2–4 seconds
   and animated play-by-play being so laggy it's almost unusable", described as a long-standing
   issue for "this brand of sports management game … with seemingly little to no improvement".
   This is the complaint that produced explicit "not recommended". [Q]
2. **Interface craft.** Menus "clunky and awkward, which sapped all the fun out of the game";
   formatting errors — blank profile pictures misaligned, overlapping coach details on the staff
   screen. Described as "unprofessional". [Q]
3. **Bugs, some save-affecting.** "Whenever they added rookies … the game would delete them from
   free agency" — reported as "a deal breaker". [Q]
4. **Free-agency and contract AI valuation.** "100 OVR running backs getting paid 15 mil a year
   while young 85 OVR 26-year-old running backs want 18 mil a year and won't take less" — the
   mispriced ones then sit unsigned through the bidding war. Separately: on release/trade, bonus
   money does **not** stay on the human player's books as dead money, but **does** on AI teams'
   books — an asymmetry that favours the human. [Q]
5. **Statistical calibration drift over a career.** "Nine receivers … breached the 1,500-yard mark"
   in one save's fourth season against one in the real 2020 NFL; in older editions "at least 10–15
   running backs rushed for over 1500 yards and probably half the QBs topped 4500 yards and 30+ TDs,
   including some QBs who were rated in their mid 70s". [Q]
6. **Single-player neglect.** A recurring charge that the developer prioritises the multiplayer/
   commissioner path over solo GM play; also that the free trial drops you into an off-season of
   "in-depth financials" with **no exhibition game**, so a prospective buyer cannot reach gameplay.
   Play-creation limits (10 offensive, 10 defensive custom plays; no practice testing) are cited
   alongside. [P]
7. **Price.** "This looks so cool but its hella expensive, i would buy for like $20 max." [Q]

#### 1.2 Draft Day Sports: College Football (Wolverine Studios)

| Axis | Finding | Grade |
|---|---|---|
| **Loop** | Season-long programme management: recruiting, scouting, transfer portal, NIL budgets, staff, facilities, finances, scheduling, player development, game plans, conference title → national title. | [P] |
| **Agency in-match** | Same engine family as DDS:PF — optional play-calling with custom playbooks, otherwise game-plan-driven. The 2025 edition's review headline is literally framed around it: *"If you like calling plays, and you like recruiting, this is for you."* | [Q] |
| **Match presentation** | Same 2D viewer as the pro title. | [P] |
| **Monetisation / platform** | Annual paid Windows release, FirstAccess pre-release window, deep discounts on prior editions. | [C] |
| **IP posture** | **Ships a fictional universe**, with a large community mod scene restoring real schools. Directly relevant to Tier A — see §5.4. | [C] |
| **Career shape** | CFB 26 added starting as a **coordinator** and working up to head coach via reputation and the carousel; PF 26 added head coach / coordinator / position coach roles beyond GM. | [C] |
| **Recent AI work** | CFB 27: "CPU programs now use updated recruit-targeting logic to pursue players more intelligently"; "AI-controlled schools do a better job of competing for talent"; NIL budgets added. | [Q] |

**Complaints:**

1. **Information architecture, not depth.** The gmgames review's cons are almost entirely
   navigation: the Teams screen "is not a simple pulldown menu with conferences and teams, making
   it an unnecessary waste of time and space"; "lack of basic organization and links to boxscores
   for articles creates a disorganized mess"; news only "slightly improved". [Q]
2. **Recruiting throughput** — treated separately in §5, because it is the load-bearing one.
3. **Same performance/latency family as the pro title** (screen-change speed was a stated fix
   target: the game "is now lightning fast with screen changes, which was a previous complaint"). [Q]
4. **AI recruiting competitiveness**, evidenced by the fix rather than by threads I could reach:
   shipping "updated recruit-targeting logic" and "AI-controlled schools do a better job of
   competing for talent" in CFB 27 is a developer admission that the prior AI under-competed. [P]

#### 1.3 Front Office Football (Solecismic Software — Jim Gindin)

The genre's depth benchmark and its clearest cautionary tale.

| Axis | Finding | Grade |
|---|---|---|
| **Loop** | Pure GM: trades, contract negotiation, free-agent bidding, the amateur draft, plus a "Fan Allegiance" economy where franchises have TV-market-based fan bases whose growth drives revenue. | [P] |
| **Agency in-match** | **"You can play the role of the armchair coach, setting game plans, creating playbooks and depth charts. You can call every play yourself if you like."** Same optional-every-snap shape as DDS, minus the 2D layer. | [Q] |
| **Match presentation** | **Text only.** An in-game play-by-play report. No 2D field. | [C] |
| **Monetisation / platform** | One-off paid Windows releases, not annualised. FOF Nine $29.99, released **31 Oct 2023**, built on an entirely new code base "designed for simulation speed, growth and flexibility", ships 17 league configurations from 9 to 32 teams. | [P] |
| **Reception** | FOF Eight: Operation Sports 8.5/10 — "The game is as in-depth as any sports game on the market, and kept me coming back for more and more"; 84% of 275 Steam reviews positive. FOF Nine: 79% of 165, "Mostly Positive". | [Q] |
| **Studio history** | One-man company founded 1998. Partnered with OOTP Developments for 2+ years on FOF9; **parted ways June 2020**, code and naming rights returned to Gindin; FOF9 as then-conceived **scrapped Feb 2021** and the algorithmic code sold to a start-up; FOF Nine eventually shipped in 2023 on a new codebase. | [C] |

**Complaints:**

1. **The interface — overwhelmingly the headline criticism.** *"If not for the outdated interface,
   this would be an all-time classic in every sense."* [Q] A survey piece puts it harder: FOF8 "has
   the best mechanics and simulation, though it features an absolutely awful Windows 95-style UI and
   assumes you know all about American football already." [Q]
2. **Onboarding cliff.** "This isn't a game that you can jump right into as the learning curve is
   relatively steep. If you are new to text sims, you need to understand that there is a massive
   amount of reading to be done." [Q]
3. **AI — trade, draft and contract logic.** The same survey: Front Office Football "has complaints
   of trade, draft, and contract AI." [Q] A dedicated "AI trade logic??" thread exists on Front
   Office Football Central. FOF Nine's own long-time-player criticism concedes the opposite
   direction — trading "improvements have been made, allowing players to better predict what teams
   would accept" — while still concluding "it really isn't that great." [P]
4. **Rating/coach randomisation producing implausible careers** — e.g. a Tomlin-calibre coach being
   fired out of nowhere. [P]
5. **Save corruption**, "usually … at the end of year one just after free agency/before the draft".
   [P]
6. **The engagement ceiling, stated by the developer himself.** In the "Lost Interest" thread the
   discussion is that people "run into a wall after about 500–1,000 hours", and the framing of the
   problem is *supporting multiplayer leagues and providing enough game-planning flexibility and
   variety to keep players interested*. [P] **This is the most important single data point in this
   document** — see §3.2 and §6.

#### 1.4 "Bound For Glory" — the title does not exist as briefed

I searched for it four ways (as a Wolverine title, as a college football sim, as a PC manager game,
excluding wrestling). **There is no football management game by that name.** The name resolves
almost entirely to TNA Wrestling pay-per-views, plus an unrelated itch.io indie. Wolverine Studios'
Steam catalogue (39 titles) is Draft Day Sports across Pro/College Football, Pro/College Basketball,
Hockey and Baseball; no such title appears. [C]

**Most likely intended:** **Bowl Bound College Football** (Grey Dog Software, designer Arlie Rahn) —
the older text-based college pole, "over 100 college football programs in over 10 regional
conferences". I profiled it as the substitute, because the substance the brief wanted from this slot
(a deep text college sim's failure modes) is exactly what it supplies:

- **Praised for:** deep recruiting with scouts reporting recruit preferences, potential and
  offensive fit; program and coach prestige and football philosophy both mattering in recruiting;
  "unparalleled breadth of team playcalling control"; called "the best text-based college football
  simulation". [Q]
- **Complained about:** **instability** — "crashes occurring multiple times in each session and
  sometimes even deletion of saved games"; **UI friction** — players "spending considerable time
  flicking back and forth between emails and the recruiting screen"; and, most decision-relevant,
  **play-calling without feedback**: "calling plays can be frustrating due to lack of play-by-play
  feedback or analysis to explain why plays work or don't work." [Q]

That third complaint is a direct hit on D1/D2 and is carried into §6.

**Owner action:** confirm whether the brief meant Bowl Bound, or a title I have failed to identify.
Until then, treat this section as a substitution, not a completion, of that slot.

#### 1.5 The wider Wolverine Studios catalogue

Founded by **Gary Gorski, May 2006**, Ortonville, Michigan; stated goal "create the deepest, most
realistic franchise mode sports simulations possible"; **39 Steam titles**. [C] The catalogue is the
most useful part of this section because the *same complaint pattern repeats across sports*, which
is much stronger evidence than any single football SKU's 13 reviews.

**DDS: Pro Basketball 2026** (12 reviews, 91% positive) carries both the sharpest praise and the
sharpest criticism found anywhere in this research:

- Praise: "the updated UI is immaculate, the new AI trade logic is amazing, and the different AI
  coaches/GMs all take different approaches to rebuilding teams." [Q]
- Criticism: "glaring issues with both the implementation of basic basketball rules and awful
  strategic and tactical decision making by **in-game coach AI at the game-by-game simulation
  level**", plus a charge that the studio "isn't putting a lot of effort into improving the game
  over time, with the game remaining an unpolished mess in many areas." [Q]
- Clock-model incoherence: "a series of three passes might cumulatively take 1 second off the shot
  clock, while at other times one animation step will take 4 or 5 seconds off the clock." [Q]

**DDS: College Basketball** — freezes on loading screens "if you click too much"; AI player-
development decisions questioned. [P] CB26 added NIL options and transfer-portal settings, mirroring
the football line. [P]

Two catalogue-level patterns worth carrying:

- **"Smarter AI" is the annual headline feature across every sport, every year.** PF26: "Smarter AI
  & Realistic Gameplay"; PB26: "Smarter AI, New Archetypes"; CFB27: "smarter coaching AI". A studio
  that ships a paid release annually and leads with AI improvements every single year is telling you
  the AI is never finished. [C]
- **The praised and the damned are the same subsystem.** "New AI trade logic is amazing" and
  "awful … in-game coach AI" appear in the same title's review page. AI is not one thing; §2 splits
  it.

---

### 2. D10 — is AI really the dominant complaint in this genre?

**Verdict: no, not as a flat statement — and the correction matters more than the confirmation.**

AI quality is the dominant complaint **among players who have already committed**. It is not the
dominant complaint overall, and it is not what stops people buying or what produces the
"not recommended". Presentation, performance and stability are. Building D10 on the unqualified
premise would misallocate a solo developer's scarcest resource.

#### 2.1 The split, with the evidence

**Entry-killers — what produces refusal, refunds and one-star:**

| Complaint | Where seen |
|---|---|
| Menu latency 2–4 s per click; play-by-play "almost unusable" | DDS:PF Steam negatives [Q] |
| "Absolutely awful Windows 95-style UI" | FOF Eight [Q] |
| "Menus clunky and awkward, which sapped all the fun out of the game" | DDS:PF [Q] |
| Crashes / save deletion / save corruption | Bowl Bound [Q]; FOF Nine [P]; and `01-RESEARCH.md` §H rank 1 |
| "Massive amount of reading"; no ramp for newcomers | FOF Eight review [Q] |
| Disorganised information architecture, no boxscore links | DDS:CFB gmgames review [Q] |

**Ceiling-killers — what ends a committed player's engagement:**

| Complaint | Where seen |
|---|---|
| Trade / draft / contract AI | FOF [Q]; genre survey [Q] |
| Free-agent valuation nonsense; unsignable mispriced stars | DDS:PF [Q] |
| Human/AI rule asymmetry (dead money on AI books, not yours) | DDS:PF [Q] |
| **In-game coach AI tactical decisions** | DDS Pro Basketball [Q] |
| Stat drift over a career (nine 1,500-yard WRs; 4,500-yard 70-OVR QBs) | DDS:PF [Q] |
| AI programmes under-competing for recruits | DDS:CFB 27 fix notes [P] |
| The wall at 500–1,000 hours | FOF dev thread [P] |

The genre-level survey states the ceiling-killer set almost as a definition: sports management sims
"often have flawed trade/free agency logic allowing players to put together a dynasty too easily,
unpredictable simulation patterns that spit out unrealistic results over time, and a general lack
of in-depth scouting and player development." [Q]

#### 2.2 The taxonomy D10 should actually adopt

"AI quality" is four separable systems with four different failure signatures, four different test
harnesses, and four different costs. Treating them as one line item is how the whole thing gets cut
when the schedule slips.

| # | System | Failure signature seen in the wild | Detectable by |
|---|---|---|---|
| A1 | **Valuation AI** (contracts, trades, FA bidding, draft boards) | Mispriced assets; exploitable accept boundary; human dynasties built too easily; asymmetric rules | Soak assertion: cross-league price dispersion; an *exploit-probe* test that brute-forces the accept boundary and asserts it cannot be farmed |
| A2 | **Roster-construction AI** (who to sign, cut, develop, rebuild) | League-wide talent drift; AI teams stop being hard in year 10 | Soak invariant: parity band on final standings and roster quality at seasons 1, 5, 10, 20 |
| A3 | **In-game tactical AI** (playcalling, clock, 4th down, timeouts) | "Awful strategic and tactical decision making"; incoherent clock; unwatchable-because-stupid | Calibration band on situational decisions (4th-down go rate by yardage/score/time) vs. a stated target; a clock-conservation assertion |
| A4 | **Recruiting / acquisition AI at scale** (the 130-programme case) | AI schools under-compete → human runs away with every class | Distribution test: class-quality Gini across all programmes; human win-rate on contested recruits must sit in a band, not at ~1.0 |

**Recommendation for D10:** specify all four with separate instruments, and rank them for a
schedule-slip triage as **A1 > A4 > A2 > A3**. A1 because it is the one every community in the
catalogue names and the one that is *exploitable* (an exploitable economy destroys jeopardy, which
is D8's whole substrate). A4 because in the college tier it is the difference between a league and
a diorama. A3 last **only if** D1 lands on an agency model where the player is calling the
high-leverage decisions themselves — because then the tactical AI is mostly running the opponent
and the off-screen slate, where a mediocre-but-consistent policy is survivable. If D1 lands on
spectate-and-adjust, **A3 moves to first**, because then the coordinator AI *is* the game.

That conditional is the real finding: **A3's priority is a function of D1, so D10 cannot be
finalised before D1 is.** Order them in `OPEN-DECISIONS.md` accordingly.

#### 2.3 The counter-evidence, stated plainly

- DDS:PF 2025's negative reviews I could surface are dominated by **lag, bugs and UI**, not AI.
- FOF Eight scores 84% positive and 8.5/10 *with* an interface universally described as terrible and
  *with* known AI complaints — so neither one is disqualifying on its own.
- FOF Nine's trade AI is reported as **improved** ("allowing players to better predict what teams
  would accept") by a critic who still didn't like the game — so fixing A1 does not by itself buy
  affection.
- Football Manager 26 launched to "Mostly Negative" — 7th worst-rated on Steam, slammed for UI,
  missing features, performance — and reviewers hating it had **60, 70, 100+ hours** logged, prompting
  the observation "It's quite something to apparently hate a game that strongly and yet keep playing
  it." [Q] Depth retains even under active hostility, *in an established franchise with 30 years of
  sunk identity*. A new v1 has none of that credit.

---

### 3. Presentation, UI, and whether depth alone kept players engaged

#### 3.1 Depth alone does not carry the entry

The strongest formulation available is the survey line about FOF8: best mechanics and simulation in
the category, "absolutely awful Windows 95-style UI", and it "assumes you know all about American
football already". [Q] That title has been the connoisseur's choice for two decades and sits at
**275 lifetime Steam reviews**. Football Coach: College Dynasty — an explicitly *shallower* college
sim reviewed as "not the most complex sports simulation on the market … a valuable point of entry
for gamers new to the genre, or a more relaxing option for seasoned sports sim gamers" — sits at
**~1,474 reviews, 95% positive**. [P]

Roughly **5× the audience for admittedly less depth, on the strength of legibility and pacing.**
That is the clearest available answer to §3 of the governing brief: in this genre, depth is what
retains the committed and legibility is what recruits anyone at all. Two different problems.

#### 3.2 What actually holds the committed: human opponents

The FOF developer's own framing of the 500–1,000-hour wall pairs it with **multiplayer-league
support**. [P] DDS:PF's community says the same thing more bluntly: the game is "really worth the
money if you join an MP league", where "the simulation becomes a gem" and there is "a great group of
GMs that provide good competition"; and the counter-complaint from solo players is that the
developer has been "more focused on the multiplayer simulation aspect rather than single-player
management gameplay". [Q]

**This is a problem for this project and it should be escalated as one.** P1 and P3 forbid
networking, accounts and any server. The deep-sim pole's own answer to long-run engagement —
*replace the AI with humans* — is constitutionally unavailable to us. Anything we build must
generate its own long-run jeopardy from AI and narrative alone, which is precisely the axis the same
communities say is weakest. See §6, finding 3.

#### 3.3 The presentation lesson that transfers to a 2D `Canvas`

Bowl Bound's complaint is the one to internalise: **"calling plays can be frustrating due to lack of
play-by-play feedback or analysis to explain why plays work or don't work."** [Q] The failure is not
that the presentation was ugly; it is that it was **non-diagnostic**. The player made a decision,
saw an outcome, and could not construct a causal story. Under those conditions, agency is
indistinguishable from a dice roll, and a decision the player cannot learn from stops being a
decision.

DDS:PF 26's presentation work points the same way from the opposite side — the additions are
**highlight ribbons, rotating stat displays, and pan/zoom that tracks the ball**. [P] Not fidelity.
Attention direction and readout. That is a strong prior for D2/§6.5: a `Canvas` view earns its cost
by *explaining the snap*, not by depicting it.

---

### 4. Session length: is a season a slog?

Direct per-season timings for DDS/FOF are not published and I could not reach forum threads that
might contain them. What I did establish:

- **Speed is a named, recurring engineering objective**, not a solved property. DDS:CFB shipped
  "lightning fast with screen changes, which was a previous complaint"; FOF Nine was rebuilt on a new
  codebase "designed for simulation speed"; and DDS:CFB advertises simming "multiple seasons in just
  minutes". [P] A studio does not put that in the changelog three years running unless players
  noticed.
- **The friction that gets called a slog is per-click latency, not per-season length.** "Each click
  between menus taking 2–4 seconds" is the shape of the complaint. In a genre where a week costs
  dozens of screen transitions, a 2 s transition is a 1–2 minute tax per week, ~30 minutes per
  season, *spent on nothing*. [P]
- **The slog complaint that is unambiguous is recruiting**, and it is §5.

**Directly relevant to P4 and D4:** the deep-sim pole's own evidence says the season-time budget is
eaten by *transition cost*, not by *decision cost*. A design that meets P4 by cutting decisions
while leaving a laggy, many-tap information architecture in place would be optimising the wrong
term. Restate the D4 budget with a **per-screen-transition ceiling** and a **taps-per-week ceiling**
alongside the week-advance figure, or the arithmetic in §4 of the brief will be right and the game
will still feel slow.

[ASSUMPTION] I could not source a wall-clock figure for a DDS:CFB season played at full recruiting
fidelity. My estimate from the mechanics in §5 — 15–16 recruiting decision points × a
multi-screen allocation pass each — is *hours per season on recruiting alone*, which is consistent
with the "grueling" complaints but is inference, not measurement.

---

### 5. DDS:CFB and recruiting throughput across 130+ programmes — the D3/D4 core

This is the most load-bearing section for this project, because P2 makes the college tier a v1
feature and the college tier is where the computational and attentional budgets both break.

#### 5.1 The real-world scale the genre models

- FBS: **10 conferences, 138 schools** as of the 2025 season. FCS: **129 teams in 2025, ~127 in
  2026**. [P] The brief's "~134 programmes" is in the right band.
- Scholarship limit moved from **85 to 105** for FBS in the 2025–26 academic year. [P] That is a
  ~24% increase in roster and therefore in annual recruiting volume — worth deciding explicitly for
  D5 rather than inheriting an obsolete 85.

#### 5.2 How DDS:CFB actually meters recruiting

The mechanism, from the developer's own recruiting guide [P]:

- **Recruiting points** are a pool the player allocates across recruits. More points on a recruit =
  more aggressive pursuit.
- **Points are re-allocable, not consumed per tick.** They "carry over"; you do not receive a fresh
  allocation each sim, you redistribute the same pool. If a recruit signs *elsewhere*, his points
  return to you. If he signs *with you*, those points are **locked** for the rest of the cycle.
- **Cadence:** recruiting begins at the week-1 regular-season sim and runs at **every sim through
  the bowl sim**, then pauses for championships/end-of-season, then gets **one final pass before the
  signing-day sim**. That is roughly **15–16 allocation opportunities per season**.
- **Scholarships available** are derived from roster size and graduating class, not a flat number.
- **Signing-day backstop:** unfilled scholarships get filled automatically — "your coaches will
  travel the country on signing day and help you get your roster filled", and those players still
  receive scholarships.
- CFB 27 layers **NIL budgets** on top: manage a budget, make competitive offers, plus expanded
  recruiting conversations and improved team-fit analysis.

#### 5.3 The four throughput devices, and the one that is missing

Read as design, DDS:CFB survives 130+ programmes by using four devices:

1. **A single fungible currency instead of per-recruit verbs.** One number per recruit. No visit
   scheduling, no call queue, no per-recruit minigame at the base layer. Allocation is O(recruits on
   your board), and the board is yours to bound.
2. **Refundable, re-allocable resource.** Losing a battle is not a sunk cost — points come back.
   This is what makes a 15-week campaign tolerable: you are steering, not spending.
3. **Locked points on success.** Winning a recruit permanently reduces your remaining flexibility.
   That is the cost model, and it is elegant: it makes the *decision to close* the real decision.
4. **A guaranteed floor.** Signing day cannot leave you short. **This is the anti-dead-end
   invariant, and it is the direct college analogue of the carousel invariant in
   `01-RESEARCH.md` §H rank 2 and brief D8.** Note it as a pattern, not a coincidence: successful
   sims in this genre put a floor under every resource loop.

**What is missing across the entire genre is a middle setting.** The evidence is consistent and
comes from three independent titles:

- Football Coach: College Dynasty — "some players wish it had a more simplified/shorter recruiting
  option, as the drawn out recruiting process can be grueling, though the only other option is
  auto-recruiting." [Q]
- EA College Football 26 — "Auto recruiting should be a quality-of-life feature to help Dynasty
  players who don't have time to micromanage 15–25 recruits every single week. However, the system
  remains almost exactly where it was last season — functional in theory, but deeply flawed in
  execution," to the point of turning a blue-blood programme into a top-30 class; the stated fix is
  that it "needs to function like a real assistant coach — not a complete takeover AI." [Q]
- Bowl Bound — the UI complaint is throughput friction: "spending considerable time flicking back
  and forth between emails and the recruiting screen." [Q]

So the offered choice is **grind or abdicate**. The grind is grueling; the abdication is
incompetent; nothing sits between them. That is a genuine, evidenced, unclaimed design position and
it maps straight onto P4, D3 and D9.

#### 5.4 The AI side of the same problem — and what CFB 27 admits

The player's throughput is only half of D3. The other half is that **every one of the ~134 AI
programmes must also recruit, every week**, and the brief is right that this may cost more than
simulating the games. DDS:CFB 27's headline recruiting change is that "CPU programs now use updated
recruit-targeting logic to pursue players more intelligently" and "AI-controlled schools do a better
job of competing for talent". [Q]

Read that as a two-decade-old studio, on its Nth annual iteration, still shipping *base competence*
in AI recruit targeting as a marquee feature. Two conclusions:

1. **The abstracted recruiting AI is genuinely hard**, and D3's consistency requirement must cover
   it explicitly: the off-screen recruiting model and the visible one must produce class-quality
   distributions that agree within a stated band, tested. Not "the games agree" — **the classes must
   agree**, because class quality is what determines whether year 10 is still hard (A2/A4 in §2.2).
2. **It is also where a small, focused competitor can win**, because the incumbent is visibly still
   working on it.

#### 5.5 The IP finding, for D6 and Tier A

DDS:CFB **ships a fictional universe** and hosts an active mod scene that restores real schools
(dedicated "DDS: College Football 2018-2026 Mods" forum). [C] Third-party fan sites host generated
DDS:CFB league universes as browsable HTML.

Two things follow, and they point in opposite directions:

- **Encouraging:** the category leader in college football management has sustained a commercial
  annual release for years on an entirely fictional universe. Fictional college IP is not a
  commercial death sentence. This materially strengthens the D6 position.
- **Warning:** its community's answer to fictional identity is *to mod real names back in*, and it
  is a substantial, organised scene. Expect the same request. Per Tier A this is absolutely out of
  scope — no importer, no bundled name files, no wink. Design implication: **D6 must make the
  generated identity good enough that the request is about nostalgia and not about deficiency**,
  and `PRODUCT.md` should pre-empt the ask in plain language rather than let the store page absorb
  it as a one-star.

---

### 6. What this should change — findings ranked by decision impact

1. **D10 must be split into four AI systems with four instruments, and A3's rank depends on D1.**
   §2.2. The unqualified premise "AI is the dominant complaint" is not supported; the supported
   claim is "AI is the dominant *ceiling* complaint, presentation/performance/stability is the
   dominant *entry* complaint." A solo developer dies of the second first. Sequence accordingly:
   D10's A1 and A4 are v1 must-haves; A3 is scoped by D1.

2. **There is an unclaimed design position between "grind" and "abdicate" in recruiting, and it is
   the sharpest wedge found in this research.** §5.3. The named target from the community itself:
   *"a real assistant coach — not a complete takeover AI."* Concretely, that means a delegation
   model with (i) standing instructions the player sets, (ii) exceptions escalated back for a
   decision, (iii) a visible account of what the assistant did and why. This is also the mechanism
   that makes P4 survivable in the college tier, and it should be specified in `02-GAME-DESIGN.md`
   as a first-class system, not as a settings toggle.

3. **The genre's own answer to long-run engagement is human opponents, and P1/P3 forbid it.**
   §3.2. Escalate this to the owner as a named risk against D8, not as a footnote. Our jeopardy has
   to come from AI opponents with distinct, legible behaviour (the one thing DDS Pro Basketball's
   reviewers *praised*: "different AI coaches/GMs all take different approaches to rebuilding teams"),
   from the carousel, and from accumulating save-local history — because the multiplayer escape
   hatch is bolted shut.

4. **A 2D match view earns its cost only if it is diagnostic.** §3.3. Bowl Bound proves that
   play-calling without an explanation of *why* the call worked is frustrating rather than engaging;
   DDS:PF 26's own investment went into highlight ribbons, rotating stat readouts and ball-tracking
   camera work. D2 should be judged against "can the player construct a causal story from one
   snap?", and the `Canvas` spec in `04` should budget for annotation — leverage, assignment,
   the losing matchup — before it budgets for smoothness.

5. **Restate D4's budgets with a transition-cost term.** §4. The genre's slog is 2–4 s per click ×
   dozens of clicks per week, not the length of the season. Add a per-screen-transition ceiling and
   a taps-per-week ceiling to D4, and make them assertable.

6. **Steal the four throughput devices, and generalise the floor.** §5.2. Single fungible currency;
   refundable on loss; locked on success; guaranteed floor at the deadline. The floor pattern
   already appears independently in this repo as the carousel invariant (§H rank 2 / D8). Promote it
   to a stated design principle: *every resource loop in this game has a floor that prevents a
   dead end*, and make it a soak assertion, not prose.

7. **Calibration must be asserted over a career, not a season.** §1.1 complaint 5. "Nine 1,500-yard
   receivers in season four" and "half the QBs over 4,500 yards" are not season-one bugs; they are
   drift. `03-MATCH-ENGINE.md`'s calibration harness must run its bands at seasons 1, 5, 10 and 20
   of the soak, not once. Extends `01-RESEARCH.md` §H rank 3 from *believability within a game* to
   *believability across a career*.

8. **Fictional college IP is commercially proven; plan for the mod request anyway.** §5.5. Good news
   for D6 and for Tier A. Also a `PRODUCT.md` messaging task.

9. **The 1,474-vs-275 review gap is the market argument.** §3.1. The accessible college sim
   out-audienced the connoisseur pro sim ~5:1. Feed this directly into §6.3; it argues that the gap
   is not "more depth than DDS" but "DDS-class depth that is legible on a phone."

10. **The promotion arc is now a shipped, validated genre feature — and P2 should not be defended as
    novel.** DDS:CFB 26 added coordinator→head-coach progression via reputation and the carousel;
    DDS:PF 26 added head coach / coordinator / position coach roles; DDS:PF can already import a
    DDS:CFB universe to bring college rookies into the pro draft. [C] P2's actual novelty is that it
    is **one save and one continuous career on a phone**, not that college and pro coexist.
    `PRODUCT.md` should make that claim precisely, or a reviewer will correct it.

---

### 7. Delta against `01-RESEARCH.md` §C and §H

Explicitly extending, not restating. §C/§H mined *the iOS reference app* and *the Android Achi Jones
lineage*; this section mines *the PC deep-sim pole*.

| Existing finding | What this research adds or changes |
|---|---|
| §H-1 Crashes / save corruption dominate (34% of reviews) | **Corroborated across the whole pole.** Bowl Bound deletes saves; FOF Nine corrupts at end of year one, just after free agency. Stability is not an iOS-indie problem — it is the genre's baseline failure. Strengthens the P7 soak gate. |
| §H-2 Job-market dead ends | **Generalised into a principle.** DDS:CFB's signing-day backstop is the same invariant applied to recruiting. §6 finding 6 promotes "every resource loop has a floor" to a design principle with a soak assertion. |
| §H-3 Sim believability; watched-vs-simmed divergence | **Extended along the time axis.** The PC pole's complaint is not within-game divergence but **multi-season statistical drift**. New requirement: calibration bands at season 1/5/10/20, not just at season 1. §6 finding 7. |
| §H-6 Recruiting UX friction; "the loop itself is loved" | **Sharpened into a positioning wedge.** Across three independent titles the only settings offered are grind or abdicate. The community's own words name the missing middle: "a real assistant coach — not a complete takeover AI." §5.3. |
| §H-9 Game-day control suite; smarter AI EV decisions | **Split into four systems with instruments.** §2.2. Also reprioritised: A1 valuation AI outranks A3 tactical AI unless D1 chooses spectate-and-adjust. |
| §H "Arcade-mode reality check": nobody asked for joystick play | **Corroborated from the opposite pole.** Neither DDS, FOF nor Bowl Bound has direct player control and none of their communities asks for it. What they ask for is *play-calling with legible causality*. Supports removing the arcade layer; **does not** support removing the explanatory layer. |
| §C "no real cap" / depth asks | Confirms the depth asks are real, and adds the cost: DDS:PF's own free-agency valuation AI is its most-cited systems complaint. Depth without a competent valuation model is worse than less depth. |
| §E competitive positioning ("no modern pro football management sim on iOS") | **Mostly intact, one correction.** The PC pole has moved: DDS:PF and DDS:CFB now interoperate, and both added coach-career ladders. The lane on iOS is still open, but "college→pro career" is no longer a differentiator on its own. §6 finding 10. |
| §B "Dev's current path: Steam, Pro Football Dynasty" | Unchanged by this research; note only that it enters a market whose incumbent already annualises at $24.99 with FirstAccess and deep back-catalogue discounting. |

---

### 8. Assumptions and unverified claims

Listed together so the owner can see exactly what the design would rest on.

- **[U] Mobile availability of Draft Day Sports.** TapTap carries "for Android/iOS" listings for
  DDS:CFB 2024 and DDS:PF 2025, and gmgames' publisher profile lists platforms including Android and
  iOS. The Steam store listings are Windows. I could not reach either store to adjudicate.
  **Do not use "there is no deep sim on iOS" as a positioning claim until this is checked**, because
  it is exactly the claim a reviewer will test. Owner action: check the App Store directly.
- **[U] DDS:PF 2025's 46%/13-review score as a quality signal.** At n=13 this is noise. It is
  reported here for completeness and should not appear in `PRODUCT.md`.
- **[U] "The community for the game is dead"** (DDS:PF single-player criticism). Single source,
  unverifiable, and contradicted by an active phpBB board and annual releases.
- **[U] The exact wording of the FOF "500–1,000 hours" wall.** The substance — a stated engagement
  ceiling discussed alongside multiplayer-league support — is what I rely on. The number should be
  re-verified before it is quoted in canon.
- **[ASSUMPTION] Recruiting costs hours per season at full fidelity in DDS:CFB.** Derived from
  15–16 allocation passes × a multi-screen pass each. No measured figure found. §4.
- **[ASSUMPTION] The "entry-killer vs ceiling-killer" split is mine.** The individual complaints are
  sourced; the two-bucket model and the ordering claim ("a solo developer dies of the entry-killers
  first") are my synthesis and should be treated as an argument, not a finding.
- **[ASSUMPTION] A1 > A4 > A2 > A3 triage ordering.** Argued in §2.2 from the recurrence of
  valuation complaints and the exploitability argument; not measured.
- **"Bound For Glory" does not exist as a football management title** — this is a sourced negative,
  but negatives are weak. If the owner can supply a developer or a store link, §1.4 should be redone
  properly rather than left as a substitution.
- **Every [Q] string in this document reached me through the WebSearch summarisation layer**, not
  from the source page. Before any of them is quoted in `PRODUCT.md`, `02-GAME-DESIGN.md` or a store
  listing, it must be re-verified against its URL on an unrestricted machine. See §0.1.

---

### 9. Sources

All URLs below were returned by the WebSearch tool during this research. Those marked ⛔ were
additionally attempted via direct fetch and refused by the organisation's egress proxy.

**Draft Day Sports — Pro Football**
- https://store.steampowered.com/app/3323590/Draft_Day_Sports_Pro_Football_2025/ ⛔
- https://steamcommunity.com/app/3323590/ ⛔
- https://steamcommunity.com/app/3323590/discussions/0/4638240322751683981/ (thread: "Too expensive") ⛔
- https://steamcommunity.com/app/3323590/discussions/0/595150188903958973/ (thread: "Where Draft Day Sports: Pro Football really shines")
- https://store.steampowered.com/app/4041080/Draft_Day_Sports_Pro_Football_2026/
- https://steamcommunity.com/app/4041080/
- https://steamcommunity.com/app/2625350/reviews/?browsefilter=toprated (DDS:PF 2024)
- https://steamcommunity.com/app/2163800/reviews/?browsefilter=toprated (DDS:PF 2023)
- https://steamcommunity.com/app/782510/reviews?browsefilter=toprated (DDS:PF 2018)
- https://steamcommunity.com/app/782510/discussions/0/1700541698679858770/ (DDSPF18 guide)
- https://www.wolverinestudios.com/games/draft-day-sports-pro-football
- https://www.wolverinestudios.com/post/new-features-coming-in-draft-day-sports-pro-football-26
- https://wolverinestudios.freshdesk.com/support/solutions/articles/44002010924-draft-day-sports-pro-football-game-plan-guide ⛔
- https://wolverinestudios.freshdesk.com/support/solutions/articles/44002010920-draft-day-sports-pro-football-user-guide-legacy-
- https://gmgames.org/2025/09/19/draft-day-sports-pro-football-2026-expands-coaching-roles-smarter-ai-and-custom-leagues/
- https://gmgames.org/draft-day-sports-pro-football-2022/review/
- https://www.operationsports.com/draft-day-sports-pro-football-22-review-another-solid-entry-in-the-series/
- https://www.metacritic.com/game/draft-day-sports-pro-football-2025/ ⛔
- https://www.draftdaysports.com/board/viewtopic.php?f=386&t=37570 (thread: "First thoughts") ⛔

**Draft Day Sports — College Football**
- https://store.steampowered.com/app/3154850/Draft_Day_Sports_College_Football_2025/
- https://steamcommunity.com/app/3154850/reviews/?browsefilter=toprated
- https://steamcommunity.com/app/3154850/discussions/
- https://store.steampowered.com/app/3914070/Draft_Day_Sports_College_Football_2026/
- https://steamcommunity.com/app/3914070/discussions/
- https://steamcommunity.com/app/878710/discussions/0/1736594593603384294 (DDS:CFB 2018 recruiting discussion)
- https://wolverinestudios.com/games/draft-day-sports-college-football/
- https://www.wolverinestudios.com/draft-day-sports-college-football-simulation/
- https://www.wolverinestudios.com/post/work-your-way-up-the-coaching-ladder-in-draft-day-sports-college-football-26
- https://wolverinestudios.com/10-reasons-draft-day-sports-college-football-27-is-the-ultimate-game-for-college-football-dynasty-builders/
- https://wolverinestudios.freshdesk.com/support/solutions/articles/44002148051-draft-day-sports-college-football-recruiting-guide ⛔
- https://wolverinestudios.freshdesk.com/support/solutions/articles/44002148052-draft-day-sports-college-football-scouting-guide
- https://wolverinestudios.freshdesk.com/support/solutions/articles/44002582595-dds-football-user-guide
- https://www.draftdaysports.com/board/viewforum.php?f=392 (DDS:CFB 2026 General Discussion) ⛔
- https://www.draftdaysports.com/board/viewtopic.php?f=380&t=37400 (thread: "Recruiting help")
- https://www.draftdaysports.com/board/viewforum.php?f=268 (DDS:CFB 2018–2026 Mods forum)
- https://www.draftdaysports.com/board/viewtopic.php?f=336&t=34456 (thread: "How to sim entire season?")
- https://gmgames.org/draft-day-sports-college-football-2025/review/
- https://gmgames.org/draft-day-sports-college-football-2023/review/
- https://gmgames.org/2025/08/01/draft-day-sports-college-football-26-released-for-windows-pc/
- https://www.operationsports.com/draft-day-sports-college-football-27-first-access-available-now/
- https://www.operationsports.com/draft-day-sports-college-football-26-first-access-begins-on-august-1/
- https://www.sncfl.us/Index.html (third-party hosted DDS:CFB universe)
- https://football.championsimleague.com/college/HTML/Teams/112.html (third-party hosted DDS:CFB universe)

**Front Office Football / Solecismic**
- https://store.steampowered.com/app/547900/Front_Office_Football_Eight/
- https://steamcommunity.com/app/547900/discussions/0/1489992080520563191/ (thread: "Lost Interest")
- https://steamcommunity.com/app/547900/reviews/?browsefilter=toprated
- https://store.steampowered.com/app/2633170/Front_Office_Football_Nine/
- https://steamcommunity.com/app/2633170/discussions/0/4356746036670287329/ (thread: "Not great")
- https://steamcommunity.com/app/2633170/discussions/0/4032473436328480481/ (thread: "I am confused by the reviews")
- https://steamcommunity.com/app/2633170/discussions/0/5513030395222850839/ (thread: "Fixes and Features List")
- http://www.solecismic.com/frontofficefootball.php
- http://www.solecismic.com/documentation/dokuwiki/doku.php?id=faq
- http://www.solecismic.com/documentation/dokuwiki/doku.php?id=updates
- http://www.solecismic.com/reviews.php
- https://www.operationsports.com/front-office-football-8-review-pc/
- https://forumsold.operationsports.com/reviews/853/front-office-football-eight/
- https://forums.operationsports.com/fofc/showthread.php?p=3391873 (thread: "AI trade logic??") ⛔
- https://gmgames.org/front-office-football-8-fof8/review/
- https://gmgames.org/front-office-football-9-fof9/
- https://gmgames.org/developer/jim-gindin/
- https://gmgames.org/2020/06/11/ootp-developments-and-solecismic-software-part-ways/
- https://gmgames.org/2021/02/20/fof9-scrapped-jim-gindin-sells-algorithmic-code-and-pursues-different-format-of-game/
- https://www.metacritic.com/game/front-office-football-eight/ ⛔
- https://steamspy.com/app/2633170

**Wolverine Studios catalogue**
- https://wolverinestudios.com/
- https://store.steampowered.com/search/?publisher=Wolverine+Studios
- https://steamdb.info/publisher/Wolverine+Studios/
- https://steambase.io/publishers/wolverine-studios ⛔
- https://gmgames.org/publisher/wolverine-studios/
- https://steamcommunity.com/app/3914210/reviews/?browsefilter=toprated (DDS: Pro Basketball 2026)
- https://store.steampowered.com/app/3914210/Draft_Day_Sports_Pro_Basketball_2026/
- https://steamcommunity.com/app/3440610/reviews/?browsefilter=toprated (DDS: College Basketball 2025)
- https://gmgames.org/2025/11/14/draft-day-sports-pro-basketball-26-tips-off-with-smarter-ai-new-archetypes-and-a-modernized-gm-experience/
- https://gmgames.org/2026/03/04/draft-day-sports-college-basketball-26-adds-nil-options-transfer-portal-settings-and-updated-game-presentation/

**"Bound For Glory" — negative result, and the Bowl Bound substitution**
- https://en.wikipedia.org/wiki/Bound_for_Glory_Series (TNA wrestling — what the name actually resolves to) ⛔
- https://matausch.itch.io/bound-for-glory (unrelated indie)
- https://greydogsoftware.com/title/bowl-bound-college-football/
- https://store.steampowered.com/app/398640/Bowl_Bound_College_Football/
- https://steamcommunity.com/app/398640/reviews/?browsefilter=toprated
- https://forumsold.operationsports.com/reviews/127/bowl-bound-college-football/
- https://forum.greydogsoftware.com/forum/40-bowl-bound-college-football-general-discussions/
- https://gmgames.org/bowl-bound-college-football/

**Genre-level and cross-reference**
- https://www.onpapersports.com/blog/best-football-management-games ⛔
- https://gmgames.org/section/american-football-nfl-college-manager-simulator-games/
- https://grandstandcentral.com/2018/sports/esports/the-momentous-rise-of-sports-management-games/
- https://medium.com/@parkergoss/sports-management-games-and-simulators-arent-going-away-anytime-soon-c4ad39e32da7
- https://loudpoet.com/2026/01/18/my-newest-data-informed-obsession-ootp26/
- https://store.steampowered.com/app/2151290/Football_Coach_College_Dynasty/
- https://steamcommunity.com/app/2151290/reviews/?browsefilter=toprated
- https://steamcommunity.com/app/2151290/discussions/0/4205868583241554711/ (thread: "Doing hard recruiting")
- https://www.operationsports.com/football-coach-college-dynasty-review-a-sports-sim-with-training-wheels-for-better-and-worse/
- https://steambase.io/games/football-coach-college-dynasty/steam-charts
- https://www.gamesbuilds.org/News/college-football-26-why-auto-recruiting-is-still-the-most-underwhelming-feature.html
- https://forums.operationsports.com/forums/forum/football/ea-sports-college-football-and-ncaa-football/947333-does-anyone-do-auto-recruiting-in-dynasty
- https://www.pcgamer.com/games/sim/football-manager-26-launches-straight-into-a-relegation-battle-as-steam-reviews-plummet-to-mostly-negative-been-playing-since-1993-and-this-is-the-worst-one/
- https://www.forbes.com/sites/barrycollins/2025/11/08/football-manager-26-is-it-as-bad-as-the-steam-reviews-suggest/
- https://gamerant.com/football-manager-26-steam-reviews-mostly-negative/
- https://www.taptap.io/app/33769262 (unverified DDS:PF mobile listing — see §8)
- https://www.taptap.io/app/33599573 (unverified DDS:CFB mobile listing — see §8)

**Real-world scale references (for D3/D5 sizing)**
- https://en.wikipedia.org/wiki/List_of_NCAA_Division_I_FBS_football_programs ⛔
- https://en.wikipedia.org/wiki/2025_NCAA_Division_I_FCS_football_season ⛔
- https://www.ncsasports.org/football/scholarships (85→105 scholarship change)

---

## §6.2B — The arcade pole and the mobile-native competition

Research part for `docs/reviews/2026-08-09-spec-prompt-v4.md` §6.2, part B. Scope: **Retro Bowl,
Retro Bowl College, Football Coach: College Dynasty, and every other mobile-native American
football management/coaching sim found on the App Store and Play Store.** Part A (Draft Day Sports,
Front Office Football, Bound For Glory, Wolverine Studios) is a separate document.

This file **extends** `docs/01-RESEARCH.md` §B (Achi Jones lineage), §C (r/FootballCoach signal),
§G (Retro Bowl mechanics) and §H (reference-app community mining). It does not restate them. Where
a claim already lives in those sections it is cited as `→ 01-RESEARCH §X` and only the *new* or
*corrected* part is written out.

---

### 0. Method, and what limits this document

**Egress constraint, stated up front.** `WebFetch` is refused by the network egress proxy for every
domain this research needed — `apps.apple.com`, `play.google.com`, `store.steampowered.com`,
`steamcommunity.com`, `gmgames.org`, `coachapps.io`, `reddit.com`. The proxy status endpoint
confirms it (`connect_rejected … gateway answered 403 to CONNECT` for `store.steampowered.com`).
All content below therefore arrived via `WebSearch`, which returns page-derived text from indexed
pages. **Every URL in §9 is a real page whose content was surfaced; none was read in full.** This is
the same limitation the §6.1 part operated under, and the same consequences apply:

- Substance is reliable; exact wording and surrounding qualification are not guaranteed.
- **Reddit is entirely unreachable.** The brief names r/RetroBowl and r/FootballCoach as sources;
  neither could be retrieved. Player voice below comes instead from **App Store / Play Store review
  text surfaced in search**, **Metacritic user reviews**, **Steam reviews and discussions**,
  **Operation Sports** (review + forums), **Pocket Tactics / Pocket Gamer / Nintendo Life**, the
  **Retro Bowl Fandom wiki**, **inreviewcritics.com** and **gmgames.org**. For the two Retro Bowl
  titles the Fandom wiki is a mechanics reference cross-checked against store copy and reviews; for
  the Achi Jones/SidelineSim titles the Steam review corpus is larger and better than any subreddit.
- Anything unsourced is marked **ASSUMPTION** (a guess) or **DERIVED** (arithmetic from sourced
  numbers) inline, and collected in §8.

**A correction to the brief's framing, made up front because everything downstream depends on it.**
The brief describes Football Coach: College Dynasty as "*a mobile college coaching sim with no
direct control … the single most relevant competitor in the whole brief*." Two halves of that are
wrong and the error changes the conclusion:

1. **It is not mobile.** FC:CD is Windows/Steam only, released 16 January 2025, $19.99 base price.
   The developer answered the mobile question directly in a Steam thread titled *"Is there plans for
   IOS/android mobile version?"*, and `gmgames.org` lists it as **Windows PC**. There is no iOS or
   Android build. ([Steam](https://store.steampowered.com/app/2151290/Football_Coach_College_Dynasty/),
   [Steam discussion](https://steamcommunity.com/app/2151290/discussions/0/594013679434942086/),
   [gmgames.org](https://gmgames.org/football-coach-college-dynasty/))
2. **It has per-snap direct control of play-calling.** You can call every offensive and defensive
   play from a 100+ play book, advancing the game one play at a time, or flip on `auto-sim` to let
   it run. ([Steam](https://store.steampowered.com/app/2151290/Football_Coach_College_Dynasty/),
   [Steam discussion](https://steamcommunity.com/app/2151290/discussions/0/3826425639848612057/))

So FC:CD is not the closest product on the axis the brief cares about. It is still the most
instructive one, because **its solution to the agency/throughput problem is the exact mechanism §4
needs** (§4.3 below). The genuinely closest *mobile* product — college and pro in one app, on iOS —
is **Football Coach: Winning Tradition** by On Paper Sports, which the brief does not name and which
nobody in the prior research found (§5.1). That is the single most important discovery in this part.

---

### 1. The field, at a glance

Every mobile-native American-football management/coaching title I could find, plus the two PC
reference points that anchor the ends. Sorted by relevance to this project.

| Title | Platform | Price / model | Agency model | Match presentation | Scale signal |
|---|---|---|---|---|---|
| **Retro Bowl** | iOS, Android, Switch, web | Free + $0.99 "Unlimited"; ads in free; Retro Bowl+ ad-free on Apple Arcade | Direct control of **offence only**; defence non-playable | Side-scroll pixel 2D for your offence; **defence resolves as text boxes** | 40 M+ downloads; ~$200 K/mo, $2.4 M/yr |
| **Retro Bowl College** | iOS, Android, web | Free + $0.99 Unlimited bundle | Same as Retro Bowl | Same as Retro Bowl | 4.36★ / ~6.5 K iOS ratings |
| **NFL Retro Bowl '26** | Apple Arcade only | Arcade subscription; no ads, no IAP | Same engine | Same, plus licensed NFL identity | Apple Newsroom launch title, 4 Sep 2025 |
| **Football Coach: Winning Tradition** (On Paper Sports) | **iOS + Android** | Free; College Mode + Creation Suite as IAP | Philosophy/gameplan + GM; no player control | Text/box-score; no field view found | ~4.5–4.6★, 25–53 ratings (small, new) |
| **Football Coach: College Dynasty** (SidelineSim) | **Windows only** | $19.99 (seen at $7.99 −60 %) | **Per-snap play-calling, player-paced, with auto-sim** | **Text play-by-play**, Steam-tagged *Text-Based* | 95–96 % positive of ~1.3–1.5 K Steam reviews |
| **Pro Football Dynasty** (SidelineSim) | Windows, **unreleased** | TBA | Presumed as FC:CD | Presumed as FC:CD | Steam page "coming soon", **no date as of Aug 2026** |
| **Pocket GM 3: Football Sim** | iOS (Android via TapTap listing) | Free + IAP | Pure GM; no play-calling | **"Texts and graphs"** play-by-play with momentum | 4.9★, 50 K+ downloads |
| **Ultimate Pro Football GM** (gmz2rk) | iOS + Android | Free, heavy IAP | GM + optional **offensive play-calls in "coach mode"** | Not established | **4.0★ / ~22 K reviews** — largest review corpus in the set |
| **ULT College Football Coach** (gmz2rk) | iOS + Android | Free, heavy IAP | **Real-time play-calling**, custom plays | Not established | — |
| **The Program: College Football** (Fantasy Moguls) | iOS + Android | Free | **Gameplan only — pure spectate** | Not established | Launched 26 Sep 2022 |
| **CFB Simulator** (Mani Foroughi) | iOS | £3.99 God Mode + packs | Playcall + defensive sets, sim-speed tiers | **2D field with LOS/first-down lines + play log** | 4.78★ / 625 US ratings → `01-RESEARCH §A, §H` |
| **EA Sports College Football 27 Mobile** | iOS + Android | Free-to-play card game | Ultimate Team; not a management sim | Arcade | ~40 GB install; EA marketing weight |

Two structural facts to hold:

- **No modern pro football management sim exists on mobile with a 2D match view.** CFB Simulator has
  the 2D view but is college-only; Pocket GM 3 has the pro depth but is "texts and graphs"; Winning
  Tradition has both leagues but no field view. `gmgames.org`'s own verdict on FC:CD states the gap
  in one line: *"the presentation is pretty barebones, so if you need visuals or want something you
  can play on your phone, this isn't it."*
  ([gmgames.org via search](https://gmgames.org/section/american-football-nfl-college-manager-simulator-games/))
- **The pro lane at the top of the genre is still empty.** SidelineSim's Pro Football Dynasty has a
  Steam page and no release date as of August 2026 — a year after `01-RESEARCH §B` recorded it as
  "late 2026". ([Steam](https://store.steampowered.com/app/4769350/Pro_Football_Dynasty/),
  [Operation Sports](https://www.operationsports.com/pro-football-dynasty-coming-soon-to-steam/))

---

### 2. Retro Bowl — the arcade pole

`01-RESEARCH §G` already documents the throw mechanic, the four-attribute player model, the
audible system, coordinators, facilities and the fan-approval fail state. This section adds the
things §G does not cover and that §4 needs: **numbers, throughput, the off-field decision loop, and
the answer to the brief's Question 1.**

#### 2.1 Scale — why this is the audience the project is walking away from

40 million+ downloads across iOS, Android, Switch and browser; ~$200 K/month and ~$2.4 M/year
revenue as of April 2026; Metascore 84 on Switch. Developer is New Star Games (Simon Read, also New
Star Soccer, BAFTA 2013).
([AppBrain](https://www.appbrain.com/app/retro-bowl/com.newstargames.retrobowl),
[AppRank](https://apprank.io/retro-bowl),
[Metacritic](https://www.metacritic.com/game/retro-bowl/),
[Grokipedia — New Star Games](https://grokipedia.com/page/New_Star_Games))

For calibration: CFB Simulator, the app this project's UI was modelled on, has 625 US ratings
(`01-RESEARCH §H`). Retro Bowl is three to four orders of magnitude larger. Whatever is being walked
away from, it is not niche.

#### 2.2 What the player actually does, mechanically, per snap

The complete input surface of a Retro Bowl offensive snap, in order:

1. **A play is dealt, not chosen.** The game hands you one play; you do not pick from a playbook.
   Each dealt play is a **hybrid**: a designed run and a designed pass on the same card. The player
   decides which to execute.
   ([Rob's guide](https://robwritesaboutwhatever.com/2021/04/27/robs-complete-guide-to-retro-bowl-winning-football-games/),
   [Playbite](https://www.playbite.com/q/how-to-change-plays-in-retro-bowl))
2. **Audible.** Tap as the QB reaches the LOS to reroll the dealt play. Limited uses per game
   (count tied to QB level, → `01-RESEARCH §G`). An audible rerolls; it does not let you choose.
   ([Playbite](https://www.playbite.com/q/how-to-change-plays-in-retro-bowl))
3. **Read the defence.** Because you cannot choose the play, the pre-snap decision is *which half of
   the dealt card to run against the alignment you can see*. Play-calling strategy is deliberately
   replaced by read-the-defence. ([Playbite](https://www.playbite.com/q/how-to-change-plays-in-retro-bowl))
4. **The throw** — the one skill expression in the whole game. Drag back from the QB to aim along a
   dotted arc; release to throw. QB Accuracy controls how much of the arc is *rendered*, so the
   player's information about their own input degrades with the player's own rating
   (→ `01-RESEARCH §G`).
5. **The carry.** Auto-run at the carrier's speed; swipe to juke, dive or stall. No sprint, no spin.

Two properties matter more than the list:

- **The loop is closed in a few seconds.** Input → resolution → next input, with no menu between.
- **Attribution is unambiguous.** The player knows *which of their own actions* caused the outcome,
  because there was exactly one action and they made it with their thumb.

#### 2.3 The off-field half — agency that already needs no direct control

This is the part the project can take wholesale, and it is bigger than `01-RESEARCH §G` implies.

- **Coaching Credits (CCs)** are the single currency. Earned per game as a function of **fan support**:
  *"for each third of the fan support bar that is filled either in full or in part, you receive one
  coaching credit at the end of each game."* Spent on staff hires, facilities and roster moves.
  ([Retro Bowl Wiki — Coaching Credits](https://retro-bowl.fandom.com/wiki/Coaching_Credits))
- **Dilemmas** — the mechanic worth stealing. Short, textual, two-option choices fired **before a
  game, after a game, and on bye weeks.** Categories seen: press-conference blame assignment after a
  loss (criticise officials → keeps team morale, costs 1 CC; criticise the team → substantial morale
  hit); front-office meetings (Owner → bonus CC; Team → morale or XP); player discipline (blame the
  underperforming player, or the coach, to save the player's morale). Some dilemmas are strictly
  good, some strictly bad, and a minority are a real trade.
  ([Retro Bowl Wiki — Dilemmas](https://retro-bowl.fandom.com/wiki/Dilemmas),
  [Coaching Credits](https://retro-bowl.fandom.com/wiki/Coaching_Credits))
- **Coordinators with traits** that are *management* effects, not simulation effects: `Likeable`
  (+5 % morale, morale penalty on firing), `Motivator` (instant morale boost on hire), `Fan
  favourite` (+1 % fan support per game, fan-support loss on firing). Note the shape: **every trait
  has a cost attached to reversing it.** That is what makes a hire a decision.
  ([Retro Bowl Wiki — Staff Hires](https://retro-bowl.fandom.com/wiki/Staff_Hires))
- **Facilities**: stadium upgrade raises fan approval immediately; training facility upgrade raises
  team morale. ([Coaching Credits](https://retro-bowl.fandom.com/wiki/Coaching_Credits),
  [Operation Sports review](https://www.operationsports.com/retro-bowl-review-a-mobile-game-that-transcends-the-platform/))

The whole off-field system is a **one-loop economy**: win → fan support → CCs → staff/facilities →
morale/XP → win. Every screen feeds one number. That is the opposite of the previous build's
failure mode, where many screens fed nothing.

#### 2.4 Presentation, and the asymmetric-fidelity trick

Retro Bowl does not simulate a football game at uniform fidelity. **It deletes half of it.** Your
offence is animated in side-scroll pixel 2D; your defence is not playable and *"is played out via
text messages on the screen."*
([Grokipedia](https://grokipedia.com/page/Retro_Bowl),
[HandWiki](https://handwiki.org/wiki/Software:Retro_Bowl))

Critics who like the game still name this: Metacritic reviewers note *"there is a bit of smoke and
mirrors when you look under the hood, as the defense is simplified"*, and Nintendo Life's positive
review calls out *"the lack of defensive play"* explicitly while still recommending it.
([Metacritic user reviews](https://www.metacritic.com/game/retro-bowl/user-reviews/),
[Nintendo Life](https://www.nintendolife.com/reviews/switch-eshop/retro-bowl))

**This is the most important structural fact about Retro Bowl for this project.** The tactility is
paid for by halving the game. A design that keeps both sides of the ball at full presentation
fidelity has twice Retro Bowl's per-game cost before it has added a single management decision.

#### 2.5 Session length and season throughput — real numbers

Sourced inputs:

- Quarter length is **1, 2 or 3 minutes, default 2**; timeouts scale with it (2 per half at 1–2 min,
  3 per half at 3 min). ([Retro Bowl Wiki — Quarters](https://retro-bowl.fandom.com/wiki/Quarters),
  [Options](https://retro-bowl.fandom.com/wiki/Options))
- **"Retro Bowl games take less than 8 minutes per game."**
  ([Operation Sports](https://www.operationsports.com/retro-bowl-review-a-mobile-game-that-transcends-the-platform/))
- Reviewers describe it as *"great for killing 10–20 minutes."*
  ([Pure Nintendo](https://purenintendo.com/review-retro-bowl-nintendo-switch/))
- **Season = 18 weeks** (17 games + 1 bye) with a stated schedule formula; **playoffs = 14 teams**,
  7 per conference, #1 seed byes.
  ([Retro Bowl Wiki — Schedule](https://retro-bowl.fandom.com/wiki/Schedule),
  [Playoff](https://retro-bowl.fandom.com/wiki/Playoff))

**DERIVED arithmetic** (mine, from the above):

```
match time   = (17 regular + 3–4 playoff) × ≤8 min   ≈ 140–168 min  ≈ 2.3–2.8 h
management   = dilemmas + roster + facilities, ~1–3 min/week × 18   ≈ 18–54 min
------------------------------------------------------------------------------
full season  ≈ 2.6–3.7 h, call it ~3 h
```

**And the number that should change a decision:** Retro Bowl's *entire* season fits in roughly
**half of P4's 6–8 hour budget**, and essentially every minute of it is input-dense. P4 is therefore
**not a constraint this project is at risk of exceeding by accident — it is a ceiling roughly twice
as generous as the most successful mobile football game ever made needs.** The danger is the mirror
image of the one §4 frames: filling 2× Retro Bowl's clock with a fraction of its input density.

**DERIVED, lower confidence:** at ≤8 min of wall clock for a 2-min-quarter game where only your
offence is played, the player runs perhaps **20–30 offensive snaps per game** — one authored moment
every ~15–20 seconds. Compare the brief's §4 figure of ~130 snaps per game at full fidelity. **Retro
Bowl's per-game snap count is roughly one fifth of a realistic sim's.** It buys tactility by
deleting snaps, not by speeding them up.

#### 2.6 Monetisation and platform

- Free on iOS/Android/web with **ads**; **$0.99 "Unlimited Version"** bought in the options page
  unlocks Team Editor, weather, a 12-man roster, replays and kick returns (mobile).
  ([Retro Bowl Wiki — Unlimited Version](https://retro-bowl.fandom.com/wiki/Unlimited_Version))
- **Retro Bowl+** on Apple Arcade (23 June 2023) is the base game with Unlimited included, no ads,
  no IAP. ([Retro Bowl Wiki — Unlimited Version](https://retro-bowl.fandom.com/wiki/Unlimited_Version),
  [Retro Bowl+ App Store](https://apps.apple.com/us/app/retro-bowl/id6446029554))
- **NFL Retro Bowl '25** (Sept 2024) and **'26** (4 Sept 2025) are Apple Arcade exclusives with a
  **full NFL/NFLPA licence** — 2,000+ real players, all 32 real team names and logos, real stadiums,
  plus a live weekly Championship Leaderboard tied to the real 2025 NFL season.
  ([Apple Newsroom 2025](https://www.apple.com/newsroom/2025/08/apple-arcade-exclusive-nfl-retro-bowl-26-launching-september-4/),
  [Apple Newsroom 2024](https://www.apple.com/newsroom/2024/08/apple-arcade-launches-three-new-games-in-september-including-nfl-retro-bowl-25/),
  [Cult of Mac](https://www.cultofmac.com/news/apple-arcade-adds-nfl-retro-bowl-26))

**Relevant to P3.** New Star Games' answer to "how do we make more money" was *a licence and a
subscription platform*, not a bigger sim. Both are closed to this project. The unlicensed Retro Bowl
remains free-with-ads on the open stores — i.e. **the highest-volume competitor is free and this
product is paid-premium.** That is not fatal (CFB Simulator sustains a paid model at 4.78★), but it
means the value proposition has to be legible in the store listing without a free tier to prove it.

#### 2.7 What the community praises, and what it complains about

**Praises** (consistent across reviews, Metacritic users and Operation Sports forums):

- **Accessibility with depth underneath.** *"You're not burdened with complex playbooks or intricate
  player stats"* while *"the depth of team management adds a layer of complexity that makes it hard
  to put down."* Critics repeatedly praise *"accessible design … suitable for short play sessions."*
  ([Grokipedia](https://grokipedia.com/page/Retro_Bowl), [Metacritic](https://www.metacritic.com/game/retro-bowl/))
- **Visible, continuous progression.** *"You win games and championships and earn coaching credits
  that can be used to upgrade your team and facilities, with the constant sense of improvement
  keeping you hooked."*
- **The 2-in-1 shape.** Nintendo Life: the on-field play *"combined with the off-field strategy
  essentially makes Retro Bowl a 2-in-1 package even with the lack of defensive play."*
  ([Nintendo Life](https://www.nintendolife.com/reviews/switch-eshop/retro-bowl))

**Complaints:**

| Complaint | Evidence |
|---|---|
| **Defence is not playable; it resolves as text you watch** | [Grokipedia](https://grokipedia.com/page/Retro_Bowl), [HandWiki](https://handwiki.org/wiki/Software:Retro_Bowl), [Nintendo Life](https://www.nintendolife.com/reviews/switch-eshop/retro-bowl) |
| **No real play-calling** — plays are dealt, audibles only reroll | [Rob's guide](https://robwritesaboutwhatever.com/2021/04/27/robs-complete-guide-to-retro-bowl-winning-football-games/), [Playbite](https://www.playbite.com/q/how-to-change-plays-in-retro-bowl) |
| **Repetition and difficulty collapse.** *"The gameplay experience can get a little repetitive"*; *"the scenarios tend to repeat themselves after a while"*; even Extreme difficulty becomes *"very repetitive and boring"* | [Metacritic user reviews](https://www.metacritic.com/game/retro-bowl/user-reviews/), [Pocket Tactics](https://www.pockettactics.com/retro-bowl/review) |
| **Career history is thrown away.** *"Player career stats are only tracked as long as you coach that team."* | [Metacritic user reviews](https://www.metacritic.com/game/retro-bowl/user-reviews/) |
| **Ads / paywalled returns** in the free build (→ `01-RESEARCH §G`) | [Unlimited Version wiki](https://retro-bowl.fandom.com/wiki/Unlimited_Version) |

Note the last two carefully. **The two complaints that survive the tactility are exactly the two
this project is structurally better at**: long-horizon difficulty (AI teams that rebuild) and
persistent career history/records. Those are the seams, not the throw mechanic.

#### 2.8 **Question 1 answered: what is available without direct control?**

The brief asks what Retro Bowl's players get mechanically, and how much of it survives the removal
of direct control. Item by item:

| What the player gets | Survives without direct control? |
|---|---|
| **A closed input→outcome loop measured in seconds, ~25× per game** | **Partly.** The *frequency and latency* survive — a pre-snap call or a leverage decision can close just as fast. The *continuous-precision* part (the drag-aim throw) does not. |
| **Unambiguous attribution** — "I caused that" | **Yes, if engineered.** Attribution comes from *one visible input immediately preceding one legible outcome*, not from thumbs. It requires the outcome to name its cause. |
| **Skill expression that improves with practice** | **No, not in this form.** This is the genuinely lost thing. The substitute is *judgement* expression (reading tendencies, spending a finite resource well), which improves more slowly and is far less legible. Do not pretend otherwise. |
| **Session granularity: interruptible every few seconds; a whole game in <8 min** | **Yes.** Purely a pacing property. |
| **Progression economy: fan support → CCs → staff/facilities → morale → wins** | **Yes, entirely.** Already agency without direct control. |
| **Dilemmas / press choices before, after and between games** | **Yes, entirely.** Two-option textual choices with morale/currency/fan consequences. Cheapest agency density in the whole genre. |
| **Roster attachment via a 4-attribute + star player model** | **Yes.** Legibility is a data-model choice. |
| **Jeopardy: fan approval as a fail state** | **Yes.** → D8. |
| **Compression by deleting half the game** | **Yes — and it is a technique, not an accident.** → D3. |

**The load-bearing conclusion.** What Retro Bowl sells is not "direct control". It is a **short loop
with legible causation, repeated often, inside a single-currency progression economy.** Direct
control is one implementation of the short loop, and the one the brief removes. The three properties
that must be preserved by whatever replaces it are: **loop latency (seconds, not minutes), causal
legibility (the outcome names the input that caused it), and repetition count (tens per game, not
one or two).** If D1 produces a model where the player makes four decisions per game and watches
thirteen minutes of animation, it has kept none of the three.

**And the sting:** the one thing Retro Bowl players get that genuinely cannot be transferred is
*mechanical skill that visibly improves*. That is a real loss and the package should say so in
`PRODUCT.md` rather than claim depth substitutes for it. What replaces it must be
**improvable judgement with visible feedback** — a prediction the player makes that is later scored
(the CFB Simulator betting-line pill, `01-RESEARCH §A`, is a cheap version of exactly this).

---

### 3. Retro Bowl College — manufacturing college identity (directly load-bearing for D6)

#### 3.1 What it adds over Retro Bowl

Same engine, same controls, same off-field economy. The college layer is:

- **250 teams** across a major and a minor subdivision (FBS/FCS analogues), in conferences.
- **Recruiting** of high-school prospects on potential and fit, replacing the draft.
- **GPA management** — a second per-player resource; too low and the player is suspended.
- **14-game regular season with two bye weeks in the majors** (vs Retro Bowl's 17+1), plus **bowl
  games** and a **12-team playoff** in the major subdivision.
- **Constant roster churn** — players graduate, so the lineup turns over far faster than in the pro
  game, which is itself the source of the college feel.
- **A coaching carousel you start at the bottom of**: you do not pick your school. You take what is
  offered, coach an FCS or lower FBS job, and earn offers upward. Prestige grants automatic CCs at
  the start of each year.

([inreviewcritics — Top 5 differences](https://inreviewcritics.com/2023/10/23/top-5-biggest-differences-between-retro-bowl-college-and-retro-bowl/),
[Operation Sports — 12-team playoff update](https://www.operationsports.com/retro-bowl-college-updates-conferences-adds-12-team-playoff-and-more/),
[New Star Games](https://www.newstargames.com/retro-bowl-college),
[Retro Bowl College App Store](https://apps.apple.com/us/app/retro-bowl-college/id1632904520))

Rated **4.36★ from ~6,500 iOS ratings**. Unlimited bundle **$0.99** (uniform editing, weather,
controllable kick returns). ([App Store](https://apps.apple.com/us/app/retro-bowl-college/id1632904520))

#### 3.2 How it manufactures college identity — and why **we cannot copy it**

This is the question the brief flags as directly load-bearing for D6, and the honest answer is
uncomfortable.

**Retro Bowl College does not manufacture college identity. It gestures at the real one and hands
the player the tools to finish the job.** The documented strategy is:

1. **Real geography and real place-names as team identity.** The pro Retro Bowl strips nicknames and
   keeps cities, preserving real divisions and conferences; the college game does the analogous
   thing with school locations. A community guide states the naming is thin enough to be transparent:
   *"since this is not an NCAA endorsed product, New Star Games cannot include some bowl names and
   real school names and colors, which is why players have to make changes themselves, though some
   of the provided names are obvious as to who or what they really are. For example, the Spice Bowl
   is supposed to be the Sugar Bowl, the Party Bowl is the Fiesta Bowl, and West Point is supposed
   to be Army."*
2. **Near-miss bowl names** in place of the real ones — Spice/Sugar, Party/Fiesta, Tangerine/Orange,
   Wool/Cotton.
3. **A paid editor as the completion mechanism.** The $0.99 Unlimited tier unlocks team-name, logo,
   abbreviation, uniform, conference and bowl editing — and the community's dominant use of it is
   restoring real identities. There are published "REALISM GUIDE" videos and full colour-code lists
   for reconstructing real conferences inside the game.

([retrobowl.college teams page](https://retrobowl.college/retro-bowl-college-teams),
[inreviewcritics](https://inreviewcritics.com/2023/10/23/top-5-biggest-differences-between-retro-bowl-college-and-retro-bowl/),
["I Added The SEC To Retro Bowl College! ALL Color Codes + Team Names"](https://www.youtube.com/watch?v=mjnV5TDU-JA),
["The Official REALISM GUIDE for College Retro Bowl (2025 Edition)"](https://www.youtube.com/watch?v=feeKPLPHd0I),
[Retro Bowl Wiki — List of teams](https://retro-bowl.fandom.com/wiki/List_of_teams))

**Tier A forbids every part of this.** Near-miss bowl names, real place-names standing in for real
programmes, and a "team editor" whose community purpose is restoring real identities are precisely
the "wink in the store listing" and "workaround that reintroduces them" the legal guardrail rules
out. **Flag for counsel, do not resolve internally:** whether a user-facing team/league editor can
ship at all, given that the demonstrated community use of exactly such an editor in the closest
comparable product is trade-dress reconstruction. `01-RESEARCH §C` and §H both carry JSON league
import/export as a v1.5 feature; **that feature now needs a legal review before it is planned**, not
after. It is a strictly larger exposure than Retro Bowl College's editor because a JSON import
accepts a *file someone else made*.

**What is transferable — the parts that are actually mechanics, not trade dress:**

| Retro Bowl College device | What it actually is | Usable? |
|---|---|---|
| **You don't pick your school** — you take an offer from the bottom | Denial of the fantasy at t=0, so that reaching it is a story | **Yes, and it is the strongest single idea here.** → D8, D9 |
| **Prestige → automatic CCs each year** | Institutional standing as a *resource*, not a label | **Yes.** → D6 |
| **Graduation churn** | Roster turnover as the engine of narrative — the team is never the same team | **Yes.** This, not the logos, is what makes college feel like college |
| **GPA as a second per-player state** | A non-football constraint that creates non-football decisions | **Yes.** The generic form: *every player carries an off-field state that can take him off the field* |
| **Two subdivisions with different postseasons** | A visible ladder with a hard rung | **Yes.** → D5 |
| **Bowl games as a wide tail of small prizes** | Most seasons end in a minor reward rather than nothing | **Yes.** → D8: 130 programmes, one champion; the tail is what keeps the other 129 playing |
| **Rivalries** | Marketed as *"historic rivalries that add excitement and intensity"* — but no evidence of a mechanical effect was found | **Take the idea, not the implementation.** See below |

**The gap D6 must fill, stated precisely.** Retro Bowl College's rivalries are, on the available
evidence, **flavour attached to borrowed real-world meaning** — the rivalry matters because the
player already knows it matters. This project has no borrowed meaning and therefore **cannot use
flavour**. D6 must make rivalry *mechanically consequential and self-accumulating*: a rivalry that
starts as a schedule fact and becomes emotionally real because the save itself recorded eleven
straight losses in it, a fired coach, and a recruit stolen. Identity has to be **earned inside the
save**, because it cannot be imported into it. That is a harder problem than Retro Bowl College
solved and the package should not pretend otherwise.

#### 3.3 What its community asks for

The single most-requested feature is a **transfer portal** — *"there's no transfer portal, that
would really add some spice to the game"*; *"a full transfer portal"* would make it *"one of the
best sports games."* Second is **redshirting**. Third is **early HS scouting**. And one review is
worth quoting for D6 directly: a player asks for *"the transfer window (perhaps if players are toxic
they leave?)"* — i.e. **they want the roster churn to generate stories, not just numbers.**
([Retro Bowl College reviews](https://apps.apple.com/us/app/retro-bowl-college/id1632904520?see-all=reviews))

Also noted as missing: no field editor; balancing complaints around GPA and rankings that New Star
patched.
([Operation Sports](https://www.operationsports.com/retro-bowl-college-update-addresses-balancing-issues-with-gpa-rankings-and-more/))

#### 3.4 Throughput

**DERIVED:** 14 regular-season games + up to 4 playoff games at ≤8 min ≈ **2.0–2.4 h of match time
per college season**, slightly under the pro game. Bye weeks are dilemma-and-recruiting weeks.

---

### 4. Football Coach: College Dynasty — the closest *design*, on the wrong platform

Platform, price and control corrections are in §0. `01-RESEARCH §B` already covers the Achi Jones
lineage and the Steam pivot; this extends it.

#### 4.1 The loop

Play as a coach (career across schools) or a school (franchise). Weekly, in-season, the game gives
you a **weekly dashboard** listing everything you owe it and **warning you before you advance if you
skipped something**. In-season the week is: **set depth chart → manage practices → establish
gameplan → play/sim the game**. Out of season it is recruiting HS and JUCO players (assigning
pitches, scheduling visits), transfer portal, development, and a coach skill/badge tree. Leagues are
customisable up to 90 teams with configurable conference and playoff formats, injury/transfer/draft
rules and NIL.
([Steam](https://store.steampowered.com/app/2151290/Football_Coach_College_Dynasty/),
[gmgames.org](https://gmgames.org/football-coach-college-dynasty/),
[Operation Sports review](https://www.operationsports.com/football-coach-college-dynasty-review-a-sports-sim-with-training-wheels-for-better-and-worse/))

The weekly dashboard with a pre-advance completeness check is a **directly copyable UX pattern** and
is the cleanest answer found anywhere to "what does the player do between games, and how do they
know they're done."

#### 4.2 How it solves the agency/throughput problem — the key finding

FC:CD does not choose a point on the §4 axis. **It gives the player the dial.**

> *"While watching games you can progress each play one by one, or turn on 'auto-sim' to watch plays
> progress automatically."* — and this applies to CPU-vs-CPU games too.
> ([Steam discussion](https://steamcommunity.com/app/2151290/discussions/0/3826425639848612057/))

Combined with: you may call all 100+ offensive and defensive plays yourself, **or** let the
coordinator AI call them, and *"the offense and defense levels represent how well plays are
executed, and apply when calling plays yourself as well as when simming through games"* — i.e. your
staff's rating is a **multiplier on execution regardless of who calls the play**, so delegating is
not punished by a hidden penalty.
([Steam discussion](https://steamcommunity.com/app/2151290/discussions/0/3826425639848612057/),
[Steam](https://store.steampowered.com/app/2151290/Football_Coach_College_Dynasty/))

Three properties, and all three matter for D1:

1. **Attention is player-paced at snap granularity.** Not "sim this game" / "play this game", but
   "advance this play" — you can lean in for a red-zone series and hold the auto-sim through a
   28-point blowout, without leaving the game.
2. **Delegation is rating-neutral.** The same execution model resolves player-called and AI-called
   plays. This is the structural fix for the CFB Simulator bug in `01-RESEARCH §H` rank 3, where
   watched and simmed games diverged and the community meta became *"watch games to get good
   results."* **State it as a hard invariant, not a hope.**
3. **The season still closes fast.** *"You can sim through a season in less than an hour or over the
   course of a whole week depending on your playstyle."*
   ([gmgames.org](https://gmgames.org/football-coach-college-dynasty/))

**And now the term §4 says is most often omitted.** FC:CD can afford *every-snap play-calling* — the
most decision-dense option on the §4 list — inside a one-hour season, because its **presentation
time per snap is effectively zero**: the snap is a line of text, tagged *Text-Based* on Steam, and
the player advances it at their own speed.
([Steambase](https://steambase.io/games/football-coach-college-dynasty/steam-charts))

**This project's 2D Canvas view reintroduces exactly the term FC:CD deleted.** That is the real cost
of P1's match view, and §4's arithmetic must price it honestly:

```
FC:CD                 : decision-dense, presentation ≈ 0  → every-snap agency fits in <1 h/season
This project (naive)  : decision-sparse, presentation ≈ 6 s/snap × 130 → 13 min/game watching alone
```

**DERIVED design consequence:** the animation must be **interruptible and player-advanced at snap
granularity**, not a fixed-duration cutscene with a game-level skip. The unit of "skip" has to be
the snap. If a snap's animation cannot be cut short the instant the player has seen what they need,
the presentation term is not controllable and P4 is at risk under every D1 option.

#### 4.3 Match presentation

Text play-by-play. Steam tags it **Text-Based**; `gmgames.org` calls it *"a text based college
football simulator"* and warns *"the presentation is pretty barebones."* No field render, no play
diagram found in any source.
([Steambase](https://steambase.io/games/football-coach-college-dynasty/steam-charts),
[gmgames.org](https://gmgames.org/football-coach-college-dynasty/))

That the genre's best-reviewed modern entry is text-only, and still scores 95–96 % positive, is
evidence that **presentation is not what makes these games good** — but also that a 2D view is a
real, unoccupied differentiator on mobile, where the same source says *"if you need visuals or want
something you can play on your phone, this isn't it."*

#### 4.4 What its community complains about — the most valuable signal in this document

Overall: **95 % positive of 1,474 reviews** (96 % of 1,262 in an earlier snapshot). So these are
complaints from people who *like* it, which is the useful kind.

1. **"A recruiting simulator, not a coaching simulator."** The dominant negative theme. Reviewers
   say the game is *"too thin"*, that it is *"more of a scouting game than a football coach/dynasty
   game"*, and that after several seasons of recruiting it *"felt hollow"* and gets boring *"unless
   you're into scouting players over and over with no real variation."* One summary: the management
   side has *"little of the specific elements like trades or draft, with very limited scouting,"*
   with players building *"90 % of their roster through recruiting and 10 % from the transfer
   portal."*
   ([Steam negative reviews](https://steamcommunity.com/app/2151290/negativereviews/?browsefilter=toprated),
   [Steam discussions](https://steamcommunity.com/app/2151290/discussions/0/4205868123787946936))
2. **Decisions that don't visibly matter.** *"Decisions in the game are pretty limited, and outcomes
   of choices don't appear to matter"* — no play editor, no formation editor, limited substitution
   settings. Facility upgrades are *"lazily made as just a linear 'level 4 to level 5' upgrade."*
3. **AI clock management.** Operation Sports' review names this as the biggest issue: the AI suggests
   *"punting in situations that would have killed off any chances in the game"*, and *"mismanaging a
   few games a year where a 2 %-chance of a win gets forfeited is indicative of a play calling AI
   that is not quite as dialed in as it could be."*
   ([Operation Sports](https://www.operationsports.com/football-coach-college-dynasty-review-a-sports-sim-with-training-wheels-for-better-and-worse/))
4. **Perceived rubber-banding.** Players report *"some hard anti-upset logic happening behind the
   scenes"* — as a small school you gameplan well and lead, then *"the simmed defense gives up large
   yards, or they fumble, seemingly designed to make them lose."*
   ([Steam discussions](https://steamcommunity.com/app/2151290/discussions/0/4205868123787946936))
5. **Linearity.** *"There is enough content to keep playing for decades in-game with this, although
   it is quite linear and very little else to do."*

**Praise:** *"easy to learn and makes you feel like you are actually coaching"*; the recruiting,
transfer portal and NIL detail; custom leagues; mod support and a responsive developer; the coach
levelling/badge RPG layer; and *"the simulation engine behind them feels like your decisions
actually matter"*.
([gmgames.org user reviews](https://gmgames.org/football-coach-college-dynasty/user-reviews/),
[Steam top-rated reviews](https://steamcommunity.com/app/2151290/reviews/?browsefilter=toprated),
[Metacritic](https://www.metacritic.com/game/football-coach-college-dynasty/))

**And the demand this project exists to serve, from FC:CD's own audience:** players ask for a pro
version, saying the developer *"could dominate the genre as there's no other solid modern NFL front
office sims."* SidelineSim's answer is Pro Football Dynasty — Windows, no release date as of August
2026. ([Steam discussions](https://steamcommunity.com/app/2151290/discussions/0/4205868123787946936),
[Steam — Pro Football Dynasty](https://store.steampowered.com/app/4769350/Pro_Football_Dynasty/))

---

### 5. The rest of the mobile-native field

#### 5.1 Football Coach: Winning Tradition — On Paper Sports (the discovery)

**The closest existing product to P2 that actually ships on a phone.** iOS + Android, free to
download, App Store id `6743344615` (listed variously as *Winning Tradition: Football*, *Winning
Tradition: Football GM* and *Football Coach: Tradition* — the developer has renamed it more than
once). Rated ~4.5–4.6★ on 25–53 ratings depending on storefront and snapshot: **new and small.**

What it ships:

- **A 32-team pro franchise mode and a 70+ team college dynasty mode with a 12-team playoff, in one
  app** — and *"the two are connected. You can import/export draft classes from College Mode into
  Pro Mode and continue the journey of your favorite players."*
- Coaching philosophy (offensive/defensive), coach perks and abilities, contract goals, coordinator
  hiring/firing, multi-week free agency, salary cap, full scouting and dynamic draft classes,
  **player morale including scheduling phone calls with unhappy players**.
- Monetisation: free base (pro mode); **College Mode and a Creation Suite are separate IAPs**.
- Cloud saves and account login.

([On Paper Sports](https://www.onpapersports.com/winning-tradition-football),
[gmgames.org](https://gmgames.org/winning-tradition-football/),
[App Store](https://apps.apple.com/us/app/winning-tradition-football/id6743344615),
[Play Store](https://play.google.com/store/apps/details?id=com.onpapersports.WinningTraditionFootball),
[Operation Sports forums — release thread](https://forums.operationsports.com/forums/forum/football/other-football-games/26874046-winning-tradition-football-released-today))

**What this changes.** `01-RESEARCH §E` and §H concluded the pro-on-mobile lane was empty and the
college→pro connection unserved. **§E's claim needs amending, not deleting.** The lane now has an
incumbent, but a weak one, and the differences are the positioning:

| Dimension | Winning Tradition | This project |
|---|---|---|
| College→pro | **Import/export of draft classes between two separate modes** | **One save, one coach, a promotion arc** (P2) |
| Match view | No field render found | 2D Canvas |
| Business model | Free + IAP gates on College Mode | Paid premium, no IAP (P3) |
| Network | Cloud save + account login; a review reports *"couldn't login and the app kept timing out with Apple login"* | **Offline, no accounts, no network at all** (Tier A) |
| Maturity | 25–53 ratings | — |

Complaints found (thin corpus): login/timeout failures; one reviewer says it offers *"an almost
identical experience to a previous version, with only a few UI additions like sliding cards for
stats and schedules that need refining"* (the developer's prior title is **On Paper Sports Football
'24**); requests for deeper team stats and richer player cards including awards, trophies and HS
stats for recruits. Recent patch notes fix recruiting classes generating no kickers or punters,
missing coach faces, a coaching-screen crash, and cloud-save upload failures.
([App Store reviews](https://apps.apple.com/us/app/winning-tradition-football/id6743344615),
[Play Store — OPS Football '24](https://play.google.com/store/apps/details?id=com.cbanfiel.OnPaperSportsFootball24))

**Do not read the low rating count as a dead lane.** Read it as: the product exists, it is young, and
it is authored by a developer already iterating annually. **It is the competitor most likely to
occupy this project's exact position before this project ships**, and `PRODUCT.md` §6.3 must argue
against it specifically rather than against a vacuum.

#### 5.2 Pocket GM 3: Football Sim

iOS, free with IAP, 4.9★ / 50 K+ downloads. Pure GM: draft, trades, free agency, roster
development, hiring coaches/scouts/physios, difficulty and reputation levels, and randomly generated
rosters as an option. Marketing promises you *"watch each football game play out with amazing
play-by-play detail and track momentum shifts."*
([App Store](https://apps.apple.com/us/app/pocket-gm-3-football-sim/id1645791169),
[gmgames.org](https://gmgames.org/pocket-gm-3-football/),
[TapTap](https://www.taptap.io/app/260894))

The review corpus is the useful part, because **Pocket GM 3 is what this project becomes if D1 goes
to pure spectate and D10 is under-resourced.** Users praise the GM layer — *"the trading, free agency
and general GM aspect is really good"* — and then:

- *"the simming of the games and watching them is awful"*
- *"multiple automatic first down penalties called every single drive whether it's defensive
  holding, roughing the passer, unnecessary roughness, etc to the point it's actually just annoying
  to watch"* — **a calibration failure that reads as a presentation failure** (→ §6.4)
- *"the decision making makes absolutely no sense"* — down 10 with 4 minutes left and punting; 4th
  and 17 in field-goal range and going for it
- *"boring that they only see texts and graphs, but won't be able to see action in scenes on the
  football field"*

The developer's response was a beta with **a rewritten game engine** to fix bugs and AI decisions.
([App Store reviews](https://apps.apple.com/us/app/pocket-gm-3-football-sim/id1645791169?see-all=reviews&platform=iphone))

`01-RESEARCH §H` records Pocket GM 3 as the community's cited pro benchmark. **It is the benchmark
for the GM layer and the anti-benchmark for the match layer.** That split is the market gap in one
product.

#### 5.3 Ultimate Pro Football GM / ULT College Football Coach (gmz2rk)

The largest review corpus in the mobile set: **Ultimate Pro Football GM, 4.0★ from ~22 K reviews**,
iOS + Android, free and offline. Sign/draft/trade, hire coaches and staff, upgrade facilities,
manage club operations; formation selection (Shotgun, I-Formation) with run/pass options; and a
**coach mode with offensive play calls during games.** The sibling **ULT College Football Coach**
adds *"real-time play calling that lets you influence each game as the action unfolds"* plus custom
play creation and playbook management.
([App Store](https://apps.apple.com/us/app/ultimate-pro-football-gm/id1530542938),
[Play Store — UFGM](https://play.google.com/store/apps/details?id=com.gmz2rk.ufgm&hl=en_US),
[Play Store — UCFC](https://play.google.com/store/apps/details?id=com.gmz2rk.ucfc&hl=en_US),
[gmgames.org](https://gmgames.org/ultimate-football-gm/))

Complaints, and all three are directly actionable:

1. **Monetisation resentment dominates.** *"aggressive pay-to-win mechanics"*; *"cash grab"* where
   *"the game will do anything to have you spend $5.99 on a purchase"*; *"you have to pay for
   everything"* and facility upgrades are costly. A 4.0★ average on 22 K reviews for a game people
   call *"the best football mobile game on the market"* is monetisation dragging a good game down.
   **This is the strongest available evidence for P3's no-IAP stance being a genuine differentiator
   rather than a self-imposed handicap.**
2. **Perceived randomness destroys trust.** *"Everything is completely random. You try to make
   educated football decisions, but then the opponent converts a 3rd and 40."*
3. **Perceived AI sabotage.** *"the game really does everything to work against you"*; *"you can have
   a pretty stacked team, and no matter which difficulty, your ai players will still find a way to
   screw the season up."*

(2) and (3) are the same complaint as FC:CD's "anti-upset logic" and Pocket GM 3's "decision making
makes no sense". **Across four independent products, the #1 failure mode of a no-direct-control
football game is that the player stops believing the simulation.** → §6.

#### 5.4 The Program: College Football (Fantasy Moguls)

iOS + Android, free, launched 26 September 2022. Recruiting-first: travel to scout, compete for
recruits, hire coordinators, manage boosters, run press conferences to build prestige. Widely
credited with doing *"the recruiting loop better than most games in this space."*
([Play Store](https://play.google.com/store/apps/details?id=com.atomic.collegefootball&hl=en_US),
[Game Solver](https://game-solver.com/the-program-college-football/),
[gmgames.org](https://gmgames.org/section/american-football-nfl-college-manager-simulator-games/))

And then, the cleanest statement in this whole research of what pure spectate costs:

> *"Where it gets frustrating is the simulation itself — you don't have much control over what
> happens on the field beyond setting a game plan and hoping for the best."*

**This is the D1 "pure spectate with weekly adjustment only" option, shipped, on mobile, in the exact
genre — and this is what its reviewers say about it.** Treat it as the disconfirming evidence for the
lowest-agency option on the §4 list.

#### 5.5 Adjacent, for completeness

- **CFB Simulator** (Mani Foroughi) — the reference app. Already fully catalogued in
  `01-RESEARCH §A` and §H. Relevant here only as the one mobile title that *does* ship a 2D field
  view with a play log, sim-speed tiers and defensive-set selection, and whose top complaint class
  is stability and save corruption rather than agency.
- **EA Sports College Football 27 Mobile** — free-to-play College Ultimate Team card collector with
  NIL-signed real players, ~40 GB install. Not a management sim and not a competitor on mechanics,
  but it is EA marketing spend aimed at "college football on your phone", and it is the licensed
  answer to the identity problem D6 has to solve without a licence.
  ([EA](https://www.ea.com/games/ea-sports-college-football/college-football-mobile/news/cfb-27-mobile-available-now))
- **Progression Football**, **RedZoneAction.org**, **Gridiron Dynasty** (WhatIfSports) — browser/PC
  GM sims surfaced during the sweep; noted so a later reader knows they were seen and set aside as
  not mobile-native.
  ([gmgames.org](https://gmgames.org/section/american-football-nfl-college-manager-simulator-games/),
  [WhatIfSports](https://www.whatifsports.com/gd/))
- **Legacy Achi Jones mobile titles** — `College Football Coach` (iOS, id `1095701497`), `College
  Football Coach: Career Edition` (Android, antdroid fork, 2018). Already in `01-RESEARCH §B`. Still
  listed, still described as *"stripped-down"*: pick a school, set a playbook, recruit between
  seasons, chase a title. They are the mobile ancestors of FC:CD and remain the only prior art for
  what FC:CD would be on a phone.
  ([App Store](https://apps.apple.com/us/app/college-football-coach/id1095701497),
  [gmgames.org](https://gmgames.org/college-football-coach-career-edition/),
  [On Paper Sports blog](https://www.onpapersports.com/blog/best-college-football-management-games))

---

### 6. Cross-title patterns — the findings that should change a decision

**P1 — Watched-without-input possessions are the universally disliked part, even inside beloved
games.** Retro Bowl's defensive text boxes are named as a flaw by critics who score it 84. Pocket GM
3's users call the watching *"awful"* and *"boring … only texts and graphs"*. The Program's reviewers
name *"setting a game plan and hoping for the best"* as the frustration. **No product in this set is
praised for the parts the player watches.** This is a much stronger claim than "Retro Bowl players
like control", and it applies directly to D1 and to the 2D match view's justification: a watched
snap has to *pay for its own seconds*, either by carrying a decision or by carrying information the
player could not get from the box score.

**P2 — AI decision quality is the #1 credibility failure in this genre, in four independent
products.** FC:CD (punt at 2 % win probability; perceived anti-upset logic), Pocket GM 3 (punting
down 10 with 4 minutes; going for it on 4th-and-17 in FG range), Ultimate Pro Football GM (*"3rd and
40"*, *"your ai players will still find a way to screw the season up"*), CFB Simulator (`01-RESEARCH
§H` rank 3 and 9). **D10's premise is confirmed, and the specific failure is nameable: fourth-down,
timeout and end-of-half expected-value decisions.** Those are cheap to get right with an EV table and
catastrophic to get wrong, because a single visibly stupid punt retroactively discredits every
outcome the engine has produced. Instrument it: assert AI 4th-down/timeout choices against a
win-probability-optimal baseline within a stated tolerance, as a test, not a review item.

**P3 — Player-paced advance at snap granularity is the throughput mechanism that works.** FC:CD's
play-by-play advance with an auto-sim toggle lets one product serve both the every-snap player and
the one-hour-season player without a mode switch. Retro Bowl's per-game simulate option is the
coarse version and is a strictly worse instrument, because the unit of skipping is the whole game.
**The §4 arithmetic should treat presentation time as a player-controlled variable, not a constant** —
and P1 (SwiftUI `Canvas`) must be built so a snap's animation can be cut the instant the player has
seen enough.

**P4 — Delegation must be rating-neutral, and this is testable.** FC:CD states that offence/defence
execution levels apply identically whether you call plays or sim. CFB Simulator failed at exactly
this and its community's meta became *"watch games to get good results"* (`01-RESEARCH §H` rank 3).
This becomes a named invariant and a named test: **the distribution of outcomes for a given state
must be statistically indistinguishable between player-called and AI-called plays.** It also
constrains D3: the abstracted off-screen model and the detailed model must agree, and this is the
same test.

**P5 — Recruiting-only depth goes hollow, on a measurable horizon.** FC:CD's own fans say the game
becomes *"a recruiting simulator, not a coaching simulator"* and feels *"hollow"* after several
seasons. Retro Bowl's users say scenarios *"repeat themselves after a while"*. Both are the same
structural fault: **the acquisition loop is deep and the everything-else loop is shallow, so once
acquisition is mastered there is nothing left.** Since P2 makes recruiting *and* the draft *and* free
agency all v1 features, this project is at above-average risk of it. → D8: the thing that has to
deepen over seasons is *jeopardy and consequence*, not acquisition.

**P6 — Identity is manufactured, in every competitor, by borrowing meaning the player already has.**
Retro Bowl College's near-miss bowl names plus a paid editor; NFL Retro Bowl's outright licence; EA's
NIL deals; CFB Simulator's real cities with invented mascots (`01-RESEARCH §A`). **This project is
the only entrant that must generate meaning endogenously**, and no competitor has solved that
problem for it to copy. D6 is therefore genuine original design work with no reference
implementation — budget it accordingly in D13.

**P7 — Monetisation resentment is a first-class quality signal.** Ultimate Pro Football GM sits at
4.0★ on 22 K reviews with users calling it *"the best football mobile game on the market"* and *"a
cash grab"* in the same corpus. Retro Bowl's ads are a named complaint; Retro Bowl+ on Apple Arcade
removes them. `01-RESEARCH §H` records CFB Simulator selling **paid checkpoint tokens as crash
insurance**. **P3's paid-premium, no-IAP, no-ads stance is defensible as a feature and should be
stated as one in the store listing**, in the same breath as "no accounts, works on a plane."

**P8 — The budget reframe.** Retro Bowl delivers a complete, input-dense season in ~3 hours (§2.5).
FC:CD delivers one in *under one hour* with every-snap play-calling. **P4's 6–8 hours is not a tight
budget; it is roughly 2–6× what the two most successful products in this space spend.** The failure
mode to design against is not overrunning P4 — it is *spending* P4 on low-density minutes because
the budget permitted it. **Recommend §4 treat 6–8 h as a ceiling and adopt an explicit density
target instead** (e.g. meaningful decisions per hour), because a per-hour density floor is a
falsifiable instrument and a per-season ceiling is not.

---

### 7. Direct inputs to the decision register

| Decision | What this part contributes |
|---|---|
| **D1 — agency model** | Retro Bowl's transferable core is loop latency + causal legibility + repetition count, not control (§2.8). FC:CD proves every-snap play-calling is affordable *when presentation ≈ 0* (§4.2). The Program shows pure spectate is the one option with shipped disconfirming evidence (§5.4). **Recommendation: player-paced snap advance with a rating-neutral delegation toggle, as the mechanism, whatever the decision surface turns out to be.** |
| **D2 — match engine** | Every competitor's match layer is its weakest-reviewed component, and the complaints are *calibration and AI* complaints (penalties every drive, 3rd-and-40, stupid punts), not fidelity complaints. Argues for a model whose outputs are directly calibratable against bands over one whose emergent behaviour is hoped to be right. |
| **D3 — two-tier sim** | P4 above makes the consistency requirement the *same test* as the delegation-neutrality test. Retro Bowl's asymmetric fidelity (§2.4) is the precedent for spending fidelity unevenly on purpose. |
| **D4 — performance budgets** | §2.5 and §4.2 give real competitor numbers: ≤8 min/game arcade; <1 h/season text sim; 14–18 game seasons. Use them as the outer envelope. |
| **D5 — college/pro** | Winning Tradition already ships both leagues on iOS but connects them by draft-class import/export, not a career (§5.1). The unified *career* is the differentiator; say so precisely. |
| **D6 — fictional identity** | §3.2 is the core input. The only working competitor strategy is borrowing, and Tier A forbids it. Transferable mechanics: you-don't-pick-your-school, prestige-as-resource, graduation churn, an off-field per-player state, a two-subdivision ladder, a wide tail of small postseason prizes. **Rivalry must be mechanically consequential and self-accumulating, because it cannot be imported.** **Escalate to counsel:** whether a team/league editor or JSON import can ship at all, given the documented community use of exactly that feature in Retro Bowl College. |
| **D8 — jeopardy** | Retro Bowl's fan-support → currency → everything economy (§2.3) is the cleanest single-loop jeopardy design in the set. Retro Bowl College's "you do not pick your school" is the strongest opening-jeopardy device found. P5 says the thing that must deepen across seasons is consequence, not acquisition. |
| **D9 — onboarding** | FC:CD's weekly dashboard with a pre-advance completeness check (§4.1) is the best "what do I owe the game this week" pattern found and is directly copyable. |
| **D10 — AI quality** | §6/P2 confirms the brief's suspicion with four independent products. Specify the instrument: EV-optimal 4th-down/timeout/end-of-half baselines with a stated tolerance, asserted in tests. |
| **D13 — content volume** | No competitor has solved endogenous identity, so there is no shortcut to copy. Retro Bowl College needs 250 teams; FC:CD supports up to 90; the brief's college tier is ~134. Budget authoring against the fact that D6 is original work. |
| **P3 / `PRODUCT.md`** | §6/P7: offline, no accounts, no ads, no IAP is a *differentiator* against a field where the biggest mobile entrants are ad-supported, IAP-gated, or login-gated (§5.1, §5.3, §2.6). |
| **P4** | §6/P8: treat 6–8 h as a ceiling; adopt a decisions-per-hour density floor as the falsifiable instrument. |

---

### 8. Assumptions and unsourced items

Collected so the owner can see what the design rests on.

- **DERIVED — Retro Bowl season time ≈ 2.6–3.7 h.** Arithmetic from sourced ≤8 min/game, 17+1 week
  season, 14-team playoff. Management time per week is my estimate, not sourced.
- **DERIVED — Retro Bowl offensive snaps per game ≈ 20–30.** Inferred from game length, quarter
  length and offence-only play. No source states a snap count. Lower confidence than the time figure.
- **DERIVED — Retro Bowl College season time ≈ 2.0–2.4 h.** From the sourced 14-game season plus
  playoff/bowls at the same per-game length.
- **DERIVED — "the animation must be cuttable at snap granularity."** This is my inference from
  FC:CD's play-paced advance plus §4's presentation-time term. No source states it.
- **ASSUMPTION — Retro Bowl College's rivalries have no mechanical effect.** Store and press copy
  describe them as *"historic rivalries that add excitement and intensity"*; **no source found
  describes a mechanical consequence**, but absence of evidence in marketing copy is weak evidence.
  If D6 leans on this claim, verify it by playing the game.
- **ASSUMPTION — Winning Tradition has no 2D field view.** No screenshot description or review in
  any surfaced source mentions one, and the developer's copy is entirely management-oriented.
  Unconfirmed; the App Store screenshots would settle it and could not be fetched.
- **UNRESOLVED — Retro Bowl's "Auto Play" option.** Multiple third-party guides reference an
  autoplay toggle in settings; the Fandom Options page content surfaced did not confirm what it
  does, and one source expresses doubt it exists in the base game. **Do not cite it.** Per-game
  simulate from the schedule screen *is* confirmed.
- **UNRESOLVED — Winning Tradition rating counts.** Two snapshots surfaced (4.6★/25 and 4.5★/53),
  presumably different storefronts or dates. Treat as "small and growing", not as a precise figure.
- **NOT RETRIEVED — Reddit.** r/RetroBowl and r/FootballCoach were both named in the brief and
  neither is reachable from this environment. The community signal above is from stores, Metacritic,
  Steam, Operation Sports and enthusiast press instead. A session with Reddit access should re-run
  this specific query; it is the one gap in the evidence base that is worth closing.
- **NOT RETRIEVED — FC:CD median hours played.** `byhoursplayed.com` and `gamalytic.com` both index
  it and would give a real throughput distribution rather than the developer's "<1 hour or a whole
  week" range. Both were surfaced but not readable.

---

### 9. Sources

All URLs below are real pages surfaced by search. Per §0, none was fetched in full.

**Retro Bowl**
- https://en.wikipedia.org/wiki/Retro_Bowl
- https://grokipedia.com/page/Retro_Bowl
- https://grokipedia.com/page/New_Star_Games
- https://handwiki.org/wiki/Software:Retro_Bowl
- https://retro-bowl.fandom.com/wiki/Gameplay
- https://retro-bowl.fandom.com/wiki/Quarters
- https://retro-bowl.fandom.com/wiki/Options
- https://retro-bowl.fandom.com/wiki/Schedule
- https://retro-bowl.fandom.com/wiki/Playoff
- https://retro-bowl.fandom.com/wiki/Coaching_Credits
- https://retro-bowl.fandom.com/wiki/Dilemmas
- https://retro-bowl.fandom.com/wiki/Staff_Hires
- https://retro-bowl.fandom.com/wiki/Front_Office
- https://retro-bowl.fandom.com/wiki/Unlimited_Version
- https://retro-bowl.fandom.com/wiki/Exhibition_Game
- https://retro-bowl.fandom.com/wiki/List_of_teams
- https://www.metacritic.com/game/retro-bowl/
- https://www.metacritic.com/game/retro-bowl/user-reviews/
- https://www.nintendolife.com/reviews/switch-eshop/retro-bowl
- https://purenintendo.com/review-retro-bowl-nintendo-switch/
- https://www.pockettactics.com/retro-bowl/review
- https://www.pocketgamer.com/retro-bowl/review/
- https://www.operationsports.com/retro-bowl-review-a-mobile-game-that-transcends-the-platform/
- https://robwritesaboutwhatever.com/2021/04/27/robs-complete-guide-to-retro-bowl-winning-football-games/
- https://robwritesaboutwhatever.com/2021/04/15/robs-complete-guide-to-retro-bowl-part-1-how-to-build-a-winning-front-office/
- https://www.playbite.com/q/how-to-change-plays-in-retro-bowl
- https://www.playbite.com/q/how-to-sim-retro-bowl-season
- https://www.appbrain.com/app/retro-bowl/com.newstargames.retrobowl
- https://apprank.io/retro-bowl
- https://apps.apple.com/us/app/retro-bowl/id1478902583
- https://apps.apple.com/us/app/retro-bowl/id6446029554

**NFL Retro Bowl (licensed, Apple Arcade)**
- https://www.apple.com/newsroom/2025/08/apple-arcade-exclusive-nfl-retro-bowl-26-launching-september-4/
- https://www.apple.com/newsroom/2024/08/apple-arcade-launches-three-new-games-in-september-including-nfl-retro-bowl-25/
- https://www.cultofmac.com/news/apple-arcade-adds-nfl-retro-bowl-26
- https://www.operationsports.com/games/nfl-retro-bowl-26/
- https://www.operationsports.com/new-star-games-releases-updates-for-all-three-retro-bowl-games

**Retro Bowl College**
- https://www.newstargames.com/retro-bowl-college
- https://apps.apple.com/us/app/retro-bowl-college/id1632904520
- https://apps.apple.com/us/app/retro-bowl-college/id1632904520?see-all=reviews
- https://play.google.com/store/apps/details?id=com.newstargames.retrobowlcollege
- https://www.operationsports.com/retro-bowl-college-updates-conferences-adds-12-team-playoff-and-more/
- https://www.operationsports.com/retro-bowl-college-update-addresses-balancing-issues-with-gpa-rankings-and-more/
- https://inreviewcritics.com/2023/10/23/top-5-biggest-differences-between-retro-bowl-college-and-retro-bowl/
- https://retrobowl.college/retro-bowl-college-teams
- https://www.youtube.com/watch?v=mjnV5TDU-JA
- https://www.youtube.com/watch?v=feeKPLPHd0I

**Football Coach: College Dynasty / SidelineSim**
- https://store.steampowered.com/app/2151290/Football_Coach_College_Dynasty/
- https://steamcommunity.com/app/2151290
- https://steamcommunity.com/app/2151290/reviews/?browsefilter=toprated
- https://steamcommunity.com/app/2151290/negativereviews/?browsefilter=toprated
- https://steamcommunity.com/app/2151290/discussions/0/594013679434942086/
- https://steamcommunity.com/app/2151290/discussions/0/3826425639848612057/
- https://steamcommunity.com/app/2151290/discussions/0/4205868123787946936
- https://steamcommunity.com/sharedfiles/filedetails/?id=3431824694
- https://steamcommunity.com/sharedfiles/filedetails/?id=3386721954
- https://www.operationsports.com/football-coach-college-dynasty-review-a-sports-sim-with-training-wheels-for-better-and-worse/
- https://gmgames.org/football-coach-college-dynasty/
- https://gmgames.org/football-coach-college-dynasty/user-reviews/
- https://www.metacritic.com/game/football-coach-college-dynasty/
- https://steambase.io/games/football-coach-college-dynasty/steam-charts
- https://gamalytic.com/game/2151290
- https://www.byhoursplayed.com/game.php?siteid=2151290
- https://store.steampowered.com/app/4769350/Pro_Football_Dynasty/
- https://www.operationsports.com/pro-football-dynasty-coming-soon-to-steam/

**Football Coach: Winning Tradition / On Paper Sports**
- https://www.onpapersports.com/
- https://www.onpapersports.com/winning-tradition-football
- https://www.onpapersports.com/blog/best-college-football-management-games
- https://www.onpapersports.com/blog/best-football-management-games
- https://apps.apple.com/us/app/winning-tradition-football/id6743344615
- https://play.google.com/store/apps/details?id=com.onpapersports.WinningTraditionFootball
- https://play.google.com/store/apps/details?id=com.cbanfiel.OnPaperSportsFootball24
- https://gmgames.org/winning-tradition-football/
- https://forums.operationsports.com/forums/forum/football/other-football-games/26874046-winning-tradition-football-released-today

**Other mobile-native titles**
- https://apps.apple.com/us/app/pocket-gm-3-football-sim/id1645791169
- https://apps.apple.com/us/app/pocket-gm-3-football-sim/id1645791169?see-all=reviews&platform=iphone
- https://gmgames.org/pocket-gm-3-football/
- https://www.taptap.io/app/260894
- https://apps.apple.com/us/app/ultimate-pro-football-gm/id1530542938
- https://play.google.com/store/apps/details?id=com.gmz2rk.ufgm&hl=en_US
- https://play.google.com/store/apps/details?id=com.gmz2rk.ucfc&hl=en_US
- https://apps.apple.com/us/app/ult-college-football-coach/id6532596535
- https://gmgames.org/ultimate-football-gm/
- https://play.google.com/store/apps/details?id=com.atomic.collegefootball&hl=en_US
- https://game-solver.com/the-program-college-football/
- https://apps.apple.com/us/app/college-football-coach/id1095701497
- https://gmgames.org/college-football-coach-career-edition/
- https://play.google.com/store/apps/details?id=antdroid.cfbcoach&hl=en_US
- https://www.ea.com/games/ea-sports-college-football/college-football-mobile/news/cfb-27-mobile-available-now
- https://www.ea.com/games/ea-sports-college-football/college-football-mobile

**Genre directories**
- https://gmgames.org/section/american-football-nfl-college-manager-simulator-games/
- https://gmgames.org/section/iphone/
- https://gmgames.org/top/
- https://www.whatifsports.com/gd/

---

## §6.3 — The market gap, argued as an output

**Governing brief:** `docs/reviews/2026-08-09-spec-prompt-v4.md` §6.3.
**Inputs:** `§6.0`, `§6.1`, `§6.2A`,
`§6.2B`, `§6.5`, `docs/01-RESEARCH.md` §C, §E, §H.
**Feeds:** `PRODUCT.md` §6.3, D1, D6, D8, D10, D13, and the P2 escalation in `docs/OPEN-DECISIONS.md`.

**Verdict in one paragraph, before the argument.** There is a real gap and it is **not the gap the
project has been assuming**. It is not a category gap — every category slot in this market is
occupied, including the one P2 describes, and one of the occupants shipped on iOS while this
research was being written. It is a **quality gap at an intersection**: nobody has shipped a
football management sim on a phone that the player can still believe in after twenty seasons.
That gap is real, it is well-evidenced, and it is worth building for. It is also the hardest kind of
gap for a solo developer to fill, because every part of it is invisible in a screenshot.

---

### 0. Method, and the grade of this argument

This document contains **no new research**. It is an argument assembled from §6.0–6.2 and
§6.5, and it inherits their evidence grades. Three inherited limits govern how hard any claim below
can be pushed:

1. **The competitive evidence reached its authors through a search-summarisation layer, not through
   fetched pages.** `§6.2A §0.1` records `EGRESS_BLOCKED` for Steam, Wolverine, Operation Sports,
   gmgames, Metacritic and Wikipedia; Reddit is refused by the tool. Every `[Q]` quotation in
   §6.2a/§6.2b must be re-verified on an unrestricted machine before it appears in a store listing.
2. **The sample sizes on the deep-sim pole are tiny** — DDS:PF 2025 shows 13 Steam reviews
   (`§6.2A §0.2`). No "the community thinks X" claim is defensible inside a single SKU at that size;
   the frequency claims below rank by **recurrence across titles**, per `§6.2A §0.2`.
3. **Nobody has played the build that exists.** `§6.0 §0` establishes there is no Swift toolchain in
   this container, so the engagement post-mortem is a source census, not a play impression. The
   owner-verifiable half is `§6.0 §8`.

Where this document reasons past its sources it says **DERIVED**. Where it cannot source a claim at
all it says **ASSUMPTION**, and §9 collects them.

---

### 1. The market map: every slot is occupied

The habitual framing in `01-RESEARCH.md` §E is *"modern iOS has no pro football management sim — the
lane is empty."* That was true when it was written and it is **no longer true**. Here is the map as
§6.2 leaves it.

| Slot | Occupied by | Platform | Quality of occupation |
|---|---|---|---|
| Arcade football, mobile | **Retro Bowl** — 40 M+ downloads, ~$2.4 M/yr | iOS/Android/Switch/web | Dominant. Metascore 84. Free+ads, $0.99 unlock |
| Arcade college football | **Retro Bowl College** — 4.36★ / ~6.5 K iOS ratings | iOS/Android/web | Solid |
| Licensed arcade | **NFL Retro Bowl '26** — full NFL/NFLPA licence | Apple Arcade only | Closed to us by definition |
| Deep pro sim | **DDS:PF**, **Front Office Football** | Windows | Occupied but decaying: FOF Eight 275 lifetime Steam reviews, FOF Nine 165 |
| Deep college sim | **DDS:CFB**, **Football Coach: College Dynasty** | Windows | FC:CD 95–96 % positive of ~1,474 reviews — the healthiest product in the deep pole |
| Pro GM sim, mobile | **Pocket GM 3** (4.9★, 50 K+ downloads); **Ultimate Pro Football GM** (4.0★, ~22 K reviews) | iOS/Android | Occupied, free+IAP, match layer widely disliked |
| College sim, mobile | **CFB Simulator** (4.78★ / 625 US ratings); **The Program** | iOS(+Android) | Occupied; CFB Simulator is the reference app |
| **College *and* pro in one mobile app** | **Football Coach: Winning Tradition** (On Paper Sports) — 32-team pro franchise + 70 + team college dynasty, draft classes import/export between them | **iOS + Android, shipping** | Occupied since 2025. ~4.5–4.6★ on 25–53 ratings — young and small, developer iterating annually |
| Mobile sim with a 2D field view | **CFB Simulator** only | iOS | College only |

Sources: `§6.2B §1` (whole table), `§6.2B §2.1, §2.6` (Retro Bowl scale and licensing),
`§6.2B §5.1` (Winning Tradition), `§6.2B §5.2–5.4`, `§6.2A §0.2, §3.1` (deep-pole review counts),
`01-RESEARCH.md §A, §H` (CFB Simulator).

**Three conclusions follow immediately, and two of them are unwelcome.**

**(a) `01-RESEARCH.md` §E needs amending, not deleting.** `§6.2B §5.1` states it plainly: the pro-on-
mobile lane *"now has an incumbent, but a weak one."* Winning Tradition ships both leagues on iOS
today with a salary cap, scouting, dynamic draft classes, coordinator hiring/firing, coaching
philosophy, contract goals and player morale. `§6.2B §5.1` names it **"the competitor most likely to
occupy this project's exact position before this project ships"** and instructs that `PRODUCT.md`
§6.3 *"must argue against it specifically rather than against a vacuum."* This document does so in §5.

**(b) The claim "there is no deep sim on iOS" is not currently safe to make.** `§6.2A §8` flags it
`[U]`: TapTap carries Android/iOS listings for DDS:CFB 2024 and DDS:PF 2025 and gmgames' publisher
profile lists mobile platforms, while the Steam listings say Windows. `§6.2A §8` gives the explicit
instruction: *"Do not use 'there is no deep sim on iOS' as a positioning claim until this is
checked, because it is exactly the claim a reviewer will test."* **Owner action, pre-listing: check
the App Store directly for Wolverine Studios.**

**(c) The unoccupied slot is an intersection, not a category.** Nothing in the map is empty. What is
empty is the *conjunction*: deep-sim management depth + phone-native legibility + a match layer that
is watchable and trusted + offline with no IAP. Intersections are where solo developers go to die of
scope, and §6 makes that the counter-case.

---

### 2. Who is underserved, specifically

Three groups, each named by the product they currently open and the specific thing they tolerate.
All quotations are inherited at their source's grade — see §0.

#### 2.1 Player A — the mobile GM who has stopped trusting the simulation

**Currently plays:** Pocket GM 3: Football Sim (iOS, free + IAP, 4.9★, 50 K+ downloads) and/or
Ultimate Pro Football GM (iOS + Android, free with heavy IAP, **4.0★ from ~22 K reviews — the
largest review corpus in the mobile set**).

**What they put up with**, from those two review corpora (`§6.2B §5.2, §5.3`):

- *"the simming of the games and watching them is awful"*
- *"multiple automatic first down penalties called every single drive whether it's defensive
  holding, roughing the passer, unnecessary roughness, etc to the point it's actually just annoying
  to watch"* — `§6.2B §5.2` correctly identifies this as **a calibration failure that reads to the
  player as a presentation failure**
- *"the decision making makes absolutely no sense"* — down 10 with 4 minutes left and punting;
  4th-and-17 in field-goal range and going for it
- *"Everything is completely random. You try to make educated football decisions, but then the
  opponent converts a 3rd and 40."*
- *"the game really does everything to work against you"*
- *"aggressive pay-to-win mechanics"*; *"the game will do anything to have you spend $5.99"*
- *"boring that they only see texts and graphs, but won't be able to see action in scenes on the
  football field"*

**The number that matters:** 4.0★ across ~22 K reviews for a product whose own reviewers call it
*"the best football mobile game on the market."* `§6.2B §5.3` reads that gap as monetisation dragging
a good game down. This is the **largest and best-evidenced underserved group in the entire
research**, and every one of its complaints is addressable by build quality rather than by a feature
this project does not have.

#### 2.2 Player B — the dynasty player without a desk

**Currently plays:** Football Coach: College Dynasty (Windows, $19.99, 95–96 % positive of ~1,474
Steam reviews) or Draft Day Sports (Windows, annual ~$24.99 release).

**What they put up with:**

- **Being at a desk.** gmgames' verdict on the genre's healthiest modern product states the gap in
  one line: *"the presentation is pretty barebones, so if you need visuals or want something you can
  play on your phone, this isn't it."* (`§6.2B §1, §4.3`)
- **Interface latency as a tax.** DDS: *"agonizing lag, with each click between menus taking 2–4
  seconds"*; menus *"clunky and awkward, which sapped all the fun out of the game."* `§6.2A §4`
  prices it: in a genre where a week costs dozens of screen transitions, a 2 s transition is
  1–2 minutes per week and **~30 minutes per season spent on nothing**.
- **Being assumed to already know the sport.** FOF8: best simulation in the category, *"absolutely
  awful Windows 95-style UI"*, and it *"assumes you know all about American football already"* —
  275 lifetime Steam reviews (`§6.2A §3.1`).
- **No pro option from the developer they trust.** FC:CD's own audience asks for a pro version,
  saying the developer *"could dominate the genre as there's no other solid modern NFL front office
  sims."* SidelineSim's answer, Pro Football Dynasty, has a Steam page and **no release date as of
  August 2026** — a year after `01-RESEARCH.md §B` recorded it as "late 2026" (`§6.2B §1, §4.4`).

**The number that matters:** `§6.2A §3.1`. FOF Eight — the connoisseur's choice, the best mechanics
in the category — sits at 275 lifetime reviews. FC:CD — explicitly reviewed as *"not the most
complex sports simulation on the market"* — sits at ~1,474. **Roughly 5× the audience for admittedly
less depth, on the strength of legibility and pacing.** `§6.2A §6` finding 9 turns this directly into
positioning: the gap is not *"more depth than DDS"*, it is **"DDS-class depth that is legible on a
phone."**

#### 2.3 Player C — the CFB Simulator loyalist whose save died in season 8

**Currently plays:** CFB Simulator (iOS, 4.78★ / 625 US ratings, £3.99 God Mode).

**What they put up with** (`01-RESEARCH.md §H`, carried forward at Tier B):

- **Crashes, save corruption and softlocks at 34 % of reviews**, corruption around season 8 — and
  the developer sells **paid checkpoint tokens that users buy as crash insurance.**
- **A sim they route around.** Watched and simmed games diverge (dev-confirmed weighting bug) badly
  enough that the community meta became *"watch games to get good results."*
- **Job-market dead ends** — contract expiry with zero offers ends the save.
- **No pro tier at all.** Pro-version demand in that community is *"explicit but low-volume."*

`§6.2A §7` corroborates the stability point across the whole competitive pole — Bowl Bound deletes
saves, FOF Nine corrupts at the end of year one just after free agency — and concludes: **stability
is not an iOS-indie problem, it is the genre's baseline failure.**

#### 2.4 The group this product is *not* for, stated plainly

The Retro Bowl player. 40 M+ downloads, ~$2.4 M/yr, ~3 h to a complete input-dense season
(`§6.2B §2.1, §2.5`). `§6.2B §2.8` is unambiguous about what P1 costs here: the one Retro Bowl
property that **cannot** be carried across the removal of direct control is *"mechanical skill that
visibly improves"*, and the section instructs that `PRODUCT.md` should **say so rather than claim
depth substitutes for it.** Whatever is being walked away from, it is not niche — it is three to
four orders of magnitude larger than the audience being walked toward.

---

### 3. What this product does that the incumbents do not

Four candidate differentiators. Each is graded on **evidence strength** (how well the research
supports the claim that the gap exists) and **defensibility** (how hard it is for an incumbent to
match). The two are independent and the strongest candidates score differently on each.

#### 3.1 Candidate 1 — a simulation the player still believes in after twenty seasons

**Evidence: STRONGEST in the research. Defensibility: moderate (hard to copy, invisible to buy).**

`§6.2B §6 P2` is the single most corroborated finding in the whole of §6.2, drawn from **four
independent products**:

| Product | The credibility failure, in its users' words |
|---|---|
| Football Coach: College Dynasty | AI *"punting in situations that would have killed off any chances in the game"*; *"mismanaging a few games a year where a 2 %-chance of a win gets forfeited"*; perceived *"anti-upset logic"* |
| Pocket GM 3 | punting down 10 with 4 minutes; going for it on 4th-and-17 in FG range; *"the decision making makes absolutely no sense"* |
| Ultimate Pro Football GM | *"the opponent converts a 3rd and 40"*; *"your ai players will still find a way to screw the season up"* |
| CFB Simulator | watched-vs-simmed divergence; late-game difficulty collapse; blocked kicks 10× too common (`01-RESEARCH.md §H` rank 3) |

`§6.2B §5.3` states the synthesis: **"Across four independent products, the #1 failure mode of a
no-direct-control football game is that the player stops believing the simulation."** And `§6.2A §6`
finding 7 extends it along the time axis: DDS's complaint is not within-game divergence but
**multi-season statistical drift** — *"nine receivers breached the 1,500-yard mark"* in a save's
fourth season; in older editions *"at least 10–15 running backs rushed for over 1500 yards and
probably half the QBs topped 4500 yards and 30+ TDs."*

This is the differentiator with the best evidence base, and it is the one that is **fully
instrumentable** rather than aspirational. `§6.2B §6 P2, §7` and `§6.2A §6` name the instruments:

- assert AI 4th-down / timeout / end-of-half choices against a win-probability-optimal baseline
  within a stated tolerance, **as a test, not a review item**;
- assert **delegation neutrality**: the outcome distribution for a given state must be
  statistically indistinguishable between player-called and AI-called plays (`§6.2B §6 P4`) — which
  is the same test as D3's two-tier consistency requirement;
- run the calibration bands at **seasons 1, 5, 10 and 20 of the soak, not once** (`§6.2A §6` f.7).

**Why the defensibility is only moderate:** nobody buys a game because its AI punts correctly. This
differentiator reaches a buyer only through reviews the product does not have yet. It is a
*retention and word-of-mouth* differentiator, not an *acquisition* one.

#### 3.2 Candidate 2 — stability across a career

**Evidence: STRONG. Defensibility: low (any incumbent can fix it; several are trying).**

34 % of CFB Simulator's reviews (`01-RESEARCH.md §H` rank 1); corruption at season 8; users buying
checkpoint tokens as crash insurance. Corroborated across the PC pole by `§6.2A §7`. Winning
Tradition's own recent patch notes fix a coaching-screen crash and cloud-save upload failures
(`§6.2B §5.1`). Pocket GM 3's developer answered with **a rewritten game engine** (`§6.2B §5.2`).

This is a genuine and universal deficiency, and `STATUS.md`'s bounded-save-growth lesson
(8.3 MB → 2.3 MB) is directly reusable knowledge. But it is table stakes rather than a wedge: it is
what stops a 1★, not what earns a 5★.

#### 3.3 Candidate 3 — offline, no accounts, no ads, no IAP

**Evidence: STRONG. Defensibility: low, but it is the only differentiator legible in a store
listing.**

`§6.2B §6 P7` makes the case from three directions:

- Ultimate Pro Football GM sits at **4.0★ on 22 K reviews** with the same corpus containing *"the
  best football mobile game on the market"* and *"a cash grab."*
- Retro Bowl's ads are a named complaint; Retro Bowl+ on Apple Arcade removes them.
- CFB Simulator sells **paid checkpoint tokens as crash insurance** (`01-RESEARCH.md §H`).
- Winning Tradition gates **College Mode itself** behind IAP, requires account login, and has a
  review reporting *"couldn't login and the app kept timing out with Apple login"* (`§6.2B §5.1`).

`§6.2B §6 P7` concludes that P3's stance is *"defensible as a feature and should be stated as one in
the store listing, in the same breath as 'no accounts, works on a plane.'"* This is the correct
read, with one qualification the same research supplies: `§6.2B §2.6` notes the **highest-volume
competitor is free** and that **P3 removes the only mechanism this category uses to prove value
before purchase**, so *"the value proposition has to be legible in the store listing without a free
tier to prove it."* That is a real cost of P3 and §6 counts it.

#### 3.4 Candidate 4 — a 2D match view on a phone, in the pro tier

**Evidence: MODERATE, and thinner than it looks. Defensibility: moderate.**

The category claim is sourced: `§6.2B §1` states **"No modern pro football management sim exists on
mobile with a 2D match view"** — CFB Simulator has the view but is college-only, Pocket GM 3 has
the pro depth but is *"texts and graphs"*, Winning Tradition has both leagues but **[ASSUMPTION,
`§6.2B §8`]** no field view; that last is unconfirmed and the App Store screenshots would settle it.

Three pieces of evidence pull the other way and must be stated:

1. **Presentation is demonstrably not what makes these games good.** `§6.2B §4.3`: FC:CD, the
   genre's best-reviewed modern entry, is **text-only** — Steam-tagged *Text-Based* — and scores
   95–96 % positive.
2. **The honest 2D view is much smaller than the phrase implies.** `§6.5 §1` computes the collision:
   22 marks is **5.5× perceptual tracking capacity at the most generous reading and 22× at the
   least**, so the design target is *"maximum diagnostic value per second of screen time, at ≤4
   individuated moving marks."* `§6.5 §8` couples this to D2 and concludes the honest artefact under
   the cheap and middle engine options is **"the play diagram drawing itself"** — two lines, a ball
   trace, an end spot, 2–4 labelled marks. That will not out-screenshot Retro Bowl's pixel field.
3. **Watched-without-input is the universally disliked part of every product in the set.**
   `§6.2B §6 P1`: *"No product in this set is praised for the parts the player watches."* A watched
   snap must **pay for its own seconds** — by carrying a decision, or by carrying information the
   box score cannot.

What *is* well-evidenced is the narrower claim `§6.2A §6` finding 4 makes: **a 2D view earns its cost
only if it is diagnostic.** Bowl Bound's complaint — *"calling plays can be frustrating due to lack
of play-by-play feedback or analysis to explain why plays work or don't work"* — is the failure to
avoid, and DDS:PF 26's own investment went into **highlight ribbons, rotating stat displays and
ball-tracking pan/zoom**, i.e. attention direction and readout, not fidelity.

So the defensible form of Candidate 4 is not *"we have a 2D match view."* It is **"the only football
sim on a phone where you can see why the play worked."** That is a smaller claim and a truer one.

#### 3.5 The composite claim, and why no single candidate carries it

None of the four is individually sufficient. 1 and 2 are quality bars invisible at purchase. 3 is
legible but trivially matched. 4 is visible but its evidenced value is diagnostic legibility rather
than spectacle. **The gap is the conjunction**, which is exactly why it is unoccupied and exactly
why it is dangerous — see §6.

The sharpest single-sentence positioning the evidence actually supports:

> **DDS-class management depth, legible on a phone, in a simulation that is still credible in
> season twenty — offline, paid once, no accounts.**

Every clause of that sentence traces to a finding: depth-vs-legibility to `§6.2A §3.1` (1,474 vs
275); credibility to `§6.2B §6 P2` (four products); drift to `§6.2A §6` f.7; offline/no-IAP to
`§6.2B §6 P7`.

---

### 4. Where the evidence does **not** support a differentiator

The brief asks for this explicitly. Four claims the project has been carrying that should be struck
or downgraded before they reach `PRODUCT.md`.

**4.1 "The pro-on-iOS lane is empty."** **STRIKE.** Winning Tradition ships 32-team pro *and* 70+
team college on iOS and Android today (`§6.2B §5.1`); Pocket GM 3 and Ultimate Pro Football GM occupy
the pro-GM-on-mobile slot with 50 K+ downloads and ~22 K reviews respectively (`§6.2B §5.2, §5.3`);
and the "no deep sim on iOS" variant is flagged `[U]` and unverified (`§6.2A §8`).

**4.2 "More depth than the incumbents."** **STRIKE — the evidence actively disconfirms it.**
`§6.2A §3.1`: the deepest product in the category has 275 lifetime reviews and the shallower one has
~1,474. `§6.2B §6 P5`: FC:CD's own fans say it becomes *"a recruiting simulator, not a coaching
simulator"* and feels *"hollow"* after several seasons — depth in the acquisition loop specifically
does not sustain. `§6.2A §7`: *"Depth without a competent valuation model is worse than less depth."*
Depth is what retains the committed; legibility is what recruits anyone at all. Two different
problems, and the project's stated audience problem is the second.

**4.3 "A 2D match view is the differentiator."** **DOWNGRADE.** See §3.4. The evidence for *demand*
is two data points — one gmgames line and one Pocket GM 3 review — against FC:CD's 95 % at
text-only. The defensible claim is diagnostic legibility, not the existence of a field render.

**4.4 "We can learn engagement from Football Manager Mobile."** **HEAVILY QUALIFIED.** `§6.1 §7.2`
ranks FMM's five engagement sources by transferability and the top one is **non-transferable**: *"Every
row in FMM's tables is a name the player already has feelings about … Tier A of this brief forbids
us any of it."* The second — player-authored jeopardy and roleplay constraints — is supplied by
**FMM Vibe, not by the binary**, and a new title has no such community on day one. `§6.1 §7.3`:
*"Copying FMM's interface without building its stakes reproduces the Pocket Tactics verdict: an
exercise in juggling numbers."* Only two of the five are directly transferable: **the game
interrupts the player** (in-match notifications) and **resumption is nearly free**.

---

### 5. Interrogating the assumed differentiator: the unified college→pro promotion arc

The brief asserts P2's promotion arc is *"likely the single strongest differentiator."* The research
does not support that, and this section says why. **This is not an argument to relitigate P2 —
P2 is fixed. It is an argument about what `PRODUCT.md` may claim, and about where the scope risk
sits.**

#### 5.1 Does any incumbent already do it? Yes — twice, and one of them is on iOS.

| Incumbent | What it ships | Grade |
|---|---|---|
| **Football Coach: Winning Tradition** (On Paper Sports) | 32-team pro franchise mode **and** 70+ team college dynasty with a 12-team playoff **in one app**, and *"the two are connected. You can import/export draft classes from College Mode into Pro Mode and continue the journey of your favorite players."* **iOS + Android, shipping now.** | `§6.2B §5.1` |
| **Draft Day Sports** | DDS:CFB 26 added starting as a **coordinator** and working up to head coach via reputation and the carousel; DDS:PF 26 added head coach / coordinator / position coach roles beyond GM; **DDS:PF can import a DDS:CFB universe** to bring college rookies into the pro draft. | `§6.2A §1.2, §6` f.10 `[C]` |
| Retro Bowl / Retro Bowl College | Same engine, two apps, no career link. | `§6.2B §3.1` |

`§6.2A §6` finding 10 states the conclusion the package must adopt verbatim:

> **"The promotion arc is now a shipped, validated genre feature — and P2 should not be defended as
> novel.** … P2's actual novelty is that it is **one save and one continuous career on a phone**,
> not that college and pro coexist. `PRODUCT.md` should make that claim precisely, or a reviewer
> will correct it."

And `§6.2A §7` amends §E accordingly: *"The lane on iOS is still open, but 'college→pro career' is no
longer a differentiator on its own."*

#### 5.2 Do players ask for it? Almost nobody asks for **this**; several ask for something adjacent.

Searched across four community corpora, the demand signal for a *unified college→pro career* is
close to absent:

- **CFB Simulator** (`01-RESEARCH.md §H`): a ranked top-10 complaint/request table. The promotion
  arc appears **nowhere in it**. Pro-version demand is recorded separately as *"explicit but
  low-volume."* What rank 5 does contain is **"start-as-coordinator"** — a career ladder, but a
  *within-tier* one, and precisely what DDS shipped.
- **FC:CD** (`§6.2B §4.4`): the ask is *a pro version* — *"no other solid modern NFL front office
  sims"* — i.e. demand for a pro **product**, not for a college→pro **career**.
- **Retro Bowl College** (`§6.2B §3.3`): the three most-requested features are **transfer portal**,
  **redshirting** and **early HS scouting**. All within college.
- **Winning Tradition** (`§6.2B §5.1`): requests are for deeper team stats and richer player cards
  including awards, trophies and HS stats — not for a continuous career.

**DERIVED.** The demand that exists is for **a ladder with rungs you climb and can fall off**, and
the rung players actually name is coordinator→head coach. The college→pro rung is an inference the
project made, not a request the market voiced. That does not make it wrong — players rarely request
a structure they have never seen — but it removes "players are asking for this" from the argument.

#### 5.3 Differentiator, or scope multiplier?

**Overwhelmingly a scope multiplier, and the multiplication lands on the three hardest decisions in
the package.**

| Cost | Magnitude | Source |
|---|---|---|
| Off-screen slate | ~15 pro games/week → **~65 college games/week across ~134 programmes**, plus recruiting and transfer-portal AI for **every one of them** — *"plausibly a larger cost than the game simulation itself"* | brief §5 D3 |
| Endogenous identity (D6) | **No competitor has solved it.** Every one manufactures college identity by **borrowing meaning the player already has** — Retro Bowl College's near-miss bowl names + a paid editor whose community purpose is restoring real schools; EA's NIL deals; CFB Simulator's real cities. **Tier A forbids all of it.** This project *"is the only entrant that must generate meaning endogenously, and no competitor has solved that problem for it to copy."* | `§6.2B §6 P6, §3.2` |
| Legal exposure | Tier A is *strictly larger* in college. `§6.2B §3.2` escalates the JSON league import/export feature carried at v1.5 in `01-RESEARCH.md §C/§H` **to counsel before it is planned**, because the demonstrated community use of exactly such an editor in the closest comparable product is trade-dress reconstruction, and a JSON import accepts *a file someone else made* | `§6.2B §3.2, §7` |
| Calibration | Pro bands are inherited from the existing suite. **College is "the genuine gap"** — clock rule, tempo and play volume, home advantage, talent dispersion across 134 programmes, kicker quality, OT structure all need new derivation | `§6.4 §4` |
| Content authoring | ~134 programmes vs 32 teams, and D6 is original work with no reference implementation to copy | `§6.2B §7` → D13 |
| Hollowing risk | P2 makes recruiting **and** the draft **and** free agency all v1 features — and `§6.2B §6 P5` names *"the acquisition loop is deep and the everything-else loop is shallow"* as the structural fault that made FC:CD go hollow. **"This project is at above-average risk of it."** | `§6.2B §6 P5` |

Against that, what it buys:

- **A genuinely differentiated narrative device.** The promotion is the strongest single-save story
  beat available to a game that cannot import meaning. It rhymes with the strongest idea `§6.2B §3.2`
  found anywhere in the arcade pole — Retro Bowl College's *"you don't pick your school"*, which
  that section calls **"the strongest single idea here"** for D8/D9: *denial of the fantasy at t=0,
  so that reaching it is a story.*
- **A structural answer to hollowing.** FC:CD goes hollow because acquisition is mastered and
  nothing else deepens. A tier change **resets the acquisition loop entirely** — new currency, new
  roster rules, new opponents, new stakes. That is a real, evidence-grounded retention argument,
  and it is the strongest thing that can be said for P2.

#### 5.4 Verdict on the promotion arc

**It is a real feature and a weak differentiator, and it is the largest scope term in the project.**

Precisely: college-and-pro-together is **shipped**, on the exact target platform (Winning Tradition)
and on desktop with a universe import (DDS). The surviving novelty is narrow — *one save, one coach,
one continuous career, on a phone* — and no community in the research asked for it. Its value is
concentrated in **a single moment that arrives after many hours of play**, and it is purchased with
the scope (D3's 134-programme recruiting AI, D6's unsolved endogenous-identity problem, D13's
authoring budget, the college calibration gap, the larger Tier A exposure) that determines whether
**the first hour is any good at all.** Under P5 — solo developer, no QA, no playtest cohort, no
telemetry — that is a bad ordering of risk.

**What follows, without relitigating P2:**

1. `PRODUCT.md` must **not** lead with the promotion arc. It leads with §3.5's composite claim, and
   states the arc precisely as *one save, one coach, continuously, on a phone* — a retention device,
   not the headline (`§6.2A §6` f.10).
2. **Escalate to the owner as a blocking sequencing question in `docs/OPEN-DECISIONS.md`:** P2 fixes
   *that* both tiers ship in v1; it does not fix *which tier is built and hardened first*, nor
   whether the college programme count is 134 or materially fewer. Both are open, both are load-
   bearing on D3/D4/D13, and both are the owner's to decide. This is a question about ordering
   inside P2, not a request to relax it.
3. The college tier must be independently good, because it is where the player starts. If D6 cannot
   make a fictional programme feel like a programme, the promotion arc is a bridge from a place
   nobody wanted to leave to a place they will never reach.

---

### 6. The counter-case: the strongest argument against building this as specified

Stated at full strength, from the research rather than from caution.

**The argument.** *This is a quality play in a market where quality is not what determines the
outcome, executed by one person, against a field where every differentiator it has is invisible at
the point of purchase.*

Six supporting legs, each sourced:

1. **The audience arithmetic is brutal and it points the wrong way.** The audience being walked away
   from: Retro Bowl, 40 M+ downloads, ~$2.4 M/yr (`§6.2B §2.1`). The audience being walked toward:
   CFB Simulator 625 US ratings, FC:CD ~1,474 Steam reviews, FOF Eight 275, DDS:PF 2025 **13**
   (`§6.2A §0.2, §3.1`). That is three to four orders of magnitude. `§6.2B §2.1` says it directly:
   *"Whatever is being walked away from, it is not niche."*

2. **P3 removes the category's only proof-of-value mechanism.** Retro Bowl, Pocket GM 3, Ultimate
   Pro Football GM and Winning Tradition are **all free to download**. This product is paid-premium
   with no free tier, no IAP and no ads. `§6.2B §2.6`: *"the value proposition has to be legible in
   the store listing without a free tier to prove it."* CFB Simulator proves a paid model can
   sustain at 4.78★ — but it is paid *after* a free download with an IAP unlock, which is a
   different shape from paid-at-the-gate.

3. **Every genuine differentiator is invisible in a screenshot.** §3: credible AI, twenty-season
   stability and no-IAP are all learned by playing or by reading reviews the product does not have.
   The one visible differentiator — the 2D view — resolves under an honest engine to *"the play
   diagram drawing itself"*, ≤4 individuated marks (`§6.5 §1, §8`), against a field where the volume
   leader ships a pixel side-scroller and the quality leader ships **text** and scores 95 %
   (`§6.2B §4.3`).

4. **The differentiators are quality bars, and P5 is the worst possible team shape for guaranteeing
   quality bars.** No QA, no playtest cohort, no telemetry. And the project has already run this
   experiment: the prior build shipped **224 tests, 13,226 assertions and a ten-season soak**
   (`STATUS.md`), and the owner's verdict was *"a bland application, not a game."* `6.0` explains
   why the tests could not see it — 1 mandatory decision per management week, **0 inbound events**,
   jeopardy frozen for an entire season, 2 of 24 coach skill nodes wired, scouting literally
   unspendable, and `AUDIT.md`'s own systemic finding: *"the test's coverage boundary became the
   quality boundary."* **Nothing in the new plan changes the mechanism that failed** — it proposes
   more tests against a wider surface.

5. **P1 deletes the part of the previous build that was carrying the load, and the replacement is
   unproven.** `§6.0 §6.4` establishes the arcade system is 3,887 lines — **~21 % of the codebase** —
   and that it carried ~99 % of the build's decision volume (~65 play calls per game against 1
   mandatory management decision per week), plus all the presentation, all the sub-annual jeopardy,
   and the only place in the build where an attribute was expressed as something other than a number
   in a grid. `§6.0 §6.4` concludes: *"If the rebuild removes the arcade and does not deliberately
   re-source those four functions in the management layer, it reproduces the blandness at higher
   fidelity."* Meanwhile `§6.2B §5.4` supplies **shipped disconfirming evidence for the lowest-agency
   option**: The Program: College Football, pure gameplan-and-spectate, on mobile, in this exact
   genre — *"Where it gets frustrating is the simulation itself — you don't have much control over
   what happens on the field beyond setting a game plan and hoping for the best."*

6. **The position may be occupied before the product ships.** Winning Tradition is on iOS now, with
   both tiers, from a developer already iterating annually (`§6.2B §5.1`). And the genre's own answer
   to long-run engagement is **human opponents** — FOF's 500–1,000-hour wall is discussed alongside
   multiplayer-league support; DDS players say the game *"becomes a gem"* in an MP league
   (`§6.2A §3.2`). P1 and P3 bolt that escape hatch shut, so all long-run jeopardy must come from AI
   and narrative alone — *"precisely the axis the same communities say is weakest."*

#### 6.1 What would have to be true for it to be right anyway

Five conditions. Three are supportable now, one is testable during the build, and **one has no
supporting evidence anywhere in the research**.

| # | Condition | Status |
|---|---|---|
| C1 | The owner is optimising for an artefact he wants to exist over commercial return | **Consistent with P3 and P5 as written.** If true, leg 1 and leg 2 of the counter-case bite only on revenue and can be accepted knowingly. **Owner question, not a research question.** |
| C2 | Credibility and stability really are the binding constraint on this niche's ceiling | **Best-evidenced claim in the package.** `§6.2B §6 P2` (four independent products), `01-RESEARCH.md §H` rank 1 (34 % of reviews), `§6.2A §7` (corroborated across the PC pole). Accept. |
| C3 | The decision-density floor can be cleared without direct control | **Testable, and §4 must clear it with arithmetic.** The floor is stated: beat **1 mandatory decision per week** (`§6.0 §10`) while preserving Retro Bowl's three transferable properties — *loop latency in seconds, causal legibility, tens of repetitions per game* (`§6.2B §2.8`). `§6.2B §6 P8` supplies the instrument: **treat P4's 6–8 h as a ceiling and adopt a decisions-per-hour density floor**, because a per-hour density floor is falsifiable and a per-season ceiling is not. If §4 cannot clear it, the counter-case wins. |
| C4 | A fictional programme can be made to feel like a programme without borrowed meaning | **NO SUPPORTING EVIDENCE EXISTS.** `§6.2B §6 P6`: every competitor borrows; `§6.2B §3.2`: Retro Bowl College's rivalries are *"flavour attached to borrowed real-world meaning"* and on the available evidence have no mechanical effect. This is the **highest-risk unproven claim in the entire package**, it is load-bearing on the tier the player starts in, and D6 has no reference implementation. `§6.2A §5.5` is the one encouraging data point — DDS:CFB has sustained a commercial annual release for years on an entirely fictional universe — but its community's answer to fictional identity is **to mod real names back in**, which Tier A forbids. |
| C5 | D11 is solved — the toolchain question | **Open.** `§6.0 §0` and `STATUS.md` record no Swift toolchain and an egress policy refusing `download.swift.org`; Phase 4C shipped **never compiled**. An unverified build is not a product, and this is orthogonal to every design argument above. |

**The honest bottom line.** C2 is strong, C3 is §4's job and is achievable, C5 is an engineering
escalation. **C4 is the one that decides whether this product is good**, and there is no evidence
for it anywhere in this research because nobody has ever tried. That is the correct place to be
frightened, and it is a *different* place from where the brief's framing points.

---

### 7. What this contributes downstream

| Target | Contribution |
|---|---|
| **`PRODUCT.md` §6.3** | Lead with §3.5's composite claim. Amend `01-RESEARCH.md §E` per §1(a) rather than deleting it. Argue against Winning Tradition **by name** (`§6.2B §5.1`). State the promotion arc precisely as *one save, one coach, on a phone* (§5.4). State the Retro Bowl loss honestly (§2.4). State no-IAP/no-accounts/offline as a feature in the listing (`§6.2B §6 P7`). |
| **§4 (gate zero)** | The gap does **not** rest on agency density — it rests on credibility, legibility and trust. §4 may therefore choose a lower-agency model than the arcade evidence suggests, **provided** it clears the C3 floor in §6.1 and does not choose pure spectate, which has shipped disconfirming evidence (`§6.2B §5.4`). |
| **D6 / D13** | C4 in §6.1 is the highest-risk unproven claim in the package. D6 should be budgeted and sequenced as the project's primary design risk, not as a compliance tax. |
| **D10** | Candidate 1 (§3.1) is the strongest differentiator the evidence supports. Its instruments are already named and should be gates, not review items. |
| **`docs/OPEN-DECISIONS.md`** | Two escalations: **(i)** §5.4 item 2 — which tier is built and hardened first inside P2, and the college programme count; **(ii)** `§6.2A §8` — verify Wolverine Studios' actual App Store presence before any "first deep sim on iOS" claim is published. |
| **Counsel** | `§6.2B §3.2` — whether a team/league editor or JSON import can ship **at all**, given the documented community use of exactly that feature for trade-dress reconstruction in the closest comparable product. `01-RESEARCH.md §C/§H` carry it as a v1.5 feature; it now needs legal review **before** it is planned. |

---

### 8. Assumptions and unsourced items

Collected so the owner can see what this argument rests on beyond its citations.

- **[ASSUMPTION — inherited, `§6.2B §8`] Winning Tradition has no 2D field view.** No screenshot
  description or review in any surfaced source mentions one. §3.4's category claim weakens if this
  is wrong. **Settle by opening the App Store listing.**
- **[U — inherited, `§6.2A §8`] Draft Day Sports' mobile availability.** TapTap and gmgames list
  Android/iOS; Steam says Windows. §1(b) and §4.1 both depend on it. **Settle by searching the App
  Store for the publisher.**
- **[DERIVED — mine] The demand signal for a unified college→pro career is close to absent.** This
  is a negative drawn from four community corpora (§5.2) that were themselves reached through a
  search-summarisation layer, with **Reddit unreachable** (`§6.2B §8`). Absence of evidence in a
  partially-sampled corpus is weak evidence. A session with Reddit access should re-run the query
  against r/FootballCoach and r/cfbsimulator specifically; `§6.2B §8` names it as *"the one gap in
  the evidence base that is worth closing."*
- **[DERIVED — mine] "The gap is a quality gap at an intersection, not a category gap."** This is
  the central synthesis of the document. Each occupancy row in §1 is sourced; the conclusion that
  the conjunction is what is unoccupied is my argument, not a finding.
- **[DERIVED — mine] The three-persona segmentation in §2.** The complaints are sourced verbatim
  from review corpora; grouping them into three players with distinct current products is my
  construction. No segmentation study exists, and under P5 none will.
- **[ASSUMPTION — mine] Winning Tradition's rating count (25–53) indicates a young product rather
  than a rejected one.** `§6.2B §8` records two conflicting snapshots and instructs treating it as
  *"small and growing"*, not as a precise figure. If it is instead a product the market has seen and
  declined, §6 leg 6 weakens considerably and §1(a) is less urgent.
- **[UNVERIFIED — inherited] Every bracketed quotation in this document reached its author through
  the WebSearch summarisation layer, not from the source page** (`§6.2A §0.1`). Before any of them
  appears in `PRODUCT.md` or a store listing, it must be re-verified against its URL on an
  unrestricted machine.
- **[NOT MEASURED] Nothing in this document is a play impression of any competitor.** No competing
  product was installed or played, on any platform, by anyone, in producing this research.

---

### 9. Sources

This document is assembled from the research parts; each claim above cites the part and section that
carries the underlying URL. The primary external sources that carry the load-bearing numbers:

**The incumbent nobody had found**
- https://www.onpapersports.com/winning-tradition-football
- https://apps.apple.com/us/app/winning-tradition-football/id6743344615
- https://gmgames.org/winning-tradition-football/
- https://forums.operationsports.com/forums/forum/football/other-football-games/26874046-winning-tradition-football-released-today

**The 1,474-vs-275 argument**
- https://store.steampowered.com/app/2151290/Football_Coach_College_Dynasty/
- https://gmgames.org/football-coach-college-dynasty/
- https://www.operationsports.com/football-coach-college-dynasty-review-a-sports-sim-with-training-wheels-for-better-and-worse/
- https://steamcommunity.com/app/2151290/negativereviews/?browsefilter=toprated
- https://gmgames.org/section/american-football-nfl-college-manager-simulator-games/

**The credibility failure across four products**
- https://apps.apple.com/us/app/pocket-gm-3-football-sim/id1645791169?see-all=reviews&platform=iphone
- https://apps.apple.com/us/app/ultimate-pro-football-gm/id1530542938
- https://play.google.com/store/apps/details?id=com.gmz2rk.ufgm&hl=en_US
- https://steamcommunity.com/app/2151290/discussions/0/4205868123787946936

**The audience being walked away from**
- https://www.appbrain.com/app/retro-bowl/com.newstargames.retrobowl
- https://apprank.io/retro-bowl
- https://www.metacritic.com/game/retro-bowl/
- https://www.operationsports.com/retro-bowl-review-a-mobile-game-that-transcends-the-platform/
- https://apps.apple.com/us/app/retro-bowl-college/id1632904520

**The pro lane's absent occupant**
- https://store.steampowered.com/app/4769350/Pro_Football_Dynasty/
- https://www.operationsports.com/pro-football-dynasty-coming-soon-to-steam/

**Pure spectate, shipped and disconfirmed**
- https://play.google.com/store/apps/details?id=com.atomic.collegefootball&hl=en_US

**Why FMM's engagement does not transfer**
- https://www.pockettactics.com/football-manager-2020-mobile/review
- https://fmmvibe.com/forums/topic/43226-opinion-what-is-the-point-of-fmm/
- https://www.footballmanager.com/fm26/features/mobile

**Borrowed identity, and why Tier A forbids the only working strategy**
- https://inreviewcritics.com/2023/10/23/top-5-biggest-differences-between-retro-bowl-college-and-retro-bowl/
- https://www.youtube.com/watch?v=feeKPLPHd0I
- https://retro-bowl.fandom.com/wiki/List_of_teams
- https://www.apple.com/newsroom/2025/08/apple-arcade-exclusive-nfl-retro-bowl-26-launching-september-4/

---

## §6.4 — Statistical calibration targets, both tiers

**Governing brief.** `docs/reviews/2026-08-09-spec-prompt-v4.md` §6.4. Feeds **D2** (what the match
engine resolves), **D3** (the two-tier consistency requirement), **D4** (performance budgets), **D6**
(fictional identity — via talent dispersion), **D11** (what runs the tests), and deliverable **`03`**,
whose definition of done is *"contains a calibration harness a builder can implement without further
design work."* This document is the input to that harness.

**Scope.** Three jobs, in order:

1. **Extract** the calibration knowledge already paid for — every band asserted in the existing test
   suite, with file and line. Tier B: reusable knowledge, not to be re-derived.
2. **Verify and refine** the pro-tier bands against public data.
3. **Build the college tier from scratch.** This is the genuine gap and the bulk of the work.

Then: talent dispersion across ~134 programmes, a formal acceptance-band specification, and the
legal posture on design-time versus shipped data.

---

### 0. Method and the honest grade of this evidence

#### 0.1 What I could and could not reach

Direct fetches were attempted first and **failed on organisation egress policy**. Verified in this
container via `curl -sS "$HTTPS_PROXY/__agentproxy/status"`. `WebFetch` returned `EGRESS_BLOCKED`
for every one of: `www.pro-football-reference.com`, `www.sports-reference.com`,
`api.collegefootballdata.com`, `collegefootballdata.com`, `www.teamrankings.com`, `www.ncaa.com`.
Per `/root/.ccr/README.md`, policy denials are reported, not routed around. No workaround was
attempted.

**Consequence:** every numeric claim below reached me through the WebSearch tool's own
retrieve-and-summarise layer. That layer reads the page; I read its rendering of the page. This
matters enormously for a document whose entire purpose is numbers, so I have graded every one.

This is the same constraint recorded in `§6.2A §0.1`, and I use its
grading vocabulary deliberately so the two documents can be read together.

| Grade | Meaning | How to treat it |
|---|---|---|
| **[Q]** | A specific figure the search layer returned as a direct statement of fact from a named source. | Usable as a band anchor. Owner should re-verify against the URL before the band ships in a test. |
| **[C]** | Corroborated — the same figure or the same substantive claim arrived from ≥2 unrelated sources. | Strongest grade available here. Safe to build a band on. |
| **[P]** | Paraphrase of a sourced page; direction and rough magnitude reliable, exact digits not. | Usable to set a band's *shape*, not its edges. |
| **[U]** | Single weak source, or plausibly a search-layer artefact. | Do not gate a test on it. Listed in §8. |
| **[ASSUMPTION]** | Mine. Not sourced. | Listed in §8, and every one is flagged inline too. |

#### 0.2 The band-derivation rule, stated before any band is written

A simulated league should be able to land anywhere a real league has actually landed, and nowhere
else. So:

> **Band = the envelope of observed league-season values across the most recent completed seasons I
> could source, with no arbitrary widening.** Where I could source only one or two seasons, the band
> is marked **provisional** and the widening is stated as an explicit assumption rather than smuggled
> in.

This rule is reproducible and it is falsifiable — the owner can re-derive any band from the cited
source and get the same answer. It is also the reason several inherited bands are *narrowed* below:
they were set by intuition, and intuition drew them wider than reality.

---

### 1. The inherited bands — extracted verbatim from the test source

`docs/STATUS.md:45` claims: *"Calibration | Scoring, yardage, completion rate, sacks, turnovers,
kicking, home advantage, fourth-quarter share, explosive plays and target distribution all asserted
inside realistic bands."* That claim is accurate. Here is what it actually means, from source.

#### 1.1 The per-game calibration suite

All from `Tests/SimTests/Suites/GameSimulatorTests.swift`, in the `suite("Calibration")` block. The
sample is built once at **line 319**:

```swift
let sample = SimHarness.sample(count: 600, seed: 31, retainPlays: true)
```

**600 games, one seed, random team pairings drawn from a single generated league** (`SimHarness.sample`,
lines 68–93). Every band below is a range-membership check against a point estimate from that one
sample.

| # | Metric | Band asserted | Line |
|---|---|---|---|
| 1 | Points per team-game | `20...26` | `GameSimulatorTests.swift:322` |
| 2 | Pass yards per team-game | `195...245` | `:326` |
| 3 | Completion percentage | `61...67` | `:327` |
| 4 | Rush yards per team-game | `100...130` | `:331` |
| 5 | Interceptions per team-game | `0.6...1.1` | `:335` |
| 6 | Sacks per team-game | `2.0...3.1` | `:336` |
| 7 | Field goal percentage | `80...90` | `:340` |
| 8 | Overtime rate (share of games) | `0.008...0.14` | `:344` |
| 9 | Home win rate (decided games) | `0.50...0.60` | `:348` |
| 10 | Offensive plays per team-game | `55...72` | `:352` |
| 11 | Share of points scored in Q4 | `0.22...0.32` | `:356` |
| 12 | Explosive plays (25+ yds) per game | `3...9` | `:360` |
| 13 | Touchdowns of 40+ yards per game | `0.2...1.2` | `:361` |
| 14 | Safeties per game | `<= 0.05` | `:365` |
| 15 | Tight end target share | `0.15...0.26` | `:369` |
| 16 | Running back target share | `0.10...0.28` | `:370` |
| 17 | Max single-receiver target share | `<= 0.45` | `:371–374` |

**Metric definitions that are not obvious from the band** and that a rebuild must preserve or
consciously change:

- **Explosive play** (`:131`) means `play.yards >= 25` and category in `{run, pass, touchdown}`.
  This is a *project-local* definition. It matches no public analytics convention (§3.6).
- **Long touchdown** (`:134`) means `category == .touchdown && yards >= 40`.
- **Max receiver share** (`:35`) only counts players on teams with `> 200` sample targets, so it is a
  sample-wide share, not a per-game share.
- **Team passing yards are net of sacks; receiver yards are gross** (`:202–205`). The suite asserts
  `teamStats.passingYards <= sum(receivingYards)`, which is the NFL convention. College box scores
  use the same convention. Keep it.
- **Fourth-quarter share** (`:51–53`) is computed over `quarterPoints[0...3]` only, so **overtime
  points are excluded from both numerator and denominator**. A rebuild that folds OT into Q4 will
  silently shift this metric.

#### 1.2 Mechanics bands outside the calibration suite

| Metric | Band asserted | Sample | Line |
|---|---|---|---|
| Tie rate, regular season | `< 0.03` | 200 games | `GameSimulatorTests.swift:245` |
| Best team beats worst team | `>= 0.72` | 400 games, home field alternated | `:298` |
| Simulation cost | `< 20 ms` per game | 200 games | `:314` |
| Playoff games never tie | exactly 0 | 60 games | `:256` |
| Play log inside field and clock | 0 violations | 1 game, all plays | `:270–275` |

#### 1.3 Season-level bands

From `Tests/SimTests/Suites/SeasonTests.swift`:

| Metric | Band asserted | Line |
|---|---|---|
| Worst team's win total | `<= 6` (of 17) | `:285` |
| Best team's win total | `>= 11` (of 17) | `:286` |
| League-wide injured players after 6 weeks | `> 0` and `< 120` | `:226–227` |
| News items after 4 weeks | `> 20` | `:234` |
| Week-advance cost | `< 150 ms` | `:218` |
| Playoff game count (14-team field) | exactly 13 | `:162` |

#### 1.4 Ten-season soak invariants

From `Tests/SimTests/Suites/DynastyTests.swift`, `suite("Ten-season soak")`:

| Invariant | Band asserted | Line |
|---|---|---|
| Average player overall, every season | `62...76` | `:187` |
| Drift in average overall, season 1 → 10 | `< 6` points | `:191` |
| Average player age, every season | `23...30` | `:196` |
| Teams holding a top-five spot all ten seasons | exactly `0` | `:204` |
| Distinct teams reaching the top five in a decade | `>= 12` | `:209–210` |
| Distinct champions in ten seasons | `>= 3` | `:213` |
| Cap overage per team after a decade | `<= salaryCap / 20` | `:230` |
| Save size after ten seasons | `< 5 MB` | `:266` |
| Oldest unsigned free agent | `< retirementAge + 2` | `:288` |
| Free-agent pool floor | `> 100` | `:301` |

#### 1.5 Generation bands

From `Tests/SimTests/Suites/GenerationTests.swift`:

| Metric | Band asserted | Line |
|---|---|---|
| Worst team overall rating | `50...75` | `:221` |
| Best team overall rating | `75...95` | `:222` |
| Best-minus-worst spread | `> 8` | `:223` |
| Share of expiring contracts | `0.15...0.55` | `:254` |
| Share of undrafted players on rosters | `0.02...0.35` | `:351` |
| Trait frequency | `0.25 ± 0.05` | `:94` |

**This section is the reusable asset.** Everything below either confirms one of these numbers,
moves it, or adds a college counterpart.

---

### 2. Four structural defects in the inherited harness

Before refining any band, the *instrument* needs fixing. These are not nitpicks; each one lets a
miscalibrated engine pass.

#### 2.1 Range membership on a point estimate is not a statistical test

`expectIn` (`Tests/SimTests/TestKit.swift:102–116`) checks whether a single number from a single
seed falls inside a range. It has no notion of sampling error, and increasing the sample size does
not make it stricter — it only makes the estimate more precise while the criterion stays fixed.

Two failure modes follow:

- **False pass.** The point estimate lands inside the band while the model's true rate is outside it.
  The suite's own comment at `GameSimulatorTests.swift:345–347` admits this: *"Home win rate is
  measured over 600 games, so its standard error is around two percentage points."* At p = 0.55,
  SE = 0.0203. A model whose true home win rate is 0.62 — outside the band, and flatly wrong — passes
  this test roughly **1 run in 6**. (Worked: at a true rate of 0.62, SE = √(0.62·0.38/600) = 0.0198;
  the upper band edge sits at z = (0.60 − 0.62)/0.0198 = −1.01, so P(pass) = Φ(−1.01) ≈ 0.156, the
  lower edge contributing nothing. An earlier draft of this section said "1 run in 3", which
  overstated it roughly twofold; the argument is unchanged, because a 16% false-pass rate on a
  flatly wrong model is still a broken instrument.)
- **False fail.** A correctly calibrated model at the band edge fails on noise, and the reflex fix is
  to widen the band rather than to fix the instrument. Band #8 (overtime rate `0.008...0.14`, a
  seventeen-fold range) looks exactly like the scar tissue of that reflex.

**Fix (§6.2):** replace range membership with **equivalence testing (TOST)** — pass iff the 90%
confidence interval for the estimate lies *entirely inside* the band. This inverts the burden of
proof: the harness must demonstrate calibration, rather than merely fail to demonstrate
miscalibration.

#### 2.2 One seed is not a sample of the model

All seventeen bands come from `seed: 31`. Tuning the model until that seed passes is overfitting to
the seed, and there is no instrument that can see it. Under **P5** — no QA, no telemetry, no playtest
cohort — an overfitted calibration is undetectable until a player notices, and there are no players
until TestFlight.

**Fix:** a fixed **seed ladder**, split into a *calibration ladder* used for tuning and a **holdout
ladder that is never used for tuning** and appears only in the gate. Concretely: 24 seeds, ladder A
(seeds 1–12) for tuning, ladder B (seeds 13–24) for the gate.

#### 2.3 One-sided assertions cannot fail in the dangerous direction

`GameSimulatorTests.swift:298` asserts the best team beats the worst **at least** 72% of the time.
A model in which the better team wins 100% of the time — no upsets, no jeopardy, the thing **D8** is
about — passes this test cleanly. Same shape at `:365` (safeties), `:371` (receiver share) and
`SeasonTests.swift:285–286` (win totals). Jeopardy has no lower bound anywhere in the suite.

**Fix:** every one-sided assertion becomes two-sided unless there is a stated physical reason it
cannot be (e.g. "playoff games never tie" is a rule, not a distribution).

#### 2.4 No band conditions on context, and college makes that fatal

Every band is marginal — averaged over all games in the sample. In the pro league, where the schedule
is near-balanced and talent is compressed, a marginal band is a reasonable summary. **In college it
is not**, because the college margin distribution is a mixture of two very different populations
(§4.5): non-conference mismatches and conference games. A single "average margin" band can be hit
exactly by a model that is badly wrong about both.

**Fix:** college bands are **conditioned on game context** (non-conference / conference / rivalry /
postseason) and asserted per stratum.

---

### 3. PRO tier — verification and refinement

#### 3.1 Scoring

- NFL teams averaged **21.4 points per game in 2024** — the fifth straight annual decline and the
  lowest since 2006. **[Q]** (NBC News; corroborated in framing by StatMuse league-average queries) **[C]**
- League average points per drive is **1.72**, against an expected 1.77, on 2009–18 data. **[Q]**
- Average NFL game total (both teams) is **45.7 points**. **[Q]** (Boyd's Bets, in the course of
  contrasting with college)

45.7 combined ⇒ **22.85 per team-game**, which brackets the 2024 figure of 21.4 from above and is
consistent with the higher-scoring 2020–21 seasons.

**Verdict: band #1 `20...26` is sound.** It contains both the recent floor (21.4) and the modern
ceiling. **Retain.**

#### 3.2 Passing volume — the one inherited band that is provably wrong

- The per-game passing average in 2024 was reported at **192.7 yards per game**. **[P]** (NBC News,
  reporting on the scoring decline; described as an early-season figure, so treat the digits as
  indicative and the direction as reliable.)

Band #2 asserts `195...245`. **192.7 is below the floor.** Even granting that this was a partial-season
figure and the full-season number likely settled slightly higher, the band's floor sits within noise
of a real observed league season — which means a correctly calibrated engine reproducing a
2024-flavoured league would **fail** this test.

**Verdict: widen band #2 to `185...245`.** Flagged as the single highest-confidence correction in
this document.

#### 3.3 Completion percentage, rushing, turnovers, pressure

I could not source league-average completion percentage, sacks per game or interceptions per game to
a specific figure — every route led to `teamrankings.com` and `ncaa.com`, both egress-blocked. **[U]**

**Verdict: retain bands #3 (`61...67`), #4 (`100...130`), #5 (`0.6...1.1`) and #6 (`2.0...3.1`)
unchanged and mark them provisional.** They are plausible against general knowledge of the modern
NFL and nothing I found contradicts them, but they are not verified here. Verification is a
five-minute job on an unrestricted machine and belongs on the owner's checklist.

#### 3.4 Kicking

- NFL kickers attempted a **league-record 1,115 field goals in 2024 and made 84%**. **[Q]** (Sportico)
- Their **69.9% rate on 50+ yard attempts** was the highest single-season mark since at least 1991. **[Q]**
- Cameron Dicker's 93.8% is the best career mark by a kicker with 50+ attempts. **[Q]**

Band #7 is `80...90`, centred well above the observed 84%.

**Verdict: narrow band #7 to `81...88`.** And add a **distance-conditioned** sub-band, because a
model can hit 84% overall while being wildly wrong about the distance curve — which is exactly the
input to every fourth-down decision the player makes (**D1**). Target: 50+ yard accuracy `0.62...0.72`.

#### 3.5 Home advantage — the inherited band is right for the wrong era

- From 1970 to the early 2010s, NFL home teams won **57–60%** of games. **[Q]** (Covers, PFF)
- Since 2019 that has dropped to **52–53%**. **[C]** (Covers; PFF; Yahoo Sports)
- **2023: under 52%.** **2022: 56.7%.** **2019: 52%**, the lowest since 1972. 2024 was the fourth
  season in six at **≤53%**. **[Q]**

Band #9 is `0.50...0.60`. The top third of that band describes a league that has not existed since
2018.

**Verdict: shift band #9 to `0.50...0.58`.** More importantly, this figure is now the single
sharpest pro/college discriminator in the whole document (§4.4).

#### 3.6 Explosive plays — re-base the metric, not just the band

Public analytics uses two conventions, and neither is the project's:

- **PFF:** a run of ≥10 yards *or* a pass of ≥15 yards. **[Q]**
- **Common analyst usage:** a run of ≥10 yards *or* a pass of ≥20 yards. **[Q]**
- Measured NFL rates: **explosive run rate 11.8%, explosive pass rate 13.7%.** **[Q]** (PFF, in a
  college-versus-NFL comparison)

The project uses "any play ≥25 yards" and counts them per game (band #12, `3...9`). That number can
never be checked against any published figure. It is a self-referential band: it asserts the engine
agrees with itself.

**Verdict: replace band #12 with two rate metrics on the public definitions** — explosive run rate
and explosive pass rate — which are directly comparable across both tiers and against published
sources. Keep the 25-yard count as a *diagnostic* readout, not a gate.

#### 3.7 Fourth-quarter share, ties, overtime

- Q4 scoring share (band #11, `0.22...0.32`): the second quarter is historically the NFL's highest-
  scoring, with the fourth next, driven by two-minute drills; the first and third are lower. **[P]**
  (Boyd's Bets). A ~0.25–0.28 share for Q4 is consistent. **Retain.**
- Tie rate `< 0.03` (`:245`): correct in kind for the NFL, where ties are legal and rare. **Retain.**
- Overtime rate (band #8, `0.008...0.14`): I could not source the true NFL rate. **[U]** The band spans
  a factor of seventeen, which cannot be right whatever the answer is. **Flag for the owner to set
  from a single Pro Football Reference season summary**; my working assumption is ~5–6% of games.
  **[ASSUMPTION]**

#### 3.8 Competitive balance — add the metric that is missing

- NFL money-line favourites won **66.6%** of games over 2018–2024 (1,013–508–7). **[Q]** (NxtBets)
- In 2024 specifically, favourites won **71.7%** straight up, the third-highest mark since 1980. **[Q]** (ESPN)
- Blowouts (margin ≥17 points) were **21.6%** of all NFL games from 2015 to 2024 — 594 games. **[Q]** (Betting.us)
- Roughly **half** of NFL games are one-score games. **[P]** (NFL Analytics)

The inherited suite has no favourite-win-rate metric at all. `:298` measures only the extreme
best-versus-worst matchup, which is a tail case that occurs about twice a season.

**Verdict: add "favourite win rate" as a first-class pro band, `0.62...0.72`**, and add
**"blowout rate (margin ≥17)", `0.17...0.26`**. Convert `:298` from `>= 0.72` to the two-sided
`0.72...0.88`, so a deterministic engine fails.

---

### 4. COLLEGE tier — the genuine gap

Nothing in the existing suite is a college band. Every number in §1 was set against professional
football. The differences below are not tuning offsets; several are **structural**, meaning the
engine's rules model has to change before any band is reachable.

#### 4.1 The clock rule — establish it, because it drives everything downstream

**The current rule: the game clock continues to run after a first down is gained, except in the last
two minutes of either half, where it stops.** **[C]** — NCAA.org, ESPN, CBS Sports, KSL, NCAA.com all
report the same rule.

Provenance and scope, which matter:

- Adopted for the **2023 season**. Before that, and continuously **since 1968**, the college clock
  stopped after every first down. **[Q]** (DraftKings Network; ESPN)
- Adopted by **Division I (FBS and FCS) and Division II. Division III did not adopt it.** **[Q]** (NCAA.org)
- Adopted alongside two related changes: **consecutive team timeouts are prohibited**, and
  **penalties at the end of the first and third quarters carry over** to the next quarter. **[Q]**
- The rules committee expected it to *"modestly"* reduce play counts; The Athletic's reporting put
  the estimate at **fewer than 10 plays per game**. **[Q]**
- A **two-minute warning** was subsequently added to the college game. **[P]** (Sports Enthusiasts;
  National Football Foundation's 2024 rule-change summary) — the owner should confirm the exact
  season before the clock model is written.

**Measured effect:** combined plays per game fell about **five per contest** versus 2022. **[Q]** (CBS Sports)

**Design consequence, and it is a big one.** A college clock model that stops on first downs — the
obvious thing to write if you build the college tier by copying the pro tier and changing the
constants — produces roughly 10 extra plays per game. That is ~7% more snaps, which compounds
directly into **P4's season time budget** and into **§4's presentation-time arithmetic**. The clock
rule is a first-class engine requirement, not a detail.

#### 4.2 Tempo and play volume — and a counting-convention trap

- Combined plays per game are **approximately 175**, down about five from 2022. **[Q]** (CBS Sports)
- A separate report put early-2024 (Weeks 0–2) at **about 127.5 plays between both teams**, with
  regulation games spanning **105 to 145** plays. **[Q]**
- Average game length in 2024 **rose to 3 hours 27 minutes** despite fewer plays — tied for the
  second-longest since the NCAA began tracking in 2008. **[Q]** (CBS Sports)

**These two figures cannot both be scrimmage plays.** 175 combined ⇒ 87.5 per team, which is above
the fastest tempo offences in the sport; 127.5 combined ⇒ ~64 per team, which is essentially the NFL
rate and too low for college. The most likely reconciliation is that **175 counts all plays including
kickoffs, punts, PATs, field goals and penalties, while 127.5 counts scrimmage plays only.** I could
not confirm this. **[U]**

**This is a definition-of-done item, not a band.** The builder must fix the counting convention
*before* setting the play-volume band, and the harness must name the convention in the metric's
definition. Getting this wrong in either direction breaks **D4**'s week-advance budget and **P4**'s
season budget by 30%.

**Provisional band, marked as such:** college offensive plays per team-game **`67...75`**, on the
scrimmage-play convention. **[ASSUMPTION]** — derived by taking the NFL's ~62–64 and adding the
tempo differential implied by college's higher scoring at similar yards-per-play, not read off a
source. It must be replaced with a sourced figure.

**Design consequence for §4 and P4.** The game-length figure is the one to sit with: **3h27m** for
college against roughly 3h05m for the NFL. If the 2D match view is watched at anything like real
time, the college tier is *structurally more expensive per game* than the pro tier, on top of having
more of them off-screen (**D3**: ~65 games a week versus ~15).

#### 4.3 Scoring

- Average college football game total is **around 57 points**, against a professional average of
  **45.7**. **[Q]** (Boyd's Bets)
- **55 is the single most common total**, landing 3.32% of the time since 2000 and **3.98% over the
  last five years** — scoring is rising. 65 points landed 2.22% overall and **2.63%** over the last
  five. **[Q]**
- Per-team scoring averages: **30.04 in 2016** (the first season above 30, an all-time record) and
  **29.56 in 2018**. **[Q]** (CBS Sports)

57 combined ⇒ **28.5 points per team-game**.

**College band: points per team-game `26...31`.** **[C]** — the 2016 and 2018 figures anchor the top,
and the Boyd's Bets average anchors the middle. Compare the pro band of `20...26`: **the two bands
barely overlap**, and the overlap region (26) is the extreme tail of one and the floor of the other.
A shared scoring model with a tuning constant will not produce both.

**Secondary band: combined game total `52...60`**, with the *modal* total at 55 ± 3 as a
distributional check (§6.3).

#### 4.4 Home advantage — the sharpest discriminator in the document

- College home teams have won roughly **64%** of games over the past decade; **2023 was 63.6%**, with
  an average point differential of **+4.1** against fellow FBS opponents. **[Q]** (Beyond the Score)
- **2001–2011: 62.8%.** **[Q]** (Bleacher Report)
- Bookmakers assign about **3.0 points** to a college home team against **2.0** in the NFL. Analytical
  estimates of the true value cluster around **2.6 points**, with one opponent-quality-controlled
  study putting home teams **+3.5**. **[C]** (VSiN; Boyd's Bets; Sports Insights)

**College band: home win rate `0.60...0.68`.** Against the pro band of `0.50...0.58`, these
**do not overlap at all**.

This is the cleanest evidence in the document that the two tiers cannot share a calibration. It is
also a warning about the naive implementation: if the engine models home advantage as a single
`homeFieldForOffense` boolean with one magnitude (as `PlayResolver.resolve` does today), the college
tier needs roughly **50% more** home effect than the pro tier, and that constant has to be tiered.

#### 4.5 Talent dispersion in outcomes — blowouts, favourites, and why the marginal band lies

- **College favourites win 74.8% of regular-season games straight up since 2005, and 74% since
  2018.** **[Q]** (BetMGM) Against the NFL's **66.6%** (2018–2024) **[Q]**, college is markedly less
  balanced.
- In the College Football Playoff era, **46.85% of Big Ten conference games** were blowouts (margin
  ≥17). **[Q]** (CBS Sports) Against **21.6%** of all NFL games. **[Q]**
- **Eight of twelve** CFP semifinals were decided by ≥17, average margin **21.25**. **[Q]**

And then the finding that reshapes the harness:

- After Week 3 of 2024, the FBS average winning margin was **25.5 points** — the widest since at
  least 2000 — and **28.9** when a power-conference team was involved. **[Q]** (Yahoo Sports / AP)
- By Week 5 the FBS weekly average margin was **14.2**, the narrowest since Week 7 of 2022 (12.5). **[Q]**
- Over the same 2024 season, **SEC conference games averaged a 10.0-point margin**, on pace for the
  slimmest of any power conference since 2000 — essentially identical to the **NFL's 10.1** at the
  same point. **[Q]**
- *"Variance in the margin of victory is much greater when looking at college football… the top nine
  [margin] key numbers for FBS scores equates to 41%, nearly double that of the NFL."* **[Q]**

**Read those together.** College conference games are about as close as NFL games. College
non-conference games in September are not remotely close. **The marginal college margin distribution
is a mixture, and its mean describes no real game.**

**Design consequence, and this is the §2.4 fix made concrete:** the college calibration harness must
stratify. Asserting "average margin ∈ [14, 22]" league-wide is worse than useless — a model that
makes every game a 17-point win passes it, and so does a model that alternates 40-point and 3-point
games in the wrong contexts.

| Stratum | Average margin band | Blowout rate (≥17) band | Confidence |
|---|---|---|---|
| Non-conference, mismatched (power vs non-power) | `22...32` | `0.55...0.75` | **[P]** from the 28.9 figure |
| Conference games, power conference | `10...16` | `0.30...0.45` | **[C]** from SEC 10.0 and Big Ten 46.85% |
| Conference games, non-power | `12...18` | `0.35...0.50` | **[ASSUMPTION]** |
| Postseason / playoff | `14...24` | `0.45...0.70` | **[Q]** from the CFP figure |

**College band: favourite win rate `0.70...0.78`.** **[C]**

#### 4.6 Kicking — college kickers are materially worse

- FBS kickers made **75.6% in 2024**, **75.2% in 2023**, **76.6% in 2022**, and **73.9% across
  2016–2020**. 2024 was the fourth straight season above 75%. **[Q]** (CBS Sports)
- A second figure from the same reporting: **1,771 of 2,291 = 77%** across FBS. **[Q]** — probably a
  different game-set (bowls included, or FBS-vs-all rather than FBS-vs-FBS). The discrepancy is
  small and does not change the band.

**College band: field goal percentage `72...79`.** Against the pro band `81...88`, again **no
overlap**. A shared kicking model needs a tiered accuracy constant, and the fourth-down decision
logic that consumes it will produce visibly different coaching behaviour between tiers — which is
correct and desirable, and worth surfacing in the UI.

#### 4.7 Ties and overtime — a structural rule difference, not a band

- **College football has no ties.** There is no limit on overtime periods, and from the **third**
  overtime onwards teams alternate two-point conversion attempts, which is structured to force a
  differential. **[C]** (ESPN; CBS Sports; NCAA.com)
- Since 2021, the **mandatory two-point try moved to the second overtime** and the alternating
  two-point shootout to the third. Before that, 2019 rules put the shootout at the fifth. **[Q]**
- **Over 71% of overtime games are settled in a single overtime**, with only a handful going past
  two. **[Q]**
- The rule lineage traces to Texas A&M 74–72 over LSU (24 Nov 2018), a seven-overtime game lasting
  almost five hours. **[Q]**

**College assertion, not a band: tie rate is exactly `0`.** This is a rules invariant, and it should
be asserted as `== 0` over the full sample, in the same category as "playoff games never tie"
(`GameSimulatorTests.swift:256`) rather than as a calibration band.

**And a save-size / soak consequence worth naming:** an unbounded-overtime rule means an unbounded
play log. `docs/STATUS.md:64` records the 8.3 MB → 2.3 MB save-growth lesson and **D7** demands every
unbounded collection be named with a bound. **The college overtime play log is one of them.** A
pathological seed producing a seven-overtime game must not be able to produce an unbounded
`GameRecord`.

#### 4.8 Explosive plays

- **College: 15.1% of rushing attempts gained ≥10 yards; 14.3% of pass plays gained ≥15 yards.**
- **NFL: 11.8% and 13.7% respectively.** **[Q]** (PFF)

**College bands: explosive run rate `0.135...0.165`; explosive pass rate `0.128...0.158`.**
**Pro bands: `0.105...0.130` and `0.125...0.150`.**

Note the shape: the *run* gap between tiers is large (15.1 vs 11.8, a 28% relative difference) and
the *pass* gap is small (14.3 vs 13.7). An engine that models the tier difference as a single global
"college is more explosive" multiplier will get the pass rate wrong. The difference is concentrated
in the run game — which is what you would expect from wider talent dispersion along the defensive
front seven, and it is a nice example of a calibration target that also tells you something true
about the sport.

#### 4.9 What I could not source for college

Completion percentage, sacks per game, interceptions per game, passing and rushing yards per game,
and points per drive — all blocked at `teamrankings.com`, `ncaa.com` and `sports-reference.com`. **[U]**

These bands are **left unset**. I have deliberately not guessed them. An unsourced band that looks
authoritative is worse than an absent one, because the builder will implement to it. §8 lists them as
open items with the exact page each can be read from in under a minute on an unrestricted machine.

---

### 5. Talent dispersion across ~134 FBS programmes

**D6** and the promotion arc both rest on this. If the generated college league is as flat as the
generated pro league, the college tier is a 134-team version of the pro tier with different words on
the buttons — and the promotion arc has no gradient to climb.

#### 5.1 What the real distribution looks like

**SP+** is *"a tempo- and opponent-adjusted measure of college football efficiency"* whose ratings
express *"how many points better (positive) or worse (negative) a team is than the average FBS team
in a given year."* It is explicitly predictive, not a résumé ranking. **[Q]** (ESPN / Bill Connelly)

Final 2024 SP+:

- **Ohio State finished No. 1**, with a preseason rating around **+30.8**. **[P]**
- **Kent State finished last at −33.0**, and was **8.2 points worse than the second-worst team**. **[Q]**
- Bill Connelly's "Top 764" exercise — every team in college football at every level, ranked on one
  scale — put multiple **FBS programmes below Division II and NAIA teams**: *"Harding > New Mexico,
  Ferris State > Temple, Ouachita Baptist > Kent State."* **[Q]**

**The spread from best to worst FBS team is therefore roughly 64 points per game.** Two randomly
chosen FBS teams can differ by more than nine touchdowns of expected margin.

For calibration of the pro tier, the equivalent spread is on the order of 20 points. **The college
talent distribution is about three times as wide.**

#### 5.2 The blue-chip ratio — the shape at the top

Bud Elliott's Blue-Chip Ratio, introduced in 2013, holds that a programme must sign a **majority
(>50%) of blue-chip (4- and 5-star) recruits** over a rolling window to be able to win a national
championship. **[Q]**

- **Every national champion since 2011** has had a roster over 50% blue-chip. **[Q]**
- **16 of 134 teams** qualified in 2024; **18** in 2025. **[Q]** (CBS Sports; Saturday Down South)
- The measure counts high-school talent only and **excludes the transfer portal**. **[Q]**

**This is the single most design-relevant statistic in the document for D6 and the promotion arc.**
It says the real distribution is not a bell curve with a long tail — it is a **hard-edged tier
structure**: roughly **12% of programmes are structurally capable of winning the title, and 88% are
not**, and that boundary is stable across more than a decade.

#### 5.3 What the generator must produce

The pro generator's bands (`GenerationTests.swift:221–223`) are: worst team `50...75`, best team
`75...95`, spread `> 8`. On a 40–99 rating scale that is a compressed, near-uniform league — correct
for the pro tier, and **badly wrong for college**.

Required properties of the college rating distribution, each stated as a testable target:

| Property | Target | Derived from |
|---|---|---|
| Best-to-worst team-strength spread | ~3× the pro spread, in the engine's own strength units | §5.1, SP+ ±31 vs NFL ~±10 |
| Share of programmes that are title-capable | `0.10...0.15` of 134 (i.e. 13–20 teams) | §5.2, 16/134 and 18/134 |
| A structural gap, not a smooth tail | The title-capable tier is separated by a visible discontinuity | §5.2, the stability of the 50% threshold |
| An extreme bottom tail | The worst programme is far below the second-worst | §5.1, Kent State 8.2 points clear of 133rd |
| Favourite win rate emerging from it | `0.70...0.78` | §4.5 |
| Blowout rate in mismatches | `0.55...0.75` | §4.5 |

**The last two rows are the point.** Dispersion is not calibrated by asserting on the rating
histogram — a generator can produce a beautiful histogram that the match engine then flattens. It is
calibrated by asserting that **the season that falls out** has the right favourite-win and blowout
rates. The rating distribution is the input; the outcome distribution is the test.

#### 5.4 Consequences for other decisions

- **D6 (fictional identity).** A tier structure this hard-edged is *good news* for manufacturing
  emotional payload from original IP. "Blue-blood / established / rising / commuter school" is a
  real structural feature of the sport, not a flavour label, and it can carry recruiting, facilities,
  fanbase and expectation mechanics that all point the same way.
- **The promotion arc (P2).** A 134-programme league with a 64-point spread gives the career an
  enormous natural gradient: take a bottom-tier job, climb. The pro league has no equivalent
  gradient — which argues that college is where the *career* story lives and the pro league is the
  destination, not a parallel sandbox.
- **D8 (jeopardy).** If favourites win 74% of college games, a coach at a bottom-tier programme who
  goes 4–8 has *met expectations*. Job security must be scored against **programme-relative**
  expectation, not absolute wins, or every low-tier save ends in a firing and the carousel churns
  meaninglessly.

---

### 6. Acceptance bands — the harness specification

This section is written to be implementable without further design work, per the §8 definition of
done. It specifies the sample, the metric definitions, the statistical test, and the pass/fail rule.

#### 6.1 Sample specification

```
CalibrationRun {
  tier:        .pro | .college
  ladder:      [UInt64]      // fixed, ordered, in source
  gamesPerSeed: Int
  contextMix:  [GameContext: Double]   // college only; matches the real schedule shape
}
```

- **Seed ladder.** 24 seeds, fixed literals in the harness source. **Ladder A = seeds[0..<12]
  (calibration, may be used for tuning). Ladder B = seeds[12..<24] (holdout, gate only, never used
  for tuning).** A comment in the source states this, because the rule is unenforceable by code and
  entirely enforceable by discipline.
- **Sample size: 2,000 games per tier per ladder.** Derived, not guessed: for a rate near p = 0.63,
  a 90% CI half-width of 0.02 requires `1.645 · √(0.63·0.37/N) ≤ 0.02` ⇒ **N ≥ 1,575**. For points
  per team-game with a per-team SD near 10, a half-width of 0.3 requires ~3,000 team-games ⇒
  **N ≥ 1,500**. 2,000 clears both with margin. The existing 600 does not clear either.
- **Cost.** At the inherited `< 20 ms` per game budget (`GameSimulatorTests.swift:314`), 2,000 games
  × 2 tiers × 2 ladders = 8,000 games ≈ **160 s worst case**. That is more than the entire current
  suite's ~100 s runtime, so **calibration is a separate target from the unit suite** and runs on the
  phase gate, not on every save. **D11** must account for this.
- **College context mix.** The college sample is drawn to match a real schedule's composition, not
  uniformly at random. Provisional mix: 25% non-conference, 65% conference, 10% postseason.
  **[ASSUMPTION]** — replace with the actual composition once the college calendar in `02` is fixed.

#### 6.2 Test 1 — scalar metrics: equivalence by TOST

For a metric with point estimate θ̂, standard error SE, and acceptance band [L, U]:

```
CI90 = [ θ̂ − 1.645·SE , θ̂ + 1.645·SE ]
PASS ⟺ CI90 ⊆ [L, U]
```

This is the **two one-sided tests (TOST)** procedure at α = 0.05: a (1−2α) confidence interval
contained within the equivalence bounds is exactly equivalent to rejecting both one-sided nulls.
Named test, so **D3**'s "with the statistical test named" is satisfied.

Standard errors:

- **Rates** (home win, favourite win, blowout, completion, explosive, FG): `SE = √(p̂(1−p̂)/n)`, n =
  the number of *trials for that metric* (games, attempts, plays) — not the number of games in the
  sample.
- **Per-team-game means** (points, yards, sacks, plays): `SE = s/√m`, s = sample SD across team-games,
  m = team-games. **The harness must compute s, not assume it.** An engine with realistic means and
  unrealistically low variance is a classic and invisible calibration failure; computing s makes it
  visible even before §6.3 catches it.

**Failure message contract.** On failure the harness prints metric, θ̂, CI90, band, n, and **which
edge was violated**. `expectIn`'s current message (`TestKit.swift:112`) prints value and range but not
n or CI, which is why a noise failure and a real failure look identical today.

#### 6.3 Test 2 — distributional shape: total variation distance

Means are not enough. Two engines can agree on average margin and disagree completely about whether
football is a game of 3-point and 40-point results or a game of 17-point results every week — and
that difference is precisely what the player experiences.

For a binned distribution with observed proportions **p̂** and target proportions **q** over k bins:

```
TVD = ½ · Σᵢ |p̂ᵢ − qᵢ|
PASS ⟺ TVD ≤ τ
```

**Use TVD, not a chi-square p-value, as the gate.** At n = 2,000 a chi-square test rejects on
deviations far too small to matter, so gating on "fail to reject" would make the harness stricter as
the sample grows — the opposite of what is wanted. TVD is an effect size: it answers "how far off is
this", which is the actual question. Chi-square and its per-bin residuals are still **reported** as
diagnostics, because the residuals tell the builder *which* bin is wrong.

Distributions to gate, with bins and τ:

| Distribution | Bins | τ | Tier |
|---|---|---|---|
| Margin of victory | 1–3, 4–7, 8–10, 11–13, 14–16, 17–20, 21–27, 28–34, 35+ | 0.06 | both, **per context stratum** in college |
| Team score | 0–9, 10–16, 17–20, 21–23, 24–27, 28–30, 31–34, 35–41, 42+ | 0.06 | both |
| Combined game total | ≤37, 38–44, 45–51, 52–58, 59–65, 66+ | 0.06 | both |
| Drive outcome | TD, FG, punt, turnover, downs, end-of-half | 0.05 | both |
| Play gain | loss, 0, 1–3, 4–6, 7–9, 10–14, 15–19, 20–29, 30+ | 0.05 | both |
| FG accuracy by distance | <30, 30–39, 40–49, 50+ | 0.05 | both |

The **target vectors q are small tables of constants — roughly 50 numbers in total** — which is the
form that matters legally (§7): they are derived facts, not a dataset, and they carry no team,
player or school identity.

**Modal-total check (college).** Additionally assert that the modal combined total bin contains 55,
per §4.3. This is a cheap, sharp check on the shape of the scoring model, and it is the kind of
assertion that catches a model whose mean is right and whose distribution is a lump.

#### 6.4 Test 3 — two-tier consistency (D3)

**D3** requires the abstracted off-screen model and the detailed model to agree within stated bands,
with the test named. Specify it as:

- Run **both** models over the **same fixture set**: the same 2,000 matchups, same seeds, same tier.
- For every scalar metric in §6.5: `|θ̂_fast − θ̂_full| ≤ ½ · (U − L)` — the fast model must sit within
  half the acceptance band's width of the detailed model.
- For every distribution in §6.3: `TVD(p̂_fast, p̂_full) ≤ τ`, the same τ.
- **Both models must independently pass §6.2 and §6.3 against the public targets.** Agreeing with
  each other while both being wrong is a failure mode this test would otherwise miss.

This gives **D3** a concrete, named, implementable consistency requirement.

#### 6.5 The band tables

Every band is stated as `[L, U]`, tested by §6.2 TOST. **Confidence** is the §0.1 grade of the
evidence the band rests on. Bands marked **provisional** are unverified and must be confirmed by the
owner before the gate is treated as meaningful.

##### PRO tier

| Metric | Band | Δ from inherited | Confidence |
|---|---|---|---|
| Points per team-game | `20.0 … 26.0` | retain | **[C]** |
| Pass yards per team-game | `185 … 245` | **widened** — 192.7 was below the old floor | **[Q]** |
| Rush yards per team-game | `100 … 130` | retain | provisional **[U]** |
| Completion percentage | `61 … 67` | retain | provisional **[U]** |
| Interceptions per team-game | `0.6 … 1.1` | retain | provisional **[U]** |
| Sacks per team-game | `2.0 … 3.1` | retain | provisional **[U]** |
| Field goal percentage | `81 … 88` | **narrowed** from `80…90` | **[Q]** |
| FG percentage, 50+ yards | `0.62 … 0.72` | **new** | **[Q]** |
| Home win rate | `0.50 … 0.58` | **shifted down** from `0.50…0.60` | **[C]** |
| Favourite win rate | `0.62 … 0.72` | **new** | **[C]** |
| Blowout rate (margin ≥17) | `0.17 … 0.26` | **new** | **[Q]** |
| Best-vs-worst win rate | `0.72 … 0.88` | **made two-sided** | **[ASSUMPTION]** on the ceiling |
| Offensive plays per team-game | `60 … 68` | **narrowed** from `55…72` | **[P]** |
| Points per drive | `1.60 … 1.95` | **new** | **[Q]** |
| Q4 share of points | `0.22 … 0.32` | retain | **[P]** |
| Explosive run rate (≥10 yd) | `0.105 … 0.130` | **re-based** from the 25-yd count | **[Q]** |
| Explosive pass rate (≥15 yd) | `0.125 … 0.150` | **re-based** | **[Q]** |
| Touchdowns of 40+ yards per game | `0.2 … 1.2` | retain | provisional **[U]** |
| Safeties per game | `0.005 … 0.05` | **made two-sided** | provisional **[U]** |
| Overtime rate | `0.03 … 0.09` | **narrowed** from `0.008…0.14` | **[ASSUMPTION]** — owner to set |
| Tie rate | `0.000 … 0.020` | **made two-sided** | **[P]** |
| TE target share | `0.15 … 0.26` | retain | **[ASSUMPTION]** |
| RB target share | `0.10 … 0.28` | retain | **[ASSUMPTION]** |
| Max single-receiver target share | `0.22 … 0.45` | **made two-sided** | **[ASSUMPTION]** |

##### COLLEGE tier

| Metric | Band | Confidence |
|---|---|---|
| Points per team-game | `26 … 31` | **[C]** |
| Combined game total | `52 … 60` | **[Q]** |
| Modal combined total | bin containing `55` | **[Q]** |
| Field goal percentage | `72 … 79` | **[C]** |
| Home win rate | `0.60 … 0.68` | **[C]** |
| Favourite win rate | `0.70 … 0.78` | **[C]** |
| Blowout rate, non-conf. mismatch | `0.55 … 0.75` | **[P]** |
| Blowout rate, power conference game | `0.30 … 0.45` | **[C]** |
| Avg margin, non-conf. mismatch | `22 … 32` | **[P]** |
| Avg margin, power conference game | `10 … 16` | **[C]** |
| Avg margin, postseason | `14 … 24` | **[Q]** |
| Explosive run rate (≥10 yd) | `0.135 … 0.165` | **[Q]** |
| Explosive pass rate (≥15 yd) | `0.128 … 0.158` | **[Q]** |
| Tie rate | **exactly `0`** (assertion, not a band) | **[C]** |
| Overtime settled in 1 period | `0.65 … 0.78` | **[Q]** |
| Offensive plays per team-game | `67 … 75` | **[ASSUMPTION]** — blocked on §4.2 |
| Title-capable share of programmes | `0.10 … 0.15` | **[Q]** |
| Completion %, pass/rush yards, sacks, INTs, points per drive | **unset** | see §4.9 |

#### 6.6 Definition of done for §6.4

The calibration work is complete when **all** of the following are true. Each is machine-verifiable
except where marked.

1. `CalibrationHarness` exists as a headless, seeded target, separate from the unit suite, runnable
   by **D11**'s mechanism with no toolchain assumptions beyond it.
2. The seed ladder is a fixed literal in source, split A/B, with the holdout rule written in a
   comment at the declaration site.
3. Every scalar band in §6.5 is gated by §6.2 TOST, and every failure message prints θ̂, CI90, band,
   n and the violated edge.
4. Every distribution in §6.3 is gated by TVD against a target vector held as a named constant table,
   with chi-square residuals printed as a diagnostic.
5. The §6.4 two-tier consistency test passes for both tiers, and both models independently pass 3
   and 4.
6. **Every band marked `provisional` or `[ASSUMPTION]` in §6.5 is either confirmed against its
   source or explicitly re-set by the owner.** *(Owner-verifiable.)*
7. §4.2's play-counting convention is resolved and written into the metric's definition, and the
   college play-volume band is re-derived from a source. *(Owner-verifiable.)*
8. The college overtime play log has a stated bound, per **D7**.
9. No band in the harness is one-sided unless a comment states the physical or rules reason.
10. The harness prints a single-screen summary table on success, not just a pass/fail — because under
    **P5** nobody else is ever going to look at these numbers, and a silent green gate is how a
    calibration quietly rots.

---

### 7. Legal posture — using public data versus shipping it

The brief calls this out specifically, so it gets its own section. **Two postures, and they are not
the same question.**

#### 7.1 Posture A — design and calibration time

**What happens:** a human or an agent reads published league-average statistics, derives a small set
of numeric bands, and writes those bands into a test file.

**What ships:** roughly 50–100 integers and decimals — `0.60...0.68`, `26...31` — plus the target
proportion vectors in §6.3. No names. No team identity. No player identity. No rows. No dataset.

**Assessment.** This is the use of *facts* and of *ideas about how football behaves statistically*.
Individual sporting statistics are not creative expression, and a band derived by a human reading a
league average and choosing an interval is not a reproduction of anyone's database. This is the
posture the project should adopt, and every number in §6.5 was produced this way.

**One discipline point that makes the posture defensible rather than merely arguable:** the bands
must be **derived and rounded, not transcribed**. `0.60...0.68` is a designed interval informed by
63.6% and 62.8%. A shipped table of "2024 FBS home win rate = 0.636, 2023 = ..., 2022 = ..." would be
a transcription of someone's compiled data, and a different question. The §0.2 derivation rule
already enforces this; it is worth knowing *why* it is there.

#### 7.2 Posture B — shipping data

**Out of scope, and each for its own reason.**

| Thing | Why it is out |
|---|---|
| Bundling a play-by-play dataset in the app | Redistribution. Also blows the save-size and binary-size budgets. |
| Any table keyed to real team, school, player or conference identity | **Tier A legal guardrail, absolutely.** Also defeats the name-collision test the guardrail ships as. |
| A runtime call to any stats API | **P1**: offline, zero third-party dependencies. **P3**: no network, no accounts. Structurally impossible in this app. |
| Scraped Sports Reference data in any form | Their licences preclude it (§7.3). |
| Real ratings used as generator seeds ("team 7 is really Alabama") | Reintroduces real identity by the back door — exactly the "wink in the store listing" the guardrail forbids. |

#### 7.3 Source licensing, and what each one permits

| Source | Licence / terms | Design-time use | Shipping |
|---|---|---|---|
| **nflverse / nflfastR data** | Majority **CC-BY 4.0**; **FTN charting data (2022+) is CC-BY-SA 4.0**. Package code is MIT. **[Q]** | Yes | CC-BY requires attribution on redistribution. **CC-BY-SA is share-alike and viral — avoid the FTN subset entirely** rather than reason about whether derived bands trigger it. |
| **CollegeFootballData.com (CFBD)** | API key required for all tiers; free tier **1,000 calls/month**; keys are non-transferable; **"Do not embed it in public repositories or client-side code."** Stated philosophy that core access remains free. **[Q]** | Yes, offline, by a human | **No. An iOS app is client-side code**, so an embedded key is a direct terms violation independent of any copyright question. This alone settles it. |
| **Sports Reference (PFR, CFB)** | *"For some of their datasets, their licences completely preclude any redistribution of the data."* Terms forbid automated access and forbid using material to build a competing database. Most data is third-party licensed, which is why no download is offered. Rate limits: 10 req/min (FBref/Stathead), 20 req/min elsewhere. **[Q]** | Read a page, derive a band. **No scraping.** | **No.** |
| **PFF** | Proprietary, subscription. | Read published articles | **No.** |
| **ESPN / SP+ (Bill Connelly)** | Editorial content, ESPN-owned. | Read for structure and dispersion | **No.** |
| **Betting analytics sites** (Boyd's Bets, BetMGM, VSiN, Covers, TeamRankings) | Editorial. | Read for aggregate figures | **No.** |

#### 7.4 Flagged for counsel — not resolved here

Per the brief, I flag rather than resolve. Three items, in descending order of likely relevance:

1. **Derived constants from a CC-BY-SA source.** If any band is ever derived *specifically* from the
   FTN charting subset rather than the CC-BY portion, does the share-alike term reach a rounded
   interval in a test file? My view is that it does not — a band is a fact-derived idea, not a
   derivative of the database — **but the cheap and correct engineering answer is to not use the FTN
   subset at all**, which makes the question moot. Recommend that, and flag it only so the decision
   is a decision rather than an oversight.
2. **The line between "derived band" and "compiled data".** §6.3 asks for target *proportion vectors*
   over binned distributions — more numbers than a single average, and closer in kind to a small
   compilation. My view is that ~50 rounded proportions describing how football behaves is a long way
   from anyone's database, and that no real identity is present. It is nonetheless the most
   compilation-shaped artefact in the design, and it is the one worth showing counsel.
3. **Fictional teams whose statistical fingerprint tracks a real programme.** If the generator ever
   produces a school whose ratings, conference, geography and history are individually fictional but
   jointly identify a real programme, that is trade-dress adjacent. **The Tier A trade-dress test
   covers colour only.** No test in the package covers statistical or biographical resemblance.
   Flagging this as a gap in the guardrail's test coverage — which is exactly the failure mode
   `AUDIT.md:777` names: *"the test's coverage boundary became the quality boundary."*

---

### 8. Assumptions and unsourced items

Collected so the owner can see what the design rests on.

**Assumptions (mine, not sourced):**

| # | Assumption | Where it bites |
|---|---|---|
| A1 | NFL overtime rate is ~5–6% of games; band set `0.03…0.09` | Band #8, §3.7 |
| A2 | College offensive plays per team-game is `67…75` on the scrimmage convention | §4.2, and through it **P4** and **D4** |
| A3 | The 175-vs-127.5 discrepancy is a counting-convention difference | §4.2 |
| A4 | College sample context mix is 25% non-conf / 65% conf / 10% postseason | §6.1 |
| A5 | Non-power conference margin band `12…18` | §4.5 |
| A6 | The best-vs-worst ceiling of 0.88, and the TE/RB/max-receiver target shares | §6.5 |
| A7 | The bin edges and τ values in §6.3 are designed, not fitted to any published binning | §6.3 |

**Sourced but single-source or ambiguous [U]:**

- NFL rush yards, completion %, sacks, INTs per game — retained from the inherited suite, unverified.
- College completion %, pass/rush yards, sacks, INTs, points per drive — **unset**, not guessed.
- The exact season the college two-minute warning was adopted.
- Whether the FBS field-goal figure is 75.6% or 77% (different game-sets; immaterial to the band).

**Each unsourced pro band is one page-load away on an unrestricted machine:**
`pro-football-reference.com/years/2024/` and `sports-reference.com/cfb/years/2024-team-offense.html`
carry every missing figure between them.

---

### 9. Sources

Every URL below was surfaced by WebSearch. **None could be fetched directly from this container**
(§0.1), so all are cited as the search layer rendered them and are marked for owner re-verification.

**Licensing and terms**
- nflverse data licensing (CC-BY 4.0 / CC-BY-SA 4.0 for FTN; MIT code) — https://nflverse.nflverse.com/ , https://github.com/nflverse/nflfastR/blob/master/LICENSE.md , https://nflfastr.com/
- CollegeFootballData terms and API tiers — https://collegefootballdata.com/terms , https://collegefootballdata.com/api-tiers , https://collegefootballdata.com/key
- Sports Reference data use and bot traffic policy — https://www.sports-reference.com/data_use.html , https://www.sports-reference.com/termsofuse.html , https://www.sports-reference.com/bot-traffic.html

**Pro tier**
- NFL 2024 scoring decline (21.4 ppg, passing 192.7) — https://www.nbcnews.com/sports/nfl/nfl-scoring-2024-season-offense-passing-down-rcna171985
- NFL league scoring averages by year — https://www.statmuse.com/nfl/ask/nfl-league-average-points-per-game-by-year-2001-to-2024
- NFL 2024 kicking (1,115 attempts, 84%, 69.9% from 50+) — https://www.sportico.com/leagues/football/2024/nfl-stats-kickers-brandon-aubrey-1234800530/ , https://conormclaughlin.net/2025/01/visualizing-nfl-kicker-accuracy-trends-1999-2024/
- NFL home-field advantage decline (52–53% since 2019) — https://www.covers.com/nfl/home-field-advantage , https://www.pff.com/news/nfl-home-field-advantage-pff-data
- NFL blowout rate (21.6%, 2015–2024) — https://www.betting.us/blog/nfl-blowout-stats-revealed/
- NFL one-score games — https://nflanalytic.com/explainer-one-score-games.html
- NFL favourites straight up (66.6% 2018–24; 71.7% in 2024) — https://nxtbets.com/most-consistent-nfl-betting-trends-for-2025/ , https://www.espn.com/espn/betting/story/_/id/43235257/nfl-betting-favorites-verge-completing-historic-season
- NFL points per drive (1.72) — https://www.stampedeblue.com/2019/8/12/18256932/drive-success-rate-and-other-stats-i-love-points-per-drive-efficiency-td-fg-rate
- NFL scoring by quarter — https://www.boydsbets.com/scoring-by-quarter-in-the-nfl/
- NFL margins and key numbers — https://walterfootball.com/nflmargins.php

**College tier — rules**
- 2023 clock rule, running clock on first downs — https://www.ncaa.org/news/2023/4/21/media-center-football-timing-rules-approved-for-divisions-i-ii.aspx , https://www.ncaa.org/news/2023/3/3/media-center-timing-rules-changes-proposed-in-football.aspx
- Same, reported (last-two-minutes exception; D-I and D-II only; first change since 1968) — https://www.espn.com/college-football/story/_/id/36255797/ncaa-approves-rule-change-run-clock-first-downs , https://dknetwork.draftkings.com/2023/4/21/23692944/ncaa-football-rules-changes-2023-game-clock-runs-on-first-down-no-stoppage , https://www.ncaa.com/news/football/article/2023-08-25/fewer-clock-stoppages-first-downs-and-more-2023-college-football-rule-changes , https://kslsports.com/500700/ncaa-college-football-clock-first-down-rule-change/
- 2024 rule changes summary — https://footballfoundation.org/news/2024/8/22/important-rule-changes-for-the-2024-college-football-season.aspx
- Overtime rules (2-pt at 2nd OT, shootout at 3rd, no ties) — https://www.espn.com/college-football/story/_/id/39111711/what-ncaa-college-football-rules , https://www.cbssports.com/college-football/news/ncaa-changes-college-football-overtime-rules-2-point-tries-required-in-second-ot-then-2-point-shootouts/ , https://www.ncaa.com/news/football/2025-01-01/how-college-football-overtime-works
- Overtime frequency (71%+ settled in one period) — https://lindyssports.com/college-football/college-football-overtime-rules

**College tier — distributions**
- Plays per game down ~5 to ~175 combined; 2024 game length 3h27m — https://www.cbssports.com/college-football/news/despite-running-fewer-plays-college-football-games-are-actually-getting-longer-so-whos-to-blame/
- Early-2024 play counts (127.5 combined; 105–145 range) — https://sportsenthusiasts.net/2024/08/30/is-the-two-minute-warning-impacting-college-football-game-length/
- Average CFB total ~57 vs NFL 45.7; key number 55 — https://www.boydsbets.com/key-numbers-for-college-football-totals/
- CFB scoring records (30.04 in 2016; 29.56 in 2018) — https://www.cbssports.com/college-football/news/college-football-scoring-average-increases-to-highest-ever-in-2016-season , https://www.cbssports.com/college-football/news/college-footballs-offensive-explosion-continued-in-2018-with-more-new-records-set
- CFB field goal accuracy (75.6% in 2024, 75.2% 2023, 76.6% 2022, 73.9% 2016–20) — https://www.cbssports.com/college-football/news/yes-college-kickers-are-getting-better-data-shows-theyre-scoring-more-from-farther-away-than-ever/ , https://www.espn.com/college-football/story/_/id/42213830/2024-college-football-kickers-history-making-field-goals
- CFB home-field advantage (63.6% in 2023; 62.8% 2001–11; 2.6–3.5 pts) — https://beyondthescoresports.substack.com/p/breaking-down-home-field-advantage , https://vsin.com/college-football/determining-college-football-true-home-field-advantage/ , https://bleacherreport.com/articles/1584737-why-college-football-teams-have-the-biggest-home-field-advantage-in-sports , https://www.boydsbets.com/college-football-home-field-advantage/
- CFB favourites straight up (74.8% since 2005; 74% since 2018) — https://sports.betmgm.com/en/blog/college-football/how-often-do-favorites-win-college-football-betting-ncaaf-bm06/
- Big Ten blowout share (46.85%); CFP semifinal margins — https://www.cbssports.com/college-football/news/is-the-college-football-playoff-delivering-on-its-promise-blowouts-lack-of-upsets-suggest-otherwise
- 2024 FBS margins (25.5 after Week 3, widest since 2000; 28.9 with a power team; 14.2 in Week 5) — https://sports.yahoo.com/article/college-football-picks-average-winning-184434064.html
- SEC 10.0 vs NFL 10.1; CFB margin variance — https://www.aol.com/articles/college-football-picks-discussion-turned-160452073.html , https://campus2canton.com/college-football-betting-101-the-fundamentals/
- Explosive play rates, CFB vs NFL (15.1%/14.3% vs 11.8%/13.7%) — https://www.pff.com/news/college-football-most-least-explosive-offenses-of-the-last-five-years , https://www.pff.com/news/nfl-explosive-plays-and-re-thinking-offensive-success
- Explosiveness definitions / IsoPPP — https://www.actionnetwork.com/ncaaf/explosiveness-isoppp-definition-college-football , https://samhoppen.substack.com/p/how-should-we-define-an-explosive
- Drive efficiency by starting field position (CFB) — https://bcftoys.com/all-drives

**Talent dispersion**
- SP+ definition and 2024 finals (Kent State −33.0, 8.2 clear of 133rd; Ohio State No. 1) — https://www.espn.com/college-football/insider/story/_/id/40836337/college-football-2024-preseason-sp+-rankings-takeaways , https://www.espn.com/college-football/insider/story/_/id/43509845/college-football-sp+-rankings-cfp-championship-game
- SP+ "Top 764" cross-division comparison — https://x.com/ESPN_BillC/status/1882050684255961275
- Blue-Chip Ratio (>50% threshold; every champion since 2011; 16 of 134 in 2024, 18 in 2025) — https://www.cbssports.com/college-football/news/blue-chip-ratio-2025-the-college-football-teams-that-have-done-less-with-more-talent/ , https://www.saturdaydownsouth.com/news/college-football/recruiting-expert-identifies-8-sec-teams-with-blue-chip-ratio-to-compete-for-national-championship/
- Conference strength and parity analysis — https://www.forbes.com/sites/giovannimalloy/2024/12/04/college-football-strength-and-parity-sec-depth-big-ten-top-heavy/

**Repository sources (primary, read directly)**
- `Tests/SimTests/Suites/GameSimulatorTests.swift`, `SeasonTests.swift`, `DynastyTests.swift`,
  `GenerationTests.swift`, `ArcadeTests.swift`, `TestKit.swift`
- `Sources/FootballSimCore/Rules/LeagueRules.swift`
- `docs/STATUS.md`

---

## §6.5 — 2D match presentation without direct control

Research part for `docs/reviews/2026-08-09-spec-prompt-v4.md` §6.5. Scope: **how comparable titles
convey what happened on a snap, and what makes a dot-based view legible rather than noise**, under
P1's fixed renderer (SwiftUI `Canvas` + `TimelineView`, iPhone, portrait — **the orientation half of
that constraint was lifted by the owner on 2026-08-10; see §6.5's correction**).

This file **extends** `§6.1 §3` (the FMM match view and its two speed sliders),
`§6.2A §3.3` (the "presentation must be diagnostic" lesson) and `§6.2B`
§4.2 (presentation time as the omitted term in the §4 arithmetic). It does not restate them; where a
claim already lives there it is cited as `→ 6.x §y` and only the new part is written out.

It is written to feed four things: **D2** (what the view can honestly draw), **D4** (frame budget),
**D12** (the accessibility contract, where the `Canvas` is the named hard case) and
`04-UX-AND-DESIGN-SYSTEM.md` (the rendering rules in §10).

---

### 0. Method, and what limits this document

**Two hard limits, stated up front so every claim below can be discounted correctly.**

1. **`WebFetch` is refused by the network egress proxy for effectively every domain this research
   needed** — `zengm.com`, `footballmanager.com`, `footballmanagerblog.org`, `arxiv.org`,
   `operations.nfl.com`, `en.wikipedia.org`, `pmc.ncbi.nlm.nih.gov`. The proxy status endpoint
   confirms the pattern (`connect_rejected … gateway answered 403 to CONNECT`). This is the same
   constraint the §6.1 and §6.2 parts operated under.
   **Two exceptions:** `github.com` is reachable and was read directly, and `developer.apple.com`
   resolves but returns a JavaScript shell with no readable body.
2. **The session's `WebSearch` budget was exhausted at 200/200 calls partway through this part.**
   Research areas 1–5 were covered before the cutoff; the searches I had queued for portrait-mode
   handling in other mobile titles and for Apple's HIG motion wording were not run. The affected
   claims are marked **UNRUN** in §11 rather than quietly padded.

**Consequences, and the marking convention used throughout:**

- Substance from search is reliable; **exact wording and surrounding qualification are not
  guaranteed**, because search returns page-derived text rather than the page.
- Only two documents in this part were read in full: the READMEs of
  [`nfl-football-ops/Big-Data-Bowl`](https://github.com/nfl-football-ops/Big-Data-Bowl) and
  [`asonty/ngs_highlights`](https://github.com/asonty/ngs_highlights). Those two carry more of the
  weight of §4 than anything else, and they are the primary sources here.
- `[Q]` = a phrase surfaced as a direct quotation. `[P]` = paraphrase from search-derived text.
- **DERIVED** = arithmetic or logic performed here from sourced numbers; the inputs are cited, the
  conclusion is mine.
- **ASSUMPTION** = a guess with no source. **UNVERIFIED** = a claim I believe is true and could not
  confirm this session. **UNRUN** = a research question the budget cut off.
  All four are collected in §11.
- **Reddit is unreachable**, as in the sibling parts. Player voice about 2D legibility comes from
  Sports Interactive's own community forums and Steam discussions, which for this specific question
  are a better corpus anyway.

---

### 1. The question, restated as an engineering problem

The brief asks what makes a dot-based view legible. Three constraints collide, and the collision is
the whole design problem:

| Constraint | Number | Where it comes from |
|---|---|---|
| **Perceptual** | A viewer can attentively track ~**4** independently moving objects, and as few as **1** when they move fast or **2–3** when they are tightly spaced | §5, MOT literature |
| **Geometric** | The field is **120 × 53.33 yd** = **2.25 : 1 landscape**; the screen is ~**390 × 844 pt** = **2.17 : 1**. Written when the screen was portrait; since 2026-08-10 it is landscape, and the two ratios being this close is what lets the whole field fit | §6, and §6.5's correction |
| **Budgetary** | Presentation time is the dominant term in the §4 season budget: 6 s/snap × 130 snaps = **13 min of watching per game** before a single decision is priced | → `§6.2B §4.2` |

Twenty-two marks is **5.5× perceptual capacity at the most generous reading and 22× at the least**.
So the design target is not "render 22 players legibly." That target is unreachable and every
comparable title that tried is complained about (§2.2). The target is:

> **maximum diagnostic value per second of screen time, at ≤4 individuated moving marks.**

Everything below is evidence about how the successful titles and the broadcast/analytics conventions
hit that target.

**The single most useful idea in this document, stated once at the top so the rest can be read
against it:**

> **The animation is the play diagram drawing itself.**
>
> There is one visual model per snap — a static play diagram: field strip, line of scrimmage,
> first-down line, ball path, end spot, 2–4 labelled marks. The "animation" is that diagram being
> inked in over ~2 s. Nothing exists in the animation that is not in the diagram.
>
> This collapses five separate features into one code path and one test surface: full-fidelity
> playback (`t` sweeps 0→1), fast-forward (`t` sweeps faster), skip (`t := 1`), low-leverage snap
> (`t := 1`, flashed), and **Reduce Motion** (`t := 1`, no `TimelineView` at all). The terminal
> state is always fully diagnostic, so nothing is lost by any of the four shortcuts, and the
> terminal state is a pure function of the play outcome, so it is trivially testable and trivially
> deterministic.

---

### 2. Football Manager's 2D match view

#### 2.1 What it draws

FM's 2D view is the closest thing to a shipped, mass-market answer to this exact question, and it
has been iterated for two decades.

- **Players are numbered circles in kit colours; the ball is a separate mark.** The 2D view displays
  "dots" moving across the pitch in structured lines, with players represented by **circles with
  their numbers**. [P]
  ([footballmanagerblog.org — FM26 2D camera vs 3D](https://www.footballmanagerblog.org/2025/12/fm26-2d-camera-vs-3d-nostalgia-tactics.html))
- **The pitch is oriented vertically, and its own community says that is why it is readable.** This
  is the finding that matters most for P1's portrait constraint:

  > the **vertical view of the pitch makes it far easier to spot team lines, movements and
  > structural gaps**, functioning like watching a match on a tactical board, with positioning of
  > both your own side and the opposition becoming much more straightforward. [P]
  > ([footballmanagerblog.org](https://www.footballmanagerblog.org/2025/12/fm26-2d-camera-vs-3d-nostalgia-tactics.html))

  Note the direction of the argument: the vertical orientation is not a mobile compromise, it is the
  orientation that reads *better* than the horizontal one for the thing a manager is looking at
  (shape, lines, gaps). See §6.5 — this inverts the framing of P1's portrait constraint from a cost
  into an asset.

  **2026-08-10: this is now evidence *against* the shipping decision, and it is kept for that
  reason.** The app is landscape and the field runs along the long axis, so our line of scrimmage is
  vertical but the direction of attack is not. Whether "easier to spot lines and gaps" transfers from
  a defensive block in soccer to a line of scrimmage in gridiron is unresolved, and `05` P13's owner
  walkthrough is where it gets asked. A finding does not stop being a finding because a decision
  went the other way.
- **On mobile it is the only view.** FMM matches are 2D top-down only; the 3D engine is a
  Touch/PC/console feature. → `§6.1 §3.1`
- **On desktop, "2D Classic" is one of a named camera list** that in FM26 includes *2D Classic,
  Behind Goal, Aerial, Broadcast, Tactical, Dynamic Sideline* and — directly relevant here —
  ***Vertical Scrolling***, with Camera Height, Camera Zoom and Reverse Camera as separate axes. [P]
  ([SI Community — camera/match view setup](https://community.sports-interactive.com/forums/topic/591889-what%E2%80%99s-your-go-to-camera-angle-match-view-setup/),
  [SI Community — 2D Camera](https://community.sports-interactive.com/forums/topic/593877-2d-camera/))

#### 2.2 What FM's own players say is illegible

This is the highest-value part of the FM evidence, because it is complaint data about precisely the
failure mode P1 exposes us to.

| Complaint | Source |
|---|---|
| **"dots moving at 100 mph annoys my eyes"** — motion speed, not mark design, is the named irritant [P] | [Steam — 2d match view on matchday, FM26](https://steamcommunity.com/app/3551340/discussions/0/506217282369896496/) |
| Players want to **select** 2D during highlights rather than have it run constantly, and would prefer **more useful statistics displayed instead** [P] | [Steam — FM26](https://steamcommunity.com/app/3551340/discussions/0/506217282369896496/) |
| Requests to **turn the background 2D view off entirely** during matchday [P] | [Steam — 2D classic match engine, FM26](https://steamcommunity.com/app/3551340/discussions/0/506216918921930920/) |
| **The ball is too big and the player circles are too big** [P] | [SI Community — "2D Match Engine – poor quality"](https://community.sports-interactive.com/forums/topic/594339-2d-match-engine-poor-quality/) |
| A standing forum thread titled **"2D Match Engine – poor quality"** exists at all | [SI Community](https://community.sports-interactive.com/forums/topic/594339-2d-match-engine-poor-quality/) |

Three transferable readings:

1. **Speed is the primary legibility lever.** Nobody complains that there are 22 dots; they complain
   about how fast the dots move. That aligns exactly with the MOT finding that capacity is
   speed-dependent, collapsing to a single trackable object at high speed (§5.2). **A slower
   animation is not a worse animation; up to a point it is a strictly more legible one, and it costs
   season budget linearly.** That trade is the core of D4's frame-budget section.
2. **Mark size is a two-sided failure.** Too small is unreadable; too big is crowding. FM's players
   report the *too big* side. At our scale (§6.3) the offensive line is a crowded cluster by
   construction, so we hit the too-big failure at any legible circle size. This is an argument for
   drawing the line as one aggregate form rather than seven marks.
3. **A meaningful share of players want the 2D view replaced by numbers.** "would prefer more useful
   statistics displayed instead" is a direct statement that, for some players, the readout beats the
   render. → this is the same conclusion `§6.2A §3.3` reached from Bowl Bound's opposite complaint.

#### 2.3 What the camera does — and FM26's most instructive structural move

FM26 rebuilt the match-day experience around **Broadcast mode** and **dynamic highlights**, and put
the classic 2D pitch on a new **Match Overview** screen that appears **between** highlights, with
"live assistant manager advice and expandable data cards" alongside it. [P]
([footballmanager.com — FM26 match day](https://www.footballmanager.com/fm26/features/where-storytelling-evolves-fm26s-match-day-experience),
[footballmanagerblog.org — FM26 match day](https://www.footballmanagerblog.org/2025/09/fm26-match-day-experience-broadcast-mode-dynamic-highlights.html),
[esports-news.co.uk](https://esports-news.co.uk/2025/09/25/football-manager-26-upgraded-match-day-experience-gameplay-revealed/))

Read that carefully, because it is a role reversal:

> **In FM26 the 2D pitch is the ambient, low-attention state display, and 3D is the dramatic one.**
> The 2D view is what you look at *while nothing is happening*, next to advice and data cards. It is
> a dashboard, not a cinema.

We have no 3D. So the 2D `Canvas` has to occupy **both** roles, and it cannot do so with one design.
That argues for two distinct rendering modes in one view — an **ambient state mode** (static field
strip, ball spot, down and distance, drive shape) which is what is on screen most of the time, and a
**play mode** (the diagram inking itself) which fires only for snaps worth watching. The transition
between them is the attention signal.

**A further transferable mechanic already established in `§6.1 §3.1`:** FMM has *two independent
speed sliders* — one for how fast commentary progresses, one for how fast the clock moves when there
is nothing to show. Dead time and dramatic time are tuned separately. Generalised for us that is
**three** independently tunable dwells: pre-snap, snap resolution, post-play. §9 prices them.

---

### 3. Other 2D sports sims: what visual language do they use for a snap?

| Title | What it draws for a play | Lesson for us |
|---|---|---|
| **Football GM (ZenGM)** | **No player-level 2D at all.** During live sim it shows a **drive chart**: the plays of the current drive drawn on top of a football field. Turnovers in **red** with the return shown below; kickoffs and punts as a **grey bar**. [P] | The field is a *coordinate system for outcomes*, not a stage for actors. Bars, not bodies. |
| **Basketball GM (ZenGM)** | Explicitly has **no shot chart**, because *"that would require knowing the 2D position of those events, which is currently not simulated."* [P] | **The engine decides what the view may honestly draw.** See §8 — this is the most important architectural sentence in the document. |
| **Draft Day Sports: Pro Football** | 2D field view with pan/zoom and play-by-play. DDS:PF 26 added **highlight ribbons, rotating stat displays**, and **pan/zoom that tracks the ball and follows plays**. → `6.2a` | The 2026 investment went into **attention direction and readout**, not fidelity. |
| **DDS (community complaint)** | *"animated play-by-play being so laggy it's almost unusable"* — long-standing → `6.2a` | An animation the player has to wait for is worse than no animation. Ties to D4. |
| **Front Office Football** | **Text only.** No 2D field. → `6.2a` | A genre pillar ships zero field rendering. |
| **Bowl Bound College Football** | Complaint: *"calling plays can be frustrating due to lack of play-by-play feedback or analysis to explain why plays work or don't work"* → `§6.2A §3.3` | The failure mode is **non-diagnostic**, not ugly. |
| **Football Coach: College Dynasty** | **Text play-by-play only**, Steam-tagged *Text-Based*; 95–96 % positive of ~1.5 K reviews → `6.2b` | The genre's best-reviewed modern entry renders no field whatsoever. |
| **CFB Simulator** (iOS) | The one mobile football title shipping a field view: **2D field with line-of-scrimmage and first-down lines, plus a play log** → `6.2b`, `01-RESEARCH §A/§H` | Note what it draws: **two lines and a log**. Not players. |
| **Retro Bowl** | Side-scroll pixel 2D for **your offence only**; your defence *"is played out via text boxes."* 40 M+ downloads → `6.2b` | The most successful football game on mobile animates roughly one side of the ball and narrates the other. |
| **Blood Bowl 2** | Top-down turn-based board; every action resolved by dice; **success percentages shown before risky plays**, described as *"information displayed elegantly enough with percentages for success."* [P] ([GameFAQs](https://gamefaqs.gamespot.com/ps4/213591-blood-bowl-2-legendary-edition/faqs/78266/gameplay), [Big Boss Battle](https://bigbossbattle.com/review-blood-bowl-2-legendary-edition/)) | The comprehension device is a **number attached to a mark**, not the motion of the mark. |
| **OOTP** | The **Game Log** *"tells the story of the game in words"*; the box score carries the numbers; 3D is a separate, later, optional presentation layer. [P] ([OOTP manual — Game Log](https://manuals.ootpdevelopments.com/index.php?man=ootp23&page=game_log), [OS review](https://www.operationsports.com/out-of-the-park-baseball-24-review-still-making-worthwhile-improvements/)) | Even in the sim with the largest presentation budget, prose is the primary carrier of meaning. |

#### 3.1 The finding that should change a design decision

> **No successful football management simulation animates 22 players. The ones that draw anything
> draw lines, bars, zones and text.**

Football GM draws bars on a field. CFB Simulator draws two lines. DDS draws a field but spent its
2026 budget on ribbons and stat readouts. FOF and FC:CD draw nothing. Retro Bowl — the commercial
outlier by two orders of magnitude — animates offence and narrates defence.

That is not evidence that a 22-mark view is impossible. It is evidence that **nobody has found it
worth the money**, and that the shipped alternatives are cheap, legible and well-liked. It sets a
high bar for D2: if we animate 22 marks, we must be able to say what that buys that a drawn diagram
does not.

#### 3.2 The ZenGM drive chart is the strongest cheap idea in the genre

It deserves separate mention because it solves a problem we have and FM does not. A soccer match is
continuous; a football game is a **stack of discrete drives**, each a sequence of gains and losses
against a moving target. The drive chart renders the *structure of the drive* — which is the thing a
coach actually reasons about — on the same field coordinate system the play uses, with a two-colour
code (red = turnover, grey = kick) and returns drawn beneath.
([ZenGM — Football GM drive chart](https://zengm.com/blog/2023/11/football-drive-chart/),
[ZenGM — play-by-play redesign](https://zengm.com/blog/2023/11/play-by-play-redesign/))

**DERIVED:** this is the natural *ambient state mode* from §2.3. Between snaps the `Canvas` shows the
drive chart; on a snap worth watching it zooms to the line of scrimmage and inks the play diagram;
when the play ends, the new bar is appended and the view returns to the drive. One `Canvas`, one
coordinate system, two zoom levels, no camera motion during the play itself (§5.4).

---

### 4. Broadcast and analytics convention for American football

#### 4.1 The broadcast angle is the *illegible* one — and that is a licence, not a warning

The reason the All-22 exists is that the standard TV angle physically cannot show the play:

> On many passing plays, **the routes of the wide receivers and the drops of the defensive backs
> will take them off the screen**, preventing even a knowledgeable fan from identifying what sorts
> of coverage or route combinations are being run until an appropriate replay has been shown. [P]
> ([Bleacher Report](https://bleacherreport.com/articles/1242852-all-22-available-for-all-nfl-fans-how-to-use-it-to-your-advantage))

> The traditional sideline angle of television coverage **doesn't let us see what the quarterback
> sees; it lets us see what the people in the expensive seats can see.** [P]
> ([Grantland — The NFL's Holy Grail](https://grantland.com/features/the-film-launch-thousand-questions-sources-offseason-stories/))

All-22 is the wide view showing every player at once; it is what coaches, scouts and players use to
study film, and it reveals **spacing, leverage and timing** that broadcast angles hide. [P]
([NFL.com](https://www.nfl.com/news/nfl-com-to-offer-fans-coaches-film-with-nfl-game-rewind-09000d5d82ac698a),
[NFL Pro / All-22](https://www.nfl.com/news/nfl-week-2-plays-to-rewatch-with-all-22-on-nfl-pro),
[Wolf Sports](https://wolfsports.com/nfl/the-new-all-22-with-nfl-pro-is-a-positive-for-football-fans/))

**Two consequences, and they point in opposite directions — hold both.**

- **In favour of our view:** a top-down frame with all 22 in it is not a poor man's broadcast. It is
  *the analyst's view*, the one that exists specifically because broadcast cannot show the play. P1
  hands us the coaches' angle for free.
- **Against it:** the All-22 is used **paused, scrubbed and rewound**, frame by frame, by people
  studying film — not for live comprehension at speed. Nobody watches All-22 at 1× to enjoy a game.
  A 2 s all-22 animation is therefore not automatically comprehensible just because all the
  information is present. Presence ≠ legibility. **This is the argument for scrub/replay controls
  and for the static terminal diagram being the primary artefact.**

#### 4.2 The most successful comprehension aid in the sport's history is a static line

The virtual yellow first-down line debuted on ESPN on **27 September 1998** (Ravens–Bengals),
invented by Sportvision under **Stan Honey**. It has been *"hailed as one of the most important
developments in sports broadcast technology since the debut of instant replay in 1963"*, nearly every
NFL and college telecast now uses a version of it, and fans **wonder why the line isn't there when
they attend a game in person**. [P]
([ESPN Front Row](https://www.espnfrontrow.com/2013/09/virtual-yellow-1st-and-ten-line-debuted-on-espn-15-years-ago-today/),
[ESPN Press Room](https://espnpressroom.com/feature/virtual-yellow-1st-and-ten-line-debuted-on-espn-15-years-ago-today/),
[National Inventors Hall of Fame — Stan Honey](https://www.invent.org/inductees/stan-honey),
[ETHW — The Making of Football's Yellow First-and-Ten Line](https://ethw.org/The_Making_of_Football%27s_Yellow_First-and-Ten_Line),
[Mental Floss](https://www.mentalfloss.com/article/27009/explaining-magic-yellow-first-down-line))

> The most important legibility invention in American football broadcasting is **a static,
> persistent, non-diegetic 2-pixel line that no player can see.**

It carries no player information, no motion and no fidelity. It answers one question — *how far?* —
and it answers it continuously, without the viewer spending any attention on it. That is the
economic model our `Canvas` should copy: spend the viewer's scarce tracking capacity on the ball and
one matchup, and answer everything else with persistent static annotation.

And note the corroboration: CFB Simulator, the only mobile football title in the competitive set
that ships a field view, draws **the line of scrimmage and the first-down line** (→ `6.2b`). Two
lines. That is what it chose to render.

#### 4.3 The analytics vocabulary, from primary sources

Both READMEs below were read in full — they are the two primary sources in this document.

**Coordinate system and sampling rate** ([`nfl-football-ops/Big-Data-Bowl`](https://github.com/nfl-football-ops/Big-Data-Bowl)):

- Field longitudinal axis **0 → 120 yd**; lateral axis **0 → 160/3 yd (= 53.333 yd)**. This is the
  canonical tracking coordinate system and it is the one our engine should use verbatim.
- Tracking is captured and animated at **10 frames per second**. The tutorial specifies animations
  should match 10 fps "to accurately represent play timing."
- Per player per frame: position `(x, y)`, team, jersey number, player id, frame id.
- Plotting approach: **`geom_point` per player** (i.e. one circle each), **jersey numbers overlaid as
  text labels**, **hash marks and yard-line annotations for field reference**, frame-by-frame render
  synchronised to play duration.

**The augmented vocabulary** ([`asonty/ngs_highlights`](https://github.com/asonty/ngs_highlights),
NGS tracking data 2017–2019):

- `plot_play_frame()` — **a single static frame** of a play is a first-class output, not just a
  by-product of the animation.
- **Velocity vectors**: an optional overlay of directional arrows showing each player's speed and
  direction of travel.
- **Voronoi tessellation**: spatial territories showing which area of the field each player
  controls — explicitly described as *borrowed from soccer analytics*.
- **Animation at 10 fps with velocity vectors, jersey numbers and the ball tracked throughout**, and
  — the detail worth stealing — the example **highlights the fastest player from each team at every
  moment with a yellow glow effect**.
- Colour distinguishes home from away.

**NGS in broadcast**: the tracking system samples player location, speed, distance and acceleration
**10 times per second**, charting movement within inches; the broadcast visualisation track
*"generates an animation, video, or chart that best visualizes the movement of players with the ball
in the air."* [P]
([NFL Operations — performance tracking data](https://operations.nfl.com/game-operations-logistics/technology/performance-tracking-data-next-gen-stats),
[Amazon Science — a decade of NGS](https://www.amazon.science/blog/a-decade-of-nfl-next-gen-stats-innovation),
[NGS animated play diagram](https://nextgenstats.nfl.com/highlights/play/type/team/season/week/playerId/2019092209/2375))

**Three things fall out of that paragraph.**

1. **10 fps is the ground truth of the sport's own instrumentation.** Anything above 10 fps in our
   `Canvas` is interpolation, not information. That is a direct input to D4: the *simulation* tick
   for a rendered snap can be 10 Hz; only the *interpolation* needs 60 fps. Cheap.
2. **"an animation, video, or chart that best visualizes"** — the NFL's own product picks a
   *representation per play*. A deep completion, a screen, a sack and a run are not the same picture.
   This is the strongest argument in the document for **per-play-type presentation templates** rather
   than one generic renderer. §10 rule 6.
3. **Highlight one player per team with a glow.** The analytics community's own answer to "22 marks
   is too many" is to individuate exactly two. That is *within* MOT capacity (§5).

#### 4.4 The minimum visual vocabulary that makes a completion read as a completion

**DERIVED**, from §4.1–4.3 plus the coverage-recognition sources below. This is the answer to the
brief's sharpest sub-question.

A football-literate viewer does not read a pass play as continuous motion. They read it as a
**sequence of five discrete states**:

| # | State | What is read | Sourced anchor |
|---|---|---|---|
| 1 | **Pre-snap** | Formation, and the **coverage shell** — literally *count the deep defenders*, those more than ~8 yd off the line. **One-high** ⇒ Cover 1/3; **two-high** ⇒ Cover 2/4/6, split at ~12–15 yd. Plus **leverage**: is the corner inside or outside the receiver? | [American Football IQ](https://americanfootballiq.com/blogs/news/football-coverages-101-the-ultimate-beginners-guide), [Athletes Untapped](https://athletesuntapped.com/blog/deciphering-the-defense-mastering-football-coverage-recognition/), [The Phinsider](https://www.thephinsider.com/2016/6/27/12039106/football-101-defensive-cover-schemes-aka-how-a-quarterback-reads-a-defense) |
| 2 | **Snap** | The line of scrimmage is fixed; the clock starts; the pocket forms | §4.2 |
| 3 | **Stems** | Route shapes against zone/man assignment — *who has whom*, *where the seams are* | [American Football IQ — reading a defense](https://americanfootballiq.com/blogs/news/how-to-read-a-defense-a-step-by-step-guide-for-high-school-qbs) |
| 4 | **Ball in the air** | **Origin, arc, target.** This is the single event that makes a completion a completion | §4.3, NGS "ball in the air" visualisation track |
| 5 | **Catch point and result** | Where it was caught, yards after, and **where the play ended relative to the first-down line** | §4.2 |

The minimum vocabulary that renders that sequence is therefore:

1. **Line of scrimmage** (persistent line).
2. **First-down line** (persistent line, the yellow-line lesson).
3. **The ball's path, drawn as a persistent stroke** from release to catch point — *not* a moving
   dot that leaves nothing behind.
4. **Exactly two individuated marks** during the ball's flight: the targeted receiver and his nearest
   defender, distinguished from everyone else by glow/size, per §4.3's yellow-glow convention.
5. **The end-of-play spot**, marked, relative to (2).
6. **Pre-snap only:** the number of deep safeties, legible as a count — because that is literally how
   a shell is identified.

Everything else — 18 other players' trajectories, blocking, pursuit angles — is optional detail that
*adds* to a legible picture but cannot *create* one.

> **A completion reads as a completion when the ball leaves a visible trace that terminates at a
> distinguished receiver past a distinguished line.** Dots converging is what you get when you draw
> the players and not the trace.

**Pursuit angles**, which the brief asks about, are the exception worth noting: on a run or a return,
the interesting information *is* the geometry of convergence — the angle a defender takes to a
ball-carrier. That is legible with **two marks and a velocity vector each** (§4.3), and it is
illegible with eleven. It is a per-play-type template (§4.3 point 2), not a general rendering mode.

---

### 5. Legibility research: how many moving marks can a viewer follow?

#### 5.1 The classical capacity

Multiple-object tracking (MOT) is a real and well-established paradigm, introduced by **Pylyshyn &
Storm (1988)**, in which observers track several moving targets among visually identical distractors.
Tracking capacity is *"generally limited to around 4/5 objects."* [P] The original account proposed
**four parallel pre-attentive indexes** (FINSTs). [P]
([Springer — Cognitive Processing, MOT expertise](https://link.springer.com/article/10.1007/s10339-020-00954-y),
[Attentional costs in multiple-object tracking, *Cognition*](https://www.sciencedirect.com/science/article/abs/pii/S0010027708000097))

#### 5.2 The capacity is not a constant — it is set by speed and spacing

**Alvarez & Franconeri (2007), *Journal of Vision*** — "How many objects can you track? Evidence for
a resource-limited attentive tracking mechanism":

- *"At slow speeds it is possible to track up to **8** objects, and yet there are fast speeds at
  which only **a single** object can be tracked."* [P]
- A **logarithmic** relationship between speed threshold and number of targets: as target count goes
  up, the speed at which tracking survives goes down. [P]
- Tracking is set by a **flexibly allocated resource**, not a fixed slot count. [P]

([PubMed 17997642](https://pubmed.ncbi.nlm.nih.gov/17997642/),
[JOV](https://jov.arvojournals.org/article.aspx?articleid=2121950),
[Harvard DASH](https://dash.harvard.edu/handle/1/41056876),
[Semantic Scholar](https://www.semanticscholar.org/paper/How-many-objects-can-you-track-Evidence-for-a-Alvarez-Franconeri/cbf6415cada79bd310b618743b6177b300c979e6))

**Spacing matters as much as speed:**

- *"When the spacing between items was small, requiring precise selection regions, only **2–3**
  locations could be selected. But when the spacing between items was large, allowing selection
  regions to be coarser, up to **6–7** locations could be selected."* [P] (same sources)

**Other constraints established in the same literature:**

- **High inter-individual variability** in the tracking limit. [P]
  ([Springer](https://link.springer.com/article/10.1007/s10339-020-00954-y))
- Tracking is **attentionally costly** — it is not free background perception.
  ([*Cognition* — Attentional costs in MOT](https://www.sciencedirect.com/science/article/abs/pii/S0010027708000097),
  [PMC2430981](https://pmc.ncbi.nlm.nih.gov/articles/PMC2430981/))
- Early-visual-cortex enhancement of tracked stimuli **has limited capacity** — the limit is
  visible in the neural signal, not just in behaviour.
  ([bioRxiv](https://www.biorxiv.org/content/10.1101/2022.09.08.507113.full.pdf))
- **Observer self-motion imposes a measurable load on MOT** — there is a literature specifically
  quantifying it.
  ([PMC3181432 — "How Many Objects are You Worth?"](https://pmc.ncbi.nlm.nih.gov/articles/PMC3181432/))

#### 5.3 What that means for 22 marks on 390 pt — with numbers

**DERIVED throughout; the inputs are §5.1–5.2 and §6.3.**

| Finding | Number |
|---|---|
| Marks on the field | 22 |
| Best-case tracking capacity (slow, well-spaced) | 8 → **2.75× over** |
| Realistic capacity (game-speed motion, mixed spacing) | ~4 → **5.5× over** |
| Worst case (fast motion, tight spacing at the line) | 1–3 → **7–22× over** |

The conclusion is not "fewer players on the field." It is a **two-class rendering rule**:

> **Class 1 — individuated (≤4 at any instant):** the ball, the ball-carrier or passer, the primary
> receiver/target, the decisive defender. These get full marks: distinct fill, glow, optional
> velocity vector, optional label.
>
> **Class 2 — aggregate (the other 18):** never individuated. Drawn as *form*, not as *objects* — a
> single filled shape for the line of scrimmage cluster, a translucent zone for the coverage shell,
> a soft blob for the pursuit mass. Aggregate forms do not consume tracking slots because they are
> not tracked; they are read as texture and boundary.

The Voronoi tessellation from §4.3 is precisely a Class 2 device: it turns eleven objects into one
partitioned surface. So is a coverage-shell shading. So is a single elongated rounded rect for the
line.

#### 5.4 The camera must not move during a snap

**DERIVED.** MOT capacity is measured in a stable reference frame, and the self-motion literature
(§5.2, PMC3181432) shows that adding observer motion *costs* tracking capacity. Camera pan/zoom
during a play introduces global optic flow that the viewer must factor out of every mark's motion
before tracking it. DDS ships ball-tracking pan/zoom (§3) and DDS's presentation is one of its named
complaint areas (→ `6.2a`); FM's complaint is about motion speed (§2.2). Both point the same way.

> **Rule: the camera transform is fixed for the duration of a snap.** Zoom and reposition happen
> *between* snaps, during the ambient state mode, where there is nothing to track. If a play runs
> off the visible window, that is a signal to *change the window before the next snap*, not to chase
> the ball during this one.

This also has a determinism benefit: a fixed transform per snap means the frame at `t` is a pure
function of `(playOutcome, t)` with no view-side state, which is what §8's determinism test needs.

---

### 6. Portrait geometry: the arithmetic

> **Superseded in its conclusion, retained in its method — 2026-08-10.** Everything below computes
> the portrait case correctly and never computes the landscape one; §6.5 carries the correction and
> the scored option E. The current numbers live in `04` §5.2. §6.3 (clustering), §6.4 (no tappable
> marks) and the pt/yd legibility floor are orientation-independent and still govern.

#### 6.1 The two rectangles

| | Long axis | Short axis | Ratio |
|---|---|---|---|
| **Field** (incl. both end zones) | 120 yd | 53.333 yd (160/3) | **2.250 : 1**, landscape |
| **iPhone portrait**, base class | 844 pt | 390 pt | **2.164 : 1**, portrait |

Field dimensions are from the NFL's own tracking coordinate system
([Big Data Bowl](https://github.com/nfl-football-ops/Big-Data-Bowl): x ∈ [0, 120], y ∈ [0, 160/3]).
Device point sizes are **ASSUMPTION** (standard iPhone logical resolutions from memory; the brief
itself states "~390 pt-wide", which is the figure used). Floor case: iPhone SE at **320 pt** wide.

#### 6.2 The near-coincidence, and why it is not quite a fit

Fit the field's **width** to the screen's **width**, rotated so the field's long axis runs vertically:

```
scale = 390 pt / 53.333 yd = 7.3125 pt per yard
full field length = 120 yd × 7.3125 = 877.5 pt
screen height                      = 844 pt
```

**DERIVED:** the whole 120-yard field, rotated vertical and fitted to width, is **877.5 pt** — about
**4 % taller than the entire screen**, before any navigation bar, scoreboard, or controls. So
"whole field, always visible, portrait" is *tantalisingly* close and **does not fit**. Pretending it
does is how you end up with 5 pt/yd and an unreadable line of scrimmage.

Realistic canvas height after chrome (nav + scoreboard + play-call strip + safe areas): **~500 pt**
(**ASSUMPTION**, to be replaced by measurement in `04`). That yields:

```
visible field length = 500 pt / 7.3125 pt·yd⁻¹ = 68.4 yards
```

**68 yards of field length, full 53.3-yard width, at 7.3 pt/yd — with no panning and no zoom.** That
is line of scrimmage ±34 yards, which covers essentially every play's *decision-relevant* geometry:
the throw, the catch, the sticks and the spot. Only long returns and deep bombs exceed it, and those
are exactly the plays that deserve a different template (§4.3).

At the SE floor: `320 / 53.333 = 6.0 pt/yd`, and `500 / 6.0 = 83 yd` visible. Wider view, smaller
marks. **The SE is the binding case for mark size, not for field coverage.**

#### 6.3 Why the line of scrimmage is a crowded cluster by construction

**DERIVED.** Adjacent offensive linemen are roughly 1–1.3 yd apart centre to centre
(**ASSUMPTION** — line splits vary by scheme; the order of magnitude is what matters).

```
7.3125 pt/yd × 1.15 yd ≈ 8.4 pt between adjacent linemen's centres   (390 pt device)
6.00   pt/yd × 1.15 yd ≈ 6.9 pt between adjacent linemen's centres   (320 pt device)
```

A circle carrying a legible **two-digit jersey number** needs roughly an 11 pt font, hence a
~20–22 pt diameter (**ASSUMPTION**, typographic rule of thumb). Even a bare, unlabelled but visually
distinct dot wants ~10–12 pt.

> **Therefore: individually numbered marks on the offensive and defensive lines are geometrically
> impossible in portrait at full field width.** Circles would overlap by 2–3× before a number is
> even drawn. FM's community complaint that "the player circles are too big" (§2.2) is the same
> failure, on a bigger screen, in a sport whose players are *further apart*.

Note the counterintuitive corollary: **ink coverage is not the problem.** 22 marks at 20 pt diameter
is `22 × π × 10² ≈ 6,900 pt²` against a `390 × 500 = 195,000 pt²` canvas — **3.5 % coverage**. The
field is nearly empty. The problem is entirely **local clustering**, which is exactly the variable
§5.2 says collapses selection capacity from 6–7 to 2–3.

This is the strongest argument for the Class 1 / Class 2 split (§5.3): the seven-man line is one
shape, not seven marks, because at this scale it *is* one shape.

#### 6.4 Touch targets

Apple's 44 × 44 pt minimum touch target (**UNVERIFIED** — long-standing HIG guidance, could not be
re-sourced this session) maps to `44 / 7.3125 = 6.0 yards` of field. Across 53.3 yards you fit **8
non-overlapping tap targets**, and they would not line up with where players actually stand.

> **Rule: nothing inside the match `Canvas` is individually tappable.** Player-level interaction
> happens in a list or card below the canvas — which is also where VoiceOver can reach it (§7.2),
> and also what FM26 does with its "expandable data cards" next to the 2D pitch (§2.3). One decision
> satisfies three constraints.

#### 6.5 The options, scored

| Option | What it is | Verdict |
|---|---|---|
| **A. Full field, rotated vertical, always visible** | Attack up-screen, 120 yd fitted to height | **Rejected on arithmetic.** Needs 877 pt of height on an 844 pt screen; with chrome you land at ~4.2 pt/yd, below any legible mark size. |
| **B. Vertical field, zoomed to the line of scrimmage** | Fixed 7.3 pt/yd, ~68 yd window centred on the LOS, recentred *between* snaps | ~~**Recommended.**~~ **Superseded 2026-08-10 by option E.** Full width always in frame; no panning during a play (§5.4); covers ±34 yd; degrades gracefully on SE. |
| **C. Pan/zoom following the ball** | DDS's approach | **Rejected for in-play use**, per §5.4. Retained as a *between-snaps* recentring transition only. |
| **D. Abstract away from geometry** | ZenGM drive chart; field as an outcome axis, plays as bars | **Adopted as the ambient mode** (§3.2), and as the honest fallback if D2 picks a non-positional engine (§8). |
| **E. Rotate the device: full field, landscape, always visible** | 120 yd fitted to the screen's long axis, LOS vertical, offence attacking rightward | **Adopted 2026-08-10 (owner).** 6.54 pt/yd on the base device and 5.56 pt/yd on the SE, whole field in frame, no pan, no recentring. Was never scored in the original table — see the correction below. |

**Correction, 2026-08-10 — the framing inversion below is falsified, and this section is why it took
so long to notice.** The owner set the app to landscape; `04` §5.2 now carries the arithmetic. The
paragraph is retained unedited because it is what the decision was made against, but two of its
claims do not survive contact with the numbers this very section establishes:

1. **"A landscape phone would force either a 2.25:1 letterbox with the width crushed, or horizontal
   panning."** Neither. This was asserted and never computed. The field is 2.250 : 1 and a landscape
   iPhone is 2.164 : 1, so fitting the field's *length* to the long axis leaves its width at 349 pt
   inside 369 pt of usable height. The letterbox is ~20 pt and the width is not crushed at all.
2. **"Portrait … keeps the entire 53.3-yard width in frame at 7.3 pt/yd with no panning."** True, and
   incomplete in the way that matters: it keeps the entire *width* and only **68 of 120 yards** of
   *length*, requiring a recentre between snaps. Landscape keeps both axes whole for an 11 % cut in
   mark size. §6.2 does the portrait arithmetic to four significant figures and never once ran the
   same three lines for the other orientation — an options table that scores four variants of one
   orientation and zero of the other was answering a narrower question than its heading claims.

What survives untouched: §6.3's clustering result (landscape gives ~7.5 pt between adjacent linemen
against portrait's ~8.4 pt — same order, same conclusion), §6.4's no-tappable-marks rule, and the
Class 1 / Class 2 split. The orientation changed; the legibility argument did not.

**The original framing inversion, retained as written:**

> **Portrait is an advantage for American football, not a constraint.** The sport's meaningful axis
> is the long one — down, distance, progress toward a goal line. Portrait gives you that axis
> vertically at full length *and* keeps the entire 53.3-yard width in frame at 7.3 pt/yd with no
> panning. A landscape phone would force either a 2.25:1 letterbox with the width crushed, or
> horizontal panning. FM's own community independently reports that the **vertical** pitch is the
> more legible orientation for reading structure (§2.1), and FM26 ships a camera literally called
> *Vertical Scrolling*.

Its last sentence is the one live residual: the FM community finding on vertical legibility is
evidence, it points the other way, and no test in the plan can settle whether it transfers to a
sport whose structure is a line of scrimmage. `05` P13's owner walkthrough carries the question.

---

### 7. Accessibility: what this view becomes (D12)

D12 names the `Canvas` as the hard case and demands a **contract with tests**. The prior build scored
1/4, with Reduce Motion at literally zero occurrences. This section is written as testable
assertions, not aspirations.

#### 7.1 Reduce Motion

**Mechanism.** SwiftUI exposes `@Environment(\.accessibilityReduceMotion)`; UIKit exposes
`UIAccessibility.isReduceMotionEnabled`. Apple's HIG has a dedicated **Motion** page.
([Apple — HIG Motion](https://developer.apple.com/design/human-interface-guidelines/motion),
[Apple — accessibilityReduceMotion](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion))
**UNVERIFIED:** the exact HIG wording could not be read — `developer.apple.com` returns a JavaScript
shell through the proxy. The widely-reported substance is: honour the setting, remove parallax,
autoplay and large-scale transitions, **prefer cross-fades to motion**.

**The design position, and why it is principled rather than a concession.**

Reduce Motion cannot mean "the same animation, slower" — that is still motion, and slower motion is
*more* total motion exposure. It must mean **a different representation of the same information**.

Because §4.4 established that the *trace*, not the motion, carries the meaning, there is a
principled answer:

> **Under Reduce Motion, the match view renders the terminal play diagram immediately: field strip,
> line of scrimmage, first-down line, the ball's path as a completed stroke, the end-of-play spot,
> and 2–4 labelled marks — with no `TimelineView` and no animation at all.**

That is not a degraded mode. It is the analyst's still frame — the `plot_play_frame()` of §4.3 — and
it is arguably **more** diagnostic than the animation, because nothing is transient. It is also the
same code path as skip, fast-forward and the low-leverage snap (§1). One implementation, four
features, one test.

**The instrument D12 requires:**

| Test | Assertion |
|---|---|
| `test_reduceMotion_producesTerminalDiagramForEverySnapType` | For every `PlayOutcome` case, `PlayPresentation(outcome:reduceMotion:true)` returns a non-empty `StaticPlayDiagram` containing at minimum: LOS, first-down line, result spot |
| `test_reduceMotion_schedulesNoFrames` | With the flag set, the view model's frame scheduler is never asked for a tick; `TimelineView` is not instantiated (assert on a seam, not on SwiftUI internals) |
| `test_reduceMotion_flagIsRead_notCached` | The flag is read from the environment per render, so toggling it in Settings mid-session takes effect |
| `test_noAnimationOutsideMatchView` (source scan) | A source-scanning test asserting every `withAnimation`/`.animation(` site in the app has a Reduce-Motion guard — the same *class* of test as the determinism source scan Tier A already mandates, and the direct answer to "0 occurrences" |

That last one is the important one. `AUDIT.md`'s systemic finding — *"the test's coverage boundary
became the quality boundary"* — is defeated here by making the test a **source scan over all view
code**, so the boundary is "the codebase" rather than "the views someone remembered to test."

#### 7.2 VoiceOver

**Mechanism.** A `Canvas` is a single opaque accessibility element by default. Three tools:

- **`.accessibilityRepresentation { }`** — replaces the element with the accessibility information of
  a hidden native view you supply. Cited against **WCAG 4.1.2 Name, Role, Value**.
  ([CVS Health — AccessibilityRepresentation](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityRepresentation.md),
  [Swift with Majid](https://swiftwithmajid.com/2021/09/01/the-power-of-accessibility-representation-view-modifier-in-swiftui/))
- **`.accessibilityChildren { }`** — synthesises child elements for an otherwise opaque container;
  the documented pattern is an `HStack` of `Rectangle`s, one per datum, each labelled, which become
  children of the `Canvas` accessibility container. [P]
  ([Deque — SwiftUI Accessibility Goodies & Gotchas](https://www.deque.com/blog/swiftui-accessibility-goodies-gotchas-part-2/),
  [WWDC21 — SwiftUI Accessibility: Beyond the basics](https://developer.apple.com/videos/play/wwdc2021/10119/))
- **Audio graphs / `AXChartDescriptor`** (iOS 15+) — sonify a series; VoiceOver plays a pitch per
  data point. Requires conforming to `AXChartDescriptorRepresentable`.
  ([Apple — Audio graphs](https://developer.apple.com/documentation/accessibility/audio-graphs),
  [Apple — Representing chart data as an audio graph](https://developer.apple.com/documentation/accessibility/representing-chart-data-as-an-audio-graph),
  [WWDC21 — Bring accessibility to charts](https://developer.apple.com/videos/play/wwdc2021/10122/),
  [Kodeco](https://www.kodeco.com/31561694-ios-accessibility-in-swiftui-create-accessible-charts-using-audio-graphs))

**A gate-relevant gotcha:** *"Audio Graphs and VoiceOver in general are not supported on the iOS
simulator, so testing requires a physical device."* [P] ([Kodeco](https://www.kodeco.com/31561694-ios-accessibility-in-swiftui-create-accessible-charts-using-audio-graphs))
That lands squarely on §8's machine/owner split: **VoiceOver behaviour is owner-verifiable only**,
and the written walkthrough script must include a device-with-VoiceOver step. An agent asserting
"VoiceOver works" is asserting something it structurally cannot check.

**The design position.**

> **The match view's accessible representation is the play-by-play sentence, not a description of
> the drawing.**

The engine already produces one string per snap — *"2nd and 7 from your 34. Hall complete to
Ferreira for 12. First down."* That sentence is generated by `FootballSimCore`, not by the view, so
it **cannot drift from what was drawn**, because both are functions of the same `PlayOutcome`. It is
also the WCAG 1.1.1 text alternative for the drawing
([CVS Health — Images](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Images.md)).

Concrete structure:

| Layer | Content |
|---|---|
| `Canvas` `accessibilityLabel` | The persistent situation: *"Field view. Ball on your 34-yard line, 2nd and 7, 8:12 left in the 2nd quarter."* |
| `Canvas` `accessibilityValue` | The last completed play's sentence |
| `.accessibilityChildren` | One synthetic element per *drive event* (mirroring the ZenGM drive chart, §3.2) — swipeable history, not per-player |
| `AccessibilityNotification.Announcement` | **Scores, turnovers and fourth-down results only.** Announcing every snap would make the app unusable; announcing nothing makes it unfollowable |
| Player-level detail | The list/cards **below** the canvas (§6.4), which are ordinary SwiftUI views and accessible for free |

**Audio graphs** are a genuine fit for one thing and should not be stretched further: the **drive
chart** and the **win-probability line** are series, and sonifying a drive ("pitch rises as you move
downfield, drops on the sack") is exactly what the API is for. The play animation is *not* a series
and should not be forced into `AXChartDescriptor`.

#### 7.3 Dynamic Type, contrast and colour inside a `Canvas`

The `Canvas` sits outside every automatic accessibility behaviour SwiftUI gives you. Three
consequences that must be written into the contract:

1. **Dynamic Type does not apply to `Canvas`-drawn text.** Any in-canvas label — yard numbers,
   jersey numbers, the down-and-distance overlay — must be sized through `@ScaledMetric` or
   `UIFontMetrics`, or the view will be the one surface in the app that ignores the user's text size.
   Test: render the canvas at the smallest and largest Dynamic Type sizes and assert the drawn font
   size differs.
2. **A `Canvas` cannot be contrast-audited by any tool that inspects the view hierarchy.** Contrast
   must be enforced at the *token* level — every colour the canvas draws comes from the same design
   tokens as the rest of the app, and the token pairs are unit-tested for ratio. Drawing a raw
   `Color(red:green:blue:)` inside a `Canvas` should be forbidden by a source-scan test. This is the
   direct fix for `AUDIT.md`'s "contrast failing at 50+ sites."
3. **Colour cannot be the only thing distinguishing the two teams** (WCAG 1.4.1, use of colour).
   Marks need a redundant non-colour channel — filled vs ring, or a directional chevron indicating
   which way the team is attacking.

**Point 3 is a genuine cross-constraint finding and deserves to be flagged to D6 and to the Tier A
trade-dress test.** Team colours in this game are *procedurally generated* and *constrained away
from real programmes' colour pairs* by the ΔE test. A generator constrained in that way will
inevitably produce some matchups whose two primaries are close in luminance — two mid-tone blues,
say. In a text-and-tables UI that is a mild aesthetic problem; **in a 22-mark `Canvas` it is a total
comprehension failure.** So:

> **Either the shape channel carries team identity redundantly (recommended, cheap, also the WCAG
> answer), or the match view substitutes contrast-guaranteed "home/away" colours for the team
> primaries during play, or the league generator gains a pairwise constraint that every scheduled
> matchup's primaries differ by a minimum ΔE.** The last is the most expensive and the most fragile.
> Pick the first.

#### 7.4 The scoring rubric this section is answering

D12's failure was not ignorance; it was that nothing was measured. Every item above is written as a
test with a seam so that `04b`'s accessibility dimension can be scored on evidence. The four
source-scanning tests (Reduce Motion guard, no raw colours in canvas, scaled fonts in canvas, text
alternative present) are deliberately of the same *kind* as the Tier A determinism source scan,
because that is the one mechanism in this project that has previously caught a systemic defect
rather than a local one.

---

### 8. The coupling to D2: the engine decides what the view may honestly draw

This is the finding with the largest downstream consequence, and it comes from ZenGM, stated by the
developer about his own game:

> A basketball shot chart *"would require knowing the 2D position of those events, **which is
> currently not simulated** in Basketball GM."* [P] ([ZenGM](https://zengm.com/blog/2023/11/play-by-play-redesign/), [ZenGM — drive chart](https://zengm.com/blog/2023/11/football-drive-chart/))

Football GM draws a **drive chart** — outcomes on a field axis — precisely because outcomes are what
it simulates. It draws no players because it has no player positions. The view is downstream of the
model, and the developer did not fake it.

**Therefore D2 and §6.5 cannot be decided independently.** The honest pairings:

| D2 option | What the `Canvas` may honestly draw | Cost |
|---|---|---|
| **Agent-based per-snap resolution** (continuous positions, 10 Hz) | Everything: true trajectories, velocity vectors, Voronoi, pursuit angles, coverage shells derived from actual defender positions | Highest sim cost; hardest to calibrate; largest replay payload if positions are persisted |
| **Play-outcome distribution + visualisation layer** | LOS and first-down lines, ball path, end spot, 2–4 marks placed by a **template** keyed to play type and result. **Not** 22 individuated trajectories — those would be fabricated | Cheapest; calibrates directly against §6.4 bands |
| **Hybrid assignment/leverage resolution** | The *matchup that decided the play* — blocker vs rusher, receiver vs defender — plus the ball path and the two lines | Middle; produces a causal story the player can learn from (the Bowl Bound fix, → `§6.2A §3.3`) |

**The convergent argument, which is the reason this section exists:**

> The middle option is the **cheapest to build and calibrate**, and its honest visual vocabulary —
> two lines, a ball trace, two distinguished marks — is **exactly** the vocabulary that §4.4 says
> makes a play legible and §5.3 says fits within tracking capacity. The expensive option buys
> fidelity the viewer's attention cannot spend.

Two constraints that apply to **any** choice:

1. **The view must be a pure function of `(playOutcome, t)`.** No RNG in the view layer. If the
   presentation invents positions, it must invent them deterministically from the outcome's seed, or
   two viewings of the same seeded play will differ and the Tier A determinism contract is broken in
   spirit even if the box score matches.
   **Test:** render at `t ∈ {0, 0.25, 0.5, 0.75, 1.0}` twice from a cold process and assert the
   emitted draw-command sequences are byte-identical.
2. **The animation may never contradict the box score.** If the diagram shows a catch at the 41 and
   the log says the ball was spotted at the 39, the player learns to distrust the view, and a
   distrusted view is worse than no view. The spot in the diagram and the spot in the play-by-play
   must be the same value, read from the same field.

---

### 9. Presentation-time arithmetic (feeds §4)

`§6.2B §4.2` established the naive figure: **6 s/snap × 130 snaps ≈ 13 minutes of watching per game**,
which alone consumes over half of the 21 min/week that P4's budget allows. This section prices the
legibility-first alternative, so §4 has a number to work with.

**Three independently tunable dwells** (generalising FMM's two-slider pattern, → `§6.1 §3.1`):

| Phase | What it must make legible | Proposed default |
|---|---|---|
| **Pre-snap dwell** | Formation and the coverage shell (deep-safety count) | **0 s by default**, 1.5 s when the player has a decision pending |
| **Snap resolution** | The diagram inking itself: trace + result | **1.2–2.5 s** by play type |
| **Post-play dwell** | Result and spot relative to the sticks | **0.8 s** |

**DERIVED budgets:**

```
Routine snap, no decision   : 0 + 1.4 + 0.8            = 2.2 s
130 snaps × 2.2 s                                      = 4.8 min/game     (vs 13 min naive)

Leverage-filtered presentation:
   25 high-leverage snaps × 3.5 s (incl. pre-snap dwell) = 87.5 s
  105 routine snaps × 0.6 s (terminal diagram, flashed)  = 63.0 s
                                                    total = 2.5 min/game
```

**Why the second figure is achievable and not wishful:** because the terminal diagram is **fully
legible at `t = 1` with zero animation** (§1), a "flashed" snap is not a degraded snap — it is the
same picture, shown instantly. The 0.6 s is dwell time to read it, not animation time. The player
loses the *drama* of the routine snap and loses none of its *information*.

**The lever this exposes for D4 and §4:** presentation time becomes a **player-controlled dial with
a legible floor**, not a fixed cost. The floor is the time to read a static diagram (~0.6 s), not the
time to watch a motion (~6 s). That is a 10× range under player control, and it is what makes P4
survivable under a 2D match view at all.

**A constraint carried forward from `6.2b`:** the unit of skip must be **the snap**, not the game. A
fixed-duration cutscene with only a game-level skip makes the presentation term uncontrollable.

---

### 10. Rendering rules for `04-UX-AND-DESIGN-SYSTEM.md`

Each rule cites the finding it comes from. These are the concrete output of this research part.

| # | Rule | From |
|---|---|---|
| 1 | **One visual model per snap: the play diagram. The animation is that diagram drawing itself.** Playback, fast-forward, skip, low-leverage and Reduce Motion are all `t`-manipulations of one renderer | §1, §7.1 |
| 2 | **Vertical field, fixed at ~7.3 pt/yd, ~68 yd window centred on the line of scrimmage.** Full 53.3 yd width always in frame | §6.2, §6.5 |
| 3 | **The camera transform is constant for the duration of a snap.** Recentring happens between snaps only | §5.4 |
| 4 | **≤4 individuated marks at any instant** (Class 1); the other 18 are drawn as aggregate form (Class 2) — one shape for the line, a translucent zone for the shell, a blob for pursuit | §5.3, §6.3 |
| 5 | **Two persistent static lines — line of scrimmage and first-down line — are the primary read**, present in every frame including the ambient state | §4.2 |
| 6 | **Per-play-type templates**, not one generic renderer: deep pass, short pass, inside run, outside run, sack, turnover, kick, return each get their own picture | §4.3 |
| 7 | **The ball is drawn as a persistent stroke with a head, not a moving dot.** The trace is what makes a completion read as a completion | §4.4 |
| 8 | **Distinguish exactly two players during the ball's flight** — target and nearest defender — by glow and size, per the NGS convention | §4.3, §4.4 |
| 9 | **Ambient state mode between snaps = the drive chart** on the same field coordinate system: plays as bars, turnovers red, kicks grey | §3.2 |
| 10 | **Nothing in the `Canvas` is tappable.** Player interaction lives in cards below it | §6.4, §7.2 |
| 11 | **No jersey numbers on line players.** They are geometrically impossible at 7.3 pt/yd and would only be drawn overlapping | §6.3 |
| 12 | **Team identity carries a redundant non-colour channel** (fill vs ring, or attack-direction chevron) | §7.3 |
| 13 | **Three separately tunable dwells** — pre-snap, resolution, post-play — exposed to the player, with skip at snap granularity | §9, → `§6.1 §3.1` |
| 14 | **Every colour and every font size inside the `Canvas` comes from design tokens**, enforced by a source-scan test | §7.3 |
| 15 | **The play-by-play sentence is the accessible representation of the drawing**, generated by the engine so it cannot drift | §7.2 |
| 16 | **Simulate a rendered snap at 10 Hz** and interpolate for display; that is the sampling rate of the sport's own instrumentation and there is no information above it | §4.3 |

---

### 11. Assumptions, unverified claims, and unrun research

**ASSUMPTION** — a guess with no source:

1. **iPhone logical point dimensions** (390 × 844 base, 320 wide on SE). From memory; the brief's own
   "~390 pt" is the figure used. Replace with measured values in `04`.
2. **~500 pt of available canvas height after chrome.** A design estimate, not a measurement. Every
   number in §6.2 scales linearly with it.
3. **Offensive line splits of ~1–1.3 yd centre to centre.** Order of magnitude only; varies by
   scheme. §6.3's conclusion survives anything in the 0.7–2 yd range.
4. **A legible two-digit numbered circle needs ~20–22 pt diameter (11 pt font).** Typographic rule of
   thumb, not tested.
5. **The dwell defaults in §9** (1.2–2.5 s resolution, 0.8 s post-play, 0.6 s flashed). These are
   proposals to be tuned against an owner timing protocol, not findings.
6. **The 25/105 high-leverage split** in §9's second budget. Illustrative arithmetic; the real
   number is an output of D1's leverage filter.
7. **That FM's 2D pitch on mobile is displayed vertically.** The vertical-orientation evidence in
   §2.1 is about FM26's desktop 2D camera. FMM being 2D-top-down is sourced (→ `§6.1 §3.1`); its
   *orientation* on a phone is not.

**UNVERIFIED** — believed true, could not confirm this session:

8. **Apple's 44 × 44 pt minimum touch target.** Long-standing HIG guidance; `developer.apple.com`
   returns no readable body through the proxy.
9. **Apple's exact HIG wording on Reduce Motion** (§7.1), including whether cross-fade is
   recommended in those words. Same cause.
10. **The precise SwiftUI API surface for suppressing `TimelineView` scheduling** under Reduce
    Motion. The environment key is documented; the "assert on a seam" test in §7.1 is written that
    way *because* I could not verify what SwiftUI internals are observable.

**UNRUN** — research the exhausted WebSearch budget cut off:

11. **How other mobile sports titles orient the field.** Only FM (§2.1) and the field arithmetic
    (§6) inform §6.5's recommendation — and as of 2026-08-10 they point in opposite directions, which
    makes this gap load-bearing rather than merely open. Retro Bowl's orientation specifically
    could not be sourced, and it is the highest-value missing data point in this document — it is
    the most-played football game on the platform.
12. **Whether any shipping title animates all 22 players in a 2D top-down football view.** I found
    none in the competitive set, but "found none" under an exhausted budget is weaker than "there is
    none." §3.1's claim should be read with that discount.
13. **Direct evidence on legible mark sizes at phone scale** — there is a data-visualisation
    literature on minimum discriminable mark size and on small-multiple density that I did not
    reach. §6.3 rests on arithmetic and a typographic rule of thumb instead.
14. **Blood Bowl / OOTP community complaints about presentation legibility specifically.** Both are
    represented here by review and manual text, not by player voice.

**DERIVED** — arithmetic or logic performed here, inputs cited: §4.4 (the five-state read and the
minimum vocabulary), §5.3 (capacity overshoot table and the Class 1/Class 2 rule), §5.4 (fixed
camera), §6.2 (877.5 pt, 68.4 yd, 7.3125 pt/yd), §6.3 (8.4 pt line spacing, 3.5 % ink coverage),
§6.4 (8 tap targets), §9 (all budgets), §3.2 (drive chart as ambient mode).

---

### 12. Sources

**Football Manager — 2D view, cameras, match day**
- https://steamcommunity.com/app/3551340/discussions/0/506217282369896496/
- https://steamcommunity.com/app/3551340/discussions/0/506216918921930920/
- https://community.sports-interactive.com/forums/topic/594339-2d-match-engine-poor-quality/
- https://community.sports-interactive.com/forums/topic/591889-what%E2%80%99s-your-go-to-camera-angle-match-view-setup/
- https://community.sports-interactive.com/forums/topic/593877-2d-camera/
- https://community.sports-interactive.com/forums/topic/567945-how-do-i-change-view-for-matches/
- https://community.sports-interactive.com/forums/topic/499028-2d-matchday-pitch-view/
- https://steamcommunity.com/app/2252570/discussions/0/3879346999814247173/
- https://www.footballmanager.com/fm26/features/where-storytelling-evolves-fm26s-match-day-experience
- https://www.footballmanagerblog.org/2025/12/fm26-2d-camera-vs-3d-nostalgia-tactics.html
- https://www.footballmanagerblog.org/2025/09/fm26-match-day-experience-broadcast-mode-dynamic-highlights.html
- https://esports-news.co.uk/2025/09/25/football-manager-26-upgraded-match-day-experience-gameplay-revealed/
- https://fmmvibe.com/forums/topic/7800-the-2d-pitch/
- https://gamegou.helpshift.com/hc/en/3-top-football-manager/faq/298-can-i-switch-between-2d-and-3d-matches/

**ZenGM (Football GM / Basketball GM)**
- https://zengm.com/blog/2023/11/football-drive-chart/
- https://zengm.com/blog/2023/11/play-by-play-redesign/
- https://zengm.com/blog/tag/live-sim/
- https://zengm.com/
- https://github.com/zengm-games/zengm

**Draft Day Sports / Wolverine Studios**
- https://www.wolverinestudios.com/games/draft-day-sports-pro-football
- https://store.steampowered.com/app/4041080/Draft_Day_Sports_Pro_Football_2026/
- https://store.steampowered.com/app/782510/Draft_Day_Sports_Pro_Football_2018/
- https://www.wolverinestudios.com/post/featurefriday-building-plays-in-draft-day-sports-pro-football-2020

**Out of the Park Baseball**
- https://manuals.ootpdevelopments.com/index.php?man=ootp23&page=game_log
- https://manuals.ootpdevelopments.com/index.php?man=ootp22&page=game_log
- https://www.operationsports.com/out-of-the-park-baseball-24-review-still-making-worthwhile-improvements/
- https://www.ootpdevelopments.com/out-of-the-park-baseball-home/

**Blood Bowl 2**
- https://gamefaqs.gamespot.com/ps4/213591-blood-bowl-2-legendary-edition/faqs/78266/gameplay
- https://bigbossbattle.com/review-blood-bowl-2-legendary-edition/
- https://www.cgmagonline.com/review/game/blood-bowl-2-legendary-edition-pc-review-gridiron-goblin/

**All-22 / coaches film**
- https://grantland.com/features/the-film-launch-thousand-questions-sources-offseason-stories/
- https://bleacherreport.com/articles/1242852-all-22-available-for-all-nfl-fans-how-to-use-it-to-your-advantage
- https://www.nfl.com/news/nfl-com-to-offer-fans-coaches-film-with-nfl-game-rewind-09000d5d82ac698a
- https://www.nfl.com/news/nfl-week-2-plays-to-rewatch-with-all-22-on-nfl-pro
- https://wolfsports.com/nfl/the-new-all-22-with-nfl-pro-is-a-positive-for-football-fans/

**The virtual first-down line**
- https://www.espnfrontrow.com/2013/09/virtual-yellow-1st-and-ten-line-debuted-on-espn-15-years-ago-today/
- https://espnpressroom.com/feature/virtual-yellow-1st-and-ten-line-debuted-on-espn-15-years-ago-today/
- https://ethw.org/The_Making_of_Football%27s_Yellow_First-and-Ten_Line
- https://www.invent.org/inductees/stan-honey
- https://www.mentalfloss.com/article/27009/explaining-magic-yellow-first-down-line
- https://en.wikipedia.org/wiki/1st_%26_Ten_(graphics_system)

**Player tracking and play visualisation (primary — READMEs read in full)**
- https://github.com/nfl-football-ops/Big-Data-Bowl
- https://github.com/asonty/ngs_highlights

**Player tracking and play visualisation (secondary)**
- https://operations.nfl.com/gameday/analytics/big-data-bowl
- https://operations.nfl.com/game-operations-logistics/technology/performance-tracking-data-next-gen-stats
- https://www.amazon.science/blog/a-decade-of-nfl-next-gen-stats-innovation
- https://nextgenstats.nfl.com/highlights/play/type/team/season/week/playerId/2019092209/2375
- https://en.wikipedia.org/wiki/Next_Gen_Stats
- https://www.sportsvideo.org/2025/12/17/espn-to-debut-mnf-playbook-with-next-gen-stats-a-new-ai-driven-nfl-data-altcast/
- https://press.disneyplus.com/news/monsters-funday-football

**Coverage recognition / what a football-literate viewer reads**
- https://americanfootballiq.com/blogs/news/football-coverages-101-the-ultimate-beginners-guide
- https://americanfootballiq.com/blogs/news/how-to-read-a-defense-a-step-by-step-guide-for-high-school-qbs
- https://athletesuntapped.com/blog/deciphering-the-defense-mastering-football-coverage-recognition/
- https://www.thephinsider.com/2016/6/27/12039106/football-101-defensive-cover-schemes-aka-how-a-quarterback-reads-a-defense
- https://forums.operationsports.com/forums/forum/football/ea-sports-college-football-and-ncaa-football/947541-how-to-identify-coverages-pre-snap-in-madden-25-and-college-football-25
- https://www.slideshare.net/slideshow/10qbreads/3018071

**Multiple-object tracking literature**
- https://pubmed.ncbi.nlm.nih.gov/17997642/
- https://jov.arvojournals.org/article.aspx?articleid=2121950
- https://dash.harvard.edu/handle/1/41056876
- https://www.semanticscholar.org/paper/How-many-objects-can-you-track-Evidence-for-a-Alvarez-Franconeri/cbf6415cada79bd310b618743b6177b300c979e6
- https://www.researchgate.net/publication/5848550_How_many_objects_can_you_track_Evidence_for_a_resource-limited_tracking_mechanism
- https://www.sciencedirect.com/science/article/abs/pii/S0010027708000097
- https://pmc.ncbi.nlm.nih.gov/articles/PMC2430981/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC3181432/
- https://link.springer.com/article/10.1007/s10339-020-00954-y
- https://www.biorxiv.org/content/10.1101/2022.09.08.507113.full.pdf

**Accessibility — Reduce Motion, VoiceOver, Canvas, audio graphs**
- https://developer.apple.com/design/human-interface-guidelines/motion
- https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion
- https://developer.apple.com/videos/play/wwdc2021/10119/
- https://developer.apple.com/videos/play/wwdc2021/10122/
- https://developer.apple.com/videos/play/wwdc2022/110340/
- https://developer.apple.com/documentation/accessibility/audio-graphs
- https://developer.apple.com/documentation/accessibility/representing-chart-data-as-an-audio-graph
- https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityRepresentation.md
- https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Images.md
- https://www.deque.com/blog/swiftui-accessibility-goodies-gotchas-part-2/
- https://swiftwithmajid.com/2021/09/01/the-power-of-accessibility-representation-view-modifier-in-swiftui/
- https://swiftwithmajid.com/2021/09/29/audio-graphs-in-swiftui/
- https://www.kodeco.com/31561694-ios-accessibility-in-swiftui-create-accessible-charts-using-audio-graphs
- https://www.createwithswift.com/making-charts-accessible-with-swift-charts/
- https://www.avanderlee.com/swiftui/accessibility-uikit-developers/
- https://www.kodeco.com/books/swiftui-by-tutorials/v4.0/chapters/12-accessibility

**Mobile football titles referenced**
- https://apps.apple.com/us/app/retro-bowl/id1478902583
- https://apps.apple.com/us/app/nfl-retro-bowl-26/id6476767864

---

## §6.6 — Football Manager UI reference read (owner-supplied screenshots)

Added 2026-08-09. Research input to `docs/04-UX-AND-DESIGN-SYSTEM.md` and to phases P12–P14 of
`docs/05-IMPLEMENTATION-PLAN.md`. This section reads **interface structure only** — what information
is grouped with what, and what the player is asked to do with it. It takes no visual expression from
the source. See §7 for the boundary this section is written inside.

### 1. What the evidence is

Eighteen screenshots supplied by the owner and reviewed in full. They are **not committed to this
repository** — they are third-party copyrighted captures, and the repo has no business holding
30 MB of them. They live outside the tree; this section is the durable artefact.

| Group | Count | What it is |
|---|---|---|
| FM26 desktop, apparently live builds | 12 | Player report ×2, portal/home, calendar, in-game glossary overlay, squad overview + bookmark manager, match-day overview, finances, set-piece designer, squad table, training, data hub |
| FM Mobile (one capture's boards read `FM23 MOBILE`; the second's digit is illegible at capture resolution and may be `21`) | 2 | In-match pitch; in-match goal event |
| FM25 design-file mocks, watermarked `Work in Progress — taken from FM25 design files and not from a game build` | 3 | Player last-5-matches, redesigned portal, redesigned match day |
| Marked `NON-FINAL CAPTURE` | 1 | Tactics planner |

**Grade: primary visual evidence, provenance unverified.** These are real captures of a real product,
which is a stronger grade than anything else in Part Two. But four of the eighteen are explicitly
non-shipping design material, and for the other fourteen this document cannot say whether they came
from a retail build, a press kit or a beta. Read structural claims as sound and "this is what players
actually use today" claims as one grade weaker.

**Amends standing caveat 1.** Part Two's caveat *"No competing product was installed or played, on
any platform, by anyone"* still holds — nothing here was played. But it is no longer true that no
competitor was *seen*. This section is direct observation of a competitor's interface; the rest of
Part Two is not.

### 2. What it settles

**AS-6.5-07 is settled, and it goes the other way.** The register assumed FM's 2D pitch on mobile
was displayed vertically, and named that as *"the single precedent for portrait orientation"*. The two
FM Mobile captures show the pitch drawn **landscape, full-bleed, left-to-right, goals at the screen
edges** — the device is rotated for the match. There is no portrait precedent here.

**One residual, named rather than glossed.** One capture's sideline boards read `FM23 MOBILE`; the
second's digit is illegible at capture resolution even enlarged, reads more like `21`, and its
fixture's league composition fits the earlier season (2026-08-12 re-read,
`docs/briefs/2026-08-12-reference-set-findings.md` §5). The settlement stands on the legible capture
alone: settled for **FMM23**, not for the current SKU. §6.1 establishes that FM26 Mobile is the
one edition that did *not* move to the new engine, which makes an orientation change across those
three years unlikely — but unlikely is not observed. The residual only matters if someone later wants
to reinstate a portrait precedent; it cannot resurrect one, because a precedent this document has not
seen is not a precedent it may cite.

This did **not**, at the time, overturn `04` §5.2's vertical field, for a reason worth stating: the
two sports have opposite field ratios. A soccer pitch is roughly 1 : 1.55 (68 × 105 m) and an
American football field is roughly 1 : 2.25 (53.3 × 120 yd). Landscape is the natural fit for the
first and the wrong fit for the second. The decision survived — but on **geometry alone**, with no
shipping precedent behind it.

**2026-08-10 — overturned, by the owner and on the geometry, not by this observation.** The app is
landscape (`04` §5.2). The ratio argument above is the part that did not hold up: 2.25 : 1 against a
2.164 : 1 screen is a *near fit*, not a wrong fit, and §6.5's correction shows the whole field lands
inside the frame with ~20 pt to spare. The owner additionally reports FMM is landscape throughout,
menus included — testimony, not capture, and recorded that way in AS-6.5-07. What this section
observed remains exactly true: two captures, landscape pitch, FMM23.

### 3. Patterns that transfer

Each names where it lands.

1. **No analytical chart without a verdict.** Every *analytical* surface pairs its graphic with a
   plain-language judgement — a pill (*performing much better than average*) plus two or three
   sentences naming which numbers are outliers and in which direction. The analytics screen does it
   eight times on one page: a summary paragraph, three radar cards, four scatter cards, each with a
   verdict pill and its own prose. The tactics overview repeats it in miniature.
   **Stated precisely, because the loose version is wrong:** the *financial* screens do not do this —
   they carry figures, directional arrows and a compliance flag, with no prose judgement. So the
   pattern is not "never a naked chart"; it is that **wherever the product expects the player to
   form a judgement, it states the judgement first** and lets the chart be the evidence.
   → `04` §4: a READOUT that cannot state its own verdict is wallpaper, and this is the test that
   catches it.
2. **The suggestion with two buttons.** In-match, the assistant proposes a specific substitution in a
   short sentence with **Do it** and **Ignore** beneath it. It converts watching into deciding at
   almost no interface cost, and it needs no direct control of play.
   → `04` §3 `CallInCard`; `05` P13. This is the closest thing in the reference set to our call-in
   model, and it is the shape to copy: a named proposal, one-tap accept, explicit dismiss.
   *(2026-08-12 provenance grade: the two-button in-match suggestion is mock-sourced — it appears in
   the redesigned-match design-file mock; the shipping analogue is weaker. The pattern stands as
   adopted; cite it as intent, not as shipping behaviour.)*
3. **Ambient field, foregrounded event.** The mobile match keeps all 22 as plain numbered dots and
   never tries to make the field itself carry the story. The story arrives as a **lower-third card**
   (scorer portrait, number, name, event, one-line descriptor) and a **one-line commentary banner**.
   → `04` §5: `LowerThird` is a real component we did not have. Our directed-attention rule is the
   stronger version of the same instinct; the card is how the moment gets named.
4. **Progress marks in the match header.** The mobile match header carries a row of nine small marks
   beside the clock, the first filled. **This is an inference, not a reading** — from a still, it
   could be highlights remaining, match periods, or a page indicator. It is carried forward because
   the *idea* is sound on its own, not because the source is proven to do it.
   → `05` P13. Under drive-granularity default, show how many key moments remain.
5. **Role tokens on the pitch.** Tactics tiles carry a short role code (`CFD`, `DLP`, `FB`) beside
   the number; the set-piece designer gives every instruction a letter-number token (`B0`, `C0`,
   `E1`) that maps a draggable list row to a labelled dot on a mini pitch. Assignment information
   reaches a small pitch without portraits or long labels, and the list-to-dot mapping is legible.
   → `04` §3 (a `Chip` variant, not a new component); `05` P14 depth chart and scheme.
6. **Two-value opposed bars** for team-versus-team stats (shots, possession, xG) — one shared track,
   value at each end. Reads at a glance where a two-column table does not.
   → `04` §3 `OpposedBar`.
7. **Form as a five-bar sparkline**, and last-five-matches as a rating line threaded across five
   result columns. Dense, small, instant.
   → `04` §3 `Sparkline`; `05` P14 player card.
8. **Constraint pressure shown, not tabulated.** The wage panel puts spend over budget on one line
   with the ratio stated (`101.8%`), figure and ratio in a negative state, the track reading full and
   capped. The breach registers before the numbers are read.
   → `04` §3 `Meter` gets a defined over-capacity state — ours draws past the track, which the
   source does not, because a full-but-capped bar cannot show *how far* over you are and a cap
   overage needs that. `05` P14 cap, scholarship and contact-budget surfaces.
9. **The agenda as commitments with a cost.** The redesigned home lists the day's obligations as
   checkboxes with time-to-event beside each (*attend press conference — 1h*), not as news.
   → `04` §4 Inbox, `05` P12. The week should show what it will cost, not only what happened.
   *(2026-08-12 provenance grade: the costed agenda is mock-sourced — it appears in the
   redesigned-home design-file mock. The pattern stands as adopted; cite it as intent, not as
   shipping behaviour.)*
10. **Status glyph columns.** Squad rows carry a small fixed vocabulary of state chips — injured,
    tired, wants a transfer — plus condition and morale icons.
    → `04` §4 roster. **Inverted for our screen size**: at most three glyphs, and each must be one
    that changes a decision. See §4.3.
11. **Tappable glossary with cross-links.** Terms open a definition panel that links to related
    terms and to the screens where they matter.
    → **A candidate for `05` P15 (D9), deliberately not committed there.** The cheap version is a
    definition sheet for the twenty terms our own UI uses, reachable by long-press. The expensive
    version is the reference set's content volume, which is not a v1 shape. Raise it when D9 is
    answered; do not add it to the plan before then.

### 4. Patterns that must not transfer

#### 4.1 Visual expression (legal)

FM's look is FM's trade dress: the near-black blue-violet ground, magenta section headings, the
violet primary action, the condensed italic display face, the gradient advance button. None of it
comes across, and our token system means no view can name a hue anyway. Neither does any label
verbatim — the section names, panel names and attribute names in these captures are their copy, not
a vocabulary to borrow. The crests, club names and player names in the captures are real-world marks
and NIL; they are blocklist material at most, never inspiration. `CLAUDE.md`'s guardrail governs, and
this section exists inside it.

#### 4.2 Density

These are 16:9 desktop screens running three and four columns, eight-column attribute blocks and
fifteen-column tables. A straight port to a phone screen is the failure mode, and it is a failure
this project has already made once — `docs/AUDIT.md` is the record. Every pattern in §3 is adopted as
a *relationship between pieces of information*, never as a layout.

**And the 2026-08-10 orientation change makes this trap easier to fall into, not harder.** A
landscape phone is 844 × 390 pt — the same *aspect* as those desktop screens and about a tenth of the
*area*. The temptation is to read "we are landscape now" as "the desktop column layouts port". They
do not: `04` §4 allows **two** panes, not four columns, and a fifteen-column table has no landscape
answer either.

#### 4.3 Navigation scale — the anti-lesson

Two of the captures are, read honestly, symptoms. One is a **bookmark manager** offering 6 of 12 pins
across roughly thirty destinations. The other is a redesigned home with a **"search for tiles"**
field. A product needs a search box over its own navigation only when its navigation has outgrown
being navigable.

→ **Constraint for `04` §4:** if this game ever needs a search field over its own screens, or a
user-configurable shortcut manager, the information architecture has failed. Five tabs, and every
destination reachable in at most two taps from its tab root.

*(2026-08-12, superseded in place: the five-tab bottom bar was removed by the owner's 2026-08-11
`04` correction — the world strip plus local routes now govern navigation. The two-tap reach
constraint survives and is restated in `04` §4.5's density budget; the five-tab framing above is
historical. The search-field and shortcut-manager tripwires stand unchanged.)*

#### 4.4 Orientation

Owner-fixed: portrait only. The mobile match rotates the device; we cannot, and per §2 we should not
want to.

*(2026-08-12, superseded in place: false since the owner's 2026-08-10 landscape decision — §2's
dated note above records the overturn. The app is landscape-only; the observation is preserved as
written because deleting it would hide what this section believed and when.)*

### 5. What this does not settle

- **AS-6.5-11 (Retro Bowl's orientation) remains unrun**, and remains the highest-value missing data
  point — it is the most-played football game on the platform and the only one whose field ratio
  matches ours.
- **AS-6.5-12 (does any shipping title animate all 22 in 2D)**: the mobile captures show all 22 as
  dots, but soccer, and this is a screenshot, not motion. Not evidence about animation.
- **Nothing about feel.** No capture tells you what any of this is like in the hand, how long a
  screen takes to parse, or whether the match holds attention. Caveat 1 still governs.
- **Nothing about our engine.** Soccer's continuous flow versus American football's per-snap surface
  is the non-transferability argument in §6.1, and none of it is weakened or strengthened here.

### 6. Sources

The eighteen files are owner-supplied captures held outside this repository. No URL; no page was
fetched for this section. Product context for the SKUs referenced sits in §6.1 and its source list.
