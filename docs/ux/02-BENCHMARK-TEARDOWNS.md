# 02 — BENCHMARK TEARDOWNS

**Coverage is the headline caveat and is stated before any finding.** The brief requires eight
primaries × ten axes, four secondaries, and three non-game analogues. What was actually obtained:

| Required | Obtained |
|---|---|
| 8 primaries × 10 axes = 80 cells | **31 cells with evidence.** Four titles have real coverage (Football Manager desktop, FM Mobile/Touch/Console, Madden Franchise, Out of the Park). Retro Bowl has a design *rule* but no feature inventory. **Madden NFL Mobile, Franchise Hockey Manager, Motorsport Manager Mobile and NBA 2K MyNBA produced nothing that survived verification** |
| ≥4 secondaries | **1** (Retro Bowl lineage / New Star Games). The rest produced nothing |
| ≥3 non-game analogues | **0.** Fantasy apps, trading terminals, broadcast graphics, mission control and PFF all returned nothing across two research passes |

**Self-scored 2/5 on brief dimension 4.** No remediation was possible within two full research
rounds; §12 states what would close it.

**Where the evidence actually is:** the only Grade-A material in this dossier is the 18 in-repo
Football Manager captures and 12 owner-supplied Madden/MLB-The-Show captures. Two web research
passes (~12M subagent tokens, 216 agents) produced **no Grade-A evidence at all**. Every web
finding is Grade B (publisher/developer-authored, some in marketing register) or C.

---

## 1. Football Manager 26 — desktop

Evidence: 13 first-hand captures in `FM Screenshots/` (Grade A), plus SI's published UI page and
Steam reception (B/C). Provenance is separated carefully: 12 captures are the shipped FM26 build,
1 is watermarked **"NON-FINAL CAPTURE"**, and 3 further captures are watermarked **"taken from FM25
design files and not from a game build"** — FM25 was cancelled and never shipped, so those are
design intent with zero reception evidence and are marked **[FM25-UNSHIPPED]** wherever cited.

**1. Information density — 360 cells (A).** Squad list: 15 columns × ~24 rows. Columns: select,
depth slot, status flags, player, position, best position, transfer value, best role, age, ability,
potential, playing time, nation, wage, expiry. Legibility technique observed: colour-filled position
chips do the positional grouping in the leftmost column; two-letter status pills (`Inj`/`Tir`/`Wnt`)
occupy their own narrow column instead of sitting inline; type is monochrome so colour reads only
where it is meaningful; the player name sits in a bordered pill so the tap target is visible.
Player Report is second-densest at ~90–110 points: 36 attributes in three labelled columns
(Technical 14 + Set Pieces 5, Mental 14, Physical 8), 5 star-rated role rows, a position map, and 7
summary cards.

**2. Navigation topology (A/B).** Top bar of six: `Portal · Squad · Recruitment · Match Day · Club ·
Career`, each with a dropdown, and a second row of contextual siblings. SI replaced the long-standing
sidebar with this top bar (B). **Bookmarks are capped at 12** out of ~30 destinations, observed
directly as "Edit Bookmarks (6/12)" over an enumerated list — and one of those destinations is
**"Responsibilities"**, i.e. delegation is configured in its own top-level place, separate from where
it is exercised. Depth was **not measured** — static frames cannot establish tap counts (gap).

**3. Delegation (A).** Three trust affordances share one toolbar on the Tactics Planner: **Advice ⌄**
(recommendation), **Undo** (reversibility), **Quick Pick ⌄** (delegate the selection). Beside them a
scope switch, **"All Matches" vs "Next Match"** — delegation scoped by *time*, not only by domain.
**"Go On Holiday" sits in the Calendar toolbar**, so maximum delegation is one control away from the
week view rather than buried. [FM25-UNSHIPPED] The **Dugout** panel reduces an assistant's
suggestion — *"I think we should replace Stones with Akanji."* — to **"Do it"** and **"Ignore ⌄"**.

**4. Decision framing (A, partial).** Defaults exist (a formation preset, an Intensity slider
pre-set). **Consequence preview was not observed on any surface** and is recorded as a gap.

**5. Ceremony (A).** Minimal on desktop. The Portal carries a news module and a rolling calendar.
Duration and skippability are **not observable from stills** (gap).

**6. Data-visualisation vocabulary (A).** Full catalogue: attribute value + green heat fill (number
always printed); trend chevron beside an attribute; half-step star ratings, with Current and
Potential as *separate adjacent rows*; 5-segment foot-strength bar; 5-bar form column chart with
numeric average; colour-banded rating pill; 8-axis radar with a filled polygon, **always paired with
a plain-language verdict**; league-relative verdict badge ("Performing much better than average");
scatter plot showing the league population with your club as a white dot; sparkline; a
budget-vs-actual bar that **overruns its own track in red at 101.8%**; stacked proportion bar with a
legend-dot table; result dot (filled green win / hollow red loss / half amber draw); event chips with
minute stamps; mood emoji; heart glyph with an ×multiplier for training intensity; coach-load donut
counts.

**7. Progressive disclosure (A).** A **browsable in-game encyclopedia**: a modal defining a term
("Squad"), with inline links to related terms, a live data panel showing *your* instance of the
concept, a tray of 13 destination chips, and its own back/forward/home navigation. This is a help
*layer*, not a tooltip, and it is removable by not opening it.

**8. Touch ergonomics — N/A** (desktop). Its density is explicitly a translation problem; see
[`00`](00-GATE-ZERO.md) §4.

**9. Session resumability — not observed** (gap).

**10. Failure modes (B/C).** SI states the architecture: *"tiles are the component parts of every
in-game screen in FM26, providing key snapshots of relevant info. When clicked on, each tile opens up
into a Card that carries more detail"*, with *"Overview screens provide you with key general
information early and often, with more detailed information available when you explore and dig
deeper."* **It was received badly**: ~81% negative on Steam ("Mostly Negative", against
"Overwhelmingly Positive" for the two prior releases), with widely repeated community reports that
splitting core screens into pop-ups roughly **doubled clicks for routine tasks** — a figure of up to
**105 clicks to set a full week's training** circulated — and that player search lost centrally
visible nationality and star rating. One review, carried via AOL, calls it *"Fun to play, awful to
look at"*.

> **The conflict is the finding, and it must not be averaged away.** SI's stated intent (B) and the
> measured reception (C) point in opposite directions. Progressive disclosure is **not**
> automatically a density remedy. The mechanism the evidence suggests — though no source isolates it
> — is that drill-down cost is ruinous for *routine repeated* tasks specifically, not for
> exploration. **Click-cost per routine task is therefore the metric to instrument**, and it is the
> single most decision-relevant result for this product's week-advance loop.

---

## 2. Football Manager Mobile / Touch / Console — the natural experiment

Evidence: 2 FM23 Mobile captures (A), SI feature pages and announcements (B), one hostile review (C).

**The cut list is a stated depth ladder, not incidental trimming (B).** SI described Touch in 2021 as
for players wanting *"something simpler than the 'full fat' FM, but more in-depth than our mobile
game"*, attributing the tier's 2013 creation to market research. Two corrections travel with this:
attribute it as **"SI stated in 2021"**, because the article's actual subject is the discontinuation
of PC/Mac Touch; and as of FM26 the lineup is four SKUs with Touch and Console converged, so the tidy
three-rung ladder is **stale as current positioning** even though the ordinal relation holds.
A related claim that FM Touch 2022 was withdrawn from Steam/Epic/App Store/Play surviving only on
Switch was **refuted 0-3** and must not be repeated.

**What FM24 Console kept vs cut (B, corroborated by a hostile source).** Kept: **set-piece design**
(a refreshed Set Piece Creator) and **board/owner requests** (a dedicated Club Vision tab, one High
Priority request per season — a decision affordance with an explicit scarcity constraint). Cut:
managerial attributes, selling via intermediary, one-to-one player conversations (*"only four team
talk and shout options"*), media interaction (*"completely absent"*), and a 10-league/30-season
ceiling. The cut list comes from **Push Square's negative review**, which independently confirms the
set-piece creator is present while enumerating what is absent — a hostile reviewer confirming the
kept feature defeats the marketing-fluff objection.

**What that ranking implies (D, premises stated).** Spatial/tactical authorship and institutional
negotiation are treated as load-bearing; conversational systems are treated as expendable. **The
opposite reading is equally consistent with the evidence** and must be recorded: conversation may be
first to go on a controller because text entry and menu depth are expensive there, not because it is
low-value. No source explains SI's reasoning. This ambiguity matters directly — this product's
staff-call-in system is a conversational system.

**FM24 Mobile bookends the week (B).** Named **Pre-Match Hub** (*"key insights before big games"* —
tactics, scouting, analysis, key stats, opponent predicted line-up, danger men, style of play, plus
Match Expectations covering media prediction, board expectation, fan thoughts) and **Post-Match Hub**
(*"an overview of how the game went, with key information available to digest straight after
full-time"* — match stats, player analysis, reactions, post-match team meeting). This is a shipped
pattern for **pre-digesting information at the two moments a mobile session naturally starts and
ends**. Grade B is promotional register, so **nothing about their density, layout, tap depth or
skippability is supported**. Two adjacent claims were **refuted 0-3**: that the feature list bounds
the mobile decision surface to five interaction classes, and that in-match notifications are SI's
framing of interruption-driven decisions.

**Mobile match view (A).** Landscape. Chrome is one top bar — hamburger, clock, both clubs + score,
an event dot-strip showing match progress, settings, PAUSE — plus a full-width commentary ticker and
two corner icon buttons. The pitch occupies essentially the whole frame. **~7 persistent controls
total.** Set against this product's `MatchDayView.swift` (1020 lines) plus `MatchDayScoreBug.swift`
(482), the benchmark's answer is markedly *less* furniture.

**Ceremony survives on the phone (A).** A goal fires a full broadcast lower-third — angled plate,
portrait card with shirt number and flag, large name, "Goal", club and descriptor — over the 2D
pitch, in landscape, **without leaving the match view and without requiring a dismissal**. This is
the single most important precedent for [`00`](00-GATE-ZERO.md) §6.

---

## 3. Madden NFL — Franchise Mode

Evidence: 10 owner-supplied captures spanning Madden 13 → Madden 25(2013) → Madden 20 → a
Franchise-era build (A), EA Gridiron Notes and feature pages (B), Operation Sports and Axios (B/C).

**Navigation topology (A).** Connected Franchise: **`HOME · NEWS · ACTIONS · TEAM · LEAGUE`**, with
header showing season/week and your identity (`[C] Walter Payton — 2nd String HB, 85 OVR — 0 XP`).

> **The most useful structural finding in the dossier: `ACTIONS` is a named top-level destination.**
> Madden separates *what is happening* (HOME/NEWS/LEAGUE) from *what I must do* (ACTIONS). This is
> the READOUT/DESTINATION distinction the brief believed it found in this repository. It is not in
> the repository — but it is here, shipped, and this is its citation.

For Madden 27 (B) EA states a **Roster Management** centre consolidating *"your roster, depth chart
and lineup, free agency, scouting, and trades"*, and a **News Center** *"accessible from anywhere in
Franchise... always one button away"* with filters for own team / multi-user league / story type /
league-wide, plus *"A persistent news ticker now runs across every screen."* Corroborated
independently by Axios. **The transferable topology is the pairing**: one consolidated management
destination plus one omnipresent filterable feed — two persistent destinations rather than a wide
menu. EA has held the "news is first-class and persistent" position for 13+ years (A: the ticker is
present in every Madden generation captured, 2012-era onward).

**Delegation and its social cost (B) — the most transferable mechanic in the dossier.** EA verbatim:
*"Coordinators may approach you with their Gameday Strategy. If you dismiss their input or make poor
choices, their trust in your leadership may decline"*, with the inverse upside that going well earns
them XP. Separately: *"Your Approval Rating reflects how well you manage key groups: the GM, Coaching
Staff, Players, Fans, and the Media"* — moving weekly, judged at season end against both user and CPU
coaches, low ratings risking the job, and surviving ratings carrying *"into future seasons"*.
**This makes ignoring an advisor a scored act rather than a free one.** Qualification: coordinator
trust is documented only qualitatively ("may decline"); no source establishes it as a numeric meter,
whether the cost is previewed before you dismiss, or whether it is undoable. Only Approval Rating is
named as persisting.

**Decision framing (A + B).** The **"BIG DECISION"** surface is the clearest single-frame answer to
this axis anywhere in the research. Observed: a headline and body copy stating the problem
(*"You have some weak spots on your roster..."*); the context that makes it judgeable — **your own
depth chart at that position, carrying a letter grade (`B-`)**, with the incumbents' OVR; then
candidate cards each with an OVR badge (77 green, 71 amber), three position-relevant attributes as
number-over-bar, an archetype glyph, a **`SUGGESTED TRADE OFFER` naming the asset you would give
up** — and three stacked controls: **`TRADE FOR PLAYER` / `NOT INTERESTED` / `PLAYER CARD`**. So:
context shown, default implied by ordering, price previewed, **an explicit decline**, and a route to
detail that does not commit.

Also **(B)**: the weekly loadout *"will be automatically filled with suggested abilities based on how
your team matches up with that week's opponent... ultimately it's up to you to choose how to
prepare."* **The no-action path is a designed state, not a null state.** Refutation attempts found
EA Forum complaints that the game keeps *re-applying* its recommendations over manual picks — which
presupposes the mechanic.

> **Refuted, and important because it is the brief's central question: that Madden previews the
> consequence of the weekly choice (0-3), and that Madden 27's delegation is confirm-with-preview
> rather than fire-and-forget (0-3).** Consequence preview is unanswered in both directions. Do not
> let the pre-population finding be read as implying preview. Also refuted: a fixed ten-slot loadout
> (1-2), Supersim variance retuning (0-3), the coordinator-playsheet stacking constraint (0-3).

**Ceremony (A).** Delivered as a **feed, not a cutscene**: League News pairs a result card
(*"MISSED OPPORTUNITIES — Jaguars fall short in New York, 23-17"*) with attributed pundit posts —
real broadcasters with EA-suffixed handles — tagged by week. Cost: zero interactions, because it is
a destination you visit rather than an interruption. Postgame carries an `EA SPORTS HIGHLIGHTS`
linescore with a scrollable plain-sentence play list, and a `TEAM STATS` comparison.
**The mechanic transfers; the real named broadcasters absolutely do not** — see `CLAUDE.md`.

**Data-visualisation vocabulary (A).** 0–99 OVR in a colour-graded badge for individuals; **letter
grades (`B-`) for aggregates** such as a depth-chart position group — a two-scale system this
product does not have; number-over-bar attributes; archetype glyph + word; tick/cross capability
lists at the point of choice; **an amber leader triangle** marking the leading side of each
comparison row in Game Stats and Team Stats.

> The leader triangle encodes by **position and direction, not hue**. It survives greyscale and
> colour-blindness for free, and is adopted in [`06`](06-TOKENS-AND-DENSITY.md) §4.

**Progressive disclosure (A).** Career setup shows trade-offs *at the point of choice*: PLAYER and
COACH cards each carry a green-tick capability list, and the NFL Legend card mixes ticks with a **red
cross** — *"✗ Ratings will be lower as a rookie"*. Career Settings is a label+stepper list where
inline help renders **for the focused row only** (*"Determines if coaches can be fired for poor
performance."*). Team selection embeds comparison: the centre team card is flanked by the depth
charts of the adjacent teams.

**Madden 27 "Emergent Actions" (B, medium confidence).** EA: *"Emergent Actions replace the old
weekly flow from Madden NFL 26 with a focus on interaction and prioritization. They are not
notifications. They are not spam. They are not unorganized clutter. Every Emergent Action asks you to
make a real decision."* **This is vendor self-assessment and must never be repeated as a verified UX
outcome** — no published usability critique of the surface exists. Madden 27 shipped 2026-08-13,
nine days before this research, and sits one cycle newer than the brief's stated scope.

**8. Touch ergonomics — N/A** (console). Every capture depends on **button legends** (`X SELECT`,
`L1/R1`, `△ MANUAL`) as load-bearing chrome with **no touch equivalent**. This is the standing
translation note for the whole Madden/Show corpus: every borrowed pattern must replace the legend
with a visible affordance.

**9. Session resumability — not observed** (gap). **10. Failure modes** — extensively documented in
community discourse per the brief, but **no characterised source survived verification** (gap).

---

## 4. Madden NFL Mobile — NOT OBSERVED

Two research passes produced nothing that survived verification. No navigation topology, no session
structure, no delegation model, no pageantry inventory, no ergonomics. **No claim about this title
may appear downstream.**

Adjacent and distinct: the **Madden NFL Companion App** (Grade B, Double Coconut studio case study)
— a mobile companion to the console game, iOS and Android, 6 months plus maintenance, Angular +
templated HTML/CSS wrapped in Ionic, constrained by a legacy Haxe codebase and limited backend
access. Its one on-brief sentence: they redesigned *"sets, card opening, and **franchise management**
for mobile"*. A documented instance of compressing franchise management onto a phone — but with **no
cut list, no metrics, and no stated research**. Design philosophy is given only as *"simplify the
flows and make each feature as intuitive as possible"*. Thin, and it must not be conflated with
Madden NFL Mobile the standalone game.

---

## 5. Retro Bowl / Retro Bowl College — the floor, as a rule

Evidence: developer interviews (B), Wikipedia corroboration (C).

**The rule, stated by the designer (B).** Simon Read, founder of New Star Games, Nintendo Life
2022-11-14: *"In a similar way to Retro Bowl, and this goes right back to my early New Star Soccer
games, you only take control of the attacking phases of the game."* The load-bearing sentence
follows immediately: *"Of course defending is a major part of any sport but is generally less fun to
play, so the idea was to skip through those defensive sequences as quickly as possible, **relying on
your team building and management skills to determine defensive outcomes**."*

**Precise formulation: the player controls offence plus kicking, never defence; defence is resolved
by the management layer.** Independently corroborated (C): *"the defense is not playable, and is
simulated by the game."* Scoping correction: the interview's proximate subject is Retro Goal,
generalised to Retro Bowl by Read's own "In a similar way to Retro Bowl" — cite it as the shared
offence-only lineage.

**Design restraint as stated policy (B).** PocketGamer.biz 2021-11-09: *"I feel that the game is at a
point where adding major new features risks upsetting the balance of the game and the simplicity that
has brought it success. Every day I get asked for online play, defensive action, full rosters,
college teams... but some of these will change the core of the game too much, so anything like that
will likely come in a sequel."* The prediction held — those went into **separate SKUs** (Retro Bowl
College, College+, NFL Retro Bowl '26/'27), not the base game. Correction: Read attributes success
to **simplicity only**; balance is named as a co-equal property placed at risk, not as a cause.

**What the brief actually asked for and did not get (gap).** The concrete inventory — which of
roster, coaching-staff upgrades, contracts, morale, draft and facilities are kept versus dropped —
and **the tap count per week**. Neither is sourced. The floor is therefore established as a
*philosophy* and not as a *number*, which is precisely the wrong way round for
[`00`](00-GATE-ZERO.md) §1. Verification limitation: both Retro Bowl checks ran after the research
session's WebSearch budget was exhausted (200/200); Reddit and the Retro Bowl wiki were unreachable,
so community counter-evidence was never checked. A stronger framing — that the management layer is
shallow inter-match filler — was **refuted 0-3** and must not be used.

---

## 6. Out of the Park Baseball — the delegation reference implementation

Evidence: OOTP's own wiki and manuals across six product generations (B), 3 owner-supplied
MLB The Show captures (A) covering the adjacent draft/scouting problem.

**Delegation architecture (B, high confidence) — the best-documented in the dossier.**
`Team Control Settings`: **11 independently assignable areas**, each its own dropdown choosing
between the human manager and a named staff member — setting lineups/depth/pitching staff; active
roster moves; transactions; initiating and reacting to trades; drafting players; international
players; sign/fire team personnel; sign/fire minor-league personnel; minor-league
signings/releases; minor-league promotions/demotions/strategy; minor-league lineups/depth/pitching.
Verified by fetching the page twice including `action=raw`, corroborated on a different host and a
different product generation, and present as far back as OOTP 18 (2017). **Correction:** OOTP *also*
ships global escapes — a "Do Not Disturb" mode where *"The AI will handle everything for you and will
never interrupt auto-play"* — so the accurate framing is **a per-area matrix as the primary surface
with global escapes layered on top**, not the absence of a global toggle.

**A second, temporary layer (B, medium).** `Vacation Settings`: a **parallel column of per-area
dropdowns**, each offering "Use Current Settings", which *"forces the game to use the value you
selected in the Team Control Settings section"*. The game's own framing is explicit — the Manager
Options screen *"allows you to delegate much of your authority to your staff on a temporary or
permanent basis."*

> **The trap the documentation volunteers, and the most useful single sentence in the web research:**
> leaving an area on "Use Current Settings" while *you* personally own it means **nobody covers it**
> in your absence — *"no changes will be made... other than the minimum required to keep the team
> running."* **The inheriting default is a hazard, not a safe default.** Direct warning for any
> cruise or away mode; see [`08`](08-DECISION-REGISTER.md) D-008.

**Event-driven handback (B, high).** `Exit Auto-Play` documents **six triggers, two with configurable
thresholds**: injuries (dropdown from "No Injury Limit" to "Out 2 months or more"), day-to-day
injuries ("No Limit" to "30% or more performance drop"), an opt-in checkbox for minor-league injury
notification, DL activation eligibility, personal messages, and received trade proposals. **Default
is on** — auto-play interrupts for any injury keeping a player out at least three days — and ESC
stops a run mid-flight. The developer states the rationale, which is the part worth carrying:
halting gives the manager *"a chance to shift your depth charts and lineups around, sign a free agent
replacement, or work a trade."* Verified identical across OOTP 16, 18, 20, 22, 23, 24 and the current
wiki: **a decade-stable affordance.** The docs themselves warn that disabling all exits means *"you
might miss critical news or opportunities."*

> Refuted 0-3: that auto-play is fundamentally configured by *time horizon* rather than by task; and
> that manual play-by-play users are forced into auto-play for the rest of the schedule. The latter
> would have been within-player oscillation evidence and **does not hold**.

**Draft and scouting presentation (A, MLB The Show — same publisher lineage, adjacent problem).**
Three findings, all directly transferable:

- **Uncertainty is the primary encoding.** Ratings print as **ranges**: `68-86 Potential`,
  `48-66 Overall`, and every attribute as `PRESENT 43-61 → FUTURE 60-78`. **Range width is the
  confidence interval**, and it narrows as `Scouting Progress 20%` fills — with the progress bar
  placed directly above the ranged attributes so the player sees *why* the numbers are vague.
- **The league-relative band legend is printed on the screen itself**:
  `Well Below Avg 0-64 | Below Avg 65-74 | Average 75-79 | Above Avg 80-84 | Well Above Avg 85-99`,
  five bands, with the attribute numbers tinted to match. **This removes the need to compute or know
  the distribution at render time** — see [`07`](07-GAP-REGISTER.md) GAP-02.
- **"Unknown" is a first-class printed value** (Secondary Position, Signing Motivation, Injury Risk),
  never a blank or a zero. Two competing ranks sit side by side — consensus board vs *your* board.

**Delegation trust, answered concretely (A).** On the scouting big board, **each assignment card
states its own yield in its header**: `+2% INTEREST PER WEEK | +40% SCOUTING PER WEEK`,
`+2% INTEREST PER WEEK | +10% SCOUTING PER WEEK`, `UP TO 2 PLAYERS DISCOVERED PER WEEK` — and each
names the individual doing it (`SCOUT: WILLIAM WOMACK`). Three granularities on one screen: delegate
to a named prospect, to a position+region, or to open discovery.

> **This is the best available answer to the brief's axis-3 question, "how is the player made to
> trust the delegate": print the delegate's rate of return on the card where you assign them, and
> name the person rather than saying "auto".**

**Draft room (A).** On-the-clock header with team, pick number and a live countdown; "Up Next"; a
two-column pick list filling in as picks are made; a pinned **draft queue** with a "+" to add — the
queue being the delegation affordance that lets the clock run without you. Ceremony and throughput
coexist in one frame.

---

## 7–10. Franchise Hockey Manager · Motorsport Manager Mobile · NBA 2K MyNBA/MyLeague — NOT OBSERVED

Nothing survived verification for any of these across two research passes. For NBA 2K specifically,
two claims were obtained and **both failed** (1-2): a MyNBA simulation-speed toggle
(Normal/Smarter/Faster) and a pre-season "MyNBA Directives" governor meeting setting goals and
budget. **Neither is established. No claim about these four titles may appear downstream.**

This is a real loss. Motorsport Manager Mobile was the brief's designated precedent for
mobile-native cruise-to-detail transitions, and NBA 2K MyNBA was named as the closest structural
analogue to this product's stated hybrid. Both are unevidenced.

---

## 11. Secondary titles and non-game analogues — NOT OBSERVED

**Secondaries (1 of ≥4).** Only the New Star Games lineage (§5) was obtained. Front Office Football,
Draft Day Sports: Pro Football, Eastside Hockey Manager, New Star Soccer/GP as UI subjects, Wrestling
Empire, and **the FM UI generation arc 2018→present** all returned nothing. The FM arc is the most
painful loss: it was the brief's designated source for what was tried and abandoned, and the FM26
reception evidence in §1 is a single point on a curve whose shape is unknown.

**Non-game analogues (0 of ≥3).** Fantasy football apps (Sleeper, ESPN, NFL, Yahoo), mobile trading
and financial terminals, live broadcast graphics packages, aviation and mission-control readouts, and
PFF-style analytics presentation **all returned nothing across both passes.**

> **This is the most consequential coverage gap in the dossier and it must be stated plainly.**
> Every title with usable evidence is desktop or console except Retro Bowl and the two FM Mobile
> captures. The non-game analogues existed in the brief precisely to supply dense-data-on-a-phone
> evidence. **Therefore: no touch-ergonomics, thumb-reach, one-handed-use or small-screen-density
> conclusion in this dossier rests on comparative research.** Those conclusions rest instead on
> (a) the two FM23 Mobile captures, (b) Apple's HIG, and (c) arithmetic against this product's own
> committed constants. Every such conclusion downstream is marked accordingly.

---

## 12. What would close the gaps

1. **Direct capture.** Every unobserved title is purchasable and runnable. Two hours with Madden NFL
   Mobile, Motorsport Manager Mobile and NBA 2K MyNBA, capturing the hub, the advance loop, the
   delegation configuration surface and the densest routine screen, would convert four NOT-OBSERVED
   entries into Grade A — **and would beat anything the web was ever going to yield**, as this
   research demonstrated at ~12M tokens for zero Grade-A results.
2. **A timed capture of one ceremony**, in any title, closes the ceremony-duration axis, which is
   unobservable from stills and is currently missing for all eight primaries.
3. **A tap-count walkthrough** — hub → deepest routine surface → back — closes the navigation-depth
   axis, also missing for all eight.
4. **Fantasy football apps are free and on the App Store.** Sleeper's draft room and lineup-setting
   flow is the nearest shipped analogue to a dense mobile decision surface anywhere in the brief, and
   it can be observed first-hand in fifteen minutes.
