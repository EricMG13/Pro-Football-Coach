# 06 — TOKENS, DENSITY AND THE ACCESSIBILITY FLOOR

Covers brief §5.4, §5.5 and §5.6.

**Baseline:** the token layer largely exists at
[`DesignTokens.swift`](../../Sources/ProFootballCoachUI/DesignTokens.swift) and is **KEEP**. This
document specifies what is added, what is corrected, and what becomes testable. Additions are marked
**NEW**.

---

## 1. What exists and survives

| Group | Contents | Ruling |
|---|---|---|
| `Frame` | `floorWidth 844`, `floorHeight 390`, `sensorHousing 59`, `homeIndicator 21`, `gutter 20`, `leadingInset 63`, `bottomInset 25`, `topInset 12`, `lowerThirdWidthRatio 338/932` | KEEP |
| `Stage` | `railLeading 59`, `railWidth 44`, `railTop 46`, `railGap 2`, `contentLeading 115`, `contentTop 46`, header rows, `contentWidth` (derived), `railFreeLeading 63` | KEEP — `contentWidth` is *derived*, not chosen, so it stays right if the floor moves |
| `Gap` | 12 steps, hair 2 → xxl 20 | KEEP — deliberately not a 4/8 grid; the source states why: *"snapping them to a grid is what makes a dense screen read as a template"* |
| `Space` | 6 steps, xxs 4 → xl 20 | KEEP |
| `Pad` | panel/row/card/alert/band, each (v,h) | KEEP |
| `Motion` | press 0.12, value 0.22, world 0.42, panelEnter 0.24, pulse 1.5, `pressDim 0.12`, `disabledOpacity 0.4` | KEEP — press **dims rather than scales**, so a committing action never shrinks under the thumb committing with it |
| `DisplaySize` | 16 steps, hero 66 → flag 9 | KEEP |
| `TypeRole` | Dynamic-Type-backed roles + `authoredFloor 12`, `workingProse 13`, `microLabel 10/0.8` | KEEP |
| `Shape` | `minimumTarget 44`, radii, `ringStrokeRatio 0.12`, `ringTextRatio 0.42` | KEEP |
| `Depth` | glass 0.56, deep 0.82, panelBorder 0.38 | KEEP |
| `Palette` | 20 semantic slots | KEEP — see §2.1 |

**The palette is already semantic, not a raw ramp**, which is what the brief asks for: `page`,
`work`, `raised`, `contentPrimary`, `contentSecondary`, `contentQuiet`, `actionPrimary`,
`actionSecondary`, `actionDestructive`, `stateLive`, `statePositive`, `stateWarning`, `stateNegative`,
`stateInfo`, `collegeIdentity`, `proIdentity`, `fieldTurf`, `fieldLine`, `fieldAnnotation`,
`fieldLive`.

---

## 2. Data-encoding tokens

These carry the analytical load and are, as the brief says, the ones most often left undefined. Four
of six exist; two are new.

### 2.1 Rating — EXISTS, EXTEND
`CoachWorldTokens.Heat` maps the 40–99 scale to three bands (red <70, amber 70–84, green ≥85), and
its rule is already right: **colour is always a second reading of a printed figure, never a
replacement.** FM26 does the same — the attribute number stays printed inside the heat fill (A).

**Extension, §2.6.**

### 2.2 Trend — EXISTS
`CoachWorldDeltaMark`. Precedent: FM26's green chevron beside an improving attribute (A). Must carry
direction **and** a non-colour cue (glyph rotation), per §4.

### 2.3 Positive / negative delta — EXISTS
`statePositive` / `stateNegative`, plus `CoachWorldMeter`'s **over** state. Precedent: FM26's wage
bar overrunning its own track in red at 101.8% (A) — the overrun is shape, not just colour.

### 2.4 Positional grouping — EXISTS
`FloodlitPill` + `FloodlitFlag`. Precedent, and the technique to copy exactly (A): FM26 puts a
**colour-filled position chip in the leading column** and keeps status flags in **their own narrow
column**, never inline. That is what lets 15 columns stay readable.

### 2.5 Confidence interval — PARTIAL, needs `RangedRating` **NEW**
`CoachWorldConfidenceTag` exists with `.banded` / `.unknown` / `.observations(n)`, and its source
comment already states the right principle: *"Unknown is quiet, not alarming: an absent observation
is not a bad one."* The Show reaches the identical conclusion, printing the literal word "Unknown"
rather than blanking or zeroing (A).

What is missing is the **rating itself as a range**. The Show's model (A): `68-86 Potential`,
`48-66 Overall`, each attribute `PRESENT 43-61 → FUTURE 60-78`, **range width being the interval**,
narrowing as a scouting-progress bar fills, with the bar placed directly above so the player sees
*why* the numbers are vague.

**NEW tokens:**
```
Confidence.rangeMinWidth   =  28 pt   // "68-86" at DisplaySize.row with tabular digits
Confidence.rangeSeparator  =  "-"     // not an en dash: tabular digits, fixed advance
Confidence.unknownOpacity  =  0.55    // quiet, not alarming
Confidence.progressHeight  =   4 pt   // the scouting bar above the ranged block
```
**Blocked on [`07`](07-GAP-REGISTER.md) GAP-06.** The engine has no confidence model, so there is no
range to render.

### 2.6 League-relative band — **NEW**
The brief's own framing is right: any rating shown as "good" requires knowing what the league looks
like. FM26 answers with a computed verdict badge plus a scatter of the league population (A). The
Show answers far more cheaply, by **printing the band legend on the surface** (A).

**Adopt The Show's answer.** It needs no live percentile at render time and degrades gracefully.

**NEW — extend `Heat` from three bands to five**, aligning with the 40–99 scale:
```
Band.wellBelow  40-59   stateNegative
Band.below      60-69   stateNegative, 0.7
Band.average    70-79   contentSecondary       // neutral, NOT amber
Band.above      80-84   stateWarning
Band.wellAbove  85-99   statePositive
```
> **Note the correction to the existing three-band scheme.** Today 70–84 is amber, i.e. "average"
> reads as *caution*. In The Show's five-band scheme average is **neutral**, and caution is reserved
> for the genuine boundary. A merely average player should not read as a warning.
>
> **This is a behaviour change to a shipped token and is recorded as [`08`](08-DECISION-REGISTER.md)
> D-007.** The three-band scheme is cited to `04` §6.4, so `04` must be amended first per the
> doc-first rule — this document does not get to change it unilaterally.

`BandLegend` (`05`) renders these five wherever banded ratings appear.

---

## 3. The density model

### 3.1 The budget

From [`00`](00-GATE-ZERO.md) §4, derived not chosen:

```
content box at the floor = 709 × 319 pt
rows      = floor(319/32) = 9 readout   |  floor(319/44) = 7 interactive
columns   = 8 working, 12 absolute maximum
BUDGET    = 72 cells per viewport
benchmark = 360 cells (FM26 squad list)      ratio 5.0 : 1
```

### 3.2 The three tiers

| Tier | Row height | Type floor | Max cells | Where | Intent |
|---|---:|---:|---:|---|---|
| **DENSE** | 32 pt | `microLabel` 10 pt for labels; `authoredFloor` 12 pt for prose | 72 | READOUT surfaces only | DEEP |
| **COMFORTABLE** | 44 pt | `workingProse` 13 pt | 56 | ACTION and MIXED surfaces | CRUISE, TRIAGE, DEEP |
| **BROADCAST** | n/a | `DisplaySize.lead` 17 pt | 12 | Match Day, ceremony surfaces | CEREMONY |

COMFORTABLE's 56 = 7 interactive rows × 8 columns. **This is the cost of interactivity**, and it is
the point of `00` §4.4 R-D3: making rows tappable costs 22% of density. That purchase must be
deliberate.

### 3.3 Tier rules

- **T-1.** Tier is a property of the surface's readout/action attribute (`04` §4), not a user
  preference. An ACTION surface may never be DENSE — a decision taken at DENSE density is a decision
  taken by mistake.
- **T-2.** A surface moves tiers only via `ColumnSetControl` (fewer columns, same tier) or Dynamic
  Type escalation (§5), never by silent reflow.
- **T-3.** BROADCAST never carries a table. If a match surface needs tabular data it links to a
  READOUT surface.
- **T-4.** Exceeding a tier's cell budget is a build failure, not a review finding. See §3.5.

### 3.4 The user-facing control
`SettingsAccessibilityView` (`01`: REFACTOR) gains a **Density** control with two options,
Comfortable and Compact, defaulting to **Comfortable**. Compact permits DENSE on READOUT surfaces
that would otherwise be COMFORTABLE. It **never** overrides T-1, and it never reduces a touch target
below 44 pt.

Honest note: **no benchmark precedent was observed for a user-facing density control.** It is
proposed because the 5:1 ratio makes one column set unable to serve both a phone-in-one-hand player
and a player studying a roster. Recorded as **D-009**.

### 3.5 Binding the tiers to a test — extending `SmallestDeviceLayoutTest`

**Correction: `SmallestDeviceLayoutTest` exists.** `Tests/SimTests/Suites/SmallestDeviceLayoutTests.swift`
(247 lines) sits on `codex/complete-game-loops`, registered in `SuiteCatalog` as
`SmallestDeviceLayoutTest`. It already pins `installFloor = CGSize(width: 844, height: 390)`,
asserts `sensorHousing == 59` and `homeIndicator == 21`, checks the stage fits horizontally and
vertically, checks furniture clears the physical insets, checks the same geometry at the promise
floor, and scans `DesignTokens.swift` for stray `844`/`390` literals.

**Port it to the working branch first. Do not rewrite it.** Then add `DensityBudgetTests` beside it,
enumerating by construction from `CoachWorldScreenID.allCases` — not from a hand-listed set, because
per `CLAUDE.md` a spot-check over hand-listed instances is a defect, not coverage.

Assertions:
1. Every canonical surface declares a tier. A surface with no tier fails to compile.
2. No surface exceeds its tier's cell budget at 844 × 390.
3. No interactive row is shorter than `Shape.minimumTarget` (44).
4. No ACTION surface declares DENSE.
5. Every tier is instantiated by at least one surface at the floor — **otherwise it is an
   aspiration, not a tier**, which is exactly what the brief demands in §10 dimension 9.

**Until this test exists, every density claim in this dossier is unverified.** It is stage 2 of
[`09`](09-BUILD-PROMPT.md).

---

## 4. Colour-independent encoding

Every semantic colour carries a redundant non-colour cue. Table, complete:

| Colour use | Redundant cue | Precedent |
|---|---|---|
| Rating band | The **number** is always printed inside the fill | FM26 (A); already the `Heat` rule |
| Trend | Chevron **direction** | FM26 chevron (A) |
| Comparison leader | **`LeaderMark` triangle position** | Madden (A) — position and direction, not hue |
| Over-budget | Bar **overruns its track** | FM26 wage bar (A) |
| Result | **Fill state**: solid win / hollow loss / half draw | FM26 result dot (A) |
| Availability | **Glyph** + two-letter code | FM26 `Inj`/`Tir`/`Wnt` (A) |
| College vs pro identity | **Label**, never colour alone | house |
| Live state | **Motion** (`Motion.pulse`), plus a label | house |

`LeaderMark` is the cheapest win here: adopting Madden's triangle discharges the comparison-row
obligation with no additional design.

---

## 5. Dynamic Type

**Apple grants no tabular carve-out (Grade B, verified via Apple's DocC JSON payload — the HIG is a
JS-rendered SPA and its live pages return only titles to a fetch).** The HIG "Lists and tables" page
contains **zero** occurrences of "Dynamic Type", "text size" or "text-size": no exemption exists.
Typography pushes the other way — *"Keep text truncation to a minimum as font size increases... aim
to display as much useful text at the largest accessibility font size as you do at the largest
standard font size."*

**But scaling need not be uniform.** Apple: *"Prioritize important content when responding to
text-size changes. Not all content is equally important"*, and SwiftUI's `dynamicTypeSize(_:)` range
limit is a **sanctioned clamp**. So *"not every cell scales equally"* is within the HIG; *"pinned to
a fixed size"* is not.

**Behaviour by tier:**

| Tier | Standard sizes | Accessibility sizes (AX1–AX5) |
|---|---|---|
| DENSE | All type scales. Cell budget falls as rows grow | **Escalates to COMFORTABLE**, then to a single-column stacked list. `ColumnSetControl` drops to the primary set |
| COMFORTABLE | All type scales | Rows become two-line; the leading identity column persists, secondary columns move to line 2 |
| BROADCAST | Score/clock use `figure()` tabular digits and scale within a clamp; labels scale freely | Furniture reflows below the field rather than over it |

`CoachWorldScaledType.swift` (112 lines) exists and already carries this responsibility.
`AccessibilityReflowTests` already asserts reflow at accessibility sizes.

**App Store Larger Text (Grade B):** declaring support requires enlargement *"to at least 200% or the
maximum font size for the system"*, achievable via Dynamic Type or an in-app control, with truncation
permitted **provided** *"users can access the same information in a different view"* — which is
precisely what the DENSE → stacked-list escalation provides. Reliance on system Zoom or Hover Text is
explicitly barred. This is a self-declared Nutrition Label criterion, not an automated review gate.

---

## 6. VoiceOver on dense tabular surfaces

The hardest accessibility problem in the product, and the one the brief is right to make a
constraint rather than a review stage.

1. **Each row is one accessibility element**, not N cells. Label composes as
   *"{name}, {position}, {rating}, {status}"* — identity first, because that is what the player is
   scanning for.
2. **Column values become custom actions or a rotor**, not siblings. A 15-cell row read as 15
   elements is unusable; the same row as one element with a rotor is navigable.
3. **`RangedRating` reads its range explicitly**: *"potential, 68 to 86"*, never *"68 dash 86"*.
   `.unknown` reads *"potential, not yet scouted"* — the tag's own principle, that an absent
   observation is not a bad one, must survive into speech.
4. **`LeaderMark` reads as a word**: *"leading"* / *"trailing"*. A triangle that only reads visually
   defeats the point of choosing a non-colour encoding.
5. **`AgendaRow` reads state first**: *"delegated to {name}"* / *"pending, due in 7 hours"*. The
   delegated state must be audible, or delegation is silent to a VoiceOver user (invariant L-3).
6. **`NewsTicker` is not in the accessibility tree by default.** It is ambient. Its content is
   reachable at the News destination. An ambient ticker that interrupts VoiceOver is a defect.
7. **`CoachWorldSystemState` announces on change** — empty, loading and error states must be
   announced, not merely drawn.
8. **Reduce Motion:** `NewsTicker` becomes a static rotating item; `Motion.pulse` becomes a static
   state; `Motion.world 0.42` backdrop transitions are suppressed.
9. **Reduce Transparency:** already handled — `CoachWorldFloodlitStage` reads
   `accessibilityReduceTransparency` and `Depth`'s glass/deep opacities collapse to opaque.

---

## 7. Touch targets

`Shape.minimumTarget = 44` is committed and matches Apple's guidance. Three rules:

- **Any row that responds to touch is 44 pt.** `FloodlitPatterns` already states it: *"32 when it is
  a dense readout, 44 the moment it can be tapped: a row that responds to touch is a control and
  takes a control's floor."*
- **Landscape thumb reach is unevidenced.** Both research passes returned **nothing** on touch
  ergonomics or thumb zones (`02` §11). Committing controls are therefore placed by the design
  references' own composition, and this is flagged as an open question (**D-010**), not dressed up as
  research-backed.
- **The icon rail at `railWidth 44`** already meets the floor.

**Landscape-only is permitted, with one obligation (Grade B).** Apple: *"If your app or game is
landscape-only, make sure it runs equally well whether people rotate their device to the left or the
right."* This is guidance, not App Store Review policy, so the testing implication — exercise both
`landscapeLeft` and `landscapeRight`, not one — is Grade D with that premise stated. `CLAUDE.md`
records an existing `OrientationPolicyTest`; it must cover both rotations.
