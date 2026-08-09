# PRODUCT

Product truth: who this is for, what it is, what it will not be. Gameplay canon is
`docs/02-GAME-DESIGN.md`; the evidence behind everything here is `docs/01-RESEARCH.md`.

---

## 1. The product in one sentence

> A native iPhone career simulator where you coach a football programme from a college job nobody
> wants to the pro league, one save, one career — and where **the week between games is the game**.

---

## 2. Who it is for

**Primary — the coach-sim player who has no phone to play on.** They play Football Coach: College
Dynasty, Draft Day Sports or Front Office Football on a desktop, or the one good college sim on iOS.
They want depth, believable outcomes and a career that accumulates. They are not asking for
joystick control — the reference app's community, mined across 395 posts and 1,312 comments, asked
for *coach-brain control, speed options and trustworthy outcomes*, and **nobody requested arcade
play** (`01-RESEARCH.md` §H).

**Secondary — the Football Manager player who likes American football.** They already accept that
the manager genre is menu-driven and watched, and they will recognise the loop instantly. What they
will not accept is a match they cannot affect.

**Not the target:** the Retro Bowl audience. That is a much larger, much more casual market, it
wants direct control, and this product does not offer it. Chasing both produces a game that is
second-best at each.

---

## 3. Positioning — the gap, argued

Argued in full at `01-RESEARCH.md` §6.3. The short version, with each clause carrying its evidence:

| Claim | Evidence |
|---|---|
| **The mobile lane is empty on the pro side** | Every credible modern competitor — DDS, FC:CD, FOF, Pro Football Dynasty — is Windows desktop. The pro-side mobile entries were abandoned in 2019 |
| **The genre's best game is criticised for having too few in-game decisions** | FC:CD sits at ~95% positive and its negative reviews say it reads as a *recruiting* simulator with "pretty limited in-game decisions" |
| **The same defect is measurable in our own prior build** | Its in-season week offered **one** branching decision: how to watch the game |
| **The reliability bar is on the floor** | 34% of the reference app's reviews concern crashes, save corruption around season 8 and softlocks — users buy checkpoint tokens as crash insurance. DDS's own forum leads with crashes and freezes |
| **Nobody spans college and pro in one save** | FC:CD is college-only; DDS ships two separate products; Pro Football Dynasty offers a college-save *import* — the seam this design removes |

**So the product is:** dense in-season weeks · a match you watch at your own speed and steer from the
sideline · one career across both tiers · and **it does not break**.

That last clause is the cheapest to win and the most valuable. It is not invention, it is
engineering discipline, and it is where the competitive set is weakest.

---

## 4. What makes it good, and what would make it fail

**The four mechanisms engagement actually comes from** (§6.1 — none of them is "depth"):

1. **Jeopardy** — the match can go wrong while you watch, and you can do something about it.
2. **Ownership** — you developed that player from a two-star; he is *yours*.
3. **Emergent narrative** — a career that writes its own history and brings it up later.
4. **Information asymmetry** — scouting, fog, tendencies. Knowing something the AI doesn't, and
   sometimes being wrong.

Depth is the substrate these run on, not a substitute for them.

**The failure mode, named so it can be watched for:** *a better-looking bland application.* A
beautiful, deep, deterministic simulation with an empty Tuesday. The prior build had 224 tests, a
full salary cap and a ten-season soak that held, and it still felt like an app — because the depth
was almost all in the offseason. Every design decision in `02` is checked against this.

---

## 5. Constraints — settled, not open

| # | Constraint |
|---|---|
| P1 | iOS 17+, Swift, SwiftUI. **iPhone only, portrait only.** Offline. **Zero third-party dependencies.** The match is SwiftUI `Canvas` + `TimelineView` — no SpriteKit, no Metal |
| P2 | **Unified college→pro career.** One save, one coach. The promotion arc is a v1 feature |
| P3 | TestFlight → **paid premium** on the App Store. **No IAP, no ads, no subscriptions, no analytics, no accounts** |
| P4 | **A full season is completable in 6–8 hours.** Priced out in `02` §3 |
| P5 | Solo developer plus AI agents. **No playtest cohort, no QA, no telemetry** |

**What P3 and P5 cost, stated honestly.** No analytics means no behavioural data, ever — every
falsifier in `OPEN-DECISIONS.md` must therefore be a test the machine can run or a play session the
owner can run, and "we would notice if players disliked it" is not available as a fallback. No IAP
means the reference app's revenue model — God Mode, scenario packs, paid checkpoint tokens — is
closed to us. That is a deliberate trade: **paid checkpoint tokens are crash insurance sold to
players, and a product that does not corrupt saves does not need to sell it.**

---

## 6. Brand commitments

- **Everything is fictional and original.** No real league, programme, conference, stadium, player
  or coach identity, no real-name roster files, no importer aimed at them, no wink in the store
  listing. Two parts of this are enforced by tests — name collision and colour trade dress; the rest
  is a review checklist and is described as one.
- **Difficulty never lies.** Higher difficulty means the AI schemes better and adjusts faster. It
  never means opponents get better ratings than the ones displayed. The genre's most damaging
  complaint is "anti-upset cheese" — the sense of having been *decided against* — and it destroys
  trust in every number in the game.
- **One engine, one truth.** Watched, key-moments and instant games run the identical simulation. A
  test asserts that retaining the play-by-play cannot change a result. Where the reference app got
  this wrong, its community's meta became "watch your games to get good results", which is a
  simulation confessing it does not believe itself.
- **No dead ends.** A coach whose contract expires always has at least one offer or an explicit year
  out. This exact situation soft-locks saves in the reference app.
- **Saves do not corrupt.** Atomic writes, a rolling backup, migration fixtures, and a 20-season
  soak that asserts it.

---

## 7. Accessibility bar

Not an audit item — a **construction requirement with tests**, because the prior build wrote these
same commitments down and scored **1/4** against them. The full contract, with the test enforcing
each line, is `docs/04-UX-AND-DESIGN-SYSTEM.md` §3.

- 4.5:1 contrast for all text in both themes, **measured against the actual composited surface**
- Every screen survives Dynamic Type at XXXL without truncation or overlap
- Reduce Motion honoured on **every** animation — the match becomes stepped rather than animated,
  and stays fully playable that way
- 44pt minimum touch targets
- A box-score row reads as a sentence, not nine loose numbers
- **No gesture-only interaction anywhere.** Every intervention is a real, labelled button

The rule that makes this different from last time: **a test that asserts a property for some members
of a category must cover all of them, or name its exclusions at the assertion site.** The prior
build's contrast suite was rigorous and narrow, and its coverage boundary silently became the
quality boundary.

---

## 8. Scope

### v1

Both tiers, the promotion arc, the Sideline Model match with its fidelity controls, recruiting and
the portal and NIL, the full pro cap and draft and free agency and trades, staff, development, the
carousel, records and the hall of fame, rivalries that accumulate, three save slots, settings, and
the first-run experience described in `02` §9.

### Explicitly later

Ordered by likely demand. Each is out because it costs week-budget or scope, not because it is bad:

1. Custom league / roster JSON import-export — the community-content culture is real (§H rank 7) and
   the architecture stays ready for it
2. Coordinator-only career start (§H rank 5)
3. Press conferences and a reacting social feed (§H rank 10)
4. iPad and landscape
5. Commissioner / editor modes
6. More than three save slots

### Never

**Direct control of a player.** It is a Tier A constraint, not a backlog item. And on the evidence,
the previous build's arcade layer was not satisfying a demand for tactility — it was the only place
in the app where an input changed an outcome within ten seconds. It was **substituting for weekly
agency** (§6.0c). Fix the week and the substitute is not needed. Leave the week empty and no amount
of tactility will save it.
