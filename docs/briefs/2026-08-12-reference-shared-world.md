# The reference library's shared world

**Destination:** `docs/briefs/2026-08-12-reference-shared-world.md`. **Working input, not canon** —
`docs/04-UX-AND-DESIGN-SYSTEM.md` §6.5 governs the sheets; this file fixes the sample content they
draw so that they depict one save rather than five.

Closes findings F-06 and F-10 and the "no shared world" item in §5 of
`docs/reviews/2026-08-12-personnel-proof-review.md`. The review's cost statement is the reason this
exists: `04b` dimension 4 is world identity and continuity, and the reference library — the one
artefact that could prove a player, a team and a week read coherently across the registry — was
proving the opposite. `04` §10 already requires the three interactive proofs to depict one
continuous fictional save; the sheets were not held to that and now are.

All identities below are **synthetic placeholders pending generator output**. They are deliberately
non-naturalistic so no reader mistakes them for real programmes or people, and every sheet keeps
the *pending generator output* label. The `CLAUDE.md` legal guardrail governs: nothing here is or
resembles a real school, team, conference, city, stadium, player or coach.

## The moment every sheet depicts

**Week 9, preparation day, Example State, record 6-2, next opponent Example Coastal (away).**
One moment, so a delta mark on the dossier, a form line on the roster row, a verdict on the readout
and a lower third in the match all describe the same world at the same time.

## The cast

| Token | Identity | Facts fixed across every sheet |
|---|---|---|
| P14 | **Player Fourteen** — QB, No. 14, senior, age 22 | OVR 84, fit 82, form last five 78/81/74/86/83, condition good, contract expires after next season |
| P72 | **Player Seventy-Two** — LT, No. 72, junior, age 20 | OVR 88, fit 85, awareness 74 up 2 since Week 6 (development focus), no status chips |
| P07 | **Player Seven** — WR, No. 7, sophomore, age 19 | OVR 79, fit 75, unscouted at the market level so worth renders as a band |
| P51 | **Player Fifty-One** — LB, No. 51, senior, age 22 | OVR 81, fit 79, suspended for this game (`shield.slash`) — **his ratings remain visible**, per F-08 |
| P11 | **Player Eleven** — TE, No. 11, junior, age 20 | OVR 76, fit 78 — supporting cast, used where a third or fourth row is needed |
| P26 | **Player Twenty-Six** — CB, No. 26, sophomore, age 19 | OVR 77, fit 74 |
| P09 | **Player Nine** — RB, No. 9, freshman, age 18 | OVR 72, fit 80, redshirt candidate |
| P54 | **Player Fifty-Four** — DE, No. 54, junior, age 20 | OVR 80, fit 82 — Example Coastal's edge rusher, so the match sheet's sack protagonist is an actor actually drawn on the field |
| S1 | **Coach Sample** — head coach, the player | — |
| S2 | **Coordinator Sample** — defensive coordinator | Voices call-ins and delegated receipts |
| S3 | **Analyst Sample** — analytics staff | Voices verdicts once G-02 lands |

The first four players carry the cases the registry needs to prove (a dossier subject, a delta
mark, per-fact fog, an unavailable-but-legible row). The last three exist so a sheet needing a
fourth and fifth row does not invent one — added 2026-08-12 under rule 4 below, after
`failure-v3.dc.html` needed exactly that.

## The teams

| Token | Identity | Colour pair drawn against |
|---|---|---|
| T-home | **Example State** | dark-primary trio pair |
| T-away | **Example Coastal** | light-primary trio pair |
| T-third | **Example Union** | low-chroma trio pair |

Team colours stay the three synthetic trio pairs in `04` §6.1, each carrying the mandatory hairline
boundary. A sheet needing a fourth team reuses one of these three rather than inventing.

## The figures

One set of numbers, so no figure is reassigned between cards (F-10).

| Quantity | Value | Where it appears |
|---|---|---|
| Rushing yards allowed, last four | 88, 121, 94, 103 | Readout verdict evidence |
| Passing yards, Example State | 213 | Opposed bar, home end, every instance |
| Passing yards, Example Coastal | 267 | Opposed bar, away end, every instance |
| Committed cap | $259,997,200 against $255,400,000 | Meter, over-capacity state |
| Overage | $4,597,200 — 101.8% | Meter, stated as text |
| Roster count | 63 of 70 | Table capacity header |
| Score at the depicted moment | Example Coastal 13, Example State 10, Q3 07:26, 1st and 10 | Score bug, lower third |
| Rushing yards this matchup | Example State 184, Example Coastal 92 | Opposed bar |
| Takeaways, Week 8 (the prior fixture) | Example Union 3, Example State 1 | Opposed bar, the low-chroma pair's instance |
| Cap projection, next season | $9,000,000 to $15,000,000 over | Meter, banded because a projection is an estimate |
| Cap projection, two seasons out | $8,000,000 under to $2,000,000 over | Meter; crosses the cap, so it carries no compliance state |

**Example Union's role.** Week 8 was Example State's prior fixture, away at Example Union. That is
what gives the low-chroma trio pair a real football instance to be drawn against rather than a
decorative third team.

## The season so far

A form line needs five distinct opponents and the cast held three, which forced one sheet to code
its history `OPP-A`–`OPP-E`. The schedule below fixes it. Weeks 1–3 are 2-1 and are not drawn by
any sheet; Weeks 4–8 are the last five and are what `FormLine` renders.

| Week | Fixture | Result | Player Fourteen's game rating |
|---|---|---|---:|
| 4 | vs Example Ridge | W | 78 |
| 5 | at Example Harbor | L | 81 |
| 6 | vs Example Valley | W | 74 |
| 7 | at Example Summit | W | 86 |
| 8 | at Example Union | W | 83 |
| 9 | at Example Coastal | the depicted moment | — |

Record 6-2. The four programmes added here exist only to give the history distinct opponents; they
carry no colour pair and no identity beyond a name, and like everything else in this file they are
synthetic and pending generator output.

## Player Fourteen's numbers

Fixed so the dossier, the roster row and the readout agree rather than each inventing.

| Fact | Value |
|---|---|
| Overall / fit | 84 / 82 |
| Awareness | 79 |
| Accuracy | 86 |
| Arm strength | 81 |
| Decision-making | 77 |
| Mobility | 68 |
| Composure | 83 |
| Contract | expires after next season; $2,400,000 remaining |
| Market worth | banded $3,000,000 to $4,500,000 — a market estimate, so never a point figure |

Attribute values are 40–99 integers per `CLAUDE.md`. Money is integer dollars. A sheet needing an
attribute this table does not hold adds it here rather than inventing locally.

**Fit prints as a word, never as a second number.** A roster row already carries one 40–99 rating,
and a second numeric scale beside it is the doubled-scale anti-lesson (A7 in the pass-2 findings).
The bands, so every sheet says the same word for the same value: **Poor** below 60, **Fair** 60–69,
**Good** 70–84, **Strong** 85 and above. The number stays in the read model and in the accessible
sentence; the surface shows the word.

Any sheet needing a figure this table does not hold adds it here first. A number appearing only in
a sheet is set dressing, which is what F-10 caught.

## Rules for the sheets

1. A name means one person. Player Fourteen is the quarterback everywhere, or he is not used.
2. A figure means one quantity with one owner. Reusing 213 for a different team is a defect.
3. Consequence is carried across sheets: the suspended linebacker is suspended on the roster table,
   in the week plan's availability line and in the depth chart's replacement prompt.
4. Where a sheet needs an identity the cast does not hold, it extends this file rather than
   inventing locally.
