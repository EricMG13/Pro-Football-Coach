# Design-reference library plan — what the sheets must contain, and what blocks them

**Destination:** `docs/briefs/2026-08-12-reference-library-plan.md`. **Working input, not canon.**
Carries Outcome 4 of the brief: the plan for the reference library, **not the sheets** — the brief
itself excludes producing `*-v3.dc.html` this session, and §2 below shows they could not honestly be
produced yet anyway. §3 contains a **proposed canon amendment** (a component registry section for
`docs/04-UX-AND-DESIGN-SYSTEM.md`); nothing has been applied.

---

## 1. The finding that reshapes this outcome

The brief defines the closed set as "the `04` §3 component registry, named exactly as `04` names
them so the mapping to the Swift registry stays 1:1."

**That registry no longer exists in canon.** The owner's 2026-08-11 correction rewrote `04` end to
end (current §3 is world navigation); the twenty-component registry the brief references survives
only in git history (`git show a60f4d9:docs/04-UX-AND-DESIGN-SYSTEM.md`, §3) and in forward
references from `01-RESEARCH.md` §6.6. The current `04` governs composition by rules (§4), a
component *pipeline* (§6.4) and a 62-family screen inventory (§8) — but names no closed component
set, and its P11 rule promotes a component only after three real production uses.

Consequences, stated as findings with costs rather than silently worked around:

1. **A sheet library keyed to a canonical registry cannot exist until canon holds a registry
   again.** Drawing sheets against the deleted registry would resurrect rejected canon; drawing them
   against nothing would recreate the parallel-design-authority defect the manifest deleted twice.
2. **The token prerequisite fails today in the other direction.** The brief's rule — no token value
   appears in a sheet that is not written into canon first — is currently violated *by the tree*:
   `Sources/ProFootballCoachUI/DesignTokens.swift` carries forty exact colour values, six spacing
   steps, four radii and seven type roles, while `04` §6.1 deliberately says exact production values
   are "validated … before SwiftUI implementation" and names none. The write-back of
   `DesignTokens.swift` into `04` §6.1/§6.2 (with measured contrast ratios, both appearances) is a
   blocking prerequisite for any sheet, and is register entry G-07.

So this plan's first deliverable is not a sheet; it is the §3 registry proposal plus the token
write-back, both owner-gated.

## 2. Preconditions before the first sheet is drawn

| # | Precondition | Owner of the work | State today |
|---|---|---|---|
| P-a | Component registry reconstituted in `04` (proposal in §3) | Owner accepts/amends; canon edit | Absent from canon |
| P-b | Token values written into `04` §6.1/§6.2 with measured ratios in both appearances | Canon edit + ratio computation | Values exist only in `Sources/ProFootballCoachUI/DesignTokens.swift`; ratios unmeasured in canon |
| P-c | Three generated team-colour pairs (dark-primary, light-primary, low-chroma) drawn from the P2 generator | Run `LeagueGenerator`/`ColourGenerator` on the owner's machine | Generator exists (`Sources/FootballSimCore/Generation/ColourGenerator.swift`); **known risk:** the 2026-08-10 design pass found all 32 pro pairs in its sample were dark-primary (`docs/STATUS.md`), so a light-primary pair may not be reachable — if so, the card uses an obviously-synthetic pair labelled *pending generator output*, and the generator gap is raised against P2 rather than hidden |
| P-d | Device window settled or at least verified (D15 / G-09), so cards render at real widths | Owner decision + sourcing rows Q4–Q5 | Window in `04` §7 inconsistent with the tree's 956 × 440 proofs |
| P-e | Density budget adopted (or amended) so cards can state their budget cost | Owner decision on `04` §4.5 proposal | Proposed in `2026-08-12-density-model.md` §7 |

## 3. Proposed canon amendment — a registry section for `04` (not applied)

Proposed as a new `04` §6.5 ("Component registry"), keeping §6.4's pipeline as its constructor. The
closed set below is grounded three ways: components that already exist in the tree (named by path),
components the capture corpus and `01` §6.6 establish as load-bearing relationships, and components
the 62-family inventory cannot be built without. Names are chosen to map 1:1 onto Swift types in
`Sources/ProFootballCoachUI/` (existing names kept exactly).

| # | Registry name | Purpose | Grounding today |
|---|---|---|---|
| 1 | `CoachWorldRouteButton` | Local-route navigation control | Exists — `CoachWorldDeskComponents.swift` |
| 2 | `CoachWorldActionButtonStyle` | Decide/inspect/delegate action styling with roles | Exists — same file |
| 3 | `coachWorldDeskSurface` | Matte opaque panel treatment, hairline rules | Exists — same file (modifier) |
| 4 | `CoachWorldBlankPhotoPlate` | Neutral person plate, no generated face | Exists — `BlankPhotoPlate.swift`; `04` §5.1 |
| 5 | `WorldStrip` | Programme/club, coach, date/phase, record, next advance | Screen-local today (`RosterView.swift`, `CoachingHQView.swift`); `04` §3 |
| 6 | `IdentityBand` | Person-led stable header for sequenced disclosure | Screen-local today (`PlayerProfileView.swift`); finding F1 |
| 7 | `DenseTable` | 24–28 pt tracked rows, sortable header, selection rule | Screen-local today (`RosterView.swift`); `04` §6.4.2 |
| 8 | `ColumnSet` | Segmented swap of fact columns over stable identity columns | Required new; density model T8 |
| 9 | `ListControls` | Sort/filter/bounded-search over simulation objects | Required new; sorting half exists (`PersonnelReadModels.swift` `RosterSortDescriptor`); G-10 |
| 10 | `RatingBadge` | Fixed-size numeric badge, printed number plus spoken band | Screen-local today (roster/profile); `04` §6.4.4 |
| 11 | `DeltaMark` | Per-value recent-change mark with sentence equivalent | Required new; finding F2, T3 |
| 12 | `ConfidenceTag` | Banded value / unknown / observation-count state | Data shape exists (`PersonnelReadModels.swift` attribute confidence); finding F3, T2 |
| 13 | `VerdictLine` | Engine-backed judgement line heading a readout | Required new; T1; `04` §4.2 |
| 14 | `Meter` | Capacity track with defined over-capacity state | Required new; `01` §6.6 §3.8 |
| 15 | `OpposedBar` | Two-team shared-track comparison | Required new; `01` §6.6 §3.6 |
| 16 | `FormLine` | Bounded last-N results with rating thread | Data shape exists (`PersonnelReadModels.swift` `FormEntry`); `01` §6.6 §3.7 |
| 17 | `StatusChip` | Closed ≤12-symbol vocabulary; ≤3 per row | Screen-local today; `01` §6.6 §3.10 inverted; density budget |
| 18 | `RoleToken` | Short role/assignment code mapping list to diagram | Required new; `01` §6.6 §3.5; finding F9 |
| 19 | `AgendaRow` | Obligation with cost/time-to-event and completion state | Screen-local today (`CoachingHQView.swift` week plan); finding F10 |
| 20 | `ScoreBug` | Teams, score, quarter, clock, down, distance, possession | Screen-local today (`MatchDayView.swift`); `04` §9 |
| 21 | `LowerThird` | Causal what-just-happened card on the field | Screen-local today (`MatchDayView.swift`); `04` §9 |
| 22 | `CallInCard` | Named staff proposal, accept/dismiss/inspect | Screen-local today (`MatchDayView.swift`); `04` §9; D1 |
| 23 | `EmptyState` / `ErrorBanner` / `InterruptedState` | The failure set, inside the owning composition | Required new; `04` §7 last clause; noted undrawn in every prior pass (`docs/STATUS.md`) |

Cost of adopting: the registry becomes an audit surface (each entry needs its three-production-uses
record or an explicit provisional mark); screen-local implementations of 5–7, 10, 17, 19–22 owe
extraction refactors when promoted, which is P11/M8 work, not a silent rename; and `04` gains a
section that must stay synchronised with `Sources/ProFootballCoachUI/` — the existing
`ContractTests.swift` source-contract pattern is the enforcement point.

## 4. The card contract

Every card in every sheet must satisfy, **and state that it satisfies**, all of:

1. Light and dark, both rendered; every foreground/background pair carries its measured contrast
   ratio against the surface it is actually composited on — 4.5:1 body text, 3:1 large text and
   non-text indicators (ratios recomputed at card-authoring time, not copied).
2. Every width in the supported set once D15 settles it — floor, ceiling, and the install floor if
   that differs — at default type and at AX5, no clipping.
3. Every interactive element at least 44 × 44 pt (floor itself UNVERIFIED — AS-6.5-08 — and the card
   says so until the sourcing row lands).
4. States, not one happy instance: default, selected, disabled, loading, empty, error, interrupted,
   delegated where the component can be any of those.
5. Anything touching `team.primary` / `team.secondary` / `team.onTeam` renders against the three
   generated pairs of precondition P-c, with floors `onTeam`-on-`primary` 4.5:1 and
   `secondary`-on-`primary` 3:1, and the light-primary caveat carried until the generator question
   closes.
6. Every data row expressible as one VoiceOver sentence, and the card states that sentence.
7. Every animation names its reduced form (Reduce Motion is a discrete state sequence per `04` §7).
8. Every READOUT-class card carries a verdict line, and names the engine computation that backs it —
   a card whose verdict has no engine owner is drawn with the verdict slot empty and the gap-register
   ID in its place.
9. Its density-budget cost under the Outcome 1 model, stated in the budget's units.
10. No token value that is not already written in `04` (precondition P-b), and sample identities
    from the P2 generator or obviously-synthetic names labelled *pending generator output*. No real
    school, team, player, coach, city or mark, ever; the name-collision and trade-dress tests stay
    green over anything generated for the sheets.

## 5. Sheet mechanics and inventory

Format, fixed by the brief: self-contained HTML and CSS at repo root, filename `*-v3.dc.html`, first
line `<!-- @dsCard group="..." -->`; no CDN, no icon font, no web font; system type stack; a glyph
is an SF Symbol name written as text. **The sheets are a rendering — `04` is the only canonical
home, and a value appearing only in a sheet has not shipped.**

Proposed inventory — one sheet per group, ordered by what unblocks the most build work:

| Sheet | Contents (registry #) | Feeds |
|---|---|---|
| `tokens-v3.dc.html` | The written-back `04` §6.1/§6.2 values, every pair with its ratio, both appearances | P11/M8 entry gate |
| `chrome-v3.dc.html` | 1–5 (route, action, surface, plate, world strip) | Every management family |
| `table-v3.dc.html` | 7–10, 17 (dense table, column sets, list controls, rating badge, status chips) | Roster, market, standings, boards |
| `person-v3.dc.html` | 6, 11, 12, 16 (identity band, delta marks, confidence, form) | Player/Prospect/Staff profiles |
| `readout-v3.dc.html` | 13–15 (verdict line, meter with overage, opposed bar) | Analytics-class readouts, cap/NIL |
| `week-v3.dc.html` | 19 (agenda row) plus chronology compositions | Coaching HQ, Practice Plan, offseason command |
| `broadcast-v3.dc.html` | 20–22 (score bug, lower third, call-in) | Match Day, Draft Room, Signing Day |
| `failure-v3.dc.html` | 23 (the failure set) | Every family; the set every prior pass left undrawn |

Eight sheets, ~23 registry entries, each card carrying the §4 contract. Broadcast cards depend
additionally on FSC-011 (anchor stream) only for *live* depictions; static state cards do not wait
for it.

## 6. What this session deliberately did not do

No sheet was produced (brief instruction). No canon file was edited. No token ratio was recomputed
here — P-b is a working session of its own with the values in front of it. And the registry proposal
was not silently reconciled with the deleted a60f4d9 registry: five of its twenty names
(`StakeholderCard`, `MapCanvas`, `AttributeRow`, `Chip`, `Sparkline`) return here in changed or
merged form (`AttributeRow` folds into `DenseTable`+`ConfidenceTag`; `Chip` splits into `StatusChip`
and `RoleToken`; `Sparkline` becomes `FormLine`; `StakeholderCard` and `MapCanvas` are deferred to
their owning families rather than pre-registered) — differences are stated so the owner is deciding,
not inheriting.
