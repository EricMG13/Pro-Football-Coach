import CoreGraphics
import CryptoKit
import Foundation
import FootballSimCore
import ImageIO
import UniformTypeIdentifiers

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

func runTeamLogoManifestExport(
    force: Bool = false,
    to targetURL: URL = teamLogoManifestURL
) throws {
    let state = GameState.bootstrap(seed: 20_260_812)
    let ids = Set(state.programmes.ids).union(state.proTeams.ids)
    let families = TeamLogoFamily.allCases
    let records = ids.sorted { $0.uuidString < $1.uuidString }.enumerated().map { index, id in
        let name = state.programmes[id]?.name
            ?? state.proTeams[id]?.displayName
            ?? "Unknown team"
        let letters = name.filter(\.isLetter)
        let assetName = "TeamLogo_" + id.uuidString.replacingOccurrences(of: "-", with: "")
        return TeamLogoRecord(
            stableID: id.uuidString,
            name: name,
            abbreviation: String(letters.prefix(3)).uppercased(),
            primaryColorHex: state.identities[id].map { "#\($0.colours.primary.hex)" } ?? "",
            secondaryColorHex: state.identities[id].map { "#\($0.colours.secondary.hex)" } ?? "",
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
        at: targetURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    let data = try encoder.encode(manifest)
    if force {
        try data.write(to: targetURL, options: .atomic)
        return
    }
    let temporaryURL = targetURL.deletingLastPathComponent()
        .appendingPathComponent(".\(targetURL.lastPathComponent).\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: temporaryURL) }
    try data.write(to: temporaryURL, options: .atomic)
    try FileManager.default.linkItem(at: temporaryURL, to: targetURL)
}

func runTeamLogoManifestTests() {
    suite("Team logo manifest") {
        test("export defaults to refusal and force regenerates a temporary manifest") {
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("team-logo-export-\(UUID().uuidString)", isDirectory: true)
            let targetURL = directory.appendingPathComponent("manifest.json")
            defer { try? FileManager.default.removeItem(at: directory) }
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let sentinel = Data("do not replace".utf8)
            try sentinel.write(to: targetURL)
            do {
                try runTeamLogoManifestExport(to: targetURL)
                expect(false, "export unexpectedly overwrote the manifest")
            } catch let error as CocoaError {
                expectEqual(error.code, .fileWriteFileExists)
            }
            expectEqual(try Data(contentsOf: targetURL), sentinel)
            try runTeamLogoManifestExport(force: true, to: targetURL)
            expectEqual(try JSONDecoder().decode(TeamLogoManifest.self, from: Data(contentsOf: targetURL)).teams.count, 166)
            let publishedURL = directory.appendingPathComponent("published.json")
            try runTeamLogoManifestExport(to: publishedURL)
            expectEqual(try JSONDecoder().decode(TeamLogoManifest.self, from: Data(contentsOf: publishedURL)).teams.count, 166)
        }
        test("manifest exactly matches the canonical world") {
            let manifest = try loadTeamLogoManifest()
            let world = GameState.bootstrap(seed: manifest.worldSeed)
            let worldIDs = Set(world.programmes.ids).union(world.proTeams.ids).map(\.uuidString)
            let worldNames = Dictionary(uniqueKeysWithValues:
                world.programmes.values.map { ($0.id.uuidString, $0.name) }
                + world.proTeams.values.map { ($0.id.uuidString, $0.displayName) }
            )
            expectEqual(manifest.schemaVersion, 1)
            expectEqual(manifest.worldSeed, 20_260_812)
            expectEqual(manifest.teams.count, 166)
            expectEqual(Set(manifest.teams.map(\.stableID)), Set(worldIDs))
            for team in manifest.teams {
                expectEqual(team.name, worldNames[team.stableID],
                            "manifest display name drifted for \(team.stableID)")
            }
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
        test("all canonical records are approved and match the packaged catalogue") {
            let teams = try loadTeamLogoManifest().teams
            let manifestAssetNames = Set(teams.map(\.assetName))
            expectEqual(teams.count, 166)
            expect(teams.allSatisfy { $0.generationStatus == "approved" && $0.humanApproved })

            let imagesetAssetNames = Set(
                try FileManager.default.contentsOfDirectory(
                    at: teamLogoAssetsURL,
                    includingPropertiesForKeys: nil
                )
                .filter { $0.pathExtension == "imageset" }
                .map { $0.deletingPathExtension().lastPathComponent }
            )
            expectEqual(imagesetAssetNames, manifestAssetNames)

            let catalog = try String(contentsOf: teamLogoCatalogURL, encoding: .utf8)
            for assetName in manifestAssetNames {
                expectEqual(
                    catalog.components(separatedBy: "\"\(assetName)\"").count - 1,
                    1,
                    "catalogue entry count for \(assetName)"
                )
            }
            for team in teams {
                let entry = "\"\(team.stableID)\": \"\(team.assetName)\""
                expectEqual(
                    catalog.components(separatedBy: entry).count - 1,
                    1,
                    "catalogue mapping for \(team.name)"
                )
            }
        }
        test("catalogue and renderer have no runtime external-mark path") {
            let paths = [
                teamLogoCatalogURL,
                URL(fileURLWithPath: "Sources/ProFootballCoachUI/CoachWorldTeamLogo.swift")
            ]
            let forbidden = ["URLSession", "http://", "https://", "network", "prompt"]
            for path in paths {
                let source = try String(contentsOf: path, encoding: .utf8)
                for term in forbidden {
                    expect(!source.localizedCaseInsensitiveContains(term), "\(path.lastPathComponent) contains \(term)")
                }
                expect(source.range(of: #"\bAI\b"#, options: [.regularExpression, .caseInsensitive]) == nil,
                       "\(path.lastPathComponent) contains AI")
            }
        }
        test("no approved PNG is visually near-duplicated") {
            let approved = try loadTeamLogoManifest().teams.filter(\.humanApproved)
            let hashes = approved.compactMap { record -> (TeamLogoRecord, [UInt64])? in
                guard let source = CGImageSourceCreateWithURL(pngURL(for: record) as CFURL, nil),
                      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                    expect(false, "invalid PNG \(record.filename)")
                    return nil
                }
                return (record, colourGradientHash(image))
            }
            expectEqual(hashes.count, approved.count)
            for lhsIndex in hashes.indices {
                for rhsIndex in hashes.indices.dropFirst(lhsIndex + 1) {
                    let lhs = hashes[lhsIndex]
                    let rhs = hashes[rhsIndex]
                    expect(
                        hashDistance(lhs.1, rhs.1) > teamLogoDuplicateThreshold,
                        "near-duplicate marks: \(lhs.0.name) and \(rhs.0.name)"
                    )
                }
            }
        }
        test("every packaged mark stays inside the drawn-size budget") {
            let imagesets = try FileManager.default.contentsOfDirectory(
                at: teamLogoAssetsURL,
                includingPropertiesForKeys: nil
            ).filter { $0.pathExtension == "imageset" }
            expect(!imagesets.isEmpty, "no imagesets under \(teamLogoAssetsURL.path)")

            // The chip never draws larger than its own largest case, so the source only has to
            // cover that many points at 3x. Reading the case back from the renderer means growing
            // the chip fails here rather than shipping a blurred mark.
            let largestDraw = try largestDrawnLogoPointSize()
            expect(largestDraw > 0, "could not read a size case from the renderer")
            expect(teamLogoSourceSide >= largestDraw * 3,
                   "\(teamLogoSourceSide)px source cannot cover a \(largestDraw)pt draw at 3x")

            var catalogueBytes = 0
            for imageset in imagesets.sorted(by: { $0.path < $1.path }) {
                let files = try FileManager.default.contentsOfDirectory(
                    at: imageset,
                    includingPropertiesForKeys: nil
                )
                let pngs = files.filter { $0.pathExtension == "png" }
                expectEqual(pngs.count, 1,
                            "\(imageset.lastPathComponent) packages \(pngs.count) PNGs")
                let contents = try String(
                    contentsOf: imageset.appendingPathComponent("Contents.json"),
                    encoding: .utf8
                )
                expectEqual(contents.components(separatedBy: "\"scale\"").count - 1, 1,
                            "\(imageset.lastPathComponent) declares more than one scale")
                for png in pngs {
                    let bytes = try Data(contentsOf: png).count
                    catalogueBytes += bytes
                    expect(bytes <= teamLogoByteBudget,
                           "\(png.lastPathComponent) is \(bytes) bytes, over "
                               + "\(teamLogoByteBudget)")
                    guard let source = CGImageSourceCreateWithURL(png as CFURL, nil),
                          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                            as? [CFString: Any],
                          let width = properties[kCGImagePropertyPixelWidth] as? Int,
                          let height = properties[kCGImagePropertyPixelHeight] as? Int else {
                        expect(false, "invalid PNG \(png.lastPathComponent)")
                        continue
                    }
                    expect(width <= teamLogoSourceSide && height <= teamLogoSourceSide,
                           "\(png.lastPathComponent) is \(width)x\(height), over "
                               + "\(teamLogoSourceSide)")
                }
            }
            expect(catalogueBytes <= teamLogoCatalogueByteBudget,
                   "packaged marks total \(catalogueBytes) bytes, over "
                       + "\(teamLogoCatalogueByteBudget)")
        }
        test("every mark brief depicts the team it belongs to") {
            // The set this replaced had the Silver Kestrels carrying a compass roundel: the brief
            // was written from the programme's region and never looked at the nickname, so a third
            // of the league wore a mark for a thing it is not named after. Checked against the
            // public name rather than a stored field, because the public name is what a player
            // reads next to the mark.
            for team in try loadTeamLogoManifest().teams {
                guard let noun = team.name.split(separator: " ").last.map(String.init),
                      noun.count > 2 else {
                    expect(false, "\(team.name) has no nickname to draw")
                    continue
                }
                expect(team.prompt.localizedCaseInsensitiveContains(noun),
                       "\(team.name) has a brief that never names its \(noun)")
                expect(team.concept.localizedCaseInsensitiveContains("flat")
                        || team.concept.count > 12,
                       "\(team.name) has an empty-looking concept")
                // The old concepts asked for a place -- "shaped by the Heath landscape of Altus"
                // -- and an image model drew one. Checked on the concept, not the prompt: the
                // prompt names these words on purpose, in the list of things not to draw.
                for scenery in ["landscape", "scenery", "horizon", "backdrop", "shaped by"] {
                    expect(!team.concept.localizedCaseInsensitiveContains(scenery),
                           "\(team.name) still asks for \(scenery) behind the mark")
                }
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

// A 44pt chip at 3x is 132 device pixels, so 256 is the drawn size with headroom to spare.
// The prior 1024px set was 7.8x linear and 60x by area over the largest draw the app ever makes:
// 157 MB packaged and 664 MiB if every mark were decoded at once, against 14 MB and 41 MiB now.
// The budgets sit roughly 40 per cent above the shipped set, which is room for a denser mark
// without being room for a second 1024px catalogue.
let teamLogoSourceSide = 256
let teamLogoByteBudget = 192 * 1024
let teamLogoCatalogueByteBudget = 20 * 1024 * 1024

private let teamLogoAssetsURL = URL(
    fileURLWithPath: "Sources/ProFootballCoachUI/Resources/TeamLogos.xcassets"
)

private let teamLogoRendererURL = URL(
    fileURLWithPath: "Sources/ProFootballCoachUI/CoachWorldTeamLogo.swift"
)

private func largestDrawnLogoPointSize() throws -> Int {
    let source = try String(contentsOf: teamLogoRendererURL, encoding: .utf8)
    let regex = try NSRegularExpression(pattern: #"case\s+\w+\s*=\s*(\d+)"#)
    let range = NSRange(source.startIndex..., in: source)
    return regex.matches(in: source, range: range).compactMap { match in
        Range(match.range(at: 1), in: source).flatMap { Int(source[$0]) }
    }.max() ?? 0
}

private let teamLogoCatalogURL = URL(
    fileURLWithPath: "Sources/ProFootballCoachUI/TeamLogoCatalog.generated.swift"
)

private func pngURL(for team: TeamLogoRecord) -> URL {
    teamLogoAssetsURL
        .appendingPathComponent(team.assetName + ".imageset")
        .appendingPathComponent(team.filename)
}

private func hasTransparentEdgePixel(_ image: CGImage) -> Bool {
    let width = image.width
    let height = image.height
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    guard let context = CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return false }
    context.setBlendMode(.copy)
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    let lastRow = (height - 1) * width
    for x in 0..<width {
        if pixels[x * 4 + 3] == 0 || pixels[(lastRow + x) * 4 + 3] == 0 {
            return true
        }
    }
    for y in 0..<height {
        if pixels[(y * width) * 4 + 3] == 0 || pixels[(y * width + width - 1) * 4 + 3] == 0 {
            return true
        }
    }
    return false
}

// This replaced an 8x8 grayscale average hash on 2026-08-21. That hash thresholded brightness
// against the image's own mean after a `.low` draw, which on a large reduction is closer to point
// sampling than to averaging -- so what separated two marks was high-frequency detail noise, not
// how alike they look. Two consequences, both measured on the shipped set: resample the same art
// to a smaller source and pairs that were far apart collapse together, and replace the `.low` draw
// with a true area average and 117 pairs land within four bits of each other, several of them
// identical. A test that green-lights a set it cannot actually tell apart is not a guard.
//
// A per-channel difference hash compares neighbouring cells instead of an absolute threshold, so
// it reads structure rather than brightness, it does not move when the source resolution changes,
// and it sees colour -- which for a team mark is half the identity. Across the 166 shipped marks
// the closest pair measures 10 of 192 bits, so the threshold below leaves a couple of bits of
// margin while still firing on a mark that is a recolour or a light edit of another, which lands
// far nearer to zero.
let teamLogoDuplicateThreshold = 8

private func colourGradientHash(_ image: CGImage) -> [UInt64] {
    let width = 9
    let height = 8
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    guard let context = CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else {
        expect(false, "cannot build a hashing context")
        return [0, 0, 0]
    }
    // Transparent artwork has to land on a known ground, or the alpha reads as whatever the
    // buffer happened to hold.
    context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return (0..<3).map { channel in
        var bits = UInt64.zero
        var offset = 0
        for y in 0..<height {
            for x in 0..<(width - 1) {
                let left = pixels[(y * width + x) * 4 + channel]
                let right = pixels[(y * width + x + 1) * 4 + channel]
                if left < right { bits |= UInt64(1) << UInt64(offset) }
                offset += 1
            }
        }
        return bits
    }
}

private func hashDistance(_ lhs: [UInt64], _ rhs: [UInt64]) -> Int {
    zip(lhs, rhs).reduce(0) { $0 + ($1.0 ^ $1.1).nonzeroBitCount }
}

func runTeamLogoAssetTests(family rawValue: String) {
    suite("Team logo assets") {
        test("transparent-edge validation reads source alpha") {
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            func image(alpha: UInt8) -> CGImage? {
                guard let provider = CGDataProvider(
                    data: Data([0, 0, 0, alpha]) as CFData
                ) else { return nil }
                guard let sourceImage = CGImage(
                    width: 1,
                    height: 1,
                    bitsPerComponent: 8,
                    bitsPerPixel: 32,
                    bytesPerRow: 4,
                    space: colorSpace,
                    bitmapInfo: CGBitmapInfo(
                        rawValue: CGImageAlphaInfo.premultipliedLast.rawValue
                    ),
                    provider: provider,
                    decode: nil,
                    shouldInterpolate: false,
                    intent: .defaultIntent
                ) else { return nil }
                let pngData = NSMutableData()
                guard let destination = CGImageDestinationCreateWithData(
                    pngData,
                    UTType.png.identifier as CFString,
                    1,
                    nil
                ) else { return nil }
                CGImageDestinationAddImage(destination, sourceImage, nil)
                guard CGImageDestinationFinalize(destination),
                      let source = CGImageSourceCreateWithData(pngData, nil) else { return nil }
                return CGImageSourceCreateImageAtIndex(source, 0, nil)
            }
            guard let transparent = image(alpha: 0), let opaque = image(alpha: 255) else {
                expect(false, "unable to create alpha regression images")
                return
            }
            expect(hasTransparentEdgePixel(transparent))
            expect(!hasTransparentEdgePixel(opaque))
        }
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
                      let sourceType = CGImageSourceGetType(source),
                      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                        as? [CFString: Any],
                      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                    expect(false, "invalid PNG \(record.filename)")
                    continue
                }
                expectEqual(sourceType as String, UTType.png.identifier,
                       "non-PNG source in \(record.filename)")
                expectEqual(properties[kCGImagePropertyPixelWidth] as? Int,
                            Optional(teamLogoSourceSide))
                expectEqual(properties[kCGImagePropertyPixelHeight] as? Int,
                            Optional(teamLogoSourceSide))
                expectEqual(properties[kCGImagePropertyHasAlpha] as? Bool, Optional(true))
                expect(hasTransparentEdgePixel(image), "opaque edge in \(record.filename)")
            }
        }
        test("no approved PNG is reused") {
            let approved = try loadTeamLogoManifest().teams.filter(\.humanApproved)
            var hashes = Set<Data>()
            hashes.reserveCapacity(approved.count)
            for record in approved {
                hashes.insert(Data(SHA256.hash(data: try Data(contentsOf: pngURL(for: record)))))
            }
            expectEqual(hashes.count, approved.count)
        }
    }
}

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
        let source = pngURL(for: team).absoluteString
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
