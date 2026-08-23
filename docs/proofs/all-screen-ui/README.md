# All-screen UI proof matrix

Evidence for the all-screen migration: every canonical destination rendered at the install floor, in
both content sizes, with what each screen actually showed recorded rather than assumed.

**This ledger is generated from the PNGs in these directories, not written by hand.** A ledger that
claims a capture the repository does not hold is worse than no ledger, and the capture status below
is whatever the directories contain at the time it was regenerated.

## What a proof records

Each filename is `screen-NN-<size>-<branch>.jpg`. The **branch** is the point: a canonical
destination may legitimately render either its identity stamp or an honest unavailable state, and a
proof that does not say which one it saw has evidenced neither. That was not a hypothetical -- the
Pro Management family passed its proof with all five screens reporting `unavailable`, exercising
none of the stamps the task had just added, and the branch record is what exposed it.

- `stamped` -- the screen rendered exactly one `canonical-screen-<id>` marker and no other
  destination's.
- `unavailable` -- the screen had no retained evidence to show and said so, rather than rendering an
  empty shell.

**Format: full-resolution JPEG, not PNG.** As PNG this matrix is **209 MB** -- it would more than
double a repository that already carries about 178 MB tracked, 89% of it under `Sources`. At quality
82 and unchanged pixel dimensions it is **21 MB**, a tenfold reduction with no visible loss: the
9-point micro labels, the tabular figures and the hairline rules all survive, which was checked by
comparing a converted frame against its original rather than assumed. Resolution was kept and
compression spent instead, because the thing a reviewer needs from these images is small type.

## Environment

| | |
|---|---|
| Host | macOS 26.5.1, Xcode 26.6 |
| Simulator runtime | iOS 26.5 (23F77) |
| Install floor | iPhone 17e, 844 x 390 pt |
| Promise floor / ceiling | iPhone 17 Pro 852 x 393, iPhone 17 Pro Max 956 x 440 |
| Career fixture | `PROOF_NEW_CAREER=424242`, DEBUG-only |
| Register | dark only -- Floodlit has no light appearance (`04` 6.1a, 6.1d) |

## Commands

Content size is set on the simulator, not by launch argument. A launch argument was tried first and
does not drive `dynamicTypeSize`; the app now renders an `ax-reflow` marker only on its accessibility
branch, and every AX5 test asserts that marker before doing anything else, so a run at the wrong size
fails loudly instead of reporting green.

```bash
xcrun simctl ui <udid> content_size large
xcrun simctl ui <udid> content_size accessibility-extra-extra-extra-large

xcodebuild test -project App/ProFootballCoach.xcodeproj -scheme ProFootballCoach \
  -destination "platform=iOS Simulator,id=<udid>" \
  -resultBundlePath <bundle> \
  -only-testing:ProFootballCoachUITests/ProFootballCoachUITests/<familyTest>

xcrun xcresulttool export attachments --path <bundle> --output-path <dir>
```

## Automated evidence

**44 of 47 canonical destinations captured at 844 x 390 default, 44 of 47 at AX5.**

Every retained PNG is landscape: 0 portrait files out of 88. Pixel sizes present: 2532x1170 (844 x 390 pt at 3x).

| ID | Family | 844 default | 844 AX5 |
|---|---|---|---|
| 1 | Entry | **not captured** | **not captured** |
| 2 | Entry | **not captured** | **not captured** |
| 6 | Entry | **not captured** | **not captured** |
| 7 | League | stamped | stamped |
| 8 | This week | stamped | stamped |
| 9 | This week | stamped | stamped |
| 10 | This week | stamped | stamped |
| 11 | This week | stamped | stamped |
| 12 | This week | stamped | stamped |
| 13 | This week | stamped | stamped |
| 14 | This week | unavailable-production-route | unavailable-production-route |
| 15 | This week | unavailable | unavailable |
| 16 | Personnel | stamped | stamped |
| 17 | Personnel | stamped | stamped |
| 18 | Personnel | stamped | stamped |
| 19 | Personnel | stamped | stamped |
| 20 | Personnel | stamped | stamped |
| 24 | Recruiting | stamped | stamped |
| 25 | Recruiting | stamped | stamped |
| 26 | Recruiting | stamped | stamped |
| 27 | Recruiting | stamped | stamped |
| 28 | Recruiting | stamped | stamped |
| 29 | Recruiting | stamped | stamped |
| 34 | Pro management | unavailable | unavailable |
| 35 | Pro management | unavailable | unavailable |
| 36 | Pro management | unavailable | unavailable |
| 39 | Pro management | unavailable | unavailable |
| 41 | League | stamped | stamped |
| 42 | League | stamped | stamped |
| 43 | League | stamped | stamped |
| 44 | League | stamped | stamped |
| 45 | League | stamped | stamped |
| 46 | League | stamped | stamped |
| 47 | This week | unavailable | unavailable |
| 48 | League | stamped | stamped |
| 49 | League | stamped | stamped |
| 50 | League | stamped | stamped |
| 51 | League | stamped | stamped |
| 52 | Career | stamped | stamped |
| 54 | Career | stamped | stamped |
| 55 | Career | stamped | stamped |
| 57 | Career | stamped | stamped |
| 58 | Career | stamped | stamped |
| 59 | Career | stamped | stamped |
| 60 | Career | stamped | stamped |
| 61 | Recruiting | stamped | stamped |
| 62 | Pro management | unavailable | unavailable |

**Entry 1, 2 and 6 are absent and cannot be captured by this harness.** It reaches a screen by
starting a career and overriding the route, so it can never stand at Title, at New Career, or at
pre-career Settings. Their stamps are written and compiled; their identity is unverified.

**Screen 14's capture is the production route, and it is labelled as such.**
`screen-14-*-unavailable-production-route.jpg` is Match Day reached through `PROOF_SCREEN_NUMBER=14`
at week 1, where no game has been played and the screen says so honestly. That is *not* the same
screen the weekly command proof asserts against: that test special-cases 14 through
`PROOF_SCREEN=match`, the recorded-match proof root, which is where the 22 actors and the five
controls live. Two different screens under one id, so the capture keeps its own label rather than
borrowing the proof root's.

A companion capture of the match proof root was attempted and **is not present** -- `simctl` stopped
responding on this host after the two full passes. Match Day's rendered content is not thereby
unproved: `testMatchDayExportsDistinctFieldLandmarksAt{Default,AX5}` and the weekly command family
proof both assert it, and both pass. What is missing is an image, not a verification. Regenerate it
with:

```bash
SIMCTL_CHILD_PROOF_SCREEN=match xcrun simctl launch --terminate-running-process <udid> com.ericmg.ProFootballCoach
xcrun simctl io <udid> screenshot screen-14-844-default-match-proof-root.jpg && sips -r 270 <file>
```

## Manual-required -- not performed, and an agent may never mark these done

Per `04b` section 6. Each needs a person to record device, OS, tester and result:

| Check | Status |
|---|---|
| VoiceOver spoken clarity and reading order | manual-required |
| Voice Control addressability by visible label | manual-required |
| Switch Control reachability of committing actions | manual-required |
| Sound and haptic equivalents | manual-required |
| Physical-device rendering and performance | manual-required |

The walkthrough script is `docs/proofs/2026-08-23-all-screen-owner-walkthrough.md`.

## Known gaps in this matrix

- **Pro Management (34, 35, 36, 39, 62) and Entry (1, 2, 6) cannot be captured as stamped.** The
  harness starts a career and overrides the route, so it can neither reach the pro tier -- starting
  jobs are college-only by design -- nor stand anywhere before a career exists. Their stamps are
  written and compiled and are *not* proved. One debug seam that can place the app in a chosen tier
  or a pre-career state would close both.
- **Increase Contrast renders identically.** No source file reads `colorSchemeContrast`, so the
  setting changes nothing. Capturing it would produce a duplicate image and imply a check that does
  not exist.
- **956 x 440 representatives are captured; 852 x 393 are not.**
  `family-representatives/screen-NN-956-default.jpg` holds one destination per family -- 8, 16, 24,
  34, 41, 52 -- at 2868 x 1320, the ceiling window. The 852 set is missing because CoreSimulator on
  this host degraded repeatedly during the run (`simctl install` and `simctl boot` hanging, devices
  stuck in `Booting`), not because the layout was not exercised.

  A correction worth carrying: **iPhone 17 Pro is 402 x 874, not 393 x 852.** The promise floor
  needs a 15 or 16 Pro; `PFC Task 6 iPhone 15 Pro` measures 1179 x 2556, which is the right device.
  Six frames were nearly written from the 17 Pro under an `852` filename before that was checked --
  they would have been correctly captured evidence with a wrong label, which is worse than no
  evidence. Regenerate with one simulator booted at a time:

  ```bash
  xcrun simctl boot 54626BB2-491E-4758-BEE7-A3355E3D7BBF   # 393 x 852
  SIMCTL_CHILD_PROOF_NEW_CAREER=424242 SIMCTL_CHILD_PROOF_SCREEN_NUMBER=<id> \
    xcrun simctl launch --terminate-running-process <udid> com.ericmg.ProFootballCoach
  xcrun simctl io <udid> screenshot out.png && sips -r 270 out.png
  ```
