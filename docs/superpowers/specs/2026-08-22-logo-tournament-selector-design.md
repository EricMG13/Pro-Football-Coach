# Logo Tournament Selector Design

**Date:** 2026-08-22  
**Status:** Approved for implementation

## Goal

Build a local interactive site for reducing every recoverable team-logo version to the final 166 game logos through successive checkbox-based rounds. Completion requires exactly one selected logo for each team in the current 166-team manifest.

## Source inventory

The inventory covers all 40 worktrees currently registered with the repository and all logo-related PNG blobs reachable through Git history. The initial audit found 2,031 distinct historical logo-related blobs, of which 1,772 appear to be individual logo versions after excluding composite review sheets. The generator must also include uncommitted worktree-only files, including raw, temporary, normalization, remake, and generated variants.

Identical image content found at multiple paths or in multiple worktrees is represented once. Its record retains every discovered origin. Composite contact sheets, phone previews, and review canvases are not selectable logo versions; they may be reported as excluded audit material.

## Reuse and architecture

Extend the existing dependency-free selector in `artifacts/team-mark-review/` instead of introducing a framework.

The implementation has two parts:

1. A manifest generator scans registered worktrees and reachable Git history, hashes image content, extracts historic blobs when needed, and writes a self-contained archive under the selector directory.
2. A static HTML/CSS/JavaScript interface loads that generated manifest, manages tournament rounds in browser storage, and exports the final decision file.

The generated archive keeps the site independent of worktree paths that may later disappear. It must not modify or remove any discovered source asset.

## Candidate matching

The current `Tools/TeamLogos/manifest.json` defines the authoritative 166 teams and their asset mappings.

Candidates are assigned to a team in this order:

1. Exact current `assetName` found in a `TeamLogo_<ID>` filename.
2. Exact normalized current team name found in a descriptive filename.
3. Existing review metadata that explicitly names the team or asset.

Candidates that cannot be matched safely remain visible in an unassigned archive. They do not count toward any team's final choice and are never assigned heuristically.

## Tournament interaction

The first round contains every matched candidate. Each candidate card shows the logo, team, version/stage label, content hash fragment, and its worktree/history origins. Light, dark, and split preview surfaces remain available.

Users check every candidate that should advance, then start the next round. Advancing stores a round snapshot and makes only the selected candidates eligible in the next round. The user can return to a previous round; changing it discards its later rounds before the next advance.

Search and filters cover team, family, source worktree, generation stage, selected state, and teams with unresolved final choices. Progress always reports:

- current round;
- candidates remaining;
- teams represented;
- teams with no candidate selected;
- teams with multiple candidates selected.

The final action is disabled until there are exactly 166 selected candidates and every authoritative team is represented exactly once. No candidate is selected automatically.

## Persistence and export

Round history and the current selection persist in `localStorage` under a versioned key tied to the generated catalog fingerprint. A catalog change starts a new state rather than applying stale selections silently.

The final JSON export contains, for each team, its stable ID, team name, asset name, chosen candidate hash, archived image path, stage, and all known origins. A second downloadable text report summarizes excluded composites and unassigned experiments for auditability.

## Visual direction and accessibility

The selector follows the project's DESK register: compact near-navy workspace, violet navigation/action furniture, chartreuse reserved for current selection state, restrained dividers, and dense two-pane hierarchy. The design stays utilitarian and avoids generic card-dashboard decoration.

Every card is a labelled checkbox with visible keyboard focus. Status updates use live regions. Touch targets remain at least 44 points, controls retain visible text, color is never the sole selection cue, and motion respects `prefers-reduced-motion`.

## Failure handling

The generator fails with a clear error if the authoritative manifest is not 166 unique teams, a source file cannot be read, an extracted Git blob is not an image, or generated output would overwrite a non-generated file.

The site shows a blocking catalog error when the generated data is absent or malformed. A missing candidate image remains listed with its origin and error state instead of disappearing.

## Verification

The smallest runnable checks must prove:

- all 40 inventoried worktrees were considered or explicitly recorded as unavailable;
- all distinct matched individual versions are represented once by content hash;
- all 166 authoritative teams have at least one candidate;
- round advancement preserves only checked candidates;
- editing an earlier round invalidates later rounds;
- finalization rejects zero or multiple selections for any team;
- final export contains exactly 166 unique team records;
- the static site loads successfully from the repository's local server.

## Deliberate exclusions

No hosted deployment, account system, shared database, collaborative voting, automatic aesthetic ranking, or automatic replacement of production assets is included. Add shared persistence only if selection must move between people or devices; add production-asset application only after the exported 166 choices are approved.
