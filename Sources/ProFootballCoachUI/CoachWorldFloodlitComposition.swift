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
    @State private var showingSurfaceRegistry = false

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
        ZStack {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    // AX5 keeps the same information and drops the absolute composition: the header
                    // becomes a stacked block and the rail becomes a scrollable row. `04` section 7.
                    accessibleLayout
                } else {
                    standardLayout
                }
            }
            if showingSurfaceRegistry {
                SurfaceRegistryOverlay(
                    current: model.screen,
                    palette: palette,
                    availableScreens: model.availableScreens,
                    onSelect: { screen in
                        showingSurfaceRegistry = false
                        onNavigate(CoachWorldIntentID(rawValue: "route|\(screen.rawValue)"))
                    },
                    onClose: { showingSurfaceRegistry = false }
                )
                .zIndex(10)
            }
        }
        .accessibilityIdentifier("floodlit-surface")
    }

    private var registryOpener: () -> Void {
        { showingSurfaceRegistry = true }
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
                    onNavigate: onNavigate, onOpenRegistry: registryOpener
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

    /// AX5 keeps the same information and drops the absolute composition.
    ///
    /// Deliberately **not** a `ScrollView`. Every converted surface already scrolls its own
    /// accessible layout, and wrapping that in a second scroll view nests two vertical scrollers —
    /// the inner one swallows the drag and the header above it becomes unreachable. The header and
    /// the rail are fixed here and the content scrolls itself.
    private var accessibleLayout: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.lg) {
            FloodlitIdentityHeader(model: model, palette: palette, onNavigate: onNavigate)
                .accessibilitySortPriority(100)
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .accessibilitySortPriority(80)
            if model.showsIconRail {
                FloodlitIconRail(
                    entries: model.rail, current: model.screen, palette: palette,
                    onNavigate: onNavigate, onOpenRegistry: registryOpener, axis: .horizontal
                )
                .accessibilitySortPriority(40)
            }
        }
        .padding(.horizontal, CoachWorldTokens.Pad.panel.h)
        .padding(.vertical, CoachWorldTokens.Pad.panel.v)
    }
}

private struct SurfaceRegistryOverlay: View {
    let current: CoachWorldScreenID
    let palette: CoachWorldTokens.Palette
    let availableScreens: [CoachWorldScreenID]
    let onSelect: (CoachWorldScreenID) -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            CoachWorldTokens.Floodlit.overlayScrim.color.opacity(0.97)
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                            Text("ALL TASKS")
                                .font(CoachWorldTokens.TypeRole.display.weight(.black))
                            Text("\(availableScreens.filter { $0.isCanonicalTask }.count) available tasks")
                                .font(CoachWorldTokens.TypeRole.caption)
                                .foregroundStyle(palette.contentSecondary.color)
                        }
                        Spacer(minLength: CoachWorldTokens.Space.sm)
                        Button("Close", action: onClose)
                            .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
                    }

                    ForEach(CoachWorldSurfaceFamily.allCases, id: \.rawValue) { family in
                        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xxs) {
                            Text(family.canonicalName.uppercased())
                                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                                .foregroundStyle(palette.actionPrimary.color)
                            ForEach(
                                family.surfaces.filter { availableScreens.contains($0) },
                                id: \.rawValue
                            ) { screen in
                                Button {
                                    onSelect(screen)
                                } label: {
                                    HStack(spacing: CoachWorldTokens.Space.sm) {
                                        Text("\(screen.number)")
                                            .monospacedDigit()
                                            .foregroundStyle(palette.actionPrimary.color)
                                            .frame(width: 28, alignment: .trailing)
                                        Text(screen.taskName)
                                            .foregroundStyle(palette.contentPrimary.color)
                                        Spacer(minLength: .zero)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget,
                                           alignment: .leading)
                                    .padding(.horizontal, CoachWorldTokens.Space.sm)
                                    .background(
                                        screen == current
                                            ? palette.actionPrimary.color.opacity(0.14)
                                            : palette.raised.color.opacity(0.55)
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(screen.canonicalName)
                                .accessibilityAddTraits(screen == current ? .isSelected : [])
                            }
                        }
                    }
                }
                .padding(CoachWorldTokens.Space.xl)
                .frame(maxWidth: 720, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .accessibilitySortPriority(200)
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
