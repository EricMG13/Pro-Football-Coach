import SwiftUI

/// Device reference values — `04` §7.
///
/// **`previewWindow` is a preview reference frame and nothing else.** `04` §7 is explicit: it is
/// "never a layout constraint, never a `.frame(width:height:)` on a screen, and no view resolves a
/// position against it". Floodlit shipped it as `Metrics.device` and then pinned every screen to it
/// through `DeviceFrame`, which is the one structural change the import had to make: production
/// promises 852 × 393 through 956 × 440 with an install floor of 844 × 390, so a screen laid out
/// against a single rect is wrong on four of the five supported windows.
///
/// The per-model safe-area insets Floodlit hard-coded (`sensor: 59`, `home: 21`) are **not** carried
/// over. They are the iPhone 15 Pro's, they vary per model, and `04` §7 records two classes as
/// unsourced gaps. `Stage` reads the real insets instead.
public enum CoachWorldMetrics {
    /// The install floor, for previews only. Production reads the window it is given.
    public static let previewWindow = CGSize(width: 844, height: 390)

    /// The default breathing room above content, when the safe area does not already provide more.
    public static let stageTop: CGFloat = CoachWorldTokens.Space.lg
}

/// Registry 28 — the safe-area-owning content inset.
///
/// Owns physical edges rather than a preferred orientation: in landscape the sensor housing is on
/// one long edge and the home indicator on the other, and which is which depends on how the phone
/// is held. Reading `safeAreaInsets` is the only way to be right in both sensor orientations, which
/// `04` §7 makes binding.
public struct Stage<Content: View>: View {
    private let top: CGFloat
    private let content: Content

    public init(
        top: CGFloat = CoachWorldMetrics.stageTop,
        @ViewBuilder content: () -> Content
    ) {
        self.top = top
        self.content = content()
    }

    public var body: some View {
        GeometryReader { proxy in
            let safe = proxy.safeAreaInsets
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, max(safe.top, top))
                .padding(.leading, safe.leading)
                .padding(.trailing, safe.trailing)
                .padding(.bottom, safe.bottom)
        }
    }
}

#if DEBUG
/// A fixed-size frame for previews, so a canvas renders at a real supported window.
///
/// DEBUG-only by construction: this is the type Floodlit's `DeviceFrame` becomes, and confining it
/// to debug builds is what stops the 844 × 390 pin from returning to production layout by habit.
/// Pass any of `04` §7's five verified windows.
public struct CoachWorldPreviewFrame<Content: View>: View {
    private let size: CGSize
    private let content: Content

    public init(
        _ size: CGSize = CoachWorldMetrics.previewWindow,
        @ViewBuilder content: () -> Content
    ) {
        self.size = size
        self.content = content()
    }

    public var body: some View {
        content
            .frame(width: size.width, height: size.height)
            .clipped()
    }
}
#endif
