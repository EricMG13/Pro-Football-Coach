import SwiftUI

/// Shared chrome drawn from `chrome-v3` and `week-v3`. This is WorldStrip, local office routes,
/// AgendaRow, Meter and the failure set — not a screen chassis. Each family view still owns its
/// task composition; these types only stop seven copies of the same world strip from drifting.
enum CoachWorldNavigation {
    /// The five world-strip destinations `04` §3 names. A week-family screen still sits under Office.
    static func worldRoute(for screen: CoachWorldScreenID) -> CoachWorldScreenID {
        switch screen {
        case .coachingHQ, .inbox, .opponentReportFilmRoom, .gamePlan, .practicePlan,
             .teamHealth, .aftermath:
            return .coachingHQ
        case .roster, .playerProfile, .depthChart, .developmentPlan, .staffRoom,
             .staffMarketProfile, .schemeBook, .personnelPackages:
            return .roster
        case .recruitingBoard, .prospectProfile, .shortlist, .contactVisitPlanner,
             .classOverview, .signingDay, .portalHub, .retentionDecisions, .portalMarket,
             .nilAllocation:
            return .recruitingBoard
        case .leagueMap, .teamProgrammeProfile, .standings, .schedule,
             .rankingsPlayoffPicture, .bracketPostseason, .gameDetailBoxScore,
             .statisticsLeaders, .awardsHonours, .news, .realignmentEvent:
            return .leagueMap
        default:
            return .careerHub
        }
    }
}

struct CoachWorldHairline: View {
    let palette: CoachWorldTokens.Palette
    var axis: Axis = .horizontal

    var body: some View {
        Rectangle()
            .fill(palette.contentQuiet.color.opacity(0.45))
            .frame(
                width: axis == .vertical ? CoachWorldTokens.Shape.hairline : nil,
                height: axis == .horizontal ? CoachWorldTokens.Shape.hairline : nil
            )
    }
}

/// Registry 5. Programme colour may own this field (`04` §5); everything else on a management
/// screen stays neutral.
struct CoachWorldWorldStrip: View {
    let team: CoachWorldTeamReference
    let contextLine: String
    let statusMessage: String?
    let currentWorldRoute: CoachWorldScreenID
    let canAdvance: Bool
    let mandatoryDueCount: Int
    let palette: CoachWorldTokens.Palette
    let isAccessibilitySize: Bool
    let onContinue: () -> Void
    let onNavigate: (CoachWorldScreenID) -> Void

    private var identity: CoachWorldTeamIdentity? {
        CoachWorldTeamIdentity(
            team: team,
            behind: palette.raised,
            inks: [palette.page, palette.contentPrimary]
        )
    }

    var body: some View {
        Group {
            if isAccessibilitySize {
                VStack(spacing: CoachWorldTokens.Space.xs) {
                    identityBlock.frame(maxWidth: .infinity, alignment: .leading)
                    worldMenu.frame(maxWidth: .infinity, alignment: .leading)
                    continueButton.frame(maxWidth: .infinity)
                }
            } else {
                HStack(spacing: CoachWorldTokens.Space.xs) {
                    identityBlock
                    Divider().overlay(palette.contentQuiet.color)
                    HStack(spacing: .zero) {
                        route("Office", screen: .coachingHQ)
                        route("Team", screen: .roster)
                        route("Recruit", screen: .recruitingBoard)
                        route("League", screen: .leagueMap)
                        route("Career", screen: .careerHub)
                    }
                    .frame(maxWidth: .infinity)
                    continueButton
                }
            }
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .padding(.vertical, isAccessibilitySize ? CoachWorldTokens.Space.xs : .zero)
        .frame(height: isAccessibilitySize ? nil : CoachWorldChromeMetric.stripHeight)
        .background(palette.raised.color)
        .overlay(alignment: .bottom) { CoachWorldHairline(palette: palette) }
        .accessibilitySortPriority(50)
    }

    private var identityBlock: some View {
        HStack(spacing: CoachWorldTokens.Space.xs) {
            Text(team.abbreviation)
                .font(CoachWorldTokens.TypeRole.caption.weight(.black))
                .foregroundStyle(markInk.color)
                .padding(.horizontal, CoachWorldTokens.Space.xxs)
                .frame(
                    minWidth: CoachWorldChromeMetric.markWidth,
                    minHeight: CoachWorldChromeMetric.markHeight
                )
                .background(
                    (identity?.accent.color ?? palette.collegeIdentity.color),
                    in: RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius)
                )
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                Text(team.name.uppercased())
                    .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                    .lineLimit(1)
                Text(statusMessage ?? contextLine)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(contextInk)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(identity?.onField.color ?? palette.contentPrimary.color)
        .padding(.horizontal, CoachWorldTokens.Space.xs)
        .frame(maxHeight: .infinity)
        .background(identity?.field.color ?? palette.raised.color)
        .overlay(alignment: .trailing) {
            if identity?.needsBoundary == true {
                CoachWorldHairline(palette: palette, axis: .vertical)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(team.name), \(statusMessage ?? contextLine)")
    }

    private var worldMenu: some View {
        Menu("World") {
            Button("Office") { onNavigate(.coachingHQ) }
            Button("Team") { onNavigate(.roster) }
            Button("Recruit") { onNavigate(.recruitingBoard) }
            Button("League") { onNavigate(.leagueMap) }
            Button("Career") { onNavigate(.careerHub) }
        }
        .frame(
            minWidth: CoachWorldTokens.Shape.minimumTarget,
            minHeight: CoachWorldTokens.Shape.minimumTarget
        )
    }

    private var continueButton: some View {
        Button(action: onContinue) {
            Label(
                "Continue · \(mandatoryDueCount) due",
                systemImage: "forward.end.fill"
            )
        }
        .buttonStyle(CoachWorldActionButtonStyle(
            role: canAdvance ? .live : .secondary,
            palette: palette
        ))
        .disabled(!canAdvance)
    }

    private func route(_ title: String, screen: CoachWorldScreenID) -> some View {
        CoachWorldRouteButton(
            title: title,
            isCurrent: currentWorldRoute == screen,
            palette: palette,
            selection: identity?.selectionRule(on: palette.raised),
            action: { onNavigate(screen) }
        )
    }

    private var markInk: CoachWorldTokens.ColorValue {
        guard let accent = identity?.accent else { return palette.page }
        return accent.mostLegibleInk(from: [palette.page, palette.contentPrimary]) ?? palette.page
    }

    private var contextInk: Color {
        if statusMessage != nil { return palette.statePositive.color }
        return identity?.onField.color ?? palette.contentSecondary.color
    }
}

/// Local routes for the office week task. Not world navigation — `04` §3 lets a task provide only
/// the local routes it needs.
struct CoachWorldOfficeRoutes: View {
    let current: CoachWorldScreenID
    let palette: CoachWorldTokens.Palette
    let isAccessibilitySize: Bool
    let onNavigate: (CoachWorldScreenID) -> Void

    private var selection: CoachWorldTokens.ColorValue { palette.collegeIdentity }

    var body: some View {
        Group {
            if isAccessibilitySize {
                Menu("Week work") {
                    ForEach(Self.items, id: \.screen) { item in
                        Button(item.title) { onNavigate(item.screen) }
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: CoachWorldTokens.Shape.minimumTarget,
                    alignment: .leading
                )
                .padding(.horizontal, CoachWorldTokens.Space.sm)
            } else {
                HStack(spacing: .zero) {
                    ForEach(Self.items, id: \.screen) { item in
                        CoachWorldRouteButton(
                            title: item.title,
                            isCurrent: current == item.screen,
                            palette: palette,
                            selection: selection,
                            action: { onNavigate(item.screen) }
                        )
                    }
                }
                .padding(.horizontal, CoachWorldTokens.Space.sm)
            }
        }
        .background(palette.page.color)
        .overlay(alignment: .bottom) { CoachWorldHairline(palette: palette) }
        .accessibilitySortPriority(40)
    }

    private static let items: [(title: String, screen: CoachWorldScreenID)] = [
        ("Desk", .coachingHQ),
        ("Inbox", .inbox),
        ("Film", .opponentReportFilmRoom),
        ("Plan", .gamePlan),
        ("Practice", .practicePlan),
        ("Health", .teamHealth),
        ("Review", .aftermath),
    ]
}

/// Registry 19. An obligation as a commitment with a cost, completion, or delegated receipt.
struct CoachWorldAgendaRow: View {
    let item: CoachWorldAgendaItem
    let palette: CoachWorldTokens.Palette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Space.sm) {
                Image(systemName: item.symbolName)
                    .foregroundStyle(item.symbolColor(in: palette).color)
                    .frame(
                        minWidth: CoachWorldTokens.Shape.minimumTarget,
                        minHeight: CoachWorldTokens.Shape.minimumTarget
                    )
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                    Text(item.title)
                        .font(CoachWorldTokens.TypeRole.headline.weight(.semibold))
                        .strikethrough(item.isComplete)
                    if let detail = item.detail {
                        Text(detail)
                            .font(CoachWorldTokens.TypeRole.caption)
                            .foregroundStyle(palette.contentSecondary.color)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(item.cost)
                    .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
                    .foregroundStyle(item.costColor(in: palette).color)
                    .monospacedDigit()
            }
            .padding(.horizontal, CoachWorldTokens.Space.sm)
            .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.spoken)
        .overlay(alignment: .bottom) { CoachWorldHairline(palette: palette) }
    }
}

/// Registry 14. A capacity track; over-capacity uses the negative state colour.
struct CoachWorldMeter: View {
    let title: String
    let value: Int
    let maximum: Int
    let unit: String
    let palette: CoachWorldTokens.Palette

    private var ratio: CGFloat {
        guard maximum > 0 else { return 0 }
        return CGFloat(min(value, maximum)) / CGFloat(maximum)
    }

    private var isOver: Bool { value > maximum }

    var body: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            HStack {
                Text(title)
                    .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                Spacer()
                Text("\(value)\(unit)")
                    .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(
                        isOver ? palette.stateNegative.color : palette.contentPrimary.color
                    )
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(palette.raised.color)
                    Capsule()
                        .fill(isOver ? palette.stateNegative.color : palette.collegeIdentity.color)
                        .frame(width: max(geometry.size.width * ratio, .zero))
                }
            }
            .frame(height: CoachWorldChromeMetric.meterTrack)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value) of \(maximum) \(unit)")
    }
}

/// Registry 23. Empty states carry a title and a description; the mark orients, the words inform.
struct CoachWorldEmptyState: View {
    let title: String
    let systemImage: String
    let description: String
    let palette: CoachWorldTokens.Palette

    var body: some View {
        VStack(spacing: CoachWorldTokens.Space.sm) {
            Image(systemName: systemImage)
                .font(CoachWorldTokens.TypeRole.title)
                .foregroundStyle(palette.contentQuiet.color)
                .accessibilityHidden(true)
            Text(title)
                .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
            Text(description)
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(CoachWorldTokens.Space.md)
    }
}

struct CoachWorldErrorBanner: View {
    let message: String
    let palette: CoachWorldTokens.Palette

    var body: some View {
        Text(message)
            .font(CoachWorldTokens.TypeRole.callout)
            .foregroundStyle(palette.stateNegative.color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(CoachWorldTokens.Space.sm)
            .background(palette.stateNegative.color.opacity(0.12))
            .overlay {
                RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius)
                    .stroke(
                        palette.stateNegative.color,
                        lineWidth: CoachWorldTokens.Shape.hairline
                    )
            }
            .accessibilitySortPriority(90)
    }
}

enum CoachWorldChromeMetric {
    static let stripHeight: CGFloat = 52
    static let markWidth: CGFloat = 36
    static let markHeight: CGFloat = 28
    static let meterTrack: CGFloat = 8
}
