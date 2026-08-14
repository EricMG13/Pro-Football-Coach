import SwiftUI

/// Registry 4 — the neutral person plate.
///
/// The product ships no portraits and generates no faces, so the plate is the honest form of that
/// rather than an empty gap: it says a person belongs here and that no likeness exists, and it says
/// so to VoiceOver too. Any future custom-universe importer preserves this as the fallback.
public struct CoachWorldBlankPhotoPlate: View {
    @Environment(\.coachWorldPalette) private var environmentPalette

    private let name: String
    private let explicitPalette: CoachWorldTokens.Palette?
    private let width: CGFloat
    private let height: CGFloat

    public init(
        name: String,
        palette: CoachWorldTokens.Palette? = nil,
        width: CGFloat,
        height: CGFloat
    ) {
        self.name = name
        explicitPalette = palette
        self.width = width
        self.height = height
    }

    private var palette: CoachWorldTokens.Palette { explicitPalette ?? environmentPalette }

    public var body: some View {
        CutCorner.row
            .fill(palette.raised.color)
            .frame(width: width, height: height)
            .overlay {
                CutCorner.row.strokeBorder(
                    palette.contentQuiet.color,
                    lineWidth: CoachWorldTokens.Shape.hairline
                )
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("No photo set for \(name)")
    }
}
