# Owner walkthrough — first run on a simulator, then on a phone

**Written 2026-08-13, on branch `claude/road-to-beta-plan-40e904`.** It closes V-6 in
`docs/plans/2026-08-12-road-to-beta.md`.

**What an agent may claim, and what it may not.** Everything in §1–§3 was run in this session on
Xcode 26.6 / Swift 6.3.3 against the iPhone 17 simulator (iOS 26.5), and the screenshots described
are what that run produced. **Nothing here has run on a phone.** §4 is the part only the owner can
do, because it needs an Apple Developer account, and no agent may claim any of it happened.

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

**Things worth your eye that are not defects to file yet:**

- The world strip is grey rather than programme-coloured. `CoachWorldTeamIdentity` returns nil when
  no palette ink reaches 4.5:1 on the generated primary, and the honest fallback is neutral
  furniture. If most programmes look grey, that is **U-7** (light-primary colours unreachable from
  the generator) showing up on the glass, not a view bug.
- **Continue** advances a week only once the due decisions are resolved; `IntentResolver` refuses
  `.advanceWeek` while any is open, and the refusal is shown verbatim rather than swallowed.
- Tapping through to Team / Recruit / League / Career reports "not available yet". Those families
  have no production view — U-6, the largest remaining item.

## 4. Owner-only: signing and TestFlight (B-2)

No agent can do any of this, and none of it has been done.

1. In Xcode, open `App/ProFootballCoach.xcodeproj`, select the **ProFootballCoach** target →
   **Signing & Capabilities**, and set your team. The bundle identifier is already
   `com.ericmg.ProFootballCoach`.
2. Register the identifier in App Store Connect and create the app record.
3. Select your phone as the destination and **Run**. That is the first time this software has been
   on hardware.
4. **Measure before you enjoy it (B-4).** D4 budgets a week advance at 2.0 s and a frame at 16.7 ms,
   and both are unmeasured on any device. Advance five weeks and time them; if a week takes longer
   than two seconds on your phone, that is the D4 falsifier firing and it should be recorded before
   any beta rather than discovered during one.
5. Archive → Distribute → TestFlight.

**Save size and latency, so it is not a surprise.** A season-1 save is small, but D-3 measured
12.53 s to encode at season 30 and the app autosaves after every intent. A long career on a phone
will feel that. It is a known open item, not a regression to report.
