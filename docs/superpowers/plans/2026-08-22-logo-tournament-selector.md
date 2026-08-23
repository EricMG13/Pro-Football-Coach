# Logo Tournament Selector Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task.

**Goal:** Build a local static site that lets the team advance logo candidates through rounds and export exactly one final logo for each of the 166 authoritative teams.

**Architecture:** A stdlib Python builder scans registered worktrees and reachable Git history, byte-deduplicates individual logo assets, writes a generated catalog/archive, and a dependency-free HTML/ES-module selector persists tournament rounds locally. The existing remake selector remains untouched.

**Tech Stack:** Python 3 stdlib, Git CLI, static HTML/CSS/JavaScript, Node built-in test runner.

## Global Constraints

- The manifest at `Tools/TeamLogos/manifest.json` is authoritative: 166 teams and one final selection per `stableID`.
- Include raw, temporary, normalized, generated, canonical, handoff, and historical versions. Keep composite contact sheets and preview canvases in the audit instead of the candidate grid.
- Match only by current `assetName`, an exact normalized team-name filename match, or existing source metadata. Do not infer a team from nicknames or visual similarity.
- Generated image payloads stay ignored; source, tests, and static UI are tracked.
- No new dependency, deployment, server, database, or change to the existing `logo-selector.html`.

---

### Task 1: Add a catalog builder and focused Python tests

**Files:**
- Create: `Tools/TeamLogos/build_tournament_catalog.py`
- Create: `Tools/TeamLogos/test_build_tournament_catalog.py`

- [ ] Write a builder with small pure helpers for image classification, exact team matching, SHA-256 deduplication, and archive overwrite protection.
- [ ] Read the manifest's `.teams` mapping and validate 166 unique stable IDs and asset names before scanning candidates.
- [ ] Test the exact matching, composite exclusion, duplicate merge, and refusal to replace a different archived byte stream.

Run:

```bash
python3 -m unittest Tools.TeamLogos.test_build_tournament_catalog
```

Expected: all tests pass before connecting the scanner to real worktrees.

### Task 2: Scan worktrees and reachable history into an ignored catalog

**Files:**
- Modify: `.gitignore`
- Modify: `Tools/TeamLogos/build_tournament_catalog.py`
- Generated (ignored): `artifacts/team-mark-review/tournament-catalog.json`
- Generated (ignored): `artifacts/team-mark-review/tournament-assets/`

- [ ] Enumerate `git worktree list --porcelain`, recording unavailable worktrees in the audit.
- [ ] Scan known logo roots in each worktree, then `git rev-list --objects --all` blobs whose paths are individual logo images.
- [ ] Deduplicate content by SHA-256, retain all origins/stages, write the first verified copy as `tournament-assets/<sha>.<suffix>`, and fail safely on a differing existing file.
- [ ] Add the generated catalog and asset directory to `.gitignore`.
- [ ] Validate every authoritative asset name has at least its canonical candidate and the output contains no repeated SHA-256 values.

Run:

```bash
python3 Tools/TeamLogos/build_tournament_catalog.py
python3 -c "import json; d=json.load(open('artifacts/team-mark-review/tournament-catalog.json')); assert len(d['teams']) == 166; assert len({c['sha256'] for c in d['candidates']}) == len(d['candidates'])"
```

Expected: catalog creation succeeds and records candidates, unassigned individual files, excluded composites, origins, and worktree coverage.

### Task 3: Implement the tournament state model with Node tests

**Files:**
- Create: `artifacts/team-mark-review/tournament-state.js`
- Create: `artifacts/team-mark-review/tournament-state.test.mjs`

- [ ] Keep state as `{ fingerprint, rounds }`, where a round snapshots its candidate IDs and checked IDs.
- [ ] Advance only checked candidates; returning to an earlier round removes all later snapshots.
- [ ] Calculate final readiness only when the current checked set contains exactly one matched candidate for every manifest team.
- [ ] Reject stale/malformed localStorage sessions rather than using them.

Run:

```bash
node --test artifacts/team-mark-review/tournament-state.test.mjs
```

Expected: checks cover advance, rewind truncation, stale session rejection, and the one-per-team final gate.

### Task 4: Build the local interactive review page

**Files:**
- Create: `artifacts/team-mark-review/tournament-selector.html`
- Modify: `artifacts/team-mark-review/tournament-state.js`

- [ ] Fetch `tournament-catalog.json`, restore namespaced local state keyed by catalog fingerprint, and present a clear missing-catalog error.
- [ ] Render a responsive, keyboard-accessible candidate grid with native checkboxes, logo preview, team, stage, source count, and abbreviated content hash.
- [ ] Add search plus team/family/stage/source/state filters; candidate cards remain native-label clickable and controls meet a 44px touch target.
- [ ] Add round progress, advance/return controls, a disabled-until-ready final JSON download, and a text audit download.
- [ ] Show unassigned individual files and excluded composites in expandable audit panels so every discovered version remains accounted for.
- [ ] Match the existing DESK review-tool visual language: near-navy field, violet panels, and chartreuse selection/progress accents.

Run:

```bash
python3 -m http.server 4173 --directory artifacts/team-mark-review
curl -fsS http://127.0.0.1:4173/tournament-selector.html >/dev/null
```

Expected: the page and its generated catalog are served locally; no public hosting is created.

### Task 5: Verify, review, and preserve worktree boundaries

**Files:**
- Review: all files above

- [ ] Run Python and Node checks from Tasks 1 and 3, regenerate the catalog, and recheck the 166-team invariant.
- [ ] Run `rewrite-tournament` post-edit mode for changed production functions and apply any confirmed simplification.
- [ ] Run `confidence-review`, investigate each concern, and fix confirmed defects.
- [ ] Stage only this task's tracked source/doc files, run GitNexus `detect_changes(scope: "staged")`, and ensure no unrelated user worktree changes are included.

Expected: the local review site works against the complete inventory, guards the final export at 166 one-per-team selections, and leaves unrelated work untouched.

## Review Notes

- No implementation dependency exceeds Python/Node already present in the repository.
- The archive is regenerated from the current worktree plus Git objects, so it deliberately stays out of version control.
- The fallback matcher is intentionally strict; unknown candidates remain visible in the audit instead of receiving an incorrect team assignment.
