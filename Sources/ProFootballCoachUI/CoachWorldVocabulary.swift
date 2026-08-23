import SwiftUI

// The reusable Floodlit vocabulary: `04` section 7's system states plus the small marks and
// readouts more than one production surface needs. Every colour-coded piece here repeats its
// meaning as text or a registered symbol (`04` section 6.6) — colour is never the only channel.
// `CoachWorldSystemState` is `public` because `CoachWorldApp` renders it directly whenever a
// registered route has no retained read model; everything else here is consumed only from within
// this module, so it stays at the default internal access every other shared component in this
// target already uses.

// MARK: - System state

/// The five compositions `04` section 7 requires wherever a screen can be empty, loading, erroring,
/// interrupted or waiting on a delegated decision. Each kind carries its own required message, so a
/// composition cannot fall back to one generic "something went wrong" — and a recovery action, when
/// offered, is always paired with the sentence describing what it does.
public struct CoachWorldSystemState: View {
    public enum Kind {
        case empty(String)
        case loading(String)
        case error(String, recoveryTitle: String?, onRecover: (() -> Void)?)
        case interrupted(String)
        case delegated(String)

        var symbolName: String {
            switch self {
            // Empty-state marks (04 section 6.6): person.3, person.crop.rectangle, list.number,
            // checkmark.circle. list.number reads as "nothing listed yet" across every dense
            // family this component serves.
            case .empty: return "list.number"
            case .loading: return "clock.badge.exclamationmark"
            case .error: return "exclamationmark.triangle"
            case .interrupted: return "pause.fill"
            // Obligation class: person.badge.clock is the delegated-receipt member on every
            // surface that shows one.
            case .delegated: return "person.badge.clock"
            }
        }

        var message: String {
            switch self {
            case let .empty(text), let .loading(text), let .interrupted(text),
                 let .delegated(text):
                return text
            case let .error(text, _, _):
                return text
            }
        }
    }

    private let kind: Kind
    private let palette: CoachWorldTokens.Palette

    public init(_ kind: Kind, palette: CoachWorldTokens.Palette = CoachWorldTokens.dark) {
        self.kind = kind
        self.palette = palette
    }

    public var body: some View {
        VStack(spacing: CoachWorldTokens.Space.md) {
            Image(systemName: kind.symbolName)
                .coachWorldIcon(CoachWorldTokens.Shape.systemStateMarkSize, weight: .semibold)
                .foregroundStyle(palette.contentQuiet.color)
                .accessibilityHidden(true)
            Text(kind.message)
                .font(CoachWorldTokens.TypeRole.headline.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.contentPrimary.color)
            if case let .error(_, recoveryTitle?, onRecover?) = kind {
                Button(recoveryTitle, action: onRecover)
                    .buttonStyle(CoachWorldActionButtonStyle(role: .primary, palette: palette))
            }
        }
        .padding(CoachWorldTokens.Space.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Status chip

/// A tracked micro-label chip: tone plus required text, with an optional symbol drawn only from
/// `04` section 6.6's 12-member Status class. The symbol is decorative reinforcement, never the
/// sole carrier of meaning — `text` has no default and cannot be omitted.
struct CoachWorldStatusChip: View {
    enum Tone {
        case go, warn, bad, quiet, cool

        func color(in palette: CoachWorldTokens.Palette) -> CoachWorldTokens.ColorValue {
            switch self {
            case .go: return palette.statePositive
            case .warn: return palette.stateWarning
            case .bad: return palette.stateNegative
            case .quiet: return palette.contentQuiet
            case .cool: return palette.stateInfo
            }
        }
    }

    /// The Status class's 12 registered members (04 section 6.6). Any other symbol name is a
    /// compile-time typo away from failing the design-contract symbol-register scan.
    enum Symbol: String, CaseIterable {
        case unavailable = "cross.case"
        case suspended = "bolt.slash"
        case shielded = "shield.slash"
        case warning = "exclamationmark.triangle"
        case overdue = "clock.badge.exclamationmark"
        case scouted = "binoculars"
        case limited = "hand.raised"
        case eligible = "graduationcap"
        case reverted = "arrow.uturn.left"
        case featured = "star"
        case verified = "checkmark.seal"
        case scheduled = "calendar.badge.exclamationmark"
    }

    let text: String
    var symbol: Symbol?
    var tone: Tone
    var palette: CoachWorldTokens.Palette = CoachWorldTokens.dark

    var body: some View {
        HStack(spacing: CoachWorldTokens.Space.xxs) {
            if let symbol {
                Image(systemName: symbol.rawValue)
                    .accessibilityHidden(true)
            }
            Text(text.uppercased())
                .lineLimit(1)
        }
        .coachWorldDisplay(CoachWorldTokens.TypeRole.microLabelSize)
        .tracking(CoachWorldTokens.TypeRole.microLabelTracking)
        .foregroundStyle(tone.color(in: palette).color)
        .padding(.horizontal, CoachWorldTokens.Space.xs)
        .padding(.vertical, CoachWorldTokens.Space.xxs)
        .background {
            CoachWorldCutCorner.row
                .fill(tone.color(in: palette).color.opacity(0.14))
        }
        .overlay {
            CoachWorldCutCorner.row
                .stroke(tone.color(in: palette).color.opacity(0.34), lineWidth: CoachWorldTokens.Shape.hairline)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

// MARK: - Delta mark

/// A signed rating delta: the printed number is the fact, the arrow is reinforcement. `04` section
/// 6.6's Change class has exactly two members — up and down — and a zero delta has no direction to
/// show, so it draws no symbol rather than inventing a third.
struct CoachWorldDeltaMark: View {
    let value: Int
    var palette: CoachWorldTokens.Palette = CoachWorldTokens.dark

    var symbolName: String? {
        if value > 0 { return "arrow.up.right" }
        if value < 0 { return "arrow.down.right" }
        return nil
    }

    private var tint: Color {
        if value > 0 { return palette.statePositive.color }
        if value < 0 { return palette.stateNegative.color }
        return palette.contentQuiet.color
    }

    var body: some View {
        HStack(spacing: CoachWorldTokens.Space.xxs) {
            if let symbolName {
                Image(systemName: symbolName)
                    .coachWorldIcon(CoachWorldTokens.TypeRole.microLabelSize, weight: .bold)
                    .accessibilityHidden(true)
            }
            Text(value == 0 ? "—" : (value > 0 ? "+\(value)" : "\(value)"))
                .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
                .monospacedDigit()
        }
        .foregroundStyle(tint)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(value == 0 ? "no change" : "\(value > 0 ? "up" : "down") \(abs(value))")
    }
}

// MARK: - Rating ring

/// A proportion ring at any diameter — the same idea from a 26 pt table cell through a 118 pt hero
/// gauge, so no separate arc-gauge/value-ring/dial type exists for what is one shape at different
/// sizes. Ratings are the documented 40–99 ceiling; the ring never implies precision the value does
/// not have.
struct CoachWorldRatingRing: View {
    let value: Int
    var ceiling: Int = 99
    var floor: Int = 40
    var diameter: CGFloat = 26
    var palette: CoachWorldTokens.Palette = CoachWorldTokens.dark

    private var fraction: Double {
        guard ceiling > floor else { return 0 }
        return min(1, max(0, Double(value - floor) / Double(ceiling - floor)))
    }

    private var strokeWidth: CGFloat {
        max(CoachWorldTokens.Shape.ringStrokeMinimum,
            diameter * CoachWorldTokens.Shape.ringStrokeRatio)
    }

    /// The design's own banding, diverging around a neutral centre since `04` section 6.4's
    /// 2026-08-22 amendment: an average figure is neither praised nor flagged, and colour is spent
    /// only at the ends. Red for a real weakness, amber below par, green above — lightened at 80-84
    /// and full from 85, so "good" and "excellent" are not the same green. Colour always repeats the
    /// printed number beside it. `CoachWorldTokens.Heat` is the one definition of the banding, so
    /// this stays a delegate rather than a second copy that can drift from it.
    private var ringColor: Color {
        CoachWorldTokens.Heat.color(for: value, palette: palette)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(palette.raised.color, lineWidth: strokeWidth)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text("\(value)")
                .coachWorldFigureCondensed(diameter * CoachWorldTokens.Shape.ringTextRatio, weight: .heavy)
                .minimumScaleFactor(0.6)
                .foregroundStyle(palette.contentPrimary.color)
        }
        .frame(width: diameter, height: diameter)
        // Personnel Room, `04` section 2: "a value settles to its new figure, it does not slide
        // there".
        .coachWorldAnimation(CoachWorldTokens.Motion.value, value: value)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("rating \(value)")
    }
}

// MARK: - Meter

/// A single proportion bar — condition, fatigue, capacity, anything expressed as a value inside a
/// range. The printed value is the caller's responsibility; this draws the fill and nothing else.
struct CoachWorldMeter: View {
    let value: Double
    var range: ClosedRange<Double> = 0...100
    var tint: Color?
    var palette: CoachWorldTokens.Palette = CoachWorldTokens.dark

    private var fraction: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return min(1, max(0, (value - range.lowerBound) / span))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(palette.raised.color)
                Capsule()
                    .fill(tint ?? palette.actionPrimary.color)
                    .frame(width: geometry.size.width * fraction)
            }
        }
        .frame(height: CoachWorldTokens.Space.xxs)
        .accessibilityHidden(true)
    }
}

// MARK: - Opposed bar

/// A two-sided comparison — home against away, for against against, anything with a leading and a
/// trailing figure. Both values are printed by the caller alongside this; the bar is the shared
/// scale, not a replacement for either number.
struct CoachWorldOpposedBar: View {
    let leading: Double
    let trailing: Double
    var leadingTint: Color?
    var trailingTint: Color?
    var palette: CoachWorldTokens.Palette = CoachWorldTokens.dark

    private var leadingFraction: Double {
        let total = leading + trailing
        guard total > 0 else { return 0.5 }
        return leading / total
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: CoachWorldTokens.Shape.hairline) {
                Rectangle()
                    .fill(leadingTint ?? palette.actionPrimary.color)
                    .frame(width: geometry.size.width * leadingFraction)
                Rectangle()
                    .fill(trailingTint ?? palette.contentQuiet.color)
            }
        }
        .frame(height: CoachWorldTokens.Space.xxs)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }
}

// MARK: - Agenda row

/// A weekly obligation or decision row: title, timing, cost and completion state. The Obligation
/// class (04 section 6.6) has exactly two members — complete and delegated — because every other
/// state a row can be in is read from its printed timing and cost, not a third icon.
struct CoachWorldAgendaRow: View {
    enum State {
        case pending
        case complete
        case delegated
    }

    let title: String
    let timing: String
    var cost: String?
    var state: State = .pending
    var palette: CoachWorldTokens.Palette = CoachWorldTokens.dark

    var body: some View {
        HStack(spacing: CoachWorldTokens.Space.sm) {
            switch state {
            case .complete:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(palette.statePositive.color)
                    .accessibilityHidden(true)
            case .delegated:
                Image(systemName: "person.badge.clock")
                    .foregroundStyle(palette.contentQuiet.color)
                    .accessibilityHidden(true)
            case .pending:
                Circle()
                    .strokeBorder(palette.contentQuiet.color, lineWidth: CoachWorldTokens.Shape.hairline)
                    .frame(width: CoachWorldTokens.Space.sm, height: CoachWorldTokens.Space.sm)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: CoachWorldTokens.Shape.hairline) {
                Text(title)
                    .font(CoachWorldTokens.TypeRole.body.weight(.semibold))
                    .foregroundStyle(palette.contentPrimary.color)
                Text(timing)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
            }
            Spacer(minLength: CoachWorldTokens.Space.sm)
            if let cost {
                Text(cost)
                    .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
                    .foregroundStyle(palette.contentSecondary.color)
            }
        }
        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Identity band

/// A mark-scale team identity strip — the recognition channel, not the atmosphere channel. Resolves
/// through `CoachWorldTeamIdentity` and renders nothing when that resolution refuses: no fallback
/// team colour is ever invented for an illegible or malformed pair.
struct CoachWorldIdentityBand: View {
    let team: CoachWorldTeamReference
    let behind: CoachWorldTokens.ColorValue
    var palette: CoachWorldTokens.Palette = CoachWorldTokens.dark

    var identity: CoachWorldTeamIdentity? {
        // Matches the ink candidate set every existing call site uses (e.g. RosterView), rather
        // than inventing a third option — the winner is measured, not preferred, but the candidate
        // pool itself should not vary between consumers of the same identity system.
        CoachWorldTeamIdentity(
            team: team,
            behind: behind,
            inks: [palette.contentPrimary, palette.page]
        )
    }

    var body: some View {
        if let identity {
            HStack(spacing: .zero) {
                Rectangle()
                    .fill(identity.accent.color)
                    .frame(width: 3)
                Text(team.name)
                    .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                    .foregroundStyle(identity.onField.color)
                    .padding(.horizontal, CoachWorldTokens.Space.sm)
                    .padding(.vertical, CoachWorldTokens.Space.xs)
            }
            .background(identity.field.color)
            .overlay {
                if identity.needsBoundary {
                    Rectangle().strokeBorder(
                        palette.contentSecondary.color, lineWidth: CoachWorldTokens.Shape.hairline
                    )
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(team.name)
        }
    }
}
