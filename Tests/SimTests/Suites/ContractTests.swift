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
//
// The self-tests deliberately include the spellings a real offender uses rather than only the
// idealised one the author had in mind: `import struct SwiftUI.Color`, `Date.now`, `Hasher()`, and
// a `.hashValue` sitting behind a URL string literal. An adversarial review of P0 planted each of
// those in the tree and watched an earlier version of this file stay green.

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

/// Strips comments and blanks the contents of string literals, one file at a time, carrying
/// block-comment state across line boundaries.
///
/// The prior build skipped any line containing "//", so `foo.hashValue // ok` was silently exempt.
/// The first fix here split on "//" instead — which was still wrong in the other direction: a URL
/// literal truncated the line, so `docsURL("https://x.io") + id.hashValue` was invisible, and
/// `Link(destination: URL(string: "https://x.com")!).padding(16)` was invisible. Both are ordinary
/// code, not contrivances. Quotes are kept and only their contents dropped, so a predicate can
/// still see that a string was there.
///
/// ponytail: no raw-string (`#"…"#`) or multiline (`"""`) handling. A multiline literal degrades to
/// blanking its content, which is the safe direction. A raw string containing a backslash could
/// mis-track the closing quote and blank the rest of the line — a false negative on a line no
/// pattern here occupies. Revisit if the tree ever gains raw strings.
private func codeLines(of text: String) -> [String] {
    var lines: [String] = []
    var inBlockComment = false
    for rawLine in text.split(separator: "\n", omittingEmptySubsequences: false) {
        let characters = Array(rawLine)
        var code = ""
        var index = 0
        var inString = false
        while index < characters.count {
            let character = characters[index]
            if inBlockComment {
                if character == "*", index + 1 < characters.count, characters[index + 1] == "/" {
                    inBlockComment = false
                    index += 2
                } else {
                    index += 1
                }
            } else if inString {
                if character == "\\" {
                    index += 2          // an escape, including \" — never ends the literal
                } else if character == "\"" {
                    inString = false
                    code.append("\"")
                    index += 1
                } else {
                    index += 1          // drop the literal's content
                }
            } else if character == "/", index + 1 < characters.count, characters[index + 1] == "/" {
                break                   // line comment: the rest of the line is prose
            } else if character == "/", index + 1 < characters.count, characters[index + 1] == "*" {
                inBlockComment = true
                index += 2
            } else if character == "\"" {
                inString = true
                code.append("\"")
                index += 1
            } else {
                code.append(character)
                index += 1
            }
        }
        lines.append(code)
    }
    return lines
}

/// Every line whose *code* matches `predicate`, as "path:line".
private func offendingLines(
    in files: [(path: String, text: String)],
    where predicate: (String) -> Bool
) -> [String] {
    var offenders: [String] = []
    for file in files {
        for (index, line) in codeLines(of: file.text).enumerated() {
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            if predicate(line) { offenders.append("\(file.path):\(index + 1)") }
        }
    }
    return offenders
}

// MARK: - The four predicates, named once so scan and self-test cannot drift apart

// The self-tests below run these against a synthetic file rather than against a copy of the rule.
// If a scan and its self-test each held their own predicate, a fix to one would leave the other
// asserting the old rule — which is how a self-test stops being evidence.

private let uiModules: Set<String> = ["SwiftUI", "UIKit", "AppKit"]

/// True for any form of import that brings a UI module into scope.
///
/// `hasPrefix("import SwiftUI")` is not enough. All of these compile and all of these put a UI type
/// in the engine: `import struct SwiftUI.Color`, `@_exported import SwiftUI`,
/// `@preconcurrency import UIKit`. This is also how 03b section 1's second limb — "no UI type" — is
/// upheld: a type cannot be referenced from a module that was never imported in any form.
private func importsUIFramework(_ line: String) -> Bool {
    var rest = line.trimmingCharacters(in: .whitespaces)
    while rest.hasPrefix("@") {                       // @_exported, @testable, @preconcurrency
        guard let space = rest.firstIndex(of: " ") else { return false }
        rest = String(rest[rest.index(after: space)...]).trimmingCharacters(in: .whitespaces)
    }
    guard rest.hasPrefix("import ") else { return false }
    rest = String(rest.dropFirst("import ".count)).trimmingCharacters(in: .whitespaces)
    // A submodule import names the declaration's kind first: `import struct SwiftUI.Color`.
    for kind in ["struct ", "class ", "enum ", "protocol ", "typealias ", "func ", "var ", "let "]
    where rest.hasPrefix(kind) {
        rest = String(rest.dropFirst(kind.count)).trimmingCharacters(in: .whitespaces)
        break
    }
    return uiModules.contains(String(rest.prefix { $0.isLetter || $0.isNumber || $0 == "_" }))
}

/// True for any per-launch-salted hash, not only the literal spelling `hashValue`.
///
/// `03` section 3 clause 2's rule is *seeds derive from identifier bytes, never from a salted hash*.
/// `Hasher()` is salted in exactly the way `hashValue` is; a scan that matches only the latter
/// implements the letter of 03b's table rather than the rule it stands for.
private func usesSaltedHash(_ line: String) -> Bool {
    line.contains(".hashValue") || line.contains("Hasher(") || line.contains("hash(into:")
}

/// True for any ambient source of identity, time or randomness.
///
/// `Date.now` is the idiomatic modern spelling of the clause-5 defect and evades a `Date()` match
/// entirely. `.random(in:)` and `SystemRandomNumberGenerator` are the same defect for the RNG:
/// clause 4 says the RNG is a value type passed explicitly, with no ambient randomness anywhere.
private func mintsAmbientIdentity(_ line: String) -> Bool {
    let markers = [
        "UUID()", "Date()", "Date.now", "Date(timeInterval",
        ".random(", "SystemRandomNumberGenerator", "arc4random", ".shuffled()",
    ]
    return markers.contains { line.contains($0) }
}

/// True if `text` contains a numeric literal that stands alone as a token.
///
/// A number that continues an identifier or follows a member dot is not a literal in the sense that
/// matters: `Token.gutter2` and `spacing.x2` are names. A number after `(`, `,`, `:` or whitespace
/// is a magic number.
private func containsBareNumber(_ text: Substring) -> Bool {
    let characters = Array(text)
    var index = 0
    while index < characters.count {
        let character = characters[index]
        let startsNumber = character.isNumber
            || (character == "." && index + 1 < characters.count && characters[index + 1].isNumber)
        if startsNumber {
            let previous: Character = index > 0 ? characters[index - 1] : "("
            if !(previous.isLetter || previous.isNumber || previous == "_" || previous == ".") {
                return true
            }
            while index < characters.count,
                  characters[index].isLetter || characters[index].isNumber
                    || characters[index] == "_" || characters[index] == "." {
                index += 1
            }
            continue
        }
        index += 1
    }
    return false
}

/// The argument text a marker owns: to the paren that closes the one it opened, or — for a label
/// marker, which opens nothing — to the next comma or unmatched close paren.
private func argumentSpan(of line: String, from start: String.Index, balanced: Bool) -> Substring {
    var depth = balanced ? 1 : 0
    var index = start
    while index < line.endIndex {
        switch line[index] {
        case "(":
            depth += 1
        case ")":
            if depth == 0 { return line[start..<index] }
            depth -= 1
            if balanced, depth == 0 { return line[start..<index] }
        case ",":
            if depth == 0 { return line[start..<index] }
        default:
            break
        }
        index = line.index(after: index)
    }
    return line[start..<line.endIndex]
}

/// True if a design-token position holds a magic number rather than a token.
///
/// Two bugs an adversarial review found in the first version, both fixed here. It accepted any `.`
/// after the marker as a decimal point, so `.padding(.horizontal, Token.gutter)` and
/// `VStack(spacing: .zero)` were reported as offenders — a false failure on compliant SwiftUI, and
/// the kind of thing that gets a gate weakened rather than obeyed. And it matched only
/// `"spacing: "` with a trailing space, so `VStack(spacing:12)` was invisible.
///
/// ponytail: still the small pattern set the plan scopes to P0 — the ones AUDIT.md actually counted,
/// plus the label spellings of the same properties. Literal colours are 03b's fourth token class and
/// are NOT covered here; P11 owns extending this set as the component registry makes the class
/// enumerable by construction. Recorded in docs/STATUS.md rather than left implicit.
private func containsDesignTokenLiteral(_ line: String) -> Bool {
    let callMarkers = [".padding(", ".cornerRadius("]
    let labelMarkers = ["spacing:", "cornerRadius:", "size:", "radius:", "lineWidth:"]
    for (markers, balanced) in [(callMarkers, true), (labelMarkers, false)] {
        for marker in markers {
            var searchStart = line.startIndex
            while let found = line.range(of: marker, range: searchStart..<line.endIndex) {
                if containsBareNumber(argumentSpan(of: line, from: found.upperBound,
                                                   balanced: balanced)) {
                    return true
                }
                searchStart = found.upperBound
            }
        }
    }
    return false
}

/// Runs a predicate against a synthetic in-memory file, so a self-test never has to write to the
/// tree it is scanning.
private func caught(_ source: String, by predicate: (String) -> Bool) -> Bool {
    !offendingLines(in: [(path: "planted.swift", text: source)], where: predicate).isEmpty
}

// MARK: - The dictionary-key scan

/// Key types Swift already encodes as a JSON object without help.
private let inherentlyKeyableTypes: Set<String> = ["String", "Int", "UUID"]

/// Every dictionary key type named in a `[Key: Value]` annotation in `text`.
///
/// ponytail: matches the annotation syntax the model actually uses — `[Key: Value]` with a single
/// capitalised identifier before the colon. A key that is itself generic or nested arrives as its
/// outer name, which is the conservative direction: it gets checked rather than skipped.
func dictionaryKeyTypes(in text: String) -> Set<String> {
    var found: Set<String> = []
    for line in codeLines(of: text) {
        var characters = Array(line)
        var index = 0
        while index < characters.count {
            guard characters[index] == "[" else { index += 1; continue }
            var cursor = index + 1
            while cursor < characters.count, characters[cursor] == " " { cursor += 1 }
            var name = ""
            while cursor < characters.count,
                  characters[cursor].isLetter || characters[cursor].isNumber
                    || characters[cursor] == "_" {
                name.append(characters[cursor])
                cursor += 1
            }
            // A dictionary annotation is "[Name:", with nothing between the name and the colon but
            // spaces. "[Name]" is an array and "[a: b]" is a literal with a lowercase key.
            while cursor < characters.count, characters[cursor] == " " { cursor += 1 }
            if cursor < characters.count, characters[cursor] == ":",
               let initial = name.first, initial.isUppercase {
                found.insert(name)
            }
            index += 1
        }
        _ = characters
    }
    return found
}

/// Every type given a `CodingKeyRepresentable` conformance anywhere in the engine.
private func codingKeyRepresentableTypes(in files: [(path: String, text: String)]) -> Set<String> {
    var conformed: Set<String> = []
    for file in files {
        for line in codeLines(of: file.text) where line.contains("CodingKeyRepresentable") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("extension ") else { continue }
            let rest = trimmed.dropFirst("extension ".count).drop(while: { $0 == " " })
            conformed.insert(String(rest.prefix { $0.isLetter || $0.isNumber || $0 == "_" }))
        }
    }
    return conformed
}

// MARK: - The directories each scan walks

// 03 section 3.5: `id: UUID = UUID()` as a default parameter is legitimate in Model/, and a scan
// cannot tell a default from a call. So Model/ is exempt BY NAME and everything else in the engine
// is covered by construction — the inverse of a hand-written list of covered directories, which
// would give a P3 that invents Sources/FootballSimCore/Simulation/ zero coverage while staying
// green. That is precisely CLAUDE.md's coverage-boundary failure, and an adversarial review found
// this file committing it.
private let ambientIdentityExemptDirectories = ["Model"]

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

        test("the UI-import scan catches every spelling of the import") {
            expect(caught("import Foundation\nimport SwiftUI\n", by: importsUIFramework),
                   "a planted import SwiftUI was not caught")
            expect(caught("  import UIKit\n", by: importsUIFramework),
                   "a planted indented import UIKit was not caught")
            expect(caught("import struct SwiftUI.Color\n", by: importsUIFramework),
                   "a planted submodule import was not caught")
            expect(caught("import class UIKit.UIImage\n", by: importsUIFramework),
                   "a planted submodule class import was not caught")
            expect(caught("@_exported import SwiftUI\n", by: importsUIFramework),
                   "a planted @_exported import was not caught")
            expect(caught("@preconcurrency import AppKit\n", by: importsUIFramework),
                   "a planted attributed import was not caught")
            expect(!caught("// import SwiftUI\n", by: importsUIFramework),
                   "a commented-out import was reported as an offender")
            expect(!caught("let s = \"import SwiftUI is banned\"\n", by: importsUIFramework),
                   "the scan matched inside a string rather than at the start of a line")
            expect(!caught("import Foundation\n", by: importsUIFramework),
                   "a legitimate import was reported as an offender")
            expect(!caught("import SwiftUIX\n", by: importsUIFramework),
                   "the scan matched a module whose name merely starts with SwiftUI")
        }

        test("no engine code seeds anything from a salted hash") {
            // Running a league twice inside one process cannot catch the worst non-determinism,
            // because the thing that varies — Swift's hash seed — is fixed for the life of a
            // process. UUID.hashValue looks like a stable identifier and is not, and one use of it
            // in the free-agent market was enough to make every launch produce a different league
            // from the same save seed. Reading the source is the only cheap guard.
            let engine = swiftFiles(under: "Sources/FootballSimCore")
            expect(!engine.isEmpty, "found no engine sources to scan — the scan would pass vacuously")
            let offenders = offendingLines(in: engine, where: usesSaltedHash)
            expect(
                offenders.isEmpty,
                "a salted hash is per-process; these lines make the league unreproducible: "
                    + offenders.joined(separator: ", ")
            )
        }

        test("the salted-hash scan is not disabled by a comment or a string literal") {
            // Three defects, each of which shipped green against a real violation at some point in
            // this file's short history.
            expect(caught("let x = someUUID.hashValue\n", by: usesSaltedHash),
                   "a plain hashValue was not caught")
            expect(caught("let x = someUUID.hashValue // deliberate\n", by: usesSaltedHash),
                   "a trailing comment disabled the scan")
            expect(caught("let n = docs(\"https://x.io\").count + id.hashValue\n", by: usesSaltedHash),
                   "a URL literal truncated the line and hid the offender")
            expect(caught("var h = Hasher(); h.combine(id)\n", by: usesSaltedHash),
                   "a planted Hasher() was not caught")
            expect(!caught("// someUUID.hashValue would be wrong here\n", by: usesSaltedHash),
                   "a hashValue mentioned only in prose was reported as an offender")
            expect(!caught("/* discussing .hashValue\n   across lines */\n", by: usesSaltedHash),
                   "a hashValue inside a block comment was reported as an offender")
        }

        test("the engine mints no ambient identity, timestamp or randomness") {
            // 03 section 3 clauses 4 and 5. Nothing enforced them, and clause 3's scan looks for the
            // wrong thing: the prior build's determinism leak was not a hashValue at all. It was
            // PlayEvent(id: UUID(), ...) at GameSimulator.swift:884, plus default-valued
            // id: UUID = UUID() on four engine initialisers. Five offenders, suite green, because
            // no scan looked. The determinism tests could not see it either — they compare scores
            // and stats, not identities.
            let engine = swiftFiles(under: "Sources/FootballSimCore").filter { file in
                !ambientIdentityExemptDirectories.contains { file.path.contains("/\($0)/") }
            }
            expect(!engine.isEmpty, "found no engine sources to scan — the scan would pass vacuously")
            let offenders = offendingLines(in: engine, where: mintsAmbientIdentity)
            expect(
                offenders.isEmpty,
                "identities come from rng.uuid(), time from the simulated calendar and randomness "
                    + "from an explicitly threaded SeededRandom (03 section 3 clauses 4 and 5): "
                    + offenders.joined(separator: ", ")
            )
        }

        test("the ambient-identity scan catches every spelling of the mint") {
            expect(caught("let leak = UUID()\n", by: mintsAmbientIdentity),
                   "a planted UUID() was not caught")
            expect(caught("event = PlayEvent(id: UUID(), kind: .snap)\n", by: mintsAmbientIdentity),
                   "a planted call-site UUID() argument was not caught")
            expect(caught("init(id: UUID = UUID()) {\n", by: mintsAmbientIdentity),
                   "a planted default-valued initialiser was not caught")
            expect(caught("let stamped = Date()\n", by: mintsAmbientIdentity),
                   "a planted Date() was not caught")
            expect(caught("let stamped = Date.now\n", by: mintsAmbientIdentity),
                   "a planted Date.now was not caught")
            expect(caught("let roll = Int.random(in: 1...6)\n", by: mintsAmbientIdentity),
                   "a planted ambient random was not caught")
            expect(caught("let order = teams.shuffled()\n", by: mintsAmbientIdentity),
                   "a planted stdlib shuffled() was not caught")
            expect(!caught("let id = rng.uuid()\n", by: mintsAmbientIdentity),
                   "a seeded rng.uuid() was reported as an offender")
            expect(!caught("let order = rng.shuffled(teams)\n", by: mintsAmbientIdentity),
                   "a seeded rng.shuffled(_:) was reported as an offender")
        }

        test("no view contains a design-token literal") {
            // DESIGN.md wrote this rule down and the prior build accumulated 43 literal spacings,
            // 25 literal radii and 9 hard-coded font sizes against it. A rule nothing enforces is a
            // wish.
            let views = swiftFiles(under: "Sources/ProFootballCoachUI")
            expect(!views.isEmpty, "found no view sources to scan — the scan would pass vacuously")
            let offenders = offendingLines(in: views, where: containsDesignTokenLiteral)
            expect(
                offenders.isEmpty,
                "a design-token literal in a view is a defect (04 section 1.1): "
                    + offenders.joined(separator: ", ")
            )
        }

        test("the design-token scan catches a planted literal and spares a token") {
            expect(caught("Text(\"hi\").padding(16)\n", by: containsDesignTokenLiteral),
                   "a planted .padding(16) was not caught")
            expect(caught("Text(\"hi\").padding(.horizontal, 16)\n", by: containsDesignTokenLiteral),
                   "a planted literal after an edge set was not caught")
            expect(caught("card.cornerRadius(8)\n", by: containsDesignTokenLiteral),
                   "a planted .cornerRadius(8) was not caught")
            expect(caught("RoundedRectangle(cornerRadius: 12)\n", by: containsDesignTokenLiteral),
                   "a planted shape corner radius was not caught")
            expect(caught("Text(\"hi\").font(.system(size: 13))\n", by: containsDesignTokenLiteral),
                   "a planted literal font size was not caught")
            expect(caught("Text(\"hi\").font(.custom(\"Inter\", size: 13))\n",
                          by: containsDesignTokenLiteral),
                   "a planted custom-font literal size was not caught")
            expect(caught("VStack(spacing: 12) {\n", by: containsDesignTokenLiteral),
                   "a planted literal spacing was not caught")
            expect(caught("VStack(spacing:12) {\n", by: containsDesignTokenLiteral),
                   "a literal spacing without a space after the colon was not caught")
            expect(caught("Link(\"d\", destination: URL(string: \"https://x.com\")!).padding(16)\n",
                          by: containsDesignTokenLiteral),
                   "a URL literal truncated the line and hid the offender")
            expect(!caught("Text(\"hi\").padding(Token.gutter)\n", by: containsDesignTokenLiteral),
                   "a token-valued padding was reported as an offender")
            expect(!caught("Text(\"hi\").padding(.horizontal, Token.gutter)\n",
                           by: containsDesignTokenLiteral),
                   "an edge set plus a token was reported as an offender")
            expect(!caught("VStack(spacing: .zero) {\n", by: containsDesignTokenLiteral),
                   "a leading-dot enum case was mistaken for a decimal point")
            expect(!caught("VStack(spacing: Token.stack) {\n", by: containsDesignTokenLiteral),
                   "a token-valued spacing was reported as an offender")
            expect(!caught("Text(\"hi\").padding(Token.gutter2)\n", by: containsDesignTokenLiteral),
                   "a digit inside a token's name was mistaken for a literal")
        }

        test("every directory the ambient-identity scan exempts exists") {
            // Model/ is exempt by name. If it is ever renamed, the exemption silently stops
            // applying — which fails safe — but the intent is lost, so say so out loud.
            for name in ambientIdentityExemptDirectories {
                let path = packageRoot()
                    .appendingPathComponent("Sources/FootballSimCore/\(name)").path
                expect(FileManager.default.fileExists(atPath: path),
                       "Sources/FootballSimCore/\(name) is missing, so the ambient-identity "
                           + "exemption names a directory that is not there")
            }
        }

        test("every dictionary key type in the engine encodes as a JSON object") {
            // Swift keys a JSON object only when the key is String, Int or CodingKeyRepresentable.
            // Anything else encodes as a flat [key, value, key, value] array in DICTIONARY ORDER,
            // which is salted per process — so the save bytes churn between launches and no
            // byte-level determinism test downstream can hold.
            //
            // CodingSupport was ported to fix this for UUID. P1 reintroduced it for Attribute and
            // CoachAttribute, because the port log recorded the fix and not the rule. This scan is
            // the rule: a phase that adds an enum-keyed map without a conformance fails here rather
            // than shipping a save that differs from itself.
            let engine = swiftFiles(under: "Sources/FootballSimCore")
            expect(!engine.isEmpty, "found no engine sources to scan — the scan would pass vacuously")
            let conformed = codingKeyRepresentableTypes(in: engine)
            var unsafe: [String] = []
            for file in engine {
                for key in dictionaryKeyTypes(in: file.text)
                where !inherentlyKeyableTypes.contains(key) && !conformed.contains(key) {
                    unsafe.append("\(file.path): [\(key): ...]")
                }
            }
            expect(
                unsafe.isEmpty,
                "these dictionary keys are not CodingKeyRepresentable, so their maps encode in "
                    + "hash order: " + unsafe.sorted().joined(separator: ", ")
            )
        }

        test("the dictionary-key scan catches an unconformed key and spares a conformed one") {
            expect(dictionaryKeyTypes(in: "var m: [Attribute: Rating] = [:]\n").contains("Attribute"),
                   "a planted dictionary annotation was not seen")
            expect(dictionaryKeyTypes(in: "var m: [String: Int]\n").contains("String"),
                   "a String-keyed annotation was not seen")
            expect(!dictionaryKeyTypes(in: "var ids: [UUID]\n").contains("UUID"),
                   "an array was mistaken for a dictionary")
            expect(!dictionaryKeyTypes(in: "let m = [key: value]\n").contains("key"),
                   "a lowercase literal key was mistaken for a type")
            expect(!dictionaryKeyTypes(in: "// [Attribute: Rating] in prose\n").contains("Attribute"),
                   "a dictionary mentioned only in a comment was reported")
        }

        test("no symlink hides source from the scans") {
            // FileManager.enumerator(atPath:) lists a symlink but does not descend into it, while
            // SwiftPM compiles whatever the link resolves to. A symlinked source directory would
            // therefore be built and never scanned — the coverage boundary parting company with
            // the compiler's, which is the one thing these scans exist to prevent.
            for root in ["Sources", "Tests"] {
                let base = packageRoot().appendingPathComponent(root)
                let names = FileManager.default.enumerator(atPath: base.path)?
                    .compactMap { $0 as? String } ?? []
                for name in names {
                    let attributes = try? FileManager.default
                        .attributesOfItem(atPath: base.appendingPathComponent(name).path)
                    let type = attributes?[.type] as? FileAttributeType
                    expect(type != .typeSymbolicLink,
                           "\(root)/\(name) is a symlink; the source scans do not follow it")
                }
            }
        }
    }
}
