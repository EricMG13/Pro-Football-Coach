# Pre-Deployment Checklist

Worked to completion in P14. **Authored here — no such file existed in this repo before.**

Two columns of ownership, and they are not interchangeable. **Machine** items an agent asserts by
running something. **Owner** items require a device, an Apple account, or a human judgement, and an
agent hands them over rather than claiming them.

---

## 1. Correctness — machine

- [ ] `swift build` clean, zero warnings in first-party code
- [ ] `swift run -c release SimTests` exits zero; pass count and assertion count recorded in `STATUS.md`
- [ ] **Zero files listed as unverified in `STATUS.md`.** Nothing ships that has never been compiled
- [ ] All pro calibration bands green
- [ ] All college calibration bands green, including blowout frequency
- [ ] Detailed vs abstract KS consistency gate green at α = 0.01
- [ ] Cross-process determinism fixture green
- [ ] 20-season soak green, including at least one promotion and one firing
- [ ] Every standing invariant I1–I11 asserted and green
- [ ] AI: `noRubberBanding`, `difficultyDoesNotTouchRatings`, exploit-resistance all green

## 2. Legal — machine, then human

- [ ] `nameCollisionTest` green across 200 seeds, both tiers
- [ ] `tradeDressTest` green at the recorded ΔE2000 threshold
- [ ] Blocklist coverage reviewed by hand — **no test can prove a blocklist complete**
- [ ] **Owner:** every visible string, mark, colour pair and conference name reviewed for
      resemblance to a real identity
- [ ] **Owner:** store listing, screenshots, keywords and trailer contain no real league, programme
      or player reference, and no wink at one
- [ ] **Owner:** no bundled roster file, no importer aimed at real identities
- [ ] Third-party dependency count is **zero** — verified from `Package.swift`
- [ ] No code derived from any CC-NonCommercial or otherwise restricted source
- [ ] Calibration band sources recorded next to each band, with the licensing posture from
      `01-RESEARCH.md` §6.4 satisfied
- [ ] **Owner:** anything flagged borderline has been to counsel, or has been consciously accepted

## 3. Performance — machine, verified on device

- [ ] Week advance, college: ≤800 ms on the reference device
- [ ] Week advance, pro: ≤250 ms
- [ ] Full-season sim, college: ≤25 s
- [ ] Match render: ≤8 ms/frame at 22 entities
- [ ] Save write: ≤100 ms, **off the main actor**, one write per user action asserted
- [ ] Save size at season 20: ≤10 MB
- [ ] Cold launch to menu: ≤1.5 s
- [ ] **Owner:** measured on a real device, not a simulator, and the device named in `STATUS.md`

## 4. The season budget — owner

The product's central promise (P4), and it cannot be asserted headlessly.

- [ ] A full season played end to end with a stopwatch running
- [ ] Total inside **6–8 hours**
- [ ] Per-week wall-clock recorded; college weeks inside ~18 min
- [ ] Match wall-clock at default fidelity inside ~7.5 min
- [ ] **≥5 meaningful decisions per in-season week**, counted the way `01-RESEARCH.md` §6.0a counts them
- [ ] Attention did not drop before week 4 — and if it did, **where** is written down

## 5. Accessibility — machine, then device

- [ ] Every D12 contract test green and **coverage-complete**
- [ ] `contrastAllTokens`: every token × every surface × both themes, no unasserted pair
- [ ] `reduceMotionCoverage`: every animation motion-aware, zero exceptions
- [ ] `touchTargetFloor`, `noFixedWidthAroundScalingText`, `noSystemSizeLiterals` green
- [ ] **Owner, on device:** VoiceOver walkthrough of a complete match, start to finish, without sight
- [ ] **Owner, on device:** Reduce Motion on — the match is playable and pleasant, not merely functional
- [ ] **Owner, on device:** XXXL Dynamic Type across every screen, no truncation or overlap
- [ ] **Owner:** smallest and largest supported iPhones both walked

## 6. Platform and store — owner

- [ ] Portrait-only, iPhone-only declared and behaving
- [ ] Large titles only at top level; Cancel in the leading slot everywhere; every modal has an exit
- [ ] Full `/impeccable audit`-equivalent: **≥17/20, zero P0/P1, app-wide**
- [ ] Privacy nutrition label: **no data collected** — true, and verified by the absence of any
      network code
- [ ] `Info.plist` free of unused permission strings
- [ ] App icon, launch screen, name, subtitle and description final
- [ ] Age rating completed honestly, including the absence of real gambling framing on any
      spread-style presentation
- [ ] Support URL and privacy policy live
- [ ] Version and build numbers set; release notes written

## 7. Durability — the competitive set's weakest point, and ours to win

- [ ] Save/load round-trips at seasons 1, 5, 10 and 20
- [ ] Rolling backup recovers from a deliberately corrupted primary save
- [ ] A newer-format save is **refused with a clear message**, never opened and mangled
- [ ] An older-format save opens, via fixture, for every shipped version
- [ ] Force-quit mid-week loses at most the current action
- [ ] Low-storage and background-termination paths exercised
- [ ] **No dead ends**: `soakCarouselNeverDeadEnds` green, and spot-checked by hand at a save where
      the coach has just been fired

## 8. Release — owner

- [ ] TestFlight build distributed and installed from the store listing, not from Xcode
- [ ] A fresh install walked by someone who has never seen the game
- [ ] `STATUS.md` reflects reality, including anything knowingly shipped imperfect
- [ ] Every open item in `OPEN-DECISIONS.md` is either resolved or consciously carried, in writing
- [ ] The walkthrough script from `08-OPUS5-BUILD-PROMPT.md` has been run in full, on device, and
      every step behaved as written

---

## The rule this checklist exists to enforce

**An agent may tick a Machine box only by running the thing.** Not by reading the code and judging it
likely to pass, not on the strength of an adversarial review, and not because the test was written
in the same commit. Where the toolchain was absent, the box stays unticked and the item moves to the
owner's column with a note saying why.

The prior build shipped a phase that had never been near a compiler, honestly labelled, and that
label is the only reason anyone knows. Keep that habit.
