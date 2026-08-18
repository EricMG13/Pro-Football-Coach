import SwiftUI

// The management composition `CoachWorldFloodlitStage` lays over its world when a surface passes
// `chrome:` (`04` section 6.1c).
//
// Deliberately not a wrapper type. A surface already calls the stage, so folding the chrome into
// the stage makes conversion a one-line change and keeps ground, world, grain and colour scheme
// under the single owner `AccessibilityReflowTests` already guards.

// MARK: - The stage

/// The container every management surface renders inside.
///
/// Positions are absolute at the install floor, so the composition is the same on every device and
/// only the content column stretches. The whole thing is `.aspectRatio`-fitted to the floor's own
/// proportion for the same reason Match Day is: the design is composed, not reflowed.
struct CoachWorldFloodlitComposition<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let model: FloodlitChromeReadModel
    private let palette: CoachWorldTokens.Palette
    private let onNavigate: (CoachWorldIntentID) -> Void
    private let content: () -> Content

    init(
        model: FloodlitChromeReadModel,
        palette: CoachWorldTokens.Palette = CoachWorldTokens.dark,
        onNavigate: @escaping (CoachWorldIntentID) -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.model = model
        self.palette = palette
        self.onNavigate = onNavigate
        self.content = content
    }

    private var leadingInset: CGFloat {
        model.showsIconRail
            ? CoachWorldTokens.Stage.contentLeading
            : CoachWorldTokens.Stage.railFreeLeading
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                // AX5 keeps the same information and drops the absolute composition: the header
                // becomes a stacked block and the rail becomes a scrollable row, because a 44 pt
                // rail of 7.5 pt labels cannot grow and stay a rail. `04` section 7.
                accessibleLayout
            } else {
                standardLayout
            }
        }
        .accessibilityIdentifier("floodlit-surface")
    }

    private var standardLayout: some View {
        // Content first, chrome over it. The chrome is the frame the surface sits in, so a
        // surface that fills its column must not paint over the identity header — which is exactly
        // what happened when the header was added to the stack before the content.
        ZStack(alignment: .topLeading) {
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, leadingInset)
                .padding(.trailing, CoachWorldTokens.Frame.gutter)
                .padding(.top, CoachWorldTokens.Stage.contentTop)
                .padding(.bottom, CoachWorldTokens.Frame.bottomInset)
                .accessibilitySortPriority(80)

            if model.showsIconRail {
                FloodlitIconRail(
                    entries: model.rail, current: model.screen, palette: palette,
                    onNavigate: onNavigate
                )
                .frame(width: CoachWorldTokens.Stage.railWidth)
                .padding(.leading, CoachWorldTokens.Stage.railLeading)
                .padding(.top, CoachWorldTokens.Stage.railTop)
                .accessibilitySortPriority(40)
            }

            FloodlitIdentityHeader(model: model, palette: palette, onNavigate: onNavigate)
                .frame(width: CoachWorldTokens.Stage.contentWidth, alignment: .leading)
                .padding(.leading, CoachWorldTokens.Stage.contentLeading)
                .padding(.top, CoachWorldTokens.Stage.headerTop)
                .accessibilitySortPriority(100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var accessibleLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.lg) {
                FloodlitIdentityHeader(model: model, palette: palette, onNavigate: onNavigate)
                    .accessibilitySortPriority(100)
                content()
                    .accessibilitySortPriority(80)
                if model.showsIconRail {
                    FloodlitIconRail(
                        entries: model.rail, current: model.screen, palette: palette,
                        onNavigate: onNavigate, axis: .horizontal
                    )
                    .accessibilitySortPriority(40)
                }
            }
            .padding(.horizontal, CoachWorldTokens.Pad.panel.h)
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
    }
}


// MARK: - Conversion seam

/// Lets a surface take the shared chrome without rewriting its public initialiser.
///
/// Both properties carry inline defaults, so an existing explicit `init` keeps compiling untouched
/// and a caller opts in with `.floodlitChrome(_:onNavigate:)`. That is what makes converting a
/// family a one-line change at the call site and a two-line change in the view.
public protocol CoachWorldChromedSurface {
    var chrome: FloodlitChromeReadModel? { get set }
    var onNavigateChrome: ((CoachWorldIntentID) -> Void)? { get set }
}

public extension CoachWorldChromedSurface {
    /// Renders this surface inside the shared management chrome.
    func floodlitChrome(
        _ chrome: FloodlitChromeReadModel?,
        onNavigate: ((CoachWorldIntentID) -> Void)? = nil
    ) -> Self {
        var copy = self
        copy.chrome = chrome
        copy.onNavigateChrome = onNavigate
        return copy
    }
}
