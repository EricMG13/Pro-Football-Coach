# Contextual Photo Worlds Pilot — Handoff Prompt

Implement the approved contextual photo-world pilot in `/Users/ericguei/Documents/Pro-Football-Coach` by executing:

`docs/superpowers/plans/2026-08-19-contextual-photo-worlds-pilot.md`

Use `superpowers:subagent-driven-development` if the user explicitly authorises sub-agents; otherwise use `superpowers:executing-plans` inline. Read `AGENTS.md` and the complete plan before acting.

Non-negotiable scope:

- Reuse the existing `FloodlitChromeReadModel.World` cases: `pitch`, `facility`, and `film`.
- Bundle exactly three licence-recorded environmental photographs through the SwiftPM UI resource bundle.
- Keep all images offline, static, accessibility-hidden, and within the plan's byte and contrast budgets.
- Reject visible people, faces, uniforms, real team/league/venue marks, sponsors, equipment brands, artwork, and projected real-game footage.
- Do not change any screen-specific view, read model, route, simulation code, save data, or Match Day/BROADCAST renderer.
- Do not add per-screen variants, downloads, caching, parallax, animation, a feature flag, a new world enum, or a dependency.
- Preserve all unrelated dirty-worktree changes.

Before editing each indexed symbol or file, run GitNexus upstream impact analysis and report the blast radius. Warn and pause on HIGH or CRITICAL risk. Before every commit, run GitNexus `detect_changes()` and review every affected process.

Follow the plan task-by-task with its failing-test-first sequence and exact file boundaries. Use the official Pexels or Unsplash site for sourcing; save complete source/licence metadata and the SHA-256 of the exact cropped file. A provider copyright licence does not clear depicted trademarks, publicity rights, or artwork, so the visual inspection is a hard gate.

After non-trivial renderer edits, run `rewrite-tournament` in post-edit mode on the changed functions. Before claiming completion or committing code, run `confidence-review`, investigate every uncertainty to root cause, and patch confirmed defects.

Required completion evidence:

- focused and full test commands from the plan;
- built-app confirmation that all three assets are present;
- the 18-image proof matrix for Coaching HQ 8, Film Room 10, and Roster 16 at 844 × 390, 852 × 393, and 956 × 440, default and AX5;
- manual Reduce Transparency, Increase Contrast, Differentiate Without Color, and Match Day isolation checks;
- licence ledger with no blank fields;
- final GitNexus comparison against `main`;
- concise report of files changed, tests run, proof paths, licensing sources, and any residual manual-only risk.

If the photographs cannot remain recognisable within the tested contrast treatment, reject the asset rather than weakening accessibility or changing panels. If Roster still feels flat after the three-world pilot, report that honestly; foreground hierarchy is explicitly a separate follow-up, not permission to broaden this implementation.
