import Foundation
@testable import ProFootballCoachUI

// The M8 production-UI entry gate, as tests (05, phase P11a).
//
// Every assertion here reads its expectation out of `docs/04-UX-AND-DESIGN-SYSTEM.md` at run time
// rather than restating it. A test that hard-codes the twelve status symbols is a second copy of
// canon that drifts silently; one that parses the table fails the day canon and the tree disagree,
// which is the only reason to write it.
//
// The reference sheets shipped with every contract block self-reporting its own compliance, and the
// 2026-08-12 proof review found the predictable result: a column count that did not match its own
// drawing, a verified-sizes table that grew an unverified row, a symbol budget that only summed
// across files. Gap G-17 is this file's reason to exist — where a claim is mechanically checkable,
// it gets mechanically checked.
//
// Each scan enumerates its file set by walking a directory, per `CLAUDE.md`'s coverage-boundary
// rule, and each ships a self-test that plants an offender and asserts the scan catches it. A scan
// that has never failed is not known to be a scan.

// MARK: - Canon readers

func canonText() -> String {
    let url = packageRoot().appendingPathComponent("docs/04-UX-AND-DESIGN-SYSTEM.md")
    return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
}

/// Every six-digit hex `04` section 6.1 states, upper-cased and without the leading hash.
///
/// The section holds the production values, the field grammar and the synthetic team trio; a sheet
/// or a view may name any of them and nothing else.
private func canonHexValues(_ canon: String) -> Set<String> {
    Set(matches(of: "#([0-9A-Fa-f]{6})\\b", in: canon).map { $0.uppercased() })
}

/// The symbol register in `04` section 6.6, as class name to (cap, members).
///
/// Parses the table rows rather than the prose: a row is `| **Name** (…) | cap | `a`, `b` | where |`.
/// The Broadcast row names its marks in words rather than as SF Symbols, so it contributes a cap and
/// no members, which is correct — a drawn wedge is not a symbol literal a scan can find.
private func canonSymbolClasses(_ canon: String) -> [(name: String, cap: Int, members: Set<String>)] {
    var classes: [(String, Int, Set<String>)] = []
    for line in canon.split(separator: "\n", omittingEmptySubsequences: false) {
        let row = String(line)
        guard row.hasPrefix("| **"), row.contains("|") else { continue }
        let cells = row.split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard cells.count >= 4 else { continue }
        let name = cells[1].replacingOccurrences(of: "*", with: "")
        guard let cap = Int(cells[2]) else { continue }   // "not a learned class" has no cap
        let members = Set(matches(of: "`([a-z][a-zA-Z0-9.]*)`", in: cells[3]))
        classes.append((name, cap, members))
    }
    return classes
}

/// 04 section 6.6's Control furniture row: capped but not a `canonSymbolClasses` entry, because its
/// cap cell reads "not a learned class" rather than an `Int`. Shared so a member added to Control
/// furniture is seen by every scan that needs it, not just the one it was written for.
func canonControlFurnitureMembers(_ canon: String) -> Set<String> {
    let row = canon.split(separator: "\n", omittingEmptySubsequences: false)
        .map(String.init)
        .first { $0.contains("Control furniture") } ?? ""
    return Set(matches(of: "`([a-z][a-zA-Z0-9.]*)`", in: row))
}

/// Comment-only lines removed, so a scan counting a source pattern is not corrupted by a doc
/// comment that quotes the pattern in prose to explain what the scan does.
func strippingLineComments(_ text: String) -> String {
    text.split(separator: "\n", omittingEmptySubsequences: false)
        .map { $0.trimmingCharacters(in: .whitespaces).hasPrefix("//") ? "" : String($0) }
        .joined(separator: "\n")
}

/// Regex helper returning the first capture group of every match.
func matches(of pattern: String, in text: String) -> [String] {
    guard let expression = try? NSRegularExpression(pattern: pattern) else { return [] }
    let range = NSRange(text.startIndex..., in: text)
    return expression.matches(in: text, range: range).compactMap { match in
        guard match.numberOfRanges > 1,
              let captured = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[captured])
    }
}

/// `04` section 6.4's heat-scale table, as `(floor, ceiling, role)` in the order canon states it.
///
/// Parses the **table**, not a sentence, and that is the whole point. This test read canon with
/// `matches(of: "red below (\\d+)")` until 2026-08-22, when `60f0c2d` replaced the three-band prose
/// sentence with a five-band table. The parser could not follow canon into a table, failed in its
/// own guard clause, and `--core-contracts` went red for a reason that had nothing to do with the
/// tokens — while the tokens, which really had fallen behind, went unchecked behind it. A parser
/// that reads the structure canon is written in survives canon being edited.
private func canonHeatBands(_ canon: String) -> [(floor: Int, ceiling: Int, role: String)] {
    let lines = canon.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    guard let start = lines.firstIndex(where: { $0.contains("default visual heat scale") })
    else { return [] }
    var bands: [(floor: Int, ceiling: Int, role: String)] = []
    for line in lines[start...] {
        let cells = line.split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard cells.count >= 4 else {
            // The first non-row line after the rows have started is the end of the table. Before
            // that it is the amendment's own prose, which the sentinel matched.
            if !bands.isEmpty { break }
            continue
        }
        let bounds = matches(of: "(\\d+)", in: cells[2]).compactMap(Int.init)
        // Skips the header and its `|---|` separator, neither of which carries two numbers.
        guard bounds.count == 2 else { continue }
        bands.append((floor: bounds[0], ceiling: bounds[1], role: cells[3]))
    }
    return bands
}

/// The palette value a heat band's role cell names, or `nil` if this test cannot resolve it.
///
/// Order matters: "`state.positive`, lightened" contains "state.positive", so the lightened case
/// must be tried first or the Above band silently resolves to the Well above band's colour — which
/// would make the test pass while the two top bands were identical on screen.
private func heatBandValue(
    for role: String,
    palette: CoachWorldTokens.Palette
) -> CoachWorldTokens.ColorValue? {
    if role.contains("state.positive"), role.contains("lightened") {
        return CoachWorldTokens.Heat.lightenedPositive(palette)
    }
    if role.contains("state.positive") { return palette.statePositive }
    if role.contains("state.negative") { return palette.stateNegative }
    if role.contains("state.warning") { return palette.stateWarning }
    if role.contains("content.secondary") { return palette.contentSecondary }
    return nil
}

/// HSL hue in degrees. `04` section 6.1a(ii) states role separation in hue, so a test of it needs
/// the same measure; contrast alone cannot see two roles that are the same colour at a glance.
private func hueDegrees(_ value: CoachWorldTokens.ColorValue) -> Double {
    let high = max(value.red, value.green, value.blue)
    let low = min(value.red, value.green, value.blue)
    let delta = high - low
    guard delta > 0 else { return 0 }
    let hue: Double
    switch high {
    case value.red:   hue = 60 * (((value.green - value.blue) / delta).truncatingRemainder(dividingBy: 6))
    case value.green: hue = 60 * (((value.blue - value.red) / delta) + 2)
    default:          hue = 60 * (((value.red - value.green) / delta) + 4)
    }
    return hue < 0 ? hue + 360 : hue
}

/// The shorter way round the colour wheel between two hues, in degrees.
private func hueSeparation(_ a: Double, _ b: Double) -> Double {
    let raw = abs(a - b).truncatingRemainder(dividingBy: 360)
    return min(raw, 360 - raw)
}

private func designSheets() -> [(name: String, text: String)] {
    let root = packageRoot()
    let names = (try? FileManager.default.contentsOfDirectory(atPath: root.path))?
        .filter { $0.hasSuffix("-v3.dc.html") }
        .sorted() ?? []
    return names.compactMap { name in
        guard let text = try? String(contentsOf: root.appendingPathComponent(name), encoding: .utf8)
        else { return nil }
        return (name: name, text: text)
    }
}

private func rawAssetLoaders(in source: String) -> [String] {
    let patterns = [
        "Image\\([^\\n]*\\bbundle\\s*:",
        "Image\\s*\\(\\s*\\\"",
        "Image\\s*\\(\\s*decorative\\s*:",
        "UIImage\\s*\\(\\s*named\\s*:",
        "NSImage\\s*\\(\\s*named\\s*:",
        "Bundle\\.module\\.(?:image|url)\\s*\\("
    ]
    return codeLines(of: source).filter { line in
        patterns.contains { line.range(of: $0, options: .regularExpression) != nil }
    }
}

// MARK: - The suite

/// Every directory under `docs/` that holds markdown.
///
/// Walked rather than listed, because a list here would be the coverage boundary the manifest's own
/// problem was made of.
private func documentedDirectories() -> [String] {
    let root = packageRoot().appendingPathComponent("docs")
    guard let walker = FileManager.default.enumerator(atPath: root.path) else { return [] }
    var directories: Set<String> = []
    for case let path as String in walker where path.hasSuffix(".md") {
        let parent = (path as NSString).deletingLastPathComponent
        directories.insert(parent.isEmpty ? "docs/" : "docs/\(parent)/")
    }
    return directories.sorted()
}

/// Every markdown file sitting at `docs/` root.
///
/// The directory walk above folds all of these into one entry, `docs/`, which the manifest satisfies
/// trivially — the string appears in nearly every row. So the files at the least hidden path in the
/// repository were the ones the directory rule could not see.
private func rootDocuments() -> [String] {
    let root = packageRoot().appendingPathComponent("docs")
    let contents = (try? FileManager.default.contentsOfDirectory(atPath: root.path)) ?? []
    return contents.filter { $0.hasSuffix(".md") }.map { "docs/\($0)" }.sorted()
}

func runDocumentManifestTests() {
    suite("Document manifest") {
        // DOC-MANIFEST decides what is canon, and it had gone stale against the tree it governs:
        // six directories holding 45 markdown files sat at paths it never named, one of them called
        // `10-CANON-AMENDMENT-04.md`. Section 1's rule already answers it in the abstract -- a path
        // listed nowhere carries no authority -- but silence reads as omission rather than as
        // classification, and a reader cannot tell which. So the directories are enumerated from
        // disk and checked against the manifest, not maintained by hand inside it.
        test("every docs directory holding markdown is classified in DOC-MANIFEST") {
            let manifestURL = packageRoot().appendingPathComponent("docs/DOC-MANIFEST.md")
            guard let manifest = try? String(contentsOf: manifestURL, encoding: .utf8) else {
                expect(false, "docs/DOC-MANIFEST.md is unavailable")
                return
            }
            let directories = documentedDirectories()
            expect(directories.count >= 8,
                   "walked only \(directories.count) docs directories — the walk, not the manifest, "
                       + "is what failed")
            let unclassified = directories.filter { !manifest.contains($0) }
            expect(unclassified.isEmpty,
                   "DOC-MANIFEST does not classify \(unclassified.count) directory(ies): "
                       + "\(unclassified.joined(separator: ", ")). Add each to section 8 with what "
                       + "it is and what authority it carries — a path the manifest never names is "
                       + "a path a reader has to guess about.")
        }

        // Section 8 enforced the directory rule and stopped there, so eight documents at `docs/`
        // root — among them `HANDOFF-CLAUDE.md` and `BETA-READINESS-CONSOLIDATED.md` — sat at paths
        // the manifest never named while the suite reported the tree fully classified. Section 9
        // classifies them; this is what keeps the next one from going unnamed.
        test("every markdown file at docs root is named in DOC-MANIFEST") {
            let manifestURL = packageRoot().appendingPathComponent("docs/DOC-MANIFEST.md")
            guard let manifest = try? String(contentsOf: manifestURL, encoding: .utf8) else {
                expect(false, "docs/DOC-MANIFEST.md is unavailable")
                return
            }
            let documents = rootDocuments()
            expect(documents.count >= 20,
                   "walked only \(documents.count) root documents — the walk, not the manifest, "
                       + "is what failed")
            let unnamed = documents.filter { !manifest.contains($0) }
            expect(unnamed.isEmpty,
                   "DOC-MANIFEST does not name \(unnamed.count) root document(s): "
                       + "\(unnamed.joined(separator: ", ")). Add each to section 9 with what it is "
                       + "and what authority it carries — a document at the path a cold builder "
                       + "opens first is the worst one to leave unclassified.")
        }

        test("the root-document scan would notice a file the manifest does not name") {
            let manifest = "| `docs/STATUS.md` | the dated log | canon |"
            let planted = ["docs/STATUS.md", "docs/HANDOFF-INVENTED.md"]
            expectEqual(planted.filter { !manifest.contains($0) }, ["docs/HANDOFF-INVENTED.md"],
                        "an unnamed root document must be reported")
        }

        test("the walk would notice a directory the manifest does not name") {
            let manifest = "| `docs/plans/` | plans | none |"
            let planted = ["docs/plans/", "docs/invented/"]
            expectEqual(planted.filter { !manifest.contains($0) }, ["docs/invented/"],
                        "an unclassified directory must be reported")
        }
    }
}

func runDesignContractTests() {
    let canon = canonText()

    suite("Orientation policy") {
        // CLAUDE.md has claimed since 2026-08-10 that landscape-only is "declared in App/project.yml
        // and asserted by OrientationPolicyTest". The declaration was real; the test was not, and
        // nothing noticed for two days. G-09.
        test("the app declares landscape-only and never a portrait orientation") {
            let path = packageRoot().appendingPathComponent("App/project.yml")
            guard let yaml = try? String(contentsOf: path, encoding: .utf8) else {
                expect(false, "App/project.yml is unreadable at \(path.path)")
                return
            }

            let orientationLines = yaml.split(separator: "\n").map(String.init).filter {
                $0.contains("UISupportedInterfaceOrientations") || $0.contains("UIInterfaceOrientation")
            }
            expect(!orientationLines.isEmpty,
                   "project.yml declares no supported orientations, so the platform picks for us")

            let declaration = orientationLines.joined(separator: "\n")
            expect(declaration.contains("LandscapeLeft") && declaration.contains("LandscapeRight"),
                   "both sensor orientations are binding (04 section 7): \(declaration)")
            expect(!declaration.contains("Portrait"),
                   "portrait is not a supported orientation (owner decision 2026-08-10): \(declaration)")
        }

        test("the scan would notice a portrait orientation being added") {
            let planted = """
            INFOPLIST_KEY_UISupportedInterfaceOrientations: >-
              UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft
            """
            expect(planted.contains("Portrait"),
                   "the predicate the real assertion uses must catch a planted portrait value")
        }
    }

    suite("Design token sync") {
        // G-07's test half. The values were written back into 04 section 6.1 on 2026-08-12; nothing
        // stopped code and canon diverging the next day.
        test("every colour DesignTokens.swift ships is a value 04 section 6.1 states") {
            let canonValues = canonHexValues(canon)
            expect(canonValues.count >= 30,
                   "parsed only \(canonValues.count) hex values from 04 section 6.1 — the parser, "
                       + "not the tokens, is what failed")

            let tokenFiles = swiftFiles(under: "Sources/ProFootballCoachUI")
                .filter { $0.path.hasSuffix("DesignTokens.swift") }
            expect(!tokenFiles.isEmpty, "DesignTokens.swift not found under Sources/ProFootballCoachUI")

            for file in tokenFiles {
                let shipped = Set(matches(of: "0x([0-9A-Fa-f]{6})\\b", in: file.text)
                    .map { $0.uppercased() })
                let undeclared = shipped.subtracting(canonValues).sorted()
                expect(undeclared.isEmpty,
                       "\(file.path) ships \(undeclared.count) colour(s) canon does not hold: "
                           + "\(undeclared.joined(separator: ", ")). Write them into 04 section 6.1 "
                           + "with their measured ratios, or remove them.")
            }
        }

        // 04 section 6.1a(ii), 2026-08-22: where two roles share a value they must be "declared as
        // aliases in the token layer rather than repeated as literals, so a future divergence is a
        // deliberate edit and not an accident". A repeated literal is the accident: someone
        // re-values one role, the other silently keeps the old number, and nothing records that the
        // two were ever meant to agree. Uniqueness is the whole invariant — this deliberately does
        // NOT pin which roles are equal, because canon permits diverging a pair on purpose.
        test("no colour literal is repeated in the token layer") {
            let tokenFiles = swiftFiles(under: "Sources/ProFootballCoachUI")
                .filter { $0.path.hasSuffix("DesignTokens.swift") }
            expect(!tokenFiles.isEmpty,
                   "DesignTokens.swift not found under Sources/ProFootballCoachUI")
            for file in tokenFiles {
                // Stripped, because the alias declarations explain themselves in prose that names
                // the very hex they replaced — 04 section 6.1a(ii)'s own example among them.
                let literals = matches(of: "(0x[0-9A-Fa-f]{6})\\b",
                                       in: strippingLineComments(file.text))
                    .map { $0.uppercased() }
                var seen: Set<String> = []
                let repeated = Set(literals.filter { !seen.insert($0).inserted }).sorted()
                expect(repeated.isEmpty,
                       "\(file.path) repeats \(repeated.count) colour literal(s): "
                           + "\(repeated.joined(separator: ", ")). 04 section 6.1a(ii) requires a "
                           + "shared value to be declared once and aliased by each role that takes "
                           + "it, so that diverging them later is a deliberate edit.")
            }
        }

        test("the repeated-literal scan would notice a duplicated value") {
            let planted = """
            static let one = ColorValue(hex: 0x4FD08C)
            static let two = ColorValue(hex: 0x4FD08C)
            """
            let literals = matches(of: "(0x[0-9A-Fa-f]{6})\\b", in: strippingLineComments(planted))
                .map { $0.uppercased() }
            var seen: Set<String> = []
            expect(!literals.filter { !seen.insert($0).inserted }.isEmpty,
                   "a planted duplicate colour literal must be caught")
        }

        test("the scan would notice a colour that canon does not hold") {
            let canonValues = canonHexValues(canon)
            let planted = "public static let rogue = ColorValue(hex: 0xABCDEF)"
            let found = Set(matches(of: "0x([0-9A-Fa-f]{6})\\b", in: planted).map { $0.uppercased() })
            expect(!found.subtracting(canonValues).isEmpty,
                   "a planted off-canon colour must not be reported as declared")
        }

        // S-2, 2026-08-19 review: the two tests above only ever look at DesignTokens.swift, and
        // only ever match a bare 0xRRGGBB hex literal. A view that constructs
        // `Color(red:green:blue:)` directly was invisible on both counts -- wrong scope, wrong
        // pattern -- and five confirmed sites did exactly that. CLAUDE.md: "A design-token literal
        // in a view is a defect: spacings, radii, colours and font sizes come from the design
        // system." The rule is that colour VALUES live only in the token file, not that every
        // value must already be a canon hex, so this does not attempt to convert an RGB literal to
        // hex and check membership -- constructing a Color outside DesignTokens.swift is the
        // defect, whatever value it happens to hold.
        //
        // Two of the five confirmed sites were exact or near-exact matches for an existing token
        // (MatchDayScoreBug's goldRule was precisely 0xD89713 = Floodlit.goldDeep;
        // CoachingHQView's ink-on-gold was ~1/255 per channel off Floodlit.goldInk, used the same
        // way elsewhere) and are fixed to reference them directly. The remaining three have no
        // existing canon hex to reference, checked by hand against `04` section 6.1's table and
        // DesignTokens.swift. Doc-first (CLAUDE.md) means a new hex value is a canon amendment the
        // owner makes, not one this fix invents, so they are named exceptions rather than silently
        // passed or left an unexplained failure -- the same shape as SuiteCatalog's unwritten
        // gates. Pinned to an exact per-file count so a new site anywhere, including a fourth in
        // one of these three files, still fails.
        test("no view constructs a raw colour outside the token layer, beyond the named exceptions") {
            let pendingCanonAmendment: [String: Int] = [
                "CoachWorldDeskComponents.swift": 0,
                "MatchDayField.swift": 0,
                "MatchDayScoreBug.swift": 1,           // .bowl kind's alternate ground, ~#0E0A06
            ]
            for file in swiftFiles(under: "Sources/ProFootballCoachUI")
            where !file.path.hasSuffix("/DesignTokens.swift") {
                // Stripped the same way the symbol scan strips prose that quotes its own pattern
                // (this file's own comments explaining the fix below say "Color(red:green:blue:)"
                // in prose, which the unstripped regex matched right back).
                let hits = matches(of: "Color\\((red|hue):", in: strippingLineComments(file.text))
                let fileName = String(file.path.split(separator: "/").last ?? "")
                let allowed = pendingCanonAmendment[fileName] ?? 0
                expect(hits.count == allowed,
                       "\(file.path) constructs \(hits.count) raw Color(...) literal(s) outside "
                           + "the token layer (expected \(allowed) pending-canon-amendment "
                           + "exception(s)). Colour values come from CoachWorldTokens, never a "
                           + "literal in a view — write a new one into 04 section 6.1 first if "
                           + "this is genuinely new, or reference an existing token.")
            }
        }

        test("the scan would notice a raw colour literal outside the token layer") {
            let planted = "Color(red: 1, green: 0.95, blue: 0.78)"
            expect(!matches(of: "Color\\((red|hue):", in: planted).isEmpty,
                   "a planted raw Color(red:...) literal must be caught")
        }

        // S-2 follow-up, 2026-08-20 remediation: three independent rating-colour bandings
        // (RosterView, DesignTokens.Heat, CoachWorldRatingRing) disagreed with each other and with
        // this exact canon sentence. RosterView and CoachWorldRatingRing now delegate to
        // `Heat.color(for:palette:)` rather than each carrying their own switch, so testing this one
        // function against canon, across the whole rating range, is what makes all three agree by
        // construction rather than by three people remembering to keep three copies in sync.
        test("Heat's banding matches 04 section 6.4's stated heat scale, across the whole range") {
            let bands = canonHeatBands(canon)
            expect(bands.count == 5,
                   "parsed \(bands.count) bands from 04 section 6.4's heat scale, not the five the "
                       + "2026-08-22 amendment states — the parser, not the tokens, is what failed")
            guard bands.count == 5 else { return }

            // The bands must partition the scale. A gap or an overlap is a rating with no colour or
            // two, and neither is visible by reading the switch: only checking every value is.
            expectEqual(bands[0].floor, CoachWorldTokens.Heat.scaleFloor,
                        "04 section 6.4's first band must start at Heat.scaleFloor")
            expectEqual(bands[bands.count - 1].ceiling, CoachWorldTokens.Heat.scaleCeiling,
                        "04 section 6.4's last band must end at Heat.scaleCeiling")
            for (lower, upper) in zip(bands, bands.dropFirst()) {
                expectEqual(upper.floor, lower.ceiling + 1,
                            "04 section 6.4's bands must be contiguous: \(lower.ceiling) is "
                                + "followed by \(upper.floor)")
            }

            let palette = CoachWorldTokens.dark
            for band in bands {
                guard let expected = heatBandValue(for: band.role, palette: palette) else {
                    expect(false, "04 section 6.4's \(band.floor)-\(band.ceiling) band names a "
                        + "role this test cannot resolve: \(band.role)")
                    continue
                }
                for rating in band.floor...band.ceiling {
                    expectEqual(CoachWorldTokens.Heat.value(for: rating, palette: palette), expected,
                                "rating \(rating) does not land in the band 04 section 6.4 "
                                    + "describes")
                }
            }
        }

        // 04 section 6.4 states two constraints on the scale in the same breath as the table, and
        // they are the reason the amendment exists: an average starter must stop reading as a
        // caution, and no band may be mistaken for the committing action.
        test("every heat band clears 4.5:1 on world.page and sits 24 degrees off gold") {
            let palette = CoachWorldTokens.dark
            let gold = hueDegrees(palette.actionPrimary)
            for rating in CoachWorldTokens.Heat.scaleFloor...CoachWorldTokens.Heat.scaleCeiling {
                let band = CoachWorldTokens.Heat.value(for: rating, palette: palette)
                let ratio = contrastRatio(band, palette.page)
                expect(ratio >= 4.5,
                       "rating \(rating)'s band measures \(ratio) on world.page, below 04 section "
                           + "6.4's stated 4.5:1")
                let separation = hueSeparation(hueDegrees(band), gold)
                expect(separation >= 24,
                       "rating \(rating)'s band sits \(separation) degrees from gold, inside 04 "
                           + "section 6.1a(ii)'s 24 degree floor — gold marks the committing action "
                           + "and carries no other meaning, least of all a rating")
            }
        }

        test("the heat-scale parser reads a table and is not satisfied by the prose it replaced") {
            let prose = """
            The default visual heat scale is red below 70, amber from 70-84 and green from 85 upward.

            """
            expect(canonHeatBands(prose).isEmpty,
                   "the superseded sentence form must not parse as bands — that it silently did "
                       + "not is what left the tokens unchecked")

            let planted = """
            The default visual heat scale over the 40-99 range is two bands:

            | Band | Range | Role |
            |---|---|---|
            | Low | 40-69 | `state.negative` |
            | High | 70-99 | `state.positive` |

            """
            let bands = canonHeatBands(planted)
            expectEqual(bands.count, 2, "a planted two-row band table must parse as two bands")
            expectEqual(bands.first?.floor, 40, "a planted band's floor must be read from the table")
            expectEqual(bands.last?.ceiling, 99, "a planted band's ceiling must be read from the table")
        }
    }

    suite("Team logo asset loading") {
        test("only CoachWorldTeamLogo loads packaged image assets") {
            let permittedPath = "Sources/ProFootballCoachUI/CoachWorldTeamLogo.swift"
            let files = swiftFiles(under: "Sources/ProFootballCoachUI") + swiftFiles(under: "App")
            expect(files.contains { $0.path == permittedPath },
                   "\(permittedPath) must own packaged image loading")

            for file in files where file.path != permittedPath {
                let loaders = rawAssetLoaders(in: file.text)
                expect(loaders.isEmpty,
                       "\(file.path) loads packaged assets outside CoachWorldTeamLogo.swift: "
                           + loaders.joined(separator: " | "))
            }
        }

        test("the scan would notice a raw asset loader outside the component") {
            expect(!rawAssetLoaders(in: #"Image("rogue")"#).isEmpty,
                   "a planted SwiftUI asset load must be caught")
            expect(!rawAssetLoaders(in: #"Image(decorative: "rogue")"#).isEmpty,
                   "a planted decorative asset load must be caught")
            expect(!rawAssetLoaders(in: "UIImage(named: \\\"rogue\\\")").isEmpty,
                   "a planted UIKit asset load must be caught")
            expect(!rawAssetLoaders(in: "Bundle.module.image(forResource: NSImage.Name(\\\"rogue\\\"))").isEmpty,
                   "a planted AppKit asset load must be caught")
        }
    }

    suite("Symbol register") {
        // G-08. Every sheet priced its symbol spend locally and then asserted global compliance,
        // which no sheet can know — the P1 the 2026-08-12 review named. 04 section 6.6 holds the
        // register; this asserts the tree against it.
        test("04 section 6.6 states a register this test can read") {
            let classes = canonSymbolClasses(canon)
            expect(classes.count >= 4,
                   "parsed \(classes.count) symbol classes from 04 section 6.6; the register is the "
                       + "single place the totals are held and it must be machine-readable")
            for symbolClass in classes {
                expect(symbolClass.members.count <= symbolClass.cap,
                       "class \(symbolClass.name) enumerates \(symbolClass.members.count) members "
                           + "against its own cap of \(symbolClass.cap)")
            }
        }

        test("every SF Symbol the UI draws is a registered member") {
            let classes = canonSymbolClasses(canon)
            let registered = classes.reduce(into: Set<String>()) { $0.formUnion($1.members) }
            let permitted = registered.union(canonControlFurnitureMembers(canon))
            expect(permitted.count >= 12, "the register parsed as \(permitted.count) symbols")

            // Every file that draws, enumerated by the UI import rather than by directory. It read
            // `Sources/ProFootballCoachUI` until 2026-08-13, when the composition layer added a
            // second target containing a view — which would have been outside the register's reach
            // on the day it was written.
            for file in swiftFilesImportingUIFramework() {
                // systemName: "x" is how SwiftUI names a symbol; that is the call this looks for.
                let drawn = Set(matches(of: "system(?:Name|Image):\\s*\"([^\"]+)\"", in: file.text))
                let unregistered = drawn.subtracting(permitted)
                    // A filled variant is the same member as its base (04 section 6.6).
                    .filter { !permitted.contains($0.replacingOccurrences(of: ".fill", with: "")) }
                    .sorted()
                expect(unregistered.isEmpty,
                       "\(file.path) draws \(unregistered.count) symbol(s) the 04 section 6.6 "
                           + "register does not hold: \(unregistered.joined(separator: ", ")). "
                           + "A symbol outside the register is a finding under 04 section 4.5, "
                           + "not a licence — map it into a class or drop it.")
            }
        }

        test("the scan would notice an unregistered symbol") {
            let classes = canonSymbolClasses(canon)
            let registered = classes.reduce(into: Set<String>()) { $0.formUnion($1.members) }
            let planted = #"Image(systemName: "flame.circle.fill")"#
            let drawn = Set(matches(of: "systemName:\\s*\"([^\"]+)\"", in: planted))
            expect(!drawn.subtracting(registered).isEmpty,
                   "a planted unregistered symbol must not be reported as registered")
        }

        // MatchDayControlID's icons used to be a bare String returned from a switch — invisible to
        // the literal scan above, which is exactly how sparkles.tv shipped. MatchDayControlSymbol
        // closes that one instance the way CoachWorldStatusChip.Symbol closes Status: a typed,
        // CaseIterable enum a contract test can enumerate. Unlike Status, these five do not own
        // their class exclusively — Control furniture is a shared pool other components draw from
        // too — so the assertion is membership, not the equality CoachWorldStatusChip.Symbol uses.
        test("MatchDayControlSymbol's members are registered, fill variants included") {
            let classes = canonSymbolClasses(canon)
            let registered = classes.reduce(into: Set<String>()) { $0.formUnion($1.members) }
            let permitted = registered.union(canonControlFurnitureMembers(canon))
            expect(permitted.count >= 12, "the register parsed as \(permitted.count) symbols")

            let shipped = Set(MatchDayControlSymbol.allCases.map(\.rawValue))
            // Same rule the general scan above applies: a filled variant is the same member as its
            // base (04 section 6.6) — hand.raised.fill for Status's hand.raised, here.
            let unregistered = shipped.subtracting(permitted)
                .filter { !permitted.contains($0.replacingOccurrences(of: ".fill", with: "")) }
            expect(unregistered.isEmpty,
                   "MatchDayControlSymbol ships \(unregistered.count) symbol(s) 04 section 6.6 does "
                       + "not hold: \(unregistered.sorted().joined(separator: ", "))")
        }

        test("every non-literal symbol call site is a known one") {
            // The scan above matches only a literal string directly after the SwiftUI symbol
            // argument, so a computed value — a switch, a ternary, a stored field — is invisible to
            // it. Closing every instance of that shape is not buildable by regex; this instead pins
            // how many such call sites exist, so a new one moving the count is a build failure a
            // human must look at. It does not itself prove the symbol underneath is registered —
            // CoachWorldStatusChip.Symbol, CoachWorldDeltaMark and MatchDayControlSymbol prove that
            // for their own sites with a dedicated canon-sync test; the rest were checked by hand
            // when this pin was set and must be re-checked by hand when it moves.
            let knownNonLiteralSites = 9
            var found = 0
            var byFile: [String] = []
            for file in swiftFilesImportingUIFramework() {
                let filtered = strippingLineComments(file.text)
                let total = matches(of: "(system(?:Name|Image):)", in: filtered).count
                let literal = matches(of: "(system(?:Name|Image):\\s*\"[^\"]+\")", in: filtered).count
                let nonLiteral = total - literal
                if nonLiteral > 0 {
                    found += nonLiteral
                    byFile.append("\(file.path)=\(nonLiteral)")
                }
            }
            expectEqual(found, knownNonLiteralSites,
                        "non-literal systemName/systemImage call sites now total \(found), pinned "
                            + "at \(knownNonLiteralSites): \(byFile.sorted().joined(separator: ", ")). "
                            + "Resolve a new one through a typed, canon-tested enum (04 section 6.6) "
                            + "like MatchDayControlSymbol, then move this pin either way, growing or "
                            + "shrinking it.")
        }

        test("the non-literal scan counts a planted site and ignores prose that quotes the pattern") {
            let planted = "Image(systemName: someComputedValue)"
            let total = matches(of: "(system(?:Name|Image):)", in: planted).count
            let literal = matches(of: "(system(?:Name|Image):\\s*\"[^\"]+\")", in: planted).count
            expectEqual(total - literal, 1, "a planted non-literal call site must be counted")

            // This is not a hypothetical: writing the test above, in this same file, first shipped
            // as its own false positive — the doc comment on MatchDayControlSymbol names
            // "systemName:" and "systemImage:" in prose to explain what the scan matches.
            let comment = "    /// the scan reads systemName: and systemImage: as plain prose here"
            expectEqual(strippingLineComments(comment), "",
                        "a comment-only line must be stripped before counting, or explaining this "
                            + "scan in its own file becomes a false positive")
        }
    }

    suite("Design reference sheets") {
        // G-17. The sheets are the definitive design references (04 section 6.5), so the claims they
        // make about themselves are load-bearing. These are the ones a machine can settle.
        test("all eight sheets are present and marked") {
            let sheets = designSheets()
            expectEqual(sheets.count, 8, "expected the eight sheets named in 04 section 6.5")
            for sheet in sheets {
                let group = sheet.name.replacingOccurrences(of: "-v3.dc.html", with: "")
                let firstLine = sheet.text.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? ""
                expectEqual(firstLine.trimmingCharacters(in: .whitespaces),
                            "<!-- @dsCard group=\"\(group)\" -->",
                            "\(sheet.name) must open with its @dsCard marker")
            }
        }

        test("no sheet reaches outside itself") {
            // Zero third-party anything is owner-fixed, and a sheet that loads a CDN font is a
            // dependency the design system cannot ship.
            for sheet in designSheets() {
                for (pattern, label) in [("<script", "a script"),
                                         ("https?://", "an external URL"),
                                         ("@font-face", "a web font"),
                                         ("<img", "an image")] {
                    let hits = matches(of: "(\(pattern))", in: sheet.text).count
                    expectEqual(hits, 0, "\(sheet.name) contains \(label)")
                }
            }
        }

        test("no sheet quotes a contrast ratio canon does not state") {
            // The one claim most worth checking: a plausible figure sitting in a row of sourced ones
            // inherits their authority. Only prose counts — CSS carries line-heights and the week
            // grid carries dose multipliers, and neither is a contrast claim.
            let canonRatios = Set(matches(of: "\\b(\\d{1,2}\\.\\d{2})\\b", in: canon))
            expect(canonRatios.count >= 40,
                   "parsed \(canonRatios.count) ratios from canon; the parser is what failed")

            for sheet in designSheets() {
                var prose = sheet.text
                for pattern in ["<style\\b[\\s\\S]*?</style>", "style\\s*=\\s*\"[^\"]*\"",
                                "[x×]\\s*\\d\\.\\d{2}"] {
                    prose = prose.replacingOccurrences(of: pattern, with: " ",
                                                       options: .regularExpression)
                }
                let quoted = Set(matches(of: "\\b(\\d{1,2}\\.\\d{2})\\b", in: prose))
                let invented = quoted.subtracting(canonRatios)
                    .filter { (1.0...21.0).contains(Double($0) ?? 0) }
                    .sorted()
                expect(invented.isEmpty,
                       "\(sheet.name) quotes \(invented.count) contrast figure(s) not in 04 "
                           + "section 6.1: \(invented.joined(separator: ", ")). Ratios are quoted "
                           + "from canon, never computed at authoring time.")
            }
        }

        test("no sheet carries an emoji or a real-world identity") {
            // The legal guardrail is absolute and the sheets are the artefact most likely to reach
            // for a familiar name for realism. No emoji is a repo-wide convention.
            for sheet in designSheets() {
                let emoji = sheet.text.unicodeScalars.filter {
                    (0x1F300...0x1FAFF).contains($0.value) || (0x2600...0x27BF).contains($0.value)
                }
                expect(emoji.isEmpty, "\(sheet.name) contains an emoji")

                expect(sheet.text.contains("pending generator output"),
                       "\(sheet.name) must label its synthetic identities")
            }
        }

        test("the sheet scan would notice a script and an invented ratio") {
            let planted = "<p>ratio 7.77</p><script>alert(1)</script>"
            expectEqual(matches(of: "(<script)", in: planted).count, 1,
                        "a planted script tag must be caught")
            let canonRatios = Set(matches(of: "\\b(\\d{1,2}\\.\\d{2})\\b", in: canon))
            expect(!canonRatios.contains("7.77"),
                   "the planted ratio must not coincidentally exist in canon")
        }
    }

    suite("Floodlit dark-only (06.1a)") {
        // 04 section 6.1a (2026-08-16): Floodlit is dark-only, with no production light palette and
        // no user-facing appearance switch. `Palette.light` and every `colorScheme` branch that
        // chose between `.dark`/`.light` are the code shape the amendment retires; this is the test
        // half of G-07 for that amendment, enumerated by directory per CLAUDE.md's coverage rule.
        test("no UI file resolves a palette by system colour scheme") {
            for file in swiftFiles(under: "Sources/ProFootballCoachUI") {
                expect(!file.text.contains("CoachWorldTokens.light"),
                       "\(file.path) still references CoachWorldTokens.light; 04 section 6.1a "
                           + "retired the light palette")
                expect(!file.text.contains("Environment(\\.colorScheme)"),
                       "\(file.path) still reads colorScheme; Floodlit has no appearance switch")
            }
        }

        test("the scan would notice a reintroduced light branch") {
            let planted = "colorScheme == .dark ? CoachWorldTokens.dark : CoachWorldTokens.light"
            expect(planted.contains("CoachWorldTokens.light"),
                   "the predicate the real assertion uses must catch a planted light reference")
        }

        test("DesignTokens.swift declares no light palette") {
            let tokenFiles = swiftFiles(under: "Sources/ProFootballCoachUI")
                .filter { $0.path.hasSuffix("DesignTokens.swift") }
            expect(!tokenFiles.isEmpty, "DesignTokens.swift not found")
            for file in tokenFiles {
                expect(!file.text.contains("public static let light"),
                       "\(file.path) still declares a light Palette instance")
            }
        }
    }

    suite("Floodlit vocabulary symbol sourcing (Task 4)") {
        // The existing "every SF Symbol the UI draws is a registered member" scan (above) only
        // matches a literal string directly after systemName:/systemImage:. CoachWorldStatusChip
        // and CoachWorldDeltaMark resolve their symbol through a typed enum for call-site safety,
        // which makes their raw values invisible to that regex — a real blind spot, closed here by
        // reading the same canon table these enums were written against.
        test("CoachWorldStatusChip.Symbol is exactly the canon Status class") {
            let classes = canonSymbolClasses(canon)
            guard let status = classes.first(where: { $0.name.contains("StatusChip") }) else {
                expect(false, "04 section 6.6 no longer names a StatusChip row")
                return
            }
            let shipped = Set(CoachWorldStatusChip.Symbol.allCases.map(\.rawValue))
            expectEqual(shipped, status.members,
                        "CoachWorldStatusChip.Symbol must be exactly the canon Status class, no "
                            + "more and no fewer")
        }

        test("CoachWorldDeltaMark's two directions are the canon Change class") {
            let classes = canonSymbolClasses(canon)
            guard let change = classes.first(where: { $0.name.contains("DeltaMark") }) else {
                expect(false, "04 section 6.6 no longer names a DeltaMark row")
                return
            }
            let shipped: Set<String> = [
                CoachWorldDeltaMark(value: 1).symbolName,
                CoachWorldDeltaMark(value: -1).symbolName,
            ].compactMap { $0 }.reduce(into: Set<String>()) { $0.insert($1) }
            expectEqual(shipped, change.members, "the two directions must be exactly the canon "
                            + "Change class")
        }

        test("CoachWorldAgendaRow's obligation marks are the canon Obligation class") {
            let classes = canonSymbolClasses(canon)
            guard let obligation = classes.first(where: { $0.name.contains("AgendaRow") }) else {
                expect(false, "04 section 6.6 no longer names an AgendaRow row")
                return
            }
            expectEqual(obligation.members, ["checkmark.circle.fill", "person.badge.clock"],
                        "CoachWorldAgendaRow draws exactly these two members inline; if canon's "
                            + "row changes, this test and the view must change together")
        }
    }

    suite("Floodlit geometry (06.1a)") {
        // The asymmetric four-radius shape 04 section 6.1a names, with its three presets. A shape
        // built from a single `cut` value cannot express 4/22/4/22, so the type itself is the
        // contract: this only compiles if the presets exist with the stated radii.
        test("the three named CutCorner presets match 04 section 6.1a's radii") {
            let panel = CoachWorldCutCorner.panel
            expectEqual(panel.topLeading, 4); expectEqual(panel.topTrailing, 22)
            expectEqual(panel.bottomTrailing, 4); expectEqual(panel.bottomLeading, 22)

            let row = CoachWorldCutCorner.row
            expectEqual(row.topLeading, 3); expectEqual(row.topTrailing, 14)
            expectEqual(row.bottomTrailing, 3); expectEqual(row.bottomLeading, 14)

            let action = CoachWorldCutCorner.action
            expectEqual(action.topLeading, 22); expectEqual(action.topTrailing, 22)
            expectEqual(action.bottomTrailing, 22); expectEqual(action.bottomLeading, 5)
        }
    }
}
