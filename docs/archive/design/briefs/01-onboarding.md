# Claude Design Brief 01 — Onboarding & Entry

**Scope:** the pre-dynasty surfaces — Main Menu, the 4-step New Game Wizard, Load Game, Scenarios — every path from cold launch into a save.

Inherits docs/design/briefs/00-system.md in full: tokens, demo teams (New York Empire NYE #14294B/#C9A227 vs Boston Harbormen BOS #0E3B2E/#C8CFD4), voice registers, staging notation and channel-tag vocabulary, platform physics (Dynamic Type XXXL, 4.5:1 measured contrast, 44×44pt targets, no color-alone state, everything fictional). Do not restate; do not deviate.

**Brief-wide staging note:** onboarding is pre-sim, so every frame is a settled state — no staged interruption fires on entry (the DESIGN §2.3 first-render law, applied). None of the §2.3 reveal rows (Final score, Cap move, Draft pick, Camp reveal, Record broken, Award, Contract signed) appear on these screens. The first staged sequence of a player's life — the season-opening card stack — lands on the Season Hub via the advance pattern, after this brief ends.

---

## 1. Main Menu (04 §1)

**Job: confidence — your dynasty is safe here, and starting a new one feels like a season premiere.**

- Hero: app mark, "Pro Football Coach", tagline (copy not yet canon — see open questions).
- **Continue** row — the most recent save as a settled card: team mark, season/week, one-line active hook. The save greets you mid-story; it should read like a paused broadcast, not a file entry.
- Rows: New Game · Load Game · Scenarios · Challenges (named templates). Gear icon → Settings sheet.
- No external links anywhere.

## 2. New Game Wizard (04 §2) — PRIMARY SCREEN: step 2

**Job: anticipation — picking a team should feel like accepting a job, not filling a form.**

- **Step 1 League:** one default-league card (32 teams, 2 conferences). Advanced options (v1.5) hidden entirely.
- **Step 2 Team (the primary frame):** search field; teams grouped by division; row = team mark, city+name, team rating figure (tier color per the rating ladder), cap-health word+symbol chip (status accents; ✓/⚠ symbol vocabulary), situation tag chip ("Contender", "Rebuild" — sets expectations and difficulty). Tap a row = detail peek: last-season line, best players as face chips, cap space fact line + consequence line, draft picks held.
- **Step 3 Coach:** name/age; background trait grid (+1 branch point); scheme pickers; GM settings; optional challenge template; save name.
- **Step 4 Confirm:** summary cards + themed **Start Franchise** CTA — the one Empire-color band on this surface.
- Step position as a plain text label ("Step 2 of 4"), stock navigation, back always available. No custom progress chrome.

Staging: Start Franchise is a new-job chapter turn — DESIGN §2.2 `turn` (full-card crossfade, `moment` budget). Its sound/haptic channels are unresolved — see open questions; annotate the CTA, do not invent tags. The card stack that follows is Season Hub territory, outside this brief.

Step 2 frame states: **light** = the division list, Liberty East at top, Empire row selected; **dark** = the Empire detail peek open; **XXXL** = the light state at accessibility XXXL (search field, rows, chips, and figures all intact — number gutters widen, nothing truncates).

Team canon for the list (these names are locked league canon, not inventions): **Liberty East = New York Empire, Boston Harbormen, Philadelphia Founders, Washington Sentinels.** Only NYE and BOS have locked colors; render Founders and Sentinels marks in neutral monochrome (secondaryLabel tint) rather than inventing palettes — see open questions. Show the next division group ("Liberty North") peeking below the fold to imply the full 32.

## 3. Load Game (04 §22)

**Job: every save greets you mid-story.**

- Save cards: team mark, save name, coach name, season/week, timestamp, one-line active hook.
- Swipe to delete, with destructive confirm.
- Checkpoints live under the Coach tab, not here — draw no checkpoints section.
- Empty state (system law — every listable surface has one): icon + headline + sentence, e.g. "No saves yet. Start a new franchise."

## 4. Scenarios (04 §23)

**Job: a dare with a deadline.**

- Exactly three cards: **Cap Hell · Expansion Franchise · Aging Legend.**
- Card anatomy = premise fact + goal + why it's hard. System voice: fact line, then consequence line. No exclamation marks — the dare is in the numbers.
- Cap Hell's locked number: **−$38M effective cap space next year.** The other two premises have no locked v1 parameters — draw structurally correct placeholder copy and see open questions.
- In-save, scenario goals ride the hooks rail; that is Season Hub territory and is not drawn here.

---

## Frames & export filenames

Nine frames, 393×852pt each, into `docs/design/mockups/`. Primary screen in three variants; all others light only.

1. `01-onboarding-main-menu-light.png`
2. `01-onboarding-wizard-league-light.png`
3. `01-onboarding-wizard-team-light.png` — primary, division list
4. `01-onboarding-wizard-team-dark.png` — primary, Empire detail peek open
5. `01-onboarding-wizard-team-xxxl.png` — primary, light state at accessibility XXXL
6. `01-onboarding-wizard-coach-light.png`
7. `01-onboarding-wizard-confirm-light.png`
8. `01-onboarding-load-game-light.png`
9. `01-onboarding-scenarios-light.png`

## Demo data

- The Empire is the chosen team everywhere: step 2's selected row and peek, step 4's confirm, the Continue card, and the first Load Game save card.
- Detail peek: last season "10–7 · 2nd Liberty East · Lost Wild Card"; situation tag "Contender"; cap fact "$12.4M space · cap $255M" (canonical figure) + consequence "Room to re-sign Reyes — asking $9.5M/yr"; face chips led by **Darius Reyes (WR, #11, Empire)**.
- Continue card and Load Game hooks reuse the canonical hook line "Reyes contract — 2 wks". Second save card may show the Harbormen for contrast.
- Invent coach names, save names, and additional player names freely — neutral, realistic, never real people. Team names come only from the canon list above; invent no teams.

## Open questions (surface, don't fill)

1. **Non-demo team identity.** Step 2 needs at least Liberty East complete, but only NYE/BOS have locked colors. Interim direction is neutral monochrome marks — is a per-team palette canon coming, contrast-vetted before it appears in rows?
2. **Start Franchise channels.** DESIGN §2.2 `turn` implies a sting, but the closed tag vocabulary has no generic sting and `fanfare` is championship-locked. What fires — a `[SND sting-final]` variant, `[HAP milestone]`, or nothing?
3. **Main Menu identity.** With no saves, does Continue hide or render as a teaching state? Pre-dynasty there is no team color — does the app itself own a brand color/band, and what is the tagline copy?
4. **Challenges screen.** 04 §1 lists Challenges as a menu row, but no brief owns a Challenges list. Does it reuse the Scenarios card layout, and which brief draws it?
5. **Situation tag accents.** "Contender"/"Rebuild" chips — info accent for all, or a semantic mapping? Color here implies judgment about difficulty.
6. **Scenario parameters.** Expansion Franchise and Aging Legend need locked v1 numbers (02 §12) before final card copy.
