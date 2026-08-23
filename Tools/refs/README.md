# Surface-register checks

Seventeen rules asserting that a generated surface register obeys `docs/04`, including
the 2026-08-22 amendments (§2.1 lean, §4.5a budget, §6.1a(ii) role separation,
§6.1d identity band, §6.4 five heat bands and ranged ratings).

    python3 checks.py          # exit 0 = all pass, 1 = failures listed

Checks a built `surface-register.html` in this directory. To check a page published
elsewhere, drop it in as `surface-register.html` first.

## Files

| File | Role |
|---|---|
| `tokens.py` | Palette, budgets and lean-to-mark mapping **as data**. `emit_css()` renders them; `checks.py` asserts against the same values, so a token cannot drift from its own rule. |
| `extract.py` | One-time lift of 59 surfaces + 107 gaps out of a published register into `data.json`. Works because the generator enforces palette closure, so frame HTML is token-only. |
| `build.py` | Reference builder. Not the shipping generator — kept because it exercises the checks. |
| `checks.py` | The rules. Pure Python, no browser. |

## Two rules worth knowing before you edit them

**Check 6 counts cells on the registry, not the HTML.** A leaf-text count over-reports
badly: measured against a hand-authored page it read Roster at 78 and Signing Day at 17
while counting chrome, labels and captions as data. Budgets are only meaningful over
*declared* data.

**Check 10 exempts `--club` and `--club-line`.** Club colours are world data, not
palette — §5.2 makes the mark and its pair a per-programme fact, and §6.1a requires a
team fill to carry its own hairline. Everything else in the body must reach colour
through a token. `10b` asserts the exemption is not a loophole: every literal colour in
the body must arrive as one of those two properties.

## What these checks cannot see

No browser runs here, so: resolved tap-target height after flex, real text wrap and
clipping at true font metrics, focus-ring visibility, geometry after `clip-path`, and
Dynamic Type reflow. Assert the declared `min-height` token instead and run one manual
pass on the published page.
