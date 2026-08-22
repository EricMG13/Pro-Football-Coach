import SwiftUI

// The eight composition patterns every management surface is built from
// (`04` section 6.1c, `FLOODLIT-SURFACES.md` section 2).
//
// A surface that needs a ninth is a finding, not a licence — the point of a closed set is that a
// coach learns the grammar once. Three of the eight already shipped and are not rebuilt here:
// the glass panel is `coachWorldFloodlitPanel`, and the arc family's smallest and largest steps
// are `CoachWorldRatingRing` and `CoachWorldMeter`. This file adds what was missing.

// MARK: - 1. Label3

/// Every panel head: 9 pt, uppercase, wide tracking, quiet ink.
///
/// The string is **written sentence case at the call site and uppercased on render**. That is not
/// styling pedantry — an uppercased literal is unreadable to a translator and unspeakable to
/// VoiceOver, so the source keeps the real sentence and the view does the shouting.
struct FloodlitLabel3: View {
    private let text: String
    private let palette: CoachWorldTokens.Palette
    private let tint: Color?

    init(
        _ text: String,
        palette: CoachWorldTokens.Palette = CoachWorldTokens.dark,
        tint: Color? = nil
    ) {
        self.text = text
        self.palette = palette
        self.tint = tint
    }

    var body: some View {
        Text(text.uppercased())
            .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.flag, weight: .bold))
            .tracking(
                CoachWorldTokens.DisplaySize.tracking(
                    CoachWorldTokens.DisplaySize.labelTracking,
                    at: CoachWorldTokens.DisplaySize.flag
                )
            )
            .foregroundStyle(tint ?? palette.contentQuiet.color)
            .lineLimit(1)
            // The uppercasing is presentation; the spoken form keeps the authored sentence.
            .accessibilityLabel(text)
    }
}

// MARK: - 2. Row / chip

/// Tables, lists and selectors. Selection is a low-opacity team tint plus a crisp visible rule;
/// neither competes with the committing action or leaves colour as the only cue.
struct FloodlitRow<Content: View>: View {
    @Environment(\.coachWorldTeamIdentity) private var teamIdentity

    private let isSelected: Bool
    private let palette: CoachWorldTokens.Palette
    private let action: (() -> Void)?
    private let content: () -> Content

    init(
        isSelected: Bool = false,
        palette: CoachWorldTokens.Palette = CoachWorldTokens.dark,
        action: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isSelected = isSelected
        self.palette = palette
        self.action = action
        self.content = content
    }

    var body: some View {
        if let action {
            Button(action: action) { body(for: true) }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
        } else {
            body(for: false)
        }
    }

    private var rowSelectionRule: CoachWorldTokens.ColorValue {
        teamIdentity?.selectionRule(on: palette.work) ?? palette.actionPrimary
    }

    private var rowSelectionTint: CoachWorldTokens.ColorValue {
        teamIdentity?.field ?? palette.actionPrimary
    }

    private func body(for interactive: Bool) -> some View {
        content()
            .padding(.vertical, CoachWorldTokens.Pad.row.v)
            .padding(.horizontal, CoachWorldTokens.Pad.row.h)
            .frame(
                maxWidth: .infinity,
                // 32 when it is a dense readout, 44 the moment it can be tapped: a row that
                // responds to touch is a control and takes a control's floor.
                minHeight: interactive
                    ? CoachWorldTokens.Shape.minimumTarget
                    : Pattern.rowMinHeight,
                alignment: .leading
            )
            .background {
                ZStack {
                    CoachWorldCutCorner.row.fill(palette.work.color.opacity(Pattern.rowFill))
                    if isSelected {
                        CoachWorldCutCorner.row.fill(rowSelectionTint.color.opacity(0.10))
                    }
                }
            }
            .overlay {
                CoachWorldCutCorner.row.stroke(
                    isSelected
                        ? rowSelectionRule.color
                        : Color.white.opacity(Pattern.rowHairline),
                    lineWidth: CoachWorldTokens.Shape.hairline
                )
            }
            .contentShape(CoachWorldCutCorner.row)
    }
}

// MARK: - 3. Card

/// Depth cards and dossiers: a panel with its own padding scale.
struct FloodlitCard<Content: View>: View {
    private let palette: CoachWorldTokens.Palette
    private let depth: CoachWorldFloodlitPanelDepth
    private let content: () -> Content

    init(
        palette: CoachWorldTokens.Palette = CoachWorldTokens.dark,
        depth: CoachWorldFloodlitPanelDepth = .glass,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.palette = palette
        self.depth = depth
        self.content = content
    }

    var body: some View {
        content()
            .padding(.vertical, CoachWorldTokens.Pad.card.v)
            .padding(.horizontal, CoachWorldTokens.Pad.card.h)
            .coachWorldFloodlitPanel(
                fill: depth == .deep
                    ? CoachWorldTokens.Floodlit.glassFlatDeep.color
                    : CoachWorldTokens.Floodlit.glassFlat.color,
                border: Color.white.opacity(CoachWorldTokens.Glass.line),
                depth: depth,
                shape: CoachWorldCutCorner.card
            )
    }
}

// MARK: - 4. Arc family

/// The arc family's panel-scale step. **Use an arc only where the datum is a proportion** — an arc
/// that encodes a rank or a count is a lie about the shape of the number.
struct FloodlitArcGauge: View {
    private let proportion: Double
    private let caption: String
    private let figure: String
    private let palette: CoachWorldTokens.Palette
    private let tint: Color?

    init(
        proportion: Double,
        figure: String,
        caption: String,
        palette: CoachWorldTokens.Palette = CoachWorldTokens.dark,
        tint: Color? = nil
    ) {
        self.proportion = min(1, max(0, proportion))
        self.figure = figure
        self.caption = caption
        self.palette = palette
        self.tint = tint
    }

    var body: some View {
        VStack(spacing: CoachWorldTokens.Gap.xxs) {
            ZStack {
                arc(1)
                    .stroke(
                        palette.contentQuiet.color.opacity(Pattern.trackAlpha),
                        style: .init(lineWidth: Pattern.arcWidth, lineCap: .round)
                    )
                arc(proportion)
                    .stroke(
                        tint ?? palette.actionPrimary.color,
                        style: .init(lineWidth: Pattern.arcWidth, lineCap: .round)
                    )
                Text(figure)
                    .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.panel, weight: .bold))
            }
            .frame(width: Pattern.arcDiameter, height: Pattern.arcDiameter)
            FloodlitLabel3(caption, palette: palette)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(caption), \(figure)")
    }

    /// An open arc, not a ring: the gap is what tells a reader this is a proportion of a stated
    /// whole rather than a clock.
    private func arc(_ fraction: Double) -> Path {
        Path { path in
            path.addArc(
                center: Pattern.arcCentre,
                radius: Pattern.arcRadius,
                startAngle: .degrees(Pattern.arcStart),
                endAngle: .degrees(Pattern.arcStart + Pattern.arcSweep * fraction),
                clockwise: false
            )
        }
    }
}

/// The arc family's hero step: one attribute, at the size the design breaks the safe area for.
struct FloodlitAttributeDial: View {
    private let rating: Int
    private let title: String
    private let palette: CoachWorldTokens.Palette
    /// The hero diameter by default. A caller that has less room passes a smaller one rather than
    /// scaling the drawn dial — `scaleEffect` shrinks the stroke and the type with it, and 7 pt of
    /// stroke and a 34 pt figure are both stated sizes.
    private let diameter: CGFloat

    init(
        rating: Int,
        title: String,
        diameter: CGFloat = Pattern.dialDiameter,
        palette: CoachWorldTokens.Palette = CoachWorldTokens.dark
    ) {
        self.rating = rating
        self.title = title
        self.diameter = diameter
        self.palette = palette
    }

    /// Where this rating sits on the 40-99 scale — the proportion the arc is entitled to draw.
    private var proportion: Double {
        let floor = Double(CoachWorldTokens.Heat.scaleFloor)
        let ceiling = Double(CoachWorldTokens.Heat.scaleCeiling)
        return min(1, max(0, (Double(rating) - floor) / (ceiling - floor)))
    }

    var body: some View {
        ZStack {
            // Only the arcs rotate. Rotating the whole stack turned the figure and its label
            // upside down — the reading has to stay upright whatever angle the gauge starts at.
            ZStack {
                Circle()
                    .trim(from: 0, to: Pattern.dialSweepFraction)
                    .stroke(
                        palette.contentQuiet.color.opacity(Pattern.trackAlpha),
                        style: .init(lineWidth: Pattern.dialWidth, lineCap: .round)
                    )
                Circle()
                    .trim(from: 0, to: Pattern.dialSweepFraction * proportion)
                    .stroke(
                        CoachWorldTokens.Heat.color(for: rating, palette: palette),
                        style: .init(lineWidth: Pattern.dialWidth, lineCap: .round)
                    )
            }
            .rotationEffect(.degrees(Pattern.dialRotation))

            VStack(spacing: CoachWorldTokens.Gap.hair) {
                Text("\(rating)")
                    .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.figure, weight: .bold))
                FloodlitLabel3(title, palette: palette)
            }
        }
        .frame(width: diameter, height: diameter)
        // Personnel Room, `04` section 2: "a value settles to its new figure, it does not slide
        // there" — the arc's fill and the printed number move together on a rating change, never a
        // hard cut between two states.
        .coachWorldAnimation(CoachWorldTokens.Motion.value, value: rating)
        // The whole dial is one element; the ring is a second reading of the printed figure, never
        // the only one (`04` section 4.4).
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(rating) out of \(CoachWorldTokens.Heat.scaleCeiling)")
    }
}

/// The arc family's smallest step, flattened: a 4 pt share of a stated whole.
struct FloodlitShareBar: View {
    private let proportion: Double
    private let tint: Color?
    private let palette: CoachWorldTokens.Palette

    init(
        proportion: Double,
        tint: Color? = nil,
        palette: CoachWorldTokens.Palette = CoachWorldTokens.dark
    ) {
        self.proportion = min(1, max(0, proportion))
        self.tint = tint
        self.palette = palette
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(palette.contentQuiet.color.opacity(Pattern.trackAlpha))
                Capsule()
                    .fill(tint ?? palette.actionPrimary.color)
                    .frame(width: geometry.size.width * proportion)
            }
        }
        .frame(height: Pattern.shareBarHeight)
        .accessibilityHidden(true)
    }
}

// MARK: - 5. Pill / Flag

/// The only capsules in the system, with `Flag`. Selected takes the gold field.
struct FloodlitPill: View {
    private let title: String
    private let isSelected: Bool
    private let palette: CoachWorldTokens.Palette
    private let action: (() -> Void)?

    init(
        _ title: String,
        isSelected: Bool = false,
        palette: CoachWorldTokens.Palette = CoachWorldTokens.dark,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.isSelected = isSelected
        self.palette = palette
        self.action = action
    }

    var body: some View {
        if let action {
            Button(action: action) { label }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
        } else {
            label
        }
    }

    private var label: some View {
        Text(title.uppercased())
            .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.pill, weight: .bold))
            .foregroundStyle(
                isSelected ? CoachWorldTokens.Floodlit.goldInk.color : palette.contentSecondary.color
            )
            .lineLimit(1)
            .padding(.horizontal, CoachWorldTokens.Gap.md)
            .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
            .background {
                if isSelected {
                    Capsule().fill(CoachWorldTokens.Floodlit.goldField)
                } else {
                    Capsule().fill(palette.work.color.opacity(Pattern.rowFill))
                }
            }
            .overlay {
                Capsule().stroke(
                    Color.white.opacity(Pattern.rowHairline),
                    lineWidth: CoachWorldTokens.Shape.hairline
                )
            }
            .contentShape(Capsule())
            .accessibilityLabel(title)
    }
}

/// A staff verdict, not a status: `Staff pick`, `Against grade`. Never interactive — a flag is
/// something the game says about an option, so tapping it would have nothing to do.
struct FloodlitFlag: View {
    private let title: String
    private let tint: Color
    private let palette: CoachWorldTokens.Palette

    init(
        _ title: String,
        tint: Color? = nil,
        palette: CoachWorldTokens.Palette = CoachWorldTokens.dark
    ) {
        self.title = title
        self.tint = tint ?? palette.actionPrimary.color
        self.palette = palette
    }

    var body: some View {
        Text(title.uppercased())
            .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.flag, weight: .bold))
            .tracking(Pattern.flagTracking)
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, CoachWorldTokens.Gap.xs)
            .padding(.vertical, CoachWorldTokens.Gap.hair)
            .overlay {
                Capsule().stroke(tint.opacity(0.5), lineWidth: CoachWorldTokens.Shape.hairline)
            }
            .accessibilityLabel(title)
    }
}

// MARK: - 6. Staff voice

/// Attributed advice: a monogram, a name and role, and a quoted opinion.
///
/// Quoted and attributed on purpose. `04` section 4.4 rejects invented authority — advice that
/// appears in the interface's own voice reads as the game telling the coach what is true, where
/// the same sentence behind a name and a monogram reads as one person's read of it.
struct FloodlitStaffVoice: View {
    private let staff: CoachWorldPersonReference
    private let advice: String
    private let palette: CoachWorldTokens.Palette

    init(
        staff: CoachWorldPersonReference,
        advice: String,
        palette: CoachWorldTokens.Palette = CoachWorldTokens.dark
    ) {
        self.staff = staff
        self.advice = advice
        self.palette = palette
    }

    private var monogram: String {
        let initials = staff.name
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
        return initials.isEmpty ? "?" : String(initials).uppercased()
    }

    var body: some View {
        HStack(alignment: .top, spacing: CoachWorldTokens.Gap.smPlus) {
            Text(monogram)
                .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.actionSmall, weight: .bold))
                .foregroundStyle(palette.contentSecondary.color)
                .frame(width: Pattern.monogram, height: Pattern.monogram)
                .background(CoachWorldCutCorner.chip.fill(palette.work.color))
                .overlay {
                    CoachWorldCutCorner.chip.stroke(
                        Color.white.opacity(Pattern.rowHairline),
                        lineWidth: CoachWorldTokens.Shape.hairline
                    )
                }
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                // Curly quotes and an em dash for the turn, per the handoff's copy rules.
                Text("\u{201C}\(advice)\u{201D}")
                    .font(CoachWorldTokens.TypeRole.body)
                    .foregroundStyle(palette.contentSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\u{2014} \(staff.name), \(staff.role)")
                    .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.flag, weight: .semibold))
                    .foregroundStyle(palette.contentQuiet.color)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(staff.name), \(staff.role), says: \(advice)")
    }
}

// MARK: - 7. Committing action

/// One per screen, bottom-right in the thumb arc. The only gold field and the only glow.
///
/// Shared with Match Day, which is where it was first built — it is the same control and must not
/// fork into two that drift.
struct FloodlitCommittingAction: View {
    private let title: String
    private let isEnabled: Bool
    private let action: () -> Void

    init(_ title: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        CommittingAction(title: title, action: action)
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : CoachWorldTokens.Motion.disabledOpacity)
            // There is one of these per screen (`04` section 6.5), and `04` section 7 requires it
            // to be in the initial viewport. Naming it here is what lets the proof enumerate the
            // class by construction instead of listing labels screen by screen.
            .accessibilityIdentifier("committing-action")
    }
}

// MARK: - 8. Cost line

/// What every option on a decision surface carries: a cost, an exposure, and a consequence with a
/// real arrow. **The interface never says which to pick** — so there is deliberately no
/// "recommended" state on this view, and adding one would be a design defect rather than a feature.
struct FloodlitCostLine: View {
    private let cost: String
    private let exposure: String?
    private let consequence: String?
    private let palette: CoachWorldTokens.Palette

    init(
        cost: String,
        exposure: String? = nil,
        consequence: String? = nil,
        palette: CoachWorldTokens.Palette = CoachWorldTokens.dark
    ) {
        self.cost = cost
        self.exposure = exposure
        self.consequence = consequence
        self.palette = palette
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
            // The middle dot separates, always — never a pipe or a slash.
            Text([cost, exposure].compactMap { $0 }.joined(separator: " · ").uppercased())
                .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.flag, weight: .semibold))
                .tracking(
                    CoachWorldTokens.DisplaySize.tracking(0.12, at: CoachWorldTokens.DisplaySize.flag)
                )
                .foregroundStyle(palette.contentSecondary.color)
            if let consequence {
                Text(consequence)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentQuiet.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            [cost, exposure, consequence].compactMap { $0 }.joined(separator: ". ")
        )
    }
}

/// The strip a surface pins above the home indicator: the note and the committing action.
///
/// It must be opaque. A `safeAreaInset` draws *over* the scrolling content beneath it, so a
/// transparent strip lets rows run through the sentence -- which is what six surfaces did before
/// this existed. One treatment, applied by every surface that pins a footer.
struct FloodlitFooterStrip: ViewModifier {
    var palette: CoachWorldTokens.Palette = CoachWorldTokens.dark

    func body(content: Content) -> some View {
        content
            .padding(.vertical, CoachWorldTokens.Pad.alert.v)
            .padding(.horizontal, CoachWorldTokens.Pad.alert.h)
            .frame(maxWidth: .infinity)
            .background(
                CoachWorldCutCorner.row.fill(CoachWorldTokens.Floodlit.glassFlatDeep.color)
            )
            .overlay {
                CoachWorldCutCorner.row.stroke(
                    Color.white.opacity(CoachWorldTokens.Glass.line),
                    lineWidth: CoachWorldTokens.Shape.hairline
                )
            }
            .padding(.top, CoachWorldTokens.Gap.xs)
    }
}

extension View {
    func floodlitFooterStrip(
        palette: CoachWorldTokens.Palette = CoachWorldTokens.dark
    ) -> some View {
        modifier(FloodlitFooterStrip(palette: palette))
    }
}

// MARK: - Literals

private enum Pattern {
    static let rowMinHeight: CGFloat = 32
    static let rowFill = 0.55
    static let rowHairline = 0.14
    static let trackAlpha = 0.22

    static let arcDiameter: CGFloat = 64
    static let arcWidth: CGFloat = 11
    /// Derived once rather than inline: the stroke is centred on the path, so the drawn radius is
    /// half the diameter less half the stroke, or the arc paints outside its own frame.
    static let arcCentre = CGPoint(x: arcDiameter / 2, y: arcDiameter / 2)
    static let arcRadius: CGFloat = arcDiameter / 2 - arcWidth / 2
    /// An open arc: 240 degrees of sweep starting from the lower left.
    static let arcStart: Double = 150
    static let arcSweep: Double = 240

    static let dialDiameter: CGFloat = 212
    static let dialWidth: CGFloat = 7
    /// The same 240-degree sweep as `ArcGauge`, expressed as a trim fraction.
    static let dialSweepFraction: CGFloat = 240 / 360
    /// Rotates the trim's 3-o'clock origin round to the arc's lower-left start.
    static let dialRotation: Double = 150

    static let shareBarHeight: CGFloat = 4
    static let flagTracking: CGFloat = 1.35
    static let monogram: CGFloat = 26
}

// MARK: - 9. Confidence tag (registry 12)

/// A banded confidence, an unknown, or an observation count — `04` section 6.5 #12.
///
/// This is **this codebase's equivalent of the reference's `78 ±3`**, and the difference is a
/// modelling decision rather than a gap. The reference prints a numeric band on every rating,
/// including players on your own roster. This game does not fog players you own — their attributes
/// carry `confidence: "Known"` — because a head coach knows his own squad. Fog belongs to the
/// people you have *not* coached: recruits (`Evaluation.uncertainty`) and scouted pros
/// (`ProspectRow.estimatedOverall` with `confidence`).
///
/// So a confidence tag is drawn where an estimate is genuinely an estimate, and nowhere else.
/// Printing one on a known rating would claim a doubt the simulation does not hold.
struct CoachWorldConfidenceTag: View {
    /// What the tag is qualifying.
    enum Band: Equatable {
        /// A stated band: `Low`, `Medium`, `High`.
        case banded(String)
        /// Nothing has been observed yet.
        case unknown
        /// How many observations back the estimate.
        case observations(Int)
    }

    let band: Band
    var palette: CoachWorldTokens.Palette = CoachWorldTokens.dark

    private var text: String {
        switch band {
        case let .banded(label): label
        case .unknown: "Unknown"
        case let .observations(count):
            count == 1 ? "1 look" : "\(count) looks"
        }
    }

    /// Unknown is quiet, not alarming: an absent observation is not a bad one.
    private var tint: Color {
        switch band {
        case .unknown: palette.contentQuiet.color
        default: palette.stateInfo.color
        }
    }

    var body: some View {
        Text(text.uppercased())
            .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.flag, weight: .bold))
            .tracking(
                CoachWorldTokens.DisplaySize.tracking(0.12, at: CoachWorldTokens.DisplaySize.flag)
            )
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, CoachWorldTokens.Gap.xxs)
            .padding(.vertical, CoachWorldTokens.Gap.hair)
            .overlay {
                CoachWorldCutCorner.row.stroke(
                    tint.opacity(0.45), lineWidth: CoachWorldTokens.Shape.hairline
                )
            }
            .accessibilityLabel("Confidence: \(text)")
    }
}
