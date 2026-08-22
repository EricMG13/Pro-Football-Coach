// Resizes the packaged team marks to the size the chip actually draws.
//
//   swift Tools/TeamLogos/downsample.swift            resize every mark in place
//   swift Tools/TeamLogos/downsample.swift --check    report sizes and exit without writing
//
// The catalogue shipped 1024 x 1024 source art for a mark the app never draws larger than 44
// points, which is 132 device pixels at 3x -- 7.8x linear and 60x by area. This is the resize step
// the generation pipeline never had. It is idempotent: a mark already at or below the target is
// left alone, so running it twice does not soften the artwork a second time.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// A 44pt chip at 3x is 132 device pixels; 256 covers it with headroom for a larger future use.
let targetSide = 256

struct Failure: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}

func loadImage(_ url: URL) -> CGImage? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(source, 0, nil)
}

// Alpha is resampled premultiplied so a transparent edge cannot bleed the mark's colour outwards.
func resized(_ image: CGImage, to side: Int) -> CGImage? {
    guard let context = CGContext(data: nil,
                                  width: side,
                                  height: side,
                                  bitsPerComponent: 8,
                                  bytesPerRow: side * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { return nil }
    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
    return context.makeImage()
}

func writePNG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL, UTType.png.identifier as CFString, 1, nil
    ) else { throw Failure("cannot create a PNG destination at \(url.path)") }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw Failure("cannot finalise \(url.lastPathComponent)")
    }
}

let assetsURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Sources/ProFootballCoachUI/Resources/TeamLogos.xcassets")
let checkOnly = CommandLine.arguments.contains("--check")

let imagesets = try FileManager.default.contentsOfDirectory(
    at: assetsURL, includingPropertiesForKeys: nil
).filter { $0.pathExtension == "imageset" }.sorted { $0.path < $1.path }
guard !imagesets.isEmpty else { throw Failure("no imagesets under \(assetsURL.path)") }

var resizedCount = 0
var skipped = 0
var largest = 0
var total = 0
for imageset in imagesets {
    let pngs = try FileManager.default.contentsOfDirectory(
        at: imageset, includingPropertiesForKeys: nil
    ).filter { $0.pathExtension == "png" }
    guard pngs.count == 1, let png = pngs.first else {
        throw Failure("\(imageset.lastPathComponent) packages \(pngs.count) PNGs, expected 1")
    }
    guard let image = loadImage(png) else { throw Failure("cannot decode \(png.path)") }
    guard image.width > targetSide || image.height > targetSide else {
        skipped += 1
        let bytes = try Data(contentsOf: png).count
        largest = max(largest, bytes)
        total += bytes
        continue
    }
    guard image.width == image.height else {
        throw Failure("\(png.lastPathComponent) is \(image.width)x\(image.height), not square")
    }
    if checkOnly {
        resizedCount += 1
        continue
    }
    guard let small = resized(image, to: targetSide) else {
        throw Failure("resize failed for \(png.lastPathComponent)")
    }
    try writePNG(small, to: png)
    let bytes = try Data(contentsOf: png).count
    largest = max(largest, bytes)
    total += bytes
    resizedCount += 1
}

let verb = checkOnly ? "would resize" : "resized"
print("\(verb) \(resizedCount) marks to \(targetSide)x\(targetSide); \(skipped) already inside it")
if !checkOnly {
    print("catalogue \(total / 1024) KB, largest file \(largest / 1024) KB")
}
