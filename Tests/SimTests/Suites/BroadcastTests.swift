import Foundation
import FootballSimCore
import ProFootballCoachUI

// The Broadcast skin puts grounds and text back on the system semantic set, so their contrast is
// the platform's guarantee rather than ours. What still ships as fixed hexes is the rating
// ladder, and that is what this suite measures — against the real system surfaces it is drawn on.

private func broadcastChannels(_ hex: String) -> [Double] {
    let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    let value = UInt32(cleaned, radix: 16) ?? 0
    return [(value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF].map { Double($0) / 255 }
}

private func broadcastLuminance(_ hex: String) -> Double {
    let linear = broadcastChannels(hex).map {
        $0 <= 0.03928 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
}

private func broadcastContrast(_ a: String, _ b: String) -> Double {
    let (high, low) = (
        max(broadcastLuminance(a), broadcastLuminance(b)),
        min(broadcastLuminance(a), broadcastLuminance(b))
    )
    return (high + 0.05) / (low + 0.05)
}

/// A `Stamp` paints its label over a wash of its own colour at `Broadcast.chipTint`.
private func broadcastComposite(_ hex: String, over background: String, alpha: Double) -> String {
    let (fore, back) = (broadcastChannels(hex), broadcastChannels(background))
    let mixed = (0..<3).map { UInt32((fore[$0] * alpha + back[$0] * (1 - alpha)) * 255) }
    return String(format: "#%02X%02X%02X", mixed[0], mixed[1], mixed[2])
}

// systemGroupedBackground and its secondary, the surfaces the skin actually draws on.
private let lightGrounds = ["card": "#FFFFFF", "page": "#F2F2F7"]
private let darkGrounds = ["card": "#1C1C1E", "page": "#000000"]

func runBroadcastTests() {
    suite("Broadcast") {

        test("rating tier hexes are well formed") {
            for tier in RatingTier.allCases {
                for hex in [tier.lightHex, tier.darkHex] {
                    expect(hex.hasPrefix("#"), "\(tier) hex \(hex) must be #-prefixed")
                    let digits = hex.dropFirst()
                    expectEqual(digits.count, 6, "\(tier) hex \(hex) must be 6 digits")
                    expect(digits.allSatisfy(\.isHexDigit), "\(tier) hex \(hex) is not hex")
                }
            }
        }

        // The chip tint is the binding case: a label at full strength over a 14 % wash of itself
        // is a lower-contrast pairing than the card, and it is what every Stamp draws.
        test("every rating tier clears AA on the surfaces it is drawn on") {
            for tier in RatingTier.allCases {
                for (mode, hex, grounds) in [
                    ("light", tier.lightHex, lightGrounds),
                    ("dark", tier.darkHex, darkGrounds),
                ] {
                    var pairings = grounds
                    pairings["chip"] = broadcastComposite(
                        hex, over: grounds["card"]!, alpha: Broadcast.chipTint
                    )
                    for (surface, background) in pairings.sorted(by: { $0.key < $1.key }) {
                        let ratio = broadcastContrast(hex, background)
                        expect(
                            ratio >= 4.5,
                            "\(tier) on \(mode) \(surface): "
                                + "\(String(format: "%.2f", ratio)):1 is below 4.5:1"
                        )
                    }
                }
            }
        }

        test("the tiers stay distinguishable without colour") {
            let labels = RatingTier.allCases.map(\.label)
            expectEqual(Set(labels).count, RatingTier.allCases.count, "labels must be unique")
            expect(labels.allSatisfy { !$0.isEmpty }, "every tier needs a spoken label")
        }

        // A club's mark must not change under it between launches, or the league loses its faces.
        test("a team's motif is stable and spread across the set") {
            for abbreviation in ["NYE", "BOS", "PIT", "MIA"] {
                let first = TeamMark.Motif.forAbbreviation(abbreviation)
                let second = TeamMark.Motif.forAbbreviation(abbreviation)
                expectEqual(first, second, "\(abbreviation) must always draw the same mark")
            }

            let all = TeamTable.entries.map { TeamMark.Motif.forAbbreviation($0.abbreviation) }
            expectEqual(all.count, 32, "every club gets a mark")
            expect(
                Set(all).count >= 4,
                "32 clubs should not collapse onto \(Set(all).count) motif(s)"
            )
        }

        // Judge the colour the mark actually draws, not the raw table value: two colours can
        // differ in hue and share a luminance, which is exactly the case legibleMotif exists for.
        test("every club's motif is visible on its own field") {
            for entry in TeamTable.entries {
                let motif = TeamMark.legibleMotif(entry.secondaryHex, on: entry.primaryHex)
                let ratio = broadcastContrast(motif, entry.primaryHex)
                expect(
                    ratio >= 1.6,
                    "\(entry.abbreviation) motif is invisible on its field at "
                        + "\(String(format: "%.2f", ratio)):1"
                )
            }
        }

        test("a club whose colours already work is left alone") {
            // Empire: navy field, gold trim — nothing to correct.
            expectEqual(
                TeamMark.legibleMotif("#C8A24A", on: "#14294B"),
                "#C8A24A",
                "a legible pair must pass through untouched"
            )
        }
    }
}
