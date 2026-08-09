# Pre-Deployment Checklist

Everything still outstanding before this ships, gathered from the `/impeccable critique` of the
Broadcast skin (commit `dc18380`, 8 assessors, 87 issues), `docs/AUDIT.md`, and `DESIGN.md`'s
known-drift section. Each item was re-checked against the tree at `a58d4f0` — items already fixed
are listed at the bottom rather than left here to rot.

Distribution is TestFlight / personal use, so nothing here is gated on App Review. The bar is the
project's own: `PRODUCT.md`'s five principles and `DESIGN.md`'s named rules.

**Status at `a58d4f0`:** 260 tests / 13,530 checks green. Design health 137/240 (up from 126 at
baseline; 0 clusters category-interchangeable, down from 2).

---

## P0 — blocks the task

*None outstanding.* The one P0 (scouting unreachable) was fixed in `23b3dcf`.

---

## P1 — must fix before release

### Front office
- [ ] **Money is absent from trades end to end.** No salary or cap hit on any row, no cap delta
      before or after a deal. The cap is the product's stated differentiator and the one screen
      where assets change hands never mentions it.
- [ ] **Pick trading is modelled and unreachable.** Three years of picks, valuation with
      future-year discounting and ownership tracking all exist in `TradeEngine`; `TradePackage` is
      built from `playerIDs` only, so none of it can be used.
- [ ] **No future-year cap anywhere.** The cap card and Contracts list show only the current year,
      so a deal's real cost in 2028 is invisible at the moment it is signed.
- [ ] **Draft day has no clock.** `select()` auto-runs the AI to the user's next turn, so the
      player is permanently on the clock and the on-the-clock moment carries no tension.
- [ ] **Franchise tags do not exist.** `docs/04-SCREENS-UI.md` §18 names a tags window in a
      ten-stage offseason; `OffseasonStage` has nine cases and no tag stage.

### Gameday
- [ ] **Defensive possessions are not an experience.** In both modes the opponent's entire drive
      resolves silently between your snaps. Half of football is a gap in the log.
- [ ] **The two-point decision is taken by the AI.** "Call every down" excludes one of the two
      calls coaches are actually remembered for. (Fourth down was addressed in `b915ad6`; two-point
      was not.)
- [ ] **No win probability anywhere in the live game.** `MatchupOdds` exists and is tested;
      `LiveGameView` never references it, so nothing tracks the swing.
- [ ] **The field-goal button is offered from anywhere on the field.** `callButton(.fieldGoal…)` is
      not gated on `situation.isInFieldGoalRange`, so a 70-yard attempt is one tap away.
- [ ] **Overtime renders as "Q5".** The score bug prints `Q\(live.quarter)` unconditionally.

### Weekly loop
- [ ] **The playoff picture does not exist.** No seeds, no clinch state, no "in the hunt" anywhere
      in the loop — in a game whose season exists to reach the playoffs.
- [ ] **Playoff weeks are announced as "Week 19"–"Week 22"** and neutral-site finals still say
      "Home".

### Entry
- [ ] **Team choice is a blind lottery.** The one decision that sets a franchise's whole difficulty
      offers city, name and stadium — no rating, no cap health, no situation. `docs/04` §2 states
      the doctrine ("Difficulty comes from team choice — surface it") and it is unimplemented.

### Team
- [ ] **The Team header is the retired world's gradient hero**, not a `BroadcastBand` — the last
      full-surface team-colour background, against DESIGN.md's One Band Rule.

---

## P2 — fix before it is seen by anyone else

### Correctness and safety
- [ ] **No busy state exists.** `AppState.isBusy` is declared and never set; founding a franchise
      generates the full 32-team league synchronously on the main actor behind a button that just
      freezes. Loading decodes a multi-megabyte save the same way.
- [ ] **Auto-Sort by Rating is instant and irreversible** — no preview, no confirmation, no undo,
      and no statement of what it changed.
- [ ] **Offseason stage advance is one-tap irreversible at every stage.** "Done Re-Signing" sits
      next to the primary action and closes the window for good.
- [ ] **Start Scenario accepts empty name fields** and silently christens the coach "Alex Rivers",
      where the wizard gates Continue on a name.
- [ ] **Released player's card stays on screen** rendering a stale copy after Release.

### Money and information
- [ ] **Cap space is not shown in the free-agent list, the offer sheet, or the negotiation sheet** —
      the number that decides every one of those actions.
- [ ] **Staff budget leaves the subtraction to the reader** — "budget" and "committed" as two
      figures, no remaining.
- [ ] **Undisclosed truncation.** Trade rosters cut at 30 of 53 with no indicator; the draft board
      and other lists truncate silently.
- [ ] **The cap sentence advises "restructure"** — a capability `PRODUCT.md` explicitly excludes
      from v1.
- [ ] **Negative cap hard-codes the fringe tier's light hex in both appearances** (~2.5:1 on the
      dark card).

### Skin consistency
- [ ] **Game chrome uses the legacy gradient, not the flat band** — score bug, final whistle and
      on-the-clock header are all `theme.gradient`.
- [ ] **The arcade is a third dialect**: rounded-design scores and its own chrome, matching neither
      the Broadcast nor the retired Almanac.
- [ ] **The preseason card wears team colour as a body surface.**
- [ ] **Segment surfaces disagree** — standings are carded, power rankings and news float.
- [ ] **The confirm step ("The appointment") is unconverted** — bare text on the page, no card, no
      band, no club colour, on the wizard's peak moment.
- [ ] **Raw system colours remain on meaning-bearing text** in TeamViews and StatsView.
- [ ] **The championship badge is white on filled system yellow** (~1.4:1).

### Accessibility
- [ ] **The attributes grid reads backwards to VoiceOver** — each cell is two loose elements with
      the number announced before its label.
- [ ] **History season lines silence their award rows** — `accessibilityElement(children: .combine)`
      swallows them.
- [ ] **Depth reordering is invisible** — reachable only through a bare toolbar `EditButton`.
- [ ] **Skill tree** — three sheets still unlisted for appearance, and the tree's own labels.

### Architecture
- [ ] **The power-ranking formula is game logic in the view** with magic numbers, alongside
      `MatchupOdds` which was moved into the engine for exactly this reason.
- [ ] **"The full preview" underdelivers** and its missing content sits in dead code.
- [ ] **Sim demands a destructive confirmation every week, forever** — correct the first time,
      friction by week ten. Consider a "don't ask again this season".

---

## P3 — polish

- [ ] Consequence copy missing on the three highest-stakes wizard toggles (salary cap, injuries,
      coach firing) in the same Form where two lesser settings have footers.
- [ ] "Coordinators call plays" filed under a "Presentation" header when it is a delegation of duty.
- [ ] Team search with no matches renders a List containing only the search field — no empty state.
- [ ] Name fields leave autocorrect on, with no `submitLabel` or next-field chaining.
- [ ] Settings and the tutorial are unreachable before a franchise exists.
- [ ] Save rows never show when a franchise was last played, though `SaveMeta.updatedAt` exists.
- [ ] Team overalls are `Int`-truncated in chips, mismatching the rounded tier colour at band edges.
- [ ] Game report: unlabeled quarter columns, raw `.orange` OT chip, `.yellow` crown.
- [ ] `potentialColor` is dead code mapping Potential to the retired raw ladder.
- [ ] Leaderboard values have no thousands grouping ("3412 yds") and the column silently changes
      meaning between categories.
- [ ] League Statistics is reachable only through the Team tab.
- [ ] Contract length is strategically irrelevant — interest and acceptance read
      `averagePerYear` only.
- [ ] Trade verdict styling keys on the string prefix "Accepted".
- [ ] Drive-log rows show "0:42 · 14–10" with unlabeled away–home order.
- [ ] Eight meaning-free rainbow row tints on the Coach hub — the same pattern removed from the
      cover.
- [ ] Tenure chapters carry no club identity — neutral cards, no mark, no colour.
- [ ] `CoachProfile.cash` is persisted on every coach (default $500,000) and never read by any view.
- [ ] Undated news, invisible bye week, sub-44pt preview link, legacy tokens in bye/offseason cards.

---

## Known drift carried in DESIGN.md

- [ ] Two clubs can draw the same motif — seven shapes across 32 clubs, so collisions are expected
      and colour is the only distinguisher. A larger motif set would reduce it.
- [ ] Some `Chip` call sites pass a rating colour directly and carry no spoken tier.
- [ ] Roughly 60 literal paddings and frames remain in views built before the token layer.

---

## Ship gates

- [ ] `swift run -c release SimTests` green.
- [ ] Definition-of-done demo from `docs/00-EXECUTIVE-PLAN.md`: wizard → full season → offseason →
      season two, on device, both appearances.
- [ ] XXXL Dynamic Type pass on the hub, standings, schedule, roster and player card.
- [ ] VoiceOver pass on the same five screens.
- [ ] Ten-season soak still green (`DynastyTests`), no roster or free-agent-pool drift.
- [ ] Re-run `/impeccable critique`; target ≥150/240 and no cluster below 22/40.
- [ ] Re-run `/impeccable audit`; target ≥16/20.

---

## Already fixed (for the record)

Landed across `23b3dcf`, `7ceb97f`, `b393c54`, `b915ad6`, `a58d4f0`:

Scouting unreachable (P0) · goals re-paying XP weekly · the dead XP event table · STARTER chips
lying when a starter is hurt · re-sign misreporting a cap wall as a rejection, and its free
re-roll · the cover naming the retired world · `Chip` → `Stamp` with self-correcting fills ·
club marks on saves, cover and load rows · sheet appearance inheritance · four hard-coded font
sizes · fourth-down advice · silent level-ups and goal completions · the arcade's unguarded Sim to
Final · job offers with no information · the scenario objective vanishing · schedule rows inert and
clipping at XXXL · trade selections surviving a partner switch.
