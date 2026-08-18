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

struct FamilyView {
    let screen: CoachWorldScreenID
    let path: String
    let text: String
}

/// The view types that draw the Floodlit world, directly or by wholly delegating to one that does.
///
/// Roughly a quarter of the registry is a thin wrapper — `NewCareerCoachIdentityView` passes
/// straight to `NewCareerSetupView`, `JobBoardView`/`OfferView`/`AppointmentView` all pass a
/// `focus:` to `CareerHubView`. A wrapper has no ground of its own to paint, so it is converted
/// exactly when the view it delegates to is. Resolved to a fixpoint rather than one hop, because
/// wrappers chain.
private func floodlitConvertedTypes() -> Set<String> {
    let sources = swiftFilesImportingUIFramework()
    func typeName(of path: String) -> String {
        String(path.split(separator: "/").last ?? "").replacingOccurrences(of: ".swift", with: "")
    }

    var converted = Set(
        sources.filter { $0.text.contains("CoachWorldFloodlitStage") }.map { typeName(of: $0.path) }
    )
    var changed = true
    while changed {
        changed = false
        for file in sources {
            let name = typeName(of: file.path)
            guard !converted.contains(name) else { continue }
            // A wrapper delegates by naming the converted type's initialiser. Naming it is not
            // sufficient: `SigningDayView` delegates on one branch and draws its own state on the
            // other, so the mention alone would have called it converted while that branch still
            // rendered on bare ground. A file that draws an unconverted composition of its own is
            // not a wrapper, whatever else it delegates to.
            let drawsItsOwnUnconvertedState = file.text.contains("ContentUnavailableView(")
            if !drawsItsOwnUnconvertedState,
               converted.contains(where: { file.text.contains($0 + "(") }) {
                converted.insert(name)
                changed = true
            }
        }
    }
    return converted
}

private func isFloodlitConverted(_ family: FamilyView) -> Bool {
    let name = String(family.path.split(separator: "/").last ?? "")
        .replacingOccurrences(of: ".swift", with: "")
    return floodlitConvertedTypes().contains(name)
}

/// Reused by `ReduceMotionContractTests` — the same partition, not a second one, so the two
/// contracts cannot silently cover different sets of families.
func landedFamilies() -> (landed: [FamilyView], pending: [CoachWorldScreenID]) {
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

        test("the convention keeps the draft room family landed") {
            let (_, pending) = landedFamilies()
            expect(!pending.contains(.draftRoom),
                   "Draft Room has a production wrapper and must not remain pending")
            expect(!pending.contains(.prospectProfile),
                   "Prospect Profile has a production dossier and must not remain pending")
            expect(!pending.contains(.shortlist),
                   "Shortlist has a production bounded list and must not remain pending")
            expect(!pending.contains(.contractNegotiation),
                   "Contract Negotiation has a production wrapper and must not remain pending")
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

    suite("Floodlit surface conversion") {
        // The cutover converts 62 families over several phases, so this enumerates by construction
        // and reports the split rather than asserting a count every later phase would have to edit
        // — the same shape as the AX5 contract above, for the same reason.
        //
        // What it *does* assert is the invariant that makes a conversion real. `CoachWorldFloodlitStage`
        // already paints the committed dark world: the page ground, the backdrop, and the fixed-seed
        // grain. A root that wraps itself in the stage and *also* keeps its own
        // `.background(palette.page.color.ignoresSafeArea())` paints flat ground straight over the
        // backdrop it just asked for — the screen compiles, looks nearly right, and silently has no
        // Floodlit world at all. That is the defect worth a test.
        test("every family is either converted to the Floodlit stage or pending, and the split is total") {
            let (landed, _) = landedFamilies()
            let converted = landed.filter(isFloodlitConverted)
            let pending = landed.filter { !isFloodlitConverted($0) }
            expectEqual(converted.count + pending.count, landed.count,
                        "the conversion partition lost a family, so some family is checked by nothing")
            print("Floodlit conversion: \(converted.count) converted, \(pending.count) pending")
        }

        test("no converted root paints its own ground under the stage backdrop") {
            let converted = landedFamilies().landed.filter(isFloodlitConverted)
            for family in converted {
                expect(!family.text.contains("palette.page.color.ignoresSafeArea()"),
                       "\(family.path) (\(family.screen.canonicalName)) wraps itself in "
                           + "CoachWorldFloodlitStage and then paints palette.page over the "
                           + "backdrop the stage draws, so the Floodlit world never renders")
            }
        }

        test("every surface each landed cutover phase claims is converted") {
            // Each phase's own completion gate. The enumeration above stays general and reports a
            // count; this pins the specific claim each commit made, so a later phase cannot quietly
            // un-convert an earlier one. A phase adds its range here when it lands — a phase that
            // forgets asserts nothing, which is how Phases 4 to 6 originally slipped through.
            let converted = Set(landedFamilies().landed.filter(isFloodlitConverted).map(\.screen))
            let claimed: [(phase: String, screens: [CoachWorldScreenID])] = [
                ("3 (entry, registry 1-7)",
                 [.titleContinue, .newCareerCoachIdentity, .jobBoard, .offer, .appointment,
                  .settingsAccessibility, .worldSearch]),
                ("4 (command, registry 8-15)",
                 [.coachingHQ, .inbox, .opponentReportFilmRoom, .gamePlan, .practicePlan,
                  .teamHealth, .matchDay, .aftermath]),
                ("5 (personnel, registry 16-23)",
                 [.roster, .depthChart, .playerProfile, .developmentPlan, .staffRoom,
                  .staffMarketProfile, .schemeBook, .personnelPackages]),
                ("6 (college, registry 24-33, 61)",
                 [.recruitingBoard, .prospectProfile, .shortlist, .contactVisitPlanner,
                  .classOverview, .signingDay, .portalHub, .retentionDecisions, .portalMarket,
                  .collegeOffseason, .nilAllocation]),
                ("career hub family landed with phase 3",
                 [.careerHub, .jobSecurity, .stakeholders, .promotionDecision, .coachingCarousel]),
            ]
            for (phase, screens) in claimed {
                for screen in screens {
                    expect(converted.contains(screen),
                           "\(screen.canonicalName) is claimed converted by phase \(phase), but its "
                               + "view does not resolve to CoachWorldFloodlitStage")
                }
            }
        }

        test("the ground-paint scan would notice a double-painted root") {
            let planted = """
            CoachWorldFloodlitStage { content }
                .background(palette.page.color.ignoresSafeArea())
            """
            expect(planted.contains("CoachWorldFloodlitStage")
                       && planted.contains("palette.page.color.ignoresSafeArea()"),
                   "the predicate the real assertion uses must catch a planted double paint")
        }
    }
}
