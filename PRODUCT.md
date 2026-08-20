# Product

A unified college→pro football coaching career simulator for iPhone. One save, one coach: you start
in the college game and, if you earn it, you get promoted. You are never a player.

---

## Positioning

**A football management career you can still believe in after twenty seasons, on a phone.**

Not the deepest football sim — those exist on desktop and are better at depth than this will be. Not
the most immediate — Retro Bowl owns that and this game deliberately gives it up. What this is: the
one that stays *true* over a long career, on the device people actually have with them.

---

## The gap

Argued in `docs/01-RESEARCH.md` §6.3 from the competitive research, not assumed.

**It is not a category gap.** Every category slot in this market is occupied, including the one this
product describes. Football Coach: Winning Tradition shipped college-and-pro on iOS during the
research window; Draft Day Sports covers the desktop deep-sim pole with a universe import; Football
Coach: College Dynasty owns the mobile college-coaching slot; Retro Bowl owns the arcade pole.
Anyone who tells you the lane is empty has not looked recently — and the previous version of this
repo's own research said exactly that, which is why it now carries a correction banner.

**It is a quality gap at an intersection.** Nobody has shipped a football management sim on a phone
that survives the long game:

- The closest mobile competitor goes **hollow** once acquisition is mastered — the loop that carries
  the early game does not deepen, and nothing replaces it.
- The deep-sim pole's dominant community complaint is **AI quality**: rosters the AI mismanages,
  in-game decisions that do not adapt, recruiting that can be gamed.
- Long careers **drift**: leagues ossify or scramble, saves bloat, and the world stops being
  believable somewhere around season ten.

Those are the three things this product is built to be good at, and all three are unglamorous —
invisible in a screenshot, provable only over hours. That is the gap, and it is the hardest kind for
a solo developer to fill.

**On the promotion arc.** It is a real feature and a **weak differentiator**: it ships elsewhere, and
no community in the research asked for it. It earns its place as a *retention* device — a tier change
resets the acquisition loop that otherwise goes hollow — not as the headline. The precise surviving
novelty is narrow and worth stating honestly: *one save, one coach, one continuous career, on a
phone.*

---

## Audience

- **Primary:** people who play management sims on a phone and have run out of football ones they
  trust. They have played the mobile college sims, hit the hollowing, and gone back to soccer.
- **Secondary:** desktop football-sim players who want something real on a commute and will accept
  less depth for a career they can carry.
- **Explicitly not:** players who want to throw the ball. Retro Bowl is better at that and this game
  does not compete for them. §6.0 found the removed arcade layer held ~99% of the previous build's
  decision volume — this product replaces that volume with coach decisions, and some players will
  still prefer the thumb. That is an accepted loss, not an oversight.

---

## What it is to play

Fifteen minutes a week: read what arrived, set a game plan, spend a scarce budget on recruiting,
watch the match and make about twenty-five calls inside it. A season is 6–8 hours. A career is
decades.

---

## Distribution and monetisation (P3)

TestFlight, then paid premium on the App Store. **No IAP, no ads, no subscriptions, no analytics, no
accounts, no network of any kind.** Offline is a feature, not a limitation, and it goes in the store
listing: your save is yours, on your device, and nothing phones home.

---

## Commitments

Every verified row names the test that proves it. A commitment without a runnable test is an
unverified target, not release evidence, and stays out of this gate table.
(`docs/06-AUDIT-DISPOSITION.md` pattern 3) and `CommitmentCoverageTest` fails the build if this table
grows a row that no test backs.

| Commitment | Test |
|---|---|
| Contrast ≥4.5:1 on measured surfaces, both appearances | `ContrastByConstructionTest` |
| Every screen legible at AX5 | `DynamicTypeContractTest` |
| Reduce Motion honoured on every animation | `ReduceMotionContractTest` |
| VoiceOver on every data row and control | `VoiceOverLabelTest` |
| 44 pt touch targets | `TouchTargetTest` |
| A save stays bounded across 20 seasons | `M1SoakTests` + `M2SoakTests` |
| Same seed, same league, across app launches | `DeterminismTests` + source scan |
| All identities fictional and original | `LegalTests` |

---

## Unverified product targets

These targets remain part of the product direction but are not release claims until their dedicated
instruments exist and run in CI:

| Target | Current evidence status |
|---|---|
| A season is completable in 6–8 hours | AgencyBudgetTests is not implemented; owner measurement remains open |
| Week advance under 2.0 s at shipping league size | The host timing probe is evidence only; the device gate remains open |
| The simulation and the off-screen model agree | `TwoTierConsistencyTests` runs a paired four-world comparison and is **red**: seven of sixteen professional bands now hold after fixing the run baseline, pass completion, pass-rush pressure and the game clock's snap cost, but total points per team-game measures a standard deviation near 30 against a real figure near 10 — independent per-duel leverage draws compounding with no per-game correlation. Equivalence is blocked on that design gap, not on the instrument |
| A save survives 20 seasons under 8 MB | **Not met.** Measured 14.76 MB at season 20 on the soaks' own seed, against 3.67 MB at season 0. Departed-identity retention is now bounded — it was unbounded, and the save passed 8 MB at season 2 and reached about 26 MB at season 20 — and both soaks now assert a ceiling and a drift allowance rather than printing the sizes. Reaching 8 MB needs the portal and scouting duplication looked at, which is engine work and an owner call |

---

## v1 scope

**In:** both tiers and the promotion arc, the match engine and 2D view, recruiting and the portal,
draft/cap/free agency, staff and scheme, generated identity with rivalries and traditions,
conference realignment, the carousel, the record book, 20-season durability.

**Out of v1:** multiplayer, anything online, custom-universe import/export, a school editor,
historical seasons, iPad and portrait. The UI reserves optional player-photo, team-identity and
venue-name/media slots so a future user-supplied universe is not blocked, but that feature requires
a separate legal, privacy, security and content-handling gate.

**Later, if it earns it:** more tiers below the top college division, a deeper staff market,
scenario starts and a legally reviewed custom-universe workflow.
