import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum CoachWorldTeamLogoSize: CGFloat {
    case compact = 20
    case medium = 32
    case large = 44
}

struct CoachWorldTeamLogo: View {
    let team: CoachWorldTeamReference
    let size: CoachWorldTeamLogoSize
    let surface: CoachWorldTokens.ColorValue
    var palette: CoachWorldTokens.Palette = CoachWorldTokens.dark
    var isDecorative = true

    var body: some View {
        Group {
            if let image = packagedImage {
                image.resizable().scaledToFit()
            } else {
                fallback
            }
        }
        .frame(width: size.rawValue, height: size.rawValue)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(team.name)
        .accessibilityHidden(isDecorative)
    }

    private var packagedImage: Image? {
        guard let name = team.mark?.assetName else { return nil }
        #if canImport(UIKit)
        if let image = UIImage(named: name, in: .module, compatibleWith: nil) {
            return Image(uiImage: image)
        }
        guard let url = packagedResourceURL(for: name),
              let image = UIImage(contentsOfFile: url.path) else { return nil }
        return Image(uiImage: image)
        #elseif canImport(AppKit)
        if let image = Bundle.module.image(forResource: NSImage.Name(name)) {
            return Image(nsImage: image)
        }
        guard let url = packagedResourceURL(for: name),
              let image = NSImage(contentsOf: url) else { return nil }
        return Image(nsImage: image)
        #else
        return nil
        #endif
    }

    private func packagedResourceURL(for name: String) -> URL? {
        Bundle.module.url(
            forResource: name,
            withExtension: "png",
            subdirectory: "TeamLogos.xcassets/\(name).imageset"
        )
    }

    private var fallback: some View {
        let identity = CoachWorldTeamIdentity(
            team: team,
            behind: surface,
            inks: [palette.contentPrimary, palette.page]
        )
        return Text(team.abbreviation)
            .font(CoachWorldTokens.TypeRole.caption.weight(.black))
            .minimumScaleFactor(0.65)
            .foregroundStyle((identity?.onField ?? palette.contentPrimary).color)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                (identity?.field ?? palette.raised).color,
                in: CoachWorldCutCorner.chip
            )
    }
}
