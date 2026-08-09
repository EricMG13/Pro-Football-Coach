import Foundation

// The four build-wide invariants from 03b section 1, in one place because that is what they are:
// properties of the whole tree, not of any suite's subject.
//
// Each scan enumerates its file set by walking a directory rather than from a hand-written list.
// AUDIT.md's lesson is that "the test's coverage boundary became the quality boundary" — a scan over
// named files covers the files someone remembered, which is the defect, not the coverage.
//
// Each scan also ships a self-test that plants an offender in a synthetic file and asserts the scan
// catches it. A scan that has never failed is not known to be a scan, and two of these exist
// specifically because the prior build's version shipped green against real violations.

private func packageRoot() -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()   // Suites
        .deletingLastPathComponent()   // SimTests
        .deletingLastPathComponent()   // Tests
        .deletingLastPathComponent()   // package root
}

private func swiftFiles(under relativePath: String) -> [(path: String, text: String)] {
    let root = packageRoot().appendingPathComponent(relativePath)
    let names = FileManager.default.enumerator(atPath: root.path)?
        .compactMap { $0 as? String }
        .filter { $0.hasSuffix(".swift") } ?? []
    return names.compactMap { name in
        guard let text = try? String(contentsOfFile: root.appendingPathComponent(name).path,
                                     encoding: .utf8) else { return nil }
        return (path: "\(relativePath)/\(name)", text: text)
    }
}

/// Every line whose *code* matches `predicate`, as "path:line".
///
/// The comment portion is stripped before the predicate runs, rather than the whole line being
/// skipped when it contains "//". The prior build's scan did the latter, so `foo.hashValue // ok`
/// was silently exempt — a scan you can disable with a trailing comment is not a gate.
///
/// ponytail: naive "//" split, so a "//" inside a string literal truncates the line early. Harmless
/// for these four patterns — none of them can appear in a URL or path string — and the failure mode
/// is a false negative on a line no real offender occupies. Revisit only if a pattern ever needs to
/// match inside string content.
private func offendingLines(
    in files: [(path: String, text: String)],
    where predicate: (String) -> Bool
) -> [String] {
    var offenders: [String] = []
    for file in files {
        for (index, line) in file.text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let code = String(line).components(separatedBy: "//").first ?? ""
            guard !code.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            if predicate(code) { offenders.append("\(file.path):\(index + 1)") }
        }
    }
    return offenders
}

// MARK: - The four predicates, named once so scan and self-test cannot drift apart

// The self-tests below run these against a synthetic file rather than against a copy of the rule.
// If a scan and its self-test each held their own predicate, a fix to one would leave the other
// asserting the old rule — which is how a self-test stops being evidence.

private func importsUIFramework(_ line: String) -> Bool {
    let trimmed = line.trimmingCharacters(in: .whitespaces)
    return trimmed.hasPrefix("import SwiftUI")
        || trimmed.hasPrefix("import UIKit")
        || trimmed.hasPrefix("import AppKit")
}

private func usesHashValue(_ line: String) -> Bool {
    line.contains(".hashValue")
}

private func mintsAmbientIdentity(_ line: String) -> Bool {
    line.contains("UUID()") || line.contains("Date()")
}

private func containsDesignTokenLiteral(_ line: String) -> Bool {
    let markers = [".padding(", ".cornerRadius(", ".font(.system(size:", "spacing: "]
    return markers.contains { marker in
        guard let range = line.range(of: marker) else { return false }
        // A literal is a digit or a decimal point immediately after the marker.
        let rest = line[range.upperBound...].drop(while: { $0 == " " })
        return rest.first.map { $0.isNumber || $0 == "." } ?? false
    }
}

/// Runs a predicate against a synthetic in-memory file, so a self-test never has to write to the
/// tree it is scanning.
private func caught(_ source: String, by predicate: (String) -> Bool) -> Bool {
    !offendingLines(in: [(path: "planted.swift", text: source)], where: predicate).isEmpty
}

// MARK: - The directories each scan walks

// 03 section 3.5: the ambient-identity scan covers the engine's behavioural directories and exempts
// Model/, where `id: UUID = UUID()` as a default parameter is legitimate and a scan cannot tell a
// default from a call.
private let ambientIdentityRoots = ["Engine", "Generation", "AI", "Abstracted"]

func runContractTests() {
    suite("Contracts") {
        test("the engine imports no UI framework") {
            let engine = swiftFiles(under: "Sources/FootballSimCore")
            expect(!engine.isEmpty, "found no engine sources to scan — the scan would pass vacuously")
            let offenders = offendingLines(in: engine, where: importsUIFramework)
            expect(
                offenders.isEmpty,
                "the engine must contain zero UI imports (03b section 1): "
                    + offenders.joined(separator: ", ")
            )
        }

        test("the UI-import scan catches a planted import") {
            expect(caught("import Foundation\nimport SwiftUI\n", by: importsUIFramework),
                   "a planted import SwiftUI was not caught")
            expect(caught("  import UIKit\n", by: importsUIFramework),
                   "a planted indented import UIKit was not caught")
            expect(!caught("// import SwiftUI\n", by: importsUIFramework),
                   "a commented-out import was reported as an offender")
            expect(!caught("let s = \"import SwiftUI is banned\"\n", by: importsUIFramework),
                   "the scan matched inside a string rather than at the start of a line")
        }

        test("no engine code seeds anything from a hash value") {
            // Running a league twice inside one process cannot catch the worst non-determinism,
            // because the thing that varies — Swift's hash seed — is fixed for the life of a
            // process. UUID.hashValue looks like a stable identifier and is not, and one use of it
            // in the free-agent market was enough to make every launch produce a different league
            // from the same save seed. Reading the source is the only cheap guard.
            let engine = swiftFiles(under: "Sources/FootballSimCore")
            expect(!engine.isEmpty, "found no engine sources to scan — the scan would pass vacuously")
            let offenders = offendingLines(in: engine, where: usesHashValue)
            expect(
                offenders.isEmpty,
                "hashValue is salted per process; these lines make the league unreproducible: "
                    + offenders.joined(separator: ", ")
            )
        }

        test("the hashValue scan is not disabled by a trailing comment") {
            // This is the exact defect being fixed. The prior build matched
            // line.contains(".hashValue") && !line.contains("//"), so the second case below
            // shipped green against a real violation.
            expect(caught("let x = someUUID.hashValue\n", by: usesHashValue),
                   "a plain hashValue was not caught")
            expect(caught("let x = someUUID.hashValue // deliberate\n", by: usesHashValue),
                   "a trailing comment disabled the scan — offendingLines is not stripping comments")
            expect(!caught("// someUUID.hashValue would be wrong here\n", by: usesHashValue),
                   "a hashValue mentioned only in prose was reported as an offender")
        }

        test("the engine mints no ambient identity or timestamp") {
            // 03 section 3 clause 5. Nothing enforced it, and clause 3 looks for the wrong thing:
            // the prior build's determinism leak was not a hashValue at all. It was
            // PlayEvent(id: UUID(), ...) at GameSimulator.swift:884, plus default-valued
            // id: UUID = UUID() on four engine initialisers. Five offenders, suite green, because
            // no scan looked. The determinism tests could not see it either — they compare scores
            // and stats, not identities.
            let engine = swiftFiles(under: "Sources/FootballSimCore")
                .filter { file in ambientIdentityRoots.contains { file.path.contains("/\($0)/") } }
            let offenders = offendingLines(in: engine, where: mintsAmbientIdentity)
            expect(
                offenders.isEmpty,
                "identities come from rng.uuid() and time from the simulated calendar (03 "
                    + "section 3 clause 5): " + offenders.joined(separator: ", ")
            )
        }

        test("every directory the ambient-identity scan covers exists") {
            // P0 leaves these directories empty, so the scan above walks nothing and would pass
            // vacuously. That is stated rather than hidden: this assertion fails loudly if a root
            // is ever renamed out from under the scan, which is the way the coverage could vanish
            // without anyone noticing.
            for name in ambientIdentityRoots {
                let path = packageRoot()
                    .appendingPathComponent("Sources/FootballSimCore/\(name)").path
                expect(FileManager.default.fileExists(atPath: path),
                       "Sources/FootballSimCore/\(name) is missing; the ambient-identity scan "
                           + "would silently cover nothing")
            }
        }

        test("the ambient-identity scan catches a planted mint") {
            expect(caught("let leak = UUID()\n", by: mintsAmbientIdentity),
                   "a planted UUID() was not caught")
            expect(caught("event = PlayEvent(id: UUID(), kind: .snap)\n", by: mintsAmbientIdentity),
                   "a planted call-site UUID() argument was not caught")
            expect(caught("init(id: UUID = UUID()) {\n", by: mintsAmbientIdentity),
                   "a planted default-valued initialiser was not caught")
            expect(caught("let stamped = Date()\n", by: mintsAmbientIdentity),
                   "a planted Date() was not caught")
            expect(!caught("let id = rng.uuid()\n", by: mintsAmbientIdentity),
                   "a seeded rng.uuid() was reported as an offender")
        }

        test("no view contains a design-token literal") {
            // DESIGN.md wrote this rule down and the prior build accumulated 43 literal spacings,
            // 25 literal radii and 9 hard-coded font sizes against it. A rule nothing enforces is a
            // wish. P11 extends the pattern set as the design system grows; these four are the ones
            // the audit actually counted.
            let views = swiftFiles(under: "Sources/ProFootballCoachUI")
            expect(!views.isEmpty, "found no view sources to scan — the scan would pass vacuously")
            let offenders = offendingLines(in: views, where: containsDesignTokenLiteral)
            expect(
                offenders.isEmpty,
                "a design-token literal in a view is a defect (04 section 1.1): "
                    + offenders.joined(separator: ", ")
            )
        }

        test("the design-token scan catches a planted literal") {
            expect(caught("Text(\"hi\").padding(16)\n", by: containsDesignTokenLiteral),
                   "a planted .padding(16) was not caught")
            expect(caught("card.cornerRadius(8)\n", by: containsDesignTokenLiteral),
                   "a planted .cornerRadius(8) was not caught")
            expect(caught("Text(\"hi\").font(.system(size: 13))\n", by: containsDesignTokenLiteral),
                   "a planted literal font size was not caught")
            expect(caught("VStack(spacing: 12) {\n", by: containsDesignTokenLiteral),
                   "a planted literal spacing was not caught")
            expect(!caught("Text(\"hi\").padding(Token.gutter)\n", by: containsDesignTokenLiteral),
                   "a token-valued padding was reported as an offender")
            expect(!caught("VStack(spacing: Token.stack) {\n", by: containsDesignTokenLiteral),
                   "a token-valued spacing was reported as an offender")
        }
    }
}
