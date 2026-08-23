# 11 — Prompt: regenerate the Floodlit Surface Register against amended canon

Hand this file to the session that owns `tools/refs/`. It is self-contained.

---

## What happened

You generated the **Floodlit Surface Register** at
`https://claude.ai/code/artifact/18336868-8b15-4ad0-8c92-f2f87d674505` — 59 surfaces, correctly
numbered, with a build-state taxonomy and a not-produced register. **The harness is right and is not
being rebuilt.** Keep it.

You built the visual layer from `docs/04-UX-AND-DESIGN-SYSTEM.md` and `DesignTokens.swift`, which was
the correct instinct under `CLAUDE.md`'s doc-first rule. Canon has since been amended, so the same
instinct now produces a different and better result.

**`docs/04` gained six amendments on 2026-08-22.** Read them before changing anything:
§2.1, §4.5a, §6.1a(ii), §6.1d, and two amended bullets in §6.4 item 4.

---

## Update the existing artifact — do not publish a new one

Pass the URL so it redeploys in place:

```
Artifact({ file_path: "<your built file>",
           url: "https://claude.ai/code/artifact/18336868-8b15-4ad0-8c92-f2f87d674505" })
```

Keep the title **Floodlit Surface Register** and the favicon stable.

---

## The six changes

### 1. Gold is the committing action and nothing else — §6.1a(ii)

`--fl-gold #FFC53D` marks the commit and the Match Day first-down line. Never a rating, never a
state, never a position chip, never decoration. **At most once per surface**, twice only on Match Day.

`state.warning` leaves the yellow band because it collided with gold at **6.1°** hue:

```
--fl-warning:  #FFB03A  →  #C9704A      /* 24.1° from gold, 5.57:1 on page */
```

The three duplicate pairs stay legal but must be **declared as aliases**, not repeated literals:
`--action-destructive: var(--state-negative)`, `--pro-identity: var(--state-info)`. Add a check.

### 2. Five heat bands, average neutral — §6.4

Replace the three-band `--heat-strong/steady/weak` scale. All five values verified on `page`,
`raised` and `panel`, and all ≥24° from gold:

| Token | Range | Hex | page | raised | panel | Δ gold |
|---|---|---|---|---|---|---|
| `--heat-well-below` | 40–59 | `#FF3B54` | 5.67 | 4.64 | 5.26 | 49.7° |
| `--heat-below` | 60–69 | `#C9704A` | 5.57 | 4.56 | 5.16 | 24.1° |
| `--heat-average` | 70–79 | `#A9BACE` | 10.00 | 8.20 | 9.28 | 170.4° |
| `--heat-above` | 80–84 | `#7FCB9E` | 10.32 | 8.46 | 9.57 | 102.4° |
| `--heat-well-above` | 85–99 | `#4FD08C` | 10.13 | 8.30 | 9.39 | 106.3° |

**Average is neutral, not amber.** The warm hue sits *below* the median. Where a surface bands a
rating it **prints the band table on that surface**.

### 3. The presentation lean — §2.1

New axis, orthogonal to canon's nine registers. Every surface carries one register **and** one lean.

| Lean | Ground | Mark | Largest numeral | Data points |
|---|---|---|---|---|
| Broadcast | club/opponent colour, flooded | 200–390 pt | 40–72 pt | ≤ 12 |
| Desk | `world.page`, club colour only in the identity band | 19 pt | 11–14 pt | ≤ 72 |
| Dossier | club colour above the seam, `world.page` below | 180–220 pt above | 40 above / 11.5 below | ≤ 8 above, ≤ 40 below |

Assign per surface: **Broadcast** — Signing Day, Draft Room, Awards, Promotion Decision,
Championship Result, Aftermath, Season Review, Realignment Event, Title/Continue.
**Dossier** — Player Profile, Prospect Profile, Team/Programme Profile, Staff Room dossiers,
Contract Negotiation, Season Expectations. **Match Day carries Broadcast + Desk simultaneously.**
Everything else is **Desk**.

A Dossier surface carries **exactly one** 2 pt `action.primary` seam at the lean change. None or two
is a finding — add a check.

### 4. The identity band — §6.1d

Replace the §6.1c header-plus-icon-rail with a single band that **encloses the whole navigation row**:
mark, club name, record and rank, family name, sibling tabs and context slot all inside it. It is not
a pill beside the navigation; the navigation is inside it.

34 pt tall · gradient from club primary to `world.page` · hairline of club secondary · mark 19 pt.
It is the **seventh** sanctioned mark placement under §5.2; the standings row is the eighth. §6.1a's
team-colour fill rule applies — the gradient is a team fill and always carries its hairline.

### 5. The measured density budget — §4.5a

Geometry gives a 709 × 319 pt box, but the usable scroll viewport measures **291 pt**, and **241 pt**
once a commit bar is reserved outside the scroll.

| Tier | Row | Viewport | Rows | Cols | Cells |
|---|---|---|---|---|---|
| Dense | 32 pt | 291 | 9 | 8 | **72** |
| Working | 44 pt | 291 | 6 | 8 | **48** |
| Committing | 44 pt | 241 | 5 | 8 | **40** |
| Broadcast | — | 390 | — | — | **12** |

Derive the viewport in chrome from `commit is not None` so the budget can never drift from the bar.
**Count declared data, not rendered elements** — chrome, labels, captions and prose are not cells.

### 6. Ranged ratings — §6.4

A rating the simulation has not earned is drawn as a **range**, not a point. Range width is the
confidence; a rating observed enough to be certain renders as a collapsed range (`83–83`), never as a
different kind of number. No observation at all prints **`Unseen`** — never a blank, dash or zero.
Draw the observation that produced the range beside it.

This carries an engine dependency (`07` GAP-06, no scouting-confidence model). Until it lands,
**render point values and declare the gap** — do not fabricate ranges.

---

## Keep unchanged

The 59 surfaces and their numbering (63–74 for the new ones) · BUILT/WRAPPER/PARTIAL/MISSING/OVERLAY ·
the not-produced register with DATA/SCREEN/INTERACTION/ART/RULE kinds and blocking counts · the
primitive set · token-only CSS with the palette-closure check · "Generated; do not hand-edit" · the
refusal of `ink-3 #65788F` for failing 4.5:1.

The gap content is good and should survive verbatim — *"EventBadge is constructed on no branch"*,
*"Renders byte-identical to Roster Cuts"*, *"ProManagementReadModel holds no transactions collection"*.

---

## New checks

Add to the existing set:

1. **Gold once** — commit + gold nodes ≤ 1 per surface, ≤ 2 on Match Day.
2. **Heat bands** — exactly five; each ≥4.5:1 on page/raised/panel and ≥24° from gold, computed, not
   asserted from a constant.
3. **Lean declared** — every surface has one; Broadcast carries no table; Dossier has exactly one seam.
4. **Cell budget** — per tier, counted on the registry.
5. **Alias closure** — no duplicate literal hex across two role tokens.
6. **Band table present** — any surface banding a rating prints the legend.

---

## Verification

1. All checks pass; non-zero exit on failure.
2. Build twice, byte-identical.
3. Grep the output: `#FFB03A` appears **zero** times; `#FFC53D` appears at most once per surface frame.
4. Redeploy to the **existing** URL and confirm the title and favicon are unchanged.

---

## Before you commit anything — read this

**The repository is on branch `Codex/logos`, which has no commits.** `HEAD` is unborn, so all ~2038
files read as newly added and `git log` fails.

Nothing is lost: the object database is intact, `origin` is configured, and `005f371` and `0a2b641`
are both reachable — `0a2b641` still contains all ten `docs/ux` files.

**Do not commit into `Codex/logos`** or the work strands on an orphan branch. Ask the owner to repair
the branch pointer first. The `docs/04` amendments described above are **applied to disk but
uncommitted**, so verify they are present before you build:

```bash
grep -c "2026-08-22 amendment" docs/04-UX-AND-DESIGN-SYSTEM.md   # expect 4
grep -c "red below 70, amber from 70" docs/04-UX-AND-DESIGN-SYSTEM.md  # expect 0
```
