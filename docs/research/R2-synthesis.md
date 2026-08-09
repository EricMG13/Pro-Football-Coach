# R2 — Synthesis: Verdict, Rulings, and Pillars

**Program:** Pro Football Coach rebuild — synthesis over evidence dossiers R1a (Madden, MAD-01–46), R1b (Retro Bowl, RB-01–42), R1c (Football Manager, FM-01–38), R1d (adjacent games, feel & narrative literature, ADJ-01–48), plus local evidence: `docs/AUDIT.md`, `docs/STATUS.md`, `PRODUCT.md`, `docs/01-RESEARCH.md`.
**Date:** 2026-08-09
**Status:** SIGNED OFF at gate 1 (owner, 2026-08-09) — pillars approved; OD-1/OD-2/OD-3 resolved as recommended, OD-4 deferred to gate 3 (see `docs/OPEN-DECISIONS.md`). Design-system work authorized.
**Traceability:** every ruling cites dossier finding IDs or local documents; decisions with no evidentiary parent are marked `NOVEL` with reasoning. Novel is a first-class origin here, not a defect.

---

## 1. The verdict on the blandness hypothesis

**Hypothesis under test:** the current build fails as a game — "a bland application" — because of game feel, identity, and reward loops, not simulation correctness.

**Verdict: confirmed in direction; wrong about what AUDIT.md proves; and incomplete — the largest single cause is one the hypothesis didn't name.**

### 1.1 What is confirmed

The failure is not simulation correctness. `STATUS.md` documents a calibrated, deterministic, ten-season-soaked engine (224 tests, 13,226 assertions), and the research shows sim believability is the genre's hard floor — the closest direct comparable's #1 documented weakness is exactly the complaint class our calibration and believability bands already answer (ADJ-12: Pocket GM's penalty spam, illogical AI, ratings disconnected from outcomes; ADJ-17: abstraction reading as rigged). The engine is not the problem; it is the moat. Its behavioral contract (calibration bands, determinism, cap legality, soak) survives the rebuild as acceptance specifications.

### 1.2 What the hypothesis gets wrong about its own evidence

`docs/AUDIT.md` (9/20, 78 findings) is cited as the supporting evidence, but its rubric measures **native craft** — accessibility, performance, theming, HIG conformance, adaptivity — and its own executive summary calls the codebase "structurally sound and idiomatic." An app could score 20/20 on that rubric and still be bland; blandness is invisible to it. AUDIT.md therefore documents a **second, independent failure**: craft debt. Both debts are real; they need different cures; fixing either alone fails.

Mapping the verdict onto AUDIT.md's five systemic failure classes:

| AUDIT.md systemic class | What it actually evidences |
|---|---|
| Written commitments with zero implementation (Reduce Motion: 0 checks; VoiceOver: ~3 modifiers) | The one class that *is* direct evidence for the hypothesis: feel-adjacent commitments existed on paper with no architectural layer to implement them. A commitment without a pipeline is a wish. |
| Contrast measured only where tested (coverage boundary = quality boundary) | Generalizes into the program's central lesson: quality exists only where a system enforces it. The feel layer had no system, no tests, no spec — so it had no quality, and no instrument even measured its absence. |
| Token bypass at scale (~80 literals) | The design system was static and shallow enough that real screens outgrew it — a symptom of a system that specified surfaces but not behavior. |
| Synchronous over-eager persistence (the one P0; ~265ms week advance vs the 150ms budget) | Directly breaks the one-more-turn substrate. Sim speed is measurably retention (ADJ-14: doubling season throughput lifted users 12%). This craft bug is also a feel bug. |
| Arcade layer weakest, partly dead code | A mode built with no feel budget in a codebase with no feel layer — the pattern, not an outlier. |

Craft debt has a second research anchor: Madden 26's redemption reviews still lead their complaints with slow, laggy, crash-prone menus (MAD-30), and FM26's collapse was navigation and click-count regressions, not sim regressions (FM-18, FM-19, FM-26). In this genre, **UX debt is what reviews are written about when the sim is fine.** The platform-physics gates in the rebuild plan (re-audit ≥17/20, zero P0/P1) are therefore not hygiene — they are the difference between our rebuild and FM26's launch.

### 1.3 What the hypothesis missed

Two additional root causes, both larger than "polish is missing":

**(a) The witness debt — the sim's outcomes go unwitnessed.** This is the program's single largest finding. The engine already generates drama — injuries, cap crunches, breakouts, collapses, milestone chases, job-security swings — and almost none of it is *delivered*: the news engine is templated volume with no salience selection, there are no permanence surfaces (career ledgers exist as data, not as story), no consequence-with-story law, no season-arc framing. The convergent evidence is overwhelming: Madden's standing diagnosis is that seasons feel "lifeless and sterile" because *nothing mediates between games* (MAD-14); FM's grip runs through the inbox as the game's real main screen narrating a persistent world (FM-01, FM-02, FM-04); OOTP players demanded an off-switch for consequences delivered without their stories (ADJ-43); Retro Bowl's one distrusted system is the one whose causality is invisible (RB-12, RB-40). Curing blandness is mostly **content delivery layered on a finished sim** — the cheap side of the rebuild, and the side the old architecture never had a place for.

**(b) The identity debt — a brand defined almost entirely by refusal.** `NOVEL` (reasoning, traceable to local evidence): three successive design systems were tried and retired (Coordinator's Clipboard → Franchise Almanac → The Broadcast), and each was a static styling system — colors, type, spacing — that specified *surfaces* but never *time*: no motion vocabulary, no sound, no haptics, no celebration choreography, no number staging. DESIGN.md's personality lives mostly in its anti-references (no shadows, no gradients, no exclamation marks, no Madden chrome). Restraint is a defensible aesthetic **only when staging carries the feel** (ADJ-24: context precedes polish — but the counter-tradition never says "no polish"); restraint with no expressive channel is just absence. The fourth design system must be built feel-first: the "time" layer (ADJ-21/22/35/37/38) is first-class content, not an appendix.

### 1.4 The four debts

1. **Craft debt** — AUDIT.md's 78 findings. Paid by platform-physics gates (≥17/20 re-audit, zero P0/P1), not by redesign.
2. **Feel debt** — no time layer: motion, sound, haptics, staging, response budgets. Paid by the new design system's feel layer (gate 2).
3. **Witness debt** — no narrative delivery: salience, permanence, consequence-with-story, season arcs. Paid by the narrative/presentation pipeline as an architectural concern (gate 3).
4. **Identity debt** — negative-space brand. Paid by the broadcast register ruling (T3 below) and the design system's positive commitments.

Fixing 1 alone yields a correct bland app. Fixing 2 without 3 yields juiced silence. 3 is the largest and cheapest per unit of impact, because the sim already produces everything it consumes.

---

## 2. The resolved tensions

The brief demands rulings, not balance. Each tension below ends in a binding ruling. Changes after gate-1 sign-off are explicit amendments.

### T1 — Depth vs immediacy: one surface, two depths

The evidence rules out both poles. Amputating the data surface reads as confiscation of expertise and satisfied nobody (FM-09, FM-18, FM-32); depth delivered as upkeep reads as punishment (RB-21); the streamlining that works deletes minutiae, never decisions (ADJ-07).
**Ruling:** one surface, two depths — the fast layer is a card feed plus a single advance verb (FM-01, FM-02, ADJ-29); every card's full data lives one tap below, click-budgeted per screen (FM-19), with column pickers and density toggles on deep tables (FM-09 + the skin-ecosystem lesson). Depth is never behind a mode. This upgrades PRODUCT.md principle 3 from assertion to evidence-backed law.
**Sub-ruling (blocking cards):** cards block the advance only when the decision has deadline semantics in the sim (contract deadline, gameday lineup, trade offer expiring). Everything else is non-blocking. FM's must-respond evidence is desktop-shaped (FM-02); phone sessions get the benefit of the doubt toward flow. Test at gate 2.

### T2 — Grounding vs immediacy: the cap stays real

Retro Bowl fuses everything into one currency and backgrounds the cap (RB-05, RB-42); our audience is genre-literate, was orphaned by an incumbent whose cardinal sin was fake cap math (PRODUCT.md, 01-RESEARCH §C), and the wishlist RB's own community keeps filing is precisely two-sided trades, real free agency, a real cap (RB-17, RB-34, RB-36).
**Ruling:** the simulation model is never simplified for the fast loop — the cap, contracts, and dead money stay real everywhere. The fast loop compresses *presentation*: cap consequences arrive as cards that say the number and what it means ("Cutting Reyes leaves $6.2M dead through 2028"), the full sheet stays one tap away. Retro Bowl's fusion is rejected as a model and adopted as a presentation target.

### T3 — Broadcast presentation vs the plainspoken voice

The apparent conflict between "no exclamation marks" and celebration choreography dissolves on the evidence: an actual broadcast is itself confident and plainspoken — its drama is produced by *staging*: pacing, cutaways, a stat graphic fired at the earned moment with a 20-second read cap (ADJ-36), numbers resolved sequentially with weight (ADJ-35), presentation skins that mark marquee occasions (MAD-04).
**Ruling:** the game's identity register is **the broadcast, done in text**: system copy stays sober and declarative; drama is carried by staging, timing, sound, and haptics, never by hype adjectives. Celebrations are broadcast events (title card, staged numbers, haptic sequence), and their copy still says the number. **Voice amendment (OD-1 — approved at gate 1, 2026-08-09):** in-fiction media voices — the beat writer, the columnist, the radio host — get personality license the system voice does not have (FM-03: the feed's texture comes from many in-fiction voices; MAD-06/07: the loved media features were voiced). The system never exclaims; the fictional press may.

### T4 — Emergence vs authored narrative

Madden's Scenario Engine failed on reward-only economics and no persistence (MAD-10 names the failure modes its own designer targeted); the loved systems all *report* simulation state rather than inventing it (MAD-06: Storyline Central as views of the morale sim; FM-04; ADJ-41).
**Ruling:** the media layer reports sim state; it never fabricates events. Authoring lives in templates cast against sim events by salience (ADJ-44, ADJ-48), with the oatmeal budget (ADJ-47): a few characterful standouts per season over adequately varied filler. Two binding laws: **consequence-with-story** — no event ships without its arc being visible (ADJ-43); **no severable drama** — the narrative layer cannot be toggled off, because what can be turned off gets turned off and then rots (ADJ-03, FM-13's delegation-fossilization). Media interactions the player must answer are rare and consequential (press dilemmas routing one scarce boost, RB-07) or they do not exist (FM-13).

### T5 — Honest numbers vs perception management

The literature's fudging canon (XCOM, Fire Emblem — ADJ-33) collides with three local facts: the engine is deterministic and auditable, the audience empirically audits sims from outside (FM-38, FM-15), and the sibling community's worst believability scandal was watched-vs-simmed divergence (01-RESEARCH §H).
**Ruling:** show true probabilities; never fudge resolution. Perception is managed structurally instead: randomness placed upstream where it reads as terrain, not at the last step where it reads as theft (ADJ-30); displayed odds honest (Civ IV's satisfaction lesson, ADJ-30); loss-streak drama surfaced as story, not silently compensated. Near-misses are surfaced only when the sim truly produced them (ADJ-32). One engine, one truth stays absolute (STATUS.md; mode-parity bands).

### T6 — Retro Bowl's role: session shape, not field game

The management-sim community requested arcade play exactly zero times (01-RESEARCH §H); Retro Bowl's own shareable layer was the dynasty, not the thumbstick (RB-37); and its formula ceiling is ~5 seasons (RB-13, RB-14).
**Ruling:** Retro Bowl's contribution to this product is the **session architecture** (complete game under 8 minutes, management beats under a minute, sim-with-takeover from day one — RB-03, RB-33), the **attachment machinery** (foreground/background roster split, star fragility events, press dilemmas — RB-41, RB-06, RB-07), and the **verb-compression discipline** (RB-02, RB-39). On the Field remains a third, never-required mode per standing scope; the fast loop's immediacy is delivered by the management game itself. The simulated-phase contract binds everywhere: any phase resolved without player input must have inspectable causality (RB-40) — the difference between FM-style commentary and RB-12's rigged dice.

### T7 — A 20-week calendar vs FM's fixture density

FM's one-more-turn runs on 40–60 fixtures plus windows; a pro football season has ~20 sim-relevant weeks. A flat weekly tick will feel thin (R1c §7.1 inference, ADJ-29).
**Ruling:** the week is a multi-stop structure — a midweek beat (injury report, practice/gameplan tradeoff, press dilemma; MAD-09, RB-07) and a gameday+aftermath beat — with drama density per stop roughly double FM's, engineered by interleaving completion horizons (contract years, development arcs, milestone chases, draft position) so something is always 1–3 weeks from resolving (ADJ-29). `NOVEL` in its specific two-beat shape (no reference game has this calendar; the components are all evidenced).

### T8 — Rebuild governance: the parity floor and the visible new answer

Rebuilds are judged against the predecessor's full feature list (FM-20: shipping below parity read as the series' soul removed; MAD-19/MAD-20: the community keeps removal ledgers for decades), big-bang rewrites of working games have a documented failure anatomy (FM-24–FM-30: scope stacking, hollow UI rebuild, feel discovered dead too late; MAD-20: Connected Careers as the canonical feature purge; FM-30: SI had failed this way before, in 2003), and a same-formula successor earns no attention (RB-22).
**Ruling:** the rebuild ships **mechanics parity or better** with v1 — a parity ledger is maintained in `docs/07-SALVAGE.md` and checked at every phase gate; the visible new answer is the presentation/narrative layer. Process rulings, binding on the build plan: one transformation per phase (FM-29); a cold-play fun gate at every phase close — one uninstructed hour, because that instrument caught what months of milestone tracking missed (FM-27); navigation primitives (search, back, where-am-I, persistent sort) as a per-screen checklist (FM-26, FM-18); no public feature announcements ahead of certainty (MAD-16's acknowledgment-plus-deferral lesson; FM-31: honesty was load-bearing for SI's survival).

---

## 3. Steal / adapt / avoid — final rulings

Consolidated from the four dossiers' preliminary tables; conflicts resolved. Verdicts are binding canon inputs for `02-GAME-DESIGN.md`, `DESIGN.md`, and `04-SCREENS-UI.md`.

### Presentation & feel

| Ruling | Element | Trace |
|---|---|---|
| STEAL | Five-slot broadcast structure in text: pregame card, in-game situational lines, halftime replay-your-half, postgame verdict, weekly league show covering games you didn't play | MAD-01, MAD-02, MAD-03, R1a §7 |
| STEAL | Persistent identity score strip, readable sound-off | MAD-04, R1a §7 |
| STEAL | "League feels alive" operational test: every simmed week produces narrated, openable evidence of games the player didn't play | MAD-03, MAD-14 |
| STEAL | Number staging for headline reveals: sequential resolution, staggered digits, magnitude-scaled emphasis, withheld total, paired haptic | ADJ-35, ADJ-37 |
| STEAL | Situation-earned stat cards, prepared-many-aired-few, ~20-second read cap | ADJ-36 |
| STEAL | Per-action stakes shown before resolution (4th down, blitz, trade verdict) | ADJ-34 |
| ADAPT | Broadcast skin swap for marquee games — original fictional show identities only, never network lookalikes | MAD-04, legal guardrail |
| ADAPT | Commentary-freshness discipline: template recombination + multi-season soak testing instead of live-service line patching | MAD-05, MAD-25, ADJ-47 |
| ADAPT | Reduce Motion as first-class variant of every staged moment: motion strippable, meaning in sound/haptics/color/text | ADJ-38, AUDIT class 3 |
| AVOID | Reflexive juice/confetti against the plainspoken register | ADJ-24, T3 |
| AVOID | Always-on live win-probability as drama (retrospective swing charts instead; live percentages deflate) | ADJ-36 |

### Loop & progression

| Ruling | Element | Trace |
|---|---|---|
| STEAL | Single advance verb gated by a severity-tiered card feed | FM-01, FM-02, ADJ-42 |
| STEAL | Interleaved completion horizons so something always resolves within 1–3 weeks | ADJ-29 |
| STEAL | Session budgets as hard numbers: advance <150ms, fast session <3 min, full played game <8 min, management interstitial <1 min | RB-03, ADJ-14, STATUS.md |
| STEAL | Sim-with-takeover interrupts from day one | RB-33 |
| STEAL | Weekly ritual where every step is a tradeoff (tendency report → focus pick with pros AND cons → reps/intensity vs injury risk) | MAD-08, MAD-09 |
| ADAPT | Injury windows that narrow midweek (estimated range, updates as a beat) — `NOVEL`-adjacent: the Madden 26 Wear & Tear evidence appeared only in a superseded dossier draft at Medium confidence; the practice-tradeoff substrate is evidenced (MAD-09), the narrowing-window presentation needs verification before adoption | MAD-09 |
| ADAPT | Calm default cadence — part of FM's grip is ritual quiet; drama density is tuned, not maximized | FM-06, FM-12, ADJ-40 |
| AVOID | XP earned from box-score stats (causally backwards, farmable, rich-get-richer) — development flows from hidden potential, curves, and camp events | MAD-23, R1a §7 |
| AVOID | Reward-only events (house-money economics make choices meaningless) — commitments carry downside | MAD-10 |
| AVOID | Depth delivered as recurring upkeep chores | RB-21, FM-13, FM-17 |

### Narrative & attachment

| Ruling | Element | Trace |
|---|---|---|
| STEAL | Consequence-with-story law: no event without its visible arc | ADJ-43 |
| STEAL | Career ledgers + milestone events for every generated player; permanence surfaces (records, banners, archives) as content | FM-07, ADJ-44, ADJ-45, RB-18 |
| STEAL | Foreground/background roster split: a handful of featured players carry arcs; the rest resolve as filler | RB-41, RB-04, ADJ-44 (attention budget) |
| STEAL | Star fragility & discipline events forcing coach decisions | RB-06 |
| STEAL | Press dilemmas routing one scarce boost between stakeholders | RB-07 |
| STEAL | Promise/commitment mechanic with delayed, real downside | MAD-10, R1a §7 |
| STEAL | Trust rules for procedural drama: telegraph big outcomes, proportional consequences, tradeoffs not gotchas, never troll | ADJ-44, RB-19 |
| STEAL | Wonderkid-hype pipeline the save later confirms or debunks; graded scout predictions (internal legitimacy for a fictional league) | FM-33, FM-37, FM-38, R1c §7.3 |
| STEAL | Named long-horizon challenge templates; exportable local season/dynasty artifacts | FM-34, ADJ-46 |
| STEAL | "Losing opens a chapter" norm-setting (copy + systems: rebuild arcs, hot-seat arcs, no dead ends) | ADJ-39, ADJ-45, 01-RESEARCH §H |
| ADAPT | Named binary star abilities with visible counters — bounded to sim-plausible effects; the conflict between "fear the star" and "superhero guarantees" is resolved by keeping effects auditable in the box score | MAD-13 vs MAD-39 |
| ADAPT | Wildermyth-style casting for the news engine (typed roles, salience scoring, personality re-voicing) — v1 floor is salience-matched templates; casting engine is an architecture decision (OD-4) | ADJ-44, ADJ-48 |
| AVOID | Severable/toggleable drama layer | ADJ-03, ADJ-43 |
| AVOID | High-volume low-stakes media (spam kills the narrating layer; volume is the enemy, salience is the design) | FM-13, ADJ-42 |
| AVOID | Untelegraphed retirements and rug-pull star exits | RB-19 |

### GM systems & AI

| Ruling | Element | Trace |
|---|---|---|
| STEAL | Cheap-gem discovery as a designed outcome (late rounds/UDFA arbitrage with engineered steals) | FM-33, R1c §7.3, 02-GAME-DESIGN §8 (already present — keep) |
| STEAL | Scouting as an uncertainty game: noisy ranges that sharpen, misses and gems, never full-reveal grades | MAD-24, RB-04 |
| STEAL | League-AI discipline as tested invariants (AI re-signs stars, stays cap-legal, drafts sanely, refuses absurd trades) — a gate before any glamour feature | MAD-14, ADJ-08, ADJ-12 |
| STEAL | Draft night as staged spectacle over the existing systems | MAD-45, FM-08 |
| ADAPT | Difficulty via opponent identity and economy pressure, never uniform stat inflation | RB-09, RB-15, RB-16 |
| AVOID | Difficulty collapse once the player out-develops the AI (AI teams must rebuild credibly across a decade) | ADJ-08, RB-13, 02-GAME-DESIGN (already specified — now a tested invariant) |
| AVOID | Disposal-only GM surfaces | RB-17 |

### Process & governance (bind the build plan)

| Ruling | Element | Trace |
|---|---|---|
| STEAL | Cold-play fun gate per phase (one uninstructed hour) | FM-27 |
| STEAL | Navigation-primitive checklist per screen | FM-26, FM-18 |
| STEAL | Parity ledger vs v1 mechanics, checked per gate | FM-20, MAD-19, MAD-20 |
| STEAL | Retention-curve honesty: playtest instruments over launch vanity metrics | FM-21, FM-23 |
| AVOID | Scope stacking (one transformation per phase) | FM-29, FM-30 |
| AVOID | Public promises ahead of certainty | MAD-16, FM-31 |
| AVOID | Any cloud dependency for saves; save durability is a marketable trust property | MAD-26, 01-RESEARCH §H |

---

## 4. Design pillars

Six pillars. Each is falsifiable — it states a test a build either passes or fails. These decide the rebuild's character; they are the gate-1 sign-off object.

**P1 — Every advance lands a story.**
Every week-advance surfaces at least one salient narrative card with a face, a number, and a consequence — and at least one active hook is always within three weeks of resolving.
*Test:* instrument the ten-season soak — zero silent weeks; automated hook-horizon audit (nearest unresolved storyline ≤3 weeks away in ≥95% of weeks).
*Trace:* MAD-14, FM-01/02, ADJ-29, ADJ-42, ADJ-47.

**P2 — Nothing pays in silence.**
Every sim consequence the player caused — cap, morale, development, job security, records — is witnessed: staged reveal or card, with its cause attached.
*Test:* an event-to-witness coverage matrix in the engine/UI contract; CI fails when a player-visible state change has no witnessing surface. The simulated-phase contract (RB-40) is the special case for phases resolved without input.
*Trace:* ADJ-43, MAD-06, RB-05/07, FM-04.

**P3 — The advance is faster than doubt.**
Week advance under 150ms; a complete fast session (open → advance → read → close) under 3 minutes one-handed; a full played game under 8 minutes; management interstitials under 1 minute.
*Test:* perf budgets asserted in CI; timed session walkthroughs at phase gates.
*Trace:* ADJ-14, RB-03, RB-29, STATUS.md contract.

**P4 — Numbers are staged, never dumped.**
Every headline number (cap space, overall reveal, final score, draft pick, record broken) has a staging spec — sequence, sound/haptic pairing, Reduce Motion variant — and no hero surface's first render is a wall of undifferentiated figures.
*Test:* DESIGN.md carries a staging spec per headline moment; the ≥17/20 re-audit includes a staging-spec-exists check for the three hero surfaces (gameday, season hub, player card).
*Trace:* ADJ-35, ADJ-36, ADJ-37, ADJ-38, MAD-01, MAD-04.

**P5 — Every number has a face.**
Every narrative card names a person, never only a team stat; featured players carry arcs (fragility, milestones, promises) under the attention budget (1–2 traits, one relationship fact); every player has a permanent career ledger the UI can open.
*Test:* card-template audit (no faceless cards); player card shows the ledger; soak counts ≥N featured-player arc events per season per team.
*Trace:* RB-41, RB-06, FM-07, MAD-13/39 (as bounded by §3), ADJ-44.

**P6 — Losing opens a chapter.**
Every failure state routes to a named next arc — hot seat, rebuild, fired-and-rehired — and the copy frames collapse as a chapter, not an end. No dead ends, ever.
*Test:* soak assertion — every fired/expired-contract path lands on an offer or an explicit sit-out-year arc (already an engine invariant; now also a presentation requirement: the arc is *announced*).
*Trace:* ADJ-39, ADJ-45, FM-05, 01-RESEARCH §H (job-market dead ends = community complaint #2).

---

## 5. Root-cause map → what the rebuild must contain

| Debt (§1.4) | Owner | Where it gets paid |
|---|---|---|
| Craft | Build plan gates | Platform physics baked into every phase: re-audit ≥17/20, zero P0/P1, Dynamic Type/contrast/44pt/Reduce Motion as construction requirements; async persistence (the P0) fixed in the architecture, not patched |
| Feel | New DESIGN.md | The time layer as first-class content: motion vocabulary, sound/haptic language, number staging specs, response budgets, Reduce Motion variants — stress-tested at gate 2 on gameday, season hub, player card |
| Witness | New 02/03/04 | The narrative delivery pipeline as an architectural concern: event → salience → casting → card feed → permanence surfaces; the five broadcast slots; P1/P2 as acceptance tests |
| Identity | New DESIGN.md + PRODUCT.md | The broadcast register (T3): positive commitments, in-fiction voices, staged celebration — an identity stated by what it does, not only what it refuses |

## 6. Open decisions for the owner (gate 1)

- **OD-1 (voice amendment, T3):** in-fiction media voices get personality license; system voice stays sober. Approve or keep the single-voice rule.
- **OD-2 (Retro Bowl's role, T6):** confirm On the Field remains a third never-required mode and the fast loop's immediacy is the management game. (Matches standing scope; re-confirmed because the hybrid brief names Retro Bowl as a pole.)
- **OD-3 (blocking cards, T1):** deadline-semantics-only blocking. Cheap to revisit at gate 2 with mockups in hand.
- **OD-4 (casting engine scope):** news engine v1 = salience-matched templates; Wildermyth-style casting as architecture option. Decide at gate 3 (architecture) with authoring-math in hand (see risks).

**Known risks and gaps carried forward:**
- Template-library sizing math (how many templates survive a 10-season soak without oatmeal — MAD-25, ADJ-47/48) must be done before the narrative layer's scope locks (gate 3 input).
- Dossier citations were gathered live by research agents but the independent citation spot-check pass was skipped on owner instruction ("proceed with what you have"); headline claims in §1–§4 rest on multi-source findings, but a background verify pass on load-bearing single-source findings (marked Medium/Low in the dossiers) is recommended before gate 3.
- FM Touch/Mobile reception — the closest analog to one-thumb management — is an evidence gap (R1c OQ-2) worth one targeted sweep before session design locks.
- R1b/R1d note their local-context input arrived empty at assembly time; their §9 relevance maps were grounded in the program brief and verified here against the actual local docs — no contradictions found, and this synthesis supersedes those sections where they differ.
