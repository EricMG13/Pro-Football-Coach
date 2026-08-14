import SwiftUI

/// Registry 23 — the failure set, drawn **inside the composition it belongs to**.
///
/// `04` §7: "Empty, error, interrupted and resume states remain inside the composition they belong
/// to." A failure drawn as a floating full-screen apology strips the frame of visible team,
/// opponent, season, person, place, football object and consequence — the application-slop
/// rejection of §4.4. So none of these types owns a screen: each replaces one region and leaves
/// the chrome above it exactly as the working surface draws it.
///
/// `ErrorBanner` and `InterruptedState` **did not exist in any form**. Errors were a
/// `statusMessage: String?` threaded into five different world-strip context lines, which meant a
/// failed write and a routing message read identically and neither offered recovery.

// MARK: - EmptyState

/// A region with nothing in it — which is not the same as a region that failed.
///
/// States three things and nothing else: **what** is empty, **why** (a cause the simulation owns,
/// never display copy), and **the one action that fills it**. The mark orients; the words inform.
/// `04` §6.6 bounds the Empty-state marks class at six and holds it deliberately *not* learned,
/// because every empty state carries a title and a description sentence.
public struct EmptyState: View {
    public enum Mark: Sendable {
        case people, person, list, complete

        var symbol: String {
            switch self {
            case .people: "person.3"
            case .person: "person.crop.rectangle"
            case .list: "list.number"
            case .complete: "checkmark.circle"
            }
        }
    }

    @Environment(\.coachWorldPalette) private var palette

    private let mark: Mark
    private let title: String
    private let cause: String
    private let actionTitle: String?
    private let onAct: (() -> Void)?

    /// - Parameters:
    ///   - cause: why it is empty, from the simulation — "Player Eleven and Player Twenty-Six are
    ///     out injured", not "No results found".
    ///   - actionTitle: the one action that fills it. One, not a menu.
    public init(
        mark: Mark,
        title: String,
        cause: String,
        actionTitle: String? = nil,
        onAct: (() -> Void)? = nil
    ) {
        self.mark = mark
        self.title = title
        self.cause = cause
        self.actionTitle = actionTitle
        self.onAct = onAct
    }

    public var body: some View {
        VStack(spacing: CoachWorldTokens.Space.xs) {
            Image(systemName: mark.symbol)
                .foregroundStyle(palette.contentQuiet.color)
                .accessibilityHidden(true)
            Text(title)
                .font(CoachWorldTokens.TypeRole.headline)
                .foregroundStyle(palette.contentPrimary.color)
                .multilineTextAlignment(.center)
            Text(cause)
                .font(CoachWorldTokens.TypeRole.body)
                .foregroundStyle(palette.contentSecondary.color)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let onAct {
                GoButton(actionTitle, kind: .ghost, size: .compact, action: onAct)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(CoachWorldTokens.Space.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(cause)")
    }
}

// MARK: - ErrorBanner

/// Something failed, the draft survived, and here is how to try again.
///
/// `04` §4.3: "Failure preserves the authoritative draft and offers recovery." The banner is a band
/// **inside** its owning panel — the readout below it keeps full contrast and keeps working,
/// because the draft never left the screen. A second failure re-presents the same banner rather
/// than stacking a pile of them.
///
/// Copy is short and plain: no error codes, no blame, no technical nouns.
public struct ErrorBanner: View {
    @Environment(\.coachWorldPalette) private var palette

    private let whatFailed: String
    private let whatIsPreserved: String
    private let retryTitle: String
    private let onRetry: () -> Void

    public init(
        whatFailed: String,
        whatIsPreserved: String,
        retryTitle: String = "Try again",
        onRetry: @escaping () -> Void
    ) {
        self.whatFailed = whatFailed
        self.whatIsPreserved = whatIsPreserved
        self.retryTitle = retryTitle
        self.onRetry = onRetry
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            HStack(spacing: CoachWorldTokens.Space.xxs) {
                Image(systemName: "exclamationmark.triangle")
                    .accessibilityHidden(true)
                Text(whatFailed)
                    .font(CoachWorldTokens.TypeRole.body)
            }
            .foregroundStyle(palette.stateNegative.color)

            Text(whatIsPreserved)
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)

            GoButton(retryTitle, size: .compact, action: onRetry)
        }
        .padding(CoachWorldTokens.Space.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CutCorner.panel.fill(
            palette.stateNegative.color.opacity(CoachWorldTokens.Table.selectionFillOpacity)
        ))
        .overlay(CutCorner.panel.strokeBorder(
            palette.stateNegative.color,
            lineWidth: CoachWorldTokens.Shape.hairline
        ))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(whatFailed) \(whatIsPreserved)")
    }
}

// MARK: - InterruptedState

/// An advance stopped part-way, and here is what survived it.
///
/// `04` §4.3 requires an interruption to disclose what changed before the player resolves it, and
/// §3's durable boundary is what makes that disclosure possible. One action, not a choice pair:
/// resume is the only legal move, because abandoning a partial advance would ask the player to
/// discard something the boundary already committed.
///
/// **The preserved-items line follows the shipping/target rule.** `G-15` — the partial-advance
/// completion record — does not exist, so the engine cannot say *what* committed before the stop.
/// The shipping form says only that progress is saved; the target form names the items and is not
/// constructible until something can produce them.
public struct InterruptedState: View {
    public enum Preserved {
        /// **Shipping form.** The boundary held; what specifically committed is not queryable.
        case unspecified(gap: String)
        /// Target form — the named items the advance committed before it stopped.
        case items([String])
    }

    @Environment(\.coachWorldPalette) private var palette

    private let whatStopped: String
    private let preserved: Preserved
    private let resumeTitle: String
    private let onResume: () -> Void

    public init(
        whatStopped: String,
        preserved: Preserved,
        resumeTitle: String = "Resume advance",
        onResume: @escaping () -> Void
    ) {
        self.whatStopped = whatStopped
        self.preserved = preserved
        self.resumeTitle = resumeTitle
        self.onResume = onResume
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            HStack(spacing: CoachWorldTokens.Space.xxs) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(palette.stateWarning.color)
                    .accessibilityHidden(true)
                Text("Advance interrupted")
                    .font(CoachWorldTokens.TypeRole.headline)
                    .foregroundStyle(palette.contentPrimary.color)
            }

            Text(message(for: preserved))
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)

            GoButton(resumeTitle, size: .compact, action: onResume)
        }
        .padding(CoachWorldTokens.Space.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CutCorner.panel.fill(
            palette.stateWarning.color.opacity(CoachWorldTokens.Table.selectionFillOpacity)
        ))
        .overlay(CutCorner.panel.strokeBorder(
            palette.stateWarning.color,
            lineWidth: CoachWorldTokens.Shape.hairline
        ))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Advance interrupted. \(message(for: preserved))")
    }

    private func message(for preserved: Preserved) -> String {
        switch preserved {
        case let .unspecified(gap):
            "\(whatStopped) Progress is saved to that point — no engine record of exactly what "
                + "committed exists yet (\(gap))."
        case let .items(items):
            "\(whatStopped) Saved up to that point: \(items.joined(separator: ", "))."
        }
    }
}
