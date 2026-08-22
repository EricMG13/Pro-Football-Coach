# Tools/refs — surface reference frames

Generates one drawn frame per Coach World surface at the install floor (844x390), with a
declared register of what is not built beneath each, and checks fourteen rules over the
result. Output is a single self-contained HTML file plus a JSON gap manifest.

```bash
python3 Tools/refs/build.py --check     # rules only, non-zero exit on failure
python3 Tools/refs/build.py --both      # check, then write docs/refs/
python3 Tools/refs/build.py --only coachingHQ matchDay roster   # a few frames, to look at
python3 Tools/refs/test_checks.py       # mutation test: prove every rule can fail
```

Nothing in `Sources/` changes. Zero dependencies beyond the standard library.

## Shape

```
tokens.py       parses tokens/*.css; nothing re-authors a design value
marks.py        the 13 vendored marks, resolved against the pinned baseline catalogue
primitives.py   eight body primitives that report cells, rows, height and gold
chrome.py       header, rail, plate, seam, committing bar -- derived, never declared
screens.py      the 62 Swift cases, transcribed and frozen; check 2 re-parses and compares
registry/       the 59 surfaces, one module per family
render.py       one loop, no per-surface branch
page.py         the document shell and the gap roll-up
checks.py       the fourteen rules; nothing imports it
build.py        the CLI
```

`tokens/` is the design system's own export, vendored verbatim. `assets/` holds the marks.

## The two things that make the checks worth running

**Budgets are measured on the registry, not on emitted HTML.** A leaf-text count cannot
tell a column head from a value; measured that way the published artifact read Roster at
78 cells and Signing day at 17 while counting prose.

**Every rule is mutation-tested.** `test_checks.py` breaks the registry one specific way
per rule and requires that rule to fire. Two rules passed their first draft while doing
nothing — rule 9 compared the generator's constant to itself, and rule 5 counted rows
while six frames clipped. A rule that cannot fail is decoration.

See `docs/refs/BASELINE.md` for which commit identities resolve against and why, and
`docs/refs/DECISIONS.md` for every number here that disagrees with one written elsewhere.
