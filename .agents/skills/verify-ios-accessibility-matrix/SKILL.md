---
name: verify-ios-accessibility-matrix
description: Verify accessibility coverage for every canonical landscape-iPhone screen. Use after adding or changing a production SwiftUI screen, component, interaction, state, or design token, and before declaring a UI milestone complete.
---

# Verify iOS Accessibility Matrix

Build the coverage manifest from the canonical screen inventory and verify the production registry
matches it exactly.

## Workflow

1. Run `python3 .agents/skills/verify-ios-accessibility-matrix/scripts/build_matrix.py` from the repository root.
2. Stop if the inventory is not exactly 62 uniquely numbered screen families or the Swift registry
   differs by number or name. Fix the canon or registration defect; do not exclude the screen.
3. Run `swift run SimTests --core-contracts`.
4. When a production app target can launch, exercise every generated device, appearance, type-size, sensor-orientation and state combination. Record geometry, focus, labels, values, actions, contrast and Reduce Motion as automated evidence.
5. Verify VoiceOver reading order and announcements, Voice Control names, Switch Control reachability, sound equivalents and haptics on a physical device. Keep these cells marked `manual-required` until a person verifies them.
6. Report automated and manual evidence separately. Headless or simulator automation cannot prove spoken clarity, motor-control usability, sound or haptics.

## Pass contract

- Every canonical screen is present in the generated manifest.
- Every axis is covered by construction; a missing cell is a failure.
- Automated checks have reproducible commands or artifacts.
- Manual-only checks name the device, OS, tester and result.
- No failure is waived by reducing text size, touch targets, safe areas or state coverage.

The generated manifest is a plan, not proof. Its initial statuses deliberately remain `not-run` and `manual-required`.
