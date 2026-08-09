# Claude Design Brief 07 — Coach & Legacy

**Scope:** the Coach tab (career hub), the Trophy Room, and Settings — the surfaces where the player's career, the dynasty's permanence, and the app's controls live.

**How to use:** paste `00-system.md` first, then this file, as one Claude Design session. Exports land in `docs/design/mockups/`.

Inherits docs/design/briefs/00-system.md in full: tokens, demo teams (New York Empire NYE #14294B/#C9A227 vs Boston Harbormen BOS #0E3B2E/#C8CFD4), voice registers, staging notation and channel-tag vocabulary, platform physics (Dynamic Type XXXL, 4.5:1 measured contrast, 44×44pt targets, no color-alone state, everything fictional). Do not restate; do not deviate.

---

## Screen 1 — Coach tab (PRIMARY)

**Emotional job: your career is its own save.**

Content inventory (04 §17):
- Profile card: team, coach name, season/week.
- **My Coach** row: level, salary, contract, **job security %** with word.
- **Skill Tree** row: 4 branches (Scouting / Development / Offense / Defense — canon, 02 §10), node chains, SP costs; unlocked nodes = accent + icon (the icon carries state, never color alone).
- **Seasonal Goals**: owner-assigned cards with progress figures + XP rewards.
- **Job Offers / Team Search**: active during the coaching-carousel window only; dormant otherwise.
- **Trophy Room** (push) and **Previous Seasons** archive rows.
- **Season Retrospective** row: staged recap + local export artifact (02 §11).
- **Franchise Management** card: Autosave toggle, Save, Checkpoints (max 5), Settings, Main Menu (destructive-confirmed, stock confirmation dialog).

Staging notes:
- Tab entry renders **settled** — the P4 first-render rule (DESIGN §2.3) generalizes here: no staged interruption on entry; staging lives in flows launched from this screen.
- Job security, XP, and progress figures are tabular numerals with `count` on change.
- Accepting a job offer resolves through the **Contract signed** row of DESIGN §2.3 (ask vs offer recap → years/money `stagger` → consequence line, `[HAP positive]`). Frames show entry points, not mid-staging states.
- The Season Retrospective is a chapter turn (`turn`, DESIGN §2.6 chapter-turns row; championship seasons run it inside Tier 4 choreography). Its interior is out of scope for these frames.

## Screen 2 — Trophy Room (push)

**Emotional job: permanence — what the dynasty has won, in one room.**

Content inventory (04 §19):
- Collection bar (earned count of total).
- Trophy grid: v1 ten types + challenge completions (canon challenge names: Dynasty, Homegrown, The Long Rebuild — 02 §12/FM-34).
- Each trophy opens its season context: record, bracket, retrospective link.

Staging notes:
- The room never replays celebration staging. Tier 4 championship choreography (DESIGN §2.6) deposits its trophy-room card upstream; entry here always finds every trophy already landed and settled.
- A newly earned, not-yet-viewed trophy carries a word chip ("New"), never a color-only marker.

## Screen 3 — Settings (sheet)

**Emotional job: control without clutter.**

Content inventory (04 §21):
- Appearance: Light / Dark / System.
- Sound effects toggle — row states that the silent switch is respected (DESIGN §2.4).
- Haptics toggle — independent of sound (DESIGN §2.5).
- Prediction display: spread ↔ win % (affects prediction chips league-wide: "Empire by 3" ↔ "61%").
- Confirm advances · Injury popups · Replay tutorial.
- App info: version, build. No accounts, no links out, no IAP — nothing that resembles a store.

Staging notes: none. Every control acknowledges at `instant` (≤100ms). No headline numbers, no §2.3 moments, no channel tags on this sheet. Stock grouped-list construction.

## Frames

Coach tab is primary: light + dark + XXXL. The light and XXXL frames show the in-season settled state (Week 13). The dark frame shows the **carousel-window state**: Job Offers row active with a count badge and one live offer card — the same alternate-state convention 00-system used for gameday's dark frame. Secondary screens get light only. No storyboard sheets in this brief; channel tags appear only if a frame depicts a staged state (none do by default).

Export exactly these five files to `docs/design/mockups/`:

- `07-coach-tab-light.png`
- `07-coach-tab-dark.png`
- `07-coach-tab-xxxl.png`
- `07-coach-trophy-room-light.png`
- `07-coach-settings-light.png`

## Demo data

- Context carried from 00-system: New York Empire, 2026 · Week 13, **9–3 · 1st Liberty East**.
- Coach (invented, fictional): **Adrian Cole, 46** — Level 8 · $4.2M/yr · 2 yrs remaining · job security **71%** with word (demo string "71% — Warm seat"; continuity with the hub's "Hot seat: 71% security" hook).
- Seasonal goals: "Win the Liberty East — 1st at 9–3 · +150 XP" (on pace, positive accent) · "Develop a young receiver — Reyes 85 → 87 · +100 XP" (resolved positive; reuses **Darius Reyes, WR #11**, continuity with the 03-player camp reveal).
- Dark-frame job offer comes from the **Boston Harbormen** (the only other sanctioned team): "BOS — 4 yrs · $5.8M/yr", Accept/Decline as entry points only.
- Trophy Room: collection bar "3 of 10"; earned demo set = 2024 Championship (detail: 13–4, bracket, retrospective link), 2025 Liberty East title, one challenge completion chip ("Homegrown — 2024"). Invent additional fictional player/coach names freely; never real ones.
- Settings: version "1.0 (214)".

## Open questions (surface, do not fill silently)

1. The ten v1 trophy types are not enumerated anywhere in canon (04 §19 says "ten types"; 02 never lists them). Frames may use an obvious placeholder set (championship, conference, division, coach-of-the-year tiers), but the canonical list needs an owner decision.
2. No job-security word ladder exists (04 §17 says "% with word"). The demo string "71% — Warm seat" is a placeholder; the %→word mapping needs defining.
3. Unearned trophy slots: visible as locked, labeled silhouettes (collection pull) or hidden until won (surprise)?
4. First-season empty Trophy Room: needs system-voice copy that promises rather than shames — draft wanted.
5. Skill-node unlock has no row in DESIGN §2.3's v1 staging table. Does it earn a staged reveal, or a plain `settle` + `[HAP positive]`?
6. Season Retrospective interior and its export artifact (02 §11) have no frame in any brief — which future brief owns them?
