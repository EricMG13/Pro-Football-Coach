import SwiftUI

public struct StaffRoomView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: StaffRoomReadModel
    public let title: String
    public let statusMessage: String?
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var openStaffID: UUID?

    public init(
        model: StaffRoomReadModel,
        title: String = "STAFF ROOM",
        statusMessage: String? = nil,
        onClose: @escaping () -> Void
    ) {
        self.model = model
        self.title = title
        self.statusMessage = statusMessage
        self.onClose = onClose
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    public var body: some View {
        CoachWorldFloodlitStage(palette: palette, chrome: chrome, onNavigate: onNavigateChrome) {
            scrollContent
        }
        .accessibilitySortPriority(100)
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.md) {
                header
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if model.rows.isEmpty {
                    CoachWorldSystemState(
                        .empty("No employed staff are recorded for this organisation."),
                        palette: palette
                    )
                } else if dynamicTypeSize.isAccessibilitySize {
                    staffList
                    staffPanel
                } else {
                    HStack(alignment: .top, spacing: CoachWorldTokens.Gap.lg) {
                        staffList
                        staffPanel
                            .frame(width: StaffMetric.panelWidth)
                    }
                }
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
        .safeAreaInset(edge: .bottom) { footer }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.xs) {
            FloodlitLabel3(
                "\(title) \u{00B7} \(model.seasonLabel) \u{00B7} "
                    + (model.rows.count == 1 ? "1 on staff" : "\(model.rows.count) on staff"),
                palette: palette
            )
            Spacer(minLength: CoachWorldTokens.Gap.xs)
        }
    }

    /// The reference's staff list: a monogram, the name and the role, and the standing as a ring.
    ///
    /// The reference also draws a delegation chip on every row. Nothing in `StaffRoomReadModel`
    /// records what is delegated to whom, so no chip is drawn: a toggle that has nothing to toggle
    /// is worse than an absent control.
    private var staffList: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xxs) {
            ForEach(model.rows) { row in
                FloodlitRow(
                    isSelected: openStaff?.id == row.id,
                    palette: palette,
                    action: { openStaffID = row.id }
                ) {
                    HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
                        monogram(for: row.name)
                        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                            Text(row.name.uppercased())
                                .coachWorldDisplay(CoachWorldTokens.DisplaySize.row, weight: .bold)
                                .lineLimit(1)
                            FloodlitLabel3(row.role, palette: palette)
                        }
                        Spacer(minLength: CoachWorldTokens.Gap.xs)
                        CoachWorldRatingRing(
                            value: row.reputation,
                            diameter: StaffMetric.ringDiameter,
                            palette: palette
                        )
                    }
                }
                .accessibilityLabel(
                    "\(row.name), \(row.role), reputation \(row.reputation), "
                        + tenure(row).lowercased()
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Initials, not a likeness. The product draws no faces.
    private func monogram(for name: String) -> some View {
        let initials = name
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map(String.init) }
            .joined()
        // Deferred (S-0 Phase 3, 2026-08-19): fixed in both dimensions, no lineLimit clamp and no
        // minimumScaleFactor at all -- the same unguarded fixed-frame class as FloodlitStaffVoice's
        // monogram, already deferred in FloodlitPatterns.swift. Two initials rarely overflow, but
        // there is no safety net if they do; needs a considered geometry fix, not a token swap.
        return Text(initials.uppercased())
            .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.flag, weight: .bold))
            .foregroundStyle(palette.contentSecondary.color)
            .frame(width: StaffMetric.monogram, height: StaffMetric.monogram)
            .background(Circle().fill(palette.work.color.opacity(StaffMetric.monogramFill)))
            .accessibilityHidden(true)
    }

    private var openStaff: StaffRoomReadModel.StaffRow? {
        model.rows.first { $0.id == openStaffID } ?? model.rows.first
    }

    /// The open coach: what they are for, stated as the four ratings the simulation actually holds.
    @ViewBuilder
    private var staffPanel: some View {
        if let row = openStaff {
            FloodlitCard(palette: palette, depth: .deep) {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
                    FloodlitLabel3(row.role, palette: palette)
                    Text(row.name.uppercased())
                        .coachWorldDisplay(CoachWorldTokens.DisplaySize.subject, weight: .bold)
                        .lineLimit(StaffMetric.nameLines)
                    Text(tenure(row))
                        .coachWorldFigure(CoachWorldTokens.DisplaySize.pill)
                        .foregroundStyle(palette.contentSecondary.color)
                    ratingRow("Development", row.development)
                    ratingRow("Recruiting", row.recruiting)
                    ratingRow("Game planning", row.gamePlanning)
                    ratingRow("Scheme fit", row.schemeAffinity)
                    // G-02: an engine-owned verdict in a named staff voice does not exist yet, and
                    // `04` section 4.4 refuses a sentence in the interface's own voice. The slot
                    // says what is missing rather than inventing an opinion to fill it.
                    Text("No staff verdict is recorded for this coach yet.")
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentQuiet.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func tenure(_ row: StaffRoomReadModel.StaffRow) -> String {
        let seasons = row.seasonsWithProgramme
        let together = seasons == 1 ? "1 season together" : "\(seasons) seasons together"
        return "Age \(row.age) \u{00B7} \(together)"
    }

    private func ratingRow(_ label: String, _ value: Int) -> some View {
        let tint = CoachWorldTokens.Heat.color(for: value, palette: palette)
        return HStack(spacing: CoachWorldTokens.Gap.smPlus) {
            FloodlitLabel3(label, palette: palette)
                .frame(width: StaffMetric.ratingLabel, alignment: .leading)
            FloodlitShareBar(proportion: proportion(of: value), tint: tint, palette: palette)
            Text("\(value)")
                .coachWorldFigure(CoachWorldTokens.DisplaySize.pill, weight: .semibold)
                .foregroundStyle(tint)
                .frame(width: StaffMetric.ratingFigure, alignment: .trailing)
        }
        .frame(minHeight: StaffMetric.ratingRowHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }

    /// Where a rating sits on the 40-99 scale, not a percentage of 99.
    private func proportion(of rating: Int) -> Double {
        let floor = CoachWorldTokens.Heat.scaleFloor
        let ceiling = CoachWorldTokens.Heat.scaleCeiling
        let clamped = min(max(rating, floor), ceiling)
        return Double(clamped - floor) / Double(ceiling - floor)
    }

    private var footer: some View {
        HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            Text("These are the people who carry the week when you are not in the room.")
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            Button("Close", action: onClose)
                .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
        }
        .floodlitFooterStrip(palette: palette)
    }
}

private enum StaffMetric {
    /// The handoff's 291pt coach panel.
    static let panelWidth: CGFloat = 291
    static let monogram: CGFloat = 28
    static let monogramFill = 0.5
    static let ringDiameter: CGFloat = 28
    static let ratingLabel: CGFloat = 88
    static let ratingFigure: CGFloat = 26
    static let ratingRowHeight: CGFloat = 23
    static let nameLines = 2
}
