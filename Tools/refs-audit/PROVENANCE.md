# Provenance

This directory is a second, independently written checker for the Floodlit Surface
Register. It arrived on `codex/logos` at `9f3ae2a` ("tools(refs): add the
surface-register rule checks"), authored against the same `docs/04` amendments of
2026-08-22 as `Tools/refs/`, and at the same paths. `README.md`, `build.py`,
`checks.py`, `tokens.py`, `.gitignore` and `extract.py` are that commit's files
verbatim; only this note was added.

## Why two checkers, and why this one is not at `Tools/refs`

They check different objects, so neither subsumes the other:

- `Tools/refs/` **generates** the register from a typed registry and asserts 23 rules
  against that registry before it renders. A defect is caught before it reaches HTML.
- `Tools/refs-audit/` **reads an already-published page** and asserts 17 rules against
  the emitted markup. It cannot prevent a defect, but it sees the artifact the reader
  sees, including anything the generator does after its own checks run.

The second is the weaker position for day-to-day work and the stronger one for an
audit, because it shares no code, no data structures and no assumptions with the
generator. It is kept for that: an outside opinion on a page `Tools/refs/` says is
clean. `Tools/refs/` remains the shipping tool.

Their independence has already paid once. `9f3ae2a`'s message records that its rules
caught `#6FA8DC` written twice, once as `fl-info` and once as `fl-pro`; the alias
closure rule in `Tools/refs/checks.py` (rule 17) found the same duplicate separately.
Two unrelated checkers converging on one defect is the evidence that the defect was
real and not an artefact of how either tool looks.

## Result of running it against the current register

Built `docs/refs/surface-references.html` from `Tools/refs/`, lifted it with
`extract.py`, and ran `checks.py`: **16 of 17 rules pass**. Two results need reading
before the number is trusted.

**Rule 7 ("every surface declares a lean") fails, and the failure is not real.**
`extract.py` reads the lean from a `register="..."` attribute on each entry, a shape
the earlier generator emitted. `Tools/refs/` states the lean elsewhere, so extraction
returns the empty string for all 59 surfaces and the rule fails uniformly. The
register does declare a lean on every surface: 44 DESK, 9 BROADCAST, 5 DOSSIER,
1 MATCH_DAY, none missing.

**Rule 6 ("cell budget per lean") passes, and the pass proves nothing.** It reads
`tokens.CELLS.get(x['register'], 72)`, so the same empty lean silently selects the
72-cell default and the DOSSIER (48) and BROADCAST (12) budgets are never applied.
This is the failure `CLAUDE.md` names: the coverage boundary quietly became the
quality boundary. That ground is covered non-vacuously by `Tools/refs/` rule 3, which
the mutation suite exercises two ways ("36 cells in a BROADCAST frame" and "13 cells
above the dossier seam"); both fire.

Fixing `extract.py` to read this generator's shape would convert rule 7 to a pass and
give rule 6 something to test. That work is not done here, so treat "16 of 17" as
15 meaningful passes, 1 false failure and 1 vacuous pass.

## Running it

    python3 extract.py /path/to/a/published/register.html   # writes data.json
    cp /path/to/that/register.html surface-register.html
    python3 checks.py                                        # 0 = all pass

`build.py` is a reference builder, not a shipping generator. It will not run as
committed: its `SRC` is an absolute path into a per-session tool-results directory on
one machine. Repoint it before use, or use `Tools/refs/build.py` instead.
