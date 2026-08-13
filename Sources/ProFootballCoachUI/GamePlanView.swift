import SwiftUI

/// Family 11. Weekly tactical keys. Setting a plan writes through `CareerSessionIntent.tacticalPlan`.
///
/// Density budget (`04` §4.5): dominant object is the three-axis plan; opponent is secondary;
/// zero verdict lines.
public struct GamePlanView: View {
    public let model: GamePlanReadModel
    public let statusMessage: String?
    public let onContinue: () -> Void
    public let onNavigate: (CoachWorldScreenID) -> Void
    public let onSetPlan: (
        CoachWorldRunPassChoice,
        CoachWorldTempoChoice,
        CoachWorldPressureChoice
    ) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var runPass: CoachWorldRunPassChoice?
    @State private var tempo: CoachWorldTempoChoice?
    @State private var pressure: CoachWorldPressureChoice?

    public init(
        model: GamePlanReadModel,
        statusMessage: String? = nil,
        onContinue: @escaping () -> Void,
        onNavigate: @escaping (CoachWorldScreenID) -> Void,
        onSetPlan: @escaping (
            CoachWorldRunPassChoice,
            CoachWorldTempoChoice,
            CoachWorldPressureChoice
        ) -> Void
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onContinue = onContinue
        self.onNavigate = onNavigate
        self.onSetPlan = onSetPlan
        _runPass = State(initialValue: model.runPass)
        _tempo = State(initialValue: model.tempo)
        _pressure = State(initialValue: model.pressure)
    }

    private var palette: CoachWorldTokens.Palette {
        colorScheme == .dark ? CoachWorldTokens.dark : CoachWorldTokens.light
    }

    private var draftComplete: Bool {
        runPass != nil && tempo != nil && pressure != nil
    }

    public var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibleLayout
            } else {
                VStack(spacing: .zero) {
                    strip
                    CoachWorldOfficeRoutes(
                        current: .gamePlan,
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
        .onChange(of: model.snapshotID) { _, _ in
            runPass = model.runPass
            tempo = model.tempo
            pressure = model.pressure
        }
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
            identityRail.frame(width: 190)
            axes.frame(maxWidth: .infinity)
        }
        .padding(CoachWorldTokens.Space.xs)
    }

    private var accessibleLayout: some View {
        ScrollView {
            VStack(spacing: CoachWorldTokens.Space.xs) {
                axes
                identityRail
                strip
                CoachWorldOfficeRoutes(
                    current: .gamePlan,
                    palette: palette,
                    isAccessibilitySize: true,
                    onNavigate: onNavigate
                )
            }
            .padding(CoachWorldTokens.Space.sm)
        }
    }

    private var identityRail: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
            Text("GAME PLAN · KEYS")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            Text(model.opponent.map { "Against \($0.name)" } ?? "No opponent this week")
                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                .fixedSize(horizontal: false, vertical: true)
            Text(model.hasRecordedPlan
                 ? "A plan is recorded for this week. Changing it and tapping Set plan overwrites it."
                 : "No plan is recorded for this week. The three keys stay blank until you set them.")
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button {
                if let runPass, let tempo, let pressure {
                    onSetPlan(runPass, tempo, pressure)
                }
            } label: {
                Label("Set plan", systemImage: "checkmark")
            }
            .buttonStyle(CoachWorldActionButtonStyle(role: .primary, palette: palette))
            .disabled(!draftComplete)
            .frame(maxWidth: .infinity)
        }
        .padding(CoachWorldTokens.Space.sm)
        .coachWorldDeskSurface(
            fill: palette.work.color,
            border: palette.contentQuiet.color.opacity(0.45)
        )
        .accessibilitySortPriority(40)
    }

    private var axes: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
            axis(
                title: "Run or pass",
                choices: CoachWorldRunPassChoice.allCases.map(\.rawValue),
                selected: runPass?.rawValue
            ) { label in
                runPass = CoachWorldRunPassChoice(rawValue: label)
            }
            axis(
                title: "Tempo",
                choices: CoachWorldTempoChoice.allCases.map(\.rawValue),
                selected: tempo?.rawValue
            ) { label in
                tempo = CoachWorldTempoChoice(rawValue: label)
            }
            axis(
                title: "Pressure",
                choices: CoachWorldPressureChoice.allCases.map(\.rawValue),
                selected: pressure?.rawValue
            ) { label in
                pressure = CoachWorldPressureChoice(rawValue: label)
            }
            Spacer(minLength: 0)
        }
        .padding(CoachWorldTokens.Space.sm)
        .coachWorldDeskSurface(
            fill: palette.work.color,
            border: palette.contentQuiet.color.opacity(0.45)
        )
        .accessibilitySortPriority(100)
    }

    private func axis(
        title: String,
        choices: [String],
        selected: String?,
        onSelect: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text(title.uppercased())
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            HStack(spacing: CoachWorldTokens.Space.xs) {
                ForEach(choices, id: \.self) { choice in
                    let isSelected = selected == choice
                    Button {
                        onSelect(choice)
                    } label: {
                        Text(choice)
                            .font(CoachWorldTokens.TypeRole.body.weight(.bold))
                            .frame(
                                maxWidth: .infinity,
                                minHeight: CoachWorldTokens.Shape.minimumTarget
                            )
                    }
                    .buttonStyle(.plain)
                    .background(
                        isSelected
                            ? palette.collegeIdentity.color.opacity(0.14)
                            : palette.raised.color
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius)
                            .stroke(
                                isSelected
                                    ? palette.collegeIdentity.color
                                    : palette.contentQuiet.color.opacity(0.65),
                                lineWidth: CoachWorldTokens.Shape.hairline
                            )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius))
                    .accessibilityLabel(choice)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }
}
