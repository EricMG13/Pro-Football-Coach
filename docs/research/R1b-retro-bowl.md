# R1b — Retro Bowl Dossier

**Program:** Pro Football Coach rebuild — R1 evidence base (per-game dossiers feeding R2-synthesis)
**Date:** 2026-08-09
**Lenses:** (a) Why it works, as mechanisms — one-thumb controls, session architecture, star attachment, management abstraction, New Star Soccer lineage, scope discipline, virality and longevity. (b) Limits and failure modes per its own community and critics — where a fast-session football sim hits the depth wall.
**Sources:** 46 unique citations [S1]–[S46], gathered live from the web by the lens agents and deduplicated here.
**Confidence:** High unless marked; Medium/Low flagged inline. Sources readable only as search excerpts are marked (excerpt) in §11.

## 1. Scope & method

- Two research agents ran independent lenses over Retro Bowl (New Star Games / Simon Read): a mechanisms lens (why it works) and a failure lens (where it breaks). Their structured findings are merged here; where they overlap they are consolidated, and where they conflict both are kept with the conflict flagged (RB-23 vs RB-31; RB-24 vs the §4 findings). Conflicts are inputs to R2-synthesis, not resolved here.
- Every substantive finding carries a stable bold ID (**RB-01**–**RB-42**), numbered continuously. Downstream design documents cite these IDs; they are never renumbered. Each sourced finding ends with its [S#] refs; unsourced synthesis appears only as marked "Inference" with one line of reasoning.
- Recency: market and update findings were checked against 2025–26 sources where noted (RB-32, RB-33, RB-34).
- Known gaps: reddit.com is blocked to research crawlers, so r/RetroBowl sentiment is triangulated through App Store reviews, developer interviews, and search excerpts. Several Retro Bowl Wiki (Fandom) pages and three other sources were readable only as search excerpts (marked in §11). Retro Bowl College and the unrelated indie game College Bowl are easily confused in search results — see RB-35 for the correction.
- The dedicated local-context payload for this run arrived empty; the §9 mapping is grounded in the program brief (hybrid rebuild of a mechanically-complete-but-bland iPhone franchise sim), CLAUDE.md constants (32-team fictional league, offline, no accounts, one-thumb iPhone), and the v1 inventory as summarized in program memory. Exact audit class names live in the audit doc.

## 2. The game in one page

Retro Bowl is an 8-bit American football franchise game by New Star Games (Simon Read), launched on iOS/Android in January 2020 and later ported to Switch and PC [S1][S7]. The player is coach/GM of a pro team. On the field you play offense only — drag back from the quarterback and release to throw, slide to evade as ball-carrier — while defensive drives resolve as text commentary [S13][S15][S16]. Off the field you run a deliberately tiny franchise: about ten named players, two coordinators, a three-round draft with a scouting cap, and a single coaching-credits currency that funds facilities, staff, morale meetings, and even cap space [S9][S10]. A full game takes under eight minutes; a season is 17 games plus playoffs; management beats between games take under a minute [S15][S16].

Reception and trajectory: Metacritic 84 with a 100% OpenCritic recommend; Nintendo Life 9/10; a 4.8-star average across nearly a million mobile reviews [S7][S14][S2]. After an Apple feature and a school-age TikTok wave, it peaked at #1 in downloads among all US App Store apps in autumn 2021, with zero paid user acquisition [S1][S2]. The formula descends from New Star Soccer (2012; BAFTA Sports/Fitness winner 2013): play only the critical moments as tactile minigames and wrap them in off-field pressure [S3][S8]. It has since forked into separate SKUs — Retro Bowl College (2023) and the NFL/NFLPA-licensed NFL Retro Bowl '25 and '26, Apple Arcade exclusives, the '26 edition finishing as the #1 Apple Arcade game of 2025 [S7][S37][S38][S39].

The critical consensus locates the magic in ruthless subtraction — an almost flawless grasp of what to leave out — and the failure literature locates the ceiling in exactly the same place: a loop that repeats identically, a sim whose causality is invisible, and a GM layer that is triage rather than dealmaking [S17][S18][S21].

## 3. Why players love it — mechanisms

**RB-01 — Offense-only is a deliberate inversion; defense is a management output.** The player controls only attacking phases; opponent drives resolve as text commentary, and defensive quality is something you buy through roster and coordinator investment rather than a second skill test. Read's stated rationale: defending is, in his words, "generally less fun to play." Reviewers explicitly compare the defense presentation to Football Manager's text commentary. See RB-12 for the cost of shipping this cut without visible causality. [S4][S13][S14][S15][S22]

**RB-02 — The entire on-field game runs on one finger and two verbs.** Drag back and release to throw (arc set by the drag), slide to evade as ball-carrier; tapping the RB pre-snap converts the called play into a run; stiff-arms and hurdles auto-trigger from ratings. Each called play bundles a designed run and a designed pass, and the player chooses which to attempt at the snap. [S11][S16]

**RB-03 — Session architecture: every pocket session ends at a natural boundary.** Quarter length is selectable at 1/2/3 minutes (default 2); a full game fits in roughly 5–8 minutes; a season is 17 games plus playoffs; management beats between games take under a minute. Explicitly designed for short bursts. Benchmark numbers for any fast mode. [S14][S15][S16]

**RB-04 — Management is compressed to ~10 named players; drafting is fast but gambley.** The ideal roster is 1 QB, 1 RB, 1 TE, 2 WR, 5 defenders (hard max 12 paid) plus two coordinators; everyone else is anonymous filler. Three-round draft, one pick per round unless traded for more, a 10-prospect scouting cap, and potential hidden until scouted. [S10][S16]

**RB-05 — One currency funds everything, fusing winning, popularity, and infrastructure into a single loop.** Coaching credits buy facilities, coordinator extensions, morale meetings, and even a raised salary cap (100 credits); credits are earned chiefly via fan-support thirds (max 3 per game), so tanking cascades — no fans, no credits, no upgrades, injured stars. The cap exists but is deliberately backgrounded: a purchasable ceiling, not a spreadsheet. [S9][S13]

**RB-06 — Star attachment is manufactured through scarcity plus fragility.** Few named players; XP leveling with rising costs toward capped potential; morale that can rot to a Toxic state carrying team-wide penalties; condition and injury risk; and random discipline events (missed practice, legal trouble) that force coach decisions. Winning repairs morale. [S10][S16]

**RB-07 — Press duties are one-tap dilemmas that route a single scarce boost.** Post-game and weekly prompts force a choice among stakeholders — praise the player (his morale), the coaching (coordinator morale), the fans (fan support), or the owner (an extra credit). Because the boosts are mutually exclusive, every media answer is a real resource-allocation choice rather than flavor text. [S14][S16][S28]

**RB-08 — Critics locate the magic in ruthless subtraction, and the sparse presentation does narrative work.** GamesRadar credits an almost flawless sense of what is essential versus omissible and argues the low-fi presentation makes players imagine the drama themselves; Nintendo Life attributes the addictiveness to design rather than complexity or realism; Operation Sports ranks it among the greatest football games made. Metacritic 84; OpenCritic 100% recommend. [S7][S14][S16][S17]

**RB-09 — Difficulty is tuned through economy and escalation, not input complexity.** (Medium) Weak starting teams are credit-poor; an optional Dynamic difficulty scales with success; later seasons get materially harder; and frequent turnover events — fumbles especially, the most common critical complaint — inject swing drama. Fun-but-challenging here means resource pressure plus drama events, not harder controls. [S11][S13][S14][S16]

**RB-10 — Mastery is reading the sim, not executing inputs.** (Medium) Defenses show legible pre-snap shells (two-high, single-high, all-out blitz); audibles are a scarce per-game resource; there are no penalties, so throwaways are free. Skill lives in decision quality under the clock: field position, timeouts, fourth downs. [S11]

**RB-11 — The retro aesthetic is a targeting decision, not just a style.** (Medium) Read aimed at lapsed 30-something console kids — the Tecmo Bowl generation — with 8-bit players in pro uniform colours, repeating the New Star Soccer strategy of courting lapsed Sensible Soccer players through direct touchscreen tactility. [S1][S3]

## 4. Where it fails — the failure literature

**RB-12 — Because defense is a pure sim, players experience it as rigged dice.** Outcomes read as scripted momentum rather than consequences of the roster you built: Pocket Tactics likens defense to gambling (decent opponents score on every drive), and a hostile longitudinal review reports a 5-star defense reliably conceding late touchdowns to 2-star offenses, dismissing the product as half a game decided by dialogue boxes. Invisible variance is read as scripting and breeds distrust. [S18][S20]

**RB-13 — The dynasty snowball breaks the game within roughly five seasons.** One dominant strategy (feeding the RB through the air, perpetual 2-point tries) plus static AI makes every game winnable past season 5; the long-run reviewer began intentionally losing for challenge and scored the extended experience 4.5/10 — enjoy briefly, then forget. [S21]

**RB-14 — Staleness is broadly echoed, and its shape is specific: loop-sameness, not content shortage.** Metacritic users call the weekly loop repetitive and monotonous and find difficulty either trivial on lower settings or artificially restrictive on higher; long-term App Store reviewers report it catching up after months; Switch reviews note the scenarios repeat. Season-over-season novelty, not more teams or modes, is what is missing. [S14][S23][S26]

**RB-15 — The difficulty ceiling works by erasing opponent identity.** (Medium; single excerpt source) Extreme difficulty makes every opponent play as a 5-star team regardless of actual rating, which destroys scouting and opponent-prep value; community guides document undefeated debut seasons on Extreme regardless. [S30]

**RB-16 — Opponent differentiation is cosmetic and numeric.** (Medium) Team identity is uniforms plus offense/defense/special-teams star ratings — no schemes, no coach identities, no tendencies. Critics cite an information vacuum limiting strategic engagement; similarly rated opponents feel interchangeable. [S18][S22]

**RB-17 — The GM game is one-way roster triage, not deal-making.** (Medium) Ten star players (12 paid) atop replacement-level filler; the trade option only sells players for value and converts into a cut button after week 8; the $150M cap forbids an all-5-star roster. Players seeking the GM fantasy of acquisition via negotiation get only disposal. [S12][S33]

**RB-18 — League and stat history is missing; the community does the bookkeeping by hand.** (Medium) Career stats survive only while you coach that team, and a reviewer judged the franchise layer illusory depth; r/RetroBowl maintains a manual Record Book to fill the gap (triangulated via search-visible thread titles; Reddit itself was inaccessible). [S23][S34]

**RB-19 — Roster churn frustration centers on opaque, abrupt retirements.** (Medium; triangulated from Q&A/explainer pages) Stars can quit around 29 after decline or injury with little telegraphing (typical ranges ~32–34, QBs ~36); the question is common enough to sustain an ecosystem of explainer pages. Losing a star reads as a rug-pull, not an arc. [S22][S35]

**RB-20 — Kicking friction registers mostly as a trust issue.** (Low) The FG minigame is a power bar plus wind-shifted aim, with 60-yarders gated on maxed kick power; complaints exist about wind, inconsistency, and sim-stat mismatches (a kicker missing twice on screen while the box score records him perfect), but kicking could not be verified as a top-tier grievance. [S23][S32][S36]

**RB-21 — Retro Bowl College's added depth largely landed as upkeep chores.** GPA/morale micromanagement and negative-event spam are the top complaints in its App Store reviews (4.3/5, ~10K ratings), alongside defenses that concede almost every possession and missing college-fantasy systems (transfer portal, NIL, redshirts). Depth delivered as recurring maintenance reads as punishment; depth as meaningful choices is what was asked for. [S24]

**RB-22 — A same-formula spin-off earned no second press cycle.** (Medium) Retro Bowl College is critically invisible next to the original — no Metascore, four user ratings, coverage reduced to patch-note churn — versus the original's scored 8–9/10 press. A successor needs a visibly new answer to be a story. [S14][S18][S27][S45]

**RB-23 — Monetization friction: the free game gates core verbs, and the licensed editions are subscription-locked.** Kick returns (mobile), the 12-man roster, the editor, weather, and replays sit behind the $0.99 Unlimited unlock; critics read this as the game intentionally worsening itself to sell the fix; coach credits are scarce early and trivial later, inverting the difficulty curve; NFL Retro Bowl '25/'26 require Apple Arcade at $6.99/month, which reviewers resent. Conflicts with RB-31. [S19][S20][S21][S25][S31]

**RB-24 — Load-bearing counterpoint: the shallowness is the product.** Read refuses features that risk the balance; sessions stay minutes long; critics score it 8–9/10 anyway, crediting the management layer (morale, condition, contracts) with carrying the strategy the field play cannot. Conflict: this sits in direct tension with RB-12 through RB-19 and with the GM-depth wishlist (RB-36) — the complaint record shows players want the GM ceiling raised, not the play sessions lengthened. Both readings are preserved for R2. [S1][S14][S18][S22]

## 5. Development history & postmortem signal

**RB-25 — Retro Bowl is a minigame that grew a management shell, not a sim that grew an arcade mode.** It began as a high-school life RPG (grades, family, health) containing a football minigame; when the RPG stalled, Read kept the minigame and wrapped a franchise layer around it. Seeing 8-bit players in pro uniform colours clarified the direction. [S1]

**RB-26 — Built in about seven months, essentially solo, by a football outsider.** July 2019 to a January 2020 launch, in GameMaker, with pixel artist John Savage recruited via Twitter. Read barely knew the sport and learned it by watching live NFL broadcasts while coding — he modeled what is legible on TV, not the rulebook, which acted as an abstraction filter. [S1]

**RB-27 — The formula descends from New Star Soccer: tactile key moments plus relationship pressure, with a swappable wrapper.** NSS mobile (2012; BAFTA winner 2013; ~10M downloads) plays only the critical match moments as minigames surrounded by off-field pressures — five relationships (boss, team, fans, girlfriend, sponsors) fed by an energy economy. Retro Bowl swapped the life-sim wrapper for team management and kept the moments-only core: the stable invariant across both hits. [S3][S8][S29]

**RB-28 — Virality: platform features, season timing, and TikTok, on zero user-acquisition spend.** January 2020 launch with an Apple pre-Super-Bowl feature; the explosion came September–October 2021 when an Apple feature, the NFL season start, and a school-age TikTok wave pushed it to #1 in downloads among all US App Store apps — 7M total downloads by October 2021, over a third of them in the final month. [S1][S2][S7]

**RB-29 — Retention embedded in the school routine.** DAUs rose across weekdays and dropped at weekends — the inverse of normal mobile patterns — while the 4.8-star average across nearly a million reviews kept organic acquisition compounding. Sub-8-minute complete games are what made class-break play possible at all. [S2]

**RB-30 — Scope discipline is explicit policy: requested depth becomes a new SKU, never core dilution.** Read receives daily requests for online play, controllable defense, full rosters, and college teams, and refuses them in place as balance risks; expansions ship as separate products (Retro Goal, Retro Bowl College, NFL editions). Start small and ship is stated doctrine; the studio was still seven people in 2021. [S1][S5][S7]

**RB-31 — Monetization is trust-first and nearly premium.** Free for four games, then a $0.99 one-time unlimited unlock; credits earnable in normal play; a fully unlocked Retro Bowl+ joined Apple Arcade in June 2023. The generosity is inseparable from the 4.8-star rating and the school-age spread. Conflict: RB-23 documents the same structure experienced as verb-gating and grind — generous by mobile-genre standards, frictious by premium standards. Both kept for R2. [S3][S7][S16]

**RB-32 — Longevity is exceptional and converted into the NFL's own license.** Retro Bowl College (Sept 2023; 250 teams); NFL/NFLPA-licensed NFL Retro Bowl '25 (Sept 2024, Apple Arcade exclusive); NFL Retro Bowl '26 (Sept 2025) with a live-season leaderboard mode tied to the real NFL schedule — the #1 Apple Arcade game of 2025, ahead of NBA 2K25 — while the 2020 original still drew ~100k monthly downloads in late 2024. [S7][S37][S38][S39][S40][S41]

**RB-33 — New Star's own updates concede the long-career grind.** 2025–26 patches added full-game sim with takeover interrupts, a league history screen, roster/practice-squad/dev-trait options, and rotating Game Center challenges — external goals rather than deeper systems. Sim-to-any-point with takeover is table stakes for multi-season play; even Retro Bowl retrofitted it. [S43][S44]

## 6. Community signal

**RB-34 — Playable or callable defense is the single most persistent unmet request, six-plus years running.** Read himself reports daily requests for it; App Store reviews for Retro Bowl, RBC, and NFL Retro Bowl '26 still ask to play or choose defense as of January 2026, while updates shipped cosmetics and challenges instead. Interactive defense — even play-calling only — is differentiating space the franchise has formally ceded. [S1][S23][S24][S25][S44]

**RB-35 — Correction for the record: Retro Bowl College has NOT added defensive play-calling.** Its only defensive nod is labeling opposing defensive stars (July 2024 patch); current RBC reviews still complain defense cannot be played or set. The timed defensive play selection sometimes attributed to it belongs to College Bowl, an unrelated indie game. Do not cite RBC as retrofit precedent — New Star's refusal to retrofit defense into a shipped balance is itself evidence of how hard the retrofit is. [S24][S42][S46]

**RB-36 — The community wishlist clusters on GM depth, not on-field depth.** Reviewers ask for two-way player/pick trades and a trade block, a deeper draft process, real free agency, roster transparency, and kick-return TDs — exactly the transactional, multi-season tooling the developer defers to sequels. [S1][S23]

**RB-37 — Long-form creator series were the first growth engine, and they showcase the management layer.** Wikipedia credits YouTube franchise-rebuild creators (JefeZhai, HostileBeast, RetroSportRadio) for the 2020 growth wave, a full year before TikTok: multi-season save narratives acted as slow-burn marketing. Evidence that the GM/dynasty layer, not just the arcade layer, is what is shareable. [S7]

**RB-38 — The community patches the missing late game with self-imposed constraints.** (Medium) Once the snowball hits, players invent their own difficulty: intentional losing, no-star challenges, and manual record-keeping (see RB-18). Self-imposed challenge is the visible symptom of absent late-game systems. [S21][S34]

## 7. Mechanics anatomy relevant to Pro Football Coach

Anatomy of the reusable machines, with inference findings where the synthesis is ours.

**Verb economy.** Two motor verbs (drag-throw, slide-evade) plus binary pre-snap choices carry the whole on-field game (RB-02); mastery then migrates to reading — coverage shells, clock, fourth downs (RB-10). The motor ceiling stays low while the decision ceiling stays high; that split is what makes one-thumb play compatible with skill expression.

**RB-39 — Inference: the run/pass bundle is a general decision-compression pattern.** One play call carrying two prepared branches, chosen after information reveals, compresses play-calling into a single legible read (RB-02). The same pattern fits a play-calling-only defense — pick a shell, adjust on the offense's look — with no motor controls at all. Reasoning: College Bowl shipped exactly this in a retro-football package (RB-35), and callable defense is the market's most persistent unmet ask (RB-34).

**RB-40 — Inference: the simulated-phase contract — a phase may be cut from play only if its causality is inspectable.** RB-01 (defense as investment) and RB-12 (defense as rigged dice) are the same mechanic seen from opposite sides: players accept not playing defense, but they do not accept not seeing why a 5-star defense failed. Reasoning: the identical investment loop is loved where its effects are legible (RB-05's fan-credit cascade) and distrusted where they are not (RB-12).

**RB-41 — Inference: attachment is a function of named-entity count and fragility, not simulation fidelity.** The 10-player cut (RB-04) plus fragility systems (RB-06) produce the star attachment, and the sparse presentation amplifies it by leaving room for imagination (RB-08). A 53-man pro roster reproduces this only through a deliberate foreground/background split: a handful of featured players with arcs and events, the rest resolved as filler. Reasoning: roster size is the main structural difference between RB's beloved stars and a full sim's anonymous 53.

**RB-42 — Inference: the single-currency loop is legible because every system pays into and draws from one pool.** Credits fuse winning, popularity, and infrastructure into one feedback cycle, with the salary cap demoted to a purchasable ceiling (RB-05). Adding parallel co-equal pressures is what turned RBC's extra depth into chores (RB-21). A pro sim that keeps a real cap must pick one primary pressure per mode rather than run two currencies at equal weight. Reasoning: RBC is the natural experiment — same formula, more dials, worse reception.

**Difficulty model.** Escalate via economy and season pressure (RB-09), never via uniform stat inflation (RB-15): inflation erases the scouting and preparation game that behavioral opponent identity would otherwise create (RB-16).

**Session scaffolding.** Numbers to hold: complete game under 8 minutes, management interstitial under 1 minute, season completable in a few evenings (RB-03); sim-to-any-point with takeover interrupts from day one (RB-33).

**Trust surface.** Displayed stats must match what the player watched (RB-20); decline and retirement must be telegraphed (RB-19); league history must persist (RB-18). All three are cheap; all three are trust infrastructure.

## 8. Preliminary steal / adapt / avoid

PRELIMINARY — final rulings happen in R2-synthesis.md against the other dossiers, not here.

| Verdict | Mechanism (findings) | One-line rationale |
|---|---|---|
| Steal | Session architecture: <8-min games, <1-min beats (RB-03) | Proven fast-mode shape; it is what enabled the class-break virality (RB-29). |
| Steal | Press dilemmas routing one scarce boost (RB-07) | Cheap to build, a real trade-off per tap, outsized narrative payoff. |
| Steal | Scouting cap + hidden potential in the draft (RB-04) | Keeps drafting fast and gambley without spreadsheet homework. |
| Steal | Discipline/fragility events on stars (RB-06) | Manufactures attachment and coach decisions at low system cost. |
| Steal | Sim-with-takeover interrupts (RB-33) | Table stakes for multi-season play; even RB had to retrofit it. |
| Steal | Persistent league history and records (RB-18) | The community does it by hand today; cheap dynasty depth. |
| Adapt | Offense-only play, defense as investment (RB-01) | Keep the cut, add the receipts (RB-40) and callable defense (RB-34, RB-39). |
| Adapt | Radical roster compression (RB-04, RB-41) | Pro realism needs 53; foreground featured players, background the rest. |
| Adapt | Single-currency fused economy (RB-05, RB-42) | Fast mode gets one fused pressure; deep mode promotes the real cap. |
| Adapt | Run/pass bundled play call (RB-02, RB-39) | Generalize the compression pattern to defensive play-calling. |
| Adapt | Economy-driven difficulty (RB-09) | Keep resource pressure; replace rubber-banding with opponent identity (RB-16). |
| Adapt | Sparse presentation as narrative engine (RB-08) | Our broadcast layer should evoke rather than enumerate — under-specify deliberately. |
| Avoid | Invisible defensive variance (RB-12) | Reads as scripting; poisons trust in the entire sim. |
| Avoid | Difficulty via uniform stat inflation (RB-15) | Destroys scouting and prep; opponents should differ, not inflate. |
| Avoid | Disposal-only GM (RB-17) | Triage is not dealmaking; two-sided trades are the felt difference. |
| Avoid | Depth delivered as weekly upkeep (RB-21) | RBC's morale/GPA babysitting shows maintenance reads as punishment. |
| Avoid | Untelegraphed retirements (RB-19) | Star loss must read as an arc, not a rug-pull. |
| Avoid | Gating core verbs behind purchases (RB-23) | We are premium-complete; completeness is the trust asset (RB-31 conflict noted). |
| Avoid | Shipping a same-formula successor (RB-22) | A rebuild without a visibly new answer earns no attention cycle. |

## 9. Relevance map to Pro Football Coach

Grounding: PFC v1 is a mechanically complete but bland offline iPhone franchise sim — 32 fictional teams, a full cap/draft/free-agency/trade/depth-chart/schedule chassis, deterministic FootballSimCore engine — and the rebuild is a Madden × Retro Bowl × FM hybrid with a fast/deep session split under hard constraints: offline, fictional clean-room content, one-thumb phone play.

**Against the v1 inventory.** v1 already owns the exact GM chassis Retro Bowl players have begged for, unmet, for six years: two-sided trades, real free agency, a real cap, a full draft (RB-17, RB-34, RB-36). That is the inherited advantage — and the dossier's warning is that those mechanics alone did not make RB fun, nor did their absence make it fail (RB-24). What v1 lacks maps directly onto what RB has: session-bounded play (RB-03), a fused economy loop (RB-05), star fragility events (RB-06), press dilemmas (RB-07), and a persistent-history surface (RB-18 — v1 tracks stats; the record-book presentation is the missing cheap win). v1's XP/progression layer paid out silently until recently audited; RB-06 and RB-07 describe the event scaffolding that makes progression felt rather than logged.

**Against the audit failure classes.** The audit verdict — complete but bland — decomposes on this evidence into: (a) no attachment surface, answered by RB-41's foreground/background roster split plus RB-06 fragility; (b) invisible causality, answered by RB-40's simulated-phase contract — the difference between our text sim reading as FM-style commentary or as RB-12's rigged dice; (c) undifferentiated opponents, answered by RB-16 — identity must be behavioral (schemes, tendencies, coach personas), which the engine can drive but the presentation must surface; (d) unfelt progression, answered by RB-05/RB-07 routing every gain through a visible choice or event. (Mapping is against the audit verdict as summarized in program memory; exact class names live in the audit doc.)

**Against the fast/deep session split.** RB is the calibration standard for the fast half: complete game under 8 minutes, interstitials under a minute (RB-03), one fused pressure (RB-42), scout-capped drafting (RB-04). The failure lens marks the boundary the deep half must not push across into fast: weekly upkeep chores (RB-21), parallel co-equal currencies (RB-42), spreadsheet-first cap surfaces (RB-05 shows the cap can be backgrounded in fast mode while deep mode promotes it). RB-13/RB-14 set the staleness clock — roughly five seasons on a static loop — which is the burden the FM-side emergent-narrative systems must carry, because RB proves content volume does not fix loop-sameness.

**Against the hard constraints.** One-thumb phone: RB-02 is the existence proof that a complete football game fits one finger and two verbs, and RB-39 shows the same compression covers play-calling — the On the Field mode has a verb budget, not just an inspiration. Offline: RB's loop is offline-complete, and its growth was organic and clip-able (RB-28, RB-37) — creator-shareable dynasty moments, not accounts or online play, carried distribution, so no-network is not a growth blocker. Fictional clean-room: pre-license Retro Bowl built all of its attachment on fictional rosters (RB-04, RB-06), so fictional names do not impede star attachment; meanwhile the NFL-licensed editions are locked behind Apple Arcade (RB-23, RB-32), leaving the open-App-Store, one-price, pro-management niche unoccupied — which is PFC's positioning. Per the program's legal guardrail, this dossier informs mechanisms only, never assets, names, or text. Solo-scale build: RB-26 and RB-30 validate the program's one-phase-at-a-time discipline — seven months, subtraction, and feature requests answered by refusal rather than accretion.

## 10. Surprises & open questions

Surprises (merged from both lenses):

- A gray-market web ecosystem (unblocked clone sites, the Poki browser build) made RB playable on school Chromebooks; browser distribution was load-bearing for the school-age phenomenon and now pollutes search-based research with SEO clones.
- YouTube franchise-rebuild creators drove the first growth wave in 2020, a full year before TikTok — long-form multi-season save content, i.e. the management layer, is what proved shareable (RB-37).
- The virality converted into the NFL's own license: annual NFL Retro Bowl editions are Apple Arcade exclusives coexisting with EA's Madden console license — and the licensed pro version being subscription-locked leaves the open-store premium niche empty (RB-32, RB-23).
- TheSixthAxis reached for a Football Manager comparison to describe an arcade game's defense — text simulation is a first-class presentation mode, not a fallback (RB-01).
- The franchise wrapper was Read's second wrapper around the same minigame core; NSS wrapped it in a life sim whose monetization drew complaints, and RB's near-premium model reads as the deliberate correction (RB-27, RB-31).
- The formula's measured staleness ceiling is about 4–5 seasons (RB-13, RB-14) — onset in a handful of seasons, not decades — and the community's response is inventing its own constraints (RB-38).
- Research hazards found the hard way: College Bowl (unrelated indie with timed defensive play-calling) is easily confused with Retro Bowl College (RB-35), and reddit.com is blocked to research crawlers, so r/RetroBowl evidence is triangulated, not direct.

Open questions (for R2 or a later research pass):

1. What does inspectable causality concretely look like for a simulated defensive phase on a phone — box-score deltas, annotated drive logs, coordinator postmortems? RB-40 names the contract, not the UI.
2. Where is the staleness wall for a sim with FM-grade emergent narrative — does it actually move past RB's ~5 seasons, and what playtest proxy would measure it? (RB-13, RB-14)
3. Can two-sided trades and real free agency coexist with a fused single-pressure economy in fast mode, or does dealmaking force the deep mode's cap forward? (RB-36 vs RB-42)
4. Is the kicking sim-vs-display mismatch (RB-20, Low) a real trust wound at scale? Cheap to prevent regardless; verify before spending design effort.
5. How much session time does play-calling-only defense cost — does a College Bowl-style timer keep full games inside the 8-minute budget? (RB-35, RB-39, RB-03)
6. Is there a statable rule separating depth-as-choices from depth-as-upkeep (RB-21) that owner-gate reviews can apply mechanically?
7. Direct r/RetroBowl wishlist data remains uncollected; budget a workaround (manual export, third-party archives) if community evidence needs strengthening.

## 11. Sources

Deduplicated across both lenses; 46 entries. Entries marked (excerpt) were readable only via search excerpts and should be treated as weaker evidence.

- [S1] How Retro Bowl went from a simple RPG to a number one sports game (Simon Read making-of) — https://www.pocketgamer.biz/new-star-games-simon-read-retro-bowl-making-of/ — postmortem/interview
- [S2] UK-based New Star Games takes US by storm with Retro Bowl — https://www.pocketgamer.biz/uk-based-new-star-games-takes-us-by-storm-with-retro-bowl/ — news
- [S3] New Star Soccer creator Simon Read on how his smartphone sim transcends the traditional football game genre — https://www.pocketgamer.com/new-star-soccer/new-star-soccer-creator-simon-read-on-how-his-smartphone-sim-transcends-the-trad/ — interview
- [S4] From Retro Bowl to Retro Goal — How New Star Games returned to its grass roots (Nintendo Life) — https://www.nintendolife.com/features/from-retro-bowl-to-retro-goal-how-new-star-games-returned-to-its-grass-roots — interview
- [S5] Q&A: Simon Read, Founder of New Star Games on Retro Goal (MCV/DEVELOP) — https://mcvuk.com/business-news/qa-simon-read-founder-of-new-star-games-on-retro-goal/ — interview
- [S6] FAQ: New Star Soccer creator Simon Read (MCV/DEVELOP) — https://mcvuk.com/development-news/faq-new-star-soccer-creator-simon-read/ — interview (gathered as background; not load-bearing for any finding)
- [S7] Retro Bowl — Wikipedia — https://en.wikipedia.org/wiki/Retro_Bowl — wiki
- [S8] New Star Soccer — Wikipedia — https://en.wikipedia.org/wiki/New_Star_Soccer — wiki
- [S9] Rob's Complete Guide to Retro Bowl: The Front Office — https://robwritesaboutwhatever.com/2021/04/15/robs-complete-guide-to-retro-bowl-part-1-how-to-build-a-winning-front-office/ — community guide
- [S10] Rob's Complete Guide to Retro Bowl: Drafting and Managing Players — https://robwritesaboutwhatever.com/2021/04/22/robs-complete-guide-to-retro-bowl-drafting-and-managing-players/ — community guide
- [S11] Rob's Complete Guide to Retro Bowl: Winning Football Games — https://robwritesaboutwhatever.com/2021/04/27/robs-complete-guide-to-retro-bowl-winning-football-games/ — community guide
- [S12] Rob's Complete Guide to Retro Bowl: Roster Basics and Player Evaluation — https://robwritesaboutwhatever.com/2021/04/20/robs-complete-guide-to-retro-bowl-roster-basics-and-player-evaluation/ — community guide
- [S13] Retro Bowl Review (TheSixthAxis) — https://www.thesixthaxis.com/2022/02/11/retro-bowl-review-switch-pc-android/ — review
- [S14] Review: Retro Bowl (Switch), 9/10 (Nintendo Life) — https://www.nintendolife.com/reviews/switch-eshop/retro-bowl — review
- [S15] Review: Retro Bowl (Nintendo Switch) (Pure Nintendo) — https://purenintendo.com/review-retro-bowl-nintendo-switch/ — review
- [S16] Retro Bowl Review: A Mobile Game That Transcends the Platform (Operation Sports) — https://www.operationsports.com/retro-bowl-review-a-mobile-game-that-transcends-the-platform/ — critical analysis
- [S17] Retro Bowl's addictive simplicity makes it one of the best sports games in recent years (GamesRadar+) — https://www.gamesradar.com/retro-bowls-addictive-simplicity-makes-it-one-of-the-best-sports-games-in-recent-years/ — critical analysis
- [S18] Retro Bowl review (Pocket Tactics) — https://www.pockettactics.com/retro-bowl/review — review
- [S19] Retro Bowl review for Nintendo Switch (Gaming Age) — https://gaming-age.com/2022/02/retro-bowl-review-for-nintendo-switch/ — review
- [S20] Death By Algorithm: Retro Bowl Seasons 1-5 Review (In Review Critics) — https://inreviewcritics.com/2020/05/18/death-by-algorithm-retro-bowl-mobile-game-review-seasons-1-5/ — critical analysis
- [S21] Beyond Pay-To-Win Mechanics: Retro Bowl Seasons 6-32 Review (In Review Critics) — https://inreviewcritics.com/2020/07/30/beyond-pay-to-win-mechanics-retro-bowl-seasons-6-32-mobile-game-review-free-version/ — critical analysis
- [S22] Retro Bowl Is The Best Mobile Football Game Out Right Now (Ego Clown) — https://www.egoclown.com/articles/retro-bowl-americas-greatest-mobile-game — critical analysis
- [S23] Retro Bowl — App Store ratings and reviews — https://apps.apple.com/us/app/retro-bowl/id1478902583?see-all=reviews — community
- [S24] Retro Bowl College — App Store ratings and reviews — https://apps.apple.com/us/app/retro-bowl-college/id1632904520?see-all=reviews — community
- [S25] NFL Retro Bowl '26 — App Store ratings and reviews — https://apps.apple.com/us/app/nfl-retro-bowl-26/id6476767864?see-all=reviews&platform=iphone — community
- [S26] Retro Bowl user reviews (Metacritic) — https://www.metacritic.com/game/retro-bowl/user-reviews/ — community
- [S27] Retro Bowl College (Metacritic) — https://www.metacritic.com/game/retro-bowl-college/ — community
- [S28] Retro Bowl Guide: Tips, Tricks & Strategies (Level Winner) — https://www.levelwinner.com/retro-bowl-guide-tips-tricks-strategies-to-secure-wins-and-form-a-dominant-franchise/ — community guide
- [S29] Review: New Star Soccer Mobile, 2012 (PIXEL SPORT) — https://pixelsport.wordpress.com/2012/05/13/review-new-star-soccer-mobile-iosandroid/ — review
- [S30] Difficulty — Retro Bowl Wiki (Fandom) — https://retro-bowl.fandom.com/wiki/Difficulty — wiki (excerpt)
- [S31] Unlimited Version — Retro Bowl Wiki (Fandom) — https://retro-bowl.fandom.com/wiki/Unlimited_Version — wiki (excerpt)
- [S32] Field Goals — Retro Bowl Wiki (Fandom) — https://retro-bowl.fandom.com/wiki/Field_Goals — wiki (excerpt)
- [S33] Star System — Retro Bowl Wiki (Fandom) — https://retro-bowl.fandom.com/wiki/Star_System — wiki (excerpt)
- [S34] Video Game Review: Retro Bowl (Nintendo Switch) (Sequential Planet) — https://sequentialplanet.com/video-game-review-retro-bowl-nintendo-switch/ — review (excerpt)
- [S35] What Age Do Players Retire in Retro Bowl? (Playbite Q&A) — https://www.playbite.com/q/what-age-do-players-retire-retro-bowl — other (excerpt)
- [S36] Top 10 Retro Bowl Hardest Achievements To Get (Gamers Decide) — https://www.gamersdecide.com/articles/retro-bowl-hardest-achievements — other (excerpt)
- [S37] Apple Arcade exclusive NFL Retro Bowl '26 launching September 4 (Apple Newsroom) — https://www.apple.com/newsroom/2025/08/apple-arcade-exclusive-nfl-retro-bowl-26-launching-september-4/ — news
- [S38] Apple Arcade launches three new games in September, including NFL Retro Bowl '25 (Apple Newsroom) — https://www.apple.com/newsroom/2024/08/apple-arcade-launches-three-new-games-in-september-including-nfl-retro-bowl-25/ — news
- [S39] The Most-Downloaded App Store Games of 2025 (GameSpot, Apple year-end charts) — https://www.gamespot.com/articles/the-most-downloaded-app-store-games-of-2025-include-fortnite-minecraft-and-balatro/1100-6536838/ — news
- [S40] Retro Bowl — Sensor Tower overview (US, Google Play) — https://app.sensortower.com/overview/com.newstargames.retrobowl?country=us — market data
- [S41] NFL Retro Bowl '25, new NFL-licensed arcade game, releasing ahead of 2024 season (CBS Sports) — https://www.cbssports.com/nfl/news/nfl-retro-bowl-25-new-nfl-licensed-arcade-game-releasing-ahead-of-2024-season/ — news
- [S42] Retro Bowl and Retro Bowl College Updates Available — Patch Notes, July 2024 (Operation Sports) — https://www.operationsports.com/retro-bowl-and-retro-bowl-college-updates-available-patch-notes/ — news
- [S43] Retro Bowl College Adds Sim Game and Interrupt Options, Editor Improvements and More, June 2025 (Operation Sports) — https://www.operationsports.com/retro-bowl-college-adds-sim-game-and-interrupt-options-editor-improvements-and-more/ — news
- [S44] New Updates Available for NFL Retro Bowl 26, Retro Bowl and Retro Bowl College, Jan 2026 (Operation Sports) — https://www.operationsports.com/new-updates-available-for-nfl-retro-bowl-26-retro-bowl-and-retro-bowl-college/ — news
- [S45] Retro Bowl College topic feed (Operation Sports) — https://www.operationsports.com/topics/retro-bowl-college/ — news
- [S46] College Bowl Patch 1.002 — Patch Notes; defensive play timer; unrelated game, kept for disambiguation (Operation Sports) — https://www.operationsports.com/college-bowl-patch-1-002-available-patch-notes/ — news
