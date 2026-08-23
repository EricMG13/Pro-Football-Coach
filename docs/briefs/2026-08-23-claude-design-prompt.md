# Prompt for Claude Design — the Floodlit design system

*Authored 2026-08-23. Source artefacts: "Two Registers" (34b9992d) and "Floodlit Surface
Register" (18336868). Paste everything below the rule into Claude Design as a single brief.
It is written to be self-contained: Claude Design has no access to this repository.*

---

# Build the Floodlit design system

## What this is

Floodlit is the design system for **Pro Football Coach**, a college-to-pro American football
coaching career simulator for **landscape iPhone**. The player is a coach. There is no direct
control of players during play — no arcade mode, no throwing passes. The player prepares,
decides, and watches. Every screen either tells them something or helps them work something out.

You are building the **system**, not the screens. The screens are how we will test whether the
system is sufficient.

**Output medium is web (HTML + CSS).** Production is SwiftUI, and this system is the drawing and
handoff medium for it. That constrains you in one specific way: **no value may be web-only.**
Every colour, length, weight and curve you specify has to be expressible as a SwiftUI value. Do
not reach for CSS features with no Swift equivalent (container queries, `:has()`-driven layout,
CSS filters as load-bearing design). Fonts are the one sanctioned substitution, and it is already
made for you — see Typography.

---

## The three hard constraints

These are not preferences. A proposal that violates one is wrong, not different.

**1. Landscape only, at a fixed install floor of 844 × 390 pt.**
Not responsive. Not a breakpoint system. Every management surface is composed at 844 × 390 with
absolute positions, and that is the *floor* — the promise range runs 852 × 393 to 956 × 440, but
below-promise devices must always install and render un-clipped. Design to 844 × 390 and let the
extra pixels be slack. Portrait is not a supported orientation. There is no tablet, no desktop,
no web-app target.

**2. Dark only. There is no light register and no appearance switch.**
Do not produce a light palette. Do not produce "derived light values". Do not add a theme toggle.
This was decided and closed; a light mode is not a nice-to-have you can add for completeness.

**3. No human likeness exists, anywhere, ever.**
No portraits, no headshots, no player art, no procedural faces, no silhouettes standing in for
faces. The app is offline by design and fetches nothing. This is the single most consequential
constraint on the system, because **every reference in this genre leads with a face** — the Topps
card portrait, the headshot on a trade card, the full-bleed player, the studio pundit. That device
is unavailable to us. A blank photo plate is the empty state, and it is permanent.

Additionally: all schools, teams, conferences, stadiums, players, coaches, marks, colours and
traditions in this product are **fictional and original**. Any example content you draw must be
invented. Never use a real programme, team, player or conference name. Real city names are
permitted; real venue names ("Rose Bowl", "Lambeau") are not, because those are marks that happen
to read as places.

---

## The thesis: three registers

A hybrid of a broadcast sports game and a management sim cannot split the difference on every
screen — that is how you get a product that is neither. So **each surface picks a side, and the
rule for picking is not taste.**

The obvious rule would be frequency: rare screens get spectacle, weekly screens get restraint.
Tested against the real screen inventory, frequency produces one absurd result — **Match Day comes
out restrained**, because you see it fifteen times a season. That is plainly wrong, and the failure
is what identifies the real axis.

**The axis is whether the player is being told something or working something out.** Frequency
only decides how much spectacle is affordable once the side has been picked.

| Register | The player is | Example surfaces | Seen/season |
|---|---|---|---|
| **Broadcast** | **Being told.** Receiving a result, a moment, a verdict. | Signing day · Draft night · Awards · Promotion decision · Championship · Aftermath | 1–15 |
| **Desk** | **Working.** Scanning, comparing, filtering, deciding. | This week · Inbox · Roster · Depth chart · Recruiting board · Standings · Schedule · Statistics · Practice · Game plan · Film room · Cap | 15–45 |
| **Dossier** | **Both.** One subject, met and then studied. | Player profile · Prospect profile · Team profile · Staff profile · Contract talks | 120+ |
| **Broadcast + Desk** | **Both at once.** Watching, and occasionally intervening. | **Match Day** — the only surface carrying both registers in one frame | 15 |

Two consequences you must design for:

**Match Day is the thesis, not the exception.** It is the one screen where a broadcast ground
carries a management plate — a full-bleed field you watch, with a dense, undoable decision surface
floating on it. If the hybrid works anywhere it has to work there.

**Dossier is the seam, and it is where most of the product lives.** A player profile opens like a
broadcast — club colour, big mark, jersey lockup, the rating at forty points — and then, **below one
visible seam**, becomes a dense attribute table at eleven. Meeting a person and studying them are
different acts, and the surface changes register between them. The seam is a designed object, not
a divider you drop in.

### What carries the drama, given no faces

Four devices, and only four:

| Device | Why |
|---|---|
| **The team mark, huge** | 166 original marks in six families are the only art the product owns. On a broadcast surface they run 200–390 px as ground or watermark. |
| **The numeral, huge** | The number does the work the face would. A rating at 40 px on a dossier, a score at 64 px on a broadcast — against 11 px in a desk table. |
| **The jersey lockup** | A squad number in club colours is the portrait substitute: it identifies a person without depicting one. **No such component exists yet. Design it.** |
| **Club colour as ground** | Flooding, not accenting. A broadcast surface should be unmistakably one club's. |

### What each register is allowed

This table is the contract. Build it into the system so a component can declare which registers it
is legal in, and so a violation is visible rather than a matter of opinion.

| Property | Broadcast | Desk | Dossier |
|---|---|---|---|
| Ground | Club or opponent colour, flooded | Neutral `#060A12` | Club colour above the seam, neutral below |
| Team mark | 200–390 px | 19 px, in the identity band only | 180–220 px above the seam |
| Largest numeral | 40–72 px | 14 px | 40 px above, 11.5 px below |
| Data points | ≤ 12 | ≤ 72 | ≤ 8 above, ≤ 40 below |
| Geometry | Angled slabs, chevrons, cut corners | Rectangles, hairline seams | Angled above, rectangular below |
| Depth | Bloom, bevel, gradient fill | One shadow, no fills on rows | Bloom above, flat below |
| Gold | Once — the commit | At most once, often zero | Once — the commit |
| Row height | n/a | 32 pt readout · 44 pt tappable | 32 pt below the seam |

**A Desk surface is allowed exactly one broadcast element.** On the weekly hub that is the fixture
card: opponent colour, their mark at 196 px, their name at 26. Everything else on the surface stays
at desk weight.

### The density budget is measured, not chosen

Geometry gives a 709 × 319 pt content box, but the running app measures the **usable scroll
viewport at 291 pt**, and **241 pt** once a surface reserves a committing bar outside the scroll.

| Tier | Row height | Viewport | Rows | Columns | **Cells** |
|---|---|---|---|---|---|
| Dense | 32 pt | 291 | 9 | 8 | **72** |
| Working | 44 pt | 291 | 6 | 8 | **48** |
| Committing | 44 pt | 241 | 5 | 8 | **40** |
| Broadcast | — | 390 | — | — | **12** |

**Interactivity is bought with rows.** A row that responds to touch takes the 44 pt control floor,
so nine readout rows become six; reserving a commit bar takes six to five. A surface carrying a
committing control has **40 cells, not 72**.

The count is of **declared data**. Chrome, labels, captions and prose are not cells.

---

## Fixed tokens — transcribe, do not invent

Every value below is already decided, measured and contrast-checked against real grounds. **Take
them verbatim.** Where you need a value that is not here, add it and say plainly that you added it;
do not quietly redefine one that is.

Two naming rules the system enforces: **tokens name purpose, never hue**, and **views read role
aliases, never base values**.

```css
:root {
  /* ---- Grounds ---- */
  --fl-page: #060A12;
  --fl-work: #100E16;
  --fl-raised: #12203A;
  --fl-room-deep: #07060B;

  /* ---- Ink ---- */
  --fl-ink-1: #F6FAFF;
  --fl-ink-2: #A9BACE;
  --fl-ink-3: #7A8A9E;

  /* ---- Gold: the committing action, and nothing else ---- */
  --fl-gold: #FFC53D;
  --fl-gold-light: #FFE196;
  --fl-gold-deep: #D89713;
  --fl-gold-ink: #150F02;
  --fl-lamp: #FFF2CE;

  /* ---- State ---- */
  --fl-live: #37E08A;
  --fl-positive: #4FD08C;
  --fl-warning: #C9704A;   /* NOT a yellow. See the note below. */
  --fl-negative: #FF3B54;
  --fl-info: #6FA8DC;

  /* ---- Tier ---- */
  --fl-college: #B07BD6;
  --fl-pro: var(--fl-info);

  /* ---- Field ---- */
  --fl-field-turf: #072616;
  --fl-field-line: var(--fl-ink-1);
  --fl-field-annotation: #FFCE6A;
  --fl-field-live: var(--fl-positive);

  /* ---- Broadcast turf ramp ---- */
  --fl-turf: #1C6E42;
  --fl-turf-hot: #37A868;
  --fl-turf-crown: #2A8850;
  --fl-turf-mid: #124E2E;
  --fl-turf-shade: #0A311D;
  --fl-turf-night: #05150D;
  --fl-endzone-opponent: #1B2431;

  /* ---- Field markings: alphas, because paint on grass is not a palette colour ---- */
  --field-yard-line: rgba(246, 250, 255, 0.26);
  --field-hash: rgba(246, 250, 255, 0.30);
  --field-stripe-light: rgba(255, 255, 255, 0.030);
  --field-stripe-dark: rgba(0, 0, 0, 0.070);
  --field-scan: rgba(0, 0, 0, 0.070);

  /* ---- Broadcast ink ---- */
  --fl-live-ink: #FF8E9C;
  --fl-go-ink: #7DF0B6;
  --fl-cool-ink: #9CC8EE;
  --fl-bowl-ink: #C9A968;

  /* ---- Per-match identity grounds ---- */
  --fl-club-field: #0F5637;
  --fl-club-ink: #EAF3EE;
  --fl-opponent-field: #123A5E;
  --fl-opponent-accent: #9CC5E8;
  --fl-opponent-ink: #C7DEF3;

  /* ---- Ball ---- */
  --fl-ball-highlight: #A6572A;
  --fl-ball-mid: #7A3E1C;
  --fl-ball-shade: #46220F;

  /* ---- Flattened glass ---- */
  --fl-glass-flat: #11141E;
  --fl-glass-flat-deep: #0B0D14;
  --fl-overlay-scrim: #04070C;

  /* ===== ROLE ALIASES — what components read ===== */
  --world-page: var(--fl-page);
  --world-work: var(--fl-work);
  --world-raised: var(--fl-raised);

  --content-primary: var(--fl-ink-1);
  --content-secondary: var(--fl-ink-2);
  --content-quiet: var(--fl-ink-3);

  --action-primary: var(--fl-gold);
  --action-secondary: var(--fl-ink-2);
  --action-destructive: var(--state-negative);  /* an alias, not a repeat:
                                                   divergence must be deliberate */

  --state-live: var(--fl-live);
  --state-positive: var(--fl-positive);
  --state-warning: var(--fl-warning);
  --state-negative: var(--fl-negative);
  --state-info: var(--fl-info);

  --college-identity: var(--fl-college);
  --pro-identity: var(--state-info);

  --field-turf: var(--fl-field-turf);
  --field-line: var(--fl-field-line);
  --field-annotation: var(--fl-field-annotation);
  --field-live: var(--fl-field-live);

  --surface-panel: var(--fl-glass-flat);
  --surface-panel-deep: var(--fl-glass-flat-deep);
  --surface-scrim: var(--fl-overlay-scrim);

  /* Ink on a filled control is always the ground, never white.
     Measured: on gold 12.55, live 11.50, positive 10.13, warning 10.87,
     info 7.84, negative 5.67. There is no separate ink token. */
  --ink-on-fill: var(--fl-page);
  --ink-on-gold: var(--fl-gold-ink);

  /* Hairlines: two jobs, two values. Structural rule groups and is near-invisible;
     a legible seam is meant to be seen. Neither carries meaning alone. */
  --rule-structural: rgba(122, 138, 158, 0.20);
  --rule-legible: rgba(122, 138, 158, 0.38);
  --rule-glass: rgba(255, 255, 255, 0.13);
  --rule-row: rgba(255, 255, 255, 0.14);

  /* The 40–99 heat scale: FIVE bands diverging around a neutral centre.
     Always a SECOND reading of a printed figure, never the only one. */
  --heat-well-below: var(--state-negative);   /* 40–59 */
  --heat-below: var(--state-warning);         /* 60–69 */
  --heat-average: var(--content-secondary);   /* 70–79, neutral */
  --heat-above: #7FCB9E;                      /* 80–84 */
  --heat-well-above: var(--state-positive);   /* 85–99 */

  --gold-field: linear-gradient(135deg, var(--fl-gold-light), var(--fl-gold) 52%, var(--fl-gold-deep));
  --glow-gold: 0 2px 24px rgba(255, 197, 61, 0.42);
}
```

**Three colour decisions you must not undo, each of which cost something to reach:**

- **`--fl-warning` is a burnt orange, not a yellow.** A yellow caution sat 6.1° from gold at
  identical saturation and 0.6% luminance apart: at 11 pt under a thumb, a caution and a commit
  were the same colour. The replacement sits 24.1° from gold at 5.57:1 on page.
- **The heat scale has five bands, and the warm one sits *below* the median.** The three-band
  red/amber/green it replaced made an average starter read as a caution. 70–79 is neutral ink.
  Every band clears 4.5:1 on page, raised and panel, and sits ≥ 24° from gold.
- **`#65788F` is refused.** It measures 4.37 / 4.23 / 3.58 on page / work / raised and fails 4.5:1
  on every ground it would be drawn on. `--content-quiet` (`#7A8A9E`, 5.62 / 5.43 / 4.61) is the
  same role and ships in its place. Do not reintroduce it.

**Gold means one thing: this moves the game forward.** Gold never means "this is good". Positive is
green. The only two non-commit uses of gold in the entire system are the line to gain on the field
and, on a Desk surface, the single permitted commit.

### Typography

Production ships the system face: SF Pro Condensed for display roles and the system face with
monospaced digits for figures. Neither is available on the web, so the drawing substitution is
already fixed and you should keep it:

```css
--font-display: "Archivo Narrow", "SF Pro Condensed", "Helvetica Neue", system-ui, sans-serif;
--font-figure:  "IBM Plex Mono", ui-monospace, "SF Mono", Menlo, monospace;
--font-body:    var(--font-display);   /* the system has no second text family */
```

Note that **SF Pro Condensed sets wider than Archivo Narrow at the same point size** — a layout
that only just fits in the drawing will not fit in the build. Leave margin.

```css
/* Display scale, verbatim */
--size-hero: 66px;         /* career moment, ceremony */
--size-name: 60px;
--size-score: 54px;
--size-situation: 52px;
--size-score-live: 40px;
--size-figure: 34px;
--size-screen: 25px;
--size-subject: 22px;
--size-title: 20px;
--size-clock: 19px;
--size-lead: 17px;
--size-panel: 16px;
--size-row: 15px;
--size-action: 14px;
--size-action-small: 12px;
--size-pill: 10.5px;
--size-flag: 9px;

/* Semantic roles */
--type-display:  700 var(--size-title) / 1.05 var(--font-display);
--type-title:    700 var(--size-lead)  / 1.15 var(--font-display);
--type-headline: 600 var(--size-row)   / 1.25 var(--font-display);
--type-body:     400 13px              / 1.45 var(--font-body);
--type-callout:  400 var(--size-action-small) / 1.4 var(--font-body);
--type-caption:  400 11px              / 1.35 var(--font-body);

/* Floors: contract, not preference */
--type-authored-floor: 12px;   /* 10.5 and 9 are permitted for tracked uppercase
                                  micro-labels ONLY, never for prose */
--type-working-prose: 13px;

--track-label: 0.2em;    /* the 9px uppercase micro-label */
--track-flag:  0.15em;
--track-micro: 0.08em;
--track-tight: -0.02em;  /* large figures only */

--figure-features: "tnum" 1, "lnum" 1;

--weight-regular: 400;  --weight-medium: 500;
--weight-semibold: 600; --weight-bold: 700;
```

**Figures are tabular** so a score or a clock does not reflow as it counts. **Prose does not become
monospaced merely to look technical** — the figure face is for figures.

Micro-labels are **written sentence case in source and uppercased on render**, so the string stays
readable to a translator and speakable to a screen reader.

### Spacing — deliberately not a 4/8 grid

```css
--gap-hair: 2px;   --gap-tight: 3px;  --gap-xxs: 4px;   --gap-xs: 6px;
--gap-sm: 7px;     --gap-sm-plus: 8px; --gap-md: 9px;   --gap-md-plus: 11px;
--gap-lg: 12px;    --gap-lg-plus: 14px; --gap-xl: 18px; --gap-xxl: 20px;

--pad-panel: 11px 15px;   --pad-row: 10px 12px;   --pad-card: 12px 13px;
--pad-alert: 11px 16px;   --pad-band: 14px 16px;

--track-row-dense: 24px;  --track-row-dense-max: 28px;
--row-min-height: 32px;   /* a dense readout */
--row-min-target: 44px;   /* the moment it can be tapped */
```

Floodlit tunes gaps per surface; **snapping them to a grid is what makes a dense screen read as a
template.** Do not regularise these into a scale. Copy the value.

### Geometry — the house shape is an asymmetric four-corner cut

Not a rounded rectangle. Order is topLeading / topTrailing / bottomTrailing / bottomLeading, which
matches the Swift type.

```css
--radius-panel:  4px 22px 4px 22px;    /* glass panels, cards */
--radius-row:    3px 14px 3px 14px;    /* rows and chips */
--radius-action: 22px 22px 22px 5px;   /* committing controls */

--radius-card:   4px 18px 4px 18px;    /* scorebug, budget bug, call-in */
--radius-alert:  4px 24px 4px 24px;
--radius-block:  4px 20px 4px 20px;
--radius-wide:   3px 18px 3px 18px;
--radius-action-small: 18px 18px 18px 4px;
--radius-play-card: 14px 14px 6px 6px;

--radius-broadcast: 0;    /* Broadcast geometry outside Match Day is SQUARE */

/* Field scale: 703.33 px per 100 yards at the install floor.
   Every marking derives from the yard, so the field cannot drift out of scale. */
--field-yard: 7.033px;
--field-five: 35.17px;
--field-crown-x: 50%;
--field-crown-y: 56%;

--hairline: 1px;
--min-target: 44px;

/* The arc family — one idea at four scales */
--ring-diameter: 26px;  --ring-stroke-ratio: 0.12;  --ring-stroke-min: 2px;
--ring-text-ratio: 0.42;
--arc-diameter: 64px;   --arc-stroke: 11px;  --arc-start: 150deg;  --arc-sweep: 240deg;
--dial-diameter: 212px; --dial-stroke: 7px;
--share-bar-height: 4px;
--monogram: 26px;       --system-state-mark: 28px;
```

**An arc is permitted only where the datum is a proportion.** An arc that encodes a rank or a count
is a lie about the shape of the number. Build that rule into the arc components.

### Material — two rules bound it

```css
--glass-fill: 0.055;   --glass-deep: 0.70;   --glass-line: 0.13;
--glass-sheen: 0.10;   --glass-track: 0.08;  --glass-hairline: 0.045;
--glass-blur: 24px;

--depth-glass-opacity: 0.56;
--depth-deep-opacity: 0.82;   /* lowest value preserving 4.5:1 body text where a
                                 panel crosses a mown stripe */
--depth-panel-border-opacity: 0.38;

--shadow-panel:   0 18px 40px rgba(0, 0, 0, 0.62);
--shadow-card:    0 14px 32px rgba(0, 0, 0, 0.50);
--shadow-popover: 0 20px 48px rgba(0, 0, 0, 0.74);
--shadow-stage:   0 24px 60px rgba(0, 0, 0, 0.60);

--inset-panel: inset 0 1px 0 rgba(246, 250, 255, 0.09),
               inset 0 0 0 1px rgba(122, 138, 158, 0.26);
--sheen-panel: linear-gradient(148deg, rgba(255, 255, 255, 0.10), transparent 62%);

--grain-tile: 128px;  --grain-opacity: 0.5;   /* overlay, over everything */
```

1. **Nothing decorative may carry meaning.** A panel's material never encodes a value.
2. **Blur only where something is genuinely in front of something else.** Non-hero glass
   **flattens** to a solid `--surface-panel` fill rather than stacking blur over a transformed
   plane, which smears.

**Three worlds, one variable.** The backdrop is the single thing that changes per screen, and it is
a fact supplied by the read model, not a guess made by the view. Film is the one place the light
goes cold.

```css
--world-pitch: radial-gradient(52% 62% at 78% 2%, rgba(255,242,206,.22), transparent 70%),
               linear-gradient(180deg, rgba(7,6,11,0) 58%, rgba(7,6,11,.55) 100%),
               repeating-linear-gradient(90deg, rgba(246,250,255,.04) 0 1px, transparent 1px 92px),
               linear-gradient(135deg, #060A12, #100E16 50%, #060A12);
--world-facility: radial-gradient(60% 55% at 12% 0%, rgba(255,242,206,.14), transparent 68%),
                  linear-gradient(180deg, rgba(7,6,11,0) 54%, rgba(7,6,11,.60) 100%),
                  linear-gradient(135deg, #070A11, #12111A 52%, #070A11);
--world-film: radial-gradient(46% 58% at 50% -6%, rgba(156,200,238,.16), transparent 72%),
              linear-gradient(180deg, rgba(4,7,12,0) 50%, rgba(4,7,12,.70) 100%),
              linear-gradient(135deg, #05070E, #0B0D14 50%, #05070E);
--world-bottom-bleed: 0.55;
```

### Motion — one curve, five durations

```css
--ease: cubic-bezier(0.32, 0.72, 0, 1);

--dur-press: 0.12s;         /* press dim */
--dur-value: 0.22s;         /* a value settling to its new figure */
--dur-panel-enter: 0.24s;
--dur-world: 0.42s;         /* a world changing */
--dur-pulse: 1.5s;          /* the live dot — a period, not a duration */

--panel-push-distance: 14px;
--press-dim: 0.12;          /* press DIMS; a committing action never shrinks under
                               the thumb that is committing with it */
--disabled-opacity: 0.4;
```

**Motion is spent only to carry a state change that is already true without it** — a value settling,
a panel entering, a snap replaying. Never to manufacture meaning that motion alone supplies.

### Frame and stage

Every management surface is composed at the install floor with absolute positions. **There is no tab
bar.** Navigation lives in the identity band: family on the left, jump-to on the right, plus a
narrow icon rail.

```css
--floor-width: 844px;   --floor-height: 390px;

--sensor-housing: 59px;  --home-indicator: 21px;  --gutter: 20px;
--leading-inset: 63px;   /* sensor housing + 4 clearance */
--bottom-inset: 25px;    /* home indicator + 4 clearance */
--top-inset: 12px;

--rail-leading: 59px;  --rail-width: 44px;  --rail-top: 46px;  --rail-gap: 2px;

--content-leading: 115px;
--content-top: 46px;
--content-width: 709px;      /* 844 − 115 − 20. Derived, so it stays right if the floor moves */
--rail-free-leading: 63px;   /* Title, Job Board and Offer carry no rail */

--header-top: 3px;  --header-primary-row: 22px;  --header-secondary-row: 16px;
```

**Content column widths are deliberate, not fluid.** A surface uses either the full 709 or one of
these named narrower columns, with the world showing beside it:
`150 250 300 330 345 380 396 400 402 404 410 420 428 430 474 697 709 761`

### Identity injection

Club identity enters the system through a small number of per-instance variables, never through
hard-coded colour: `--club`, `--club-line`, `--fl-flood`, `--tint`. Every component that carries
club identity reads one of these. Keep that seam — it is what lets 166 generated marks and colour
pairs flow through one set of components.

---

## Accessibility contract — binding, not aspirational

- **44 × 44 pt touch floor.** Stricter than Apple's stated 28 × 28 minimum, deliberately.
- **AX5 (the largest accessibility type size) is binding.** AX5 **expands and reflows rather than
  shrinking.** A dense table at AX5 becomes a different composition, not a smaller one. Design the
  AX5 branch, do not assume it.
- **Colour is never the only carrier of meaning.** The two-sided comparison marks its leading side
  with a wedge, not a colour. The heat band is always a second reading of a printed figure.
- **Reduce Motion** replaces travel, reveal and field animation with discrete state changes.
- **Reduce Transparency** removes glass, grain and blur and falls back to opaque work/raised fills
  at the same depth order. This is **mandatory** — no component may render glass without that
  branch.
- **Reading order** is: world context → dominant object → evidence → actions → local navigation.
- **Loading never displays invented percentage progress.**
- **Empty, error, interrupted and resume states stay inside the composition they belong to.** They
  are not separate screens you route to.

---

## What to produce

A design system, organised so that a builder can draw any surface in this product without inventing
a value. Concretely:

**1. The token layer.** Everything above, transcribed exactly, organised by purpose, with the base
values and the role aliases kept as distinct layers. Document *why* for the three colour decisions
that cost something (warning hue, five heat bands, the refused `#65788F`) — a system that loses its
reasons gets those decisions reverted by the next person.

**2. A register-aware component library.** This is the part that does not exist yet and is the real
work. Every component declares **which registers it is legal in**, and carries its per-register
variant where it has one. A panel is not one component with a `variant` prop bolted on; Broadcast
and Desk are different enough that the system should make an illegal combination hard to express.

Components the surfaces demonstrably need, at minimum:

- *Chrome*: identity band (34 pt, club-primary gradient to page, mark at 19), icon rail, content
  plate, commit bar
- *Structure*: glass panel with head/body/meta, dense table, readout row, tappable row, chip,
  the **seam** (the Dossier's register change, a designed object)
- *Broadcast*: flooded hero with mark watermark, angled slab, chevron and cut-corner shapes,
  the ceremony headline lockup
- *Identity*: the **jersey lockup** (squad number in club colours — the portrait substitute, and
  currently missing), the mark at each sanctioned scale, the team crest in a row
- *Figures*: the heat band with its printed legend, the confidence **range** (a rating drawn as
  a range whose width is the confidence, plus an `Unseen` state), the arc family at four scales,
  the share bar, the meter that **overruns its track rather than clamping** when a cap is
  breached, the opposed comparison, the form strip
- *Match Day*: the field at 703.33 px per 100 yards with derived markings, the scorebug carrying
  both teams' identity, the call-in plate, the undo affordance
- *States*: empty, loading, error, interrupted, resume — as compositions, not as screens

**3. Three register templates**, at 844 × 390, that a surface can be composed into: Broadcast,
Desk, Dossier — plus the Match Day hybrid, which is its own thing.

**4. The rules, written as rules.** Gold spent once. Arc only for proportions. Nothing decorative
carries meaning. Blur only for real occlusion. Colour never the only carrier. Cell budget per tier.
A system whose constraints live only in prose gets violated within a week; where you can express a
rule as a constraint of the component API rather than a paragraph, do that instead.

### The sufficiency test

The system is finished when it can draw these **without inventing a value** — the surfaces that
currently have design sheets, or an obvious need, and no design:

- **Responsibilities** — where delegation is configured, as opposed to exercised. Eleven ownership
  areas, each resolving to a named person, each printing what they yield, plus the interrupt
  thresholds that end a cruise.
- **While You Were Away** — what happened during delegated weeks. *Invisible delegation is
  indistinguishable from a bug*, which is why this is not optional.
- **Season Expectations** and **Season Review** — a season currently has no beginning and no
  ending. For a career game whose whole arc is college to pro, that is the most conspicuous hole.
- **Compare** — two players side by side, attribute against attribute. A core verb of the genre
  that no surface performs.
- **Championship Result** — the fifth ceremony, with no surface at all.
- **The four ceremony surfaces that are stubs** — Signing Day, Draft Room, Awards, Promotion
  Decision. The entire Broadcast register is currently unbuilt.
- **Four overlay layers that render over any surface**: First Run, Teaching, Failure, System State.
  These carry no screen ID, which is exactly why nothing caught their absence. **Teaching's
  benchmark is a browsable in-game encyclopedia** — a term, a definition, links to related terms, a
  live panel showing the player's own instance of the concept, and its own back and forward
  navigation.
- **Save & Continuity** and **Appearance**.

If drawing one of these forces a new token, that is a real finding — add it and say so.

---

## Known unresolved — surface these, do not silently resolve them

**A Dossier that bands a rating cannot also commit at the install floor.** The head wants 180–220 pt;
the band table must sit beside the banded figure; reserving a commit bar leaves 241 pt. The three do
not fit together. The current drawing omits the bar and routes to a separate committing surface
instead. **This is an owner question, not a drawing choice** — if your composition resolves it,
say how and flag it as a proposal.

**One live contradiction in the type scale.** An unmerged branch halves the display scale, deletes
the icon rail from the stage, and moves the rating floor — while carrying the only executable proof
that committing actions stay inside the viewport. It cannot be discarded and cannot be merged as-is.
Design against the scale given above, and note anywhere a halved scale would change your answer.

**Several data dependencies do not exist**, and the design must declare the gap rather than fake the
precision. Chiefly: there is **no scouting-confidence model**, so ratings are point values today,
even though the system requires an unearned rating to be drawn as a range whose width is the
confidence, and `Unseen` where nothing has been observed. Design the range and the `Unseen` state
anyway — they are the correct design, and drawing them is what makes the gap visible.

Where two sources disagree, **print both values rather than averaging them.**
