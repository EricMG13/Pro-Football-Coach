import Foundation
import CoreGraphics
import ProFootballCoachUI

/// `SmallestDeviceLayoutTest`, D15's first falsifier and `04` section 7's two-tier gate.
///
/// Before this file the gate named a registered `ReleaseGateID` case with `runner == nil`, so
/// `--catalog` printed `MISSING RUNNER` for it and `runCommitmentCoverageTest` failed on "registered
/// without a runnable command". This file is the runner, written to the same shape
/// `ReduceMotionContractTests.swift` used to close the same defect for its own gate.
///
/// **What is asserted.** The geometry every chromed surface is laid out from — `04` sections 6.1b
/// and 6.1c's frame and stage tokens — fits inside the install floor, and inside the promise floor,
/// with the physical insets cleared. That arithmetic is the part a headless executable can actually
/// see, and it is not vacuous: a stage token edited past the floor fails here.
///
/// **What is not asserted, and must not be claimed.** D15's falsifier says *renders at the install
/// floor with no clipping and all controls reachable*. Clipping and reachability are properties of a
/// render, and this target has neither XCTest nor a view host — `04` section 7.1 already states that
/// limitation for G-12 and it applies here unchanged. **The rendered limb of D15's falsifier stays
/// open.** Nothing below is evidence that a surface renders correctly at 844 x 390; it is evidence
/// that the geometry it is laid out from cannot overflow that frame by construction. An audit under
/// `04b` may not treat this suite as the rendered proof.

// MARK: - The two tiers, from `04` section 7

/// The install floor. Below-promise devices install anyway — no store mechanism excludes by screen
/// size — so D15 fixes this as the frame every surface must fit forever.
private let installFloor = CGSize(width: 844, height: 390)

/// The promise floor: iPhone 15 Pro class, the smallest window inside the support promise, where
/// D15 says the full budget must hold. Held here rather than in `CoachWorldTokens` deliberately —
/// no production code lays out from it yet, and a token nothing consumes is its own defect.
private let promiseFloor = CGSize(width: 852, height: 393)

// MARK: - The fit, as a value so the self-test can exercise it

/// A horizontal band: leading offset, content column, trailing gutter, against a frame width.
private struct HorizontalFit {
    let leading: CGFloat
    let width: CGFloat
    let gutter: CGFloat
    let frame: CGFloat

    var extent: CGFloat { leading + width + gutter }
    var fits: Bool { extent <= frame }
    var overflow: CGFloat { extent - frame }
}

// MARK: - The re-typed-floor scan

/// Standalone integer tokens on a line: `844` matches, `18440` and `0.844` do not.
///
/// A plain `contains("844")` would fire on any number containing those digits, which is how a scan
/// starts reporting noise and then gets deleted.
private func integerTokens(in line: String) -> Set<String> {
    let characters = Array(line)
    var tokens: Set<String> = []
    var index = 0
    while index < characters.count {
        guard characters[index].isNumber else {
            index += 1
            continue
        }
        let start = index
        while index < characters.count, characters[index].isNumber { index += 1 }
        let before = start > 0 ? characters[start - 1] : " "
        let after = index < characters.count ? characters[index] : " "
        let joinedToAWord = before == "." || before == "_" || before.isLetter
            || after == "." || after == "_" || after.isLetter
        if !joinedToAWord { tokens.insert(String(characters[start..<index])) }
    }
    return tokens
}

/// True for a line that writes an install-floor dimension as a literal somewhere other than the one
/// declaration that owns it.
///
/// This is the by-construction limb. `Stage.contentWidth` is written
/// `Frame.floorWidth - contentLeading - Frame.gutter` precisely so it stays right if the floor moves;
/// a sibling written `844 - 115 - 20` would be identical today and silently wrong the day D15 is
/// revisited. The scan makes the second spelling impossible rather than trusting the next author to
/// remember the first.
private func retypesTheInstallFloor(_ line: String) -> Bool {
    let tokens = integerTokens(in: line)
    let width = tokens.contains("844")
    let height = tokens.contains("390")
    guard width || height else { return false }
    if width && line.contains("floorWidth") { return false }
    if height && line.contains("floorHeight") { return false }
    return true
}

func runSmallestDeviceLayoutTests() {
    suite("Smallest device layout") {
        test("the install and promise floors are the ones 04 section 7 fixes") {
            // Pins canon into the token layer. If someone edits the frame tokens, this is what says
            // the design window moved, rather than the change landing silently.
            expectEqual(CoachWorldTokens.Frame.floorWidth, installFloor.width)
            expectEqual(CoachWorldTokens.Frame.floorHeight, installFloor.height)
            expectEqual(CoachWorldTokens.Frame.sensorHousing, 59)
            expectEqual(CoachWorldTokens.Frame.homeIndicator, 21)
            expect(promiseFloor.width >= installFloor.width
                       && promiseFloor.height >= installFloor.height,
                   "the promise floor is smaller than the install floor in some dimension, so the "
                       + "two tiers are the wrong way round")
        }

        test("the management stage fits inside the install floor") {
            // `04` section 6.1c: the rail sits against the sensor housing, the content column is
            // what is left after the rail and the trailing gutter. This is that sentence as
            // arithmetic, at the smaller of the two tiers.
            let fit = HorizontalFit(
                leading: CoachWorldTokens.Stage.contentLeading,
                width: CoachWorldTokens.Stage.contentWidth,
                gutter: CoachWorldTokens.Frame.gutter,
                frame: installFloor.width
            )
            expect(fit.fits,
                   "the stage's content band extends \(fit.extent) pt across an "
                       + "\(installFloor.width) pt install floor, overflowing by \(fit.overflow) pt")
            expect(CoachWorldTokens.Stage.contentWidth > 0,
                   "the content column has no width left after the rail and the gutter")
            expect(CoachWorldTokens.Stage.railLeading + CoachWorldTokens.Stage.railWidth
                       <= CoachWorldTokens.Stage.contentLeading,
                   "the icon rail overlaps the content column, so one is drawn over the other")
        }

        test("the stage's vertical furniture fits inside the install floor") {
            let header = CoachWorldTokens.Stage.contentTop
                + CoachWorldTokens.Stage.headerTop
                + CoachWorldTokens.Stage.headerPrimaryRow
                + CoachWorldTokens.Stage.headerSecondaryRow
                + CoachWorldTokens.Frame.bottomInset
            expect(header <= installFloor.height,
                   "the header block plus the bottom band is \(header) pt against an "
                       + "\(installFloor.height) pt install floor, so the content area is negative")
            expect(CoachWorldTokens.Frame.topInset < CoachWorldTokens.Stage.contentTop,
                   "top furniture is not above the content it labels")
        }

        test("furniture clears the physical insets at the install floor") {
            // `04` section 7's inset table: 59 pt sensor edge, 21 pt home edge for the 15
            // generation. Landscape puts the sensor housing on a short edge and the home indicator
            // along the bottom, so these are checked against the axis each one actually occupies
            // rather than pooled.
            expect(CoachWorldTokens.Frame.leadingInset >= CoachWorldTokens.Frame.sensorHousing,
                   "leading furniture does not clear the sensor housing")
            expect(CoachWorldTokens.Stage.railLeading >= CoachWorldTokens.Frame.sensorHousing,
                   "the icon rail is drawn under the sensor housing")
            expect(CoachWorldTokens.Stage.railFreeLeading >= CoachWorldTokens.Frame.sensorHousing,
                   "a rail-free surface's leading edge is drawn under the sensor housing")
            expect(CoachWorldTokens.Frame.bottomInset >= CoachWorldTokens.Frame.homeIndicator,
                   "the bottom band is drawn under the home indicator")
        }

        test("the same geometry fits at the promise floor") {
            // Tier two. D15 asks for both, and the pair is what carries the signal: geometry that
            // fits here and fails the tier above says the design window has quietly moved up to the
            // promise floor while below-promise devices can still install.
            let fit = HorizontalFit(
                leading: CoachWorldTokens.Stage.contentLeading,
                width: CoachWorldTokens.Stage.contentWidth,
                gutter: CoachWorldTokens.Frame.gutter,
                frame: promiseFloor.width
            )
            expect(fit.fits,
                   "the stage's content band overflows even the promise floor by \(fit.overflow) pt")
        }

        test("no floor dimension is re-typed as a literal in the token layer") {
            let tokensURL = packageRoot()
                .appendingPathComponent("Sources/ProFootballCoachUI/DesignTokens.swift")
            guard let text = try? String(contentsOf: tokensURL, encoding: .utf8) else {
                expect(false, "DesignTokens.swift is unavailable")
                return
            }
            let offenders = offendingLines(
                in: [(path: "Sources/ProFootballCoachUI/DesignTokens.swift", text: text)],
                where: retypesTheInstallFloor
            )
            expect(offenders.isEmpty,
                   "an install-floor dimension is written as a literal away from its declaration at "
                       + offenders.joined(separator: ", ")
                       + " — derive it from Frame.floorWidth/floorHeight so it survives D15 being "
                       + "revisited")
        }

        test("the registry the stage geometry serves is intact") {
            // Anti-vacuity, and the reach statement. Every chromed surface is laid out from the
            // Stage tokens, so the gate's reach is the registry's reach; if the registry broke, the
            // arithmetic above would still pass while covering nothing.
            let (landed, pending) = landedFamilies()
            expectEqual(landed.count + pending.count, CoachWorldScreenID.allCases.count,
                        "the partition lost a family")
            expectEqual(CoachWorldScreenID.allCases.count, 62)
            expect(!landed.isEmpty, "no family view was found — the gate would pass vacuously")
            print("Smallest device layout: \(landed.count) landed, \(pending.count) pending "
                      + "at \(Int(installFloor.width)) x \(Int(installFloor.height))")
        }

        test("the fit check catches geometry that overflows the floor") {
            let overflowing = HorizontalFit(leading: 115, width: 760, gutter: 20, frame: 844)
            expect(!overflowing.fits, "a band 51 pt wider than the floor was reported as fitting")
            expectEqual(overflowing.overflow, 51)
            let exact = HorizontalFit(leading: 115, width: 709, gutter: 20, frame: 844)
            expect(exact.fits, "a band exactly the width of the floor was reported as overflowing")
        }

        test("the re-typed-floor scan catches a planted literal and spares the declarations") {
            expect(caught("    static let sidebar: CGFloat = 844 - 115 - 20\n",
                          by: retypesTheInstallFloor),
                   "a planted re-typed 844 was not caught")
            expect(caught("    static let stripHeight: CGFloat = 390 / 2\n",
                          by: retypesTheInstallFloor),
                   "a planted re-typed 390 was not caught")
            expect(!caught("    public static let floorWidth: CGFloat = 844\n",
                           by: retypesTheInstallFloor),
                   "the floorWidth declaration was mistaken for a re-typed literal")
            expect(!caught("    public static let floorHeight: CGFloat = 390\n",
                           by: retypesTheInstallFloor),
                   "the floorHeight declaration was mistaken for a re-typed literal")
            expect(!caught("    static let ratio: CGFloat = 338 / 932\n",
                           by: retypesTheInstallFloor),
                   "an unrelated pair of dimensions was reported as a floor literal")
            expect(!caught("    static let big: CGFloat = 18440\n", by: retypesTheInstallFloor),
                   "844 inside a longer number was matched as a standalone dimension")
        }

        test("SmallestDeviceLayoutTest is dispatched from the branches every release claim quotes") {
            // The same dispatch failure ReduceMotionContractTests guards: an instrument that exists
            // but is absent from the no-argument branch is an instrument verify.sh --lane full never
            // runs, while release notes quote that lane.
            let mainURL = packageRoot().appendingPathComponent("Tests/SimTests/main.swift")
            guard let source = try? String(contentsOf: mainURL, encoding: .utf8) else {
                expect(false, "Tests/SimTests/main.swift is unavailable")
                return
            }
            let callSites = source.components(separatedBy: "runSmallestDeviceLayoutTests()").count - 1
            expect(callSites >= 3,
                   "runSmallestDeviceLayoutTests() is called \(callSites) time(s) in main.swift; it "
                       + "must be dispatched from the no-argument branch, --design-contracts and "
                       + "--core-contracts — the branches verify.sh's full and accessibility lanes "
                       + "and every release claim quote")
        }
    }
}
