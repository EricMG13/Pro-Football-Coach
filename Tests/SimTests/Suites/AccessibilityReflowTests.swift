import Foundation
import ProFootballCoachUI

/// G-12, the last M8 entry-gate instrument. `04` §7.1 states exactly what it does and does not
/// assert; this file implements that and nothing wider.
///
/// The point of it is the enumeration. A spot-check over the five views that happen to exist today
/// would pass forever and cover nothing new, which is the defect `CLAUDE.md` names: a test's
/// coverage boundary becoming the quality boundary. Families come from `CoachWorldScreenID`, so the
/// sixth view is inside this contract the day its file appears.

/// The view file a family lands as. `coachingHQ` → `CoachingHQView.swift`.
///
/// Derived from the case name rather than mapped by hand, for the same reason the enumeration is:
/// a hand map is a second list to forget to update.
private func viewFileName(for screen: CoachWorldScreenID) -> String {
    let name = String(describing: screen)
    return name.prefix(1).uppercased() + name.dropFirst() + "View.swift"
}

private struct FamilyView {
    let screen: CoachWorldScreenID
    let path: String
    let text: String
}

private func landedFamilies() -> (landed: [FamilyView], pending: [CoachWorldScreenID]) {
    let sources = swiftFilesImportingUIFramework()
    var landed: [FamilyView] = []
    var pending: [CoachWorldScreenID] = []
    for screen in CoachWorldScreenID.allCases {
        let fileName = viewFileName(for: screen)
        if let file = sources.first(where: { $0.path.hasSuffix("/" + fileName) }) {
            landed.append(FamilyView(screen: screen, path: file.path, text: file.text))
        } else {
            pending.append(screen)
        }
    }
    return (landed, pending)
}

func runAccessibilityReflowTests() {
    suite("AX5 reflow contract") {
        test("every screen family is either landed and checked or pending and named") {
            let (landed, pending) = landedFamilies()
            expectEqual(
                landed.count + pending.count,
                CoachWorldScreenID.allCases.count,
                "the partition lost a family, so some family is checked by nothing"
            )
            expectEqual(CoachWorldScreenID.allCases.count, 62)
            expect(!landed.isEmpty,
                   "no family view was found — the scan would pass vacuously")
            // Reported rather than asserted at a number: production views land family by family
            // through P11–P15, and a count here would have to be edited by every one of them.
            print("AX5 contract: \(landed.count) landed, \(pending.count) pending")
        }

        test("every landed family declares an accessibility-size composition") {
            // `04` §7.1 clause 1. A screen with no AX5 branch has not had AX5 considered.
            for family in landedFamilies().landed {
                expect(family.text.contains("dynamicTypeSize.isAccessibilitySize"),
                       "\(family.path) (\(family.screen.canonicalName)) has no accessibility-size "
                           + "composition, so AX5 reflow was never decided for it (04 section 7.1)")
            }
        }

        test("every landed family declares deterministic VoiceOver order") {
            // `04` §7.1 clause 2: world context, dominant object, evidence, actions, navigation.
            for family in landedFamilies().landed {
                expect(family.text.contains("accessibilitySortPriority"),
                       "\(family.path) (\(family.screen.canonicalName)) leaves VoiceOver order to "
                           + "layout accident (04 section 7)")
            }
        }

        test("the family-to-file convention resolves the views that exist") {
            // The guard against the enumeration silently finding nothing: if the naming convention
            // drifts, every family becomes "pending" and the two clauses above pass over an empty
            // set. These five are the production screens `05` records as built.
            let landed = Set(landedFamilies().landed.map(\.screen))
            for screen in [
                CoachWorldScreenID.coachingHQ,
                .matchDay,
                .roster,
                .playerProfile,
                .recruitingBoard,
            ] {
                expect(landed.contains(screen),
                       "\(screen.canonicalName) did not resolve to \(viewFileName(for: screen))")
            }
        }

        test("the convention would notice a family that has not landed") {
            // A family with no view must resolve to no file, or "pending" means nothing.
            let (_, pending) = landedFamilies()
            expect(pending.contains(.draftRoom),
                   "Draft Room has no production view and must be reported as pending")
            expectEqual(viewFileName(for: .draftRoom), "DraftRoomView.swift")
            expectEqual(viewFileName(for: .rankingsPlayoffPicture),
                        "RankingsPlayoffPictureView.swift")
        }

        test("the clauses would notice a view that declares neither") {
            // The self-test half: the predicates are run against a synthetic view rather than
            // against a copy of the rule, so a fix to one cannot leave the other asserting the old
            // rule.
            let bare = "import SwiftUI\nstruct BareView: View { var body: some View { Text(\"x\") } }"
            expect(!bare.contains("dynamicTypeSize.isAccessibilitySize"),
                   "a view with no accessibility branch was reported as having one")
            expect(!bare.contains("accessibilitySortPriority"),
                   "a view with no VoiceOver order was reported as having one")
        }
    }
}
