# Claude Design Brief 05 — Front Office

Scope: the money wing — the Front Office tab root and its six rooms: Salary Cap, Re-Sign, Free Agency, Trades, Staff, Owner (04-SCREENS-UI.md §12). Static frames only; no storyboard sheet in this brief.

Inherits docs/design/briefs/00-system.md in full: tokens, demo teams (New York Empire NYE #14294B/#C9A227 vs Boston Harbormen BOS #0E3B2E/#C8CFD4), voice registers, staging notation and channel-tag vocabulary, platform physics (Dynamic Type XXXL, 4.5:1 measured contrast, 44×44pt targets, no color-alone state, everything fictional). Do not restate; do not deviate.

## Emotional job

04 §12 defines one job for the whole tab; every screen below serves it:

> **Job: the long game — money as consequences, not spreadsheets (until you want the spreadsheet).**

First screenful is always facts and consequences in system voice; the full table sits one tap deeper, never amputated.

## Screens

### Front Office hub (tab root)
Content: six navigation rows — Salary Cap, Re-Sign, Free Agency, Trades, Staff, Owner — each with a badge chip carrying its live count or state ("$12.4M space", "3 expiring", "2 offers pending"). Chips are metadata, never controls; the row itself is the ≥44pt target.
No staged moments; renders settled.

### Salary Cap — PRIMARY
Content:
- Hero fact card: "$12.4M space · cap $255M" + stacked bar of committed spend; consequence line for the nearest crunch directly beneath, system voice ("2027 is the wall — $241M committed before Reyes re-signs").
- Year selector (current + future years).
- Contracts DataTable: sort by cap hit, expiring filter, tabular figures right-aligned.
- Click budget (hard requirement from 04): any contract's dead-money figure reachable in ≤2 taps from this screen.
Staging: cut/restructure confirmations follow DESIGN.md §2.3 row **"Cap move (cut/sign/trade)"** — "Cap impact" anticipate, dead money then cap space stagger, consequence line, `[HAP negative]`/`[HAP positive]`. All frames depict the settled state.

### Re-Sign
Content: expiring list (face mark, name, position, age, OVR in tier color, ask) with walk-risk stated per row as word + number; negotiate sheet presented over the list — years/salary/guarantee sliders, true accept-probability meter (label and value, never color alone), round counter (3 rounds), promise option; a contract deadline has blocking semantics on the week advance (FeedCard blocking flag).
Frame depicts the negotiate sheet open for Darius Reyes, mid-negotiation, nothing staged.
Staging: an accepted deal follows §2.3 row **"Contract signed"** — ask-vs-offer recap, years/money stagger, cap line + morale effect, `[HAP positive]`.

### Free Agency
Content: market DataTable (position/age filters, sort); bid sheet with true interest meter; wave ticker cards narrating market movement in press voice with byline chips; the in-season street-FA variant states explicit refusal reasons in system voice ("Declined — wants a contender").
Frame depicts the offseason market with one wave ticker card visible.
Staging: a completed signing follows §2.3 rows **"Contract signed"** and **"Cap move (cut/sign/trade)"**. Frame settled.

### Trades
Content: partner picker with AI need hints; two asset columns (yours / theirs) with add/remove pickers; true value verdict rendered as a StakesPanel — Decline / Close / Accept as words with true numbers, `[HAP stakes]` on verdict change; counter-offer action; deadline banner with weeks remaining; incoming AI offers arrive as feed cards (`[SND card]` `[HAP cardLand]` — arrival lives on the hub feed, listed as pending here).
Frame depicts a live offer built against Boston (BOS), verdict reading "Close".
Staging: an accepted trade follows §2.3 row **"Cap move (cut/sign/trade)"**. Frame is pre-acceptance, settled.

### Staff
Content: OC / DC / STC cards — name, rating in tier color, scheme match as symbol + word ("✓ Fits" / "⚠ Stretch"), signature trait, salary, years; staff budget bar; hire/renew actions available only during the offseason carousel; poaching arcs arrive as feed cards.
Frame depicts the carousel-open state, actions visible.

### Owner
Content: expectation card (this season's stated demand); patience as word + number; job security % — reuse 71% to match the hub hook "Hot seat: 71% security".
No §2.3 row applies; values change by `count`; renders settled.

## Frames (9 exports)

| # | File | State |
|---|---|---|
| 1 | `05-front-office-hub-light.png` | tab root, badges live |
| 2 | `05-front-office-cap-light.png` | hero card + stacked bar + table top |
| 3 | `05-front-office-cap-dark.png` | same state, dark |
| 4 | `05-front-office-cap-xxxl.png` | same state, accessibility XXXL, light — nothing truncates, gutters widen |
| 5 | `05-front-office-resign-light.png` | negotiate sheet open, Reyes |
| 6 | `05-front-office-free-agency-light.png` | offseason market + wave card |
| 7 | `05-front-office-trades-light.png` | live BOS offer, verdict "Close" |
| 8 | `05-front-office-staff-light.png` | three coordinator cards + budget bar |
| 9 | `05-front-office-owner-light.png` | expectation + patience + security |

## Demo data

- **Darius Reyes — WR · #11 · New York Empire** anchors the money story wherever a player is needed. Locked canon: OVR 87 (Star); current deal 2 yrs · $7.2M/yr · $4.1M guaranteed; cut consequence "$6.2M dead through 2028"; contract-year ask 3 yrs · $9.5M/yr. His row appears in the cap table; the Re-Sign sheet negotiates his ask.
- Cap card numbers: $12.4M space · cap $255M (04 §12 canon).
- Trade partner: Boston Harbormen (BOS) — the standing two-team pairing.
- Owner screen: job security 71%.
- Invent everything else freely — coordinators, free agents, the owner, bylines — neutral realistic fictional names, never real people. Money copy is system voice: fact line, then consequence line.
- Calendar: cap, Re-Sign, and Trades read as in-season 2026; Free Agency and Staff read as offseason carousel. Label each frame's phase honestly in its nav subtitle; do not force one date across the brief.

## Open questions (surface, don't fill)

1. Stacked-bar composition on the cap hero card — segments by position group, or active/dead/reserved? 04 doesn't say.
2. Year-selector range — how many future years does the cap view project?
3. Promise option — the canonical promise list lives in 02-GAME-DESIGN.md §6 and is not quoted here; the sheet needs real strings before it is final.
4. Trade verdict — the three words alone, or words plus a numeric value delta? StakesPanel requires true numbers; 04 gives only Decline/Close/Accept.
5. Owner expectation card — is there a canonical expectations list, or is the demand string free to invent?
