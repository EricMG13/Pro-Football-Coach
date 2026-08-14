import CoreGraphics
import Foundation
import SwiftUI

/// The film-grain tile.
///
/// Flat vector shapes on flat dark is most of what reads as machine-made, so a single noise tile
/// sits over every screen at low opacity in overlay blend. The noise is generated once from a fixed
/// seed, so the tile is identical between runs and can be cached — the same determinism discipline
/// the engine keeps, for the same reason: a thing that differs per launch cannot be reasoned about.
///
/// The constants below are the noise algorithm's, not design tokens: they describe how the tile is
/// generated, and no surface reads them.
enum CoachWorldGrain {
    static let tile: Image? = makeTile()

    private static func makeTile(side: Int = 128, alpha: UInt8 = 26) -> Image? {
        var bytes = [UInt8](repeating: 0, count: side * side * 4)
        var seed: UInt64 = 0x9E37_79B9_7F4A_7C15

        for index in stride(from: 0, to: bytes.count, by: 4) {
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let noise = Int((seed >> 33) % 75) - 37
            let value = UInt8(clamping: 118 + noise)
            // premultipliedLast: the colour channels must already carry the alpha.
            let premultiplied = UInt8(Int(value) * Int(alpha) / 255)
            bytes[index] = premultiplied
            bytes[index + 1] = premultiplied
            bytes[index + 2] = premultiplied
            bytes[index + 3] = alpha
        }

        let info = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard
            let provider = CGDataProvider(data: Data(bytes) as CFData),
            let image = CGImage(
                width: side, height: side,
                bitsPerComponent: 8, bitsPerPixel: 32,
                bytesPerRow: side * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: info,
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        else { return nil }

        return Image(decorative: image, scale: 1)
    }
}

/// Registry 26 — the grain, dropped over the top of a screen above everything else.
///
/// **Dropped entirely under Reduce Transparency**, per `04` §7: "the grain is dropped and the world
/// is replaced by `world.page`". It carries no information, so removing it costs nothing but the
/// texture — which is the test a decoration has to pass to be permitted at all under §6.1's
/// delete test.
public struct GrainOverlay: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private let opacity: Double

    public init(opacity: Double = CoachWorldTokens.Atmosphere.grainOpacity) {
        self.opacity = opacity
    }

    public var body: some View {
        if !reduceTransparency, let tile = CoachWorldGrain.tile {
            tile
                .resizable(resizingMode: .tile)
                .opacity(opacity)
                .blendMode(.overlay)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}
