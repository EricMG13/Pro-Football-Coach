# Owner walkthrough — first run on a simulator, then on a phone

**Written 2026-08-13, on branch `claude/road-to-beta-plan-40e904`.** It closes V-6 in
`docs/plans/2026-08-12-road-to-beta.md`.

**What an agent may claim, and what it may not.** Everything in §1–§3 was run in this session on
Xcode 26.6 / Swift 6.3.3 against the iPhone 17 simulator (iOS 26.5), and the screenshots described
are what that run produced. **Nothing here has run on a phone.** §4 is the part only the owner can
do, because it needs an Apple Developer account, and no agent may claim any of it happened.

**§3a is different again, and the difference matters.** It was added 2026-08-19 by a session with
no `swift` and no `xcodebuild` at all. **None of it has been run** — not the commands, not the
simulator steps. Every expected result in it is a prediction to check, not something observed.

---

## 1. Build it

```bash
cd App && xcodegen generate
```

```bash
xcodebuild -project App/ProFootballCoach.xcodeproj -scheme ProFootballCoach -configuration Release -destination 'platform=iOS Simulator,name=iPhone 17' build
```

**Expected: `** BUILD SUCCEEDED **`.** This is the answer to B-1, which the plan named the single
largest unknown in the document: the package now builds as an `.app`. The device slice compiles too
— `-destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO` also succeeds — so the only thing
between this and a phone is signing, which is §4.

## 2. Run it

```bash
xcrun simctl boot 'iPhone 17'; open -a Simulator
```

```bash
xcrun simctl install 'iPhone 17' "$(xcodebuild -project App/ProFootballCoach.xcodeproj -scheme ProFootballCoach -configuration Release -showBuildSettings 2>/dev/null | awk -F' = ' '/ BUILT_PRODUCTS_DIR/{print $2}')/ProFootballCoach.app"
```

```bash
xcrun simctl launch 'iPhone 17' com.ericmg.ProFootballCoach
```

**Rotate the simulator to landscape** (`Cmd+←`). The app is landscape-only by declaration, so in a
portrait window the content is rendered sideways rather than re-laid-out.

## 3. What to look at, and what is deliberately blank

**Title.** "Pro Football Coach" and a **New career** button. Before this session a RELEASE build
reached `ContentUnavailableView` — "No career loaded" — and nothing else; that was B-3/G-01.

**Tap New career.** It generates the world from a fixed seed (`CoachWorldStore.defaultSeed`,
20 260 812) — fixed on purpose so every tester plays the same world and a report about week 4 is
reproducible. Generation runs off the main actor; the title screen stays live while it works.

**Coaching HQ.** In this session's run the world produced:

| Surface | Value | Where it comes from |
|---|---|---|
| Programme | Marrow Hollow Normal | lowest-prestige programme in the generated league |
| Coach | Kelay Tarrford | that programme's generated head coach |
| Context | Season 1 · Week 1 · 0–0 · #122 | calendar, standings row, rankings index |
| Opponent / venue | Calder Mining · Marrow Hollow Grounds | this week's scheduled game and its home identity |
| Decision | Redshirt: Daryn Wickwick, evidence "Playing time: 0" | a queued mandatory decision and its own reason codes |
| Desk | 3 due | mandatory decisions for this programme |

**Three regions are blank, and each is blank on purpose.** `04` §4.4 requires a surface without
engine backing to ship without the claim rather than with an invented one:

- **The week strip** has no days. The calendar's finest grain is a week, so a seven-day plan is not
  a thing the engine knows. G-14 closes it.
- **Your Desk** lists the opponent but carries no correspondence. There is no inbox system; the
  scheduler's own `expiringInboundEvents` step is marked inactive to say so.
- **No staff recommendation** appears. A recommendation needs a verdict, a reason *and* a
  confidence; the root holds a recommended option and reason codes but no confidence, so
  three-quarters of it would be invented. G-02 closes it.

`--screen-read-models` asserts each of those blanks, so filling one in future requires deleting an
assertion that names the register item which justifies it.

**Tap Team.** The Roster is truthful too: 105/105, injuries, open needs, class balance, and a row per
player with number, position, overall, development, scheme fit, condition and availability — all of
it out of the root. Selecting a row fills the dossier beside it. Three fields there are blank on
purpose: no hometown (the root records where a *prospect* came from, not where a rostered player
grew up), no staff summary (G-02), no recent form (G-04).

Numbers are derived per roster, unique **within a unit** — a 105-man roster does not fit in 100
numbers, and two players who are never on the field together may share one. `#0` on a defensive back
is legal, not a bug.

**Tap Recruit.** The board is truthful: `SLOTS`, `HOURS` and `VISITS` are all real. `HOURS` is the
engine's own weekly contact-points pool (100, reset every week), and `VISITS` is that pool divided
by what a visit costs — the engine tracks one shared resource, not two. Committing a `Contact` or
`Evaluate` choice spends against it and the number moves. At week one the board itself is empty
("No prospects on the board"), which is correct — the AI recruiting cycle populates it as the
season runs, not at kickoff.

**Tap anything else — League, Career, Depth.** Each reports "… is not available yet". That
is deliberate: an empty screen would claim the family exists.

**Things worth your eye that are not defects to file yet:**

- **The colours.** Coaching HQ's world strip is neutral and the Roster's is the programme's primary,
  and both are correct: `04` §5 gives programme colour the world-strip field and forbids a colour
  wash on management panels. What the Roster shows is whatever the generator drew — in the default
  seed that is a hot magenta. If most programmes look either garish or grey, that is **U-7**
  (light-primary colours unreachable from the generator) landing on the glass, not a view bug.
  Judge the generator, not the screen.
- **Continue** advances a week only once the due decisions are resolved; `IntentResolver` refuses
  `.advanceWeek` while any is open, and the refusal is shown verbatim rather than swallowed.
- Tapping through to Team / Recruit / League / Career reports "not available yet". Those families
  have no production view — U-6, the largest remaining item.

## 3a. The install floor, and `SmallestDeviceLayoutTest` (added 2026-08-19, not run)

`SmallestDeviceLayoutTest` is D15's first falsifier and `04` §7's two-tier gate. Until 2026-08-19 it
was registered in `SuiteCatalog` with `runner == nil`, so `--catalog` printed `MISSING RUNNER` for it
and `runCommitmentCoverageTest` failed on "registered without a runnable command" — one of the seven
failed checks CI was carrying. The runner is `Tests/SimTests/Suites/SmallestDeviceLayoutTests.swift`.

### The compiler, ordered by how fast it fails

Do not open with `./scripts/verify.sh`. The full lane is roughly 36 minutes, and a syntax error costs
all of it before saying so.

```bash
swift build -Xswiftc -enable-testing
```

**Expected: it compiles.** This is the step that has never been done — see the preamble. If it fails,
everything below is moot.

```bash
swift run -Xswiftc -enable-testing SimTests --smallest-device-layout
```

**Expected: `[ok  ] Smallest device layout — 10 tests`**, printing one
`Smallest device layout: N landed, M pending at 844 x 390` line.

```bash
swift run -Xswiftc -enable-testing SimTests --catalog | grep -i smallest
```

**Expected:** a row ending
`--smallest-device-layout → runSmallestDeviceLayoutTests`, **not** `MISSING RUNNER`.

```bash
swift run -Xswiftc -enable-testing SimTests --commitment-coverage
```

**Expected: six failed checks, not seven.** The `SmallestDeviceLayoutTest is registered without a
runnable command` line is gone; `AgencyBudgetTests`, `PerformanceBudgetTests` and
`TwoTierConsistencyTests` remain at both `SuiteCatalog.swift:128` and `:143`. This suite still fails,
by design — three gates are still unbuilt, and `AgencyBudgetTests` cannot be made truthful before
D1's timing protocol runs, because its constants are proposals rather than measurements.

```bash
./scripts/verify.sh --lane accessibility     # the lane SuiteCatalog declares for this gate
./scripts/verify.sh                          # the CI equivalent, ~36 min
```

### What the suite checks, and what only the simulator can

The suite asserts that the frame and stage tokens every chromed surface is laid out from fit inside
both floors, clear the sensor housing and the home indicator, and that no floor dimension is
re-typed as a literal away from its declaration.

It does **not** assert that anything renders un-clipped or that controls are reachable. Those are
properties of a render, and `SimTests` is a headless executable with neither XCTest nor a view host;
`04` §7.1 already records that limit for G-12 and it applies here unchanged. **The rendered limb of
D15's falsifier stays open, and this section is how it closes.** An audit under `04b` may not treat
the suite as the rendered proof.

### Running it at both floors

§1–§2 target iPhone 17 — that is the ceiling of the design window. This gate needs the other end.

| Tier | Points, landscape | Device class | What red here means |
|---|---|---|---|
| Install floor | 844 x 390 | iPhone 16e, or 13/14 | Below-promise devices install anyway, so a clip here ships |
| Promise floor | 852 x 393 | iPhone 15 Pro class | The full budget must hold; D15 is falsified if it does not |

```bash
xcrun simctl list devicetypes | grep -iE "iPhone (16e|15 Pro|14|13)"
```

Pick a 390 x 844 device for tier one and a 393 x 852 device for tier two, then run §1 and §2's
build/install/launch with that name in place of `iPhone 17`, and `Cmd+←` for landscape:

```bash
DEVICE='iPhone 16e'   # then repeat the whole block with a 15 Pro-class device
xcodebuild -project App/ProFootballCoach.xcodeproj -scheme ProFootballCoach -configuration Release -destination "platform=iOS Simulator,name=$DEVICE" build
xcrun simctl boot "$DEVICE"; open -a Simulator
xcrun simctl install "$DEVICE" "$(xcodebuild -project App/ProFootballCoach.xcodeproj -scheme ProFootballCoach -configuration Release -showBuildSettings 2>/dev/null | awk -F' = ' '/ BUILT_PRODUCTS_DIR/{print $2}')/ProFootballCoach.app"
xcrun simctl launch "$DEVICE" com.ericmg.ProFootballCoach
```

**The three things to look at**, each the rendered form of an assertion the suite can only make as
arithmetic:

1. **The icon rail clears the sensor housing.** The rail sits at 59 pt, exactly the housing width.
   If it is drawn under the notch on the sensor side, the token is right and the safe-area ownership
   is not.
2. **The content column is not clipped at the trailing edge.** The band is
   `115 + 709 + 20 = 844`, exactly the floor. It has no slack at all, so anything that adds width
   clips rather than compresses.
3. **The bottom band clears the home indicator.** 25 pt against a 21 pt indicator, so 4 pt of
   clearance and no more.

Check both sensor orientations — rotate 180 degrees, not just into landscape. Safe areas are owned at
physical edges per `04` §7, so sensor-left and sensor-right are two different layouts.

Anything red here falsifies D15's chosen window, which is a decision to re-argue rather than a bug
to patch. Record it and stop; `docs/OPEN-DECISIONS.md` D15 is where it lands.

## 4. Owner-only: signing and TestFlight (B-2)

No agent can do any of this, and none of it has been done.

1. In Xcode, open `App/ProFootballCoach.xcodeproj`, select the **ProFootballCoach** target →
   **Signing & Capabilities**, and set your team. The bundle identifier is already
   `com.ericmg.ProFootballCoach`.
2. Register the identifier in App Store Connect and create the app record.
3. Select your phone as the destination and **Run**. That is the first time this software has been
   on hardware.
4. **Expect the week advance to be slow, because it already is here.** This is not a device
   question any more: `--week-advance-timing` measured a **median 2.83 s per week** on a
   development Mac against D4's **2.0 s** budget, with the season-boundary week at **29.6 s**. Your
   phone will be worse. Time five weeks anyway so the device number exists, but treat D4 as already
   falsified rather than as something the beta might discover. Frame time (16.7 ms) still needs a
   device and Instruments and has never been measured.
5. Archive → Distribute → TestFlight.

**Save size and latency, so it is not a surprise.** A season-1 save is small, but D-3 measured
12.53 s to encode at season 30 and the app autosaves after every intent. A long career on a phone
will feel that. It is a known open item, not a regression to report.
