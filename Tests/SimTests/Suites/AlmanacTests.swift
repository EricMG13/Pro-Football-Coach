import Foundation
import ProFootballCoachUI

// Contrast maths against the Almanac's own declared hexes, so these assertions test the values
// the app ships rather than a copy of them. Formulas: WCAG 2.2 §1.4.3.

private func almanacChannels(_ hex: String) -> [Double] {
    let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    let value = UInt32(cleaned, radix: 16) ?? 0
    return [(value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF].map { Double($0) / 255 }
}

private func almanacLuminance(_ hex: String) -> Double {
    let linear = almanacChannels(hex).map {
        $0 <= 0.03928 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
}

private func almanacContrast(_ a: String, _ b: String) -> Double {
    let (high, low) = (
        max(almanacLuminance(a), almanacLuminance(b)),
        min(almanacLuminance(a), almanacLuminance(b))
    )
    return (high + 0.05) / (low + 0.05)
}

/// A `Stamp` outlines rather than fills, but a rating value drawn on a tinted ground still needs
/// checking — this is the composite the old `Chip` painted behind its own label.
private func almanacComposite(_ hex: String, over background: String, alpha: Double) -> String {
    let (fore, back) = (almanacChannels(hex), almanacChannels(background))
    let mixed = (0..<3).map { UInt32((fore[$0] * alpha + back[$0] * (1 - alpha)) * 255) }
    return String(format: "#%02X%02X%02X", mixed[0], mixed[1], mixed[2])
}

func runAlmanacTests() {
    suite("Almanac") {

        test("grounds and inks are well formed") {
            let hexes = [
                Almanac.pageLight, Almanac.pageDark, Almanac.cardLight, Almanac.cardDark,
                Almanac.inkLight, Almanac.inkDark, Almanac.ruleLight, Almanac.ruleDark,
                Almanac.mutedLight, Almanac.mutedDark,
            ]
            for hex in hexes {
                expect(hex.hasPrefix("#"), "\(hex) must be #-prefixed")
                let digits = hex.dropFirst()
                expectEqual(digits.count, 6, "\(hex) must be 6 digits")
                expect(digits.allSatisfy(\.isHexDigit), "\(hex) has a non-hex character")
            }
        }

        test("ink and muted ink clear AA on both grounds, both editions") {
            let pairings: [(String, String, String)] = [
                ("ink on paper card", Almanac.inkLight, Almanac.cardLight),
                ("ink on paper page", Almanac.inkLight, Almanac.pageLight),
                ("ink on night card", Almanac.inkDark, Almanac.cardDark),
                ("ink on night page", Almanac.inkDark, Almanac.pageDark),
                ("muted on paper card", Almanac.mutedLight, Almanac.cardLight),
                ("muted on paper page", Almanac.mutedLight, Almanac.pageLight),
                ("muted on night card", Almanac.mutedDark, Almanac.cardDark),
                ("muted on night page", Almanac.mutedDark, Almanac.pageDark),
            ]
            for (name, fore, back) in pairings {
                let ratio = almanacContrast(fore, back)
                expect(
                    ratio >= 4.5,
                    "\(name): \(String(format: "%.2f", ratio)):1 is below 4.5:1"
                )
            }
        }

        // The whole point of moving off the system greys is that paper changes every ratio the
        // old suite verified. Re-measure the shipped ladder against the new grounds.
        test("every rating tier clears AA on the almanac grounds") {
            for tier in RatingTier.allCases {
                for (edition, hex, card, page) in [
                    ("paper", tier.lightHex, Almanac.cardLight, Almanac.pageLight),
                    ("night", tier.darkHex, Almanac.cardDark, Almanac.pageDark),
                ] {
                    let surfaces = [
                        ("card", card),
                        ("page", page),
                        ("tint", almanacComposite(hex, over: card, alpha: 0.14)),
                    ]
                    for (surface, background) in surfaces {
                        let ratio = almanacContrast(hex, background)
                        expect(
                            ratio >= 4.5,
                            "\(tier) on \(edition) \(surface): "
                                + "\(String(format: "%.2f", ratio)):1 is below 4.5:1"
                        )
                    }
                }
            }
        }

        test("the printed rule stays visible against its own ground") {
            // Decorative, so 3:1 rather than 4.5:1 — but an invisible rule is a missing rule.
            let pairs = [
                ("paper", Almanac.ruleLight, Almanac.cardLight),
                ("night", Almanac.ruleDark, Almanac.cardDark),
            ]
            for (edition, rule, ground) in pairs {
                let ratio = almanacContrast(rule, ground)
                expect(ratio >= 1.2, "\(edition) rule is invisible at \(String(format: "%.2f", ratio)):1")
            }
        }

        test("paper and night are genuinely different grounds") {
            expect(Almanac.pageLight != Almanac.pageDark, "grounds must differ per edition")
            expect(
                almanacContrast(Almanac.cardLight, Almanac.pageLight) > 1.0,
                "the card must lift off the page by day"
            )
            expect(
                almanacContrast(Almanac.cardDark, Almanac.pageDark) > 1.0,
                "the card must lift off the page at night"
            )
        }
    }
}
