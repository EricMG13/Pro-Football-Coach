import SwiftUI

// MARK: - Registry 5: WorldStrip

/// Where the coach is, and the one thing that moves them forward — `04` §6.5 registry 5.
///
/// **World state, not an app toolbar.** `04` §3 keeps navigation in the composition rather than a
/// rail or a tab bar, and the advance slot is the whole reason the strip is a component rather than
/// a header: `Continue` advances only to the next unresolved obligation or scheduled event, and
/// clocks and ceremonies suppress it entirely. Modelling that as an enum means a screen cannot
/// render an advance affordance during a match by forgetting to.
///
/// Existed three times, diverged: only `RosterView`'s copy carried team identity, and each of the
/// three built its own context line from a different set of fields.
public struct WorldStrip<Routes: View>: View {
    public enum Advance {
        /// The path is clear; the slot advances the world.
        case clear(title: String)
        /// Work is due first. The slot names the count and opens the obligation, not the calendar.
        case pending(count: Int)
        /// A match, a clock or a ceremony is running. `04` §3 suppresses the slot outright —
        /// dimming it would imply it could be pressed.
        case suppressed
    }

    @Environment(\.coachWorldPalette) private var palette
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let programme: String
    private let contextLine: String
    private let identity: AnyView?
    private let advance: Advance
    private let onAdvance: () -> Void
    private let routes: Routes

    /// - Parameters:
    ///   - contextLine: coach, season, week, phase and record, already joined by the caller — the
    ///     read model decides what is true, not this view.
    ///   - identity: the programme mark, which `04` §5 resolves through `CoachWorldTeamIdentity`.
    public init(
        programme: String,
        contextLine: String,
        identity: AnyView? = nil,
        advance: Advance,
        onAdvance: @escaping () -> Void,
        @ViewBuilder routes: () -> Routes
    ) {
        self.programme = programme
        self.contextLine = contextLine
        self.identity = identity
        self.advance = advance
        self.onAdvance = onAdvance
        self.routes = routes()
    }

    public var body: some View {
        GlassPanel(depth: .standard) {
            layout
                .padding(.horizontal, CoachWorldTokens.Space.md)
                .padding(.vertical, CoachWorldTokens.Space.xs)
        }
        // World context is spoken first, per `04` §7's VoiceOver order.
        .accessibilitySortPriority(50)
    }

    @ViewBuilder private var layout: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                title
                routes
                advanceSlot
            }
        } else {
            HStack(spacing: CoachWorldTokens.Space.md) {
                if let identity { identity }
                title
                Rectangle()
                    .fill(palette.contentQuiet.color)
                    .frame(width: CoachWorldTokens.Shape.hairline)
                    .accessibilityHidden(true)
                routes
                Spacer(minLength: CoachWorldTokens.Space.sm)
                advanceSlot
            }
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text(programme.uppercased())
                .font(CoachWorldTokens.TypeRole.title)
                .foregroundStyle(palette.contentPrimary.color)
                .lineLimit(1)
            Text(contextLine)
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentSecondary.color)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(programme). \(contextLine)")
    }

    @ViewBuilder private var advanceSlot: some View {
        switch advance {
        case let .clear(title):
            GoButton(title, action: onAdvance)
        case let .pending(count):
            GoButton("\(count) due", kind: .ghost, action: onAdvance)
                .accessibilityLabel("\(count) obligations due. Opens the next one.")
        case .suppressed:
            EmptyView()
        }
    }
}

// MARK: - Registry 6: IdentityBand

/// A person-led stable header for sequenced disclosure — `04` §6.5 registry 6.
///
/// The band stays put while the detail beneath it changes, so the reader never loses whose record
/// they are reading. It carries the blank photo plate rather than a generated face: the product
/// ships no portraits, and a neutral plate is the honest form of that rather than an empty gap.
///
/// A verdict slot is offered but never filled by default — `04` §6.6's verdict-state rule, so a
/// person header cannot grow an unearned judgement.
public struct IdentityBand<Facts: View>: View {
    @Environment(\.coachWorldPalette) private var palette

    private let name: String
    private let subtitle: String
    private let mark: AnyView?
    private let verdict: VerdictLine.State?
    private let facts: Facts

    public init(
        name: String,
        subtitle: String,
        mark: AnyView? = nil,
        verdict: VerdictLine.State? = nil,
        @ViewBuilder facts: () -> Facts
    ) {
        self.name = name
        self.subtitle = subtitle
        self.mark = mark
        self.verdict = verdict
        self.facts = facts()
    }

    public var body: some View {
        GlassPanel(depth: .standard) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                HStack(spacing: CoachWorldTokens.Space.sm) {
                    if let mark { mark }
                    VStack(alignment: .leading, spacing: .zero) {
                        Text(name)
                            .font(CoachWorldTokens.TypeRole.title)
                            .foregroundStyle(palette.contentPrimary.color)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(subtitle)
                            .font(CoachWorldTokens.TypeRole.caption)
                            .foregroundStyle(palette.contentSecondary.color)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(name). \(subtitle)")
                    Spacer(minLength: CoachWorldTokens.Space.sm)
                    facts
                }
                if let verdict {
                    VerdictLine(verdict)
                }
            }
            .padding(CoachWorldTokens.Space.sm)
        }
        // The dominant object follows world context in `04` §7's reading order.
        .accessibilitySortPriority(40)
    }
}

// MARK: - Registry 19: AgendaRow

/// An obligation with its cost, its time to event, and its completion state — registry 19.
///
/// `04` §3: mandatory work cannot be skipped, but it may be explicitly delegated where the system
/// supports it. The delegated state therefore stays **in the row** and becomes the receipt — who
/// did it and what they chose — rather than vanishing and leaving a hole in the week.
public struct AgendaRow: View {
    public enum State: Sendable {
        case due(deadline: String)
        case waiting(deadline: String)
        case done(when: String)
        /// Named staff, and the exact terms they chose. `04` §4.3: success shows an exact receipt.
        case delegated(to: String, terms: String)
        case missed(consequence: String)

        var status: CoachWorldStatus? {
            switch self {
            case .due: .due
            case .waiting: .due
            case .done, .delegated: nil
            case .missed: .atRisk
            }
        }

        var trailing: String {
            switch self {
            case let .due(deadline), let .waiting(deadline): deadline
            case let .done(when): when
            case .delegated: "Set"
            case .missed: "Missed"
            }
        }
    }

    @Environment(\.coachWorldPalette) private var palette

    private let title: String
    private let cost: String?
    private let state: State
    private let onOpen: (() -> Void)?

    public init(title: String, cost: String? = nil, state: State, onOpen: (() -> Void)? = nil) {
        self.title = title
        self.cost = cost
        self.state = state
        self.onOpen = onOpen
    }

    public var body: some View {
        Group {
            if let onOpen {
                Button(action: onOpen) { content }
                    .buttonStyle(.plain)
            } else {
                content
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    private var content: some View {
        HStack(spacing: CoachWorldTokens.Space.sm) {
            mark
            VStack(alignment: .leading, spacing: .zero) {
                Text(title)
                    .font(CoachWorldTokens.TypeRole.body)
                    .foregroundStyle(palette.contentPrimary.color)
                    .lineLimit(1)
                if let detail {
                    Text(detail)
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentQuiet.color)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: CoachWorldTokens.Space.sm)
            Text(state.trailing)
                .font(CoachWorldTokens.TypeRole.caption)
                .monospacedDigit()
                .foregroundStyle(palette.contentSecondary.color)
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        .coachWorldSeam(.structural)
    }

    @ViewBuilder private var mark: some View {
        switch state {
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(palette.statePositive.color)
                .accessibilityHidden(true)
        case .delegated:
            Image(systemName: "person.badge.clock")
                .foregroundStyle(palette.statePositive.color)
                .accessibilityHidden(true)
        default:
            if let status = state.status {
                Image(systemName: status.symbol)
                    .foregroundStyle(status.ink(palette))
                    .accessibilityHidden(true)
            }
        }
    }

    private var detail: String? {
        switch state {
        case let .delegated(to, terms): "Set by \(to) · \(terms)"
        case let .missed(consequence): consequence
        default: cost
        }
    }

    private var spoken: String {
        switch state {
        case let .due(deadline): "\(title), due \(deadline)\(costPhrase)"
        case let .waiting(deadline): "\(title), waiting, \(deadline)\(costPhrase)"
        case let .done(when): "\(title), done \(when)"
        case let .delegated(to, terms): "\(title) set by \(to), \(terms)"
        case let .missed(consequence): "\(title), missed. \(consequence)"
        }
    }

    private var costPhrase: String { cost.map { ", costs \($0)" } ?? "" }
}
