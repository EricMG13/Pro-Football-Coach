import SwiftUI

/// Family 12. Scarce practice minutes across four buckets. There is no per-day grid (G-14).
///
/// Density budget (`04` §4.5): dominant object is the four-bucket spend; presets are the one
/// secondary region; session-type symbols are withheld because they belong to a week grid this
/// engine does not have.
public struct PracticePlanView: View {
    public let model: PracticePlanReadModel
    public let statusMessage: String?
    public let onContinue: () -> Void
    public let onNavigate: (CoachWorldScreenID) -> Void
    public let onSetPreset: (CoachWorldPracticePreset) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: PracticePlanReadModel,
        statusMessage: String? = nil,
        onContinue: @escaping () -> Void,
        onNavigate: @escaping (CoachWorldScreenID) -> Void,
        onSetPreset: @escaping (CoachWorldPracticePreset) -> Void
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onContinue = onContinue
        self.onNavigate = onNavigate
        self.onSetPreset = onSetPreset
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
                        current: .practicePlan,
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
        HStack(spacing: CoachWorldTokens.Space.xs) {
            buckets.frame(maxWidth: .infinity)
            presets.frame(width: 200)
        }
        .padding(CoachWorldTokens.Space.xs)
    }

    private var accessibleLayout: some View {
        ScrollView {
            VStack(spacing: CoachWorldTokens.Space.xs) {
                buckets
                presets
                strip
                CoachWorldOfficeRoutes(
                    current: .practicePlan,
                    palette: palette,
                    isAccessibilitySize: true,
                    onNavigate: onNavigate
                )
            }
            .padding(CoachWorldTokens.Space.sm)
        }
    }

    private var buckets: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
            HStack {
                Text("PRACTICE MINUTES")
                    .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                    .foregroundStyle(palette.collegeIdentity.color)
                Spacer()
                Text("\(model.spentMinutes)/\(model.weeklyMinutes)m")
                    .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                    .monospacedDigit()
                    .accessibilityLabel("\(model.spentMinutes) of \(model.weeklyMinutes) minutes spent")
            }
            if !model.isRecordedThisWeek {
                Text("No plan is recorded for this week. The budget is \(model.weeklyMinutes) minutes; a plan must spend it exactly.")
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
            }
            CoachWorldMeter(
                title: "Install",
                value: model.installMinutes,
                maximum: model.weeklyMinutes,
                unit: "m",
                palette: palette
            )
            CoachWorldMeter(
                title: "Conditioning",
                value: model.conditioningMinutes,
                maximum: model.weeklyMinutes,
                unit: "m",
                palette: palette
            )
            CoachWorldMeter(
                title: "Recovery",
                value: model.recoveryMinutes,
                maximum: model.weeklyMinutes,
                unit: "m",
                palette: palette
            )
            CoachWorldMeter(
                title: model.positionFocusLabel.map { "Position focus · \($0)" } ?? "Position focus",
                value: model.positionFocusMinutes,
                maximum: model.weeklyMinutes,
                unit: "m",
                palette: palette
            )
            Text("A seven-day load grid is not shown. The calendar's finest grain is a week.")
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentQuiet.color)
            Spacer(minLength: 0)
        }
        .padding(CoachWorldTokens.Space.sm)
        .coachWorldDeskSurface(
            fill: palette.work.color,
            border: palette.contentQuiet.color.opacity(0.45)
        )
        .accessibilitySortPriority(100)
    }

    private var presets: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text("SET WORK")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            Text("Each preset spends the \(model.weeklyMinutes)m budget exactly.")
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(CoachWorldPracticePreset.allCases, id: \.self) { preset in
                let selected = model.matchingPreset == preset && model.isRecordedThisWeek
                Button {
                    onSetPreset(preset)
                } label: {
                    Text(preset.rawValue)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: CoachWorldTokens.Shape.minimumTarget
                        )
                }
                .buttonStyle(CoachWorldActionButtonStyle(
                    role: selected ? .primary : .secondary,
                    palette: palette
                ))
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }
        .padding(CoachWorldTokens.Space.sm)
        .coachWorldDeskSurface(
            fill: palette.raised.color.opacity(0.45),
            border: palette.contentQuiet.color.opacity(0.45)
        )
        .accessibilitySortPriority(80)
    }
}
