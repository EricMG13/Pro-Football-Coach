# R1d — Adjacent Games, Game Feel & Narrative Systems Dossier

**Program:** Pro Football Coach rebuild — evidence dossier R1d (input to R2-synthesis.md)
**Date:** 2026-08-09
**Lenses (5 payloads, 3 lens types):** adjacent sports-management games (two independent research passes), game-feel and reward-presentation literature (two passes), narrative-manufacture mechanisms (one pass). Lens research was gathered live from the web by research agents; this dossier was assembled by the program orchestrator from their structured findings after the assembly agent was stopped mid-run.
**Sources:** ~115 unique, cited by named key (e.g. [swink-ch1]) rather than S-numbers — keys are the lens agents' own citation ids, kept stable for traceability. Full list in §9.
**Confidence:** High unless marked Medium inline. Medium marks cover search-excerpt-only evidence, single-source claims, and store/tracker data.

---

## 1. Scope & method

Three questions this dossier answers with evidence: (1) what have small teams actually achieved in sports management, and where does each fall short — the existence proofs and cautionary tales for a solo-scale iPhone sim; (2) what does the game-feel and reward-presentation literature prescribe, operationally, for a text-first sports sim; (3) how do simulation games manufacture narrative that players feel and retell. Findings are numbered **ADJ-01**–**ADJ-48**, stable and never to be renumbered; downstream design documents cite these IDs. Where two lens passes covered the same ground independently, findings are merged and carry both passes' citations. Statements without a source appear only as marked *Inference* with one line of reasoning. Preliminary steal/adapt/avoid verdicts in §6 are not final rulings — those happen in R2-synthesis.md.

## 2. Adjacent games — what small teams achieve, where each falls short

### Out of the Park Baseball (benchmark depth, small studio)

**ADJ-01 — A founder-led text sim can own a sport's management niche for 25+ years by compounding one deterministic engine through annual releases.** Markus Heinsohn began OOTP as a 1997 hobby project; OOTP 2007 hit 96 on Metacritic and OOTP 17 tied The Witcher 3 as 2016's highest-rated PC game. The ceiling is modest: Sportico pegs OOTP at roughly $1M yearly gross versus Football Manager's $30M+. Durable niche ownership, not scale. [wiki-ootp][os-heinsohn][sportico-bbgm]

**ADJ-02 — OOTP presents sim results text-first, with the broadcast layer optional and skippable at any granularity.** Play-by-play, box scores, keypress pitch-by-pitch, plus a watchable 2D/3D layer reviewers tolerate as decoration; you can enter or skip the watchable layer at any point. The product is the text and the numbers. [gamecritics-ootp25][ootp26-gsc-review][digitalchumps-ootp26]

**ADJ-03 — OOTP's drama layer is a weighted morale model plus severable storyline events — and sim-focused players turn it off.** Morale combines team performance, transactions, personal performance, and role expectations, weighted per personality; interactive storylines (problem player: suspend/trade/ignore) date to OOTP 13 (2012) and are fully removable by toggle. Players who experience storyline consequences without their story demand the off-switch (see ADJ-43). [ootp-wiki-morale][wiki-ootp][ootp-morale-forum]

**ADJ-04 — OOTP's perennial documented weakness is UX debt, not simulation:** overwhelming UI, thin tutorials, navigation lagging decades behind the engine, "safe" annual updates. Medium (aggregated reviews + one long-form critique). Depth-first development accrues presentation debt that eventually defines the reviews. [sgo-ootp26][ootp-5-things][gamedaily-ootp27]

**ADJ-05 — OOTP is also the genre's trust cautionary tale.** Com2uS acquired the studio (2020), the founder exited after OOTP 25, and veterans on Steam blame card-mode monetization (Perfect Team) for diverted resources — "bloated, disjointed version" of itself. Acquisition + monetization drift can spend 25 years of community trust. [wiki-ootpdev][os-heinsohn][ootp-steam-over]

### Motorsport Manager (streamlined-depth benchmark)

**ADJ-06 — A premium mobile management sim can sell 1.6M+ copies and bootstrap a studio into a SEGA-published PC franchise.** One ex-console programmer built the 2014 iOS original alone; 88 iOS Metacritic; SEGA published the ground-up 2016 PC rebuild. [wiki-mm2014][wiki-mm][pgbiz-west][mm-racefans]

**ADJ-07 — Critics call it the genre's best entry point because it deletes minutiae, not decisions.** "Never overwhelming, nor too light"; clear labels, big strategic calls, drama concentrated in watchable races; minutiae suppressed. The mid-spectrum position is a deliberate, teachable design stance. [wiki-mm2014][os-mm][mm-stuff-review][mm-dd-review]

**ADJ-08 — Streamlining's two documented costs: a collapsing difficulty curve and fixed pacing.** Challenge disappears once the player out-develops the AI (perfect car, unopposed wins); races run 30+ minutes even at max speed with no auto-resolve; the PC version sits torn between mobile-light and full-sim audiences. Medium (community threads + reviews). Late-game challenge and time-compression are where streamlined sims die. [steam-mm-threads][mm-cgm-review][mm-dd-review][opencritic-mm]

### Pocket GM (closest direct comparable: solo-dev iPhone football GM sim)

**ADJ-09 — One UK hobbyist has sustained a premium phone-first American-football GM sim for 6+ years.** Pocket GM 3: $2.99 one-time, 4.9/5 from 4,300+ US ratings, no ads, no data collection, still shipping season updates (v1.6.2, July 2025). The niche supports a solo premium app. [pgm-appstore][pgm-pocketgamer][appstore-pgm3]

**ADJ-10 — Its scope discipline is the design: pure GM role, zero in-match control, games as passive play-by-play, plus a social-feed layer for roster drama.** Howell's stated position: everything outside matches is the GM's actual remit. Draft, trades, free agency, coach hires with traits and schemes; a feed surfaces holdouts, injuries, suspensions. [pgm-pocketgamer][pgm-appstore]

**ADJ-11 — Its community praises exactly the off-field layer and the responsive developer.** Draft/scouting depth, staff with unique traits, VoiceOver accessibility, community roster sharing standing in for a license, a subreddit that visibly steers updates. Ranked #2 among football management games by a genre site (March 2026). [appstore-pgm3][gmgames-pgm3][onpapersports][pgm-onpaper]

**ADJ-12 — Its documented weakness is game-day sim believability: penalty spam, illogical AI, ratings disconnected from outcomes.** App Store reviewers document punting down ten late, 4th-and-17 attempts in field-goal range, an 89-overall roster persistently losing to 68–75 teams; the developer rewrote the engine in response. Standing requests: practice squads, schemes that visibly change simulated play. **This is the direct existence proof that sim believability is the genre's floor — the exact complaint class our calibration bands were built against.** [appstore-pgm3][gmgames-pgm3][onpapersports]

### Basketball GM (zero-graphics browser sim)

**ADJ-13 — A free, zero-graphics browser sim retains a global audience for 15+ years on three pillars: nothing is mandatory, everything is customizable, it runs anywhere.** Solo dev; record 4.9M+ yearly user sessions; played in 189 of 193 countries by 2020; a living wage from on-site ads alone, microtransactions refused. [zengm-about][zengm-fulltime][sportico-bbgm]

**ADJ-14 — Its retention levers are measured, not vibes: sim speed, zero friction, ownable leagues.** A code-optimization project nearly doubled completed seasons per user and lifted users 12% — sim speed is measurably retention. Real-roster league files were started ~3× more than custom ones. [zengm-lwog]

**ADJ-15 — With no graphics, it manufactures narrative hooks inside the sim.** Generated player families (sons, siblings) with morale boosts when relatives share a team, purpose-built to seed stories players retell; trades and drafts designed as "the fun parts." Medium (interview + profile). [roundball-scheff][sportico-bbgm][zengm-lwog]

### Football Chairman / Astonishing Basketball Manager (minimal mobile management)

**ADJ-16 — Radical abstraction scales — to a ceiling.** Football Chairman (players as single grades, seasons in minutes): 3M+ downloads, repeated Apple editorial awards, and full blind-player screen-reader accessibility as a side effect of text-first design; reviewers' verdict is "right depth for on-the-go, eventually repetitive." Medium (official site + reviews + accessibility review). [fc-official][fc-screenrobot][fc-tripletap][gamingmatters-fcp][backloggd-fcp]

**ADJ-17 — Stripped-down management risks reading as rigged.** A detailed player critique documents asymmetric blame (fans blame you for relegation, shrug at promotion), manager AI absurdities the chairman pays for, and bait mechanics engineering death spirals — "addictive but farce." Abstraction removes the evidence a player needs to believe an outcome was fair. Medium (one long-form critique). [fc-medium]

**ADJ-18 — A solo, phone-native manager with life-sim storylines sustains a real iOS audience — and does not transfer to Steam.** Astonishing Basketball Manager: 4.7/5 from ~4,370 ratings, offline, story-flavored career mode; the Steam port sits at 61% positive from 13 reviews, with balance complaints (legendary teams losing to weak ones). Phone-native design is its own discipline. Medium (store data + tracker). [mwm-abm][abm-appstore][abm-steam]

### Legend Bowl / Axis Football (indie football, the two halves separated)

**ADJ-19 — Feel-first wins critics even in football — and the audience still demands the franchise layer, which shipped rushed.** Solo dev Legend Bowl: industry-leading sprite juice, Steam Very Positive (~88%), "best pacing since NFL Blitz." Its management half drew a 6/10: no player-initiated trades, no usable scouting, drafts without preparation. Community threads argue ~95% of the audience lives in multi-season play; the post-launch franchise update (facilities, weekly newspaper) revitalized the game. [os-lb][steam-lb][lb-retrolike][nintendolife-lb][lb-steam-franchise][lb-os-franchise]

**ADJ-20 — Axis Football is the inverse proof: deep franchise scaffolding cannot rescue weak moment-to-moment feel.** 16-role coaching staffs, scouts, contracts, practice squads — praised; on-field play "sluggish," presentation weak; a 2/5 review recommends Madden despite the price gap. **ADJ-19 + ADJ-20 together are the empirical case for the hybrid thesis: either half alone fails.** [axis-os-2019][thegamesletter-axis][axis-xboxhub][gamesandwich-axis26]

## 3. Game-feel principles catalog (operational)

Each principle is stated with how it applies to a text-first franchise sim (cap-sheet reveal, week advance, draft pick, game result).

**ADJ-21 — Feel in a menu game is the polish region: sub-100ms response, weight sold by effects.** Swink's definition — real-time control + simulated space + polish — explicitly places turn-based/menu games (Civ 4, Bejeweled) in a "polish-only" region where all feel comes from effects that sell weight and presence. Operationally: every tap acknowledged within ~100ms; the sim's numbers gain "mass" only through staged presentation. [swink-ch1][gamefeel-wiki][critpoints]

**ADJ-22 — Juice = many small layered outputs per input.** The canonical demo layers tweening, sound, particles, and shake onto identical Breakout mechanics; each layer is cheap and marginal, the sum transforms feel. A week-advance can carry the same layering: tick, card slide, haptic, count-up, snap. [juice-gdcvault][juice-talk][roblog-juice]

**ADJ-23 — Vlambeer's four transferable principles: exaggeration, interruption (hitstop), inertia, permanence.** Permanence — the world keeps visible traces of what happened — is the management-sim translation: records, banners, career ledgers, a rivalry's scar tissue. Hitstop translates to the beat of silence before a big reveal. [vlambeer-tecx][vlambeer-writeup][vlambeer-victor]

**ADJ-24 — The counter-tradition: context precedes polish; reflexive juicing erodes meaning.** Effects that obscure information or clash with tone backfire; restraint preserves grounding. For a brand voice of "confident, plainspoken," juice must live in staging and timing more than in confetti. [dontjuice-gd][kelly-counter]

**ADJ-25 — Engagement is nested loops; arcs are exit-once content; loops die when feedback is missing or variation exhausts.** Cook's diagnostic — "what repeats and what does not?" — is the audit question for a 20-week season loop. A loop without feedback (a week that changes nothing visible) is a dead loop. [lostgarden-loops]

**ADJ-26 — Meier's psychology: players credit wins to skill and blame losses on the game; front-load rewards; keep progression monotonic.** "You almost cannot reward the player enough" in the first 15 minutes; randomness breeds paranoia; design consistent advancement rather than realistic rise-and-fall. [meier-gd2010][museumofplay]

**ADJ-27 — Fudge perception, not outcomes players can audit: odds toward expectation, loss-streak protection, penalties reframed as bonuses.** CivRev hard-codes 3:1 as a guaranteed win because testers read it that way; WoW's rest system reframed a 50% penalty as a 200% bonus — identical math, opposite sentiment. "Feedback is fact." [meier-shack][ybrikman-meier]

**ADJ-28 — An interesting decision needs tradeoffs, situational variance, personal expression, persistence.** A clearly superior option is an evaluation, not a decision. This is the test every screen's primary choice must pass — and the documented failure of Madden's reward-only scenarios (see R1a MAD-15) is its negative image. [meier-2012]

**ADJ-29 — One-more-turn is engineered: staggered completion timers, events that start before your stopping point, a frictionless advance control, cliffhangers pointing at the next turn.** Multiple systems finishing at offset times means something is always 1–3 turns from done. For a franchise sim: contract years, development arcs, milestone chases, and draft positioning must deliberately interleave their completion horizons across weeks. [onemoreturn-kangmu][meier-tips][gd-onemoreturn][soren-tlgd]

**ADJ-30 — Randomness placement determines fairness perception: upstream randomness reads as terrain, last-step randomness reads as theft.** Players over-anticipate 1% events and treat 99% as certain; unlearnable "nasty surprises" are always bad; constant die rolls blur into noise. Civ IV's showing exact success percentages drastically improved satisfaction. [soren-odds][designer-notes-odds]

**ADJ-31 — Reward schedules: variable-ratio sustains steady play; fixed-ratio creates post-reward pauses (quit points); sharp reward-rate drops read as betrayal.** Defending what you own (job security, a record, a streak) motivates without new rewards. [hopson]

**ADJ-32 — Near misses recruit win-like reward circuitry and prolong play — strongest when outcome follows action immediately.** Manufacturing them is literally patented gambling tech; the effect is unstudied where skill mediates outcomes. Ethical line for us: surface true near-misses the sim already produced (a 1-yard-short season, a missed record) rather than fabricating them. [madigan][clark-nearmiss][nearmiss-review]

**ADJ-33 — The displayed-odds canon: XCOM and Fire Emblem both secretly bend true odds toward the displayed story.** XCOM inflates hit chances and protects streaks below top difficulty because players read 85% as "should not miss"; Fire Emblem's 2RN makes displayed 75 hit ~82–88% — and players experience the fudged system as fairer. The honest-miss that survives becomes the story players retell. [xcom-aim][xcom2-wiki][solomon-gd][vigaroe-xcom][serenes-truehit][fe-truehit]

**ADJ-34 — Per-action stakes and telegraphed threat: Blood Bowl's turnover rule gives every roll a visible risk that forces sequencing; Slay the Spire's intent icons exist because informed decisions feel more meaningful than hidden ones.** Both convert probability into drama before resolution, not after. Fourth-down decisions and blitz calls are our native home for this. [bloodbowl-mlu][meeplelikeus-bb][goonhammer-bb][sts-intent][hopeinsource-sts]

**ADJ-35 — Balatro is the state of the art in number staging — and its haptics made the iPhone version the best-feeling one.** Sequential per-source resolution on a rising pitch ladder, staggered rolling digits (~600ms for one reveal), shake scaled to magnitude before the number lands, total deliberately withheld. A cap-sheet or box-score reveal can be staged identically. [balatro-crosley][crosley-balatro][balatro-gmtk][kokutech-balatro][rogueliker]

*Haptics half, citation corrected 2026-08-09 by the OD-5 spot-check:* the claim that per-scoring-tick haptics make the iPhone version the best-feeling one is **true but was mis-cited**. The TouchArcade reference is a 403 paywall, and the Shacknews piece describes only light feedback on taps and deals without tying it to scoring. The supporting source is [iphoneincanada-balatro], which states it directly — "every time a card's score is activated, there's a punchy kick in response via the haptics." Treat this as one review's observation, not a chorus. [iphoneincanada-balatro][shacknews-balatro]

**ADJ-36 — Broadcast stat practice: prepare far more graphics than you air, fire them only when the situation earns them, cap each at a ~20-second read.** SNF produces ~30 pieces weekly and airs ~5; a three-sack graphic fires after the third sack. Corollary from criticism of live win-probability: retrospective swing charts amplify emotion, always-on percentages deflate it. FM26 now ships drama-adaptive highlight density (more highlights in close, important games). The template pool exists so the moment can select, not so everything shows. [gaudelli-fmia][defector-winprob][fm26-storytelling][fmscout-fm26]

**ADJ-37 — Apple's audio-haptic doctrine is causality, harmony, utility — and the Not Boring studio proves game-grade juice works on utility surfaces.** Feedback fires on its visible cause; visual, sound, and haptic share the same frame and character; reserve haptics for meaningful moments or players learn to ignore them; pair sound and haptics almost always; ship 8–12 pitch/volume variants per sound to survive repetition. [wwdc810][hig-haptics][wwdc21-haptics][notboring-btd][notboring-sound]

**ADJ-38 — Juice must be built as strippable layers for Reduce Motion.** Position-based motion (shake, slide, zoom) swaps to crossfade/opacity; meaning persists in non-motion channels — sound, haptics, color, persistent text. Motion is a layer, never the sole carrier of information. Medium (assembled guidance, no single canonical source). [reduce-motion-loaf][useyourloaf-rm][apple-reducemotion][xbox117]

## 4. Narrative-manufacture mechanisms catalog (operational)

**ADJ-39 — RimWorld's founding frame: "Not a game — a story generator."** Mechanics are selected for the arcs they inflict on characters; loss is threatened inside the story, never as game-over; systems must include both loss and recovery. A franchise sim's equivalent: a season can be lost in a way that opens the next chapter (rebuild, revenge arc), never a dead end — convergent with our existing no-dead-end carousel invariant. [rimworld-gdc]

**ADJ-40 — Apophenia engineering: players narrate hardest where the game abstracts feedback and keeps long-term relevance.** Sylvester's two-ingredient recipe for player-manufactured story; plus the storyteller as pacing governor (tension curves with breathing room, event weight scaled to current stakes). Medium on storyteller internals (wiki excerpt). Drama cadence is a tunable system, not an accident of the sim. [rimworld-gdc][rimworld-analysis][rimworld-wiki]

**ADJ-41 — CK2's legibility rule: one unified, visible opinion scale plus contradictory personality traits makes every betrayal arrive pre-explained — and thus retellable.** The most-retold sagas were accidental collisions of independent events that pattern-seeking players read as authored plot. Causal legibility is what converts sim output into story; the player's pattern-seeking does the authoring free of charge. [ck2-surprising][ck2-killscreen]

**ADJ-42 — FM's inbox is the narrative delivery organ — and its documented failure mode is spam.** SI's own telemetry showed players live in the inbox (FM26 rebuilt its home screen around it); all story arrives as items attributed to named in-world sources. The failure literature: repeated, context-free questions and padded reports make players skip the layer meant to narrate their save. Volume is the enemy; salience is the design. [fm24-manual][fm26-portal][fullerfm]

**ADJ-43 — The delivery-layer law (OOTP): a consequence without its story reads as random punishment.** An 18-year-old five-star prospect "abruptly retired to play football" as a terse notice — the player's response was to ask how to turn storylines off. If the system cannot show the arc, do not ship the event. [ootp-bp][ootp-forum]

**ADJ-44 — Wildermyth's four transferable systems:** (1) events as a Library of Plays — hand-written scenes with typed roles cast at runtime by scoring functions, re-voiced per personality/relationship; (2) permanence — injuries never erased, every change visible and mechanically real; (3) trust rules — tradeoffs not gotchas, consequences proportional, big outcomes telegraphed, odds usually shown, never troll the player; (4) the attention budget — players track only 1–2 personality traits per character and one relationship fact, and relationships never decay because decay tested as not-fun. Authoring effort goes to casting and salience, not simulation depth. [wildermyth-gdc]

**ADJ-45 — Dwarf Fortress proves system-generated history is readable content, and "losing is fun" is norm-setting copy.** Legends mode makes the archive itself a product surface; the slogan began as a manual joke and successfully reframed collapse as the best chapter — the game's most famous story is a fall, not a win. A franchise sim's history book, record book, and "previous seasons" archive are content, not chrome; and the game's copy can teach players that a 4–13 season is a chapter. [df-wikipedia][boatmurdered-wikipedia]

**ADJ-46 — Run-report culture arises when a game supplies stakes, an arc, and a named format — and Blaseball proves authorial absence plus statistically legible chaos is enough for a community to mythologize a sports sim.** Boatmurdered and NetHack's YAAP institutionalized write-ups; Blaseball's devs kept no lore team and let RNG outputs stand as canon while fans held funerals for incinerated players. Exportable season/dynasty artifacts are the single-player analog. [boatmurdered-wikipedia][yaap-nethackwiki][blaseball-mary][blaseball-gd][blaseball-tvtropes]

**ADJ-47 — The oatmeal problem sets the generated-content quality bar: perceptual uniqueness for standouts, mere differentiation for filler.** 10,000 procedurally unique bowls still read as oatmeal. Budget: a handful of characterful, memorable artifacts per season (the breakout star, the collapse, the heist trade) against a background of adequately varied filler. [oatmeal]

**ADJ-48 — Procedural text practice: matching beats assembling.** Select author-written templates by salience of world state; vary via substitution; spend effort choosing what to mention, not on syntactic cleverness players never notice; weed any fragment that can fail — one bad output ruins ten good ones. [emshort-2014][wildermyth-gdc]

## 5. Cross-cutting lessons: depth on a phone

1. **Sim believability is the genre's floor, and it is our moat.** The closest comparable's #1 documented weakness is exactly the complaint class our calibration bands, believability bands, and ratings-predictiveness tests were built against (ADJ-12; also ADJ-17's rigged-feeling failure). The validated engine contract is a competitive asset no adjacent solo title demonstrably holds.
2. **Either half alone fails.** Feel without franchise depth left Legend Bowl's audience demanding the dynasty layer (ADJ-19); franchise scaffolding without feel gets Axis Football a 2/5 (ADJ-20). The hybrid thesis is not taste — it is the documented failure pattern of the adjacent slate.
3. **Text-first is not a compromise.** OOTP, Basketball GM, Football Chairman, and Pocket GM all prove presentation quality is orthogonal to graphics; Basketball GM's blind-accessibility side effect and measured sim-speed retention lever (ADJ-13, ADJ-14, ADJ-16) show text-first done well is a feature.
4. **Premium, no-ads, solo works in this niche** (Pocket GM at $2.99/4.9★, Motorsport Manager mobile at 1.6M+ premium sales) — consistent with our TestFlight/no-monetization posture and the community's no-ads ethos (ADJ-06, ADJ-09).
5. **Speed is retention.** Basketball GM measurably doubled completed seasons and grew users by optimizing sim speed (ADJ-14); our <150ms week-advance budget is not an engineering nicety, it is the one-more-turn substrate (with ADJ-29's interleaved horizons giving each fast advance a reason).
6. **The feel literature converges on staging, not spectacle**, for a plainspoken product: layered-but-restrained juice (ADJ-22/24), number staging (ADJ-35), situation-earned stat drama (ADJ-36), haptic discipline (ADJ-37), Reduce Motion as a first-class variant (ADJ-38).
7. **Narrative is a delivery-layer problem on top of a finished sim.** Every mechanism in §4 — inbox salience, causal legibility, permanence, casting, named formats — consumes sim events we already generate; none requires new simulation. The failure modes (spam, consequence-without-story, trolling) are authoring disciplines, not engineering ones.

## 6. Preliminary steal / adapt / avoid

PRELIMINARY — final rulings in R2-synthesis.md.

| Verdict | Element | One-line rationale | Findings |
|---|---|---|---|
| Steal | Sim-speed-as-retention budget (fast advance, zero friction) | Measured: doubling season throughput lifted users 12% | ADJ-14, ADJ-29 |
| Steal | Number staging for big reveals (sequential resolution, staggered digits, magnitude-scaled emphasis, withheld total) | State of the art proven on iPhone with haptics | ADJ-35, ADJ-37 |
| Steal | Situation-earned stat cards with a 20-second read cap | Broadcast practice: prepare many, air few, fire on the moment | ADJ-36 |
| Steal | Per-action stakes shown before resolution (4th down, blitz, trade accept) | Blood Bowl/StS: visible risk converts probability into drama | ADJ-34 |
| Steal | Interleaved completion horizons across weeks | The engineered core of one-more-turn | ADJ-29, ADJ-25 |
| Steal | Permanence surfaces: career ledgers, records, scars, archives as content | Vlambeer permanence × Wildermyth × DF legends | ADJ-23, ADJ-44, ADJ-45 |
| Steal | Consequence-with-story law (no event ships without its arc) | OOTP's off-switch demand is the counterexample | ADJ-43, ADJ-42 |
| Steal | Trust rules for procedural drama (telegraph, proportional, tradeoffs, never troll) | Wildermyth's tested pitfall list | ADJ-44, ADJ-28 |
| Steal | Exportable season/dynasty artifacts (local image/text) | Run-report culture needs an artifact; offline-compatible | ADJ-46 |
| Adapt | Odds presentation (show %, protect perception via upstream randomness placement) | Show-the-number improves satisfaction; last-step randomness reads as theft; full XCOM-style fudging conflicts with a deterministic auditable engine — adapt, don't copy | ADJ-30, ADJ-33, ADJ-27 |
| Adapt | Storyteller-style drama pacing governor | Tension cadence as a tunable system, sized to a 20-week season | ADJ-40, ADJ-25 |
| Adapt | Wildermyth casting for news/story templates (typed roles, salience scoring, personality re-voicing) | The authoring architecture for a fresh-for-10-seasons news engine | ADJ-44, ADJ-47, ADJ-48 |
| Adapt | Attention budget (1–2 traits, one relationship fact per player) | Caps trait-system scope to what players actually track | ADJ-44 |
| Adapt | "Losing is a chapter" norm-setting copy | Reframes bad seasons; must fit plainspoken voice | ADJ-45, ADJ-39 |
| Avoid | Depth-first UX debt (OOTP pattern) | Decades of engine excellence reviewed through its navigation | ADJ-04 |
| Avoid | Severable/toggleable drama layer | What can be turned off gets turned off; integrate or omit | ADJ-03, ADJ-43 |
| Avoid | Difficulty that collapses when the player out-develops the AI | The streamlined-sim death; AI teams must rebuild credibly | ADJ-08 |
| Avoid | Abstraction below the evidence threshold (outcomes players can't audit) | "Addictive but farce" — asymmetric blame reads as rigged | ADJ-17, ADJ-12 |
| Avoid | Fabricated near-misses | Patented gambling tech; surface true ones the sim produced | ADJ-32 |
| Avoid | Reflexive juice/confetti against the plainspoken voice | Context precedes polish; effects must not obscure information | ADJ-24, ADJ-38 |

## 7. Relevance map to Pro Football Coach

**Against the audit's failure classes.** The audit (docs/AUDIT.md, 9/20) measures native craft — contrast, Dynamic Type, touch targets, Reduce Motion, main-thread saves — and its systemic finding "written-down commitments with zero implementations" (Reduce Motion: 0 checks) is directly answered by ADJ-38: motion must ship as strippable layers with meaning in non-motion channels, which is only possible if the feel layer is architected, not sprinkled. The audit cannot see blandness; this dossier supplies the missing rubric: dead loops (ADJ-25), unstaged numbers (ADJ-35), consequence-without-story (ADJ-43), no permanence surfaces (ADJ-23/45), no interleaved horizons (ADJ-29).

**Against the current-game inventory.** The engine already generates everything §4 consumes: injuries, milestones, cap crunches, breakouts, streaks, records, retirements, job-security swings. The templated news engine (6–12 items/week) is the embryo of ADJ-42's inbox — what it lacks is salience selection (ADJ-48), casting (ADJ-44), permanence hooks (ADJ-45), and a no-spam volume discipline (ADJ-42). The three retired design systems all specified color/type/spacing and never time — ADJ-21/22/35/37 are precisely the missing "time" layer (staging, layering, haptic-audio pairing, response budgets).

**Against the fast/deep split.** Fast sessions get the ADJ-29 machinery (interleaved horizons + frictionless advance + cliffhanger cards) and ADJ-14's speed budget; deep sessions get the expertise surfaces the adjacent slate proves text can carry (ADJ-02, ADJ-13). The split is served by one card feed with severity tiers, not two modes — consistent with FM's inbox evidence (R1c FM-01) and Pocket GM's feed (ADJ-10).

**Against hard constraints.** Offline/fictional: Basketball GM and Pocket GM prove fictional leagues with community roster culture retain (ADJ-11, ADJ-13); deterministic engine + integer money make graded predictions and auditable outcomes possible — our answer to ADJ-17's rigged-feeling risk and ADJ-33's fudging dilemma (we can show honest numbers because our sim is calibrated). One-thumb: every §3 principle has a one-thumb form; Balatro's iPhone haptics (ADJ-35) is the proof the best-feeling version of a numbers game is the phone version. Reduce Motion/WCAG as physics: ADJ-38 and Football Chairman's blind-playability (ADJ-16) show accessibility and text-first design are mutually reinforcing, not in tension.

**Against the solo/Opus-5 build reality.** The adjacent slate's scope discipline lessons (ADJ-10's "pure GM remit," ADJ-07's "delete minutiae, not decisions") and its failure modes (ADJ-04's UX debt, ADJ-19's rushed franchise half) are the program-management evidence for building the feel/narrative layer as first-class scope, not a post-launch patch.

## 8. Surprises & open questions

**Surprises.**
1. The strongest direct comparable's #1 weakness (Pocket GM's sim believability) is precisely the thing our current build has already solved and validated — the moat is real and already built (ADJ-12).
2. Basketball GM measured what designers usually assert: sim speed is retention (doubled seasons → +12% users) (ADJ-14).
3. The feel literature's most-transferable case for a numbers game is a poker roguelike: Balatro's staging + iPhone haptics is a complete blueprint for staging franchise-sim numbers (ADJ-35).
4. Wildermyth's attention budget — players track 1–2 traits and one relationship fact — caps how much personality simulation is worth building; the constraint is authoring salience, not sim depth (ADJ-44).
5. OOTP players demanded an off-switch for drama delivered without its story — the counterexample that kills "add storylines" as a feature bullet (ADJ-43).
6. Blind-player accessibility fell out of text-first design for free in Football Chairman — accessibility and this genre are natural allies (ADJ-16).
7. Both juice canons carry an explicit counter-tradition warning against reflexive juice — restraint is in the literature, not just in our brand voice (ADJ-24).

**Open questions.**
- **OQ-D1:** What is the right drama cadence for ~20 sim-relevant weeks (vs FM's 40–60 fixtures)? ADJ-40's pacing governor needs football-calendar tuning (converges with R1c OQ-1).
- **OQ-D2:** Where exactly is the line between honest odds (deterministic, auditable engine) and perception management (ADJ-27/33)? Candidate ruling: show true percentages, place randomness upstream, never fudge resolution — but this needs a synthesis-level decision.
- **OQ-D3:** How large must the news/story template library be to survive a 10-season soak without oatmeal (ADJ-47, ADJ-48; converges with R1a OQ-2)? Needs authoring math before scope lock.
- **OQ-D4:** Do blocking priority cards (FM-style) delight or irritate in 3-minute phone sessions (R1c OQ-5)? Prototype question for the design phase.
- **OQ-D5:** Is a Wildermyth-style casting engine over-scope for v1 of the news system, with plain salience-matched templates (ADJ-48) as the floor? Architecture-phase decision.

## 9. Sources

Cited by named key. Grouped by lens; duplicates across lenses listed once.

**Adjacent games:**
[wiki-ootp] Out of the Park Baseball — Wikipedia — https://en.wikipedia.org/wiki/Out_of_the_Park_Baseball (wiki)
[wiki-ootpdev] Out of the Park Developments — Wikipedia — https://en.wikipedia.org/wiki/Out_of_the_Park_Developments (wiki)
[os-heinsohn] Exclusive Interview with OOTP Developer Markus Heinsohn — Operation Sports — https://forums.operationsports.com/news/252672/exclusive-interview-with-ootp-baseball-developer-markus-heinsohn/ (interview)
[ootp-wiki-morale] Player Morale — OOTP Wiki — https://wiki.ootpdevelopments.com/index.php?title=OOTP_Baseball:Important_Game_Concepts/The_Player_Model/Personality_Ratings/Player_Morale (wiki)
[os-ootp24] OOTP 24 Review — Operation Sports — https://www.operationsports.com/out-of-the-park-baseball-24-review-still-making-worthwhile-improvements/ (review)
[gamecritics-ootp25] OOTP 25 Review — Gamecritics — https://gamecritics.com/brad-bortone/out-of-the-park-baseball-25-review/ (review)
[digitalchumps-ootp26] OOTP 26 Review — digitalchumps — https://digitalchumps.com/out-of-the-park-baseball-26-review-pc/ (review)
[ootp26-gsc-review] OOTP 26 Review — Gamer Social Club — https://gamersocialclub.ca/2025/03/25/out-of-the-park-baseball-26-review/ (review)
[sgo-ootp26] OOTP 26 Review — Sports Gamers Online — https://www.sportsgamersonline.com/news/reviews/out-of-the-park-baseball-26-review-a-baseball-nerds-dream/ (review)
[gamedaily-ootp27] OOTP 27 Is Out Now — GameDaily — https://gamedaily.com/games/out-of-the-park-baseball-27-out-now-launch (news)
[ootp-5-things] 5 Things I Hate About OOTP — Baseball Replay Journal — https://baseballreplayjournal.substack.com/p/5-things-i-hate-about-ootp (critical-analysis)
[ootp-steam-over] Is OOTP 'over'? — Steam discussion — https://steamcommunity.com/app/3116890/discussions/0/604164169660491290/ (community)
[ootp-morale-forum] Player Morale/Expectations and Personality Systems — OOTP forums — https://forums.ootpdevelopments.com/showthread.php?t=320595 (community)
[wiki-mm] Motorsport Manager — Wikipedia — https://en.wikipedia.org/wiki/Motorsport_Manager (wiki)
[wiki-mm2014] Motorsport Manager (2014 video game) — Wikipedia — https://en.wikipedia.org/wiki/Motorsport_Manager_(video_game) (wiki)
[mm-racefans] Meeting the brains behind Motorsport Manager — RaceFans — https://www.racefans.net/2016/08/10/meeting-man-behind-motorsport-manager/ (interview; 403s, search-excerpt)
[mm-playsport] Studio — Playsport Games — https://www.playsportgames.com/studio/ (other)
[pgbiz-west] Christian West on business planning as an indie — PocketGamer.biz — https://www.pocketgamer.biz/christian-west-on-business-planning-as-an-indie/ (interview)
[mm-pgbiz] (same interview, alternate URL) — https://www.pocketgamer.biz/news/66185/christian-west-on-business-planning-as-an-indie/ (interview)
[linkedin-west] Christian West on leaving Playsport — LinkedIn — https://www.linkedin.com/posts/christian-west-2300124_last-year-i-left-playsport-and-the-motorsport-activity-7338938219868110854-Vs16 (other)
[os-mm] Motorsport Manager Review (PC) — Operation Sports — https://forumsold.operationsports.com/reviews/847/motorsport-manager/ (review)
[mm-os-review] (same) (review)
[mm-stuff-review] Motorsport Manager review — Stuff — https://www.stuff.tv/review/motorsport-manager-review/ (review)
[mm-dd-review] Review: Motorsport Manager (PC) — Digitally Downloaded — https://www.digitallydownloaded.net/2016/11/review-motorsport-manager-pc.html (review)
[mm-cgm-review] Motorsport Manager (PC) Review — CGMagazine — https://www.cgmagonline.com/review/game/motorsport-manager-pc-review (review)
[steam-mm-threads] Motorsport Manager difficulty/AI threads — Steam — https://steamcommunity.com/app/415200/discussions/0/142261027579663958/ (community)
[opencritic-mm] Motorsport Manager — OpenCritic — https://opencritic.com/game/3566/motorsport-manager (review)
[racinggames-2026] Best Racing Management Games 2026 — racinggames.gg — https://racinggames.gg/article/the-best-racing-management-games-to-play-in-2026 (other)
[appstore-pgm3] Pocket GM 3: Football Sim — App Store — https://apps.apple.com/us/app/pocket-gm-3-football-sim/id1645791169 (other)
[pgm-appstore] (same) (other)
[pgm-pocketgamer] Pocket GM 20 — Pocket Gamer — https://www.pocketgamer.com/pocket-gm-20/pocket-gm-20-is-an-american-football-management-sim-thats-available-now-for-ios/ (news)
[game-solver-pgm3] Pocket GM 3 — Game Solver — https://game-solver.com/pocket-gm-3-football-sim/ (other)
[mwm-pgm3] Pocket GM 3 stats — MWM — https://mwm.ai/apps/pocket-gm-3-football-sim/1645791169 (other)
[gmgames-pgm3] Pocket GM 3 Football — GM Games — https://gmgames.org/pocket-gm-3-football/ (community)
[onpapersports] Best Football Management Games (March 2026) — On Paper Sports — https://www.onpapersports.com/blog/best-football-management-games (community)
[pgm-onpaper] (same) (community)
[zengm-about] About — ZenGM — https://zengm.com/about/ (other)
[zengm-fulltime] Basketball GM is now my full time job — ZenGM Blog — https://zengm.com/blog/2021/01/full-time-job/ (postmortem)
[zengm-lwog] ZenGM: Growth of the Best Free Browser Management Sim — Last Word on Gaming — https://lastwordongaming.com/2022/10/28/zengm-manager-simulation-series/ (critical-analysis)
[sportico-bbgm] Basketball GM Beats Industry Odds — Sportico — https://www.sportico.com/business/tech/2025/basketball-gm-video-game-luka-doncic-trade-1234855985/ (news)
[roundball-scheff] Interview with Basketball GM creator Jeremy Scheff — SportsEthos — https://sportsethos.com/audio-video/podcasts/roundball-ramble-interview-with-basketball-gm-creator-jeremy-scheff/ (interview)
[gmgames-bbgm-review] Review of BBGM — GM Games — https://gmgames.org/basketball-gm/review/ (community)
[fc-official] Football Chairman official site — https://www.football-chairman.com/ (other)
[fc-screenrobot] Football Chairman developer interview — Screen Robot — https://screenrobot.com/football-chairman-developer-interview-behind-scenes-look/ (interview; site unreachable, search-excerpt)
[fc-tripletap] Football Chairman Pro — TripleTapTech blind-accessibility review — https://tripletaptech.org/football-chairman-pro/ (review)
[gamingmatters-fcp] Football Chairman Pro Review — Gaming Matters — https://siboyle.wixsite.com/sismatters/single-post/2016/09/25/gaming-matters-football-chairman-pro-review (review)
[backloggd-fcp] Football Chairman Pro — Backloggd review — https://backloggd.com/u/internettrey/review/164316 (community)
[fc-medium] Football Chairman: Pro — a Total Farce — Medium — https://medium.com/@mattkeeling92/football-chairman-pro-a-total-farce-76f24b22fb9f (critical-analysis)
[mwm-abm] Astonishing Basketball Manager stats — MWM — https://mwm.ai/apps/astonishing-basketball-manager/1589313811 (other)
[abm-appstore] Astonishing Basketball Manager — App Store — https://apps.apple.com/us/app/astonishing-basketball-manager/id1589313811 (other)
[gmgames-aerilys] Developer Bio: Aerilys — GM Games — https://gmgames.org/developer/aerilys/ (community)
[abm-steam] Astonishing Basketball Manager — Steam — https://store.steampowered.com/app/2170680/Astonishing_Basketball_Manager/ (other)
[steam-abm] (same) (other)
[sgo-lb-ea] Legend Bowl Early Access Review — Sports Gamers Online — https://www.sportsgamersonline.com/games/football/legend-bowl-early-access-review-throwing-back-to-the-classics/ (review)
[os-lb] Legend Bowl Review — Operation Sports — https://www.operationsports.com/legend-bowl-review-well-worth-the-wait/ (review)
[steam-lb] Legend Bowl — Steam — https://store.steampowered.com/app/1106340/Legend_Bowl/ (other)
[lb-retrolike] Legend Bowl Review (PS5) — Retrolike — https://retrolike.net/2023/08/12/legend-bowl-review-ps5/ (review)
[nintendolife-lb] Legend Bowl (Switch) Review — Nintendo Life — https://www.nintendolife.com/reviews/switch-eshop/legend-bowl (review)
[lb-steam-franchise] Legend Bowl franchise-mode Steam discussion — https://steamcommunity.com/app/1106340/discussions/0/4931994385951640739 (community)
[lb-os-franchise] Legend Bowl Franchise Mode Impressions — Operation Sports — https://www.operationsports.com/legend-bowl-franchise-mode-impressions/ (review)
[os-axis19] / [axis-os-2019] Axis Football 2019 Review — Operation Sports — https://www.operationsports.com/axis-football-2019-review-a-solid-alternative-to-madden/ (review)
[thegamesletter-axis] Does Axis Football 26 Have the Best Franchise Mode? — The Games Letter — https://thegamesletter.com/does-axis-football-26-have-the-best-franchise-mode/ (other)
[gamesandwich-axis26] Axis Football 2026 Review — Game Sandwich — https://www.gamesandwich.com/axis-football-2026-review/ (review)
[axis-xboxhub] Axis Football 2026 Review — TheXboxHub — https://www.thexboxhub.com/axis-football-2026-review/ (review)

**Game feel / reward presentation:**
[swink-ch1] Game Feel, Chapter 1 — Steve Swink (full PDF) — http://mycours.es/gamedesign2014/files/2014/10/Game-Feel-Steve-Swink-chapter-1.pdf (academic)
[gamefeel-wiki] Game feel — Wikipedia — https://en.wikipedia.org/wiki/Game_feel (wiki)
[critpoints] You don't know what Game Feel is — Critpoints — https://critpoints.net/2020/05/23/you-dont-know-what-game-feel-is-read-the-damn-book-please/ (critical-analysis)
[juice-gdcvault] Juice It or Lose It — GDC Vault — https://www.gdcvault.com/play/1016487/Juice-It-or-Lose (talk)
[juice-talk] Juice it or lose it — YouTube — https://www.youtube.com/watch?v=Fy0aCDmgnxg (talk)
[roblog-juice] / [juice-roblog] Juice it or lose it — Roblog — https://roblog.co.uk/2024/03/juicy-games/ (critical-analysis)
[dontjuice-gd] / [kelly-counter] Indies, resist the urge to 'juice it or lose it' — Game Developer — https://www.gamedeveloper.com/design/video-indies-resist-the-urge-to-juice-it-or-lose-it- (talk)
[vlambeer-tecx] / [vlambeer-writeup] The art of screenshake — technique-list writeup — https://theengineeringofconsciousexperience.com/jan-willem-nijman-vlambeer-the-art-of-screenshake/ (talk)
[vlambeer-victorweidar] / [vlambeer-victor] The Art Of Screenshake — design-student writeup — https://victorweidar.wordpress.com/2016/10/06/the-art-of-screenshake/ (critical-analysis)
[lostgarden-loops] Loops and Arcs — Daniel Cook — https://lostgarden.com/2012/04/30/loops-and-arcs/ (critical-analysis)
[meier-gd2010] GDC: Sid Meier's Lessons On Gamer Psychology — Game Developer — https://www.gamedeveloper.com/game-platforms/gdc-sid-meier-s-lessons-on-gamer-psychology (talk)
[museumofplay] GDC 2010: Game Psychology 101 — Museum of Play — https://www.museumofplay.org/blog/gdc-2010-game-psychology-101/ (news)
[meier-shack] Meier and Pardo on Probability and Player Psychology — Shacknews — https://www.shacknews.com/article/62807/sid-meier-and-rob-pardo (talk)
[ybrikman-meier] Review: Sid Meier's Memoir — Brikman — https://www.ybrikman.com/blog/2026/06/18/sid-meier-memoir/ (review)
[meier-2012] Sid Meier on games as sets of interesting decisions — Game Developer — https://www.gamedeveloper.com/design/gdc-2012-sid-meier-on-how-to-see-games-as-sets-of-interesting-decisions (talk)
[onemoreturn-kangmu] What's the basis of 'one more turn' syndrome? — https://kangmu.wordpress.com/2017/04/02/whats-the-basis-of-one-more-turn-syndrome/ (critical-analysis)
[meier-tips] / [gd-onemoreturn] Just one more turn — tips from Sid Meier — Game Developer — https://www.gamedeveloper.com/game-platforms/just-one-more-turn---game-development-tips-and-tricks-from-the-creator-of-civilization-sid-meier- (critical-analysis)
[soren-odds] / [designer-notes-odds] GD Column 9: Playing the Odds — Soren Johnson — https://designer-notes.com/?p=171 (critical-analysis)
[soren-tlgd] Think Like A Game Designer #49: Soren Johnson — https://justingarydesign.substack.com/p/think-like-a-game-designer-49-soren-9d4 (interview)
[hopson] Behavioral Game Design — John Hopson — https://www.gamedeveloper.com/design/behavioral-game-design (academic)
[madigan] The Near Miss Effect and Game Rewards — Jamie Madigan — https://www.psychologyofgames.com/2016/09/the-near-miss-effect-and-game-rewards/ (critical-analysis)
[clark-nearmiss] Gambling Near-Misses… (Clark et al., Neuron) — https://www.ncbi.nlm.nih.gov/pmc/articles/PMC2658737/ (academic)
[nearmiss-review] The Near-Miss Effect in Slot Machines (J Gambling Studies) — https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7214505/ (academic)
[xcom-aim] XCOM 2 / Aim Bonuses — StrategyWiki — https://strategywiki.org/wiki/XCOM_2/Aim_Bonuses (wiki)
[xcom2-wiki] Game difficulty (XCOM 2) — XCOM Wiki — https://xcom.fandom.com/wiki/Game_difficulty_(XCOM_2) (wiki)
[solomon-gd] Jake Solomon on randomness in XCOM 2 — Game Developer — https://www.gamedeveloper.com/design/jake-solomon-explains-the-careful-use-of-randomness-in-i-xcom-2-i- (interview)
[vigaroe-xcom] XCOM 2 Analysis: Difficulty Levels — Vigaroe — http://www.vigaroe.com/2020/05/xcom-2-analysis-difficulty-levels.html (critical-analysis)
[serenes-truehit] True Hit — Serenes Forest — https://serenesforest.net/general/true-hit/ (community)
[fe-truehit] True hit — Fire Emblem Wiki — https://fireemblemwiki.org/wiki/True_hit (wiki)
[fe3h-truehit] True Hit Guide — fe3h.com — https://www.fe3h.com/true_hit (wiki)
[bloodbowl-mlu] / [meeplelikeus-bb] Blood Bowl (2016) — Meeple Like Us — https://www.meeplelikeus.co.uk/blood-bowl-2016/ (review)
[goonhammer-bb] Risk Management in Blood Bowl — Goonhammer — https://www.goonhammer.com/hammer-of-math-risk-management-in-blood-bowl/ (critical-analysis)
[sts-intent] Intent — Slay the Spire Wiki — https://slaythespire.wiki.gg/wiki/Intent (wiki)
[hopeinsource-sts] Mastery and Learning through Games (Giovannetti) — Hope in Source — https://hopeinsource.com/games/ (interview)
[balatro-crosley] / [crosley-balatro] Balatro: Juicy Feedback in a Poker Roguelike — Blake Crosley — https://blakecrosley.com/guides/design/balatro (critical-analysis)
[balatro-gmtk] Balatro's 'Cursed' Design Problem — GMTK — https://gmtk.substack.com/p/balatros-cursed-design-problem (critical-analysis)
[kokutech-balatro] Learning How Balatro Rewards Players — Kokutech — https://www.kokutech.com/blog/gamedev/design-patterns/power-fantasy/balatro (critical-analysis)
[rogueliker] Balatro Interview — LocalThunk — Rogueliker — https://rogueliker.com/balatro-interview/ (interview)
[toucharcade-balatro] Balatro iOS Review — TouchArcade — https://www.patreon.com/posts/balatro-ios-one-114583423 (review) — **403 paywall, unverifiable; superseded for the haptics claim by the entry below**
[iphoneincanada-balatro] Balatro's iOS/Android release — iPhone in Canada — https://www.iphoneincanada.ca/2024/09/25/balatros-ios-android-release/ (review) — verified 2026-08-09; source of the per-scoring-tick haptic claim in ADJ-35
[shacknews-balatro] Balatro Mobile impressions — Shacknews — https://www.shacknews.com/article/141549/balatro-mobile-impressions (review)
[gaudelli-fmia] Fred Gaudelli on a week in the life of SNF — NBC Sports FMIA — https://www.nbcsports.com/nfl/profootballtalk/fmia/news/fmia-guest-fred-gaudelli-on-a-week-in-the-life-of-sunday-night-football (interview)
[defector-winprob] ESPN's Win Probability Graphic Wants To Give You Gambling Brain — Defector — https://defector.com/espns-win-probability-graphic-wants-to-give-you-gambling-brain (critical-analysis)
[fm26-storytelling] FM26's Match Day Experience — Football Manager official — https://www.footballmanager.com/fm26/features/where-storytelling-evolves-fm26s-match-day-experience (other)
[fmscout-fm26] FM26 New Features Guide — FM Scout — https://www.fmscout.com/a-football-manager-2026-new-features.html (news)
[wwdc810] WWDC19 810: Designing Audio-Haptic Experiences — notes — https://wwdcnotes.com/documentation/wwdcnotes/wwdc19-810-designing-audiohaptic-experiences/ (talk)
[wwdc21-haptics] Practice audio haptic design — WWDC21 10278 — https://developer.apple.com/videos/play/wwdc2021/10278/ (talk)
[hig-haptics] Playing haptics — Apple HIG — https://developer.apple.com/design/human-interface-guidelines/playing-haptics (other)
[notboring-btd] Behind the Design: (Not Boring) Habits — Apple Developer — https://developer.apple.com/news/?id=9ab1g4r3 (interview)
[notboring-sound] The Sound of Software — Not Boring — https://notbor.ing/words/the-sound-of-software (critical-analysis)
[reduce-motion-loaf] / [useyourloaf-rm] Reducing Motion of Animations — Use Your Loaf — https://useyourloaf.com/blog/reducing-motion-of-animations/ (other)
[apple-reducemotion] Reduce screen motion — Apple Support — https://support.apple.com/en-us/111781 (other)
[xbox117] Xbox Accessibility Guideline 117 — Microsoft Learn — https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117 (other)

**Narrative systems:**
[rimworld-gdc] RimWorld: Contrarian, Ridiculous, and Impossible Game Design Methods — Tynan Sylvester, GDC 2017 slides — https://media.gdcvault.com/gdc2017/Presentations/Sylvester_Tynan_RimWorld_Contrarian_Ridiculous.pdf (talk)
[rimworld-analysis] The Story Generator: A Game Design Analysis of RimWorld — https://zaydqazi.substack.com/p/the-story-generator-a-game-design (critical-analysis)
[rimworld-wiki] AI Storytellers — RimWorld Wiki — https://rimworldwiki.com/wiki/AI_Storytellers (wiki; 403'd, search-excerpt)
[ck2-surprising] The Surprising Design of Crusader Kings II — Game Developer — https://www.gamedeveloper.com/design/the-surprising-design-of-i-crusader-kings-ii-i- (critical-analysis)
[ck2-killscreen] The story AI behind Crusader Kings 2 — Kill Screen — https://www.killscreen.com/fascinating-story-ai-behind-crusader-kings-2s-dark-chain-events/ (interview)
[fm24-manual] Inbox and News — FM24 official manual — https://community.sports-interactive.com/sigames-manual/football-manager-2024/inbox-and-news-r4956/ (other)
[fm26-portal] FM26's Reimagined User Interface — Football Manager official — https://www.footballmanager.com/fm26/features/fm26s-reimagined-user-interface (other)
[fullerfm] FM Logic: Media & Press Interactions — Fuller FM — https://fullerfm.com/2025/05/22/fm-logic-media-press-interactions/ (critical-analysis)
[ootp-bp] Prospectus Review: OOTP 13 — Baseball Prospectus — https://www.baseballprospectus.com/news/article/16753/prospectus-review-out-of-the-park-baseball-13/ (review)
[ootp-forum] How do you turn off storylines? — OOTP forums — https://forums.ootpdevelopments.com/showthread.php?t=290435 (community)
[wildermyth-gdc] Getting Players Emotionally Invested in Procedural Characters — Nate Austin, GDC 2022 slides — https://media.gdcvault.com/GDC+2022/Speaker+Slides/GettingPlayersEmotionally_Austin_Nate.pdf (talk)
[df-wikipedia] Dwarf Fortress — Wikipedia — https://en.wikipedia.org/wiki/Dwarf_Fortress (wiki)
[boatmurdered-wikipedia] Boatmurdered — Wikipedia — https://en.wikipedia.org/wiki/Boatmurdered (wiki)
[yaap-nethackwiki] Yet Another Ascension Post — NetHack Wiki — https://nethackwiki.com/wiki/Yet_Another_Ascension_Post (wiki)
[blaseball-mary] What Blaseball Taught Me — Mary Georgescu — https://www.marygeorgescu.com/blog/blaseball (critical-analysis)
[blaseball-gd] Finding hope in the maniacal absurdity of Blaseball — Game Developer — https://www.gamedeveloper.com/game-platforms/finding-hope-in-the-maniacal-absurdity-of-the-game-band-s-i-blaseball-i- (interview)
[blaseball-tvtropes] Blaseball — TV Tropes — https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/Blaseball (community)
[oatmeal] So you want to build a generator… — Kate Compton — https://galaxykate0.tumblr.com/post/139774965871/so-you-want-to-build-a-generator (critical-analysis)
[emshort-2014] Procedural Text Generation in IF — Emily Short — https://emshort.blog/2014/11/18/procedural-text-generation-in-if/ (critical-analysis)
