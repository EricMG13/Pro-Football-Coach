# 10 — Proposed amendment to `docs/04-UX-AND-DESIGN-SYSTEM.md`

**Status: DRAFT, for owner approval. Not canon until merged into `04` itself.**
Dated 2026-08-22. Follows `04`'s existing amendment convention (`6.1a`, `6.1b`, `6.1c`, `6.7`).

---

## Why this exists

The "Two Registers" design system was published as an artifact and never written into canon.
`docs/04` therefore has no knowledge of it, and a generated surface register built from canon —
correctly, under `CLAUDE.md`'s doc-first rule — reproduced the shipped Floodlit language instead,
including four palette collisions and a three-band heat scale this work had specifically repaired.

That is the right outcome from the wrong inputs. **The fix is to give the findings standing in canon,
not to override canon from an artifact.**

## What this amendment does *not* do

It does **not** introduce a competing register taxonomy. `04` §2 already defines **nine registers** —
Coach's Office, Personnel Room, Acquisition Room, Front Office, League & Media, Career & Legacy, Film
Room, Broadcast, Ceremony — and they are sound. The artifact's "Broadcast / Desk / Dossier" is a
*different axis* and is presented below as such.

It also does not replace §4.5's density budget, which already says most of what is needed. §4.5
already requires "24–28 pt table tracks with six to nine fact columns beside identity, further facts
arriving as column sets rather than horizontal scroll" — consistent with the measured eight — and
already forbids "a band without a recorded observation" as fabrication under §4.4. This amendment
supplies the missing *measured numbers* and the missing *visual form* for rules canon already holds.

---

## A. New §2.1 — The presentation lean

*Insert immediately after §2's register table, before "No screen may describe itself as 'Film Room'…".*

> ### 2.1 The presentation lean (2026-08-22 amendment)
>
> §2's nine registers say what a screen **is about**. They do not say how much presentation it may
> spend. That is a second, orthogonal axis with three positions, and every surface carries one of each.
>
> The axis is **whether the player is being told something or working something out.** Frequency does
> not set it; frequency only decides how much spectacle is affordable once the side is picked. This
> was tested against the §8 inventory: a frequency-first rule classifies Match Day as a working
> surface because it is seen fifteen times a season, which is plainly wrong.
>
> | Lean | The player is | Ground | Mark | Largest numeral | Data points |
> |---|---|---|---|---|---|
> | **Broadcast** | being told | club or opponent colour, flooded | 200–390 pt | 40–72 pt | ≤ 12 |
> | **Desk** | working | `world.page`, club colour confined to the identity band | 19 pt | 11–14 pt | ≤ 72 |
> | **Dossier** | meeting a subject, then studying it | club colour above the seam, `world.page` below | 180–220 pt above | 40 pt above, 11.5 below | ≤ 8 above, ≤ 40 below |
>
> **Default lean per §2 register:** Broadcast and Ceremony take the Broadcast lean. Coach's Office,
> Acquisition Room, Front Office, League & Media and Career & Legacy take the Desk lean. Personnel
> Room takes Desk for its lists and Dossier for its dossiers — the register's own row already
> distinguishes "dense comparison where earned" from "identity-led detail". Film Room takes Desk.
>
> **Match Day is the only surface carrying two leans at once** — a Broadcast ground with a Desk plate
> on it. This is not an exception to be tolerated but the product's central claim, and §9 governs it.
>
> **Dossier is marked by exactly one visible seam**, a 2 pt `action.primary` rule, at the point the
> lean changes. A Dossier surface with no seam, or with two, is a finding.

---

## B. Amend §6.1a — gold is the committing action, and nothing else

*The palette in §6.1a carries four role collisions, measured in HSL from the shipped
`DesignTokens.swift`:*

| Colliding roles | Values | Separation |
|---|---|---|
| `actionPrimary` / `stateWarning` | `#FFC53D` / `#FFB03A` | **6.1°** hue, identical saturation, 0.6% luminance |
| `stateNegative` / `actionDestructive` | `#FF3B54` / `#FF3B54` | **identical** |
| `stateInfo` / `proIdentity` | `#6FA8DC` / `#6FA8DC` | **identical** |
| `stateLive` / `statePositive` | `#37E08A` / `#4FD08C` | **1.1°** hue |

The first is the serious one: a caution and a commit are the same colour under a thumb at 11 pt.

> **§6.1a amendment (2026-08-22).** Gold — `action.primary` `#FFC53D` — marks the committing action
> and the live first-down line, and carries no other meaning. It is never a rating, never a state,
> never a position chip, never decoration. **A surface spends gold at most once**, twice only on
> Match Day where the second is the first-down line.
>
> Consequently `state.warning` leaves the yellow-orange band. Its replacement must sit at least 24°
> from gold's hue of 42.1° and clear 4.5:1 on `world.page`; `#C9704A` satisfies both at 18.0° and
> 5.57:1.
>
> The three identical or near-identical pairs stay legal as *aliases* — `action.destructive` may
> alias `state.negative` — but must be declared as aliases in the token layer rather than repeated as
> literals, so a future divergence is a deliberate edit and not an accident.

---

## C. Amend §6.4 — the heat scale becomes five bands, centred on neutral

*Replaces the third bullet under §6.4 item 4 (currently at line 674): "Use red below 70, amber from
70–84 and green from 85 upward as the default visual heat scale".*

The three-band scale paints 70–84 amber, so an average starter reads as a caution. The reference
implementation for scouted ratings runs red → orange → **neutral** → light green → green, with the
warm hue *below* the median, and prints the band table on the surface that uses it.

> **§6.4 amendment (2026-08-22).** The default visual heat scale over the 40–99 rating range is five
> bands, diverging around a neutral centre:
>
> | Band | Range | Role |
> |---|---|---|
> | Well below | 40–59 | `state.negative` |
> | Below | 60–69 | the amended `state.warning` |
> | **Average** | **70–79** | **`content.secondary` — neutral, never amber** |
> | Above | 80–84 | `state.positive`, lightened |
> | Well above | 85–99 | `state.positive` |
>
> Every band clears 4.5:1 on `world.page` and sits at least 24° from gold. The printed number and
> spoken band are retained unchanged — colour remains a second reading, per the existing rule.
>
> **Where a surface bands a rating it prints the band table on that surface.** This discharges the
> league-relative question without computing a live percentile, and it degrades correctly in a save
> with no league history.

---

## D. Amend §6.4 — ranged ratings are the form of an unearned number

§4.5 already forbids "a band without a recorded observation" as fabrication under §4.4. What canon
does not yet supply is what to draw *instead*. Today an unscouted prospect's ability renders as a
point value, which is precisely the fabrication §4.4 prohibits.

> **§6.4 amendment (2026-08-22).** A rating the simulation has not earned is drawn as a **range**,
> not a point. Range width is the confidence: it narrows as observation accumulates, and a rating
> observed enough to be certain renders as a collapsed range (`83–83`), never as a different kind of
> number. An attribute with no observation at all prints the word — `Unseen` — never a blank, a dash
> or a zero.
>
> Where a range is drawn, the observation that produced it is drawn with it, so the player can see
> *why* the number is vague.
>
> This is a view contract with an engine dependency: it requires a scouting-confidence model that
> does not exist (`07` GAP-06). Until that lands, surfaces render point values and **declare the gap**
> rather than implying a precision the engine cannot support.

---

## E. Amend §4.5 — the measured density budget

§4.5's currencies and caps stand. What follows are the measured numbers behind them, which canon
currently states only as ratios.

> **§4.5 amendment (2026-08-22).** At the install floor the content box is 709 × 319 pt, but the
> **usable scroll viewport measures 291 pt**, and **241 pt** once a surface reserves a committing bar
> outside the scroll. Budgets follow from that, not from the box:
>
> | Tier | Row | Viewport | Rows | Columns | Cells |
> |---|---|---|---|---|---|
> | Dense | 32 pt | 291 | 9 | 8 | **72** |
> | Working | 44 pt | 291 | 6 | 8 | **48** |
> | Committing | 44 pt | 241 | 5 | 8 | **40** |
> | Broadcast | — | 390 | — | — | **12** |
>
> **Interactivity is bought with rows.** A row that responds to touch takes the 44 pt control floor,
> so nine readout rows become six; reserving a commit bar takes six to five. A surface that carries a
> committing control therefore has 40 cells, not 72, and must be composed against that number.
>
> A surface exceeding its tier's cell count is over budget by construction, in the same way §4.5's
> existing clauses define over-budget. The count is of *declared data*, not of rendered elements:
> chrome, labels and prose are not cells.

---

## F. New §6.1d — the identity band

The nav furniture in §6.1c places a 19 pt mark in the identity header beside a separate icon rail.
Club identity is consequently near-absent from every management surface, which is what makes a
football game read as a database.

> ### 6.1d The identity band (2026-08-22 amendment)
>
> On every management surface the club's colour, mark, name and record are carried in a single band
> that **encloses the whole of the navigation row** — mark, club name, record and rank, the family
> name, the sibling tabs and the context slot all sit inside it. It is not a pill beside the
> navigation; the navigation is inside it.
>
> The band is 34 pt tall, runs a gradient from the club's primary to `world.page`, and carries a
> hairline of the club's secondary. Its mark is 19 pt — the Desk lean's size — because the band is
> the *only* place a Desk surface spends club colour. The band is the sanctioned seventh placement
> for a team mark under §5.2, alongside the standings row as the eighth.

---

## Consequences and cost

| Change | Foreclosed | Obligated |
|---|---|---|
| A | Gold as decoration, rating or state | `state.warning` re-picked; every position chip re-coloured |
| B–C | The three-band scale | Every `Heat` consumer re-reads; `CoachWorldTokens.Heat` gains two bands |
| D | Point ratings for unearned numbers | GAP-06 becomes a release dependency for recruiting surfaces |
| E | Composing an action surface against 72 | A density test enumerating surfaces by construction |
| F | The mark absent from management surfaces | `6.1c` chrome re-drawn; `FloodlitChrome` header replaced |

**Reversal cost** is low for A, C, E and F — token and layout edits. It is medium for D, which has an
engine dependency, and B, which may have pinned colour expectations in tests.

**Sequencing:** A, C and F can land immediately. D should land as a *declared gap* now and a visual
form when GAP-06 does. E should land with its test, or it is a claim rather than a rule.

Once merged into `04`, regenerating the surface register will reproduce these decisions without
further instruction — which is the whole point of routing them through canon rather than an artifact.
