import CoachWorldApp
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

/// The mark inventory, keyed by the nickname each mark depicts.
///
/// Schema 2. Schema 1 was an inventory of *teams*, keyed by a team identifier — and an identifier
/// is a position in the generated random stream, so every change to generation re-keyed the whole
/// catalogue and left marks filed against teams that no longer existed. It also meant the app
/// resolved a mark at exactly one seed. A nickname is drawn from a fixed pool, so it survives both.
struct TeamLogoManifest: Codable {
    let schemaVersion: Int
    var marks: [TeamLogoMark]
}

struct TeamLogoMark: Codable {
    let nickname: String
    var family: TeamLogoFamily
    var concept: String
    var prompt: String
    /// The two flats the artwork was drawn in. Empty until it is drawn.
    var paletteHex: [String]
    /// Nil while the brief has no artwork behind it.
    let assetName: String?
    let filename: String?
    var generationStatus: String
    var humanApproved: Bool
    var reviewNotes: String

    /// Drawn, and adopted by the owner. Only these reach the app.
    var isDrawn: Bool { generationStatus == "approved" && humanApproved }
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

func runTeamLogoManifestTests() {
    suite("Team logo manifest") {
        test("every brief depicts the nickname it is filed under") {
            // The set this replaced had the Silver Kestrels carrying a compass roundel: the brief
            // was written from the programme's region and never looked at the nickname, so a third
            // of the league wore a mark for a thing it is not named after.
            for mark in try loadTeamLogoManifest().marks {
                expect(mark.prompt.localizedCaseInsensitiveContains(mark.nickname),
                       "a \(mark.nickname) brief never names its \(mark.nickname)")
                expect(mark.concept.count > 12, "\(mark.nickname) has an empty-looking concept")
                // The old concepts asked for a place -- "shaped by the Heath landscape of Altus"
                // -- and an image model drew one. Checked on the concept, not the brief: the brief
                // names these words on purpose, in the list of things not to draw.
                for scenery in ["landscape", "scenery", "horizon", "backdrop", "shaped by"] {
                    expect(!mark.concept.localizedCaseInsensitiveContains(scenery),
                           "\(mark.nickname) still asks for \(scenery) behind the mark")
                }
            }
        }
        test("the nickname pool and the manifest cover each other") {
            // Enumerated from the grammar rather than listed here, so a noun added to the pool
            // fails on the day it is added instead of the day somebody remembers the artwork.
            // That is the whole difference between a coverage boundary and a quality boundary.
            let pool = Set(NameGrammar.nicknameNounVocabulary)
            let marks = try loadTeamLogoManifest().marks
            let briefed = Set(marks.map(\.nickname))
            expect(!pool.isEmpty, "the nickname pool read back empty")
            for noun in pool.sorted() {
                expect(briefed.contains(noun), "no mark is briefed for the \(noun)")
            }
            for noun in briefed.sorted() {
                expect(pool.contains(noun),
                       "\(noun) marks are briefed for a nickname nothing can generate")
            }
        }
        test("every team in a generated world wears a mark drawn for its nickname") {
            // The gate the old suite could not hold: it compared the manifest against itself, so a
            // team wearing somebody else's mark only showed up as a name mismatch, and only at the
            // one seed the manifest was keyed to. This asks the app's own resolution path, at four
            // seeds, what each of 166 teams would actually be shown.
            let marks = try loadTeamLogoManifest().marks
            let pool = Set(NameGrammar.nicknameNounVocabulary)
            var drawnFor: [String: Set<String>] = [:]
            for mark in marks where mark.isDrawn {
                drawnFor[mark.nickname, default: []].insert(mark.assetName ?? "")
            }
            for seed in [20_260_812, 20_260_813, 7, 1_999] as [UInt64] {
                let results = CoachWorldReadModelProvider
                    .worldSearch(from: GameState.bootstrap(seed: seed)).results
                expect(!results.isEmpty, "seed \(seed) generated no teams")
                // Teams sharing a nickname pick among its marks by a hash of their identifier's
                // bytes, so more marks are worn than there are nicknames to wear them. A resolver
                // that lost the index and always took the first would land exactly on equality.
                var worn: Set<String> = []
                var nicknamesWorn: Set<String> = []
                for result in results {
                    let noun = String(result.team.name.split(separator: " ").last ?? "")
                    // Read off the public name, while the app reads it off the stored nickname.
                    // Two independent routes to the same noun, so a name that stops ending in its
                    // nickname fails here instead of quietly resolving to no mark at all.
                    expect(pool.contains(noun),
                           "\(result.team.name) does not end in a nickname the pool can emit")
                    guard let assets = drawnFor[noun] else {
                        expect(result.team.mark == nil,
                               "\(result.team.name) wears a mark and no \(noun) is drawn")
                        continue
                    }
                    guard let mark = result.team.mark else {
                        expect(false, "\(result.team.name) wears nothing and \(noun) marks exist")
                        continue
                    }
                    expect(assets.contains(mark.assetName),
                           "\(result.team.name) wears \(mark.assetName), briefed for another "
                               + "nickname")
                    expectEqual(mark.stableID, result.team.stableID)
                    worn.insert(mark.assetName)
                    nicknamesWorn.insert(noun)
                }
                expect(worn.count > nicknamesWorn.count,
                       "seed \(seed) wears \(worn.count) marks over \(nicknamesWorn.count) "
                           + "nicknames, so the mark never varies within one")
            }
        }
        test("drawn records match the packaged catalogue") {
            let marks = try loadTeamLogoManifest().marks
            let drawn = marks.filter(\.isDrawn)
            expect(!drawn.isEmpty, "no mark is drawn")
            let manifestAssetNames = Set(drawn.compactMap(\.assetName))
            expectEqual(manifestAssetNames.count, drawn.count)

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
            for nickname in Set(drawn.map(\.nickname)) {
                expectEqual(
                    catalog.components(separatedBy: "\"\(nickname)\": [").count - 1,
                    1,
                    "catalogue key for \(nickname)"
                )
            }
        }
        test("a brief with no artwork claims none") {
            for mark in try loadTeamLogoManifest().marks where !mark.isDrawn {
                expectEqual(mark.generationStatus, "pending")
                expect(!mark.humanApproved)
                expectEqual(mark.assetName, nil, "\(mark.nickname) names an asset it has not got")
                expectEqual(mark.filename, nil)
                expect(mark.paletteHex.isEmpty)
                expect(!mark.reviewNotes.trimmingCharacters(in: .whitespaces).isEmpty,
                       "\(mark.nickname) is outstanding and says nothing about why")
            }
        }
        test("briefs are complete and name no real competition") {
            let manifest = try loadTeamLogoManifest()
            expectEqual(manifest.schemaVersion, 2)
            for mark in manifest.marks {
                expect(!mark.nickname.isEmpty)
                expect(!mark.prompt.trimmingCharacters(in: .whitespaces).isEmpty)
                expect(!mark.concept.trimmingCharacters(in: .whitespaces).isEmpty)
                expect(!mark.reviewNotes.trimmingCharacters(in: .whitespaces).isEmpty)
                for competition in ["NFL", "NBA", "MLB", "NHL"] {
                    expect(!mark.prompt.localizedCaseInsensitiveContains(competition),
                           "a \(mark.nickname) brief names \(competition)")
                }
                guard mark.isDrawn else { continue }
                expectEqual(mark.paletteHex.count, 2)
                expect(mark.paletteHex.allSatisfy { $0.count == 7 })
                expectEqual(mark.filename, mark.assetName.map { $0 + ".png" })
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
        test("no drawn PNG is visually near-duplicated") {
            let drawn = try loadTeamLogoManifest().marks.filter(\.isDrawn)
            let hashes = drawn.compactMap { mark -> (TeamLogoMark, [UInt64])? in
                guard let url = pngURL(for: mark),
                      let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                    expect(false, "invalid PNG \(mark.filename ?? mark.nickname)")
                    return nil
                }
                return (mark, colourGradientHash(image))
            }
            expectEqual(hashes.count, drawn.count)
            for lhsIndex in hashes.indices {
                for rhsIndex in hashes.indices.dropFirst(lhsIndex + 1) {
                    let lhs = hashes[lhsIndex]
                    let rhs = hashes[rhsIndex]
                    expect(
                        hashDistance(lhs.1, rhs.1) > teamLogoDuplicateThreshold,
                        "near-duplicate marks: \(lhs.0.assetName ?? "") and "
                            + "\(rhs.0.assetName ?? "")"
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
        test("no motif family takes over the set") {
            // A fraction rather than a count. The old bound was 27-or-28 of 166, which was really
            // an assertion about how many teams there are; what matters to a league map is that no
            // one shape swallows the set, and that no shape has fallen out of it.
            let marks = try loadTeamLogoManifest().marks
            for family in TeamLogoFamily.allCases {
                let count = marks.filter { $0.family == family }.count
                expect(count > 0, "\(family.rawValue) has no marks")
                expect(count * 3 <= marks.count,
                       "\(family.rawValue) holds \(count) of \(marks.count) marks")
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

private func pngURL(for mark: TeamLogoMark) -> URL? {
    guard let assetName = mark.assetName, let filename = mark.filename else { return nil }
    return teamLogoAssetsURL
        .appendingPathComponent(assetName + ".imageset")
        .appendingPathComponent(filename)
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
        test("requested family is accounted for") {
            guard let family = TeamLogoFamily(rawValue: rawValue) else {
                expect(false, "unknown family \(rawValue)")
                return
            }
            let records = try loadTeamLogoManifest().marks.filter { $0.family == family }
            expect(!records.isEmpty, "\(rawValue) holds no marks")
            // Drawn or pending, and never a third state: a record that is approved without
            // artwork, or carries artwork without approval, is the one nobody can tell apart by
            // looking at the app.
            expect(records.allSatisfy { $0.isDrawn == ($0.assetName != nil) })
            expect(records.allSatisfy { !$0.reviewNotes.isEmpty })
        }
        test("requested family PNGs are square alpha images with transparent edges") {
            guard let family = TeamLogoFamily(rawValue: rawValue) else { return }
            let records = try loadTeamLogoManifest().marks
                .filter { $0.family == family && $0.isDrawn }
            for record in records {
                guard let url = pngURL(for: record) else {
                    expect(false, "a drawn \(record.nickname) mark names no asset")
                    continue
                }
                expect(FileManager.default.fileExists(atPath: url.path), "missing \(url.path)")
                guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                      let sourceType = CGImageSourceGetType(source),
                      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                        as? [CFString: Any],
                      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                    expect(false, "invalid PNG \(record.filename ?? record.nickname)")
                    continue
                }
                expectEqual(sourceType as String, UTType.png.identifier,
                       "non-PNG source in \(record.filename ?? record.nickname)")
                expectEqual(properties[kCGImagePropertyPixelWidth] as? Int,
                            Optional(teamLogoSourceSide))
                expectEqual(properties[kCGImagePropertyPixelHeight] as? Int,
                            Optional(teamLogoSourceSide))
                expectEqual(properties[kCGImagePropertyHasAlpha] as? Bool, Optional(true))
                expect(hasTransparentEdgePixel(image),
                       "opaque edge in \(record.filename ?? record.nickname)")
            }
        }
        test("no drawn PNG is reused") {
            let drawn = try loadTeamLogoManifest().marks.filter(\.isDrawn)
            var hashes = Set<Data>()
            hashes.reserveCapacity(drawn.count)
            for record in drawn {
                guard let url = pngURL(for: record) else { continue }
                hashes.insert(Data(SHA256.hash(data: try Data(contentsOf: url))))
            }
            expectEqual(hashes.count, drawn.count)
        }
    }
}

func writeTeamLogoSpecimen(family rawValue: String) throws {
    let drawn = try loadTeamLogoManifest().marks.filter(\.isDrawn)
    let marks: [TeamLogoMark]
    if rawValue == "all" {
        marks = drawn
    } else if let family = TeamLogoFamily(rawValue: rawValue) {
        marks = drawn.filter { $0.family == family }
    } else {
        fatalError("unknown team-logo family \(rawValue)")
    }
    let cards = marks.sorted {
        ($0.nickname, $0.assetName ?? "") < ($1.nickname, $1.assetName ?? "")
    }.compactMap { mark -> String? in
        guard let source = pngURL(for: mark)?.absoluteString else { return nil }
        return """
        <article><h2>\(mark.nickname)</h2>
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
