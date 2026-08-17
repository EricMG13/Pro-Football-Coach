import Foundation
@testable import ProFootballCoachUI

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

func packageRoot() -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()   // Suites
        .deletingLastPathComponent()   // SimTests
        .deletingLastPathComponent()   // Tests
        .deletingLastPathComponent()   // package root
}

func swiftFiles(under relativePath: String) -> [(path: String, text: String)] {
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

/// Every Swift file anywhere under `Sources/` that brings a UI framework into scope.
///
/// The class "code that draws" defined by what makes code draw, so a target added tomorrow is
/// covered the day it is added rather than the day someone remembers it (`CLAUDE.md`: a test's
/// coverage boundary must not become the quality boundary).
func swiftFilesImportingUIFramework() -> [(path: String, text: String)] {
    swiftFiles(under: "Sources").filter { file in
        file.text.split(separator: "\n").contains { importsUIFramework(String($0)) }
    }
}

private func referencesAuthoritativeRoot(_ line: String) -> Bool {
    line.split { character in
        !(character.isLetter || character.isNumber || character == "_")
    }.contains("GameState")
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

/// The files the save-shape scans walk: the whole engine, minus anything explicitly exempted.
private func savedShapeFiles() -> [(path: String, text: String)] {
    swiftFiles(under: "Sources/FootballSimCore").filter { file in
        !saveShapeExemptDirectories.contains { file.path.contains("/\($0)/") }
    }
}

/// Runs a predicate against a synthetic in-memory file, so a self-test never has to write to the
/// tree it is scanning.
private func caught(_ source: String, by predicate: (String) -> Bool) -> Bool {
    !offendingLines(in: [(path: "planted.swift", text: source)], where: predicate).isEmpty
}

// MARK: - The dictionary-key scan

/// Key types Swift already encodes as a JSON object with no help from us.
///
/// `UUID` is **not** on this list, deliberately, even though every `[UUID: ...]` map in the save
/// encodes correctly today. It does so only because of the retroactive `CodingKeyRepresentable`
/// conformance in `Support/CodingSupport.swift`. Allowlisting `UUID` here meant deleting that
/// conformance left this scan green while every UUID-keyed map in an 800 KB save reverted to
/// hash-ordered flat arrays — the scan would have been allowlisting the fix rather than checking
/// for it.
private let inherentlyKeyableTypes: Set<String> = ["String", "Int"]

/// Directories whose types are never encoded, and are therefore outside the save-shape scans.
///
/// Exempt-by-name, cover-everything-else — the inversion the ambient-identity scan already uses,
/// carried across after P2 put ten `Codable` save types in `Generation/` while both of these scans
/// still walked `Model/` alone. Nothing is exempt today; the list exists so that a future
/// scratch-only directory is an explicit, visible decision rather than a scope that quietly
/// stopped covering the tree.
private let saveShapeExemptDirectories: [String] = []

/// Every dictionary key type named in `text`, in either spelling Swift accepts.
///
/// Both forms, because the sugar-only version shipped and a planted `Dictionary<ProbeKey, Int>`
/// walked straight past it:
///
///     [Key: Value]            the sugar
///     Dictionary<Key, Value>  the generic spelling
///
/// ponytail: a key that is itself generic or nested arrives as its outer name, which is the
/// conservative direction — it gets checked rather than skipped. The one spelling neither form
/// catches is a dictionary declared with no type annotation at all; `stored properties carry a
/// type annotation` below is the rule that closes it.
func dictionaryKeyTypes(in text: String) -> Set<String> {
    var found: Set<String> = []
    for line in codeLines(of: text) {
        let characters = Array(line)
        var index = 0
        while index < characters.count {
            if characters[index] == "[" {
                var cursor = index + 1
                while cursor < characters.count, characters[cursor] == " " { cursor += 1 }
                var name = ""
                while cursor < characters.count, isIdentifierCharacter(characters[cursor]) {
                    name.append(characters[cursor])
                    cursor += 1
                }
                // A dictionary annotation is "[Name:", with nothing between the name and the colon
                // but spaces. "[Name]" is an array and "[a: b]" is a literal with a lowercase key.
                while cursor < characters.count, characters[cursor] == " " { cursor += 1 }
                if cursor < characters.count, characters[cursor] == ":",
                   name.first?.isUppercase == true {
                    found.insert(name)
                }
            }
            index += 1
        }
        if let key = genericKeyType(in: line, after: "Dictionary<") { found.insert(key) }
    }
    return found
}

/// Every `Set<Element>` element type named in `text`.
///
/// `Set` encodes to an *unkeyed* container in iteration order, and `.sortedKeys` orders object keys
/// rather than array elements — so a `Set` in a `Codable` model is the same per-launch churn a
/// hash-ordered dictionary is, on a shape the dictionary scan cannot see. P1 shipped exactly that
/// on `Player.traits`.
/// Only *stored* properties. A computed property that returns a `Set` is never encoded — the first
/// version of this scan flagged `OffensiveScheme.emphasises`, which is a lookup table, not a save
/// field. A gate that fails on correct code gets weakened rather than obeyed.
func setElementTypes(in text: String) -> Set<String> {
    var found: Set<String> = []
    for line in codeLines(of: text) where storedPropertyDeclaration(in: line) != nil {
        if let element = genericKeyType(in: line, after: "Set<") { found.insert(element) }
    }
    return found
}

/// The part of `line` after `var`/`let` and its name, if `line` declares a **stored property of a
/// type** — not a local binding, and not a computed property.
///
/// Two discriminators, both textual, because the alternative is parsing Swift:
///
/// - **Indentation of four spaces or less.** A type's own members sit one level in; a binding
///   inside a function body sits at eight or more. The first version of this scan had no such
///   check and reported eleven `let container = try decoder...` locals as offenders.
/// - **No `{` after the declaration.** That is a computed property or an observer.
///
/// ponytail: a stored property of a *nested* type sits at eight spaces and is therefore skipped.
/// The model has no nested stored properties today. If one appears, this misses it — a false
/// negative, which is the direction that does not break a correct build.
private func storedPropertyDeclaration(in line: String) -> Substring? {
    let indent = line.prefix(while: { $0 == " " }).count
    guard indent <= 4 else { return nil }
    var rest = Substring(line.trimmingCharacters(in: .whitespaces))
    // `static` declarations are skipped rather than stripped. A static is a lookup table, not a
    // field of an encoded value, so neither save-shape rule applies to it: `Blocklist.names` is a
    // legitimate `static let Set<String>`, and the rules modules are full of legitimate inferred
    // static constants. Including them turned one scan into 70 false failures and the other into
    // one, which is how a gate gets weakened instead of obeyed.
    if rest.hasPrefix("static ") || rest.hasPrefix("class ") { return nil }
    for modifier in ["public ", "internal ", "private ", "fileprivate ", "private(set) ",
                     "public private(set) ", "lazy "]
    where rest.hasPrefix(modifier) {
        rest = rest.dropFirst(modifier.count)
    }
    if rest.hasPrefix("static ") || rest.hasPrefix("class ") { return nil }
    guard rest.hasPrefix("var ") || rest.hasPrefix("let ") else { return nil }
    guard !rest.contains("{") else { return nil }
    let declaration = rest.dropFirst(4)
    let name = declaration.prefix(while: isIdentifierCharacter)
    guard !name.isEmpty else { return nil }
    return declaration[name.endIndex...].drop(while: { $0 == " " })
}

private func isIdentifierCharacter(_ character: Character) -> Bool {
    character.isLetter || character.isNumber || character == "_"
}

/// The first type argument following `marker`, if the line contains it.
private func genericKeyType(in line: String, after marker: String) -> String? {
    guard let range = line.range(of: marker) else { return nil }
    let rest = line[range.upperBound...].drop(while: { $0 == " " })
    let name = String(rest.prefix(while: isIdentifierCharacter))
    return name.first?.isUppercase == true ? name : nil
}

/// Stored-property declarations in `text` that carry no explicit type annotation.
///
/// The inferred-literal case the two scans above cannot see: `var m = [SomeKey.a: 1]` declares a
/// dictionary with no annotation anywhere for a scan to read. Rather than parse Swift, `Model/`
/// carries the rule that a stored property is annotated — which is good practice for a type that
/// defines a save format anyway, and makes the other two scans total over that directory.
func unannotatedStoredProperties(in text: String) -> [Int] {
    var offenders: [Int] = []
    for (index, line) in codeLines(of: text).enumerated() {
        guard let afterName = storedPropertyDeclaration(in: line) else { continue }
        // An annotated declaration reads "name: Type". Anything else that assigns is inferred.
        if afterName.hasPrefix(":") { continue }
        if afterName.hasPrefix("=") { offenders.append(index + 1) }
    }
    return offenders
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

private func contrastRatio(
    _ foreground: CoachWorldTokens.ColorValue,
    _ background: CoachWorldTokens.ColorValue
) -> Double {
    func linearized(_ channel: Double) -> Double {
        channel <= 0.04045
            ? channel / 12.92
            : pow((channel + 0.055) / 1.055, 2.4)
    }
    func relativeLuminance(_ color: CoachWorldTokens.ColorValue) -> Double {
        0.2126 * linearized(color.red) + 0.7152 * linearized(color.green)
            + 0.0722 * linearized(color.blue)
    }
    let foregroundLuminance = relativeLuminance(foreground)
    let backgroundLuminance = relativeLuminance(background)
    return (max(foregroundLuminance, backgroundLuminance) + 0.05)
        / (min(foregroundLuminance, backgroundLuminance) + 0.05)
}

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

        test("no file that imports a UI framework owns or reads the authoritative root") {
            // Enumerated by construction rather than by directory. This scan read
            // `Sources/ProFootballCoachUI` until 2026-08-13, which made the directory the rule
            // instead of the rule the rule: `Sources/CoachWorldApp` — the composition layer G-01
            // added, which by design sees both the root and the read models — would have been
            // outside it on the day it was created, and every future target after that. The class
            // this defends is "code that draws", and what defines that class is the UI import.
            let views = swiftFilesImportingUIFramework()
            expect(views.count >= 8,
                   "found \(views.count) UI-importing sources — the scan would pass vacuously")
            // The enumeration itself is asserted, because a scan that silently stops finding the
            // views is indistinguishable from a scan that finds them clean.
            for known in [
                "CoachingHQView", "RosterView", "MatchDayView", "PlayerProfileView",
                "RecruitingBoardView", "RootView", "CoachWorldAppRootView",
            ] {
                expect(views.contains { $0.path.hasSuffix("/\(known).swift") },
                       "\(known).swift is not in the UI-importing enumeration")
            }
            let offenders = offendingLines(in: views, where: referencesAuthoritativeRoot)
            expect(
                offenders.isEmpty,
                "UI code consumes immutable read models and intents, never GameState: "
                    + offenders.joined(separator: ", ")
            )
        }

        test("the composition layer is where the root and the read models meet") {
            // The other half of the boundary. G-01 needed one place that sees both, and the risk of
            // creating it is that it becomes a second UI layer with the root in scope. So it is
            // asserted to exist, to hold the root, and to keep the two in separate files.
            let composition = swiftFiles(under: "Sources/CoachWorldApp")
            expect(!composition.isEmpty, "the composition layer is missing")
            let holdsRoot = composition.filter { file in
                file.text.split(separator: "\n").contains {
                    referencesAuthoritativeRoot(String($0))
                }
            }
            expect(!holdsRoot.isEmpty,
                   "no file in the composition layer reads the root, so nothing can be truthful")
            for file in holdsRoot {
                expect(!file.text.split(separator: "\n").contains {
                    importsUIFramework(String($0))
                }, "\(file.path) both draws and holds the authoritative root")
            }
        }

        test("the shipped application root is the composition root, not the proof harness") {
            let shell = swiftFiles(under: "App")
            expect(!shell.isEmpty, "the application target has no sources")
            let entryPoint = shell.first { $0.text.contains("@main") }?.text ?? ""
            expect(entryPoint.contains("CoachWorldAppRootView"),
                   "a release build must launch into the simulated world, not into a fixture")
        }

        test("HQ film inspection reaches the application service") {
            let root = swiftFiles(under: "Sources/CoachWorldApp")
                .first { $0.path.hasSuffix("/CoachWorldAppRootView.swift") }?.text ?? ""
            let store = swiftFiles(under: "Sources/CoachWorldApp")
                .first { $0.path.hasSuffix("/CoachWorldStore.swift") }?.text ?? ""
            expect(root.contains("inspectOpponentFilm()")
                       && root.contains("navigate(.opponentReportFilmRoom"),
                   "HQ film inspection must reach the store seam and film route")
            expect(!root.contains("onInspect: {}"),
                   "HQ film inspection must not be a dead callback")
            expect(store.contains("No current opponent film evidence is recorded."),
                   "missing film evidence needs an explicit unavailable state")
            let filmFiles = swiftFiles(under: "Sources/ProFootballCoachUI")
            let film = filmFiles.first { $0.path.hasSuffix("/OpponentFilmView.swift") }?.text ?? ""
            let filmModel = filmFiles.first {
                $0.path.hasSuffix("/OpponentFilmReadModels.swift")
            }?.text ?? ""
            let filmProvider = swiftFiles(under: "Sources/CoachWorldApp")
                .first { $0.path.hasSuffix("/CoachWorldOpponentFilmProvider.swift") }?.text ?? ""
            expect(film.contains("public struct OpponentFilmView")
                       && film.contains("OPPONENT REPORT"),
                   "film must render an evidence-backed production surface")
            expect(filmModel.contains("public struct OpponentFilmReadModel")
                       && filmModel.contains("Observer-scoped"),
                   "film must consume a bounded immutable read model")
            expect(filmProvider.contains("static func opponentFilm(from state: GameState)")
                       && filmProvider.contains("tactical.observation"),
                   "film must use observer-scoped tactical evidence")
            expect(root.contains("case .opponentReportFilmRoom")
                       && root.contains("OpponentReportFilmRoomView("),
                   "film route must be reachable from the shipped root")
            let hq = filmFiles.first { $0.path.hasSuffix("/CoachingHQView.swift") }?.text ?? ""
            expect(hq.contains("if model.opponent != nil") && hq.contains("filmButton.frame"),
                   "film must remain reachable when no mandatory decision is present")
        }

        test("news reaches the shipped root from typed history") {
            let root = swiftFiles(under: "Sources/CoachWorldApp")
                .first { $0.path.hasSuffix("/CoachWorldAppRootView.swift") }?.text ?? ""
            let store = swiftFiles(under: "Sources/CoachWorldApp")
                .first { $0.path.hasSuffix("/CoachWorldStore.swift") }?.text ?? ""
            let provider = swiftFiles(under: "Sources/CoachWorldApp")
                .first { $0.path.hasSuffix("/CoachWorldNewsProvider.swift") }?.text ?? ""
            let view = swiftFiles(under: "Sources/ProFootballCoachUI")
                .first { $0.path.hasSuffix("/NewsView.swift") }?.text ?? ""
            expect(root.contains("case .news") && root.contains("NewsView("),
                   "news must be reachable from the shipped root")
            expect(store.contains("public private(set) var news")
                       && store.contains("CoachWorldReadModelProvider.news"),
                   "news must be rebuilt from the application store seam")
            expect(provider.contains("NewsFeedReadModel.build(from: state)"),
                   "news must derive from typed history")
            expect(view.contains("public struct NewsView")
                       && view.contains("No news recorded"),
                   "news must render a truthful bounded empty state")
        }

        test("durable history families share one production route and projection") {
            let root = swiftFiles(under: "Sources/CoachWorldApp")
                .first { $0.path.hasSuffix("/CoachWorldAppRootView.swift") }?.text ?? ""
            let store = swiftFiles(under: "Sources/CoachWorldApp")
                .first { $0.path.hasSuffix("/CoachWorldStore.swift") }?.text ?? ""
            let provider = swiftFiles(under: "Sources/CoachWorldApp")
                .first { $0.path.hasSuffix("/CoachWorldHistoryProvider.swift") }?.text ?? ""
            let view = swiftFiles(under: "Sources/ProFootballCoachUI")
                .first { $0.path.hasSuffix("/LegacyHistoryView.swift") }?.text ?? ""
            let model = swiftFiles(under: "Sources/ProFootballCoachUI")
                .first { $0.path.hasSuffix("/LegacyHistoryReadModels.swift") }?.text ?? ""
            expect(root.contains("case .recordBook:")
                       && root.contains("RecordBookView(")
                       && root.contains("RivalriesView(")
                       && root.contains("CareerLineView(")
                       && root.contains("CoachingTreeView("),
                   "all durable history families must reach one authoritative projection")
            expect(store.contains("legacyHistory = CoachWorldReadModelProvider.legacyHistory"),
                   "history must rebuild from the application store seam")
            expect(provider.contains("WorldHistoryReadModel.build(from: state)")
                       && provider.contains("CoachingTreeReadModel.build(from: state)"),
                   "history must use authoritative archive and coaching-tree projections")
            expect(model.contains("public struct LegacyHistoryReadModel")
                       && model.contains("prefix(256)"),
                   "history read models must be immutable and bounded")
            expect(view.contains("public struct LegacyHistoryView")
                       && view.contains("Button(\"Record book\")"),
                   "history must expose a native, origin-preserving view selector")
        }

        test("competition leaders and honours use production routes") {
            let root = swiftFiles(under: "Sources/CoachWorldApp")
                .first { $0.path.hasSuffix("/CoachWorldAppRootView.swift") }?.text ?? ""
            let store = swiftFiles(under: "Sources/CoachWorldApp")
                .first { $0.path.hasSuffix("/CoachWorldStore.swift") }?.text ?? ""
            let provider = swiftFiles(under: "Sources/CoachWorldApp")
                .first { $0.path.hasSuffix("/CoachWorldStatisticsProvider.swift") }?.text ?? ""
            let stats = swiftFiles(under: "Sources/ProFootballCoachUI")
                .first { $0.path.hasSuffix("/StatisticsLeadersView.swift") }?.text ?? ""
            let awards = swiftFiles(under: "Sources/ProFootballCoachUI")
                .first { $0.path.hasSuffix("/AwardsHonoursView.swift") }?.text ?? ""
            expect(root.contains("case .statisticsLeaders:") && root.contains("StatisticsLeadersView(")
                       && root.contains("case .awardsHonours:") && root.contains("AwardsHonoursView("),
                   "statistics and awards must reach the shipped root")
            expect(root.contains("RankingsPlayoffPictureView(")
                       && root.contains("BracketPostseasonView("),
                   "rankings and postseason must use named production family entries")
            expect(store.contains("statisticsLeaders = CoachWorldReadModelProvider.statisticsLeaders")
                       && store.contains("awardsHonours = CoachWorldReadModelProvider.awardsHonours"),
                   "competition history must rebuild from the store seam")
            expect(provider.contains("state.competition.playerStatistics")
                       && provider.contains("state.competition.archives"),
                   "leaders and honours must derive from authoritative competition state")
            expect(stats.contains("dynamicTypeSize.isAccessibilitySize")
                       && stats.contains("accessibilitySortPriority"),
                   "statistics must declare accessibility composition and order")
            expect(awards.contains("dynamicTypeSize.isAccessibilitySize")
                       && awards.contains("accessibilitySortPriority"),
                   "awards must declare accessibility composition and order")
        }

        test("realignment is backed by a typed event and shipped route") {
            let root = swiftFiles(under: "Sources/CoachWorldApp")
                .first { $0.path.hasSuffix("/CoachWorldAppRootView.swift") }?.text ?? ""
            let provider = swiftFiles(under: "Sources/CoachWorldApp")
                .first { $0.path.hasSuffix("/CoachWorldRealignmentProvider.swift") }?.text ?? ""
            let view = swiftFiles(under: "Sources/ProFootballCoachUI")
                .first { $0.path.hasSuffix("/RealignmentEventView.swift") }?.text ?? ""
            let engine = swiftFiles(under: "Sources/FootballSimCore/History")
                .first { $0.path.hasSuffix("/DomainEvent.swift") }?.text ?? ""
            expect(root.contains("case .realignmentEvent:") && root.contains("RealignmentEventView("),
                   "realignment must reach the shipped root")
            expect(provider.contains("case let .realignment")
                       && provider.contains("ConferenceRealignmentSwap"),
                   "realignment must read typed before/after swaps")
            expect(engine.contains("case realignment(")
                       && engine.contains("ConferenceRealignmentReason"),
                   "realignment cause must be persisted as a typed domain event")
            expect(view.contains("dynamicTypeSize.isAccessibilitySize")
                       && view.contains("No realignment event recorded."),
                   "realignment must expose accessible and truthful empty states")
        }

        test("game detail reuses immutable aftermath evidence") {
            let root = swiftFiles(under: "Sources/CoachWorldApp")
                .first { $0.path.hasSuffix("/CoachWorldAppRootView.swift") }?.text ?? ""
            let view = swiftFiles(under: "Sources/ProFootballCoachUI")
                .first { $0.path.hasSuffix("/GameDetailBoxScoreView.swift") }?.text ?? ""
            expect(root.contains("case .gameDetailBoxScore:")
                       && root.contains("GameDetailBoxScoreView(")
                       && root.contains("navigate(.gameDetailBoxScore"),
                   "box score must be reachable from the immutable aftermath route")
            expect(view.contains("AftermathReadModel")
                       && view.contains("dynamicTypeSize.isAccessibilitySize")
                       && view.contains("accessibilitySortPriority"),
                   "box score must render the bounded aftermath model with AX5 ordering")
        }

        test("the authoritative-root UI scan catches code but ignores prose") {
            expect(caught("let state: GameState\n", by: referencesAuthoritativeRoot),
                   "a planted GameState property was not caught")
            expect(!caught("// GameState stays in the application service\n",
                           by: referencesAuthoritativeRoot),
                   "a comment about GameState was reported")
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
            // Enumerated by the UI import, not by directory: the rule is about code that draws,
            // and the composition layer added a second target that does.
            let views = swiftFilesImportingUIFramework()
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

        test("the production UI tokens preserve the canonical scales") {
            expectEqual(
                [CoachWorldTokens.Space.xxs, CoachWorldTokens.Space.xs,
                 CoachWorldTokens.Space.sm, CoachWorldTokens.Space.md,
                 CoachWorldTokens.Space.lg, CoachWorldTokens.Space.xl],
                [4, 6, 8, 12, 16, 20],
                "spacing must remain the six-step canonical scale"
            )
            expect(CoachWorldTokens.Shape.minimumTarget >= 44,
                   "interactive targets must remain at least 44 points")
            expect(CoachWorldTokens.TypeRole.authoredFloor >= 12,
                   "authored text must remain at least 12 points")
            expect(CoachWorldTokens.TypeRole.workingProse >= 12
                       && CoachWorldTokens.TypeRole.workingProse <= 13,
                   "standard management prose must remain in the compact 12–13 point band")
        }

        test("the production screen registry is complete and stably numbered") {
            let screens = CoachWorldScreenID.allCases
            expectEqual(screens.map(\.number), Array(1...62),
                        "production screens must remain numbered exactly 1...62")
            expectEqual(Set(screens.map(\.canonicalName)).count, 62,
                        "production screen names must remain unique")
        }

        test("Coaching HQ exposes an injected read-model surface and a truthful app root") {
            let uiFiles = swiftFiles(under: "Sources/ProFootballCoachUI")
            let hq = uiFiles.first { $0.path.hasSuffix("/CoachingHQView.swift") }?.text ?? ""
            let appRoot = swiftFiles(under: "Sources/CoachWorldApp")
                .first { $0.path.hasSuffix("/CoachWorldAppRootView.swift") }?.text ?? ""
            let recruiting = uiFiles.first {
                $0.path.hasSuffix("/RecruitingBoardView.swift")
            }?.text ?? ""
            let roster = uiFiles.first { $0.path.hasSuffix("/RosterView.swift") }?.text ?? ""
            let profile = uiFiles.first {
                $0.path.hasSuffix("/PlayerProfileView.swift")
            }?.text ?? ""
            let deskComponents = uiFiles.first {
                $0.path.hasSuffix("/CoachWorldDeskComponents.swift")
            }?.text ?? ""
            let root = uiFiles.first { $0.path.hasSuffix("/RootView.swift") }?.text ?? ""

            expect(hq.contains("public struct CoachingHQView"),
                   "CoachingHQView.swift must expose the production HQ screen")
            expect(hq.contains("let model: CoachingHQReadModel"),
                   "Coaching HQ must consume an immutable read model")
            expect(hq.contains("Button("), "Coaching HQ must use native buttons")
            expect(!hq.contains("onTapGesture"),
                   "Coaching HQ must not replace semantic controls with tap gestures")
            expect(hq.contains("@State private"),
                   "screen-owned draft state must remain private")
            expect(hq.contains("accessibilitySortPriority"),
                   "Coaching HQ must declare deterministic VoiceOver order")

            expect(recruiting.contains("public struct RecruitingBoardView"),
                   "RecruitingBoardView.swift must expose the production board")
            expect(recruiting.contains("let model: RecruitingBoardReadModel"),
                   "Recruiting Board must consume an immutable read model")
            expect(recruiting.contains("Button("),
                   "Recruiting Board must use native buttons")
            expect(!recruiting.contains("onTapGesture"),
                   "Recruiting Board must not replace semantic controls with tap gestures")
            expect(recruiting.contains("accessibilitySortPriority"),
                   "Recruiting Board must declare deterministic VoiceOver order")
            expect(recruiting.contains("choice.cost") && recruiting.contains("choice.consequence"),
                   "recruiting actions must expose both cost and consequence")
            let prospectProfile = uiFiles.first {
                $0.path.hasSuffix("/ProspectProfileView.swift")
            }?.text ?? ""
            let shortlist = uiFiles.first {
                $0.path.hasSuffix("/ShortlistView.swift")
            }?.text ?? ""
            expect(prospectProfile.contains("public struct ProspectProfileView")
                       && prospectProfile.contains("RecruitingBoardReadModel")
                       && prospectProfile.contains("onAction")
                       && prospectProfile.contains("dynamicTypeSize.isAccessibilitySize"),
                   "Prospect Profile must reuse the authoritative recruiting dossier and actions")
            expect(shortlist.contains("public struct ShortlistView")
                       && shortlist.contains("RecruitingBoardReadModel")
                       && shortlist.contains("onOpenProspect")
                       && shortlist.contains("dynamicTypeSize.isAccessibilitySize"),
                   "Shortlist must reuse the bounded recruiting board projection")
            expect(appRoot.contains("case .prospectProfile")
                       && appRoot.contains("ProspectProfileView(")
                       && appRoot.contains("case .shortlist")
                       && appRoot.contains("ShortlistView("),
                   "Prospect Profile and Shortlist must be reachable from the shipped app root")

            expect(roster.contains("public struct RosterView"),
                   "RosterView.swift must expose the production roster screen")
            expect(roster.contains("let model: RosterReadModel"))
            expect(roster.contains("Button("))
            expect(!roster.contains("onTapGesture"))
            expect(roster.contains("monospacedDigit"))
            expect(roster.contains("accessibilitySortPriority"))
            expect(roster.contains("dynamicTypeSize.isAccessibilitySize"))
            expect(roster.contains("CoachWorldRouteButton"))
            expect(roster.contains("CoachWorldActionButtonStyle"))
            expect(roster.contains("accessibleRating(\"OVR\", player.overall)"),
                   "accessibility rows must preserve a distinct overall rating")
            expect(roster.contains("accessibleDevelopmentDelta(player.developmentDelta)"),
                   "accessibility rows must preserve a distinct development change")
            expect(roster.contains("accessibleRating(\"COND\", player.condition)"),
                   "accessibility rows must preserve a distinct condition rating")
            expect(roster.contains(".sheet(item: $presentedProfile)"),
                   "the dossier must preserve roster selection and sort state")
            expect(roster.contains("lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)"),
                   "the summary ribbon must wrap rather than truncate at accessibility sizes")

            expect(profile.contains("public struct PlayerProfileView"))
            expect(profile.contains("let model: PlayerProfileReadModel"))
            expect(profile.contains("Button("))
            expect(!profile.contains("onTapGesture"))
            expect(profile.contains("monospacedDigit"))
            expect(profile.contains("accessibilitySortPriority"))
            expect(profile.contains("dynamicTypeSize.isAccessibilitySize"))
            expect(profile.contains("CoachWorldBlankPhotoPlate"))
            expect(profile.contains("model.attributeGroups"))
            expect(profile.contains("private var routeBar"),
                   "player profile must expose its route selector in production source")
            expect(!profile.contains(".disabled(route != .overview)"),
                   "player profile routes must not remain placeholder-disabled")
            expect(profile.contains("No recent form recorded."),
                   "player profile must expose a truthful empty form state")

            expect(deskComponents.contains("struct CoachWorldActionButtonStyle")
                       && deskComponents.contains("struct CoachWorldRouteButton")
                       && deskComponents.contains("coachWorldDeskSurface"),
                   "management screens must share the proven action, route and desk-surface elements")
            expect(hq.contains("CoachWorldActionButtonStyle")
                       && hq.contains("CoachWorldRouteButton")
                       && recruiting.contains("CoachWorldActionButtonStyle")
                       && recruiting.contains("CoachWorldRouteButton"),
                   "HQ and Recruiting must consume the same management-screen controls")
            expect(!hq.contains("HQActionButtonStyle")
                       && !recruiting.contains("RecruitingActionButtonStyle"),
                   "screen-local copies of shared controls must not return")

            expect(root.contains("public struct RootView"),
                   "the application shell imports a public RootView")
            expect(root.contains("#if DEBUG")
                       && root.contains("CoachWorldSampleData.coachingHQ")
                       && root.contains("CoachWorldSampleData.recruitingBoard"),
                   "sample career values must be debug-only")
            expect(root.contains("No career loaded"),
                   "release builds need a truthful no-career state")
            expect(root.contains("CoachWorldSampleData.roster"),
                   "the personnel proof entry must use the fixed sample roster")
            expect(root.contains("--roster") && root.contains("PROOF_SCREEN")
                       && root.contains("\"roster\""),
                   "Roster needs both a launch argument and a proof-screen name")
            expect(root.contains("--player-profile") && root.contains("\"player\""),
                   "Player Profile needs both a launch argument and a proof-screen name")
            expect(root.contains("RosterView(") && root.contains("PlayerProfileView("),
                   "the debug root must reach both personnel screens")

            expect(roster.contains("CoachWorldTeamIdentity(") && roster.contains("uniformMark"),
                   "the world strip must carry generated programme identity, not neutral furniture")
            expect(roster.contains("selectionColour"),
                   "selection speaks in programme colour where it is legible")
            expect(profile.contains("let team: CoachWorldTeamReference"),
                   "the dossier must know whose uniform the player wears")

            let health = uiFiles.first { $0.path.hasSuffix("/TeamHealthView.swift") }?.text ?? ""
            let healthModel = uiFiles.first {
                $0.path.hasSuffix("/TeamHealthReadModels.swift")
            }?.text ?? ""
            expect(health.contains("public struct TeamHealthView"),
                   "Team Health must expose a production view")
            expect(health.contains("let model: TeamHealthReadModel"),
                   "Team Health must consume an immutable read model")
            expect(health.contains("dynamicTypeSize.isAccessibilitySize")
                       && health.contains("accessibilityLabel"),
                   "Team Health must preserve accessibility-size and semantic evidence")
            expect(healthModel.contains("public struct TeamHealthReadModel"),
                   "Team Health read model is missing")
            expect(appRoot.contains("case .teamHealth") && appRoot.contains("TeamHealthView("),
                   "Team Health must be reachable from the shipped app root")
            expect(hq.contains("Button(\"Team health\")") && roster.contains("screen != .teamHealth"),
                   "Team Health must be reachable from HQ and the roster without a disabled route")
            expect(hq.contains("route(\"Health\", screen: .teamHealth)"),
                   "standard HQ must expose Team Health, not only its accessibility menu")

            let proOffseason = uiFiles.first {
                $0.path.hasSuffix("/ProOffseasonView.swift")
            }?.text ?? ""
            let proOffseasonModel = uiFiles.first {
                $0.path.hasSuffix("/ProOffseasonReadModels.swift")
            }?.text ?? ""
            let appStore = swiftFiles(under: "Sources/CoachWorldApp")
                .first { $0.path.hasSuffix("/CoachWorldStore.swift") }?.text ?? ""
            expect(proOffseason.contains("public struct ProOffseasonView")
                       && proOffseason.contains("dynamicTypeSize.isAccessibilitySize"),
                   "Pro Offseason must expose a production accessibility-aware view")
            expect(proOffseasonModel.contains("public struct ProOffseasonReadModel")
                       && proOffseasonModel.contains("ProMarketAction"),
                   "Pro Offseason must project existing market actions")
            expect(appRoot.contains("case .proOffseason")
                       && appRoot.contains("ProOffseasonView("),
                   "Pro Offseason must be reachable from the shipped app root")
            expect(hq.contains("proOffseason") && appStore.contains("actOnProMarket"),
                   "professional offseason must be reachable only through the market seam")
            for family in [
                ("DraftBoardView.swift", "DraftBoardView", "draftBoard"),
                ("DraftRoomView.swift", "DraftRoomView", "draftRoom"),
                ("FreeAgencyView.swift", "FreeAgencyView", "freeAgency"),
                ("ProScoutingBoardView.swift", "ProScoutingBoardView", "proScoutingBoard")
            ] {
                let view = uiFiles.first { $0.path.hasSuffix("/\(family.0)") }?.text ?? ""
                expect(view.contains("public struct \(family.1)")
                           && view.contains("ProOffseasonView(")
                           && view.contains("dynamicTypeSize.isAccessibilitySize"),
                       "\(family.1) must reuse the authoritative pro market surface")
                expect(appRoot.contains("case .\(family.2)")
                           && appRoot.contains("\(family.1)("),
                       "\(family.1) must be reachable from the shipped app root")
                expect(hq.contains("\(family.2)"),
                       "\(family.1) must be reachable from the HQ route surface")
            }
            for family in [
                ("JobBoardView.swift", "JobBoardView", "jobBoard"),
                ("OfferView.swift", "OfferView", "offer"),
                ("AppointmentView.swift", "AppointmentView", "appointment")
            ] {
                let view = uiFiles.first { $0.path.hasSuffix("/\(family.0)") }?.text ?? ""
                expect(view.contains("public struct \(family.1)")
                           && view.contains("CareerHubView(")
                           && view.contains("dynamicTypeSize.isAccessibilitySize"),
                       "\(family.1) must reuse the authoritative career ledger")
                expect(appRoot.contains("case .\(family.2)")
                           && appRoot.contains("\(family.1)("),
                       "\(family.1) must be reachable from the shipped app root")
                expect(hq.contains("\(family.2)") && hq.contains("showsCareer"),
                       "\(family.1) must be reachable only for a controlled career")
            }
            for family in [
                ("ClassOverviewView.swift", "ClassOverviewView", "classOverview"),
                ("ContactVisitPlannerView.swift", "ContactVisitPlannerView", "contactVisitPlanner")
            ] {
                let view = uiFiles.first { $0.path.hasSuffix("/\(family.0)") }?.text ?? ""
                expect(view.contains("public struct \(family.1)")
                           && view.contains("RecruitingBoardReadModel")
                           && view.contains("dynamicTypeSize.isAccessibilitySize"),
                       "\(family.1) must consume the authoritative recruiting read model")
                expect(appRoot.contains("case .\(family.2)")
                           && appRoot.contains("\(family.1)("),
                       "\(family.1) must be reachable from the shipped app root")
                expect(hq.contains("\(family.2)") && hq.contains("showsRecruitingBoard"),
                       "\(family.1) must be reachable only for a controlled recruiting career")
            }

            let proManagement = uiFiles.first {
                $0.path.hasSuffix("/ProManagementView.swift")
            }?.text ?? ""
            let proManagementModel = uiFiles.first {
                $0.path.hasSuffix("/ProManagementReadModels.swift")
            }?.text ?? ""
            let proManagementProvider = swiftFiles(under: "Sources/CoachWorldApp")
                .first { $0.path.hasSuffix("/CoachWorldProManagementProvider.swift") }?.text ?? ""
            expect(proManagement.contains("public struct ProManagementView")
                       && proManagement.contains("dynamicTypeSize.isAccessibilitySize"),
                   "Cap and roster management must expose an accessibility-aware production view")
            expect(proManagementModel.contains("public struct ProManagementReadModel")
                       && proManagementModel.contains("ProManagementAction"),
                   "Cap and roster management must project existing transaction actions")
            expect(proManagementProvider.contains("static func proManagement(")
                       && proManagementProvider.contains("ProManagementSystem.capSnapshot"),
                   "Cap and roster management must derive from the authoritative pro engine")
            expect(appRoot.contains("case .capContracts")
                       && appRoot.contains("rosterCutsTransactions")
                       && appRoot.contains("CapContractsView(")
                       && appRoot.contains("RosterCutsTransactionsView("),
                   "Cap and roster management must be reachable from the shipped app root")
            expect(hq.contains("showsProManagement")
                       && hq.contains("capContracts")
                       && hq.contains("rosterCutsTransactions"),
                   "Cap and roster management must be reachable from the HQ route surface")

            let staffRoom = uiFiles.first {
                $0.path.hasSuffix("/StaffRoomView.swift")
            }?.text ?? ""
            let staffRoomModel = uiFiles.first {
                $0.path.hasSuffix("/StaffRoomReadModels.swift")
            }?.text ?? ""
            let staffRoomProvider = swiftFiles(under: "Sources/CoachWorldApp")
                .first { $0.path.hasSuffix("/CoachWorldStaffRoomProvider.swift") }?.text ?? ""
            expect(staffRoom.contains("public struct StaffRoomView")
                       && staffRoom.contains("dynamicTypeSize.isAccessibilitySize"),
                   "Staff Room must expose an accessibility-aware production view")
            expect(staffRoomModel.contains("public struct StaffRoomReadModel")
                       && staffRoomModel.contains("StaffRow"),
                   "Staff Room must project a bounded staff ledger")
            expect(staffRoomProvider.contains("static func staffRoom(")
                       && staffRoomProvider.contains("state.staff"),
                   "Staff Room must derive from authoritative staff records")
            expect(appRoot.contains("case .staffRoom")
                       && appRoot.contains("staffMarketProfile")
                       && appRoot.contains("StaffRoomView("),
                   "Staff Room and Staff Market & Profile must be reachable from the shipped app root")
            expect(hq.contains("staffRoom") && hq.contains("Staff market & profile"),
                   "Staff Room routes must be reachable from HQ")
            for family in [
                ("StaffMarketProfileView.swift", "StaffMarketProfileView", "staffMarketProfile"),
                ("CapContractsView.swift", "CapContractsView", "capContracts"),
                ("ContractNegotiationView.swift", "ContractNegotiationView", "contractNegotiation"),
                ("RosterCutsTransactionsView.swift", "RosterCutsTransactionsView", "rosterCutsTransactions")
            ] {
                let view = uiFiles.first { $0.path.hasSuffix("/\(family.0)") }?.text ?? ""
                expect(view.contains("public struct \(family.1)")
                           && view.contains("dynamicTypeSize.isAccessibilitySize"),
                       "\(family.1) must be a production accessibility-aware family view")
                expect(appRoot.contains("case .\(family.2)")
                           && appRoot.contains("\(family.1)("),
                       "\(family.1) must be routed by the shipped app root")
            }

            let negotiationCore = swiftFiles(under: "Sources/FootballSimCore")
                .first { $0.path.hasSuffix("/ProContractNegotiation.swift") }?.text ?? ""
            expect(negotiationCore.contains("public struct ProContractNegotiation")
                       && negotiationCore.contains("maximumOfferHistory"),
                   "Contract Negotiation must use a bounded persisted negotiation ledger")
            expect(appRoot.contains("ContractNegotiationView(")
                       && appRoot.contains("case .contractNegotiation"),
                   "Contract Negotiation must be reachable from the shipped app root")
            expect(hq.contains("showsContractNegotiation")
                       && hq.contains("contractNegotiation"),
                   "Contract Negotiation must be reachable from professional HQ")

            let schemeBook = uiFiles.first {
                $0.path.hasSuffix("/SchemeBookView.swift")
            }?.text ?? ""
            let packages = uiFiles.first {
                $0.path.hasSuffix("/PersonnelPackagesView.swift")
            }?.text ?? ""
            expect(schemeBook.contains("public struct SchemeBookView")
                       && schemeBook.contains("GamePlanView(")
                       && schemeBook.contains("dynamicTypeSize.isAccessibilitySize"),
                   "Scheme Book must reuse the authoritative game-plan surface")
            expect(packages.contains("public struct PersonnelPackagesView")
                       && packages.contains("DepthChartView(")
                       && packages.contains("dynamicTypeSize.isAccessibilitySize"),
                   "Personnel Packages must reuse the authoritative personnel surface")
            expect(appRoot.contains("case .schemeBook")
                       && appRoot.contains("case .personnelPackages")
                       && appRoot.contains("SchemeBookView(")
                       && appRoot.contains("PersonnelPackagesView("),
                   "Scheme Book and Personnel Packages must be reachable from the shipped app root")
            expect(hq.contains("schemeBook") && hq.contains("personnelPackages"),
                   "Scheme Book and Personnel Packages must be reachable from HQ")

            let collegeOffseason = uiFiles.first {
                $0.path.hasSuffix("/CollegeOffseasonView.swift")
            }?.text ?? ""
            let collegeOffseasonModel = uiFiles.first {
                $0.path.hasSuffix("/CollegeOffseasonReadModels.swift")
            }?.text ?? ""
            let collegeOffseasonProvider = swiftFiles(under: "Sources/CoachWorldApp")
                .first { $0.path.hasSuffix("/CoachWorldCollegeOffseasonProvider.swift") }?.text ?? ""
            expect(collegeOffseason.contains("public struct CollegeOffseasonView")
                       && collegeOffseason.contains("dynamicTypeSize.isAccessibilitySize"),
                   "College Offseason must expose a production accessibility-aware view")
            expect(collegeOffseasonModel.contains("public struct CollegeOffseasonReadModel")
                       && collegeOffseasonModel.contains("CoachingHQReadModel.Decision"),
                   "College Offseason must project existing mandatory decisions")
            expect(collegeOffseasonProvider.contains("static func collegeOffseason(")
                       && collegeOffseasonProvider.contains("from state: GameState"),
                   "College Offseason must be derived from authoritative college state")
            expect(appRoot.contains("case .collegeOffseason")
                       && appRoot.contains("CollegeOffseasonView("),
                   "College Offseason must be reachable from the shipped app root")
            expect(hq.contains("showsCollegeOffseason")
                       && hq.contains("collegeOffseason"),
                   "College Offseason must be reachable from the HQ route surface")
            for family in [
                ("PortalHubView.swift", "PortalHubView", "portalHub"),
                ("RetentionDecisionsView.swift", "RetentionDecisionsView", "retentionDecisions"),
                ("PortalMarketView.swift", "PortalMarketView", "portalMarket"),
                ("NilAllocationView.swift", "NilAllocationView", "nilAllocation"),
                ("SigningDayView.swift", "SigningDayView", "signingDay")
            ] {
                let view = uiFiles.first { $0.path.hasSuffix("/\(family.0)") }?.text ?? ""
                expect(view.contains("public struct \(family.1)")
                           && view.contains("CollegeOffseasonView(")
                           && view.contains("dynamicTypeSize.isAccessibilitySize"),
                       "\(family.1) must reuse the authoritative college offseason surface")
                expect(appRoot.contains("case .\(family.2)")
                           && appRoot.contains("\(family.1)("),
                       "\(family.1) must be reachable from the shipped app root")
                expect(hq.contains("\(family.2)"),
                       "\(family.1) must be reachable from HQ")
            }
            let development = uiFiles.first {
                $0.path.hasSuffix("/DevelopmentPlanView.swift")
            }?.text ?? ""
            expect(development.contains("public struct DevelopmentPlanView")
                       && development.contains("RosterReadModel")
                       && development.contains("dynamicTypeSize.isAccessibilitySize"),
                   "Development Plan must project recorded roster evidence")
            expect(appRoot.contains("case .developmentPlan")
                       && appRoot.contains("DevelopmentPlanView("),
                   "Development Plan must be reachable from the shipped app root")
            let settings = uiFiles.first {
                $0.path.hasSuffix("/SettingsAccessibilityView.swift")
            }?.text ?? ""
            expect(settings.contains("public struct SettingsAccessibilityView")
                       && settings.contains("dynamicTypeSize.isAccessibilitySize"),
                   "Settings & Accessibility must expose its explicit beta product contract")
            expect(appRoot.contains("screen == .settingsAccessibility")
                       && appRoot.contains("SettingsAccessibilityView("),
                   "Settings & Accessibility must be reachable from the title surface")

            let inbox = uiFiles.first { $0.path.hasSuffix("/InboxView.swift") }?.text ?? ""
            let inboxModel = uiFiles.first { $0.path.hasSuffix("/InboxReadModels.swift") }?.text ?? ""
            let inboxProvider = swiftFiles(under: "Sources/CoachWorldApp")
                .first { $0.path.hasSuffix("/CoachWorldInboxProvider.swift") }?.text ?? ""
            expect(inbox.contains("public struct InboxView")
                       && inbox.contains("dynamicTypeSize.isAccessibilitySize")
                       && inbox.contains("minimumTarget"),
                   "Inbox must be a production, accessibility-sized surface")
            expect(inboxModel.contains("public struct InboxReadModel"),
                   "Inbox must consume a bounded immutable read model")
            expect(inboxProvider.contains("static func inbox(")
                       && inboxProvider.contains("from state: GameState")
                       && inboxProvider.contains("NewsFeedReadModel.build"),
                   "Inbox must be derived from authoritative decisions and typed history")
            expect(appRoot.contains("case .inbox") && appRoot.contains("InboxView("),
                   "Inbox must be reachable from the shipped app root")
            expect(appRoot.contains("inboxOrigin")
                       && appRoot.contains("markInboxItemRead")
                       && appRoot.contains("persistOrReport(store)"),
                   "Inbox read receipts and origin must survive the app boundary")
            expect(hq.contains("route(\"Inbox\", screen: .inbox)")
                       && roster.contains("route(\"Inbox\", screen: .inbox)"),
                   "Inbox must have two production navigation origins")
        }

        test("League Map is a read-model surface that invents no place and no reach") {
            let map = swiftFiles(under: "Sources/ProFootballCoachUI")
                .first { $0.path.hasSuffix("/LeagueMapView.swift") }?.text ?? ""
            expect(map.contains("public struct LeagueMapView"),
                   "LeagueMapView.swift must expose the production map screen")
            expect(map.contains("let model: LeagueMapReadModel"),
                   "League Map must consume an immutable read model")
            expect(map.contains("Button("), "League Map must use native buttons")
            expect(!map.contains("onTapGesture"),
                   "a place is selected with a Button, so it is focusable and has a spoken label")
            expect(map.contains("monospacedDigit"))
            expect(map.contains("accessibilitySortPriority"))
            expect(map.contains("dynamicTypeSize.isAccessibilitySize"))
            expect(map.contains("CoachWorldRouteButton")
                       && map.contains("CoachWorldActionButtonStyle"),
                   "world routes and Continue use the shared controls, not screen-local copies")

            let provider = swiftFiles(under: "Sources/CoachWorldApp")
                .first { $0.path.hasSuffix("/CoachWorldLeagueMapProvider.swift") }?.text ?? ""
            expect(!provider.isEmpty, "CoachWorldLeagueMapProvider.swift not found")
            // The join that matters. `cityName` is a display string, and `GameMap` keeps a
            // with-replacement fallback for a smaller name pool; if it fired, a name join would
            // collapse two cities and draw a programme where it does not play.
            expect(provider.contains("homeCityID"),
                   "the provider must join a member to its city by identifier, never by name")
            // No engine system reads `recruitingReach`, so no radius may be drawn from it.
            expect(!provider.contains("recruitingReach") && !map.contains("recruitingReach"),
                   "a reach radius would invent a grid-unit mapping the engine does not have")
            expect(provider.contains("RivalrySeeder.strongest"),
                   "rival order is the engine's own, not a second definition that can drift")
        }

        // `04` section 5 names `CoachWorldTeamIdentity` the sole resolution point for generated
        // colour and calls the rule source-scannable. Nothing scanned it until League Map landed,
        // and a view reading a hex directly is exactly how the legibility gates get bypassed —
        // the gates are inside that initialiser.
        test("no view resolves a generated colour except through the identity type") {
            for file in swiftFilesImportingUIFramework() {
                let isResolutionPoint = file.path.hasSuffix("/TeamIdentity.swift")
                guard !isResolutionPoint else { continue }
                let code = codeLines(of: file.text)
                for property in ["primaryColorHex", "secondaryColorHex"] {
                    expect(!code.contains(where: { $0.contains(property) }),
                           "\(file.path) reads \(property) directly. Generated colour resolves "
                               + "through CoachWorldTeamIdentity, which is where the contrast "
                               + "floors live and where a pair that cannot be read is refused "
                               + "(04 section 5).")
                }
            }
        }

#if DEBUG
        test("generated team colour resolves to legible ink or refuses to paint") {
            let dark = CoachWorldTokens.dark
            let inks = [dark.contentPrimary, dark.page]

            for team in [CoachWorldSampleData.homeTeam, CoachWorldSampleData.awayTeam] {
                guard let identity = CoachWorldTeamIdentity(
                    team: team, behind: dark.raised, inks: inks
                ) else {
                    expect(false, "\(team.name) carries a colour pair and must resolve")
                    continue
                }
                expect(identity.field.contrast(against: identity.onField)
                           >= CoachWorldTeamIdentity.bodyTextFloor,
                       "\(team.name) ink measures below the body floor on its own field")
                guard let rule = identity.selectionRule(on: dark.work) else {
                    expect(false, "\(team.name) must offer a visible selection rule")
                    continue
                }
                expect(rule.contrast(against: dark.work) >= CoachWorldTeamIdentity.nonTextFloor,
                       "\(team.name) selection rule measures below the non-text floor")
            }

            // A field too close to the surface behind it is spoken by a boundary, never left to
            // colour alone. Both reference primaries are dark, so this fires in dark appearance.
            let home = CoachWorldTeamIdentity(
                team: CoachWorldSampleData.homeTeam, behind: dark.raised, inks: inks
            )
            expectEqual(home?.needsBoundary, true,
                        "a dark generated field on a dark strip must carry a boundary")

            let malformed = CoachWorldTeamReference(
                stableID: "malformed", name: "Malformed", abbreviation: "MAL",
                primaryColorHex: "not-a-colour", secondaryColorHex: "#D9B23C"
            )
            expect(CoachWorldTeamIdentity(team: malformed, behind: dark.raised, inks: inks) == nil,
                   "a malformed pair falls back to neutral furniture rather than guessing")

            let illegible = CoachWorldTeamReference(
                stableID: "illegible", name: "Illegible", abbreviation: "ILL",
                primaryColorHex: "#767676", secondaryColorHex: "#D9DDE4"
            )
            expect(CoachWorldTeamIdentity(team: illegible, behind: dark.raised, inks: inks) == nil,
                   "a field no palette ink can reach 4.5:1 on must refuse to paint")
        }

        test("personnel projections keep stable identities and deterministic sorting") {
            let roster = CoachWorldSampleData.roster
            expectEqual(roster.provenance, .sample)
            expectEqual(Set(roster.players.map(\.stableID)).count, roster.players.count)
            expectEqual(Set(roster.players.map(\.profile.stableID)).count, roster.players.count,
                        "callbacks carry the profile identity, so it must resolve one player")
            expect(roster.players.allSatisfy { $0.person.photo == nil })
            expect(roster.players.allSatisfy { player in
                player.overall >= 0 && player.overall <= 99
                    && player.development >= 0 && player.development <= 99
                    && player.condition >= 0 && player.condition <= 100
            })
            expect(roster.players.allSatisfy { player in
                player.profile.attributeGroups.count == 3
                    && player.profile.attributeGroups.flatMap(\.attributes).allSatisfy {
                        $0.value >= 0 && $0.value <= 99
                    }
            })

            let descending = RosterSortDescriptor(field: .overall, isAscending: false)
                .sorted(roster.players)
            expectEqual(descending.map(\.overall), descending.map(\.overall).sorted(by: >))

            let ascending = RosterSortDescriptor(field: .name, isAscending: true)
                .sorted(roster.players)
            expectEqual(ascending.map { $0.person.name }, ascending.map { $0.person.name }.sorted())
        }

        test("sample read models stay labelled and enforce the recorded-match shape") {
            let headquarters = CoachWorldSampleData.coachingHQ
            expectEqual(headquarters.weekPlan.count, 7,
                        "the Coaching HQ week plan must come from seven read-model days")
            expectEqual(headquarters.weekPlan.filter(\.isCurrent).count, 1,
                        "the Coaching HQ week plan must own one current day")
            expect(headquarters.unallocatedPracticeMinutes >= 0,
                   "the Coaching HQ time bank must be owned by a nonnegative read-model value")
            expect(headquarters.coach.photo == nil,
                   "the base career uses the canonical blank coach photo state")

            let recruiting = CoachWorldSampleData.recruitingBoard
            expectEqual(recruiting.provenance, .sample,
                        "preview recruiting data must identify itself as sample data")
            expectEqual(recruiting.prospects.count, 5,
                        "the proof board needs enough rows to test comparison hierarchy")
            expectEqual(Set(recruiting.prospects.map(\.stableID)).count,
                        recruiting.prospects.count,
                        "recruiting prospect identifiers must be unique")
            expectEqual(Set(recruiting.prospects.map(\.boardRank)).count,
                        recruiting.prospects.count,
                        "recruiting board ranks must be unique")
            expect(recruiting.prospects.allSatisfy { $0.person.photo == nil },
                        "personnel samples use the canonical blank photo state")
            expect(recruiting.prospects.allSatisfy { prospect in
                prospect.choices.allSatisfy { choice in
                    !choice.cost.isEmpty && !choice.consequence.isEmpty
                }
            }, "every recruiting choice must name its cost and consequence")
            // Imported media stays absent: `04` section 5.1 reserves mark and uniform assets for a
            // future custom universe. Colour is not in that class — the base game generates a pair
            // under the trade-dress gate, and section 5 lets it own the world strip, which is why
            // section 6.1 states contrast floors for generated colour at all.
            expect(CoachWorldSampleData.homeTeam.secondaryMarkAsset == nil
                       && CoachWorldSampleData.homeTeam.uniformAsset == nil
                       && CoachWorldSampleData.homeTeam.mark == nil,
                   "future custom-universe team media must remain absent")
            expect(CoachWorldSampleData.homeTeam.primaryColorHex != nil
                       && CoachWorldSampleData.homeTeam.secondaryColorHex != nil,
                   "a programme fixture carries the generated colour pair the frame paints")

            let sample = CoachWorldSampleData.matchDay
            expectEqual(sample.provenance, .sample,
                        "preview match data must identify itself as sample data")
            expectEqual(sample.actors.count, 22, "a Match Day frame must contain all 22 actors")
            expect(sample.foregroundActorIDs.count <= 3,
                   "a Match Day frame may foreground at most three actors")
            expectEqual(Set(sample.controls.map(\.id)), Set(MatchDayControlID.allCases),
                        "Match Day exposes exactly the five canonical controls")
            if let interruption = sample.staffInterruption {
                expect(!interruption.evidence.isEmpty,
                       "a staff interruption must cite inspectable evidence")
                expectEqual(
                    Set(interruption.actions.map(\.path)),
                    Set(MatchDayReadModel.StaffInterruption.Path.allCases),
                    "a staff interruption must expose accept, dismiss and inspect-evidence paths"
                )
                expect(interruption.actions.allSatisfy { action in
                    !action.cost.isEmpty && !action.consequence.isEmpty
                }, "every staff interruption path must expose cost and consequence")
                do {
                    _ = try MatchDayReadModel.StaffInterruption(
                        stableID: interruption.stableID,
                        staff: interruption.staff,
                        message: interruption.message,
                        evidence: interruption.evidence,
                        actions: Array(interruption.actions.dropLast())
                    )
                    expect(false, "an interruption without inspect-evidence was accepted")
                } catch let error as MatchDayReadModel.StaffInterruption.ValidationError {
                    expectEqual(error, .missingPath(.inspectEvidence),
                                "the wrong missing-path error was returned")
                } catch {
                    expect(false, "an unexpected interruption error was returned: \(error)")
                }
                do {
                    _ = try MatchDayReadModel.StaffInterruption(
                        stableID: interruption.stableID,
                        staff: interruption.staff,
                        message: interruption.message,
                        evidence: ["   "],
                        actions: interruption.actions
                    )
                    expect(false, "an interruption with blank evidence was accepted")
                } catch let error as MatchDayReadModel.StaffInterruption.ValidationError {
                    expectEqual(error, .evidenceRequired,
                                "the wrong blank-evidence error was returned")
                } catch {
                    expect(false, "an unexpected blank-evidence error was returned: \(error)")
                }
                do {
                    let actions = interruption.actions.map { action in
                        action.path == .accept
                            ? .init(
                                path: action.path,
                                intentID: action.intentID,
                                title: action.title,
                                cost: " ",
                                consequence: action.consequence,
                                isEnabled: action.isEnabled
                            )
                            : action
                    }
                    _ = try MatchDayReadModel.StaffInterruption(
                        stableID: interruption.stableID,
                        staff: interruption.staff,
                        message: interruption.message,
                        evidence: interruption.evidence,
                        actions: actions
                    )
                    expect(false, "an interruption with a blank accept cost was accepted")
                } catch let error as MatchDayReadModel.StaffInterruption.ValidationError {
                    expectEqual(error, .costRequired(.accept),
                                "the wrong blank-cost error was returned")
                } catch {
                    expect(false, "an unexpected blank-cost error was returned: \(error)")
                }
                do {
                    let repeatedIntent = interruption.actions[0].intentID
                    let actions = interruption.actions.map { action in
                        MatchDayReadModel.StaffInterruption.Action(
                            path: action.path,
                            intentID: repeatedIntent,
                            title: action.title,
                            cost: action.cost,
                            consequence: action.consequence,
                            isEnabled: action.isEnabled
                        )
                    }
                    _ = try MatchDayReadModel.StaffInterruption(
                        stableID: interruption.stableID,
                        staff: interruption.staff,
                        message: interruption.message,
                        evidence: interruption.evidence,
                        actions: actions
                    )
                    expect(false, "an interruption with duplicate intent IDs was accepted")
                } catch let error as MatchDayReadModel.StaffInterruption.ValidationError {
                    expectEqual(error, .duplicateIntentID,
                                "the wrong duplicate-intent error was returned")
                } catch {
                    expect(false, "an unexpected duplicate-intent error was returned: \(error)")
                }
            } else {
                expect(false, "the sample Match Day frame must contain a staff interruption")
            }

            func rebuilding(
                actors: [MatchDayReadModel.Actor],
                foregroundActorIDs: [String],
                situation: MatchDayReadModel.Situation? = nil,
                offenseDirection: MatchFieldDirection? = nil,
                causalCommentary: String? = nil,
                controls: [MatchDayReadModel.ControlState]? = nil
            ) throws -> MatchDayReadModel {
                try MatchDayReadModel(
                    recordedOutcomeID: sample.recordedOutcomeID,
                    provenance: sample.provenance,
                    world: sample.world,
                    venue: sample.venue,
                    home: sample.home,
                    away: sample.away,
                    situation: situation ?? sample.situation,
                    offenseDirection: offenseDirection ?? sample.offenseDirection,
                    actors: actors,
                    lineOfScrimmage: sample.lineOfScrimmage,
                    firstDownLine: sample.firstDownLine,
                    foregroundActorIDs: foregroundActorIDs,
                    causalCommentary: causalCommentary ?? sample.causalCommentary,
                    staffInterruption: sample.staffInterruption,
                    controls: controls ?? sample.controls
                )
            }

            do {
                _ = try rebuilding(
                    actors: Array(sample.actors.dropLast()),
                    foregroundActorIDs: sample.foregroundActorIDs
                )
                expect(false, "a 21-actor recorded frame was accepted")
            } catch let error as MatchDayReadModel.ValidationError {
                expectEqual(error, .actorCount(21), "the wrong 21-actor error was returned")
            } catch {
                expect(false, "an unexpected 21-actor error was returned: \(error)")
            }

            do {
                var actors = sample.actors
                let actor = actors[0]
                actors[0] = MatchDayReadModel.Actor(
                    stableID: actor.stableID,
                    side: actor.side,
                    uniformNumber: actor.uniformNumber,
                    position: actor.position,
                    xYardsFromLeftGoalLine: actor.xYardsFromLeftGoalLine,
                    yFraction: .nan
                )
                _ = try rebuilding(
                    actors: actors,
                    foregroundActorIDs: sample.foregroundActorIDs
                )
                expect(false, "a non-finite actor position was accepted")
            } catch let error as MatchDayReadModel.ValidationError {
                expectEqual(error, .invalidFieldPosition(sample.actors[0].stableID),
                            "the wrong non-finite-position error was returned")
            } catch {
                expect(false, "an unexpected non-finite-position error was returned: \(error)")
            }

            do {
                _ = try rebuilding(
                    actors: sample.actors,
                    foregroundActorIDs: sample.actors.prefix(4).map(\.stableID)
                )
                expect(false, "a four-actor foreground was accepted")
            } catch let error as MatchDayReadModel.ValidationError {
                expectEqual(error, .foregroundCount(4),
                            "the wrong four-actor foreground error was returned")
            } catch {
                expect(false, "an unexpected foreground error was returned: \(error)")
            }

            do {
                _ = try rebuilding(
                    actors: sample.actors,
                    foregroundActorIDs: sample.foregroundActorIDs,
                    situation: .init(
                        quarter: sample.situation.quarter,
                        clockSecondsRemaining: sample.situation.clockSecondsRemaining,
                        down: 5,
                        yardsToGo: sample.situation.yardsToGo,
                        possession: sample.situation.possession
                    )
                )
                expect(false, "a fifth down was accepted")
            } catch let error as MatchDayReadModel.ValidationError {
                expectEqual(error, .invalidSituation("down"),
                            "the wrong invalid-down error was returned")
            } catch {
                expect(false, "an unexpected invalid-down error was returned: \(error)")
            }

            do {
                _ = try rebuilding(
                    actors: sample.actors,
                    foregroundActorIDs: sample.foregroundActorIDs,
                    offenseDirection: .rightToLeft
                )
                expect(false, "a first-down line behind the declared direction was accepted")
            } catch let error as MatchDayReadModel.ValidationError {
                expectEqual(error, .invalidLine("firstDownDirection"),
                            "the wrong first-down-direction error was returned")
            } catch {
                expect(false, "an unexpected first-down-direction error was returned: \(error)")
            }

            do {
                _ = try rebuilding(
                    actors: sample.actors,
                    foregroundActorIDs: sample.foregroundActorIDs,
                    causalCommentary: "   "
                )
                expect(false, "blank causal commentary was accepted")
            } catch let error as MatchDayReadModel.ValidationError {
                expectEqual(error, .commentaryRequired,
                            "the wrong blank-commentary error was returned")
            } catch {
                expect(false, "an unexpected commentary error was returned: \(error)")
            }

            do {
                let repeatedIntent = sample.controls[0].intentID
                let controls = sample.controls.map { control in
                    MatchDayReadModel.ControlState(
                        id: control.id,
                        value: control.value,
                        isEnabled: control.isEnabled,
                        isSelected: control.isSelected,
                        intentID: repeatedIntent
                    )
                }
                _ = try rebuilding(
                    actors: sample.actors,
                    foregroundActorIDs: sample.foregroundActorIDs,
                    controls: controls
                )
                expect(false, "Match Day controls with duplicate intent IDs were accepted")
            } catch let error as MatchDayReadModel.ValidationError {
                expectEqual(error, .invalidControls,
                            "the wrong duplicate-control-intent error was returned")
            } catch {
                expect(false, "an unexpected duplicate-control-intent error was returned: \(error)")
            }
        }
#endif

        test("the production palette preserves readable role contrast") {
            // 04 section 6.1a (2026-08-16): Floodlit is dark-only, so `dark` is the sole production
            // palette. There is no `.light` to iterate any more.
            for (name, palette) in [
                ("dark", CoachWorldTokens.dark),
            ] {
                for surface in [palette.page, palette.work, palette.raised] {
                    expect(contrastRatio(palette.contentPrimary, surface) >= 4.5,
                           "\(name) primary content must meet 4.5:1")
                    expect(contrastRatio(palette.contentSecondary, surface) >= 4.5,
                           "\(name) secondary content must meet 4.5:1")
                    expect(contrastRatio(palette.contentQuiet, surface) >= 4.5,
                           "\(name) quiet content must meet 4.5:1")
                }
                for indicator in [
                    palette.actionPrimary, palette.actionSecondary,
                    palette.actionDestructive, palette.stateLive, palette.statePositive,
                    palette.stateWarning, palette.stateNegative, palette.stateInfo,
                ] {
                    expect(contrastRatio(indicator, palette.work) >= 3,
                           "\(name) action and state indicators must meet 3:1")
                }
                expect(contrastRatio(palette.fieldLine, palette.fieldTurf) >= 3,
                       "\(name) field lines must meet 3:1")
                expect(contrastRatio(palette.fieldAnnotation, palette.fieldTurf) >= 3,
                       "\(name) field annotations must meet 3:1")
                expect(contrastRatio(palette.fieldLive, palette.fieldTurf) >= 3,
                       "\(name) live field marks must meet 3:1")
            }
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

        test("the dictionary-key scan sees both spellings Swift accepts") {
            expect(dictionaryKeyTypes(in: "var m: [Attribute: Rating] = [:]\n").contains("Attribute"),
                   "a planted dictionary annotation was not seen")
            expect(dictionaryKeyTypes(in: "var m: Dictionary<ProbeKey, Int> = [:]\n")
                       .contains("ProbeKey"),
                   "the generic Dictionary<> spelling was not seen — this exact plant walked past "
                       + "the first version of this scan")
            expect(dictionaryKeyTypes(in: "var m: [String: Int]\n").contains("String"),
                   "a String-keyed annotation was not seen")
            expect(!dictionaryKeyTypes(in: "var ids: [UUID]\n").contains("UUID"),
                   "an array was mistaken for a dictionary")
            expect(!dictionaryKeyTypes(in: "let m = [key: value]\n").contains("key"),
                   "a lowercase literal key was mistaken for a type")
            expect(!dictionaryKeyTypes(in: "// [Attribute: Rating] in prose\n").contains("Attribute"),
                   "a dictionary mentioned only in a comment was reported")
        }

        test("no model type stores a Set, whose encoded order is salted per launch") {
            // Set encodes to an UNKEYED container in iteration order. .sortedKeys orders object
            // keys and does nothing to array elements, and Swift's hash seed is per-launch, so a
            // Set in a saved type produces different bytes every launch. P1 shipped this on
            // Player.traits — two traits was enough — and nothing could see it: Set equality is
            // order-independent so a round-trip test passes, and within one process the order is
            // constant so a repeat-encode test passes too.
            //
            // The fix is an array in a fixed order.
            //
            // Scoped to Model/ when it was written, on the premise that nothing outside Model/ is
            // encoded. P2 falsified that the same day by putting GeneratedWorld, TeamIdentity,
            // Rivalry, Tradition, GameMap, MapCity, Colour and three more Codable save types in
            // Generation/, all unscanned. It now walks the whole engine and exempts by name, which
            // is the inversion the ambient-identity scan above already uses.
            let model = savedShapeFiles()
            expect(!model.isEmpty, "found no engine sources to scan — the scan would pass vacuously")
            var offenders: [String] = []
            for file in model where !setElementTypes(in: file.text).isEmpty {
                offenders.append("\(file.path): Set<\(setElementTypes(in: file.text).sorted().joined(separator: ", "))>")
            }
            expect(
                offenders.isEmpty,
                "a Set in a saved type encodes in per-launch order; use an array in a fixed order: "
                    + offenders.joined(separator: ", ")
            )
        }

        test("every stored property in a model type carries a type annotation") {
            // The spelling neither map scan can see: `var m = [SomeKey.a: 1]` declares a dictionary
            // with no annotation anywhere to read. Rather than parse Swift, the engine carries the
            // rule that an instance stored property is annotated — good practice for types that
            // define a save format, and what makes the two scans above total over the tree.
            let model = savedShapeFiles()
            expect(!model.isEmpty, "found no engine sources to scan — the scan would pass vacuously")
            var offenders: [String] = []
            for file in model {
                for line in unannotatedStoredProperties(in: file.text) {
                    offenders.append("\(file.path):\(line)")
                }
            }
            expect(
                offenders.isEmpty,
                "an inferred stored-property type hides its shape from the map scans: "
                    + offenders.joined(separator: ", ")
            )
        }

        test("the Set and annotation scans catch their planted offenders") {
            expect(setElementTypes(in: "    public var traits: Set<Trait>\n").contains("Trait"),
                   "a planted stored Set was not seen")
            expect(setElementTypes(in: "    var members: Set<ProbeSetKey> = []\n")
                       .contains("ProbeSetKey"),
                   "a planted initialised Set was not seen")
            expect(setElementTypes(in: "    public var emphasises: Set<Attribute> { [.speed] }\n")
                       .isEmpty,
                   "a computed property returning a Set was reported — it is a lookup table, not a "
                       + "save field, and this false positive was in the first version")
            expect(setElementTypes(in: "        let scratch: Set<Int> = []\n").isEmpty,
                   "a local Set inside a function body was reported")
            expect(setElementTypes(in: "    let x: Int = 1\n").isEmpty,
                   "a plain declaration was reported as a Set")

            expectEqual(unannotatedStoredProperties(in: "    var inferred = [ProbeKey.alpha: 1]\n"),
                        [1], "a planted inferred dictionary literal was not caught")
            expectEqual(unannotatedStoredProperties(in: "    public static let limit = 8\n"), [],
                        "a static constant was reported — a static is a lookup table, not a field "
                            + "of an encoded value, and the rules modules are full of legitimate "
                            + "inferred ones")
            expect(setElementTypes(in: "    public static let names: Set<String> = []\n").isEmpty,
                   "a static Set lookup table was reported — Blocklist.names is one and is never "
                       + "encoded")
            expectEqual(unannotatedStoredProperties(in: "    public var name: String\n"), [],
                        "an annotated property was reported")
            expectEqual(unannotatedStoredProperties(in: "    public var overall: Rating { rating }\n"),
                        [], "a computed property was reported")
            expectEqual(unannotatedStoredProperties(in: "        let container = try d.container()\n"),
                        [], "a local binding inside a function body was reported — eleven of these "
                            + "were false failures in the first version")
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

    suite("Floodlit vocabulary (Task 4)") {
        // 04 section 7's "empty, error, interrupted and resume states remain inside the
        // composition" made checkable: every kind the canon names must produce a distinct label,
        // so a composition cannot silently fall back to one generic "something went wrong".
        test("CoachWorldSystemState exposes a distinct required label for every canon kind") {
            let kinds: [(CoachWorldSystemState.Kind, String)] = [
                (.empty("Nothing here yet"), "Nothing here yet"),
                (.loading("Loading"), "Loading"),
                (.error("Could not load", recoveryTitle: nil, onRecover: nil), "Could not load"),
                (.interrupted("Paused"), "Paused"),
                (.delegated("Staff decision in progress"), "Staff decision in progress"),
            ]
            for (kind, expected) in kinds {
                expectEqual(kind.message, expected,
                            "every canon kind must surface the exact message it was given")
            }
            let symbols = Set(kinds.map(\.0.symbolName))
            expectEqual(symbols.count, 5, "the five kinds must draw five visually distinct marks")
        }

        test("CoachWorldStatusChip cannot be built without visible text") {
            // The type itself is the contract: `text` is a required, non-optional parameter, so a
            // colour-only chip does not compile. This exercises the public initializer to prove the
            // requirement holds at the call site, not only in the declaration.
            let chip = CoachWorldStatusChip(text: "Full", tone: .go)
            expect(!chip.text.isEmpty, "a status chip's text must never be empty")
        }

        test("CoachWorldDeltaMark prints the signed value, never colour alone") {
            let positive = CoachWorldDeltaMark(value: 4)
            let negative = CoachWorldDeltaMark(value: -2)
            expectEqual(positive.value, 4)
            expectEqual(negative.value, -2)
            // Both directions must resolve to a registered Change-class symbol (04 section 6.6):
            // arrow.up.right / arrow.down.right. A third direction (value == 0) has no motion to
            // show and must not invent one.
            expectEqual(positive.symbolName, "arrow.up.right")
            expectEqual(negative.symbolName, "arrow.down.right")
            expect(CoachWorldDeltaMark(value: 0).symbolName == nil,
                   "a zero delta must not draw a direction it does not have")
        }

        test("CoachWorldIdentityBand renders nothing when identity resolution refuses") {
            // Mirrors CoachWorldTeamIdentity's own refusal contract: a malformed or illegible pair
            // must produce no team colour anywhere it is consumed, including this component.
            let malformed = CoachWorldTeamReference(
                stableID: "x", name: "X", abbreviation: "X",
                primaryColorHex: "not-a-colour", secondaryColorHex: "not-a-colour"
            )
            let band = CoachWorldIdentityBand(team: malformed, behind: CoachWorldTokens.dark.raised)
            expect(band.identity == nil, "a malformed pair must resolve to no identity, not a guess")
        }

        test("the broadcast register renders no desk backdrop or grain") {
            let sourcePath = "Sources/ProFootballCoachUI/CoachWorldDeskComponents.swift"
            guard let text = try? String(contentsOfFile: sourcePath, encoding: .utf8) else {
                expect(false, "could not read \(sourcePath)")
                return
            }
            expect(text.contains("enum CoachWorldRegister"),
                   "CoachWorldFloodlitStage has no register type to select broadcast's flat backdrop")
            expect(text.contains("register == .desk"),
                   "the backdrop/grain are not conditioned on the register, so broadcast would "
                       + "inherit desk chrome")
        }
    }
}
