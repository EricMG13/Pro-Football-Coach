# Pre-Deployment Checklist

Everything that must be true before the rebuild ships to TestFlight. Regenerated for the rebuild — the previous checklist tracked v1's outstanding defects and is superseded; items still outstanding are carried forward below.

Distribution is TestFlight and personal use (`PRODUCT.md`), so nothing here is written to App Review, store metadata, age ratings, or screenshots.

---

## A. Blocking — the run stops

- [ ] **`swift build` green** on the shipping toolchain.
- [ ] **`swift run SimTests` green**, all suites, self-registered (no suite exists that the runner never calls).
- [x] **Suite green in release.** `swift run -c release SimTests` — 324 tests, 18,631 checks, all passed (2026-08-09). Includes Phase 4C's full arcade suite.
- [x] **Performance tests guard their build configuration.** `SeasonTests.swift` measures in both configurations and asserts only in release.
- [ ] **Re-run on every phase close.** The number above is a point-in-time result, not a standing guarantee.
- [ ] **The week-advance budget measured on an A15**, not inferred. `03-ARCHITECTURE.md` §6.6 states the target; nobody has verified it on device.
- [ ] **Both source scanners green**, each with its planted-offender self-test: no `.hashValue` seeding, no `UUID()`/`Date()` as argument or assignment in `Engine/`/`Generation/`.
- [ ] **No unresolved blocking item in `docs/OPEN-DECISIONS.md`.**

## B. Engine acceptance (`03-ARCHITECTURE.md` §6)

- [ ] Determinism: same seed ⇒ byte-identical season; holds **across processes**, not just within one.
- [ ] Mode parity: `retainPlays` true vs false produces identical results.
- [ ] Narration determinism: the same save produces the same cards.
- [ ] All ten calibration bands (§6.2).
- [ ] All eight believability bands (§6.3), including the ratings-predictiveness test **with its ≥12 OVR gap asserted**, not merely printed.
- [ ] Cap invariants (§6.4): never illegal beyond the sanctioned dead-money overage, at the end of **every** season — asserted inside the soak loop, not after it.
- [ ] All four practice-squad laundering doors closed: demotion, release-after-demotion, call-up, re-signing/signing onto the flag.
- [ ] Ten-season soak (§6.5): ratings and ages stable, ≥12 distinct teams reach the top five, ≥3 champions, cap grows, save round-trips byte-identically and stays <5 MB, pools bounded.
- [ ] Soak witness assertions: zero silent weeks, hook horizon populated in ≥95% of weeks, no card without a face and a cause, no template repeating within 10 weeks on standout events.
- [ ] Soak P6 assertion: the seed forces a firing; every fired or expired path yields an offer or a sit-out arc **and** a chapter card.
- [ ] End-of-game state machine exhaustive: 0:00 edge cases, kneel-outs, untimed downs after a defensive penalty, OT caps, touchdown as time expires still awarding the try.
- [ ] Coach tenure across seasons: contract clock advances once (not twice), the trophy case follows the man not the employer, the firing toggle blocks calendar eviction too.

## C. Witness layer (the rebuild's thesis)

- [ ] **P2 state-to-witness matrix passes** — every player-visible mutation (cap, morale, development, job security, records, roster and contract status) emits an event. Not "every EventKind has a template," which is circular.
- [ ] Every card carries a face, a headline number, and a consequence line.
- [ ] Blocking cards appear only for deadline-semantics decisions.
- [ ] The five broadcast slots all produce output, including The Weekly for games the player never touched.
- [ ] Simulated-phase receipts: every defensive drive and every AI game can show why it went the way it did.

## D. Feel and design system

- [ ] Staging gate: every moment in `DESIGN.md` §2.3 has a spec; each hero surface has a stated first render; the table and the surface list are in sync by test.
- [ ] Reduce Motion: every named motion has its variant; the director reads `UIAccessibility`, not `@Environment`; a test flips the flag and asserts the variant is chosen.
- [ ] Haptics and sound: single owner fires each event; user toggles exist for both; sounds respect the silent switch; neither channel is ever the sole carrier of state.
- [ ] `fanfare` and `.championship` fire for tier 4 only.
- [ ] Contrast coverage law: every token pairing is tested against its real composited surface in both themes, and an untested pairing fails the build.
- [ ] All 32 club primaries clear 4.5:1 against white; every secondary clears its own primary.

## E. Platform physics

- [ ] Dynamic Type XXXL on every screen: no truncation, no overlap, number gutters widen.
- [ ] 44×44pt minimum on every tappable element, both dimensions; ≥8pt between adjacent targets.
- [ ] No state conveyed by colour alone.
- [ ] VoiceOver: stat rows read as sentences; staged reveals announce; custom meters expose label and value; the arcade is playable end-to-end via its assistive control path.
- [ ] Portrait locked app-wide (the all-22 field is vertical; nothing rotates).
- [ ] No main-actor file I/O; a failed write surfaces to the user; long operations show progress (`isBusy` is wired, not declared and abandoned).

## F. Performance and durability

- [ ] Sim-only week <150 ms on the dev Mac; per-game assertion <9 ms in CI.
- [ ] Week advance end-to-end **measured on an A15** and inside its stated budget.
- [ ] Session budgets timed by walkthrough: fast session ≤3 min one-handed, played game ≤8 min, interstitial ≤1 min, gameplan ≤60 s.
- [ ] 60 fps on an A15 during arcade play.
- [ ] Save <5 MB after ten seasons; rolling backup recovers a corrupted primary; migration fixtures exist for every format version; an older save still opens.

## G. Content and legal

- [ ] Every team, city pairing, player name, college, broadcast identity, and mark is fictional and original.
- [ ] No string, asset, layout, or line of source traceable to any reference app; the CC-NonCommercial ancestor was never read.
- [ ] No duplicate full names in a generated league.
- [ ] Copy follows the two-voice rule: system voice plainspoken with no exclamation marks; press voices characterful and clearly attributed.
- [ ] No lorem ipsum, no placeholder strings, no TODO text visible to a player.

## H. Ship gates

- [ ] Definition of done demonstrated on device: wizard → full season → full offseason → season two, both appearances.
- [ ] `/impeccable audit` ≥17/20 with zero P0/P1 across the app.
- [ ] Cold-play hour on the finished build: it is fun, and it pulls.
- [ ] Parity ledger clean — nothing v1 shipped has silently disappeared (`07-SALVAGE.md`).
- [ ] Every phase gate in `05-IMPLEMENTATION-PLAN.md` green.

---

## Carried forward from v1 (unresolved when the rebuild began)

Recorded so they are not lost; each is superseded if its surface is rebuilt.

- [ ] Two clubs can draw the same motif — seven shapes across 32 clubs, so collisions are expected and colour is the only distinguisher.
- [ ] The arcade's carrier/decision windows are unvalidated guesses; only device play with a real thumb settles them.
