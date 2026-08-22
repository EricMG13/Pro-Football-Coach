# Canonical Team Logos Implementation Plan

**Amended 2026-08-21.** Source art is 256 x 256, the size a 44 pt chip needs at 3x. The 1024 x 1024 requirement below is superseded: it shipped 157 MB of source art for a 132 device-pixel draw, and the pipeline had no resize step. `Tools/TeamLogos/downsample.swift` is that step; `TeamLogoTests` walks the imageset directory and bounds the pixel side, the per-file bytes and the catalogue total.


> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate, curate, package, and display one original AI-generated logo for each of the 166 teams in the canonical default-seed world, with safe fallback identity for every other seed.

**Architecture:** A checked-in manifest owns the canonical UUID-to-asset contract and generates one static catalogue in `ProFootballCoachUI`. `CoachWorldReadModelProvider.teamReference(_:in:)` attaches the existing optional `CoachWorldAssetReference`, and one reusable SwiftUI component renders the packaged image or the established colour-and-abbreviation fallback. Artwork is generated and approved offline; the shipped app has no AI or network path.

**Tech Stack:** Swift 5.10/Swift 6 package manifest, SwiftUI, Swift Package asset catalogues, Foundation JSON, ImageIO/CoreGraphics validation, the existing hand-rolled `SimTests` harness, XCTest/XCUITest, and the built-in `imagegen` tool for offline artwork generation.

## Global Constraints

- Canonical world seed: `20_260_812`.
- Canonical set size: exactly 166 stable team UUIDs and 166 distinct primary marks.
- Source art: exactly 256 x 256 transparent PNG files (was 1024 x 1024; see the amendment note).
- Artwork contains no words, initials, numerals, league names, watermarks, real-team references, or copied trade dress.
- Outer silhouettes are unrestricted; the six motif families finish with 27 or 28 teams each.
- Runtime lookup uses only stable UUID; never team name, abbreviation, colour, or table order.
- Unknown and alternate-seed UUIDs return `nil` and render the colour-and-abbreviation fallback.
- The app performs no AI generation, prompt execution, image download, or logo network request.
- Keep `FootballSimCore.TeamIdentity` and the save schema unchanged.
- Reuse `CoachWorldTeamReference.mark` and `CoachWorldAssetReference`; do not add a second logo model.
- No third-party dependency.
- Before Task 2's first artwork call, read and invoke the `imagegen` skill; keep one distinct logo per imagegen call through Task 7.
- League-map markers remain colour dots, and player jersey numbers remain numbers.
- Before editing any existing function, method, class, struct, or enum, run GitNexus upstream impact analysis and warn before HIGH or CRITICAL work.
- Before every code commit, run the repository-required `rewrite-tournament` for non-trivial changed code, `confidence-review` for all changed code, and GitNexus `detect_changes`.
- Stage only explicit task paths. Never use `git add .`, `git add -A`, `git commit -a`, amend, force-push, or include unrelated workspace changes.

## Artwork Generation Protocol

Generate one image per call. For the current manifest record, replace the bracketed values below with that record's exact values and save the final expanded prompt back into its `prompt` field before generation:

```text
Create one original American football team logo for the fictional [TEAM NAME].
Concept: [TEAM-SPECIFIC CONCEPT]. Motif family: [MOTIF FAMILY].
Use [PRIMARY HEX] and [SECONDARY HEX] as the dominant colours, with only neutral black or white where essential for separation.
Bold simplified professional sports identity, strong unique silhouette, readable at 20 points, balanced negative space, clean hard edges, centered in a square canvas, transparent background.
No words, letters, initials, numbers, league marks, uniforms, mockup, photograph, gradient haze, watermark, or reference to any real team. Do not imitate an existing sports logo or trade dress.
Output one isolated 256 x 256 PNG with transparency around the mark.
```

For every result:

1. Inspect the generated image before copying it into the repository.
2. Reject and regenerate text, unwanted background, fragile detail, wrong palette, obvious real-team resemblance, or similarity to an already approved fictional mark.
3. Place the accepted candidate at the manifest record's exact `.imageset` path and set only that record's `generationStatus` to `candidate`; leave `humanApproved` false.
4. Present the completed family's specimen grid to the owner. A machine pass does not satisfy the originality/similarity gate.
5. After owner approval, set those records to `generationStatus: "approved"`, `humanApproved: true`, and add concrete review notes.
6. Run the family command named in the task; expected output is `[ok] Team logo assets — 3 tests` and no failures.

---

### Task 1: Canonical Manifest and Validation Harness

**Files:**
- Create: `Tools/TeamLogos/manifest.json`
- Create: `Tests/SimTests/Suites/TeamLogoTests.swift`
- Modify: `Tests/SimTests/main.swift:8-202`

**Interfaces:**
- Consumes: `GameState.bootstrap(seed:)`, canonical `programmes`, `proTeams`, and `identities`.
- Produces: `TeamLogoManifest`, `TeamLogoRecord`, `runTeamLogoManifestExport()`, `runTeamLogoManifestTests()`, and `runTeamLogoAssetTests(family:)`.

- [ ] **Step 1: Run impact analysis for the test entry point**

Run GitNexus upstream impact on `main.swift`'s dispatch path. Expected risk is LOW because the new arguments are additive. If the result is HIGH or CRITICAL, stop and show the user the affected processes before editing.

- [ ] **Step 2: Write the failing manifest tests and exporter**

Create `TeamLogoTests.swift` with these public-to-the-test-target contracts and assertions:

```swift
import CoreGraphics
import Foundation
import FootballSimCore
import ImageIO

enum TeamLogoFamily: String, Codable, CaseIterable {
    case animalCreature
    case regionalSymbol
    case equipmentVehicle
    case originalCharacter
    case framedEmblem
    case abstractMotion
}

struct TeamLogoManifest: Codable {
    let schemaVersion: Int
    let worldSeed: UInt64
    var teams: [TeamLogoRecord]
}

struct TeamLogoRecord: Codable {
    let stableID: String
    let name: String
    let abbreviation: String
    let primaryColorHex: String
    let secondaryColorHex: String
    var family: TeamLogoFamily
    var concept: String
    var prompt: String
    let assetName: String
    let filename: String
    var generationStatus: String
    var humanApproved: Bool
    var reviewNotes: String
}

private let teamLogoManifestURL = URL(
    fileURLWithPath: "Tools/TeamLogos/manifest.json"
)

private func loadTeamLogoManifest() throws -> TeamLogoManifest {
    try JSONDecoder().decode(
        TeamLogoManifest.self,
        from: Data(contentsOf: teamLogoManifestURL)
    )
}

func runTeamLogoManifestExport() throws {
    let state = GameState.bootstrap(seed: 20_260_812)
    let ids = Set(state.programmes.keys).union(state.proTeams.keys)
    let families = TeamLogoFamily.allCases
    let records = ids.sorted { $0.uuidString < $1.uuidString }.enumerated().map { index, id in
        let name = state.programmes[id]?.name
            ?? state.proTeams[id].map { "\($0.cityName) \($0.nickname)" }
            ?? "Unknown team"
        let letters = name.filter(\.isLetter)
        let assetName = "TeamLogo_" + id.uuidString.replacingOccurrences(of: "-", with: "")
        return TeamLogoRecord(
            stableID: id.uuidString,
            name: name,
            abbreviation: String(letters.prefix(3)).uppercased(),
            primaryColorHex: state.identities[id]?.colours.primary.hex ?? "",
            secondaryColorHex: state.identities[id]?.colours.secondary.hex ?? "",
            family: families[index % families.count],
            concept: "",
            prompt: "",
            assetName: assetName,
            filename: assetName + ".png",
            generationStatus: "pending",
            humanApproved: false,
            reviewNotes: ""
        )
    }
    let manifest = TeamLogoManifest(schemaVersion: 1, worldSeed: 20_260_812, teams: records)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try FileManager.default.createDirectory(
        at: teamLogoManifestURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try encoder.encode(manifest).write(to: teamLogoManifestURL, options: .atomic)
}

func runTeamLogoManifestTests() {
    suite("Team logo manifest") {
        test("manifest exactly matches the canonical world") {
            let manifest = try loadTeamLogoManifest()
            let world = GameState.bootstrap(seed: manifest.worldSeed)
            let worldIDs = Set(world.programmes.keys).union(world.proTeams.keys).map(\.uuidString)
            expectEqual(manifest.schemaVersion, 1)
            expectEqual(manifest.worldSeed, 20_260_812)
            expectEqual(manifest.teams.count, 166)
            expectEqual(Set(manifest.teams.map(\.stableID)), Set(worldIDs))
        }
        test("lookup keys, names and prompts are unique and complete") {
            let teams = try loadTeamLogoManifest().teams
            expectEqual(Set(teams.map(\.stableID)).count, 166)
            expectEqual(Set(teams.map(\.assetName)).count, 166)
            expectEqual(Set(teams.map(\.filename)).count, 166)
            for team in teams {
                expect(UUID(uuidString: team.stableID) != nil)
                expect(!team.name.isEmpty)
                expect(team.abbreviation.count == 3)
                expect(team.primaryColorHex.count == 7)
                expect(team.secondaryColorHex.count == 7)
                expect(!team.concept.trimmingCharacters(in: .whitespaces).isEmpty)
                expect(!team.prompt.trimmingCharacters(in: .whitespaces).isEmpty)
                expect(!team.prompt.localizedCaseInsensitiveContains("NFL"))
                expect(!team.prompt.localizedCaseInsensitiveContains("NBA"))
                expect(!team.prompt.localizedCaseInsensitiveContains("MLB"))
                expect(!team.prompt.localizedCaseInsensitiveContains("NHL"))
            }
        }
        test("motif families are balanced") {
            let teams = try loadTeamLogoManifest().teams
            for family in TeamLogoFamily.allCases {
                let count = teams.filter { $0.family == family }.count
                expect(count == 27 || count == 28, "\(family.rawValue) has \(count) teams")
            }
        }
    }
}
```

Add `import CryptoKit` and this asset gate in the same file:

```swift
private let teamLogoAssetsURL = URL(
    fileURLWithPath: "Sources/ProFootballCoachUI/Resources/TeamLogos.xcassets"
)

private func pngURL(for team: TeamLogoRecord) -> URL {
    teamLogoAssetsURL
        .appendingPathComponent(team.assetName + ".imageset")
        .appendingPathComponent(team.filename)
}

private func hasTransparentEdgePixel(_ image: CGImage) -> Bool {
    let width = image.width
    let height = image.height
    var pixels = [UInt8](repeating: 255, count: width * height * 4)
    guard let context = CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return false }
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    let edgeOffsets = (0..<width).flatMap { x in
        [x * 4 + 3, ((height - 1) * width + x) * 4 + 3]
    } + (0..<height).flatMap { y in
        [(y * width) * 4 + 3, (y * width + width - 1) * 4 + 3]
    }
    return edgeOffsets.contains { pixels[$0] == 0 }
}

func runTeamLogoAssetTests(family rawValue: String) {
    suite("Team logo assets") {
        test("requested family is complete and approved") {
            guard let family = TeamLogoFamily(rawValue: rawValue) else {
                expect(false, "unknown family \(rawValue)")
                return
            }
            let records = try loadTeamLogoManifest().teams.filter { $0.family == family }
            expect(records.count == 27 || records.count == 28)
            expect(records.allSatisfy { $0.generationStatus == "approved" && $0.humanApproved })
            expect(records.allSatisfy { !$0.reviewNotes.isEmpty })
        }
        test("requested family PNGs are square alpha images with transparent edges") {
            guard let family = TeamLogoFamily(rawValue: rawValue) else { return }
            let records = try loadTeamLogoManifest().teams.filter { $0.family == family }
            for record in records {
                let url = pngURL(for: record)
                expect(FileManager.default.fileExists(atPath: url.path), "missing \(url.path)")
                guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                        as? [CFString: Any],
                      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { continue }
                expectEqual(properties[kCGImagePropertyPixelWidth] as? Int, Optional(256))
                expectEqual(properties[kCGImagePropertyPixelHeight] as? Int, Optional(256))
                expectEqual(properties[kCGImagePropertyHasAlpha] as? Bool, Optional(true))
                expect(hasTransparentEdgePixel(image), "opaque edge in \(record.filename)")
            }
        }
        test("no approved PNG is reused") {
            let approved = try loadTeamLogoManifest().teams.filter(\.humanApproved)
            let hashes = try approved.map { record in
                Data(SHA256.hash(data: try Data(contentsOf: pngURL(for: record))))
            }
            expectEqual(Set(hashes).count, hashes.count)
        }
    }
}
```

Add the review-page writer so family and complete-set approval use the same scale proof:

```swift
func writeTeamLogoSpecimen(family rawValue: String) throws {
    let manifest = try loadTeamLogoManifest()
    let teams: [TeamLogoRecord]
    if rawValue == "all" {
        teams = manifest.teams
    } else if let family = TeamLogoFamily(rawValue: rawValue) {
        teams = manifest.teams.filter { $0.family == family }
    } else {
        fatalError("unknown team-logo family \(rawValue)")
    }
    let cards = teams.sorted { $0.name < $1.name }.map { team in
        let source = "../../Sources/ProFootballCoachUI/Resources/TeamLogos.xcassets/"
            + "\(team.assetName).imageset/\(team.filename)"
        return """
        <article><h2>\(team.name)</h2>
          <div class="dark"><img class="c" src="\(source)"><img class="m" src="\(source)"><img class="l" src="\(source)"></div>
          <div class="light"><img class="c" src="\(source)"><img class="m" src="\(source)"><img class="l" src="\(source)"></div>
        </article>
        """
    }.joined(separator: "\n")
    let html = """
    <!doctype html><meta charset="utf-8"><title>Team logo specimen: \(rawValue)</title>
    <style>
      body{font:14px system-ui;background:#111827;color:#f8fafc;margin:24px}
      main{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:12px}
      article{border:1px solid #475569;padding:12px}h2{font-size:13px;margin:0 0 8px}
      .dark,.light{height:56px;display:flex;align-items:center;gap:18px;padding:8px}
      .dark{background:#07111f}.light{background:#f8fafc}.c{width:20px;height:20px}.m{width:32px;height:32px}.l{width:44px;height:44px}img{object-fit:contain}
    </style><main>\(cards)</main>
    """
    let output = FileManager.default.temporaryDirectory
        .appendingPathComponent("team-logo-specimen-\(rawValue).html")
    try html.write(to: output, atomically: true, encoding: .utf8)
    print(output.path)
}
```

- [ ] **Step 3: Wire the two commands and verify the test fails before the manifest exists**

Add these branches before `--screen-read-models` in `main.swift`:

```swift
} else if CommandLine.arguments.contains("--export-team-logo-manifest") {
    try runTeamLogoManifestExport()
} else if CommandLine.arguments.contains("--team-logo-manifest") {
    runTeamLogoManifestTests()
} else if let index = CommandLine.arguments.firstIndex(of: "--team-logo-assets"),
          CommandLine.arguments.indices.contains(index + 1) {
    runTeamLogoAssetTests(family: CommandLine.arguments[index + 1])
} else if let index = CommandLine.arguments.firstIndex(of: "--team-logo-specimen"),
          CommandLine.arguments.indices.contains(index + 1) {
    try writeTeamLogoSpecimen(family: CommandLine.arguments[index + 1])
```

Run: `swift run SimTests --team-logo-manifest`

Expected: FAIL because `Tools/TeamLogos/manifest.json` does not exist.

- [ ] **Step 4: Export and complete the manifest**

Run from the repository root:

Run: `swift run SimTests --export-team-logo-manifest`

Expected: the command atomically creates `Tools/TeamLogos/manifest.json` with 166 records.

For every record, choose a name-appropriate concept, rebalance family assignments until each family has 27 or 28 records, expand the exact Artwork Generation Protocol prompt, and save it to `prompt`. Leave `generationStatus: "pending"`, `humanApproved: false`, and `reviewNotes: ""` until artwork is actually reviewed.

- [ ] **Step 5: Run the manifest gate**

Run: `swift run SimTests --team-logo-manifest`

Expected: `[ok] Team logo manifest — 3 tests` and no failures.

- [ ] **Step 6: Review and commit**

Run rewrite-tournament on the new exporter/validator, confidence-review, and GitNexus `detect_changes`. Fix confirmed issues, then:

```bash
git add Tools/TeamLogos/manifest.json
git add Tests/SimTests/Suites/TeamLogoTests.swift
git add Tests/SimTests/main.swift
git commit -m "test: define canonical team logo manifest" -m "Co-Authored-By: Codex Opus 4.8 <noreply@anthropic.com>"
```

### Task 2: Animal and Creature Logo Batch

**Files:**
- Modify: `Tools/TeamLogos/manifest.json`
- Create: `Sources/ProFootballCoachUI/Resources/TeamLogos.xcassets/Contents.json`
- Create: all `.imageset` directories whose manifest family is `animalCreature`

**Interfaces:**
- Consumes: Task 1 manifest records and the Artwork Generation Protocol.
- Produces: 27 or 28 owner-reviewed `animalCreature` PNGs and approved manifest records.

- [ ] **Step 1: Generate the batch one record per imagegen call**

Use the exact expanded prompt stored in each `animalCreature` record. Inspect each result, then create its imageset `Contents.json` with one universal 1x image whose `filename` is exactly the record's `filename`; the `info` object is `{ "author": "xcode", "version": 1 }`. The asset-catalogue root `Contents.json` contains that same `info` object.

- [ ] **Step 2: Obtain owner approval, then validate**

Run: `swift run SimTests --team-logo-assets animalCreature`

Run `swift run SimTests --team-logo-specimen animalCreature` and present the generated page first. After the owner approves it, update the approval fields and run the asset command. Expected: `[ok] Team logo assets — 3 tests`.

- [ ] **Step 3: Commit only this batch**

Run confidence-review and `detect_changes`, then:

```bash
git add Tools/TeamLogos/manifest.json
git add Sources/ProFootballCoachUI/Resources/TeamLogos.xcassets
git commit -m "assets: add animal team logos" -m "Co-Authored-By: Codex Opus 4.8 <noreply@anthropic.com>"
```

### Task 3: Regional Symbol Logo Batch

**Files:**
- Modify: `Tools/TeamLogos/manifest.json`
- Create: all `.imageset` directories whose manifest family is `regionalSymbol`

**Interfaces:**
- Consumes: Task 1 manifest records and the Artwork Generation Protocol.
- Produces: 27 or 28 owner-reviewed `regionalSymbol` PNGs and approved manifest records.

- [ ] **Step 1: Generate and inspect each regional-symbol mark**

Use one imagegen call per record and the exact stored prompt. Reject generic skyline collages; the chosen local landmark, natural feature, or regional symbol must remain recognizable at compact size. Write the record's exact PNG and imageset `Contents.json`, then set its approval fields.

- [ ] **Step 2: Obtain owner approval, then validate**

Run: `swift run SimTests --team-logo-assets regionalSymbol`

Run `swift run SimTests --team-logo-specimen regionalSymbol` and present the generated page first. After owner approval, update the approval fields and run the asset command. Expected: `[ok] Team logo assets — 3 tests`.

- [ ] **Step 3: Commit only this batch**

Run confidence-review and `detect_changes`, then explicitly stage the manifest and asset catalogue and commit as `assets: add regional team logos` with the required co-author trailer.

### Task 4: Equipment and Vehicle Logo Batch

**Files:**
- Modify: `Tools/TeamLogos/manifest.json`
- Create: all `.imageset` directories whose manifest family is `equipmentVehicle`

**Interfaces:**
- Consumes: Task 1 manifest records and the Artwork Generation Protocol.
- Produces: 27 or 28 owner-reviewed `equipmentVehicle` PNGs and approved manifest records.

- [ ] **Step 1: Generate and inspect each object-led mark**

Use one imagegen call per record and the exact stored prompt. The tool, vehicle, equipment, or cultural object must lead the silhouette; reject clip-art rendering, literal product branding, or small secondary objects that disappear at 20 points.

- [ ] **Step 2: Obtain owner approval, then validate**

Run: `swift run SimTests --team-logo-assets equipmentVehicle`

Run `swift run SimTests --team-logo-specimen equipmentVehicle` and present the generated page first. After owner approval, update the approval fields and run the asset command. Expected: `[ok] Team logo assets — 3 tests`.

- [ ] **Step 3: Commit only this batch**

Run confidence-review and `detect_changes`, then explicitly stage the manifest and asset catalogue and commit as `assets: add object team logos` with the required co-author trailer.

### Task 5: Original Character Logo Batch

**Files:**
- Modify: `Tools/TeamLogos/manifest.json`
- Create: all `.imageset` directories whose manifest family is `originalCharacter`

**Interfaces:**
- Consumes: Task 1 manifest records and the Artwork Generation Protocol.
- Produces: 27 or 28 owner-reviewed `originalCharacter` PNGs and approved manifest records.

- [ ] **Step 1: Generate and inspect each character mark**

Use one imagegen call per record and the exact stored prompt. Reject celebrity likeness, real uniform elements, stereotypes, extra limbs, facial artifacts, and characters whose silhouette depends on a surrounding wordmark.

- [ ] **Step 2: Obtain owner approval, then validate**

Run: `swift run SimTests --team-logo-assets originalCharacter`

Run `swift run SimTests --team-logo-specimen originalCharacter` and present the generated page first. After owner approval, update the approval fields and run the asset command. Expected: `[ok] Team logo assets — 3 tests`.

- [ ] **Step 3: Commit only this batch**

Run confidence-review and `detect_changes`, then explicitly stage the manifest and asset catalogue and commit as `assets: add character team logos` with the required co-author trailer.

### Task 6: Framed Emblem Logo Batch

**Files:**
- Modify: `Tools/TeamLogos/manifest.json`
- Create: all `.imageset` directories whose manifest family is `framedEmblem`

**Interfaces:**
- Consumes: Task 1 manifest records and the Artwork Generation Protocol.
- Produces: 27 or 28 owner-reviewed `framedEmblem` PNGs and approved manifest records.

- [ ] **Step 1: Generate and inspect each framed mark**

Use one imagegen call per record and the exact stored prompt. Shields, roundels, and pennants may be broken by the central motif; reject a batch that repeats one container or turns the unrestricted-shape direction into a uniform badge system.

- [ ] **Step 2: Obtain owner approval, then validate**

Run: `swift run SimTests --team-logo-assets framedEmblem`

Run `swift run SimTests --team-logo-specimen framedEmblem` and present the generated page first. After owner approval, update the approval fields and run the asset command. Expected: `[ok] Team logo assets — 3 tests`.

- [ ] **Step 3: Commit only this batch**

Run confidence-review and `detect_changes`, then explicitly stage the manifest and asset catalogue and commit as `assets: add framed team logos` with the required co-author trailer.

### Task 7: Abstract Motion Logo Batch

**Files:**
- Modify: `Tools/TeamLogos/manifest.json`
- Create: all `.imageset` directories whose manifest family is `abstractMotion`

**Interfaces:**
- Consumes: Task 1 manifest records and the Artwork Generation Protocol.
- Produces: 27 or 28 owner-reviewed `abstractMotion` PNGs and a fully approved 166-record manifest.

- [ ] **Step 1: Generate and inspect each abstract mark**

Use one imagegen call per record and the exact stored prompt. The logo must still have a describable relationship to speed, force, weather, or motion; reject meaningless corporate swooshes and anything close to a real sports or automotive mark.

- [ ] **Step 2: Obtain final owner approval, then run the complete asset gate**

Run `swift run SimTests --team-logo-specimen abstractMotion` for the family review and `swift run SimTests --team-logo-specimen all` for the complete 166-logo grid. The owner reviews both for duplicates and real-team similarity. After approval, update the final records, run all six family commands, and confirm every record is `approved` and `humanApproved == true`.

Expected: six `[ok] Team logo assets — 3 tests` lines and zero pending records.

- [ ] **Step 3: Commit only this batch**

Run confidence-review and `detect_changes`, then explicitly stage the manifest and asset catalogue and commit as `assets: complete canonical team logos` with the required co-author trailer.

### Task 8: Package Resources, Generate the Catalogue, and Map Read Models

**Files:**
- Create: `Tools/TeamLogos/generate_catalog.swift`
- Create: `Sources/ProFootballCoachUI/TeamLogoCatalog.generated.swift`
- Modify: `Package.swift:18-27`
- Modify: `Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:462-476`
- Modify: `Tests/SimTests/Suites/ReadModelProviderTests.swift:43-74`

**Interfaces:**
- Consumes: fully approved `manifest.json`.
- Produces: `CoachWorldTeamLogoCatalog.mark(forStableID:) -> CoachWorldAssetReference?` and populated `CoachWorldTeamReference.mark` values.

- [ ] **Step 1: Run impact analysis**

Run upstream impact on `CoachWorldReadModelProvider.teamReference`, `CoachWorldTeamReference`, and the `ProFootballCoachUI` target declaration in `Package.swift`. Report direct callers and affected flows; stop for a HIGH or CRITICAL warning.

- [ ] **Step 2: Write failing provider tests**

Add to the identity suite in `ReadModelProviderTests.swift`:

```swift
test("canonical teams receive their stable logo references") {
    let world = GameState.bootstrap(seed: CoachWorldStore.defaultSeed)
    let results = CoachWorldReadModelProvider.worldSearch(from: world).results
    expectEqual(results.count, 166)
    expect(results.allSatisfy { result in
        result.team.mark?.stableID == result.team.stableID
            && result.team.mark?.assetName.hasPrefix("TeamLogo_") == true
    })
}

test("alternate seeds do not borrow canonical logos") {
    let world = GameState.bootstrap(seed: CoachWorldStore.defaultSeed + 1)
    let results = CoachWorldReadModelProvider.worldSearch(from: world).results
    expect(results.allSatisfy { $0.team.mark == nil })
}
```

Run: `swift run SimTests --screen-read-models`

Expected: FAIL because canonical teams still have `mark == nil`.

- [ ] **Step 3: Add resource processing and the generated catalogue**

Change the UI target in `Package.swift` to:

```swift
.target(
    name: "ProFootballCoachUI",
    dependencies: ["FootballSimCore"],
    path: "Sources/ProFootballCoachUI",
    resources: [.process("Resources")]
),
```

Create `generate_catalog.swift` as a complete manifest-to-Swift generator:

```swift
import Foundation

struct Manifest: Decodable { let teams: [Team] }
struct Team: Decodable {
    let stableID: String
    let name: String
    let abbreviation: String
    let primaryColorHex: String
    let secondaryColorHex: String
    let assetName: String
    let generationStatus: String
    let humanApproved: Bool
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let manifestURL = root.appendingPathComponent("Tools/TeamLogos/manifest.json")
let outputURL = root.appendingPathComponent(
    "Sources/ProFootballCoachUI/TeamLogoCatalog.generated.swift"
)
let manifest = try JSONDecoder().decode(
    Manifest.self,
    from: Data(contentsOf: manifestURL)
)
guard manifest.teams.count == 166,
      manifest.teams.allSatisfy({ $0.generationStatus == "approved" && $0.humanApproved })
else { fatalError("catalogue requires 166 owner-approved logo records") }

let entries = manifest.teams
    .sorted { $0.stableID < $1.stableID }
    .map { "        \"\($0.stableID)\": \"\($0.assetName)\"," }
    .joined(separator: "\n")
func swiftLiteral(_ value: String) -> String {
    value.replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
}
let proofEntries = manifest.teams
    .sorted { $0.stableID < $1.stableID }
    .map { team in
        "        CoachWorldTeamReference(stableID: \"\(team.stableID)\", "
            + "name: \"\(swiftLiteral(team.name))\", "
            + "abbreviation: \"\(team.abbreviation)\", "
            + "mark: mark(forStableID: \"\(team.stableID)\"), "
            + "primaryColorHex: \"\(team.primaryColorHex)\", "
            + "secondaryColorHex: \"\(team.secondaryColorHex)\"),"
    }
    .joined(separator: "\n")
let source = """
// Generated by Tools/TeamLogos/generate_catalog.swift. Do not hand-edit.
public enum CoachWorldTeamLogoCatalog {
    public static func mark(forStableID stableID: String) -> CoachWorldAssetReference? {
        assetNames[stableID].map {
            CoachWorldAssetReference(stableID: stableID, assetName: $0)
        }
    }

    private static let assetNames: [String: String] = [
\(entries)
    ]

    #if DEBUG
    static let proofTeams: [CoachWorldTeamReference] = [
\(proofEntries)
    ]
    #endif
}
"""
try source.write(to: outputURL, atomically: true, encoding: .utf8)
```

Run: `swift Tools/TeamLogos/generate_catalog.swift`

Expected: `TeamLogoCatalog.generated.swift` contains exactly 166 dictionary entries and no prompt or review metadata.

- [ ] **Step 4: Attach marks at the existing composition point**

Add the one argument to `teamReference`:

```swift
return CoachWorldTeamReference(
    stableID: id.uuidString,
    name: name,
    abbreviation: abbreviation(name),
    mark: CoachWorldTeamLogoCatalog.mark(forStableID: id.uuidString),
    primaryColorHex: colours?.primary.hex,
    secondaryColorHex: colours?.secondary.hex
)
```

- [ ] **Step 5: Verify and commit**

Run:

```bash
swift run SimTests --team-logo-manifest
swift run SimTests --screen-read-models
swift build
```

Expected: all pass. Run rewrite-tournament, confidence-review, and `detect_changes`, then commit the five task paths as `feat: map canonical team logo assets` with the required co-author trailer.

### Task 9: Reusable Logo and Fallback Component

**Files:**
- Create: `Sources/ProFootballCoachUI/CoachWorldTeamLogo.swift`
- Create: `Sources/ProFootballCoachUI/TeamLogoProofView.swift`
- Modify: `Sources/ProFootballCoachUI/RootView.swift` at its DEBUG proof routing
- Modify: `Tests/SimTests/Suites/DesignContractTests.swift` in the raw-asset scan section

**Interfaces:**
- Consumes: `CoachWorldTeamReference.mark` and `CoachWorldTeamIdentity`.
- Produces: `CoachWorldTeamLogo`, `CoachWorldTeamLogoSize`, and a DEBUG proof surface that renders asset and fallback branches.

- [ ] **Step 1: Run impact analysis and add the failing contract**

Run upstream impact on `RootView`, `CoachWorldTeamIdentity`, and the design-contract scan. Add a test that scans `Sources/ProFootballCoachUI` and fails if `Image(...bundle:)`, `UIImage(named:)`, or `NSImage` asset loading appears outside `CoachWorldTeamLogo.swift`. Run `swift run SimTests --design-contracts`; expected FAIL because the approved loader file does not exist yet.

- [ ] **Step 2: Implement the minimum reusable component**

Create:

```swift
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum CoachWorldTeamLogoSize: CGFloat {
    case compact = 20
    case medium = 32
    case large = 44
}

struct CoachWorldTeamLogo: View {
    let team: CoachWorldTeamReference
    let size: CoachWorldTeamLogoSize
    let surface: CoachWorldTokens.ColorValue
    var palette: CoachWorldTokens.Palette = CoachWorldTokens.dark
    var isDecorative = true

    var body: some View {
        Group {
            if let image = packagedImage {
                image.resizable().scaledToFit()
            } else {
                fallback
            }
        }
        .frame(width: size.rawValue, height: size.rawValue)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(team.name)
        .accessibilityHidden(isDecorative)
    }

    private var packagedImage: Image? {
        guard let name = team.mark?.assetName else { return nil }
        #if canImport(UIKit)
        guard let image = UIImage(named: name, in: .module, compatibleWith: nil) else { return nil }
        return Image(uiImage: image)
        #elseif canImport(AppKit)
        guard let image = Bundle.module.image(forResource: NSImage.Name(name)) else { return nil }
        return Image(nsImage: image)
        #else
        return nil
        #endif
    }

    private var fallback: some View {
        let identity = CoachWorldTeamIdentity(
            team: team,
            behind: surface,
            inks: [palette.contentPrimary, palette.page]
        )
        return Text(team.abbreviation)
            .font(CoachWorldTokens.TypeRole.caption.weight(.black))
            .minimumScaleFactor(0.65)
            .foregroundStyle((identity?.onField ?? palette.contentPrimary).color)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                (identity?.field ?? palette.raised).color,
                in: CoachWorldCutCorner.chip
            )
    }
}
```

Implement the proof surface with `CoachWorldTeamLogoCatalog.proofTeams`, all three sizes, both backgrounds, and one constructed unknown team:

```swift
#if DEBUG
struct TeamLogoProofView: View {
    private let palette = CoachWorldTokens.dark
    private let unknown = CoachWorldTeamReference(
        stableID: "00000000-0000-0000-0000-000000000000",
        name: "Fallback Team",
        abbreviation: "FBK",
        primaryColorHex: "#315C8C",
        secondaryColorHex: "#E8B84A"
    )

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220))]) {
                ForEach(CoachWorldTeamLogoCatalog.proofTeams, id: \.stableID) { team in
                    VStack(alignment: .leading) {
                        Text(team.name)
                        logoRow(team, surface: palette.page)
                            .background(palette.page.color)
                        logoRow(team, surface: palette.raised)
                            .background(palette.raised.color)
                    }
                }
            }
            .accessibilityIdentifier("team-logo-asset-proof")
            logoRow(unknown, surface: palette.raised)
                .accessibilityIdentifier("team-logo-fallback-proof")
        }
        .padding()
        .background(palette.work.color)
    }

    private func logoRow(
        _ team: CoachWorldTeamReference,
        surface: CoachWorldTokens.ColorValue
    ) -> some View {
        HStack {
            CoachWorldTeamLogo(team: team, size: .compact, surface: surface)
            CoachWorldTeamLogo(team: team, size: .medium, surface: surface)
            CoachWorldTeamLogo(team: team, size: .large, surface: surface)
        }
    }
}
#endif
```

Add this first branch in `DebugCoachingHQRoot.body`:

```swift
if ProcessInfo.processInfo.environment["PROOF_SCREEN"] == "team-logos" {
    TeamLogoProofView()
} else if ProcessInfo.processInfo.environment["PROOF_SCREEN"] == "job-redesign"
            || CommandLine.arguments.contains("--redesigned-job-board") {
```

The app shell already routes every non-nil `PROOF_SCREEN` value to `RootView`, so no app-target change is needed.

- [ ] **Step 3: Verify and commit**

Run `swift run SimTests --design-contracts` and `swift build`. Expected: PASS and both platform compilation branches type-check. Run rewrite-tournament, confidence-review, and `detect_changes`, then commit the four task paths as `feat: add team logo renderer` with the required co-author trailer.

### Task 10: Large and Medium Placements

**Files:**
- Modify: `Sources/ProFootballCoachUI/NewCareerSetupView.swift:125-185`
- Modify: `Sources/ProFootballCoachUI/WorldSearchView.swift:150-204`
- Modify: `Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift:55-113,197-249`
- Modify: `Sources/ProFootballCoachUI/LegacyHistoryView.swift:47-139`
- Modify: `Sources/ProFootballCoachUI/RosterView.swift:89-162`

**Interfaces:**
- Consumes: `CoachWorldTeamLogo` from Task 9.
- Produces: large controlled-team/profile marks and medium job, search, rivalry, and career-presentation marks.

- [ ] **Step 1: Run impact analysis for every changed view symbol**

Run upstream impact on `NewCareerSetupView.jobRow`, `WorldSearchView.resultRow`, `TeamProgrammeProfileView.identityColumn`, `TeamProgrammeProfileView.rivalRow`, `LegacyHistoryView.topBar`, `LegacyHistoryView.careerLine`, and `RosterView.uniformMark`. Stop for any HIGH or CRITICAL warning.

- [ ] **Step 2: Add the two large identity marks**

Add this before the name block in `TeamProgrammeProfileView.identityColumn` and use the same component in `RosterView.worldStrip` in place of `uniformMark`:

```swift
CoachWorldTeamLogo(
    team: model.team,
    size: .large,
    surface: palette.raised,
    palette: palette
)
```

The 44-point size fits the existing 48-point roster strip and remains the fixed recognition mark beside reflowing profile text.

- [ ] **Step 3: Add medium marks without changing labels**

Insert a `.medium` logo as the leading child in the existing `HStack` for each job, world-search result, profile rivalry row, legacy top bar, and career-line row. Use each view's actual background token for `surface`. Keep the surrounding row's existing accessibility label and keep the logo hidden from VoiceOver.

Use these exact component calls at the named sites:

```swift
CoachWorldTeamLogo(team: job.programme, size: .medium, surface: palette.raised, palette: palette)
CoachWorldTeamLogo(team: result.team, size: .medium, surface: palette.work, palette: palette)
CoachWorldTeamLogo(team: rival.team, size: .medium, surface: palette.work, palette: palette)
CoachWorldTeamLogo(team: model.team, size: .medium, surface: palette.raised, palette: palette)
CoachWorldTeamLogo(team: row.organisation, size: .medium, surface: palette.page, palette: palette)
```

At accessibility Dynamic Type sizes, preserve the text's full-width reflow; the fixed 32-point logo may stay fixed because the adjacent label carries the complete identity.

- [ ] **Step 4: Verify and commit**

Run:

```bash
swift run SimTests --screen-read-models
swift run SimTests --design-contracts
swift build
```

Expected: all pass. Run rewrite-tournament, confidence-review, and `detect_changes`, then commit the five explicit view paths as `feat: add prominent team logo placements` with the required co-author trailer.

### Task 11: Compact Scorebug, Standings, Schedule, Rankings, and Chrome Placements

**Files:**
- Modify: `Sources/ProFootballCoachUI/MatchDayScoreBug.swift:74-177`
- Modify: `Sources/ProFootballCoachUI/StandingsView.swift:110-210`
- Modify: `Sources/ProFootballCoachUI/ScheduleView.swift:110-196`
- Modify: `Sources/ProFootballCoachUI/CompetitionOverviewView.swift:122-173`
- Modify: `Sources/ProFootballCoachUI/FloodlitChrome.swift:306-417`

**Interfaces:**
- Consumes: `CoachWorldTeamLogo` from Task 9.
- Produces: compact team recognition in dense and broadcast surfaces while retaining all text identity.

- [ ] **Step 1: Run impact analysis for the six rendering functions**

Run upstream impact on `ScoreBug.cell`, `StandingsView.rowBody`, `ScheduleView.gameRow`, `CompetitionOverviewView.rankingRow`, `FloodlitIdentityHeader.primaryRow`, and `FloodlitIdentityHeader.contextChip`. Stop for any HIGH or CRITICAL warning.

- [ ] **Step 2: Add compact marks beside existing text**

Add `.compact` logos:

- before the abbreviation in each scorebug cell;
- before the team name in both normal and accessibility standings layouts;
- before the two-line away/home text block, using a compact logo for each scheduled team rather than replacing either name;
- before the team name in ranking rows;
- in the controlled-team chrome header, replacing its 11 x 14 pennant;
- in the opponent context chip, replacing its pennant.

Use the actual row/cell background token as `surface`. Do not change possession, score, selected-row, controlled-team, opponent-neutral, or VoiceOver logic.

The inserted calls are:

```swift
CoachWorldTeamLogo(team: score.team, size: .compact,
                   surface: CoachWorldTokens.Floodlit.roomDeep)
CoachWorldTeamLogo(team: row.team, size: .compact,
                   surface: palette.work, palette: palette)
CoachWorldTeamLogo(team: game.away, size: .compact,
                   surface: palette.work, palette: palette)
CoachWorldTeamLogo(team: game.home, size: .compact,
                   surface: palette.work, palette: palette)
CoachWorldTeamLogo(team: row.team, size: .compact,
                   surface: palette.work, palette: palette)
CoachWorldTeamLogo(team: model.club, size: .compact,
                   surface: CoachWorldTokens.Floodlit.roomDeep, palette: palette)
CoachWorldTeamLogo(team: opponent, size: .compact,
                   surface: CoachWorldTokens.Floodlit.roomDeep, palette: palette)
```

For schedule rows, put the away logo beside the away name and the home logo beside the `at <home>` line; do not collapse them into one ambiguous fixture mark.

- [ ] **Step 3: Confirm deliberate exclusions**

Run:

```bash
rg -n "CoachWorldTeamLogo" Sources/ProFootballCoachUI/LeagueMapView.swift Sources/ProFootballCoachUI/PlayerProfileView.swift
```

Expected: no league-map use and no replacement of the player-profile jersey mark. A logo may appear elsewhere in the player profile only if it sits beside, not over, the number.

- [ ] **Step 4: Verify and commit**

Run `swift run SimTests --screen-read-models`, `swift run SimTests --design-contracts`, and `swift build`. Run rewrite-tournament, confidence-review, and `detect_changes`, then commit the five explicit view paths as `feat: add compact team logo placements` with the required co-author trailer.

### Task 12: Canon Write-Back, Proofs, Accessibility, and Release Gate

**Files:**
- Modify: `docs/04-UX-AND-DESIGN-SYSTEM.md:162-242`
- Modify: `Tests/SimTests/Suites/TeamLogoTests.swift`
- Modify: `Tests/SimTests/main.swift:160-202`
- Modify: `Tests/ProFootballCoachUITests/ProFootballCoachUITests.swift`

**Interfaces:**
- Consumes: the complete asset set, catalogue, renderer, and placements.
- Produces: permanent default-run gates, screenshot evidence, accessibility evidence, and canon matching the shipped design.

- [ ] **Step 1: Replace the superseded generated-crest canon**

Replace §5.2's code-generated heraldic crest system with the approved rules: one offline AI-generated primary mark for each canonical default-seed UUID, stable catalogue lookup, optional `team.mark`, alternate-seed fallback, no runtime AI/network, unrestricted silhouettes, text-free artwork, and manual similarity review. Preserve §5's colour restraint, recognition, contrast, and custom-universe language.

- [ ] **Step 2: Make the completed logo suites part of the default run**

Add after `runReadModelProviderTests()` in the default branch of `main.swift`:

```swift
runTeamLogoManifestTests()
for family in TeamLogoFamily.allCases {
    runTeamLogoAssetTests(family: family.rawValue)
}
```

Extend the manifest tests to assert all 166 records are approved, the set of `.imageset` directory names exactly equals the manifest asset-name set (catching missing and orphaned assets), and every asset name appears exactly once in `TeamLogoCatalog.generated.swift`. Add a source scan that fails on URL/network/AI terms in the catalogue and renderer files.

Add this 8 x 8 grayscale average-hash helper and compare every pair of approved images:

```swift
private func averageHash(_ image: CGImage) -> UInt64 {
    var pixels = [UInt8](repeating: 0, count: 64)
    let context = CGContext(
        data: &pixels,
        width: 8,
        height: 8,
        bitsPerComponent: 8,
        bytesPerRow: 8,
        space: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: CGImageAlphaInfo.none.rawValue
    )!
    context.interpolationQuality = .low
    context.draw(image, in: CGRect(x: 0, y: 0, width: 8, height: 8))
    let average = pixels.reduce(0) { $0 + Int($1) } / pixels.count
    return pixels.enumerated().reduce(into: UInt64.zero) { result, entry in
        if Int(entry.element) >= average { result |= UInt64(1) << UInt64(entry.offset) }
    }
}

private func hammingDistance(_ lhs: UInt64, _ rhs: UInt64) -> Int {
    (lhs ^ rhs).nonzeroBitCount
}
```

Decode each PNG to `CGImage`, store `(record, averageHash(image))`, and use nested index loops to fail with both team names when Hamming distance is 4 or less. Exact SHA-256 duplicate rejection remains in the family gate. A flagged near-duplicate must be visually reviewed and regenerated before the threshold gate can pass; do not add a silent allowlist.

- [ ] **Step 3: Capture branch and accessibility proofs**

Add XCUITests that set `app.launchEnvironment["PROOF_SCREEN"] = "team-logos"`, launch the existing proof route, and assert both `team-logo-asset-proof` and `team-logo-fallback-proof` exist. Capture attachments for:

```swift
func testTeamLogoAssetAndFallbackProof() {
    let app = XCUIApplication()
    app.launchEnvironment["PROOF_SCREEN"] = "team-logos"
    app.launch()
    XCTAssertTrue(app.otherElements["team-logo-asset-proof"].waitForExistence(timeout: 20))
    XCTAssertTrue(app.otherElements["team-logo-fallback-proof"].exists)
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = "Team logos — packaged and fallback"
    attachment.lifetime = .keepAlways
    add(attachment)
}

func testTeamLogoProofAtAccessibilityType() {
    let app = XCUIApplication()
    app.launchEnvironment["PROOF_SCREEN"] = "team-logos"
    app.launchArguments += [
        "-UIPreferredContentSizeCategoryName",
        "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"
    ]
    app.launch()
    XCTAssertTrue(app.staticTexts["Fallback Team"].waitForExistence(timeout: 20))
    XCTAssertTrue(app.otherElements["team-logo-fallback-proof"].exists)
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = "Team logos — accessibility type"
    attachment.lifetime = .keepAlways
    add(attachment)
}
```

Use the existing production proof environments for representative app surfaces and capture attachments for:

- the all-logo light/dark specimen grid;
- a large team profile/header mark;
- a medium new-career/search/rivalry mark;
- compact scorebug, standings, schedule, rankings, and roster marks;
- the fallback proof using a non-canonical UUID;
- one accessibility Dynamic Type layout and one VoiceOver-labelled screen.

The assertions must continue to find the neighboring team name, score/status text, player number, and league-map markers; the logo itself remains accessibility-hidden.

- [ ] **Step 4: Run the complete verification matrix**

Run:

```bash
swift run -c release SimTests --team-logo-manifest
swift run -c release SimTests --screen-read-models
swift run -c release SimTests --design-contracts
swift build -c release
./scripts/verify.sh
xcodebuild -project App/ProFootballCoach.xcodeproj -scheme ProFootballCoach -configuration Debug -sdk iphonesimulator test
```

Expected: every command exits 0; the logo manifest reports 166 records; all six asset families pass; no screenshot shows a missing asset, clipped mark, duplicated spoken team name, displaced jersey number, or logo-based league-map marker.

- [ ] **Step 5: Perform the final human gate**

Present the final 166-logo grid and representative in-app proofs to the owner. Record concrete review notes for any regenerated mark. Do not claim automated legal clearance; completion requires the owner's final originality and real-team-similarity approval.

- [ ] **Step 6: Final review and commit**

Run rewrite-tournament for the modified test/proof code, confidence-review over every code change, and GitNexus `detect_changes({scope: "compare", base_ref: "main"})`. Fix confirmed issues. Commit only the four task paths as `test: gate canonical team logos` with the required co-author trailer. Do not push unless explicitly requested.

## Completion Checklist

- [ ] 166 canonical UUIDs, 166 manifest records, 166 distinct approved PNGs, and 166 generated catalogue entries match exactly.
- [ ] Every PNG is 256 x 256 with usable transparent edges, inside the byte budget.
- [ ] Every motif family contains 27 or 28 approved marks.
- [ ] Canonical read models receive `mark`; alternate seeds receive `nil`.
- [ ] The reusable component renders packaged art and a legible abbreviation fallback.
- [ ] All approved large, medium, and compact placements retain adjacent text and semantics.
- [ ] League-map dots and player jersey numbers remain unchanged.
- [ ] Light/dark, Dynamic Type, and VoiceOver proofs pass.
- [ ] No runtime AI, prompt, external image URL, or logo network path exists.
- [ ] Final human originality and real-team-similarity review is recorded.
