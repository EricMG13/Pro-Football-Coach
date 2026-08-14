import SwiftUI

// MARK: - Registry 13: VerdictLine

/// How confident a judgement is. Three-valued, because a simulation that only ever speaks with
/// certainty is lying about thin samples (`04` §6.5).
public enum CoachWorldConfidence: Sendable {
    case high, moderate, low

    public var word: String {
        switch self {
        case .high: "high"
        case .moderate: "moderate"
        case .low: "low"
        }
    }
}

/// An engine-backed judgement heading a readout — `04` §6.5 registry 13.
///
/// **The verdict-state rule is enforced by the type, not by discipline.** `04` §6.6 gives the whole
/// library one drawing convention: the shipping form is the slot *empty* with its gap ID in place,
/// because G-02 does not exist and §4.4 rejects invented authority; the populated form is never the
/// unlabelled default. Modelling that as an enum with no default case means a caller cannot
/// accidentally ship the aspirational form — they have to name which one they mean, and the
/// populated case cannot be built without a staff owner, a sample size and the computation that
/// backs it.
public struct VerdictLine: View {
    public struct Judgement: Sendable {
        public let sentence: String
        public let staffName: String
        public let staffRole: String
        public let sampleSize: Int
        public let confidence: CoachWorldConfidence
        /// The named engine computation behind the sentence. A verdict with no computation is an
        /// opinion the product has no right to state.
        public let computation: String

        public init(
            sentence: String,
            staffName: String,
            staffRole: String,
            sampleSize: Int,
            confidence: CoachWorldConfidence,
            computation: String
        ) {
            self.sentence = sentence
            self.staffName = staffName
            self.staffRole = staffRole
            self.sampleSize = sampleSize
            self.confidence = confidence
            self.computation = computation
        }
    }

    public enum State {
        /// **The shipping form.** The slot is empty and names the gap that would fill it.
        case awaiting(gap: String)
        /// The populated form — only constructible with everything that makes it honest.
        case judged(Judgement)
    }

    @Environment(\.coachWorldPalette) private var palette

    private let state: State
    private let onInspectEvidence: (() -> Void)?

    public init(_ state: State, onInspectEvidence: (() -> Void)? = nil) {
        self.state = state
        self.onInspectEvidence = onInspectEvidence
    }

    public var body: some View {
        switch state {
        case let .awaiting(gap):
            awaitingSlot(gap)
        case let .judged(judgement):
            judged(judgement)
        }
    }

    /// Says less rather than saying something unearned. There is no Evidence control here, because
    /// with no judgement to audit there is nothing to inspect.
    private func awaitingSlot(_ gap: String) -> some View {
        Text("No engine baseline exists yet (\(gap)).")
            .font(CoachWorldTokens.TypeRole.callout)
            .foregroundStyle(palette.contentQuiet.color)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel("Verdict not available. No engine baseline exists yet, \(gap).")
    }

    private func judged(_ judgement: Judgement) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text(judgement.sentence)
                .font(CoachWorldTokens.TypeRole.headline)
                .foregroundStyle(palette.contentPrimary.color)
                .fixedSize(horizontal: false, vertical: true)

            Text(attribution(judgement))
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentSecondary.color)

            Text(judgement.computation)
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentQuiet.color)

            if let onInspectEvidence {
                GoButton("Evidence", kind: .ghost, size: .compact, action: onInspectEvidence)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(judgement.sentence) \(attribution(judgement)).")
    }

    private func attribution(_ judgement: Judgement) -> String {
        "\(judgement.staffName), \(judgement.staffRole) · sample \(judgement.sampleSize) "
            + "· confidence \(judgement.confidence.word)"
    }
}

// MARK: - Registry 14: Meter

/// A capacity track with a defined over-capacity state — `04` §6.5 registry 14.
///
/// Every capacity in this product is a hard rule someone can break: a roster limit, a scholarship
/// count, a salary cap. The over-limit state is therefore not an error styling exercise — it is the
/// state the player spends most of the offseason in, and it has to read as a fact rather than an
/// alarm. Money is integer dollars (`CLAUDE.md`); the caller formats.
public struct Meter: View {
    @Environment(\.coachWorldPalette) private var palette

    private let used: Double
    private let limit: Double
    private let label: String
    private let printed: String

    public init(used: Double, limit: Double, label: String, printed: String) {
        self.used = used
        self.limit = limit
        self.label = label
        self.printed = printed
    }

    private var fraction: Double { limit > 0 ? used / limit : 0 }
    private var isOver: Bool { used > limit }

    public var body: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            HStack {
                CoachWorldFieldLabel(label)
                Spacer(minLength: CoachWorldTokens.Space.sm)
                Text(printed)
                    .font(CoachWorldTokens.TypeRole.callout)
                    .monospacedDigit()
                    .foregroundStyle(isOver ? palette.stateNegative.color
                                            : palette.contentPrimary.color)
            }
            track
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    private var track: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(CoachWorldTokens.Gauge.track.color)
                Capsule()
                    .fill(isOver ? palette.stateNegative.color : palette.actionPrimary.color)
                    .frame(width: proxy.size.width * min(max(fraction, 0), 1))
                // The limit, marked where it actually falls, so an over-cap bar shows how far over.
                Rectangle()
                    .fill(palette.contentSecondary.color)
                    .frame(width: CoachWorldTokens.Shape.hairline)
                    .offset(x: proxy.size.width * min(1 / max(fractionOfDrawn, 1), 1))
            }
        }
        .frame(height: CoachWorldTokens.Gauge.shareBarHeight)
    }

    /// When over the limit the bar is drawn against the *used* total, so the limit line moves
    /// inward rather than the fill running off the end.
    private var fractionOfDrawn: Double { isOver ? used / max(limit, 1) : 1 }

    private var spoken: String {
        isOver ? "\(label), \(printed), over the limit" : "\(label), \(printed)"
    }
}

// MARK: - Registry 15: OpposedBar

/// A two-team shared-track comparison — `04` §6.5 registry 15.
///
/// One track, two claims on it: this is the shape a matchup takes when neither side owns the
/// screen. The not-yet-recorded state matters more than it looks — before kickoff there is no
/// share, and drawing 50/50 would state a fact the simulation has not produced.
public struct OpposedBar: View {
    @Environment(\.coachWorldPalette) private var palette

    private let label: String
    private let home: Double?
    private let homeName: String
    private let awayName: String
    private let homePrinted: String
    private let awayPrinted: String
    private let homeTint: Color?
    private let awayTint: Color?

    /// - Parameter home: the home side's share, 0…1. `nil` when nothing is recorded yet.
    public init(
        label: String,
        home: Double?,
        homeName: String,
        awayName: String,
        homePrinted: String,
        awayPrinted: String,
        homeTint: Color? = nil,
        awayTint: Color? = nil
    ) {
        self.label = label
        self.home = home
        self.homeName = homeName
        self.awayName = awayName
        self.homePrinted = homePrinted
        self.awayPrinted = awayPrinted
        self.homeTint = homeTint
        self.awayTint = awayTint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            HStack {
                Text(homePrinted).monospacedDigit()
                Spacer(minLength: CoachWorldTokens.Space.sm)
                CoachWorldFieldLabel(label)
                Spacer(minLength: CoachWorldTokens.Space.sm)
                Text(awayPrinted).monospacedDigit()
            }
            .font(CoachWorldTokens.TypeRole.callout)
            .foregroundStyle(palette.contentPrimary.color)

            track
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    @ViewBuilder private var track: some View {
        GeometryReader { proxy in
            if let home {
                HStack(spacing: .zero) {
                    Rectangle().fill(homeTint ?? palette.actionPrimary.color)
                        .frame(width: proxy.size.width * min(max(home, 0), 1))
                    Rectangle().fill(awayTint ?? palette.contentSecondary.color)
                }
            } else {
                Rectangle().fill(CoachWorldTokens.Gauge.track.color)
            }
        }
        .frame(height: CoachWorldTokens.Gauge.shareBarHeight)
        .clipShape(Capsule())
    }

    private var spoken: String {
        guard home != nil else { return "\(label), not yet recorded" }
        return "\(label), \(homeName) \(homePrinted), \(awayName) \(awayPrinted)"
    }
}

// MARK: - Registry 16: FormLine

/// A bounded last-N run of results with its rating thread — `04` §6.5 registry 16.
///
/// Bounded is the point: "recent form" that grows without limit is a season summary wearing a
/// smaller name, and every collection that grows across seasons needs a stated bound
/// (`CLAUDE.md`). A bye or an absence is drawn as itself rather than skipped, because a gap in a
/// run of five is information.
public struct FormLine: View {
    public enum Result: Sendable {
        case won(rating: Int, opponent: String)
        case lost(rating: Int, opponent: String)
        case drew(rating: Int, opponent: String)
        /// No game, or the player took no part in it.
        case absent(reason: String)
    }

    @Environment(\.coachWorldPalette) private var palette

    private let results: [Result]
    private let subject: String

    public init(_ results: [Result], subject: String) {
        self.results = results
        self.subject = subject
    }

    public var body: some View {
        HStack(spacing: CoachWorldTokens.Space.xxs) {
            ForEach(Array(results.enumerated()), id: \.offset) { _, result in
                cell(result)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    @ViewBuilder private func cell(_ result: Result) -> some View {
        switch result {
        case let .won(rating, _), let .lost(rating, _), let .drew(rating, _):
            ValueRing(rating, tint: outcomeTint(result))
        case .absent:
            Text("—")
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentQuiet.color)
                .frame(
                    width: CoachWorldTokens.Gauge.ringDiameter,
                    height: CoachWorldTokens.Gauge.ringDiameter
                )
        }
    }

    private func outcomeTint(_ result: Result) -> Color {
        switch result {
        case .won: palette.statePositive.color
        case .lost: palette.stateNegative.color
        case .drew: palette.contentSecondary.color
        case .absent: palette.contentQuiet.color
        }
    }

    private var spoken: String {
        let parts = results.map { result -> String in
            switch result {
            case let .won(rating, opponent): "won against \(opponent), rated \(rating)"
            case let .lost(rating, opponent): "lost to \(opponent), rated \(rating)"
            case let .drew(rating, opponent): "drew with \(opponent), rated \(rating)"
            case let .absent(reason): reason
            }
        }
        return "\(subject) recent form: " + parts.joined(separator: "; ") + "."
    }
}
