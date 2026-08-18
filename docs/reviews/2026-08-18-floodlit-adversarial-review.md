# Adversarial review — shipped surfaces against the Floodlit reference

**Date:** 2026-08-18
**Authority:** `design_handoff_floodlit_surfaces_and_match_day/design/Floodlit Surfaces.dc.html`
is the UI/UX authority. Where the shipped app and the reference disagree, the app is wrong.
**Method:** reference served locally and driven through its registry; shipped app captured on the
iPhone 17 Pro Max simulator via the debug proof harness, rotated upright. Four surfaces sampled
(week hub, personnel, recruiting, league) out of 62.
**Reviewer stance:** adversarial. Findings are stated as defects, not as differences.

---

## The headline finding

**F-01 · P0 · Milestone 3 ported the chrome, not the compositions.**

The six family commits gave every surface the shared identity header, icon rail, world backdrop
and grain. They did **not** rebuild any surface's interior to match the reference. Every one of the
four surfaces sampled differs structurally inside the content column — different panels, different
columns, different information, different committing action.

This was reported at the time as "all six families converted", and against the milestone's own
words ("Build the identity header, icon rail, world backdrop and grain overlay as one container
view every management surface renders inside") that is accurate. Against the standing instruction
that the front end **must look exactly like the reference**, it is not. The gap is the whole
interior of 62 screens, and no amount of chrome work closes it.

Everything below is a consequence of F-01, listed per surface so the work is scopeable.

---

## Week hub — reference vs `CoachingHQView`

| # | Sev | Defect |
|---|---|---|
| F-02 | P0 | **The open-items agenda is absent.** The reference's left column is the week's actual agenda: a hero count (`5 OPEN`), a progress line (`0 of 5 cleared`), then five rows — GAME PLAN, PRACTICE, RECRUITING, INJURY, BOOSTERS — each tagged `OPEN`. This is the surface's dominant object (`04` §4.1). The app shows a next-fixture card and a staff plate instead. |
| F-03 | P0 | **No `SQUAD HEALTH` panel.** Reference carries three rows (position token, player, status flag: `Qtd` / `Flg 71` / `Cleared`) top-right. Absent. |
| F-04 | P0 | **No `STAKEHOLDERS` panel.** Reference carries four rows with share bars (Athletic dir. 58, Boosters 61, Fanbase 74, Locker room 69). Absent. |
| F-05 | P0 | **No committing action.** Reference has the gold `ADVANCE →` bottom-right with `5 STILL OPEN` above it. The app's nearest equivalent is a `Set work` button inside the decision card — not bottom-right, not the screen's one commitment. Violates the handoff's "one per screen, bottom-right in the thumb arc". |
| F-06 | P1 | **Decision card is not the reference's.** Reference leads with a headline question ("Halloran runs 62% of snaps from empty. Pick your answer."), prose, then three option rows each carrying its own cost line (`SAFE · −2 RUN FIT`). The app truncates its title mid-word and shows two options. |
| F-07 | P2 | The app adds a Mon–Sun day strip the reference does not have. |

## Personnel — reference vs `RosterView`

| # | Sev | Defect |
|---|---|---|
| F-08 | P0 | **Table columns are wrong.** Reference: `POS NO. PLAYER YR RATING FIT FRESH ST`. App: `# PLAYER POS OVR DEV Δ FIT COND STATUS`. |
| F-09 | P0 | **Ratings carry no uncertainty.** Reference prints `78 ±3`, `61 ±9`, `74 ±3` — the uncertainty is on every rating, and is the surface's honesty mechanism. The app prints a bare `91`. |
| F-10 | P0 | **No player dossier as drawn.** Reference right panel: 26 px `ValueRing`, `CEILING EST 80–86`, four attribute bars with heat (ARM 80 / DECIDE 75 / MOBILE 70 / DURAB 74), two `Flag`s (`ICE IN VEINS · match`, `WORKHORSE · development`), an eligibility line, and a `FULL PROFILE` action. The app shows prose strengths/concern and an `Open dossier` button. Five of the eight composition patterns are unused here. |
| F-11 | P1 | **`POS` should be a role token** (`QB1`, `RB2`, `WR1`, `TE1`) in cool ink — registry #18. The app prints a plain position. |
| F-12 | P1 | **`FRESH` should be a share bar**, not a number. The arc family's 4 px step exists and is unused. |
| F-13 | P1 | **Group filter is wrong control.** Reference: three pills (`OFF` / `DEF` / `ST`), gold when selected. App: five large tabs (Roster / Depth / Health / Development / Staff) which duplicate the header's own sibling links — the same navigation twice on one screen. |

## Recruiting — reference vs `RecruitingBoardView`

| # | Sev | Defect |
|---|---|---|
| F-14 | P0 | **No `POSITION PLAN` footer.** Reference closes the board with `MLB 0/2 · WR 2/3 · DT 1/2 · CB 1/3 · RT 0/1` — the class plan against which every row is judged. Absent. |
| F-15 | P0 | **Discovery rows are not differentiated.** Reference marks them `D`, greys them, and shows `Unknown` interest / `Unproven` fit. The app lists them like any other prospect. |
| F-16 | P1 | **Budget strip is over-weighted.** Reference is one compact inline line (`SLOTS 3 open · CONTACT 12 left · VISITS 2 left`). The app renders three large stat tiles, one of which truncates to `CONT...`. |
| F-17 | P1 | Prospect rows lose the hometown line the reference carries under each name. |
| F-18 | P2 | A `SAMPLE CAREER` debug badge renders over the board title. |

## League — reference vs `LeagueMapView`

| # | Sev | Defect |
|---|---|---|
| F-19 | P0 | **Wrong surface entirely.** The reference's League screen is a **standings table** — `# PROGRAMME CONF OVERALL PWR LAST 5` for 14 programmes — beside a `SATURDAY ACROSS THE LEAGUE` fixture panel and a narrative line. The app renders a geographic dot map with a College/Professional toggle. These are not the same screen, and the header's own `LEAGUE MAP` link is selected while the reference under that link shows the table. |

## Chrome defects (all surfaces)

| # | Sev | Defect |
|---|---|---|
| F-20 | P1 | **The header's right chip is global.** The app prints the next fixture (`SAT · SOUTHERN STATE`) on every surface. The reference varies it per surface: `85 SCHOLARSHIPS · 3 OPEN` on personnel, `CLASS OF 2027 · 14 OF 22` on recruiting, `4–2 · 3RD IN CONFERENCE` on league. It is surface context, not a global fact, and the read model models it as global. |
| F-21 | P1 | **Sibling links print full registry names.** App: `OPPONENT REPORT / FILM ROOM`, `PLAYER PROFILE`, `DEVELOPMENT PLAN`. Reference: `FILM ROOM`, `PLAYER`, `DEVELOPMENT`. The long forms overflow the row and force truncation elsewhere. |
| F-22 | P2 | **Rail's seventh entry is wrong.** Reference: `ALL 62` (opens the registry overlay). App: `LEAGUE`. |
| F-23 | P2 | **The registry overlay is not built.** `FLOODLIT-SURFACES.md` §1 specifies it as a dev surface behind a flag; the `ALL 62 SURFACES` header chip and the rail's `ALL 62` entry both target it. |

---

## Honest assessment of scope

The chrome, the token layer, the eight patterns and Match Day are real and match the reference.
The interiors of the management surfaces do not, and closing that is not a polish pass — it is
re-authoring 62 compositions against the reference, plus the read-model fields those compositions
need that the current models do not carry (rating uncertainty, ceiling estimates, freshness,
stakeholder standings, position plans, per-surface header context).

Several of these compositions also need data the simulation does not yet hold. Those are the ones
to identify before building, because a surface drawn against invented data is worse than one not
yet drawn — `04` §4.4.

**Recommended order:** fix the chrome defects first (F-20 to F-22 — they affect all 62 and are
small), then take surfaces one at a time in the handoff's own order, treating each as "port the
composition" rather than "wrap the existing view".


---

## Disposition

**Fixed in `docs/reviews` follow-up commit:**

- **F-20** — the header chip is now surface context, not a global fixture. `chrome(for:hub:context:)`
  takes it; the root supplies roster and recruiting figures; the opponent pennant now attaches only
  when the chip is actually about the fixture. Confirmed on device: personnel reads
  `85 SCHOLARSHIPS · 3 OPEN`.
- **F-21** — `CoachWorldScreenID.navigationName` gives the sibling row the reference's short forms
  (`FILM ROOM`, `PLAYER`, `DEVELOPMENT`). `canonicalName` stays the accessible name, so shortening
  a link to fit a 16 pt row does not shorten what the screen is called to someone who cannot see
  the row.
- **F-22** — the rail's seventh entry is `ALL 62`, not `LEAGUE`.

**Week hub rebuilt (F-02 to F-07).** The composition now matches the reference: the open agenda as
the dominant object (count, cleared line, obligation rows), the decision with a headline, evidence
and per-option cost lines, the `SQUAD HEALTH` and `STAKEHOLDERS` panels, and the single gold
`ADVANCE` bottom-right.

No data was invented for it. Squad health reads the same `PlayerLifecycleState` Team Health reads,
so the two surfaces cannot disagree about who is fit; stakeholder standing reads
`careerArc.stakeholderSupport`, which the engine already holds. Both are empty rather than faked
when the state is absent.

Two defects were introduced and caught in the same pass. The stakeholder share bars were tinted
with `CoachWorldTokens.Heat`, whose bands are defined for the **40–99 rating scale** — applied to a
**0–100 standing** it reported 58 support as poor using a scale that does not describe it. Colour
must be a second reading of the same figure, not of a different one; the bars now take a single
tint. Two labels also truncated and were shortened.

**Personnel rebuilt (F-08, F-10 to F-13).** The table now carries the reference's columns in its
order — `POS NO. PLAYER YR RATING FIT FRESH ST` — with the slot as a role token in cool ink, the
number in gold, and freshness as the arc family's 4 pt share bar beside its figure rather than
instead of it. The dossier leads with a `ValueRing`, then attribute bars and trait `Flag`s.

Attribute bars draw `(value − 40) / (99 − 40)`, not `value / 100`: the ratings scale starts at 40,
so a bar drawn against 100 would show the floor of the scale as 40 per cent of something.

The five route tabs are gone under chrome (**F-13**) — they repeated the identity header's own
family links, which is the same navigation twice on one screen. The reference's `OFF / DEF / ST`
group filter is **not** built in their place: the read model carries no unit field, and deriving
one in the view is the computation the read-model seam exists to prevent.

**F-09 is refused, not deferred.** The reference prints `78 ±3` on every rating. No per-player
rating uncertainty exists anywhere in the engine — `Player.potential` is hidden truth, and the
confidence-band model `02` section 5 describes was never built. Deriving a band from academic year
or games played would be inventing a scouting model and printing its output as fact, which `04`
section 4.4 forbids outright. The same applies to the dossier's `CEILING EST 80–86`. Both need
engine work first; until then the surfaces print what is known and nothing more.

**Open — the substance of the review.** F-01 (for the remaining surfaces), F-09, F-14 to F-19 and
F-23 are unaddressed. They are the
surface interiors, and they are the work. Nothing in this disposition should be read as reducing
F-01: the chrome is now right, and the compositions inside it are still not the reference's.
