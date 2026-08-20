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
            ?? state.proTeams[id].map { "\($0.cityName) \($0.nickname)" }
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
                expectEqual(properties[kCGImagePropertyPixelWidth] as? Int, Optional(1024))
                expectEqual(properties[kCGImagePropertyPixelHeight] as? Int, Optional(1024))
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
