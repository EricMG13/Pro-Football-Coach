import Foundation
import ProFootballCoachUI

// Contrast maths, run against the palette's own hex strings so these assertions test the
// values the app actually ships rather than a copy of them. Formulas: WCAG 2.2 §1.4.3.

private func channels(_ hex: String) -> [Double] {
    let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    let value = UInt32(cleaned, radix: 16) ?? 0
    return [(value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF].map { Double($0) / 255 }
}

private func luminance(_ hex: String) -> Double {
    let linear = channels(hex).map { $0 <= 0.03928 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4) }
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
}

private func contrast(_ a: String, _ b: String) -> Double {
    let (high, low) = (max(luminance(a), luminance(b)), min(luminance(a), luminance(b)))
    return (high + 0.05) / (low + 0.05)
}

/// `Chip` draws its label at full strength over a 14 % tint of the same colour, which is a
/// lower-contrast pairing than the card itself — so it has to be checked separately.
private func composite(_ hex: String, over background: String, alpha: Double) -> String {
    let (fore, back) = (channels(hex), channels(background))
    let mixed = (0..<3).map { UInt32((fore[$0] * alpha + back[$0] * (1 - alpha)) * 255) }
    return String(format: "#%02X%02X%02X", mixed[0], mixed[1], mixed[2])
}

// The surfaces a rating is ever drawn on, per theme: grouped card, page background, chip tint.
private let lightSurfaces = ["card": "#FFFFFF", "page": "#F2F2F7"]
private let darkSurfaces = ["card": "#1C1C1E", "page": "#000000"]

func runDesignSystemTests() {
    suite("DesignSystem") {

        test("rating tiers split at the documented band boundaries") {
            let expected: [(Int, RatingTier)] = [
                (40, .fringe), (63, .fringe),
                (64, .rotational), (73, .rotational),
                (74, .starter), (83, .starter),
                (84, .star), (89, .star),
                (90, .elite), (99, .elite),
            ]
            for (rating, tier) in expected {
                expectEqual(RatingTier(rating: rating), tier, "rating \(rating)")
            }
        }

        test("doubles round to the same tier as their integer rating") {
            expectEqual(RatingPalette.tier(for: 73.4), .rotational, "73.4 rounds down")
            expectEqual(RatingPalette.tier(for: 73.6), .starter, "73.6 rounds up")
        }

        // Both parsers here and in `Color(hex:)` fall back silently — to black and to grey
        // respectively — so a typo'd hex would sail through the contrast check below and then
        // render grey on device. Validate the format itself.
        test("tier hexes are well formed") {
            for tier in RatingTier.allCases {
                for hex in [tier.lightHex, tier.darkHex] {
                    expect(hex.hasPrefix("#"), "\(tier) hex \(hex) must be #-prefixed")
                    let digits = hex.dropFirst()
                    expectEqual(digits.count, 6, "\(tier) hex \(hex) must be 6 digits")
                    expect(
                        digits.allSatisfy(\.isHexDigit),
                        "\(tier) hex \(hex) contains a non-hex character"
                    )
                }
            }
        }

        test("every tier clears WCAG AA on every surface it is drawn on") {
            for tier in RatingTier.allCases {
                for (theme, hex, surfaces) in [
                    ("light", tier.lightHex, lightSurfaces),
                    ("dark", tier.darkHex, darkSurfaces),
                ] {
                    var pairings = surfaces
                    pairings["chip"] = composite(hex, over: surfaces["card"]!, alpha: 0.14)
                    for (surface, background) in pairings.sorted(by: { $0.key < $1.key }) {
                        let ratio = contrast(hex, background)
                        expect(
                            ratio >= 4.5,
                            "\(tier) on \(theme) \(surface): \(String(format: "%.2f", ratio)):1 "
                                + "is below the 4.5:1 the project commits to"
                        )
                    }
                }
            }
        }

        // The bands are near-isoluminant by necessity — every one has to be dark enough to
        // clear 4.5:1 on white, which compresses the available lightness range. That means hue
        // is doing all the visual work, so the tier has to be reachable without seeing colour.
        test("tiers are distinguishable without colour") {
            let labels = RatingTier.allCases.map(\.label)
            expectEqual(Set(labels).count, RatingTier.allCases.count, "labels must be unique")
            expect(labels.allSatisfy { !$0.isEmpty }, "every tier needs a spoken label")

            let hexes = RatingTier.allCases.flatMap { [$0.lightHex, $0.darkHex] }
            expectEqual(Set(hexes).count, hexes.count, "no two tiers may share a colour")
        }
    }
}
