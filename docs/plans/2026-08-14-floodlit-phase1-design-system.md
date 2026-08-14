# Phase 1 — Import Floodlit and build the component registry

*Written 2026-08-14. Owner-approved. Executes canon P11a plus `05` P11 item 4 ("build production
tokens, shared interaction primitives and contract tests"). Does **not** include the three proof
screens — that is Phase 3, and `04` §10's gate stands between it and the other 59 families.*

`CLAUDE.md` requires `superpowers:writing-plans` against the relevant `05` section before a phase
begins. **That skill is not installed in this container** (nor is `adversarial-reviewer`; the
Phase 0b review was run by a general-purpose agent instructed to be adversarial, and the same
substitution applies here). This plan is written by hand to the same shape and saved to the same
place, so the gate is met in substance and the substitution is recorded rather than hidden.

## What exists before this phase

Phases 0 and 0b landed canon and the reference library. **No Swift changed.** Of `04` §6.5's 35
registry entries, **only 1–4 exist as named types** — verified by grepping every entry name across
`Sources/`, not assumed. Entries 5–35 return zero hits: they are anonymous inline code inside the
five screen views, or absent entirely.

| Target | Lines | Note |
|---|---:|---|
| `Sources/ProFootballCoachUI/` | 4,937 | 5 screens + `RootView`, flat, no subdirectories |
| `Sources/CoachWorldApp/` | 1,233 | providers + the one composition-layer view |
| Floodlit design system (to import) | ~1,377 | `Tokens`, `Support`, `Atmosphere`, `Components` |
| Floodlit prototype screens (**not** imported) | ~1,407 | `Screens`, `Fixtures`, `Gallery`, `Demo` |

## Three corrections to the programme plan, found while grounding

1. **The bundle carries no HTML prototypes for fifteen screens.** The programme plan said it did.
   There is exactly one HTML file in the bundle's entire history — `project/Landscape Screens
   v4.dc.html`, 11 frames covering **four** screens (Coaching HQ, Depth Chart, Player Profile, Match
   Day). The ten unported screens have only a one-line description each in `FLOODLIT.md` §65–84.
   The bundle is still the right artifact — 12 files the tarball lacks, all 36 shared files
   byte-identical — but not for the stated reason. **Consequence for Phase 3: Recruiting Board, one
   of the three proof screens, has no Floodlit design at all.** Its sources are `table-v4`,
   `person-v4` and `04` §8. Surfaced now rather than at the gate.

2. **`04` §6.5 already sequences this work differently.** Line 669 says screen-local implementations
   "owe extraction refactors **when promoted**", under P11's three-production-uses rule, and names
   the screen-local set precisely as **5–7, 10, 17, 19–22** — nine entries, not "5–23". The owner
   chose to build all nineteen now. That is a deliberate departure and is recorded in §6.5 rather
   than left to contradict it silently. It is more defensible than it first appears: Phase 0b built
   the spec for exactly the entries that have no implementation — `table-v4` specifies `ColumnSet`
   and `ListControls`, `person-v4` `DeltaMark` and `ConfidenceTag`, `readout-v4` `Meter` and
   `OpposedBar`, `failure-v4` the failure set. Nothing here is invented.

3. **Floodlit's prototype screens are not imported.** Our five views already exist, take read models
   and are tested; importing Floodlit's inert screens would create a second Coaching HQ, Player
   Profile and Match Day. The programme plan's own stated endpoint is "matching the five existing
   views", and its target directory is `DesignSystem/`. The measured split settles it:

   | | design system | prototype screens |
   |---|---:|---:|
   | fixed font sizes | 4 | **56** |
   | bare padding/spacing/radius/lineWidth | 21 | **87** |
   | fixed `.frame(width:height:)` | 9 | **31** |
   | `.position(` | 3 (fraction-based) | **8** (device-rect arithmetic) |

   Every one of the six worst offenders — `.position(x: Metrics.device.width - 20 - 148, …)` —
   is in `Screens/`. Not importing that half removes them rather than fixing them.

## 1A — Canon first

Doc-first rule: each of these gates code that would otherwise fail a test the day it lands.

- **§6.6 — three of Floodlit's four SF Symbols are unregistered.** Floodlit draws `arrow.right`,
  `chart.line.uptrend.xyaxis`, `chevron.left`, `exclamationmark.triangle`; only the last is a member.
  **And `chevron.*` in the control-furniture row cannot be parsed by the test at all**: the register
  reader's regex is `` `([a-z][a-zA-Z0-9.]*)` `` and the `*` blocks the closing backtick, so the glob
  contributes no members and *any* chevron fails. That is a latent defect in canon, unexposed only
  because no current view draws one. Fix the glob to enumerate real members; resolve the other two
  under §6.6's own rule that one meaning takes one member.
- **§6.1 — add the atmosphere-value table.** 66 hex literals sit in the imported half and only ~35
  are named tokens; the rest are world-backdrop gradient stops, beams, dust and jersey ramps.
  Canon's rule is absolute ("a design-token literal in a view is a defect… colours come from the
  design system"), so they become tokens, and every token must be a value canon states.
- **§6.5 — record the promotion decision** (correction 2 above).
- **§6.3 — record the spacing snap.** Floodlit uses 0,1,2,3,5,7,9,11,14,18,30; `ContractTests:691`
  pins `[4, 6, 8, 12, 16, 20]` by value. The snap was decided in the Phase 0 plan; this records the
  mapping so it is not re-litigated per call site.

## 1B — Import the design system

Copy — **never symlink**, `ContractTests:1362` fails on symlinks under `Sources/` — into
`Sources/ProFootballCoachUI/DesignSystem/`.

| From | Rework on arrival |
|---|---|
| `Tokens/Palette.swift` | Folded into `DesignTokens.swift`, **not** kept as a rival `Palette`. `ContractTests:1196` is compile-coupled to `CoachWorldTokens.Palette`'s 20 role names. Add the missing `lightFills`. |
| `Tokens/Typography.swift` | `Face`/`Label3` gain `@ScaledMetric` off the §6.2 ramp. `Label3`'s 9 pt default breaches §6.2's 10 pt Caption floor. |
| `Tokens/Metrics.swift` | `device` becomes a preview constant per §7. `sensor: 59`/`home: 21` are hard-coded iPhone 15 Pro insets standing in for `safeAreaInsets`. |
| `Support/CutCorner.swift`, `Grain.swift` | Radii to §6.3 tokens; grain gains its Reduce Transparency branch. |
| `Atmosphere/Worlds.swift` | 28 inline colours to tokens. `PitchPlane(perspective:)` keeps its caveat comment verbatim. |
| `Components/Surfaces.swift` | `DeviceFrame`'s `.frame(width: Metrics.device.width, …)` is the single structural pin and becomes adaptive; `Stage` owns physical safe-area edges. `GlassPanel`'s deep fill moves 0.70 → **0.78** per §6.1's measured rule. |
| `Components/Gauges.swift`, `Controls.swift` | Registry 29–35. Tokenise 21 bare metrics. `GoButton`'s `action:` loses its `{}` default so a dead control cannot compile. |

**Not imported:** `Screens/`, `Fixtures/Save.swift`, `Gallery.swift`, `Demo/`, and all 5,332 lines of
`LandscapeScreens/` — superseded by its own documentation, and it carries the retired violet palette
(`accent #9964E8`), which would fail token sync immediately.

## 1C — Registry entries 5–23

Named **public** types (entries 1–4 are `internal` today and unreachable from `CoachWorldApp`, which
is why `CoachWorldAppRootView.swift:116` hand-rolls a `.borderedProminent` button instead of using
registry 2). Each built against the v4 sheet that specifies it.

- **Extracted from real duplication (9):** `WorldStrip` ×3, `IdentityBand` ×3, `DenseTable` ×2
  *independent* implementations (`RosterView:302` 28 pt rows with `LazyVStack`;
  `RecruitingBoardView:320` 44 pt rows with **no `ScrollView` and no lazy stack** — the board does
  not scroll today), `RatingBadge` ×3 (none draws the badge §6.4 specifies; they only colour text),
  `StatusChip` ×2 non-conforming, `AgendaRow` ×2, `ScoreBug` ×2, `LowerThird`, `CallInCard`.
- **Written fresh against the sheets (10):** `ColumnSet`, `ListControls` (only sort exists — no
  filter, no search anywhere in the target), `DeltaMark`, `ConfidenceTag` (spoken today, never
  drawn), `VerdictLine`, `Meter`, `OpposedBar`, `FormLine`, `RoleToken`, and the failure set —
  **`ErrorBanner` and `InterruptedState` exist in no form at all**; errors are a `statusMessage:
  String?` threaded into five different world-strip renderings.
- **Shared plumbing, extracted once:** the `palette` computed property is copy-pasted **five times**
  → an `EnvironmentValues` entry; `seam`/`verticalSeam` are **nine copies across five files at two
  opacities, one missing `.accessibilityHidden`** — a real VoiceOver defect in `CoachingHQView`;
  `ratingColor` twice byte-identical; `route(_:screen:current:)` ×3; `worldContextLine` ×3; five
  private `*Metric` enums holding overlapping un-tokenised constants.

**Every extraction must serve both compositions.** The five `accessibleLayout` bodies are not
modifiers over the standard tree — they are parallel hand-written screens, so each inline component
exists twice. This roughly doubles the surface and is the phase's biggest sizing risk.

## 1D — Retrofit the screens, rewrite the test

Re-skin the five views onto the registry. **Keep every file name**: `ContractTests:504` hard-lists
seven view names and `AccessibilityReflowTests:77` hard-lists five, and a rename silently drops a
family out of the AX5 contract. Read models, initialisers and intent closures are unchanged.

Rewrite **`ContractTests.swift:716`** — 62 substrings, not the ~50 the programme plan estimated.
Verified breakdown: **27** are real invariants worth keeping (type declarations, `Button(` over
`onTapGesture`, the accessibility modifiers), **22 are dead on a re-skin** (10 pin component names
Floodlit replaces, 12 pin exact call-site expressions), **13** are debug-harness plumbing. Replace
the dead 22 with a registry-enumerated check — every §6.5 entry resolves to a type, by construction
— which is the coverage-boundary rule `CLAUDE.md` states and this test currently violates.

## What breaks, verified against the suites

| Test | Why | Action |
|---|---|---|
| `ContractTests:641` token literals | Scans **every** UI-importing file under `Sources/`; the marker set is **seven**, including `size:` and `cornerRadius:` | Tokenise on import |
| `DesignContractTests:168` symbol register | Same enumeration; 3 of 4 symbols unregistered | 1A first |
| `DesignContractTests:122` token sync | Every new `0xRRGGBB` needs `#RRGGBB` in canon | 1A first |
| `DesignContractTests:238` sheet ratios | A palette change must land in canon **and all ten sheets** together | Hold the palette still |
| `ContractTests:1196` palette contrast | Compile-coupled to `Palette`'s 20 role names | Fold, do not replace |
| `ContractTests:691` spacing scale | Value assertion on `[4,6,8,12,16,20]` | Snap Floodlit's metrics |
| `LegalTests:352` shipped copy | Sweeps every string literal under `Sources/` against the **institution** blocklist. Floodlit's cast is already "Example State"/"Coach Sample" and it ships no raw strings, so the sweep sees everything — low risk, but a gate | Verify after import |

Unaffected: the engine scans (`hashValue`, ambient identity, UI imports) are scoped to
`Sources/FootballSimCore` and never see imported UI code.

## Verification

**Nothing in this phase can be compiled here.** Re-confirmed: no `swift`, no `xcodebuild`, egress to
`download.swift.org` refused (403), and **no CI exists in the repository**, so the first compile is
the owner's. Per `CLAUDE.md` this is recorded, never claimed, and the phase gate that depends on a
build is an escalation rather than a judgement call.

Run here before pushing, each an exact replica of a suite's logic against the real files:

- the **token-sync assertion** — every `0x……` in `DesignTokens.swift` appears as `#……` in `04`;
- the **symbol-register parser** — every `systemName:` string against §6.6's parsed classes (this is
  what found the `chevron.*` defect);
- the **sheet-ratio lint** across all ten v4 sheets, so a palette edit cannot desync canon;
- a **brace/paren balance and import sweep** over every new file. Floodlit's own author found three
  compile errors this way and says so plainly; it catches structure, never types.

`docs/STATUS.md` records the phase as **unverified — never compiled**, naming every file.

On the owner's Mac: `./scripts/verify.sh` (build, then the no-argument suite — it does **not**
forward flags; focused gates are `swift run -c release SimTests --core-contracts` and
`--design-contracts`). Baseline: **719 tests / 755,310 checks**, last measured 2026-08-13 and now
stale by 25 commits.

## Risks, stated rather than discovered later

1. **~1,377 lines of never-compiled SwiftUI plus ~19 new types in one landing, with no CI.** The
   largest uncompiled surface this project has taken at once — the owner's explicit choice, and the
   right call for round-trip cost, but a systematic mistake repeats everywhere before anything
   catches it.
2. **`PitchPlane(perspective: 0.55)` has never rendered.** The author states CSS `perspective: 620px`
   and SwiftUI's parameter are different units and that this value is an estimate.
3. **Blur cost is unmeasured.** Stacked `.ultraThinMaterial` over a 3D-transformed plane is the
   heaviest thing in the package; P13's 16.7 ms ceiling is untested. §6.1's two-material budget is
   the mitigation.
4. **Type sizes were tuned against Arial Narrow**, not SF Pro condensed — the author expects a pass.
5. **Recruiting Board has no Floodlit design** (correction 1). A Phase 3 problem, surfaced now.
