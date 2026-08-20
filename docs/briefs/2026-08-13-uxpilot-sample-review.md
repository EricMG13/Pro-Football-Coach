# UX Pilot Match Day samples — review, 2026-08-13

Two externally-generated Match Day samples, supplied by the owner for review:

- **Sample A** — `https://uxpilot.ai/s/2af99dc8220ebf67521729377afe3ab1`, rendered at 1440 x 920
- **Sample B** — `https://uxpilot.ai/s/fb07172265ad36194869602aa2224349`, rendered at 375 x 840

Neither is stored in this repository. Sample B contains a real league mark and must not be copied
into it in any form — see §1. Findings were taken by reading each sample's rendered DOM and computed
styles directly, so the colour and effect counts below are measured, not eyeballed.

---

## 1. Blocking — Sample B carries a real league mark

**Sample B prints `NFL` in the panel header, top right of the score rail.** That is a registered mark
of a real league and it is the exact thing the `CLAUDE.md` legal guardrail exists to prevent. Nothing
from Sample B may be carried forward while that string is present, and the sample itself should not
be committed, forwarded to a contractor, or used as a prompt seed.

Sample A is clean — a scan for `NFL`, `NCAA`, `ESPN`, `Super Bowl`, `Madden`, `Fox Sports`,
`College Football Playoff` and `Nike` over its source returned nothing. Its identities
(Iron Wolves, Vale Steel, Marcus Stein, Ryker, Cole, Harper) are all fictional and original.

This is worth naming as a pattern rather than a one-off: **a generative design tool reaches for a
real league mark as soon as the prompt says "football", because that is what its training data looks
like.** The Stitch run produced the same class of error in a different place — it assumed a networked
product. Every externally-generated sample needs a real-mark scan before anyone looks at it properly.

---

## 2. Blocking — neither sample is in the shipping frame

| | Frame | Aspect | Verdict |
|---|---|---|---|
| Target (`04` §7) | 852 x 393 | 2.17 | — |
| Sample A | 1440 x 920 | 1.57 | Desktop dashboard. **2.3x the vertical room we have** |
| Sample B | 375 x 840 | 0.45 | **Portrait.** Not a supported orientation |

This is not a detail to fix later; it invalidates most of both compositions.

**Sample A** stacks the field, then a key-moments row, then a player-spotlight card and a game-stats
panel beneath it. In 393 pt of height the field alone is the dominant object — everything below it
has nowhere to go. The sample looks good precisely because it is not solving our problem.

**Sample B** is worse in kind rather than degree. It puts the field in a portrait column, so only
about 35 yards are visible and five players are on screen. `04` §5.2 chose landscape specifically so
the whole 120-yard field sits in frame with no camera pan. Sample B is a demonstration of the failure
that decision was taken to avoid. It also pushes its controls below the fold, requiring a vertical
page scroll that `04` §4 does not permit on a composition.

---

## 3. Blocking — token and surface violations, measured

Both samples use the **stock Tailwind palette**, not our tokens:

| Role as drawn | Sample value | Canon value |
|---|---|---|
| Home team / negative | `#EF4444` (red-500) | no such token; team colour is generated, `state.negative` is `#F07886` |
| Away team / info | `#3B82F6` (blue-500) | no such token; `state.info` is `#72ADEC` |
| Accent / warning | `#F59E0B` (amber-500) | `state.warning` is `#F0C56C` |
| Turf | `#1A5E2E` (A) | `field.turf` is `#163E2A` |
| Ground | `#0A0E16` (B) | `world.page` is `#080A14` |

Prohibited surface treatment, counted in source:

| | Sample A | Sample B |
|---|---:|---:|
| Gradients | 5 | present on turf |
| Blur / backdrop-filter | 4 | present |
| Box/text shadow | 2 | present |
| Animations | 4 | marquee ticker |
| Emoji in UI copy | 5 | 4 |

`04` §6.1 is unambiguous: no gradients, glow, glass, decorative shadow; surfaces are matte and
opaque. §6.3 prohibits emoji outright. Both samples also float rounded, shadowed DESK-register cards
over the field, where BROADCAST requires radius 0 — the two registers blur, which is the specific
thing the register split exists to prevent.

One further contrast risk, unmeasured but visible: Sample B colours the **score numerals themselves**
in team colour. Score legibility then depends on generated colour clearing contrast against the rail,
which no generator can guarantee. Score stays in `content.primary` or `broadcast.ink`; team colour
goes in the block behind it, carrying its mandatory hairline.

---

## 4. Worth taking — seven ideas that survive

The samples are wrong in frame and wrong in values, and still contain more usable Match Day thinking
than the Stitch broadcast board did. Ranked:

### 4.1 The momentum bar as a distinct object — Sample A **[recommend]**

Under the field, a single shared track: `IRON 61% ——— 39% VALE`. This is not the scoreboard and not a
stat; it is *who is currently winning the game state*, drawn as one opposed bar. Registry 15
`OpposedBar` exists but nothing in canon says the match view should carry a momentum reading. It is
one line, it is engine-backed if the model owns a momentum term, and it answers the question a coach
actually has while watching. If the engine does not own that term, this is the honest-degraded case
and it should not be drawn — which makes it a good test of `04` §4.4.

### 4.2 The drive strip — Sample B **[recommend]**

`IW ——▮——— ENZ` with `+12 yds · 4 plays` beneath. Compact drive state: where this possession started,
how far it has come, what it has cost. Four facts in about 30 pt of height. Nothing in the current
Match Day composition carries drive context at all, and it is the unit a coach thinks in.

### 4.3 Key moments as clock-stamped marks — Sample A

`Q2 4:12 · Q2 1:55 · Q3 11:22` as discrete marks in a row beneath the field, each a jump target.
Registry 22 already anticipates this; the sample shows it costs one 20 pt row and reads instantly.

### 4.4 The causal lower third, well executed — both

"Holding on Vale Steel #71. Ten yards, automatic first down." and "Stein catches a 24-yd strike from
Ryker in the back of the end zone." Both name the actor *and* the cause, which is the standard
registry 21 sets. This is the one place both samples clear our bar without amendment, and they are
worth keeping as copy exemplars for whoever writes the commentary strings.

### 4.5 The five-control decision cluster — Sample B

`QUICK CALL · SUB · TIMEOUT · PLAY · BOOST` as one row. Sample B is the only one of the two that
remembers the player is a coach. Note that it lands on **five** primary controls, which is what
`04` requires — arrived at independently, which is mild evidence the number is right.
`BOOST` is a video-game verb and should not survive; the other four are real decisions.

### 4.6 The split rail chassis — Sample B

A persistent left rail carrying score, clock, down and distance, drive, and timeouts, with the field
filling the remainder. In portrait this is what starves the field. **Rotated into 852 x 393 it is
promising**: a narrow leading rail plus a wide field is closer to our frame than Sample A's stacked
dashboard, and it keeps the score furniture off the field surface entirely.

### 4.7 The spotlight card as four stat tiles — Sample A

`6 CATCHES · 94 YDS · 2 TDS · 9.2 RATING` with a leading accent bar. Cheap, scannable, and it gives
the standout performer a home without a second dominant object.

---

## 5. The finding that matters most

**Sample A has no coach controls at all.** Not a reduced set — none. It is a spectator broadcast
view: watch the field, read the stats, admire the momentum bar.

That is the project's central design problem walking in the front door. `docs/02-GAME-DESIGN.md`
exists because "the match is watched in a 2D view and shaped by preparation and decisions" is hard,
and the tempting failure is to build the watching and forget the shaping. A generative tool asked for
a "football match screen" will produce a broadcast, because broadcasts are what it has seen. Both
samples drifted that way; Sample B only partly resisted.

Worth holding onto as a review question for any future Match Day work: **what does the coach do on
this screen, and where is it?** If the answer takes more than one sentence, the composition has
drifted into spectating.

---

## 6. Recommendation

Take §4.1 and §4.2 forward as `04` amendment candidates — the momentum bar and the drive strip are
genuinely new objects and both are cheap in the density budget. Fold §4.3, §4.4 and §4.7 into the
existing registry entries as executions rather than new components. Test §4.6 by rebuilding the split
rail at true 852 x 393 in the Figma pool file and seeing whether the field still fits beside it.

Discard everything else: the frames, the palette, the surface treatment, the emoji, `BOOST`, and all
of Sample B's identity layer.

Both samples remain external references only. Neither is design authority, and where a sample and
`04` disagree, `04` wins.
