# Reference-frame decisions

Where this generator departs from a number written down elsewhere, and why.

**Rewritten 2026-08-22 after an adversarial review against the source.** The first version
of this file recorded seven "open questions". Five of them were not open — they were
answered in the source artifact's specification table, which the first build had not read.
They are kept below, marked as errors, because a decision register that quietly deletes its
wrong entries teaches nothing.

The source is `claude.ai/code/artifact/34b9992d-8d69-40f0-a2f3-b8e1c15b3311` ("Two
Registers"). Where it states a value, it wins.

## Resolved — and previously recorded wrong

### 1. The viewport is 291 pt, not 319. ~~Open.~~ **The first version had this backwards.**

The source: *"Geometry gives a 709 × 319 pt content box, but the running app measures the
usable scroll viewport at 291 pt, and 241 once a commit bar is reserved outside the
scroll."*

Those are two quantities, not two claims about one. `frame.css` and
`docs/ux/00-GATE-ZERO.md:164` both say 319 because 319 *is* the geometric box; 291 is what
scrolls inside it. The first build read the pair as a contradiction, kept the geometric
number, and wrote the disagreement up as settled. Measured against 291/241, **24 of 59
frames overflowed the plate they are actually drawn into** — including the height check
added specifically to catch clipping, which was calibrated to the wrong plate and passed
them all.

`tokens.CONTENT_BOX_H` is the geometry; `tokens.VIEWPORT_H` / `VIEWPORT_H_COMMITTING` are
the measurement; `SCROLL_CHROME` is the 28 pt difference, asserted so a token change that
moves the box without a fresh measurement is visible.

### 2. Row budgets are 9 / 6 / 5. ~~Derived.~~ **Derivation from the wrong box.**

The source: *"Nine readout rows at 32 pt, six tappable at 44, five once the bar is
reserved. Eight columns. That is where 72 comes from, and why a committing surface gets
40."* The first build derived (9, 7) and (8, 6) from the 319 pt box and defended the
derivation as drift-proof. It was drift-proof against the wrong number.

### 3. Cell budgets. Broadcast ≤ 12 · Desk ≤ 72 · Dossier ≤ 8 above the seam, ≤ 40 below.

The dossier figure is a **split**, not one number. The first build used a flat 48, which
let a dossier print 48 cells above the seam — in the register whose whole point is that the
head is a broadcast moment and the body is a working table.

The `docs/ux/06-TOKENS-AND-DENSITY.md` DENSE-72 / COMFORTABLE-56 pair remains a genuine
disagreement with the source's four-register table. The source is the later document and is
followed; the dossier is flagged for the owner.

### 4. A Dossier head is 180–220 px. ~~"Unachievable."~~ **The mark is a watermark.**

The first build argued 180 could not fit and drew 96 — reasoning from the 275 pt plate that
§1 shows was wrong, and then widening `MARK_HEIGHT_RANGE` to (96, 220) so its own output
would pass. Loosening a bound to fit the artefact is the coverage-boundary failure
`CLAUDE.md` names.

The mark is a **watermark behind the head**, not an inline image beside it, which is what
makes 390 px fit inside a 291 pt plate at all. The source's own drawn dossier: *"opponent
colour flooding a 132 pt head, a 212 px watermark, the name at 38 and the ceiling at 40
points."*

### 5. The twelve missing surfaces are named by the source.

M1 Responsibilities · M2 Championship Result · M3 Season Expectations · M4 Season Review ·
M5 While You Were Away · M6 Compare · M7 Save & Continuity · M8 Appearance, plus four
overlay layers that carry no screen ID at all: O1 First run · O2 Teaching · O3 Failure ·
O4 System state.

The first build invented nine of the twelve and gave each one fabricated `file:line`
evidence in the same format as the real entries. `source_inventory.SOURCE_MISSING` now
holds the list and check 1 counts against it.

## Standing

### 6. Row heights are measured, not derived

`primitives._ROW` holds four measured numbers rather than padding-plus-line-height
arithmetic. Deriving them under-read by about a fifth — an inline run inside a flex row
occupies its line box, not its line-height. Captured 2026-08-22 in the Browser pane at
1280 × 720. Re-measure with `build.py --only <id>` if `chrome.css` changes a padding or a
face. **Nothing enforces the re-measurement**; that is a known weakness.

### 7. Aliases are not drawn

59 = 74 registry numbers less the 15 that redirect. Check 2 requires every canonical Swift
case to have exactly one entry and no alias to have any.

### 8. Status is Swift build state; Gap is design state

`Coach World.dc.html` routes all 62 registry surfaces, so almost everything is *drawn*
while far less is *built*. `Status` answers "does this exist in `Sources/`"; `Gap` answers
"what is missing from it". The source classifies by line count (Built ≥180, Thin 100–179,
Stub under 100); that reading is recorded in `source_inventory` for comparison and is not
used, because line count is not build state.

### 9. Only one of the two legal tests is ported

`legal.py` ports the institution-kind blocklist (`Blocklist.blocks`) to Python, because
this generator publishes generated identities to a hosted page the Swift suite never sees.
**The ΔE trade-dress check is not ported** — it needs the real programme colour table and a
colour space, and the Swift suite owns it. That is a stated limit, not coverage.

### 10. Density is thinner than the source's, and the row primitive is why

Every frame now fits its plate, but several sit well under budget: Coaching HQ prints 4
cells where the source's This Week carries roughly eight items in the same 241 pt.

The cause is `Rows`, which measures **64 pt tappable / 52 pt readout** — a lead line, a
meta line and a values column, plus `--pad-row`. The source's list items are compact lines
closer to the 32/44 pt tracks the specification names. So the budget is now right and the
primitive is fat, which spends the budget on chrome instead of data.

Fixing it means retuning `.fl-row` and re-measuring `primitives._ROW`, and is the next
thing worth doing to this generator. Recorded rather than hidden: a frame that fits by
being empty is not the same as a frame that fits.

---

## Canon amendments, 2026-08-22

`docs/04` gained six amendments. All are applied; three of them settle entries above.

### 11. §4.5a settles §1 and §2 — they were already right, now they are canon

The measured 291 / 241 viewport and the 9 / 6 / 5 row budgets are no longer inferred from
the design source: `04` §4.5a states them. §1 and §2 above stand as written.

What did change is that the cell budget keys off the **density tier**, not the lean. Dense
72 · Working 48 · Committing 40 · Broadcast 12, where the tier is set by row height and by
whether a commit bar is reserved. The previous build gave every Dossier 48 whatever it
drew.

### 12. §2.1 renames the axis this generator was already modelling

What this module called `Register` is the **presentation lean** — a second axis orthogonal
to canon's nine registers. Renamed. **The nine-register assignment is not modelled**: it is
not derivable from the amendment, and inventing it is what produced nine fabricated
surfaces last time.

### 13. §6.1d replaces the header and the icon rail with one identity band

34 pt, gradient from club primary to `world.page`, hairline of club secondary, mark 19 pt,
enclosing the whole navigation row. The icon rail is gone. The plate keeps its 115 pt
leading so the content box stays the canon 709 — the rail's space is simply vacated.

### 14. §6.4's five bands are computed, not asserted

`check_heat_bands` resolves each band and computes its contrast on page / raised / panel and
its hue separation from gold. Independently reproduces canon's table to two decimals:
5.67 / 4.64 / 5.26 · 5.57 / 4.56 / 5.16 · 10.00 / 8.20 / 9.28 · 10.32 / 8.46 / 9.57 ·
10.13 / 8.30 / 9.39, at 49.7 / 24.1 / 170.4 / 102.4 / 106.3 degrees.

### 15. A banded Dossier cannot also commit at the install floor

§2.1 gives the Dossier head 180–220, §6.4 requires the band table beside a banded figure,
and §4.5a leaves 241 pt once a commit bar is reserved. The three do not fit. Player Profile
and Prospect Profile are drawn **without the bar**, routing to their committing surface, and
each declares the conflict as a blocking `RULE` gap. **This is an owner question.**

### 16. Ranged ratings are declared, not faked

§6.4 requires an unearned rating drawn as a range with `Unseen` where nothing is observed.
The scouting-confidence model does not exist (`07` GAP-06), so surfaces render point values
and declare the gap — four of them do.

### 17. Canon now leads `DesignTokens.swift`

`--fl-warning` is `#C9704A` per §6.1a(ii); `DesignTokens.swift` still ships the retired hex,
and its `Heat` enum still has three bands. The vendored token sheet no longer mirrors the
Swift, and says so at the top. **The app carries both gaps.**

### 18. Two defects this pass introduced and caught

- A blanket `Register` → `Lean` rename rewrote the page **title**. Rule: the title is stable
  across redeploys because the artifact is found by it; it is now commented as such.
- `.fl-band` was claimed by both the identity band and the heat legend's swatches, so the
  swatches inherited the band's absolute positioning and smeared across every frame with a
  legend. Rule 19 makes a second owner for one class a build failure.
- The standalone file carries no charset, so a plain file server mojibaked every multi-byte
  character while the artifact host rendered it correctly. Rule 20 requires ASCII output.

### 19. The arc family, and why three defects and the density problem were one problem

A review asked whether these read as a game or as software. Forty-one of fifty-nine
contained nothing but tables, rows, panels and stacks, and **none** of the design system's
ten graphical components were rendered. Every proportion in a sport made of proportions --
snap share, allocation, cap, third-down splits -- was printed as text in a column.

Six arcs added: `ShareBar` 4 pt, `ValueRing` 26, `AttributeDial` 212, plus `Meter`,
`OpposedBar` and `FormLine`. `ArcGauge` (64) is not built -- it is `ValueRing` at another
diameter and no surface needs it yet.

`geometry.css` bounds them: *"An arc is permitted ONLY where the datum is a proportion. An
arc that encodes a rank or a count is a lie about the shape of the number."* Enforced by
construction -- every one takes a proportion of a stated whole and raises outside 0-1, so a
rank cannot be drawn as an arc even by mistake. Rule 21 covers the back door: an arc with
no printed figure beside it, which would make the shape the only reading.

**`AttributeDial`'s shipped doc is stale.** It says "red below 70, amber 70-84, green 85+"
-- the three-band scale `04` 6.4 retired. The dial uses the five bands, so a dial and a
table cell never disagree about the same number.

Adding them fixed the density defect rather than decorating around it: Player Profile
carried **two** attribute rows because a table costs 116 pt for four. A dial plus four
share bars carries five attributes in 92 pt, inside the same plate.

### 20. The column track was measured in the wrong font

`Col.chars` emitted a `ch` track. `ch` resolves against the CONTAINER's font -- Archivo
Narrow, 5.472 px per digit at 12 px -- while a figure cell renders in IBM Plex Mono at
7.2 px. So `12ch` bought 66 px for `$24,000,000`, which needs 79, and Contract
Negotiation's money columns collided.

Tracks are now computed in px from the advance of the face the column actually renders in,
`figure` selecting between the two measured constants, and check 11 uses the same
expression -- so the check and the render cannot disagree about a width again.

### 21. Prospect Profile contradicted its own gap

Its head printed `68-89` while the same surface declared that ranges are impossible until
the scouting-confidence model lands. Now a point value, consistent with the declaration.

### 22. What the Madden reference set could and could not be taken from

Nine reference captures were supplied. The through-line is layered ground, team mark at
scale, and data in cards -- and comparison two-sided around a centre label.

**Taken:** the field at real geometry, the scorebug strip, the two-sided stat comparison,
and the player card's composition -- number and position small, given name medium, surname
large, vitals tracked, overall as a badge in its band, attributes as figure-plus-bar.

**Refused, with reasons:**

- **The headshot.** Every reference card leads with a face. This product may never draw
  one; `CoachWorldBlankPhotoPlate` exists to be that empty state. The crest carries the
  identity instead.
- **The full-bleed logo watermark behind a management screen.** `04` section 5's restraint
  rules give a management screen exactly one full-bleed team field, the world strip's, and
  make every other use mark-scale. A watermark behind a Desk surface is the wash section
  4.4 rejects. This is the single change that would most cheaply make the Desk surfaces
  look like a game, and canon refuses it -- an owner question, not a drawing choice.
- **Flooding a card header on a Desk surface.** Same clause. `PlayerCard(flooded=True)` is
  legal only above a Dossier seam or on a Broadcast frame; rule 22 enforces it. On Desk the
  card takes the club's colour as a boundary.

### 23. Entities in registry data, twice

`&middot;` was written into a surface's copy in batch 1 and again in batch 3, and both
times `escape()` turned it into `&amp;middot;` and printed it. `page._ascii` converts the
real character at the emitter, so the data should always carry the character. Rule 23 makes
the third occurrence a build failure.

### 24. Batch 4: the three shapes the copy was already asking for

The surfaces left after batch 3 were not uniformly table-shaped. Three phrases in the copy
were the tell, and each names a shape:

- **"X of Y"** is a capacity, and a capacity wants a track. Class places 2 of 22, contacts
  used 6 of 12, weeks without a bye 6 of 8, and the active roster at **56 of 53** -- the one
  case the over-capacity state exists for. The bar overruns its track rather than clamping,
  because a roster sheet that cannot show itself breached is not a roster sheet.
- **A person** is a card, not a row. Staff Room and Shortlist follow Compare.
- **A run of results** is a sequence. Schedule splits into played, as a form line, and
  to come, as a table -- two different questions that were sharing one table.

Stakeholders was five moods in a table; approval is a proportion, so it is five bars.

`PlayerCard` now takes a person with no squad number, which is what a coordinator is.

Still only tables and rows: **28 of 59**, from 41 before batch 1. Shapes in use: ShareBar
18, Hero 14, PlayerCard 8, Meter 5, FormLine 3, StatCompare 3, Chips 3, ScoreBug 1,
Field 1, AttributeDial 1.

The 28 that remain are mostly right as tables -- Inbox, Standings, Rankings, Bracket,
Statistics, Record Book, Coaching Tree. The ones still worth a shape are Coaching HQ,
Game Plan, Development Plan and Recruiting Board, all of which want a card or a track that
the current copy does not yet name.
