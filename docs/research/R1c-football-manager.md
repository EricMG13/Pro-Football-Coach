# R1c — Football Manager Dossier

**Program:** Pro Football Coach rebuild — evidence base R1 (reference-game dossiers)
**Date:** 2026-08-09
**Lenses (2):** (1) The one-more-turn anatomy — emergent narrative, newgen attachment, long-horizon projects, the inbox as the real main screen, media ambivalence, data identity, and what SI protects across versions. (2) The failure literature — FM25 cancellation, FM26 launch and current state, the complexity-wall critique, and ground-up-rebuild lessons.
**Sources:** 71 unique citations ([S1]–[S71]), deduplicated from two lens agents; citations were gathered live from the web during research.
**Confidence note:** Load-bearing claims are multi-source or primary (SI statements, Jacobson interviews, live Steam data); single-source and community-inference items are marked Medium inline; two numeric conflicts between lenses are kept and flagged rather than resolved (FM-12, FM-35).

## 1. Scope & method

This dossier consolidates structured research from two lens agents into the single evidence file for Football Manager (FM) in the Pro Football Coach (PFC) rebuild program. Lens 1 examined why FM grips people; Lens 2 examined how and why it has recently failed. Findings carry stable IDs (**FM-01**…**FM-38**) numbered continuously through this file; downstream documents (R2-synthesis and later design docs) cite these IDs and they must never be renumbered. All lens citations are merged into one numbered source list ([S1]–[S71]); every finding ends with its source refs. Where the lenses disagree on figures, both are kept and the conflict is stated — conflicts are input to synthesis, not noise to resolve here. Unsourced statements appear only as marked "Inference:" lines with one line of reasoning.

Limits. The orchestrator did not populate the local-project-context input for this run; section 9 therefore maps findings against the rebuild brief (Madden / Retro Bowl / FM hybrid; the mechanically-complete-but-bland audit verdict; the fast/deep session split; the offline, fictional-league, one-thumb-phone constraints) and the system inventory stated in the project instructions. No repository files were read. Note: a prior draft of this file existed from an earlier workflow attempt built on a different lens run; it was replaced in full by this version so that every finding traces to the citations below. Section 8 verdicts are preliminary — final steal/adapt/avoid rulings happen in R2-synthesis.md.

## 2. The game in one page

Football Manager (Sports Interactive / Sega) is the dominant association-football management simulator: annual, PC-first, menu-driven, with no on-pitch avatar play. The player manages a club inside a licensed database of real leagues and players; the loop is inbox triage → squad, tactics, and transfer decisions → continue time → simulated match, repeated across seasons without a designed ending. Its distinguishing assets are a persistent world that simulates every league whether or not the player looks at it [S1]; hidden true attributes (current ability / potential ability) that make scouting an expertise fantasy [S49]; generated players ("newgens") who replace real ones as careers age out and who carry the game's deepest documented attachments [S45]; and the inbox, which SI's own telemetry identified as the de facto main screen [S2].

Playtime is hobby-scale: engaged players average in the hundreds of hours [S53], FM20 alone logged 60,000 years of combined play [S54], and the recognized record save spans 154 seasons [S55]. The audience is bimodal — most who try FM quit within five hours; those who cross the cliff typically pass 100 [S1][S19].

Recent history supplies the cautionary half of this dossier. FM25, a ground-up rebuild on Unity, was cancelled outright in February 2025 — the modern series' first cancellation, with pre-orders refunded [S9]. FM26 shipped on the new engine in November 2025 to record launch concurrents and "Mostly Negative" Steam reviews, the anger centered on the rebuilt UI rather than the simulation [S21][S22]. As of August 2026: 37% positive lifetime on Steam, 59% recent, support ended, FM27 due November 2026 [S36][S38]. The franchise's grip survived; its trust did not.

For this program, FM is the deep pole of the hybrid (analytical depth, emergent narrative, one-more-turn) and simultaneously the genre's best-documented warning about rebuilding a working game. Both halves are evidence.

## 3. Why players love it — mechanisms

**FM-01.** FM's grip rests on a persistent world that runs with or without the player; SI explicitly frames the product as a world, not a game. Jacobson: "We don't make a game, we make a world" — do anything you want in it. FM26 is framed as the first version of the next 20 years, with emergent storytelling and player agency as the design center. A save must feel like a league that keeps breathing between the user's actions — rival moves, news, standings drift. [S1]

**FM-02.** The inbox is FM's real main screen, and SI's own telemetry proved it: Home-screen use was limited and most player time was spent in the Inbox, so FM26 merged Home and Inbox into a single "Portal" hub — messages, news, fixtures, a two-week calendar, and results, with All/New/Tasks/Unread filters and a tile-to-card drill-down system. [S2]

**FM-03.** (Medium) The feed's texture comes from many in-fiction voices — clubs, competitions, media sources, journalists, a supporter spokesperson delivering fan reactions — not a single narrator, and it mixes decisions-required items with pure color; filters keep the two legible. [S3][S2]

**FM-04.** (Medium) Stories emerge from interlocking systems — morale streaks, personalities, relationships — so ordinary roster decisions become plot: benching or selling an influential player can trigger dressing-room conflict; losing streaks crater morale and cascade; a ~600-hour player cites lasting credit for a former club's later success as an authored-legacy payoff. [S43][S44]

**FM-05.** Each save is a private alternate football history in which the player authors the victory conditions and the sim supplies resistance — players invent objectives rather than chase preset win states. [S42]

**FM-06.** The one-more-match loop is binge-shaped — closer to a consuming second job than a session game — and visibly bleeds into real life: a fan honeymooned in Bulgaria to watch a team he'd managed virtually; police responded to one player's match shouting; the game has been cited in 35 UK divorce cases. [S42][S59]

**FM-07.** Players form museum-grade attachments to fictional newgens over decade-long careers — the strongest documented bonds in the game are to generated players. Jonny Sharples' Celtic newgen Ivica Strok (836 goals, 23 titles across 22 in-game seasons) gained a Twitter afterlife; a replica shirt and testimonial programme were displayed at Manchester's National Football Museum, with programme sales raising £500 for charity; another fan framed a shirt for his newgen striker. Generated rookies can carry the deepest attachment if discovered young and careers span many seasons. [S45][S46]

**FM-08.** Youth intake day is FM's self-described Christmas: an annual two-beat ritual (preview, then reveal) powered by lottery hopes of a "golden generation". The preview builds anticipation yet often diverges from the actual intake — the forecast noise preserves uncertainty and is what makes the reveal a holiday rather than a report. [S47][S48]

**FM-09.** The numeric attribute grid is FM's data identity. FM26's swap of staff attribute numbers for word labels and its shrunken attribute graphs were received as game-breaking — SI's own bug tracker hosts threads demanding numbers back because words made comparing staff slow and unintuitive. Numbers-forward cards are the expertise fantasy, not clutter; summarize on top of raw values, never instead of them. [S6][S33]

**FM-10.** Flavor-only agency still counts: players mourned Touchline Shouts when FM26 cut them, despite the feature having no actual gameplay effect — it provided psychological engagement during matches. [S30]

**FM-11.** (Medium) Two distinct judging audiences — the board (objective focus) and supporters (club identity, rival results, individual favorites) — generate FM's pressure drama and its beloved injustice stories: countless tales of managers sacked days after cup wins because faith, not results, collapsed. [S4][S50]

## 4. Where it fails — the failure literature

**FM-12.** Retention is bimodal with a five-hour cliff: most who try FM never cross it, while those who do become 100+ hour devotees; FM26 added dedicated accessibility systems presenting complexity as bite-sized, searchable explanations to ease entry without cutting depth. Conflict between lenses, both citing Jacobson: Lens 1 (Ingenuity interview) has about 8M people trying FM24, most stopping within five hours; Lens 2 (Eurogamer-derived coverage) has 19.09M FM24-era players, 7.5M past five hours (~60% bounce), and a 118.8-hour engaged average. The metric bases likely differ (buyers vs subscription reach; engaged average vs all players) — both kept, unresolved. The structural claim is robust either way: the first session is where the audience is lost, and the business runs on the retained minority. [S1][S19]

**FM-13.** Press conferences are the loop's acknowledged chore — repetitive dialogue trees with nonsense questions persisting for years, which veterans mass-delegate without felt penalty — and delegation is a confession mechanism: FM ships skip/delegate buttons for features players broadly consider not worth playing, then retains them version after version for role-play and occasional man-management stakes. The community's codified philosophy: delegate whatever ruins enjoyment; keep transfers, tactics, player development. If a feature's optimal use is skipping it, cut it or make it consequential — never ship tedium with a bypass as the fix. [S30][S7][S60][S66][S61]

**FM-14.** (Medium) The series carries a "spreadsheet game" complexity reputation that both defines and limits it: newcomers are described as overwhelmed, veterans routinely maintain external Excel tooling to play, TechRadar called FM24's set-piece menu "needlessly complicated", and FM26 reviews praising its tutorials as the most accessible ever confirm accessibility was a known deficit. [S68][S65][S41]

**FM-15.** (Medium) Community lab-testing shows FM's attribute system silently collapsed: FM Arena's automated harness concluded pace and acceleration dominate outcomes and you can "safely ignore all other attributes (except for goalkeepers)"; once an ideal tactic is found, most tactical switches are irrelevant. The solved-game feeling is a cited quit reason, with role-play framing proposed as the antidote. Depth that testing proves inert becomes bloat. [S62]

**FM-16.** (Medium) The stagnation critique — annual releases as paid database updates — was mainstream before FM25: FM24 was promoted as "the most complete edition to date" and reviewed as a disappointment; Steam threads say practically nothing changed FM24→FM26 in the core sim; a recurring community proposal is a 3–4 year cycle with annual database DLC. This pressure shaped SI's over-correction into a big-bang rebuild — the failure mode is swinging from iteration to revolution in one step. [S69][S67][S64]

**FM-17.** (Medium) Lapsed players cite chores, solved mechanics, time cost and burnout, and — post-FM26 — broken trust and lost feel rather than missing capability: saves become jobs, "many things… are just chores that make little difference", excitement replaced by obligation during SI's communication silences; post-World-Cup-update verdicts said FM26 "moved forward technically but sideways emotionally". Players quit over feel and friction, not feature count. [S65][S63][S35]

**FM-18.** FM26's UI failed again even after the "fixed" redesign: console-first patterns, pop-up menus, wasted space, controller-style carousels, and a UI "hurriedly lifted and shifted to the new engine" without polish; community reports tasks that took one click in FM24 needing four or five — despite Jacobson pre-launch billing FM26's UI as "a warm hug" restoring back buttons, search, and the inbox. One redesign pass on a failed UI did not clear the bar; UI recovery needs its own full validation cycle, not assurances. [S29][S32][S14][S31]

**FM-19.** A professional UX analysis (a principal experience-design strategist and 15-year player) frames the core rebuild error: the redesign destroyed veteran users' accumulated competence — broken mental models, relocated core functions, deleted keyboard shortcuts, higher interaction cost under a visually cleaner layout. "When you change the interface, you're not just redesigning the product. You're redesigning the user." Muscle-memory debt is real even for small games. [S31]

**FM-20.** FM26 shipped meaningfully below feature parity — international management deliberately cut (per Jacobson, not well-received by users and not complete enough to keep), plus shouts, comparison tools, the Development Centre, cup draws, deadline day, heatmaps, U18/U21 training control and more, tracked in a comprehensive community megalist. The telemetry-justified removal was rejected by the community anyway, and international management only returned May–June 2026 via a licensed FIFA World Cup 2026 update. Removals still read as theft to invested players regardless of usage stats — write an explicit parity checklist before a rebuild ships. [S33][S34][S8][S40][S35]

**FM-21.** FM26's launch paradox: record reach — 2.5M players, 84,909 peak concurrents (+23% vs FM24) — alongside ~22–23% positive Steam reviews (briefly 7th-lowest on the Steam 250; Metacritic/OpenCritic 72 vs FM24's 84; 44% of critics recommending), a 300+ fix patch the day after launch, and daily players down to ~32k by February 2026, with the 26.2/26.3 patches reading as stabilization rather than transformation. The loop out-pulled sentiment, but trust decayed measurably; loyal audiences buy day one on trust and then review what actually shipped — launch volume is not validation. [S20][S21][S22][S23][S24][S25][S26][S27][S28]

**FM-22.** Current state (verified August 2026): FM26 sits at 37% positive overall on Steam ("Mostly Negative", 9,041 English reviews) with recent reviews only "Mixed" (59%); support ended July 2026 with patch 26.3.2 as SI pivoted to FM27 (November 2026), saying feedback gave "a clearer direction and focused list of priorities"; 8M cumulative players by July 2026, second-highest ever behind FM24's 19M+, inflated by subscription-platform distribution. Nine months of patching moved sentiment from ~23% to only 59%-recent — launch-window reputation is nearly irrecoverable within a cycle. [S36][S38][S39][S40]

**FM-23.** (Medium) Despite record launch and cumulative reach, FM26 engagement decayed faster than any recent FM: ~51,000 concurrents by December 2025, reported as the lowest at that stage of any FM from 2016–2024, with ~10% week-on-week decline; major creators' FM26 videos took ~3x longer to reach prior view counts. Sentiment damage shows up as churn and creator abandonment, lagging headline sales — retention, not acquisition, took the damage. [S37][S40]

## 5. Development history & postmortem signal

**FM-24.** FM25 was cancelled outright in February 2025 after two delays (November 26 2024, then March 2025) — the modern series' first cancellation, with all pre-orders auto-refunded. SI: the game was "too far away from the standards you deserve", shipping-then-fixing would be wrong, and the team was "simply rushing too much and in danger of compromising our usual standards"; the extra time from the first delay was judged insufficient. A rebuild can miss two extended deadlines and still not be shippable; slips signal scope failure, not schedule failure. [S9][S10][S16][S17][S13]

**FM-25.** The root technical cause was underestimating the C++-to-Unity (C#) engine migration despite 2+ years of pre-production. Jacobson likened it to switching from Windows to Mac overnight — "learning a new language and way of working" — with tasks expected to take weeks dragging into months. Platform and engine swaps multiply every estimate; PFC keeps Swift/SwiftUI, removing FM25's single biggest risk class. [S16][S13][S19]

**FM-26.** The fatal component was the UI rebuild, not the simulation: Jacobson called the build "completely hollow" — simulation fine, interface confusing; the new tile-and-card UI "tried to be too clever"; he "literally sat there and just couldn't find things in my own game", including his youth squad. Also: "You can't polish a turd, and FM25… parts of it were turdy." In a menu-driven management sim the UI is the game; a working engine under an unnavigable shell is still a dead product. [S12][S15][S13]

**FM-27.** The kill criterion was feel, and it was discovered by a leadership playtest far too late — Christmas, weeks before the planned March release. Jacobson: "The actual game itself was working – but it wasn't fun. It felt clunky. The famous one more game factor just wasn't there." He concluded within one-to-two hours of the Christmas build that it couldn't ship, then escalated to Sega in January. Recurring feel-gates on real builds — "is it fun, can I find things" — must run throughout a rebuild, not as one verdict at the end. [S14][S12][S15]

**FM-28.** Cancellation was financially brutal: "the most expensive decision we've ever made", a lost year of revenue, and a ~$40.2M Sega quarterly write-down tied to FM25 work-in-progress (alongside the Amplitude divestment); analyst Rob Wilson estimated $30–40M total damage including the later FM26 backlash. [S11][S18][S17]

**FM-29.** FM25 stacked simultaneous bets: new engine + ground-up UI redesign + first women's football integration + the opening step of a 10-year plan — plus surprise problems (a forgotten dev item, a legal issue, a third-party problem). Jacobson admitted the team was "too ambitious" and "probably pushing our luck" even without the surprises. Women's football slipped to FM26, where it shipped well (35,000+ licensed players, 14 leagues). Never bundle engine change, UI reinvention, and headline new scope in one release; sequence them. [S11][S12][S19][S40]

**FM-30.** SI had failed a big-bang rewrite before: Championship Manager 4 (2003), a total rewrite adding the first 2D match engine, was delayed from late 2002 to March 2003 and still launched "littered with bugs" (missing player histories, match scores randomly changing); the fiasco led to SI leaving Eidos and rebranding as Football Manager, with the improved 03/04 edition rescuing it. Ground-up rewrites of beloved sims failed the same studio twice, 22 years apart; the pattern is structural, not personal. [S70][S71]

**FM-31.** Cancelling FM25 with refunds did not dent demand: FM26 set the franchise concurrent record anyway. Trust in quality standards proved more load-bearing than annual cadence — and conversely, FM26 shows that the trust buys day-one sales, not forgiveness for what ships (FM-21). [S10][S19][S21]

**FM-32.** (Medium) Serving newcomers and veterans with one rebuilt product failed in both directions: FM26's onboarding tutorials were praised as its most accessible ever while the same console-first choices enraged the PC veteran base; SI's earlier dedicated streamlined edition (FM Touch standalone) was axed after PC/tablet sales had "fallen significantly", with Android device fragmentation cited. Pick one primary player and depth posture per product; a mobile-native sim should be designed accessible-first, not simplified-down. [S41][S5][S31]

## 6. Community signal

**FM-33.** (Medium) A cottage industry of annual wonderkid/CA-PA lists exists because finding future stars cheaply is FM's core expertise fantasy: FM Scout and Passion4FM publish yearly wonderkid lists and shortlists; creators unmask hidden attributes in the editor and holiday saves years forward to verify development before rating recommendations — third-party scouting labor built on hidden potential values. The appeal is a Moneyball fantasy of undervalued finds. [S49][S43]

**FM-34.** (Medium) Player-invented challenges are decades-old community retention engines with documentation cultures and halls of fame: Dafuge's Challenge (running since FM2006 — newly-promoted non-league club to Champions League winners) spawned a Hall of Fame and a culture of documenting finances, obscure finds, and playoff heartbreak; the San Marino challenge is renowned as the series' hardest long-haul climb. Codifying community-style challenges as named, tracked modes is a proven retention pattern. [S51][S52]

**FM-35.** (Medium) Playtime is hobby-scale and SI treats it as the franchise KPI: Jacobson cited roughly 300-hour average PC playtime, calling FM more hobby than game; FM20 alone logged 60,000 years of combined play; the Guinness-recognized longest save is Darren Bland's 154-season Fiorentina career totaling 173 days of play time. See FM-12 for the conflicting 118.8-hour engaged-average figure — both attributed to Jacobson, bases unresolved. [S53][S54][S55]

**FM-36.** (Medium) Academic work (Edge Hill University, in-depth player interviews, social identity theory) finds FM functions as a persuasive game feeding players' social identities — promoting in-group affiliation and positive shared experiences extending beyond gameplay. [S58]

**FM-37.** (Medium) FM's fictional projections are culturally powerful enough to burden real careers: Cherno Samba, a Championship Manager 01/02 super-wonderkid, says he felt compelled to live up to his in-game stats, describes collapsing after a failed Liverpool move and feeling he had failed, and was still recognized by strangers through the game decades later — the wonderkid myth outgrew the person. [S56][S57]

**FM-38.** The community empirically audits the sim from outside: editor unmasking of hidden values, holiday-save verification of development, and automated test harnesses (FM Arena) that exposed attribute inertness (FM-15). Any numbers-driven sim with an invested audience will eventually be lab-tested by its players; the numbers must survive the audit. [S49][S62]

## 7. Mechanics anatomy relevant to Pro Football Coach

Translation of FM's load-bearing mechanics into PFC's pro-football frame (draft, contracts, cap, free agency, trades). Analysis cites the findings above; unsourced mappings are marked as inference.

- **The continue loop.** FM: inbox triage → decisions → advance time → match. PFC: news feed home → decisions → sim → game presentation. The feed is the spine (FM-02); the load-bearing detail is separating action-required items from color so triage stays fast (FM-03).
- **The calendar as ritual scaffold.** FM's year has one engineered holiday — youth intake, built as preview beat + reveal beat + forecast noise (FM-08). Inference: the pro football year natively contains several — combine, draft (class preview at season end → draft day), free-agency opening, cut day, trade deadline — so PFC can run more Christmases per season than FM, each needing its own two-beat structure and honest noise.
- **People as content.** Newgens prove generated players can carry decade-scale attachment (FM-07); the visible prerequisites: discovered young, hidden ceiling, long careers, accumulated shared history (titles, records), and exportable identity (shirts, testimonials). PFC equivalents: drafted rookies and UDFA finds, franchise records, ring counts, jersey retirement, career retrospectives.
- **Hidden information as expertise fantasy.** CA/PA plus scout error creates the wonderkid economy (FM-33). PFC: true ratings and potential hidden behind scout grades with bounded error; combine results as partial unmasking; bust and steal outcomes frequent enough to keep forecasts honest (FM-08's noise principle).
- **Judgment as drama.** Board vs supporters (FM-11) maps to owner (objectives, patience, win-now vs rebuild mandate) vs fan base (identity, rivals, star favorites). Two meters that can disagree generate the fired-after-a-cup-win injustice stories players retell.
- **Chores and delegation.** Any repeated media or ceremony beat ships only with a variety budget and first-class delegation from day one (FM-13); if its optimal play is skipping, cut it or give it consequence.
- **The data surface.** Numbers-forward player cards are identity, not clutter (FM-09); summaries sit on top of raw values, never replace them. Re-composing a dense grid for a phone without word-labels is PFC's open layout problem.
- **Flavor agency.** Small low/no-effect controls (sideline calls, celebrations) buy real engagement cheaply (FM-10) — but discovered-inert depth is a quit reason (FM-15). The tension resolves by where discovery happens; see open question 6.
- **Player-authored goals.** FM's save-as-alt-history (FM-05) and community challenges (FM-34) suggest shipping named challenge modes (cellar-team-to-dynasty, cap-hell rescue) with progress tracking, rather than leaving self-direction entirely unstructured.

## 8. Preliminary steal / adapt / avoid

PRELIMINARY — final rulings happen in R2-synthesis.md, not here.

| Verdict | FM element | One-line rationale (findings) |
|---|---|---|
| Steal | Feed/inbox as the home screen | Telemetry-proven real main screen; design it as home from day one (FM-02) |
| Steal | Task-vs-color feed filters | Decisions and texture must be separable for fast triage (FM-02, FM-03) |
| Steal | Draft-class reveal as engineered holiday | Intake-Christmas two-beat ritual plus noisy forecasts transfers directly (FM-08) |
| Steal | Hidden potential + imperfect scouting | Core expertise fantasy; powers community meta (FM-33, FM-38) |
| Steal | Generated-player attachment arc | Strongest documented bonds are to generated players (FM-07) |
| Steal | Numbers-forward player cards | Data identity; word-labels caused a revolt (FM-09) |
| Steal | First-session-as-product onboarding | Five-hour cliff is the funnel's choke point (FM-12) |
| Adapt | Dual judgment: owner vs fan base | Board/supporter split re-based on US franchise fiction (FM-11) |
| Adapt | Media beats | Only with a variety budget plus first-class delegation, else cut (FM-13) |
| Adapt | Flavor-only agency (sideline calls) | Placebo agency has value but must not be discoverable as fake depth (FM-10, FM-15) |
| Adapt | World-runs-without-you simulation | Full-league background sim scaled to a phone/offline budget (FM-01) |
| Adapt | Player-authored goals / challenges | Codify Dafuge-style community challenges as named tracked modes (FM-05, FM-34) |
| Adapt | Hobby-scale save longevity | Multi-decade dynasties reshaped for mobile session boundaries (FM-35, FM-06) |
| Avoid | Big-bang UI reinvention over a working sim | FM25 died in exactly our rebuild layer (FM-26, FM-27, FM-30) |
| Avoid | Feature removal without a parity ledger | Telemetry-justified cuts still read as theft (FM-20) |
| Avoid | Words replacing numbers | Instant legibility revolt from the invested audience (FM-09) |
| Avoid | Tedium shipped with a bypass | Delegation as confession; cut or make consequential (FM-13) |
| Avoid | Stacking engine + UI + scope bets | FM25's stacked-bet failure; sequence risk instead (FM-29, FM-25) |
| Avoid | Simplified-down companion product | FM Touch died; build accessible-first as the primary (FM-32) |
| Avoid | Depth that testing proves inert | Attribute system collapsed to 2 of ~40 attributes; harness-verify ours (FM-15, FM-38) |
| Avoid | Trading familiar navigation for chrome | Muscle-memory debt; keep navigation stable across rebuild phases (FM-19) |

## 9. Relevance map to Pro Football Coach

**Against the v1 inventory** (season loop, rosters/depth chart, draft, free agency, salary cap, trades, playoffs, multi-season dynasty, On the Field mode, JSON save slots). v1 already contains FM's mechanical skeleton; what it lacks is FM's connective tissue — a feed that narrates the world (FM-02, FM-03), rituals that structure the year (FM-08), and people whose careers accumulate story (FM-04, FM-07). The FM evidence says blandness of exactly our kind is a presentation-and-ritual deficit, not a missing-mechanic deficit: lapsed FM players quit over feel and friction, not feature count (FM-17), which matches the owner's "mechanically complete but bland" diagnosis of v1.

**Against the audit's failure classes.** v1's audited symptoms — transactions and sim outcomes resolving without being felt — are the same disease FM's burnout literature names ("many things… are just chores that make little difference", FM-17). Two findings convert directly into engineering tasks: (1) an attribute-sensitivity harness in the sim package (FootballSimCore is deterministic under a seeded RNG, so this is testable) proving every band of the 40–99 rating scale actually moves outcomes — FM's ~40-attribute system silently collapsed to two and the community found out (FM-15, FM-38); (2) a news layer in which every consequential transaction generates a voiced in-fiction reaction so no decision resolves in silence (FM-03, FM-04).

**Against the fast/deep session split.** FM's Portal filters (All/New/Tasks/Unread) are the one-thumb triage model for the fast session: open feed → clear action-required items → sim the next game (FM-02). The deep session inherits FM's planning surfaces — draft board, cap sheet, scouting grids — where numbers-forward density is the point (FM-09). The five-hour cliff compresses brutally on a phone: the first session must contain one complete satisfying loop — take the job, make a decision, sim, see the result, hear the reaction (FM-12). FM's binge shape has no clean session boundaries (FM-06); a phone game must land them deliberately, which is where the Retro Bowl lens (R1b) takes over.

**Against the hard constraints.** Offline: FM's world-keeps-breathing feel is pure local simulation — fully compatible; it is a sim-scheduling and news-generation problem, not a network one (FM-01). Fictional: PFC cannot borrow identity from a licensed database, and the licensed-content apology lever SI reached for after FM26 (the FIFA World Cup update, FM-20) does not exist for us — systems quality and generated-player attachment must carry the entire identity load; FM-07 is the existence proof that generated people can hold the deepest bonds, with the cold-start question flagged below (open question 3). One-thumb phone: FM26's console-first click inflation (FM-18) and FM Touch's commercial death (FM-32) bracket the layout problem from both sides — build accessible-first as the primary product, and re-compose the data grid for a thumb without word-labels (FM-09).

**Against the rebuild process itself.** PFC's shape is FM25's shape: a working, validated engine underneath a to-be-rebuilt experience layer. FM25 proves that combination still dies if the shell fails — in a menu-driven management sim, the UI is the game (FM-26). The evidence prescribes our mitigations directly: recurring owner feel-gates on real builds early and often, never one late verdict (FM-27 — this is what the program's three owner gates are for, and they should ask FM25's two questions: is it fun, can I find things); a written parity checklist against v1 before the rebuild ships (FM-20); stable navigation architecture across rebuild phases (FM-19); and no simultaneous platform bets — Swift/SwiftUI and the validated engine stay (FM-25, FM-29, FM-30).

## 10. Surprises & open questions

**Surprises** (merged from both lenses):

1. FM26's fiercest revolt was about data legibility, not sim quality — replacing numeric attributes with words and burying attribute graphs was called game-breaking; the spreadsheet is the brand (FM-09).
2. Record launch reach coexisted with "Mostly Negative" reviews; the damage surfaced weeks later as record-fast engagement decay and creator abandonment, not lost day-one sales — grip is not forgiveness (FM-21, FM-23).
3. The retention choke point is the first five hours, not the deep end; the business runs entirely on the 100+-hour minority (FM-12).
4. Players mourned Touchline Shouts, a control with zero mechanical effect — while separately citing discovered-inert depth as a quit reason. Placebo agency and fake depth are the same object judged by where discovery happens (FM-10, FM-15).
5. Cancelling FM25 outright with refunds did not dent demand for FM26 — trust in standards proved more load-bearing than annual cadence (FM-31).
6. Youth intake's Christmas feeling depends on unreliable forecasts — the noise is the holiday (FM-08).
7. SI justified removing features with usage telemetry and the community rejected the data-backed removal anyway — invested players treat removal as breach of ownership (FM-20).
8. Catastrophic reviews and paper success decoupled: 8M players and second-best-ever reach on subscription-inflated distribution, over 37% positive sentiment (FM-22).
9. A premium sports license was deployed as the apology/recovery lever for a broken launch — a lever a fictional-league game does not have (FM-20).
10. SI failed the same big-bang rewrite twice, 22 years apart (CM4 2003, FM25 2025); the CM4 fiasco is why "Football Manager" exists at all (FM-30).
11. Community-built automated harnesses empirically audit sim balance from outside and publish the results — external players discovered the 40-attribute system reduces to pace + acceleration (FM-38, FM-15).

**Open questions** (for R2-synthesis and prototypes):

1. The funnel-figure conflict (8M tried / ~300h average vs 19.09M players / 60% bounce / 118.8h engaged average — both attributed to Jacobson): which metric basis is right, and what should we assume when sizing onboarding vs depth investment? (FM-12, FM-35)
2. Does feed-as-home survive translation to one-thumb phone sessions, or does it read as notification clutter at phone scale? Prototype question for the first owner gate. (FM-02)
3. Can a fully fictional league bootstrap Strok-grade attachment from season one? FM newgens inherit a real club's accumulated meaning; PFC's teams start with none. What substitutes — generated team history, records, rivalries — and how fast can it accrue? (FM-07)
4. What is the mobile equivalent of the five-hour cliff — first session, first fifteen minutes? No mobile funnel data exists in this evidence base. (FM-12)
5. US draft culture (mock drafts, big boards) expects precision; FM intake thrives on noise. How much forecast error will a draftnik-shaped player tolerate before drama reads as broken scouting? (FM-08, FM-33)
6. Where exactly do flavor systems need real teeth? Needs a ruling in R2-synthesis: which sideline/media controls get mechanical effect, which stay placebo, and how discovery risk is managed for each. (FM-10 vs FM-15)

## 11. Sources

[S1] Miles Jacobson on Football Manager 26, Modding & a New Era of FM — https://ingenuityfantasy.com/feature-articles/miles-jacobson-on-football-manager-26-modding-a-new-era-of-fm/ — interview
[S2] FM26's Reimagined User Interface (Sports Interactive) — https://www.footballmanager.com/fm26/features/fm26s-reimagined-user-interface — official
[S3] Inbox and News — FM24 Touch/Console official manual — https://community.sports-interactive.com/sigames-manual/football-manager-2024-touch-and-console/inbox-and-news-r4976/ — official manual
[S4] Supporter Confidence — Football Manager 26 feature page — https://www.footballmanager.com/features/supporter-confidence — official
[S5] Major Changes for FM22 Touch and Beyond (Sports Interactive) — https://www.footballmanager.com/news/major-changes-fm22-touch-and-beyond — official
[S6] Why don't staff attributes use numbers? — FM26 official bug tracker — https://community.sports-interactive.com/bugtracker/1644_football-manager-26-bugs-tracker/user-interface/2166_advanced-access-betas-ui-issues/2074_general-user-interface-issues/why-dont-staff-attributes-use-numbers-because-it-isnt-intuitive-i-have-to-take-a-long-time-to-figure-out-who-is-good-its-annoying-r31805/ — community (official tracker)
[S7] Is sending my assistant to press conferences detrimental? — SI forums — https://community.sports-interactive.com/forums/topic/377861-is-sending-my-assistant-manager-to-press-conferences-detrimental-to-my-team/ — community
[S8] FM26: Comprehensive Bug, Missing Features & UI/UX Issues Megalist — SI forums — https://community.sports-interactive.com/forums/topic/598916-fm26-comprehensive-bug-missing-features-uiux-issues-megalist-updated/ — community
[S9] Football Manager 2025 canceled: "too far away from the standards you deserve" — TechRadar — https://www.techradar.com/gaming/football-manager-2025-canceled-as-sports-interactive-say-were-too-far-away-from-the-standards-you-deserve-and-releasing-the-game-in-its-current-state-would-not-be-the-right-thing-to-do — news
[S10] Football Manager 25 would have damaged us forever, says maker — BBC — https://feeds.bbci.co.uk/news/articles/c70xd5wl00zo — news
[S11] Football Manager 25 would have damaged us forever (BBC via AOL) — https://www.aol.com/football-manager-25-damaged-us-141511640.html — news
[S12] FM25 Cancelled — Miles Jacobson's BBC Interview Dissected — footballmanagerblog.org — https://www.footballmanagerblog.org/2025/09/fm25-miles-jacobson-bbc-interview-analysis.html — critical analysis
[S13] Miles Jacobson Opens Up About Cancelling Football Manager 25 — Operation Sports — https://www.operationsports.com/miles-jacobson-opens-up-about-cancelling-football-manager-25/ — interview
[S14] FM26: Miles Jacobson on FM25 Failure and FM26 Hopes — https://www.fm26.co.uk/news/miles-jacobson-fm26-interview/ — interview
[S15] The Athletic Football — Jacobson FM25 cancellation thread (interview excerpt) — https://x.com/TheAthleticFC/status/1961345829584753142 — interview
[S16] Miles Jacobson Explains FM25 Cancellation & FM26 Plans — FM Scout — https://www.fmscout.com/a-miles-jacobson-explains-fm25-cancellation-and-fm26-plans.html — interview
[S17] "It would have damaged us forever": FM director on the embarrassing cancellation — FourFourTwo — https://www.fourfourtwo.com/news/we-looked-stupid-football-manager-director-reveals-costliness-of-embarrassing-fm25-cancellation — interview
[S18] FM26's Rough Launch Could Cost SEGA $40 Million, Analyst Says — Operation Sports — https://www.operationsports.com/football-manager-26s-rough-launch-could-cost-sega-40-million-analyst-says/ — news
[S19] FM26 boss almost "ruined" huge 10-year plan by cancelling FM25 (Eurogamer coverage via FRVR) — https://frvr.com/blog/football-manager-26-boss-almost-ruined-huge-10-year-plan-by-cancelling-fm25-but-the-fanbase-is-already-bigger-than-ever/ — news
[S20] "Football Manager" bosses address '26's disastrous launch — NME — https://www.nme.com/news/gaming-news/football-manager-boss-responds-26-disastrous-launch-3908212 — news
[S21] FM26 debuts as 10th most played game on Steam despite overwhelmingly negative reviews — Gamepressure — https://www.gamepressure.com/newsroom/fm26-debuts-as-the-10th-most-played-game-on-steam-despite-overwhe/z388c0 — news
[S22] Football Manager 26 Now Has "Mostly Negative" Reviews on Steam — Game Rant — https://gamerant.com/football-manager-26-steam-reviews-mostly-negative/ — news
[S23] FM26 is already one of the worst games ever rated on Steam — FRVR — https://frvr.com/blog/football-manager-26-is-already-one-of-the-worst-games-ever-rated-on-steam-following-its-truly-disastrous-launch/ — news
[S24] Football Manager 26 Launches to "Mostly Negative" Steam Reviews — Operation Sports — https://www.operationsports.com/football-manager-26-launches-to-mostly-negative-steam-reviews/ — news
[S25] Football Manager 26 Player Base Stays Strong Despite Backlash — Operation Sports — https://www.operationsports.com/football-manager-26-player-base-stays-strong-despite-backlash/ — news
[S26] Football Manager 26 Is Tracking As The Lowest Steam Performer In Over A Decade — Operation Sports — https://www.operationsports.com/football-manager-26-is-tracking-as-the-lowest-steam-performer-in-over-a-decade/ — news
[S27] Football Manager 26 hits Steam: backlash with "mostly negative" reviews — Glass Almanac — https://glassalmanac.com/football-manager-26-hits-steam-faces-backlash-with-mostly-negative-reviews/ — news
[S28] Football Manager 26 Update 26.3: Youth Setup Overhaul and Database Changes — Soccer Gaming — https://soccergaming.com/football-manager-26-update-26-3-released-with-youth-setup-overhaul-and-database-changes/ — news
[S29] Football Manager 26: Is It As Bad As The Steam Reviews Suggest? — Forbes (Barry Collins) — https://www.forbes.com/sites/barrycollins/2025/11/08/football-manager-26-is-it-as-bad-as-the-steam-reviews-suggest/ — review
[S30] Football Manager 26 review — worth the wait? — ESPN — https://www.espn.com/gaming/story/_/id/46845460/football-manager-26-review — review
[S31] When a Game You've Played for 15 Years Suddenly Feels Foreign (UX analysis of FM26) — https://medium.com/design-bootcamp/when-a-game-youve-played-for-15-years-suddenly-feels-foreign-fa779d1b9d2d — critical analysis
[S32] FM26 Community Frustrations Grow as Basic Features Remain Unfixed — Operation Sports — https://www.operationsports.com/fm26-community-frustrations-grow-as-basic-features-remain-unfixed/ — news
[S33] Everything Football Manager 2026 forgot — what's actually missing from FM26 — FRVR — https://frvr.com/blog/everything-football-manager-2026-forgot-whats-actually-missing-from-fm26/ — community roundup
[S34] Ben Carr — translation of Jacobson on removing international management from FM26 — https://x.com/DoctorBenjy/status/1975546924116717781 — community
[S35] FM26 International Management: enough to save the game? — Footballrover — https://footballrover.com/fm26-international-management-world-cup/ — community
[S36] Football Manager 26 — Steam store page (live review ratings, Aug 2026) — https://store.steampowered.com/app/3551340/Football_Manager_26/ — primary data
[S37] Football Manager is dying as FM26 player counts and engagement nosedive — FRVR — https://frvr.com/blog/news/football-manager-is-dying-as-fm26-player-counts-and-engagement-nosedives-into-the-ground/ — news
[S38] Football Manager 26 updates end as Sports Interactive moves on to FM27 — GamesHub — https://www.gameshub.com/news/article/football-manager-26-updates-end-fm27-2888131/ — news
[S39] Will there be an FM27 and when will it be released? — The Higher Tempo Press (May 2026) — https://www.thehighertempopress.com/2026/05/will-there-be-an-fm27-and-if-so-when-will-football-manager-2027-be-released/ — news
[S40] Football Manager 26 — Wikipedia — https://en.wikipedia.org/wiki/Football_Manager_26 — wiki
[S41] Football Manager 26 Review: A new beginning after a year of waiting — Sportskeeda — https://www.sportskeeda.com/esports/football-manager-26-review-a-new-beginning-year-waiting — review
[S42] Inside the Cult of "Football Manager" — Vice — https://www.vice.com/en/article/football-manager-greg-johnson-322/ — critical analysis
[S43] Is Football Manager the Greatest RPG Ever? — loudpoet — https://loudpoet.com/2023/09/23/is-football-manager-the-greatest-rpg-ever-tldr-yes/ — critical analysis
[S44] The War of the Stories — Emergent vs. Linear Storytelling — GameGrin — https://www.gamegrin.com/articles/the-war-of-the-stories-emergent-vs.-linear-storytelling/ — critical analysis
[S45] The Undying Legacy of Ivica Strok: Legendary "Football Manager" Regen — Bleacher Report — https://bleacherreport.com/articles/2587913-the-undying-legacy-of-ivica-strok-legendary-football-manager-regen — critical analysis
[S46] Man Has Framed Shirt Dedicated To Football Manager Newgen In His House — SPORTbible — https://www.sportbible.com/football/news-reactions-community-gaming-man-has-framed-shirt-dedicated-to-football-manager-newgen-in-his-house-20210503 — news
[S47] Youth Intake — Football Manager Projects (Daniel Evensen) — https://fmprojects.substack.com/p/youth-intake — community
[S48] Youth Intake: How Clubs Produce Newgens — Passion4FM — https://www.passion4fm.com/youth-intake-guide-how-clubs-produce-newgens/ — community
[S49] Football Manager 2026 Wonderkids — FM Scout — https://www.fmscout.com/a-football-manager-2026-wonderkids.html — community
[S50] Board Confidence guide — FM Scout — https://www.fmscout.com/confidence.htm — community wiki
[S51] What is the Dafuge's Challenge? — sortitoutsi — https://sortitoutsi.net/content/71012/what-is-the-dafuges-challenge — community
[S52] The Ultimate San Marino Challenge — Football Manager Blog — https://www.footballmanagerblog.org/2024/11/san-marino-challenge-football-manager.html — community
[S53] Football Manager's average playtime proves it's more hobby than game — Dot Esports — https://dotesports.com/general/news/football-manager-average-playtime-proves-more-hobby-than-regular-game — news
[S54] "Football Manager 20" has recorded 60,000 years of playtime — NME — https://www.nme.com/news/gaming-news/football-manager-20-has-recorded-60000-years-of-playtime-2807097 — news
[S55] Fan breaks world record for longest ever Football Manager game — Sportskeeda — https://www.sportskeeda.com/football/fan-breaks-world-record-longest-ever-football-manager-game — news
[S56] "I felt like I'd failed": Cherno Samba on life after being a Championship Manager wonderkid — FourFourTwo — https://www.fourfourtwo.com/features/i-felt-like-id-failed-cherno-samba-on-life-after-being-a-championship-manager-wonderkid — interview
[S57] Cherno Samba: My Champ Man stats were right, but I didn't put the work in — Planet Football — https://www.planetfootball.com/in-depth/cherno-samba-my-stats-on-champ-man-were-right-i-didnt-work-hard-enough — interview
[S58] Football Manager as a persuasive game for social identity formation — Edge Hill University — https://research.edgehill.ac.uk/en/publications/football-manager-as-a-persuasive-game-for-social-identity-formati-2 — academic
[S59] Football Manager Stole My Life: 20 Years of Beautiful Obsession (book) — https://www.goodreads.com/book/show/15823371-football-manager-stole-my-life — book
[S60] Which Responsibilities You Should and Shouldn't Delegate in FM26 — Operation Sports — https://www.operationsports.com/which-responsibilities-you-should-and-shouldnt-delegate-in-football-manager-26/ — community guide
[S61] The Most Annoying Aspect Of Football Manager — FM Projects — https://fmprojects.substack.com/p/the-most-annoying-aspect-of-football — community
[S62] Make Football Manager Great Again — FM Projects (FM Arena testing) — https://fmprojects.substack.com/p/make-football-manager-great-again — community
[S63] Self Inflicted Wounds — FM Projects — https://fmprojects.substack.com/p/self-inflicted-wounds — community
[S64] The Delay — FM Projects — https://fmprojects.substack.com/p/the-delay — community
[S65] Football Manager Burnout — A Personal Story — The FFM — https://theffm.co.uk/football-manager-burnout/ — community
[S66] "Hate press conference" — FM26 Steam General Discussions — https://steamcommunity.com/app/3551340/discussions/0/691997051773290819/ — community
[S67] "Nothing new: Total disappointment" — FM26 Steam General Discussions — https://steamcommunity.com/app/3551340/discussions/0/690866958234805523/ — community
[S68] Football Manager 2024 review — extra time — TechRadar — https://www.techradar.com/gaming/football-manager-24-review — review
[S69] Football Manager 2024 review: High expectations, huge disappointment — Dot Esports — https://dotesports.com/football-manager/news/football-manager-2024-review-high-expectations-huge-disappointment — review
[S70] Championship Manager 03/04: The Review (on CM4's failed launch) — Champ Man Fans — https://champmanfans.wordpress.com/2021/03/20/championship-manager-03-04-the-review-cm9798/ — community
[S71] Championship Manager 4 — Wikipedia — https://en.wikipedia.org/wiki/Championship_Manager_4 — wiki
