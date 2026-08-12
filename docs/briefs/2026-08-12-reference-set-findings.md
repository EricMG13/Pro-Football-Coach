# Reference-set findings — what the eighteen captures teach that canon does not already hold

**Destination:** `docs/briefs/2026-08-12-reference-set-findings.md`. **Working input, not canon.**
Carries Outcome 2 of the brief. §5 contains **proposed corrections** to `docs/01-RESEARCH.md` §6.6
and `docs/04-UX-AND-DESIGN-SYSTEM.md` §1.1, written as proposals only; no canon file has been
edited.

Method and boundary: all eighteen files in the gitignored `FM Screenshots/` directory were read in
full this session, for **interface structure only** — what information is grouped with what, and
what the player is asked to do with it. They are third-party copyright; they stay outside the tree;
this document is the durable artefact and contains no real club, player or competition name, no
copied label, and no visual expression. The legal guardrail in `CLAUDE.md` governs throughout.

---

## 1. Provenance census

The brief requires provenance established per capture before any conclusion. Files are listed by
their timestamps; `C`-numbers are used by the other deliverables.

| C | File (Screenshot 2026-08-09 at …) | Surface | Provenance evidence | Grade |
|---|---|---|---|---|
| C1 | 22.37.59 | Player report, overview tab (established star player) | Current-generation desktop chrome, live-save furniture (real date, message counts) | Desktop FM26, apparently live build |
| C2 | 22.38.07 | Club portal / home dashboard | Same chrome, live save | Desktop FM26, apparently live |
| C3 | 22.38.16 | Calendar, month view | Same | Desktop FM26, apparently live |
| C4 | 22.38.29 | In-game glossary overlay over the portal | Same, overlay carries its own navigation | Desktop FM26, apparently live |
| C5 | 22.38.37 | Squad overview with pinned-destination editor open | Same; editor shows 6 of 12 pins over ~30 destinations | Desktop FM26, apparently live |
| C6 | 22.40.39 | Player last-5-matches detail | Watermark: "Work in Progress — taken from FM25 design files and not from a game build" | **FM25 design-file mock** |
| C7 | 22.40.47 | Redesigned portal/home (training-ground header, tile search) | Same watermark | **FM25 design-file mock** |
| C8 | 22.40.56 | Redesigned live match overview | Same watermark | **FM25 design-file mock** |
| C9 | 22.41.08 | Mobile in-match pitch, play in progress | Sideline boards read `FM23 MOBILE`; phone aspect | FM Mobile 23, live |
| C10 | 22.41.31 | Tactics planner overlay | Bottom-left stamp `NON-FINAL CAPTURE`, inside current desktop chrome | Desktop FM26, **non-final capture** |
| C11 | 22.41.48 | Match-day overview hub (pre-match) | Current desktop chrome, live save | Desktop FM26, apparently live |
| C12 | 22.42.08 | Player report of a generated youth player, deep save (in-game year 2037) | Current desktop chrome; generated identity; attribute-change arrows | Desktop FM26, apparently live |
| C13 | 22.42.38 | Mobile in-match goal event with lower-third card | Sideline boards read `FM2x MOBILE` — digit not resolvable at capture resolution even at 10× enlargement; more consistent with `21` than `23`, and the fixture's league composition fits the earlier season | FM Mobile, live; **SKU year uncertain** |
| C14 | 22.42.56 | Finances screen | New-generation card layout, breadcrumb chrome, no watermark | Desktop FM26, apparently live |
| C15 | 22.43.19 | Set-piece designer | Same, no watermark | Desktop FM26, apparently live |
| C16 | 22.43.33 | Squad table of a *foreign* club with scouting fog | Same, no watermark | Desktop FM26, apparently live |
| C17 | 22.43.43 | Training week overlay | Same, no watermark | Desktop FM26, apparently live |
| C18 | 22.43.55 | Analytics hub, key-findings tab | Same, no watermark | Desktop FM26, apparently live |

Census: **12 desktop live** (C1–C5, C11, C12, C14–C18), **3 design-file mocks** (C6–C8), **2 mobile
in-match** (C9, C13), **1 non-final desktop capture** (C10). This matches `01-RESEARCH.md` §6.6 §1's
table exactly in counts and grouping.

**Grading rule applied downstream:** a pattern seen only in C6–C8 or C10 is evidence of the
competitor's *intent*, not of a shipping product. Patterns so graded in this corpus: the agenda as
costed commitments (C7), the redesigned chat-style inbox (C7), the assistant suggestion with two
inline actions during play (C8 — the shipping analogue in C11/C5 is weaker), the threaded form line
over five result columns (C6), and the whole redesigned match composition (C8). `01` §6.6 §3 items 2
and 9 lean on those mocks and their grade should be read accordingly (proposed correction, §5).

## 2. The SKU question the brief ordered checked

The request that commissioned the current personnel work names **Football Manager Touch**
(`docs/superpowers/plans/2026-08-12-fm-touch-personnel-examples.md`, and `04` §1.1: "closest in
intent to Football Manager Touch"; `docs/proofs/README.md`: "the current Football Manager Touch
target").

**The corpus contains zero captures of Football Manager Touch.** It contains desktop screens, two
FM-Mobile in-match frames, and design mocks. "Closest in intent to FM Touch" is therefore a
*characterisation* — plausibly a good one, meaning "desktop information behaviour at reduced scale,
not the simplified mobile SKU" — but it is not supported by any capture of that SKU, and nothing in
this corpus can tell us what FM Touch actually simplifies or keeps. Two consequences:

1. Any claim of the form "FM Touch does X" that traces to these captures is ungrounded and should be
   rewritten as "the desktop reference does X". The proofs README and the personnel plan both carry
   the stronger claim today.
2. Whether FM Touch even exists as a current SKU, and on what platforms, is an owner-market question
   this session could not verify (no retrieval was run; see the sourcing log, row Q10, flagged as a
   competitor-product query for owner judgement).

Proposed wording for `04` §1.1 (owner to accept or reject): replace the SKU attribution with
"desktop-class composition adapted for landscape iPhone — the captures are desktop FM plus two
FM-Mobile match frames; no FM Touch capture exists in the corpus."

## 3. What the corpus teaches that we did not already hold

`01` §6.6 is the baseline to beat; its eleven §3 patterns and four §4 anti-lessons all reproduce
from this corpus and are not restated. New findings, each stated as **a relationship between pieces
of information** with its destination. None is a layout.

| F | Finding | The relationship | Seen in | Destination |
|---|---|---|---|---|
| F1 | **The identity band is the stable anchor of sequenced disclosure** | Who the person is (name, age, role, employer, terms, current/potential worth) stays fixed while everything beneath it swaps between overview, personal, performance, career | C1, C12 | `04` §4 composition; Player Profile family; density model T9 |
| F2 | **Change marks ride the attributes themselves** | A developing player's dossier shows, per attribute, the direction it recently moved — the "what changed" question is answered *in place*, not on a separate development screen | C12 | Density model T3; gap G-04 (engine change record) |
| F3 | **Uncertainty is a display state, not a footnote** | For an unscouted player: worth renders as a band, ability as unknown, and the required action ("scout him") sits in the same cell where the answer would be | C16 | Density model T2; gap G-06; Recruiting/Pro Scouting families |
| F4 | **Compliance leads the ledger** | The money screen's first citizen is the binary compliance state plus how far over (ratio and overflow), then the composition of the total; projections carry negative futures in an alarm state, two seasons out | C14 | Cap & Contracts, NIL Allocation families; `04` §4.2 "lead with the judgement" already covers the shape |
| F5 | **Load and consequence share the training screen** | The week of sessions (chronology) sits beside who improved and who regressed (counters) and how hard each day is (intensity glyphs); cause and effect co-located | C17 | Practice Plan family; density model T3/T6 |
| F6 | **Teaching borrows the reader's own data** | The glossary defines a term beside live values from the reader's save, and cross-links to the screens where the term matters | C4 | D9 candidate, deliberately uncommitted (`01` §6.6 §3.11 unchanged) |
| F7 | **A deep save keeps its identity machinery running** | Twelve in-game years in, a generated player carries a full dossier indistinguishable in structure from a real-world star's — the interface does not degrade as the world becomes fictional | C12 | Confidence for D6 endogenous identity; no new work |
| F8 | **The market row is a decision row** | The foreign-club table packs, per player: role slot, condition, status chips, banded value, contract expiry — exactly the facts a poaching decision needs, and nothing else | C16 | Portal Market, Free Agency, Pro Scouting families; density model T8 column-set rule |
| F9 | **Set-piece instructions map list to diagram by token** | Each instruction row carries a letter-number token that reappears on the pitch diagram; the list is editable, the diagram is readable, neither tries to be both | C15 | Personnel Packages, Scheme Book, Depth Chart families (`01` §6.6 §3.5 held the tactics half; the designer generalises it to any list-diagram pair) |
| F10 | **The pre-match hub is composed from other screens' summaries** | Match-day overview tiles are one-line reductions of squad, tactics, set pieces, feedback and analytics, each opening its full screen — a hub earns density by summarising, not by owning | C11 | Coaching HQ, Match Day pre-game; supports `04` §4.4's rejection of the contents-page screen only when tiles are *summaries with verdicts*, not bare links |
| F11 | **Match presentation and match management are separable registers even at the reference** | The mobile match is ambient field + lower-third + one-line commentary with near-zero chrome; the desktop pre-match is dense tiles. The reference does not blend them | C9, C13 vs C11 | Confirms `04` §2's Broadcast/management split against the temptation to add management chrome to Match Day |
| F12 | **Progress marks quantify the remaining watch** | The mobile match header carries a row of small marks, first ones filled — how much of this match remains, at a glance (`01` §6.6 §3.4 recorded this as an inference; C9 and C13 both carry the row, so it is now an observation, though its exact meaning is still unread) | C9, C13 | P13 key-moments indicator |

## 4. Anti-lessons — what a mature product's sprawl looks like from inside

Extends `01` §6.6 §4. Each is a symptom captured live in this corpus, kept as a tripwire:

| A | Symptom | The failure it evidences | Our tripwire |
|---|---|---|---|
| A1 | A pinned-destination editor offering 6 of 12 pins across ~30 destinations (C5) | Navigation outgrew navigability | The world strip plus local routes (`04` §3); the day a pin system is proposed, the IA has failed |
| A2 | A search field over the product's own tiles (C7, mock) | Same failure, admitted in a redesign | World Search indexes football objects only; density model §6 |
| A3 | An in-game encyclopedia needed to play the game (C4) | The working vocabulary outgrew learning | The ≤ 12-symbol vocabulary cap; if a glossary ever becomes *necessary* rather than nice, the cap has been breached |
| A4 | Fifteen-column tables and three side-by-side attribute columns (C1, C16) | Density by area, unavailable on a phone | Six-to-nine fact columns plus column sets; density model T8 |
| A5 | Attribute meaning carried by a learned 1–20 scale with colour highlights (C1, C12) | A numeracy convention substituting for stated meaning | Ratings stay 40–99 with the printed number plus spoken band (`04` §6.4.4); verdicts carry meaning, not scale familiarity |

## 5. Proposed corrections to canon (not applied)

1. **`01-RESEARCH.md` §6.6 §1/§2 — the mobile SKU year.** §6.6 states both mobile captures' boards
   read `FM23 MOBILE`. C9's do. C13's digit is not resolvable at capture resolution; enlargement
   reads more like `21`, and the fixture's league composition fits the earlier year. Proposed
   wording: "one capture's boards read FM23; the second's are illegible at capture resolution and
   may be FM21." No conclusion changes — both are FM Mobile, in-match only, and neither is FM Touch;
   AS-6.5-07's settlement (landscape pitch, device rotated) stands on C9 alone.
2. **`01-RESEARCH.md` §6.6 §3 items 2 and 9 — provenance grades.** The in-match suggestion with two
   inline actions and the costed agenda are mock-sourced (C8, C7). The patterns remain sound and
   remain adopted; the citations should carry the mock grade so nobody later cites them as shipping
   behaviour.
3. **`01-RESEARCH.md` §6.6 §4.3/§4.4 — two stale clauses.** §4.3's constraint is stated as "five
   tabs, every destination within two taps of its tab root"; the five-tab bottom bar was removed by
   the owner's 2026-08-11 correction (`04` §3, world strip). The two-tap reach survives and is
   restated in the density budget; the five-tab framing should be marked superseded in place.
   §4.4 still reads "Owner-fixed: portrait only" — false since 2026-08-10 and internally
   contradicted by §6.6 §2's own 2026-08-10 note; mark it superseded in place rather than editing
   the observation.
4. **`04` §1.1 — SKU attribution.** Per §2 above.
5. **`docs/proofs/README.md` and the personnel plan** carry "Football Manager Touch target" as if
   evidenced; downgrade to "desktop-reference density target" when next touched (working files, not
   canon; noted for hygiene).

## 6. What §6.6 still holds, verified against the corpus

Re-read against all eighteen captures, the following §6.6 claims survive unweakened and need no
amendment: the verdict-first analytics pattern including its financial-screen exception (C14 indeed
carries no prose judgement, only state and ratio — the pattern's precise form); the ambient-field /
foregrounded-event match grammar (C9, C13); role tokens (C10, C15); opposed bars (C8 mock, C11
live); the form sparkline family (C1 live bottom-band, C6 mock threaded line); status-glyph columns
with the three-glyph inversion for our screen size (C5, C11, C16); the density anti-lesson that
desktop column layouts do not port (§4.2, now with the landscape-phone warning aged well); and the
observation that the captures establish structure, not feel (§5 — still nothing here tells us what
any of this is like in the hand).
