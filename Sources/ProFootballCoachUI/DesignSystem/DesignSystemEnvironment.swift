import SwiftUI

/// The appearance palette, resolved once and read from the environment.
///
/// Every screen carried its own identical `private var palette` — five byte-for-byte copies of
/// `colorScheme == .dark ? .dark : .light`. That is the duplication `CLAUDE.md`'s coverage-boundary
/// rule warns about in a different costume: five places to edit when the resolution rule changes,
/// and nothing that notices when only four of them are edited.
private struct CoachWorldPaletteKey: EnvironmentKey {
    static let defaultValue = CoachWorldTokens.dark
}

/// The state fills for the current appearance.
///
/// `04` §6.1: light appearance has **no separate fill form** — every light ink already clears 4.5:1
/// on all three surfaces, so the ink *is* the fill there. Dark is the only appearance where the two
/// diverge, because its accents sit between the 3:1 and 4.5:1 floors on `raised`.
private struct CoachWorldFillsKey: EnvironmentKey {
    static let defaultValue = CoachWorldTokens.darkFills
}

public extension EnvironmentValues {
    var coachWorldPalette: CoachWorldTokens.Palette {
        get { self[CoachWorldPaletteKey.self] }
        set { self[CoachWorldPaletteKey.self] = newValue }
    }

    var coachWorldFills: CoachWorldTokens.StateFills {
        get { self[CoachWorldFillsKey.self] }
        set { self[CoachWorldFillsKey.self] = newValue }
    }
}

public extension View {
    /// Resolve the palette for the current colour scheme and publish it to the subtree.
    ///
    /// Apply once, at the screen root. Everything below reads `\.coachWorldPalette` rather than
    /// re-deriving it.
    func coachWorldAppearance(_ scheme: ColorScheme) -> some View {
        let palette = scheme == .dark ? CoachWorldTokens.dark : CoachWorldTokens.light
        return environment(\.coachWorldPalette, palette)
            .environment(\.coachWorldFills, CoachWorldTokens.lightHasNoFillForm(scheme))
    }
}

public extension CoachWorldTokens {
    /// The fills for an appearance.
    ///
    /// Named for the rule it encodes rather than for what it returns: in light appearance the ink
    /// is the fill, so this hands back the light inks in fill positions rather than a second set of
    /// values nobody derived. Inventing light fills is exactly the defect the reference sheets
    /// caught during Phase 0b — a table of numbers with no derivation behind them.
    static func lightHasNoFillForm(_ scheme: ColorScheme) -> StateFills {
        guard scheme == .dark else {
            return StateFills(
                live: light.stateLive,
                positive: light.statePositive,
                warning: light.stateWarning,
                info: light.stateInfo,
                collegeIdentity: light.collegeIdentity,
                onFill: light.work
            )
        }
        return darkFills
    }
}
