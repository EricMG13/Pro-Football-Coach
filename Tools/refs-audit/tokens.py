"""Design tokens as DATA. emit_css() renders them; checks.py asserts against
the same values. No other module holds a colour. Canon: docs/04 6.1a, 6.1a(ii),
6.4 (2026-08-22 amendments)."""

PAGE, RAISED, PANEL = "#060A12", "#12203A", "#11141E"

# 6.1a(ii): gold is the committing action and nothing else. state.warning left
# the yellow band because it sat 6.1 deg from gold at identical saturation.
GOLD = "#FFC53D"
WARNING = "#C9704A"          # was #FFB03A. 24.1 deg from gold, 5.57:1 on page.

# 6.4: five bands, diverging around a neutral centre. Average is NOT amber.
HEAT = [("well-below", 40, 59, "#FF3B54"),
        ("below",      60, 69, WARNING),
        ("average",    70, 79, "#A9BACE"),   # content.secondary, neutral
        ("above",      80, 84, "#7FCB9E"),
        ("well-above", 85, 99, "#4FD08C")]

BASE = {
  "fl-page": PAGE, "fl-work": "#100E16", "fl-raised": RAISED, "fl-room-deep": "#07060B",
  "fl-ink-1": "#F6FAFF", "fl-ink-2": "#A9BACE", "fl-ink-3": "#7A8A9E",
  "fl-gold": GOLD, "fl-gold-light": "#FFE196", "fl-gold-deep": "#D89713",
  "fl-gold-ink": "#150F02", "fl-lamp": "#FFF2CE",
  "fl-live": "#37E08A", "fl-positive": "#4FD08C", "fl-warning": WARNING,
  "fl-negative": "#FF3B54", "fl-info": "#6FA8DC",
  "fl-college": "#B07BD6",
  "fl-turf": "#1C6E42", "fl-turf-hot": "#37A868", "fl-turf-crown": "#2A8850",
  "fl-turf-mid": "#124E2E", "fl-turf-night": "#05150D",
  "fl-club-field": "#0F5637", "fl-club-ink": "#EAF3EE",
  "fl-opponent-field": "#123A5E", "fl-opponent-ink": "#C7DEF3",
  "fl-glass-flat": PANEL, "fl-glass-flat-deep": "#0B0D14",
}

# 6.1a(ii): duplicate roles are ALIASES, never repeated literals.
ALIAS = {
  "world-page": "fl-page", "world-work": "fl-work", "world-raised": "fl-raised",
  "content-primary": "fl-ink-1", "content-secondary": "fl-ink-2", "content-quiet": "fl-ink-3",
  "action-primary": "fl-gold", "action-secondary": "fl-ink-2",
  "action-destructive": "fl-negative",          # alias, not a literal
  "state-live": "fl-live", "state-positive": "fl-positive",
  "state-warning": "fl-warning", "state-negative": "fl-negative", "state-info": "fl-info",
  "college-identity": "fl-college",
  "fl-pro": "fl-info",          # alias: was a duplicate literal of fl-info
  "pro-identity": "fl-info",                    # alias, not a literal
  "surface-panel": "fl-glass-flat", "surface-panel-deep": "fl-glass-flat-deep",
  "ink-on-gold": "fl-gold-ink",
}

# 4.5a: budgets follow the MEASURED viewport, not the 319pt box.
VIEWPORT, VIEWPORT_COMMIT = 291, 241
CELLS = {"DESK": 72, "DOSSIER": 48, "BROADCAST": 12, "MATCH_DAY": 72}
MARK = {"DESK": (19, 19), "BROADCAST": (200, 390), "DOSSIER": (180, 220), "MATCH_DAY": (19, 390)}

def emit_css():
    L = [":root {"]
    for k, v in BASE.items():   L.append(f"  --{k}: {v};")
    for k, v in ALIAS.items():  L.append(f"  --{k}: var(--{v});")
    for n, lo, hi, v in HEAT:   L.append(f"  --heat-{n}: {v};   /* {lo}-{hi} */")
    L += [f"  --viewport: {VIEWPORT}px;", f"  --viewport-commit: {VIEWPORT_COMMIT}px;",
          "  --band-height: 34px;", "  --seam: 2px;", "}"]
    return "\n".join(L)
