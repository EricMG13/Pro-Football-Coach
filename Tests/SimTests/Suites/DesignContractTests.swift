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

func runDesignContractTests() {
    let canon = canonText()

    suite("Mock reconciliation vertical slice") {
        test("selected production surfaces use truthful supported copy") {
            let root = packageRoot().appendingPathComponent("Sources/ProFootballCoachUI")
            let paths = ["CoachingHQView.swift", "RosterView.swift", "PlayerProfileView.swift"]
            let source = paths.compactMap {
                try? String(contentsOf: root.appendingPathComponent($0), encoding: .utf8)
            }.joined(separator: "\n")

            for required in [
                "Before kickoff",
                "Open full dossier",
                "Back to the roster",
                "Open development evidence"
            ] {
                expect(source.contains(required), "vertical slice is missing truthful copy: \(required)")
            }

            for unsupported in [
                "4 of 7 done", "3d 06h", "Thin at EDGE", "6 games on record",
                "Into the development plan"
            ] {
                expect(!source.localizedCaseInsensitiveContains(unsupported),
                       "vertical slice copied unsupported mock claim: \(unsupported)")
            }
        }

        test("HQ names the no-opponent state honestly") {
            let path = packageRoot()
                .appendingPathComponent("Sources/ProFootballCoachUI/CoachingHQView.swift")
            let source = (try? String(contentsOf: path, encoding: .utf8)) ?? ""

            expect(
                source.contains(
                    "model.opponent == nil ? \"No game scheduled\" : \"Before kickoff\""
                ),
                "HQ must reserve Before kickoff for a scheduled opponent"
            )
        }
    }

    suite("One-band top navigator") {
        test("the management frame is rail-free at the install floor") {
            expectEqual(CoachWorldTokens.Stage.contentLeading, 63)
            expectEqual(CoachWorldTokens.Stage.contentTop, 54)
            expectEqual(CoachWorldTokens.Stage.headerTop, 12)
            expectEqual(CoachWorldTokens.Stage.headerHeight, 34)
            expectEqual(CoachWorldTokens.Stage.contentWidth, 761)
        }

        test("no production source retains rail presentation") {
            let source = swiftFilesImportingUIFramework().map(\.text).joined(separator: "\n")
            for retired in ["FloodlitIconRail", "RailEntry", "showsIconRail"] {
                expect(!source.contains(retired), "retired rail source remains: \(retired)")
            }
        }

        test("the header owns registry opening and a stable accessibility hook") {
            let source = swiftFilesImportingUIFramework().map(\.text).joined(separator: "\n")
            expect(source.contains("onOpenRegistry"))
            expect(source.contains("top-navigator"))
            expect(source.contains("Open all tasks,"))
        }

        test("selection, context, and AX5 survive the compact visual band") {
            let path = packageRoot()
                .appendingPathComponent("Sources/ProFootballCoachUI/FloodlitChrome.swift")
            let source = (try? String(contentsOf: path, encoding: .utf8)) ?? ""

            expect(source.contains("siblingUnderlineInset"),
                   "the current sibling needs a visible in-band rule")
            expect(source.contains("contextViewportWidth"),
                   "supplied context needs a protected truncating viewport")
            expect(
                source.contains(
                    ".frame(height: dynamicTypeSize.isAccessibilitySize ? nil : CoachWorldTokens.Stage.headerHeight)"
                ),
                "AX5 must expand the header intrinsically instead of clipping it to 34 points"
            )
        }

        test("unchromed Match Day keeps its broadcast top inset") {
            let path = packageRoot()
                .appendingPathComponent("Sources/ProFootballCoachUI/MatchDayView.swift")
            let source = (try? String(contentsOf: path, encoding: .utf8)) ?? ""

            expect(
                source.contains(
                    "chrome == nil ? CoachWorldTokens.Frame.topInset : CoachWorldTokens.Stage.contentTop"
                ),
                "PROOF_SCREEN=match must not reserve a blank navigator band"
            )
        }
    }

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

        test("the scan would notice a colour that canon does not hold") {
            let canonValues = canonHexValues(canon)
            let planted = "public static let rogue = ColorValue(hex: 0xABCDEF)"
            let found = Set(matches(of: "0x([0-9A-Fa-f]{6})\\b", in: planted).map { $0.uppercased() })
            expect(!found.subtracting(canonValues).isEmpty,
                   "a planted off-canon colour must not be reported as declared")
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
