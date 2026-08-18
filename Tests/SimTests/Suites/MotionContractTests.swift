import Foundation
@testable import ProFootballCoachUI

/// The motion choke point, as a test. `04` section 6.7 names `CoachWorldMotion.swift` as the one
/// file permitted raw motion vocabulary; this file is what makes that true rather than aspirational.
///
/// This is prevention, not detection. A predicate that only *catches* an off-token animation still
/// lets one ship and rot until the suite next runs. Containing the vocabulary to one file means an
/// off-token literal cannot be written outside it at all — the choke point's two modifiers are the
/// only path to `.animation(`, and both already read `04` section 6.7's register and
/// `accessibilityReduceMotion` for you.
///
/// Each scan enumerates its file set by walking a directory or a construction, per `CLAUDE.md`'s
/// coverage-boundary rule, and ships a self-test that plants an offender. A scan that has never
/// failed is not known to be a scan.

/// Raw motion vocabulary: the primitives that *schedule* an animation. Deliberately excludes
/// `accessibilityReduceMotion` — reading that is required everywhere a Tier-B construct animates
/// (`04` section 7.1 clause 3), not confined to the choke point, so forbidding it here would
/// contradict the clause this file's sibling gate enforces.
private let rawMotionVocabulary: [String] = [
    "withAnimation(", "Animation.", ".easeInOut", ".easeIn(", ".easeOut(", ".linear(", ".spring(",
    ".timingCurve(", ".bouncy", ".smooth", ".snappy", ".interpolatingSpring(",
    ".interactiveSpring(", ".repeatForever(", ".repeatCount(", ".delay(", ".speed("
]

private func namesRawMotionVocabulary(_ line: String) -> Bool {
    rawMotionVocabulary.contains { line.contains($0) }
}

/// Every UI-importing file except the choke point itself.
private func motionConsumers() -> [(path: String, text: String)] {
    swiftFilesImportingUIFramework().filter { !$0.path.hasSuffix("/CoachWorldMotion.swift") }
}

private func chokePointFile() -> (path: String, text: String)? {
    swiftFilesImportingUIFramework().first { $0.path.hasSuffix("/CoachWorldMotion.swift") }
}

// MARK: - Canon sync

/// `04` section 6.7's two tables share one row shape — `| **name** | number ... |` — so one parse
/// covers durations and companions without needing to tell the tables apart: the equality check
/// below does not care which table a token came from, only that code and canon agree on it.
private func canonMotionTokens(_ canon: String) -> [String: String] {
    guard let sectionStart = canon.range(of: "### 6.7 The motion register"),
          let sectionEnd = canon.range(
              of: "\n## 7. Device", range: sectionStart.upperBound..<canon.endIndex
          )
    else { return [:] }
    let section = String(canon[sectionStart.upperBound..<sectionEnd.lowerBound])

    var tokens: [String: String] = [:]
    for line in section.split(separator: "\n", omittingEmptySubsequences: false) {
        let row = String(line)
        guard row.hasPrefix("| **") else { continue }
        let cells = row.split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard cells.count >= 3 else { continue }
        let name = cells[1].replacingOccurrences(of: "*", with: "")
        guard let value = matches(of: "^([0-9.]+)", in: cells[2]).first else { continue }
        tokens[name] = value
    }
    return tokens
}

/// The `public static let name: Type = value` lines inside `Motion`'s own braces — bracket-counted
/// rather than matched to the enum's closing line by a second regex, so a member added after
/// `standard(_:)` is still inside the block this reads.
private func motionEnumBlock(_ designTokensText: String) -> String {
    guard let start = designTokensText.range(of: "public enum Motion {") else { return "" }
    var depth = 1
    var index = start.upperBound
    var block = ""
    while index < designTokensText.endIndex, depth > 0 {
        let character = designTokensText[index]
        if character == "{" { depth += 1 }
        if character == "}" { depth -= 1 }
        if depth > 0 { block.append(character) }
        index = designTokensText.index(after: index)
    }
    return block
}

private func shippedMotionTokens(_ designTokensText: String) -> [String: String] {
    let block = motionEnumBlock(designTokensText)
    guard let expression = try? NSRegularExpression(
        pattern: "public static let ([a-zA-Z]+): \\w+ = ([0-9.]+)"
    ) else { return [:] }
    let range = NSRange(block.startIndex..., in: block)
    var tokens: [String: String] = [:]
    for match in expression.matches(in: block, range: range) {
        guard let nameRange = Range(match.range(at: 1), in: block),
              let valueRange = Range(match.range(at: 2), in: block) else { continue }
        tokens[String(block[nameRange])] = String(block[valueRange])
    }
    return tokens
}

private func designTokensText() -> String {
    let files = swiftFilesImportingUIFramework()
    return files.first { $0.path.hasSuffix("/DesignTokens.swift") }?.text ?? ""
}

func runMotionContractTests() {
    suite("Motion contract") {
        test("no view outside CoachWorldMotion.swift names raw motion vocabulary") {
            let consumers = motionConsumers()
            expect(!consumers.isEmpty, "found no view sources to scan — the scan would pass vacuously")
            let offenders = offendingLines(in: consumers, where: namesRawMotionVocabulary)
            expect(
                offenders.isEmpty,
                "raw motion vocabulary outside the choke point (04 section 6.7): "
                    + offenders.joined(separator: ", ")
            )
        }

        test("the choke point actually contains what it claims to wrap") {
            // The clause easiest to omit and most load-bearing: without it, deleting
            // CoachWorldMotion.swift makes the clause above pass perfectly, because an empty file
            // has no raw vocabulary anywhere, inside or outside itself.
            guard let chokePoint = chokePointFile() else {
                expect(false, "CoachWorldMotion.swift does not exist — 04 section 6.7 names a file "
                    + "that is not there")
                return
            }
            expect(chokePoint.text.contains("accessibilityReduceMotion"),
                   "the choke point does not read Reduce Motion, so it cannot be honouring it")
            for marker in ["withAnimation(", "Animation.timingCurve", ".repeatForever("] {
                expect(chokePoint.text.contains(marker),
                       "the choke point no longer contains \(marker) — is it still the choke point, "
                           + "or has the real logic moved elsewhere while this file stayed as cover?")
            }
        }

        test("the containment scan catches raw vocabulary and spares the choke-point call") {
            expect(caught("withAnimation(.easeInOut) { x = true }\n", by: namesRawMotionVocabulary),
                   "a planted withAnimation( was not caught")
            expect(caught("// withAnimation would be wrong here\n", by: namesRawMotionVocabulary)
                   == false,
                   "a comment was treated as an offending line — codeLines(of:) is not in the path")
            expect(
                caught(
                    "withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {\n"
                        + "    pulsing = true\n}\n",
                    by: namesRawMotionVocabulary
                ),
                "the exact text MatchDayScoreBug.swift:468 shipped, before it moved into the choke "
                    + "point, is no longer caught — a regression pin, not a hypothetical"
            )
            expect(!caught(".coachWorldAnimation(CoachWorldTokens.Motion.value, value: x)\n",
                           by: namesRawMotionVocabulary),
                   "a compliant call through the choke point was reported as an offender")
            expect(!caught(".coachWorldPulse()\n", by: namesRawMotionVocabulary),
                   "a compliant pulse call was reported as an offender")
        }

        test("04 section 6.7 and CoachWorldTokens.Motion agree on every token, in both directions") {
            let canon = canonMotionTokens(canonText())
            expect(canon.count >= 6,
                   "parsed only \(canon.count) motion tokens from 04 section 6.7 — the parser, not "
                       + "the tokens, is what failed")
            let shipped = shippedMotionTokens(designTokensText())
            expect(shipped.count >= 6,
                   "parsed only \(shipped.count) motion tokens from DesignTokens.swift — the parser, "
                       + "not the tokens, is what failed")

            let onlyInCanon = canon.keys.filter { shipped[$0] == nil }.sorted()
            let onlyInCode = shipped.keys.filter { canon[$0] == nil }.sorted()
            expect(onlyInCanon.isEmpty,
                   "04 section 6.7 names a token no code ships: \(onlyInCanon) — a canon row "
                       + "naming a value nothing ships is the same false promise this section "
                       + "exists to end")
            expect(onlyInCode.isEmpty,
                   "CoachWorldTokens.Motion ships a token 04 section 6.7 does not name: "
                       + "\(onlyInCode)")

            for name in Set(canon.keys).intersection(shipped.keys) {
                expectEqual(canon[name], shipped[name],
                            "\(name)'s value disagrees between 04 section 6.7 and code")
            }
        }

        test("the shared curve appears exactly once, matching 04 section 6.7's control points") {
            let curveSites = swiftFilesImportingUIFramework().filter { $0.text.contains("timingCurve(") }
            expectEqual(curveSites.count, 1,
                        "timingCurve( appears in \(curveSites.count) file(s); 04 section 6.7's "
                            + "\"one curve for the whole product\" requires exactly one")
            expect(curveSites.first?.text.contains("timingCurve(0.32, 0.72, 0, 1") == true,
                   "the shipped curve's control points do not match 04 section 6.7's stated "
                       + "0.32, 0.72, 0, 1")
        }

        test("the canon-sync scan catches a drifted value and a name only one side ships") {
            let canonWithDrift = "### 6.7 The motion register\n"
                + "| **press** | 0.99 | x | y |\n"
                + "\n## 7. Device"
            expectEqual(canonMotionTokens(canonWithDrift)["press"], "0.99",
                        "the canon parser did not read a planted duration")
            let onlyCanonExample = "### 6.7 The motion register\n"
                + "| **ghost** | 1.0 | x | y |\n"
                + "\n## 7. Device"
            expect(canonMotionTokens(onlyCanonExample)["ghost"] == "1.0",
                   "the canon parser missed a planted token-only row")
            let shippedExample = "public enum Motion {\n"
                + "    public static let press: Double = 0.12\n"
                + "    public static let panelPushDistance: CGFloat = 14\n"
                + "}\n"
            expectEqual(shippedMotionTokens(shippedExample)["press"], "0.12",
                        "the shipped parser did not read a planted Double duration")
            expectEqual(shippedMotionTokens(shippedExample)["panelPushDistance"], "14",
                        "the shipped parser did not read a planted CGFloat companion")
        }
    }
}
