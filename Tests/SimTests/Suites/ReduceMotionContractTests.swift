import Foundation
@testable import ProFootballCoachUI

/// `PRODUCT.md` commits: *"Reduce Motion honoured on every animation → ReduceMotionContractTest."*
/// Before this file, that named a registered `ReleaseGateID` case and nothing else —
/// `runCommitmentCoverageTest` only checks the name is registered, never that a runner exists behind
/// it. This file is the runner, and `04` section 7.1 clause 3 is the rule it checks.
///
/// Reuses `landedFamilies()` from `AccessibilityReflowTests.swift` — the same partition, not a
/// second one, so the two contracts cannot silently cover different sets of families.

/// Tier-B constructs: motion primitives the choke point cannot wrap, because SwiftUI requires them
/// to sit directly in the view that uses them rather than behind a modifier.
private let tierBConstructs: [String] = [
    "TimelineView(", ".matchedGeometryEffect(", ".phaseAnimator(", ".keyframeAnimator(",
    ".symbolEffect("
]

private func usesTierBConstruct(_ text: String) -> Bool {
    tierBConstructs.contains { text.contains($0) }
}

func runReduceMotionContractTests() {
    suite("Reduce Motion contract") {
        test("every screen family is landed, pending, or aliased, and the split is total") {
            // Re-asserted rather than assumed from AccessibilityReflowTests: if the
            // <Name>View.swift convention ever drifts, both contracts must fail, not just AX5's.
            let (landed, pending, aliased) = landedFamilies()
            expectEqual(landed.count + pending.count + aliased.count,
                        CoachWorldScreenID.allCases.count,
                        "the partition lost a family, so some family is checked by nothing")
            expectEqual(CoachWorldScreenID.allCases.count, 62)
            expect(!landed.isEmpty, "no family view was found — the scan would pass vacuously")
        }

        test("every landed family using a Tier-B construct declares Reduce Motion is read") {
            // `04` section 7.1 clause 3. A Tier-B construct outside the choke point still has to
            // honour Reduce Motion itself, and this is the source-visible proxy that it was
            // considered — the same discipline AX5's two clauses already use for their own concern.
            // Checked against `renderedText`, not `text`, for the same reason AX5's clauses are
            // (S-1): a Tier-B construct inside a delegate like LegacyHistoryView would otherwise be
            // invisible to the wrapper's own text.
            let landed = landedFamilies().landed
            let animating = landed.filter { usesTierBConstruct($0.renderedText) }
            let still = landed.filter { !usesTierBConstruct($0.renderedText) }
            expectEqual(animating.count + still.count, landed.count)
            // Reported rather than pinned to a number: families land incrementally through
            // P11–P15, and a hard count here would be edited by every one of them — the same
            // reason AX5's own family count is printed, not asserted.
            print("Reduce Motion contract: \(animating.count) animating, \(still.count) still")
            for family in animating {
                expect(family.renderedText.contains("accessibilityReduceMotion"),
                       "\(family.path) (\(family.screen.canonicalName)) uses a Tier-B motion "
                           + "construct with no accessibilityReduceMotion read, so Reduce Motion "
                           + "was never decided for it (04 section 7.1 clause 3)")
            }
        }

        test("at least one landed family actually animates") {
            // Anti-vacuity: Match Day guarantees this is non-empty today. An empty result means
            // the scan broke, not that the tree got cleaner — the same guard AX5's own suite uses.
            let animating = landedFamilies().landed.filter { usesTierBConstruct($0.renderedText) }
            expect(!animating.isEmpty,
                   "no landed family uses a Tier-B construct — Match Day's TimelineView guarantees "
                       + "this is never empty while the suite is actually scanning")
        }

        test("the scan catches a Tier-B construct with no Reduce Motion branch") {
            expect(caught("TimelineView(.animation) { _ in dots }\n", by: usesTierBConstruct),
                   "a planted TimelineView( was not caught")
            expect(caught(".matchedGeometryEffect(id: x, in: ns)\n", by: usesTierBConstruct),
                   "a planted matchedGeometryEffect was not caught")
            expect(!caught(".coachWorldAnimation(CoachWorldTokens.Motion.value, value: x)\n",
                           by: usesTierBConstruct),
                   "a Tier-A call through the choke point was mistaken for a Tier-B construct")
        }

        test("ReduceMotionContractTest is dispatched from the branches every release claim quotes") {
            // The dispatch failure this closes: the M8 instruments were absent from exactly the
            // no-argument branch verify.sh --lane full runs for two days while releases quoted it
            // (main.swift's own comment on that incident is what this test is modelled on).
            let mainURL = packageRoot().appendingPathComponent("Tests/SimTests/main.swift")
            guard let source = try? String(contentsOf: mainURL, encoding: .utf8) else {
                expect(false, "Tests/SimTests/main.swift is unavailable")
                return
            }
            let callSites = source.components(separatedBy: "runReduceMotionContractTests()").count - 1
            expect(callSites >= 3,
                   "runReduceMotionContractTests() is called \(callSites) time(s) in main.swift; "
                       + "it must be dispatched from the no-argument branch, --design-contracts and "
                       + "--core-contracts — the branches verify.sh's full and accessibility lanes "
                       + "and every release claim quote")
        }
    }
}
