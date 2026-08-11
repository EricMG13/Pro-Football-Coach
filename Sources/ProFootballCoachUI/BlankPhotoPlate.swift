import SwiftUI

struct CoachWorldBlankPhotoPlate: View {
    let name: String
    let palette: CoachWorldTokens.Palette
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius)
            .fill(palette.raised.color)
            .frame(width: width, height: height)
            .overlay {
                RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius).stroke(
                    palette.contentQuiet.color,
                    lineWidth: CoachWorldTokens.Shape.hairline
                )
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("No photo set for \(name)")
    }
}
