import SwiftUI
import FootballSimCore

public struct ClassOverviewView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: RecruitingBoardReadModel
    public let statusMessage: String?
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(model: RecruitingBoardReadModel, statusMessage: String? = nil,
                onClose: @escaping () -> Void) {
        self.model = model
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
                if dynamicTypeSize.isAccessibilitySize {
                    classCount
                    needsGrid
                } else {
                    HStack(alignment: .top, spacing: CoachWorldTokens.Gap.xl) {
                        classCount
                            .frame(width: ClassMetric.countColumn)
                        needsGrid
                    }
                }
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                committedList
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
        .safeAreaInset(edge: .bottom) { footer }
    }

    /// The reference leads with the class as one figure over a stated whole: committed against the
    /// scholarship limit, at display size.
    private var classCount: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
            FloodlitLabel3("The class \u{00B7} committed", palette: palette)
            HStack(alignment: .lastTextBaseline, spacing: CoachWorldTokens.Gap.smPlus) {
                Text("\(committedCount)")
                    .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.name, weight: .bold))
                // `CollegeRules.initialSigningsPerClass` is the engine's own per-class target.
                // The scholarship count the earlier draft compared against
                // (`capacity.scholarshipSlotsRemaining`) is whole-roster capacity against the
                // 85-man limit, not a signing-class size, and summing the two produced a total
                // with no real meaning.
                Text("of \(CollegeRules.initialSigningsPerClass)")
                    .font(
                        CoachWorldTokens.display(
                            CoachWorldTokens.DisplaySize.title, weight: .bold
                        )
                    )
                    .foregroundStyle(palette.contentSecondary.color)
            }
            FloodlitLabel3(
                "\(model.capacity.scholarshipSlotsRemaining) scholarships still open",
                palette: palette,
                tint: palette.actionPrimary.color
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(committedCount) committed of \(CollegeRules.initialSigningsPerClass), "
                + "\(model.capacity.scholarshipSlotsRemaining) scholarships still open"
        )
    }

    private var committedProspects: [RecruitingBoardReadModel.Prospect] {
        model.prospects.filter { $0.status == "Committed" || $0.status == "Signed" }
    }

    private var committedCount: Int { committedProspects.count }

    /// The reference frames this grid as recruiting-class progress. `PositionNeed.committed` is
    /// not that: it is a tally of the WHOLE current roster at a position
    /// (`CoachWorldRecruitingBoardProvider.positionNeeds`), and `.target` is the league's
    /// minimum-playable-roster floor (`SharedRules.minimumPlayableRosterByPosition`) -- neither
    /// figure is about this signing cycle. A position filled by returning veterans with zero new
    /// recruits this year would show as "full" here, which is true of the roster and false of the
    /// class. The section is titled for what the data actually says -- roster coverage against
    /// the league floor -- rather than borrowed class-progress language it cannot support.
    private var needsGrid: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
            FloodlitLabel3("Roster coverage against the league minimum", palette: palette)
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: CoachWorldTokens.Gap.sm),
                    GridItem(.flexible(), spacing: CoachWorldTokens.Gap.sm),
                    GridItem(.flexible(), spacing: CoachWorldTokens.Gap.sm),
                    GridItem(.flexible(), spacing: CoachWorldTokens.Gap.sm),
                ],
                spacing: CoachWorldTokens.Gap.sm
            ) {
                ForEach(model.positionNeeds, id: \.stableID) { need in
                    needCell(need)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// A share bar, not `CoachWorldRatingRing`: the ring's colour bands are calibrated to the
    /// 40-99 player-rating scale, and every one of these counts (roster headcount at a position,
    /// realistically 0-5) falls in the ring's "red" band regardless of how full the position
    /// actually is. `FloodlitShareBar` carries no scale assumption -- it just draws the proportion
    /// it is given, which is what a small count against a small target needs.
    private func needCell(_ need: RecruitingBoardReadModel.PositionNeed) -> some View {
        let short = max(0, need.target - need.committed)
        let tint = short == 0 ? palette.statePositive.color : palette.actionPrimary.color
        return VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
            Text(need.position.uppercased())
                .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.pill, weight: .bold))
                .lineLimit(1)
            FloodlitShareBar(
                proportion: need.target > 0 ? Double(need.committed) / Double(need.target) : 0,
                tint: tint,
                palette: palette
            )
            Text("\(need.committed)/\(need.target)")
                .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.flag))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, minHeight: ClassMetric.cellHeight, alignment: .leading)
        .padding(.horizontal, CoachWorldTokens.Gap.xs)
        .padding(.vertical, CoachWorldTokens.Gap.xxs)
        .background(
            CoachWorldCutCorner.card.fill(palette.work.color.opacity(ClassMetric.cellFill))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            short == 0
                ? "\(need.position), at the roster minimum"
                : "\(need.position), \(need.committed) of \(need.target) on the roster, "
                    + "\(short) short of the league minimum"
        )
    }

    /// The reference's "Signed and committed": one row per name already on the class.
    ///
    /// The reference sets a five-star rating per prospect. Nothing in `RecruitingBoardReadModel`
    /// records a star rating -- the closest figure is `Evaluation.verdict`, a sentence, not a
    /// count -- so no rating is drawn. Five empty stars beside every name would be a rating that
    /// reads as zero, which is worse than no rating at all.
    private var committedList: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
            FloodlitLabel3("Signed and committed", palette: palette)
            if committedProspects.isEmpty {
                Text("Nobody has committed to this class yet.")
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentQuiet.color)
            } else {
                ForEach(committedProspects, id: \.stableID) { prospect in
                    committedRow(prospect)
                }
            }
        }
    }

    private func committedRow(_ prospect: RecruitingBoardReadModel.Prospect) -> some View {
        HStack(spacing: CoachWorldTokens.Gap.md) {
            Text(prospect.person.name.uppercased())
                .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.row, weight: .bold))
                .lineLimit(1)
                .frame(width: ClassMetric.nameColumn, alignment: .leading)
            Text(prospect.position.uppercased())
                .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.flag, weight: .bold))
                .foregroundStyle(palette.stateInfo.color)
                .lineLimit(1)
                .frame(width: ClassMetric.positionColumn, alignment: .leading)
            Text(prospect.evaluation.schemeFit)
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentQuiet.color)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(prospect.status.uppercased())
                .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.flag, weight: .bold))
                .foregroundStyle(
                    prospect.status == "Signed"
                        ? palette.statePositive.color
                        : palette.actionPrimary.color
                )
                .lineLimit(1)
        }
        .frame(minHeight: ClassMetric.rowHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(prospect.person.name), \(prospect.position), \(prospect.status)"
        )
    }

    private var footer: some View {
        HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            Text(footerNote)
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitCommittingAction("Done", action: onClose)
        }
        .floodlitFooterStrip(palette: palette)
    }

    private var footerNote: String {
        let open = model.positionNeeds.filter { $0.committed < $0.target }
        if open.isEmpty { return "Every position is at or above the league's roster minimum." }
        let names = open.map(\.position).joined(separator: ", ")
        return open.count == 1
            ? "\(names) is below the league's roster minimum."
            : "\(open.count) positions are below the league's roster minimum: \(names)."
    }
}

private enum ClassMetric {
    static let countColumn: CGFloat = 240
    static let ringDiameter: CGFloat = 34
    static let cellHeight: CGFloat = 74
    static let cellFill = 0.32
    static let nameColumn: CGFloat = 160
    static let positionColumn: CGFloat = 44
    static let rowHeight: CGFloat = 24
}
