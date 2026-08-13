import SwiftUI

/// Family 13. Availability, fatigue and injury. Return decisions are not a separate intent yet —
/// the list is the fact the coach acts from.
///
/// Density budget (`04` §4.5): dominant object is the unavailable list; the available/injured
/// counts are the one secondary header; at most one status glyph per row (`cross.case`).
public struct TeamHealthView: View {
    public let model: TeamHealthReadModel
    public let statusMessage: String?
    public let onContinue: () -> Void
    public let onNavigate: (CoachWorldScreenID) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: TeamHealthReadModel,
        statusMessage: String? = nil,
        onContinue: @escaping () -> Void,
        onNavigate: @escaping (CoachWorldScreenID) -> Void
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onContinue = onContinue
        self.onNavigate = onNavigate
    }

    private var palette: CoachWorldTokens.Palette {
        colorScheme == .dark ? CoachWorldTokens.dark : CoachWorldTokens.light
    }

    public var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibleLayout
            } else {
                VStack(spacing: .zero) {
                    strip
                    CoachWorldOfficeRoutes(
                        current: .teamHealth,
                        palette: palette,
                        isAccessibilitySize: false,
                        onNavigate: onNavigate
                    )
                    standardLayout
                }
            }
        }
        .foregroundStyle(palette.contentPrimary.color)
        .background(palette.page.color.ignoresSafeArea())
    }

    private var strip: some View {
        CoachWorldWorldStrip(
            team: model.frame.team,
            contextLine: model.frame.contextLine,
            statusMessage: statusMessage,
            currentWorldRoute: .coachingHQ,
            canAdvance: model.frame.canAdvance,
            mandatoryDueCount: model.frame.mandatoryDueCount,
            palette: palette,
            isAccessibilitySize: dynamicTypeSize.isAccessibilitySize,
            onContinue: onContinue,
            onNavigate: onNavigate
        )
    }

    private var standardLayout: some View {
        VStack(spacing: .zero) {
            header
            if model.rows.isEmpty {
                CoachWorldEmptyState(
                    title: "Everyone is available",
                    systemImage: "checkmark.circle",
                    description: "No one on the roster is injured or unavailable this week.",
                    palette: palette
                )
            } else {
                rowHeader
                ScrollView {
                    LazyVStack(spacing: .zero) {
                        ForEach(model.rows) { row in
                            playerRow(row)
                        }
                    }
                }
            }
        }
        .padding(CoachWorldTokens.Space.xs)
        .coachWorldDeskSurface(
            fill: palette.work.color,
            border: palette.contentQuiet.color.opacity(0.45)
        )
        .padding(CoachWorldTokens.Space.xs)
        .accessibilitySortPriority(100)
    }

    private var accessibleLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                header
                if model.rows.isEmpty {
                    CoachWorldEmptyState(
                        title: "Everyone is available",
                        systemImage: "checkmark.circle",
                        description: "No one on the roster is injured or unavailable this week.",
                        palette: palette
                    )
                } else {
                    ForEach(model.rows) { row in
                        playerRow(row)
                    }
                }
                strip
                CoachWorldOfficeRoutes(
                    current: .teamHealth,
                    palette: palette,
                    isAccessibilitySize: true,
                    onNavigate: onNavigate
                )
            }
            .padding(CoachWorldTokens.Space.sm)
        }
    }

    private var header: some View {
        HStack {
            Text("TEAM HEALTH")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            Spacer()
            Text("\(model.availableCount)/\(model.rosterCount) available · \(model.injuredCount) injured")
                .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
                .monospacedDigit()
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        .overlay(alignment: .bottom) { CoachWorldHairline(palette: palette) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(model.availableCount) of \(model.rosterCount) available, \(model.injuredCount) injured"
        )
        .accessibilitySortPriority(90)
    }

    private var rowHeader: some View {
        HStack {
            Text("PLAYER").frame(maxWidth: .infinity, alignment: .leading)
            Text("POS").frame(width: 48, alignment: .leading)
            Text("COND").frame(width: 48, alignment: .trailing)
            Text("RETURN").frame(width: 72, alignment: .trailing)
        }
        .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
        .foregroundStyle(palette.contentQuiet.color)
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        .overlay(alignment: .bottom) { CoachWorldHairline(palette: palette) }
        .accessibilityHidden(true)
    }

    private func playerRow(_ row: TeamHealthReadModel.PlayerRow) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Space.sm) {
            Image(systemName: "cross.case")
                .foregroundStyle(palette.stateNegative.color)
                .frame(
                    minWidth: CoachWorldTokens.Shape.minimumTarget,
                    minHeight: CoachWorldTokens.Shape.minimumTarget
                )
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                Text("#\(row.number)  \(row.person.name)")
                    .font(CoachWorldTokens.TypeRole.headline)
                    .lineLimit(1)
                Text(row.injuryLabel ?? row.availability)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(row.position)
                .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
                .frame(width: 48, alignment: .leading)
            Text("\(row.condition)")
                .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
                .monospacedDigit()
                .frame(width: 48, alignment: .trailing)
            Text(row.weeksRemaining.map { "\($0)w" } ?? "—")
                .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
                .monospacedDigit()
                .frame(width: 72, alignment: .trailing)
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        .overlay(alignment: .bottom) { CoachWorldHairline(palette: palette) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(spoken(row))
    }

    private func spoken(_ row: TeamHealthReadModel.PlayerRow) -> String {
        let injury = row.injuryLabel ?? row.availability
        let weeks = row.weeksRemaining.map { "\($0) weeks remaining" } ?? "return unknown"
        return "\(row.person.name), number \(row.number), \(row.position), \(injury), condition \(row.condition), \(weeks)"
    }
}
