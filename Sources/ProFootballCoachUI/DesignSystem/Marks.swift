import SwiftUI

// MARK: - Registry 10: RatingBadge

/// A fixed-size numeric badge — the printed number plus a spoken band.
///
/// `04` §6.4 item 4: replace repeated prose bands (Elite / Average / Poor) with a badge when the
/// rating is simulation-owned, and **retain the printed number and a spoken band so colour is not
/// the sole meaning**. Three screens drew a rating three different ways and not one of them drew
/// the badge — they coloured the text and stopped, which loses the band for anyone who cannot see
/// the hue.
public struct RatingBadge: View {
    /// How the badge sits in its row.
    public enum Emphasis {
        /// Filled with the heat band — the production form for a dense table.
        case filled
        /// Outlined, for a single rating in a context that would be shouted at by a fill.
        case outlined
    }

    @Environment(\.coachWorldPalette) private var palette
    @Environment(\.coachWorldFills) private var fills
    @ScaledMetric(relativeTo: .caption) private var textSize =
        CoachWorldTokens.Mark.badgeTextSize

    private let value: Int
    private let label: String
    private let emphasis: Emphasis

    /// - Parameter label: what the rating *is* — "overall", "development". Spoken, never drawn:
    ///   the column header carries it visually, the sentence carries it aurally.
    public init(_ value: Int, label: String, emphasis: Emphasis = .filled) {
        self.value = value
        self.label = label
        self.emphasis = emphasis
    }

    private var heat: CoachWorldHeat { .band(value) }

    public var body: some View {
        Text("\(value)")
            .font(.system(size: textSize, weight: .bold, design: .monospaced))
            .foregroundStyle(ink)
            .lineLimit(1)
            .frame(
                minWidth: CoachWorldTokens.Mark.badgeWidth,
                minHeight: CoachWorldTokens.Mark.badgeHeight
            )
            .background { field }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(label), \(value), \(heat.spoken)")
    }

    private var ink: Color {
        emphasis == .filled ? fills.onFill.color : heat.ink(palette)
    }

    @ViewBuilder private var field: some View {
        let shape = RoundedRectangle(cornerRadius: CoachWorldTokens.Mark.badgeRadius)
        switch emphasis {
        case .filled:
            shape.fill(heat.ink(palette).opacity(CoachWorldTokens.Mark.badgeFillOpacity))
        case .outlined:
            shape.strokeBorder(
                heat.ink(palette).opacity(CoachWorldTokens.Mark.badgeFillOpacity),
                lineWidth: CoachWorldTokens.Shape.hairline
            )
        }
    }
}

// MARK: - Registry 11: DeltaMark

/// A per-value recent-change mark, with its sentence equivalent.
///
/// `04` §6.6's Change class, capped at two members and closed: a value went up or it went down.
/// The mark never appears without the amount beside it — a direction with no size is a hint, not
/// a fact, and `04` §4.4 rejects invented authority.
public struct DeltaMark: View {
    public enum Direction: Sendable {
        case rose, fell

        var symbol: String {
            switch self {
            case .rose: "arrow.up.right"
            case .fell: "arrow.down.right"
            }
        }

        var spoken: String {
            switch self {
            case .rose: "up"
            case .fell: "down"
            }
        }
    }

    @Environment(\.coachWorldPalette) private var palette

    private let direction: Direction
    private let amount: Int
    private let subject: String

    /// - Parameter subject: what changed — "speed", "overall". Spoken only.
    public init(_ direction: Direction, amount: Int, subject: String) {
        self.direction = direction
        self.amount = amount
        self.subject = subject
    }

    public var body: some View {
        HStack(spacing: CoachWorldTokens.Space.xxs) {
            Image(systemName: direction.symbol)
            Text("\(amount)")
                .font(CoachWorldTokens.TypeRole.caption)
                .monospacedDigit()
        }
        .foregroundStyle(tint)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(subject) \(direction.spoken) \(amount)")
    }

    /// Direction is never carried by colour alone — the glyph and the spoken word both say it.
    private var tint: Color {
        switch direction {
        case .rose: palette.statePositive.color
        case .fell: palette.stateNegative.color
        }
    }
}

// MARK: - Registry 12: ConfidenceTag

/// What is known about a value, and how well.
///
/// Scouting produces a banded estimate before it produces a number, and `04` §4.4 forbids showing
/// an estimate as though it were measured. The tag was spoken in `PlayerProfileView` and **never
/// drawn**, so a sighted player saw a bare figure with no indication it was a guess.
public struct ConfidenceTag: View {
    public enum Knowledge: Sendable, Equatable {
        /// Nothing has been observed. The value is not shown at all.
        case unknown
        /// A range, from too few observations to narrow it.
        case banded(low: Int, high: Int, observations: Int)
        /// Enough observation to state a figure, with the count that earned it.
        case measured(value: Int, observations: Int)

        var spoken: String {
            switch self {
            case .unknown:
                "not yet observed"
            case let .banded(low, high, observations):
                "between \(low) and \(high), \(observations) observations, low confidence"
            case let .measured(value, observations):
                "\(value), \(observations) observations, high confidence"
            }
        }

        var printed: String {
            switch self {
            case .unknown: "—"
            case let .banded(low, high, _): "\(low)–\(high)"
            case let .measured(value, _): "\(value)"
            }
        }
    }

    @Environment(\.coachWorldPalette) private var palette

    private let knowledge: Knowledge
    private let subject: String

    public init(_ knowledge: Knowledge, subject: String) {
        self.knowledge = knowledge
        self.subject = subject
    }

    public var body: some View {
        Text(knowledge.printed)
            .font(CoachWorldTokens.TypeRole.callout)
            .monospacedDigit()
            .foregroundStyle(tint)
            .lineLimit(1)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(subject), \(knowledge.spoken)")
    }

    /// Quiet for what is not known, ordinary ink for what is. Uncertainty reads as *less*
    /// emphatic rather than as an alarm — it is an absence, not a problem.
    private var tint: Color {
        switch knowledge {
        case .unknown, .banded: palette.contentQuiet.color
        case .measured: palette.contentPrimary.color
        }
    }
}

// MARK: - Registry 17: StatusChip

/// The closed status vocabulary of `04` §6.6 — twelve members, at most three per row.
///
/// **Closed by construction, not by test.** §6.6 caps the class at twelve and says a symbol outside
/// the register is a finding rather than a licence; modelling the class as an enum means a
/// thirteenth cannot be drawn without editing this type, which is the same edit canon requires.
/// The tones match `table-v4`'s rendering of the class.
public enum CoachWorldStatus: String, CaseIterable, Sendable {
    case injured, unavailable, suspended, atRisk, due, scouted
    case held, academic, returning, standout, signed, scheduleClash

    var symbol: String {
        switch self {
        case .injured: "cross.case"
        case .unavailable: "bolt.slash"
        case .suspended: "shield.slash"
        case .atRisk: "exclamationmark.triangle"
        case .due: "clock.badge.exclamationmark"
        case .scouted: "binoculars"
        case .held: "hand.raised"
        case .academic: "graduationcap"
        case .returning: "arrow.uturn.left"
        case .standout: "star"
        case .signed: "checkmark.seal"
        case .scheduleClash: "calendar.badge.exclamationmark"
        }
    }

    /// The word that carries the meaning. `04` §6.1: state is never colour alone, and §6.6 requires
    /// every mark to carry a printed or spoken value beside it.
    public var word: String {
        switch self {
        case .injured: "Injured"
        case .unavailable: "Unavailable"
        case .suspended: "Suspended"
        case .atRisk: "At risk"
        case .due: "Due"
        case .scouted: "Scouted"
        case .held: "Held"
        case .academic: "Academic"
        case .returning: "Returning"
        case .standout: "Standout"
        case .signed: "Signed"
        case .scheduleClash: "Schedule clash"
        }
    }

    func ink(_ palette: CoachWorldTokens.Palette) -> Color {
        switch self {
        case .injured, .unavailable, .suspended: palette.stateNegative.color
        case .atRisk, .due, .scheduleClash: palette.stateWarning.color
        case .scouted: palette.stateInfo.color
        case .standout, .signed: palette.statePositive.color
        case .held, .academic, .returning: palette.contentSecondary.color
        }
    }
}

/// A status mark with its word — `04` §6.5 registry 17.
public struct StatusChip: View {
    @Environment(\.coachWorldPalette) private var palette
    @ScaledMetric(relativeTo: .caption) private var textSize = CoachWorldTokens.Mark.chipTextSize

    private let status: CoachWorldStatus
    private let showsWord: Bool

    /// - Parameter showsWord: false inside a dense table row, where the column supplies the word
    ///   and the row's spoken sentence carries it. The word is always in the accessible label.
    public init(_ status: CoachWorldStatus, showsWord: Bool = true) {
        self.status = status
        self.showsWord = showsWord
    }

    public var body: some View {
        HStack(spacing: CoachWorldTokens.Space.xxs) {
            Image(systemName: status.symbol)
            if showsWord {
                Text(status.word)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .lineLimit(1)
            }
        }
        .font(.system(size: textSize))
        .foregroundStyle(status.ink(palette))
        .padding(.horizontal, CoachWorldTokens.Mark.chipInset)
        .frame(minHeight: CoachWorldTokens.Mark.chipHeight)
        .overlay(
            CutCorner.row.strokeBorder(
                status.ink(palette).opacity(0.35),
                lineWidth: CoachWorldTokens.Shape.hairline
            )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(status.word)
    }
}

// MARK: - Registry 18: RoleToken

/// A short role or assignment code, mapping a list row to a position on a diagram.
///
/// The one job is correspondence: the "X" in the roster row and the "X" on the field must be the
/// same mark, or the diagram is decoration. Drawn letters are **text**, so they take `field.label`
/// (4.90 on turf) rather than `field.annotation` (3.96, a non-text indicator only).
public struct RoleToken: View {
    @Environment(\.coachWorldPalette) private var palette
    @ScaledMetric(relativeTo: .caption) private var textSize =
        CoachWorldTokens.Mark.roleTokenTextSize

    private let code: String
    private let name: String
    private let onField: Bool

    /// - Parameters:
    ///   - code: the short mark — "X", "Z", "H", "Y", "F".
    ///   - name: what it means, spoken — "split end", "flanker".
    ///   - onField: true when drawn over the turf, which changes the ink to the field label form.
    public init(_ code: String, name: String, onField: Bool = false) {
        self.code = code
        self.name = name
        self.onField = onField
    }

    public var body: some View {
        Text(code)
            .font(CoachWorldTokens.TypeRole.display(textSize))
            .foregroundStyle(ink)
            .lineLimit(1)
            .frame(
                minWidth: CoachWorldTokens.Mark.roleTokenSize,
                minHeight: CoachWorldTokens.Mark.roleTokenSize
            )
            .background(
                Circle().fill(onField
                              ? Color.clear
                              : CoachWorldTokens.Glass.track.color)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(code), \(name)")
    }

    private var ink: Color {
        onField ? CoachWorldTokens.fieldLabel.color : palette.contentPrimary.color
    }
}
