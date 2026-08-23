import SwiftUI
import FootballSimCore

public struct DepthChartView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: DepthChartReadModel
    public let title: String
    public let statusMessage: String?
    public let onSelect: (PersonnelPlan) -> Void
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedID: String
    @State private var unit = DepthUnit.offense
    @State private var openPositionID: String?

    public init(
        model: DepthChartReadModel,
        title: String = "DEPTH CHART",
        statusMessage: String? = nil,
        onSelect: @escaping (PersonnelPlan) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.model = model
        self.title = title
        self.statusMessage = statusMessage
        self.onSelect = onSelect
        self.onClose = onClose
        _selectedID = State(initialValue: model.options.first {
            $0.plan == model.currentPlan
        }?.id ?? "")
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    public var body: some View {
        CoachWorldFloodlitStage(palette: palette, chrome: chrome, onNavigate: onNavigateChrome) {
            scrollContent
        }
        .accessibilitySortPriority(100)
        // Beside the stage, not inside its stack. As a stack child the stamp measured a
        // point and took the stack's spacing with it, pushing every surface down 10
        // points in a 390-point window -- a layout cost for a marker that is meant to
        // have none.
        .background(alignment: .topLeading) { CanonicalScreenStamp(id: 17) }
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.md) {
                unitBar
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if dynamicTypeSize.isAccessibilitySize {
                    // The diagram is a second reading of the list, never the only one, so at AX
                    // sizes the list stands alone rather than a 390pt field being scaled to nothing.
                    groupSelector
                    positionList
                    optionList
                } else {
                    HStack(alignment: .top, spacing: CoachWorldTokens.Gap.lg) {
                        fieldDiagram
                            .frame(width: DepthMetric.fieldWidth, height: DepthMetric.fieldHeight)
                        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.md) {
                            groupSelector
                            positionList
                            optionList
                        }
                    }
                }
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) { vacancyStrip }
    }

    private var unitBar: some View {
        HStack(spacing: CoachWorldTokens.Gap.xs) {
            ForEach(DepthUnit.allCases, id: \.rawValue) { candidate in
                FloodlitPill(
                    candidate.rawValue,
                    isSelected: unit == candidate,
                    palette: palette,
                    action: {
                        unit = candidate
                        openPositionID = nil
                    }
                )
            }
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitLabel3(model.weekLabel, palette: palette)
        }
    }

    /// The groups on the field for the chosen unit, in the order the model records them.
    private var visibleGroups: [DepthChartReadModel.PositionGroup] {
        model.positions.filter { unit.holds($0.id) }
    }

    private var openGroup: DepthChartReadModel.PositionGroup? {
        visibleGroups.first { $0.id == openPositionID } ?? visibleGroups.first
    }

    /// The reachable position-group picker. `token(_:)`, below, sets `openPositionID` too, but it
    /// draws inside `fieldDiagram`, which is `.accessibilityHidden(true)` at every type size and
    /// is not constructed at all once `dynamicTypeSize.isAccessibilitySize` -- so before this, a
    /// VoiceOver coach at any size, or any coach at AX5, could reach only the first group of
    /// whichever unit the pills last selected, never the other fourteen. This renders in both
    /// compositions so the same control works regardless of type size or assistive technology.
    private var groupSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: CoachWorldTokens.Gap.xs) {
                ForEach(visibleGroups) { group in
                    FloodlitPill(
                        group.title,
                        isSelected: openGroup?.id == group.id,
                        palette: palette,
                        action: { openPositionID = group.id }
                    )
                }
            }
        }
    }

    /// The handoff's field diagram: a token per position, placed where that position stands.
    ///
    /// The placement is a **drawing convention of the sport**, which `04` section 6.6 already
    /// distinguishes from invented evidence -- a left tackle stands left of the centre whatever the
    /// simulation records. No formation is claimed, because the model records none; what is drawn
    /// is where each position group sits relative to the others, and a group the convention has no
    /// spot for stays in the list rather than being dropped somewhere plausible.
    private var fieldDiagram: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                CoachWorldCutCorner.card.fill(palette.fieldTurf.color)
                ForEach(0..<DepthMetric.yardLines, id: \.self) { index in
                    Rectangle()
                        .fill(palette.fieldLine.color.opacity(DepthMetric.lineAlpha))
                        .frame(height: CoachWorldTokens.Shape.hairline)
                        .offset(
                            y: proxy.size.height
                                * (Double(index + 1) / Double(DepthMetric.yardLines + 1))
                        )
                        .accessibilityHidden(true)
                }
                ForEach(placedGroups, id: \.group.id) { placed in
                    let width = tokenWidth(for: placed.placement, in: proxy.size)
                    token(placed.group)
                        .frame(width: width, height: DepthMetric.tokenHeight)
                        .offset(
                            x: proxy.size.width * placed.placement.x - width / 2,
                            y: proxy.size.height * placed.placement.y - DepthMetric.tokenHeight / 2
                        )
                }
            }
        }
        .accessibilityHidden(true)
    }

    /// The groups the convention has a spot for, with that spot resolved. A group with no spot is
    /// not drawn on the field; it is still in the list, which is the authority.
    private var placedGroups: [(group: DepthChartReadModel.PositionGroup, placement: DepthPlacement)] {
        visibleGroups.compactMap { group in
            DepthPlacement.placement(for: group.id).map { (group, $0) }
        }
    }

    /// A token is as wide as its row allows, never wider than the handoff's 84pt. Fixing the width
    /// instead would overlap the six-across line row on a 390pt field, which is what the first pass
    /// did -- the tokens are what the row can hold, not a constant.
    private func tokenWidth(for placement: DepthPlacement, in size: CGSize) -> CGFloat {
        min(
            DepthMetric.tokenWidth,
            size.width / CGFloat(placement.columns) - DepthMetric.tokenGap
        )
    }

    private func fieldPlayerName(_ name: String?) -> String {
        guard let name else { return "Vacant" }
        let parts = name.split(separator: " ")
        guard parts.count > 1 else { return name }
        return "\(parts[0].prefix(1)). \(parts.dropFirst().joined(separator: " "))"
    }

    private func token(_ group: DepthChartReadModel.PositionGroup) -> some View {
        let starter = group.slots.first
        let isOpen = openGroup?.id == group.id
        // The vacancy beam: a position whose starter cannot play is the thing this screen exists
        // to show, so it takes the warning tint rather than a quiet one.
        let vacant = starter == nil || starter?.isUnavailable == true
        // This token stays undrawn by @ScaledMetric on purpose: it is drawn inside `fieldDiagram`,
        // which is `.accessibilityHidden(true)` in its entirety and the caller fixes both
        // dimensions (`token(...).frame(width:height:)` at fieldDiagram's call site), so scaling
        // here would only risk clipping an already small field token for sighted low-vision users,
        // without helping a VoiceOver user this diagram is inaccessible to either way. Group
        // selection itself no longer depends on this diagram at all -- `groupSelector`, above, is
        // the reachable control every type size and every accessibility technology can use; this
        // token's own tap-to-select stays as a sighted-only shortcut into the same state.
        return Button {
            openPositionID = group.id
        } label: {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                Text(DepthPlacement.abbreviation(for: group.id))
                    .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.pill, weight: .bold))
                    .foregroundStyle(
                        vacant ? palette.stateWarning.color : palette.contentPrimary.color
                    )
                Text(fieldPlayerName(starter?.playerName))
                    .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.flag))
                    .foregroundStyle(palette.contentSecondary.color)
                    .lineLimit(1)
            }
            .padding(.horizontal, CoachWorldTokens.Gap.sm)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(
                CoachWorldCutCorner.row.fill(
                    palette.page.color.opacity(DepthMetric.tokenFill)
                )
            )
            .overlay {
                CoachWorldCutCorner.row.stroke(
                    isOpen
                        ? palette.actionPrimary.color
                        : (vacant ? palette.stateWarning.color : Color.white.opacity(DepthMetric.tokenHairline)),
                    lineWidth: CoachWorldTokens.Shape.hairline
                )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(DepthPlacement.abbreviation(for: group.id)), \(starter?.playerName ?? "Vacant")"
        )
    }

    /// The open position's ordering, deepest chart first. This is the list the diagram is a second
    /// reading of, and the only place the ordering is actually stated.
    @ViewBuilder
    private var positionList: some View {
        if let group = openGroup {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xxs) {
                HStack(spacing: CoachWorldTokens.Gap.smPlus) {
                    FloodlitLabel3(group.title, palette: palette)
                    Spacer(minLength: CoachWorldTokens.Gap.xs)
                    FloodlitLabel3(
                        group.slots.count == 1 ? "1 deep" : "\(group.slots.count) deep",
                        palette: palette
                    )
                }
                ForEach(Array(group.slots.enumerated()), id: \.element.id) { index, slot in
                    slotRow(slot, at: index)
                }
            }
        }
    }

    private func slotRow(_ slot: DepthChartReadModel.Slot, at index: Int) -> some View {
        FloodlitRow(palette: palette) {
            HStack(spacing: CoachWorldTokens.Gap.md) {
                Text(index == 0 ? "START" : "\(index + 1)")
                    .coachWorldDisplay(CoachWorldTokens.DisplaySize.flag, weight: .bold)
                    .foregroundStyle(
                        slot.isUnavailable
                            ? palette.stateWarning.color
                            : palette.contentQuiet.color
                    )
                    .frame(width: DepthMetric.rankColumn, alignment: .leading)
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                    Text(slot.playerName.uppercased())
                        .coachWorldDisplay(CoachWorldTokens.DisplaySize.row, weight: .bold)
                        .lineLimit(1)
                    Text(slot.availability)
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentSecondary.color)
                        .lineLimit(1)
                }
                Spacer(minLength: CoachWorldTokens.Gap.xs)
                if slot.isOverride {
                    FloodlitFlag("Your call", tint: palette.actionPrimary.color, palette: palette)
                }
            }
        }
        .accessibilityLabel(
            "\(slot.playerName), \(index == 0 ? "starter" : "depth \(index + 1)"). "
                + slot.availability
                + (slot.isOverride ? ". Your call." : "")
        )
    }

    /// The available chart choices. Tapping a row only selects it; the footer owns the commit.
    private var optionList: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xxs) {
            FloodlitLabel3("What a different order costs", palette: palette)
            ForEach(model.options) { option in
                FloodlitRow(
                    isSelected: selectedID == option.id,
                    palette: palette,
                    action: {
                        selectedID = option.id
                    }
                ) {
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                        Text(option.title.uppercased())
                            .coachWorldDisplay(CoachWorldTokens.DisplaySize.row, weight: .bold)
                            .lineLimit(1)
                        // A sentence, not a cost phrase: `FloodlitCostLine` uppercases and
                        // tracks its cost slot, which turns prose into a tracked-capitals
                        // paragraph. These options carry a consequence and no cost figure.
                        Text(option.consequence)
                            .font(CoachWorldTokens.TypeRole.caption)
                            .foregroundStyle(palette.contentSecondary.color)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityLabel("\(option.title). \(option.consequence)")
            }
        }
    }

    /// The reference's alert strip, carrying the thing this screen is for: who cannot play, and
    /// what the chart does about it.
    private var vacancyStrip: some View {
        HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            Text(vacancyMessage)
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(
                    vacantGroups.isEmpty ? palette.contentSecondary.color : palette.contentPrimary.color
                )
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitCommittingAction(
                selectedOption.map { "Set \($0.title)" } ?? "Set the chart",
                action: {
                    guard let selectedOption else { return }
                    onSelect(selectedOption.plan)
                    onClose()
                }
            )
            .disabled(selectedOption == nil)
        }
        .padding(.vertical, CoachWorldTokens.Pad.alert.v)
        .padding(.horizontal, CoachWorldTokens.Pad.alert.h)
        .frame(maxWidth: .infinity)
        .background(CoachWorldCutCorner.row.fill(CoachWorldTokens.Floodlit.glassFlatDeep.color))
        .overlay {
            CoachWorldCutCorner.row.stroke(
                vacantGroups.isEmpty
                    ? Color.white.opacity(CoachWorldTokens.Glass.line)
                    : palette.stateWarning.color.opacity(DepthMetric.alertBorderAlpha),
                lineWidth: CoachWorldTokens.Shape.hairline
            )
        }
        .padding(.top, CoachWorldTokens.Gap.xs)
    }

    private var vacantGroups: [DepthChartReadModel.PositionGroup] {
        model.positions.filter { $0.slots.first?.isUnavailable ?? true }
    }

    private var selectedOption: DepthChartReadModel.Option? {
        model.options.first { $0.id == selectedID } ?? model.options.first
    }

    private var vacancyMessage: String {
        let names = vacantGroups.map(\.title)
        switch names.count {
        case 0:
            return "Every position has a starter who can play. "
                + "The chart falls back on its own if that changes."
        case 1:
            return "\(names[0]) has no starter who can play. "
                + "The chart falls back to the next name unless you set one."
        default:
            return "\(names.count) positions have no starter who can play: "
                + names.joined(separator: ", ") + "."
        }
    }
}

/// The unit pills. `Position.unit` already partitions the fifteen positions three ways, so this
/// reads that partition rather than restating it.
private enum DepthUnit: String, CaseIterable {
    case offense = "Offense"
    case defense = "Defense"
    case specialTeams = "Special teams"

    func holds(_ positionID: String) -> Bool {
        guard let position = Position(rawValue: positionID) else { return false }
        switch (self, position.unit) {
        case (.offense, .offense), (.defense, .defense), (.specialTeams, .specialTeams):
            return true
        default:
            return false
        }
    }
}

/// Where each position stands on the diagram, as a row and a column within that row.
///
/// A drawing convention of the sport, not a formation the simulation recorded: the line stands
/// across the middle with the quarterback behind it and the back behind him; the secondary plays
/// deepest and the rush stands closest. Rows and columns rather than free coordinates because the
/// tokens must not overlap at any field width -- a fixed pair of fractions overlapped the
/// six-across line row and pushed the wide receiver off the plane.
private struct DepthPlacement {
    let row: Int
    let rows: Int
    let column: Int
    let columns: Int

    var x: Double { (Double(column) + 0.5) / Double(columns) }
    var y: Double { (Double(row) + 0.5) / Double(rows) }

    static func placement(for positionID: String) -> DepthPlacement? {
        guard let position = Position(rawValue: positionID) else { return nil }
        switch position {
        // Offence: the line across, the quarterback behind it, the back behind him.
        case .wideReceiver: return .init(row: 0, rows: 3, column: 0, columns: 6)
        case .leftTackle: return .init(row: 0, rows: 3, column: 1, columns: 6)
        case .guardPosition: return .init(row: 0, rows: 3, column: 2, columns: 6)
        case .center: return .init(row: 0, rows: 3, column: 3, columns: 6)
        case .rightTackle: return .init(row: 0, rows: 3, column: 4, columns: 6)
        case .tightEnd: return .init(row: 0, rows: 3, column: 5, columns: 6)
        case .quarterback: return .init(row: 1, rows: 3, column: 0, columns: 1)
        case .runningBack: return .init(row: 2, rows: 3, column: 0, columns: 1)
        // Defence: the secondary deepest, the rush nearest the line.
        case .cornerback: return .init(row: 0, rows: 3, column: 0, columns: 2)
        case .safety: return .init(row: 0, rows: 3, column: 1, columns: 2)
        case .linebacker: return .init(row: 1, rows: 3, column: 0, columns: 1)
        case .edgeRusher: return .init(row: 2, rows: 3, column: 0, columns: 2)
        case .defensiveTackle: return .init(row: 2, rows: 3, column: 1, columns: 2)
        // Specialists: both on the one row, because that is the whole unit.
        case .kicker: return .init(row: 0, rows: 1, column: 0, columns: 2)
        case .punter: return .init(row: 0, rows: 1, column: 1, columns: 2)
        }
    }

    /// The chart's own shorthand. Drawn uppercase; spoken as the full title from the list.
    static func abbreviation(for positionID: String) -> String {
        guard let position = Position(rawValue: positionID) else { return "--" }
        switch position {
        case .quarterback: return "QB"
        case .runningBack: return "RB"
        case .wideReceiver: return "WR"
        case .tightEnd: return "TE"
        case .leftTackle: return "LT"
        case .guardPosition: return "G"
        case .center: return "C"
        case .rightTackle: return "RT"
        case .edgeRusher: return "EDGE"
        case .defensiveTackle: return "DT"
        case .linebacker: return "LB"
        case .cornerback: return "CB"
        case .safety: return "S"
        case .kicker: return "K"
        case .punter: return "P"
        }
    }
}

private enum DepthMetric {
    /// The handoff's 390pt-wide field. Its 222pt height does not survive the port: the handoff
    /// draws a bare 46pt nav row above the field where this build carries the identity band and
    /// the sibling row, which together stand about 40pt taller. 185 is what is left between the
    /// unit pills and the alert strip at the 844x390 install floor, and a field that overlapped
    /// its own alert bar would be worse than a shorter one.
    static let fieldWidth: CGFloat = 390
    static let fieldHeight: CGFloat = 185
    static let tokenWidth: CGFloat = 84
    static let tokenGap: CGFloat = 5
    static let tokenHeight: CGFloat = 32
    static let rankColumn: CGFloat = 40
    static let yardLines = 4
    static let lineAlpha = 0.5
    static let tokenFill = 0.72
    static let tokenHairline = 0.16
    static let alertBorderAlpha = 0.45
}
