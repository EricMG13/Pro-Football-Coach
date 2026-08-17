import SwiftUI

public struct AftermathView: View {
    public let model: AftermathReadModel
    public let statusMessage: String?
    public let onContinue: () -> Void
    public let onOpenBoxScore: (() -> Void)?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: AftermathReadModel,
        statusMessage: String? = nil,
        onContinue: @escaping () -> Void,
        onOpenBoxScore: (() -> Void)? = nil
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onContinue = onContinue
        self.onOpenBoxScore = onOpenBoxScore
    }

    public var body: some View {
        let palette = CoachWorldTokens.dark
        CoachWorldFloodlitStage(palette: palette, register: .broadcast) {
            if dynamicTypeSize.isAccessibilitySize {
                content(palette: palette).accessibilitySortPriority(100)
            } else {
                content(palette: palette).accessibilitySortPriority(100)
            }
        }
    }

    private func content(palette: CoachWorldTokens.Palette) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
                Text("AFTERMATH")
                    .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                Text(model.headline)
                    .font(CoachWorldTokens.TypeRole.title.weight(.black))
                Text("\(model.away.team.abbreviation) \(model.away.score) · \(model.home.team.abbreviation) \(model.home.score)")
                    .font(CoachWorldTokens.TypeRole.display.weight(.black))
                    .monospacedDigit()
                Text(model.resultLabel)
                    .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                    .foregroundStyle(palette.contentSecondary.color)
                section("Evidence", model.evidence)
                section("Call-ins", model.callIns.isEmpty ? ["No controlled call-ins recorded."] : model.callIns)
                section("Injuries", model.injuries.isEmpty ? ["No injury evidence recorded."] : model.injuries)
                if !model.grades.isEmpty {
                    Text("PLAYER GRADES")
                        .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                    ForEach(model.grades) { grade in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(grade.player.name).font(.headline.weight(.bold))
                                Text("\(grade.position) · \(grade.evidence)")
                                    .font(.caption)
                                    .foregroundStyle(palette.contentSecondary.color)
                            }
                            Spacer()
                            Text("\(grade.rating)")
                                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                                .monospacedDigit()
                        }
                        .padding(CoachWorldTokens.Space.sm)
                        .coachWorldFloodlitPanel(
                            fill: palette.raised.color,
                            border: palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity)
                        )
                    }
                }
                if let statusMessage {
                    Text(statusMessage).font(CoachWorldTokens.TypeRole.body)
                }
                if let onOpenBoxScore {
                    Button("Open box score", action: onOpenBoxScore)
                        .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
                        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                }
                Button("Continue to HQ", action: onContinue)
                    .buttonStyle(CoachWorldActionButtonStyle(role: .primary, palette: palette))
                    .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
            }
            .padding(CoachWorldTokens.Space.lg)
        }
    }

    private func section(_ title: String, _ rows: [String]) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text(title.uppercased())
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
            ForEach(rows, id: \.self) { Text($0).font(CoachWorldTokens.TypeRole.body) }
        }
    }
}
