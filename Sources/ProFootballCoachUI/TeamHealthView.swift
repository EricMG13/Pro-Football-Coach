import SwiftUI

public struct TeamHealthView: View {
    public let model: TeamHealthReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    public let onContinue: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: TeamHealthReadModel,
        statusMessage: String? = nil,
        onClose: @escaping () -> Void,
        onContinue: @escaping () -> Void
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onClose = onClose
        self.onContinue = onContinue
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    public var body: some View {
        CoachWorldFloodlitStage(palette: palette) {
            ScrollView {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
                    header

                    if let statusMessage {
                        Text(statusMessage)
                            .font(CoachWorldTokens.TypeRole.callout)
                            .foregroundStyle(palette.stateWarning.color)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    summary

                    if model.players.isEmpty {
                        CoachWorldSystemState(
                            .empty(
                                "No health records. No controlled roster is available "
                                    + "for this week."
                            ),
                            palette: palette
                        )
                    } else {
                        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                            Text("READINESS BY PLAYER")
                                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                                .foregroundStyle(palette.contentSecondary.color)
                            ForEach(model.players) { player in
                                playerRow(player)
                            }
                        }
                    }

                    Button(action: onContinue) {
                        Label("Continue", systemImage: "forward.end.fill")
                            .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget)
                    }
                    .buttonStyle(CoachWorldActionButtonStyle(
                        role: model.canContinue ? .primary : .secondary,
                        palette: palette
                    ))
                    .disabled(!model.canContinue)
                    .accessibilityHint(model.continueReason ?? "")
                }
                .padding(CoachWorldTokens.Space.md)
            }
        }
        .frame(maxWidth: .infinity,
               alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .center)
        .accessibilitySortPriority(100)
    }

    @ViewBuilder
    private var header: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                titleBlock
                Button("Done", action: onClose)
                    .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                           minHeight: CoachWorldTokens.Shape.minimumTarget)
            }
        } else {
            HStack(alignment: .top) {
                titleBlock
                Spacer(minLength: CoachWorldTokens.Space.sm)
                Button("Done", action: onClose)
                    .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                           minHeight: CoachWorldTokens.Shape.minimumTarget)
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text("TEAM HEALTH")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            Text(model.team.name)
                .font(CoachWorldTokens.TypeRole.display.weight(.black))
                .fixedSize(horizontal: false, vertical: true)
            Text(model.weekLabel)
                .font(CoachWorldTokens.TypeRole.body)
                .foregroundStyle(palette.contentSecondary.color)
        }
    }

    private var summary: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: CoachWorldTokens.Space.xs)],
                     alignment: .leading,
                     spacing: CoachWorldTokens.Space.xs) {
            summaryCell("CONDITION", "\(model.averageCondition)%")
            summaryCell("FATIGUE", "\(model.averageFatigue)%")
            summaryCell("INJURIES", "\(model.injuryCount)")
            summaryCell("SUSPENSIONS", "\(model.suspensionCount)")
        }
        .accessibilitySortPriority(80)
    }

    private func summaryCell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text(label)
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentSecondary.color)
            Text(value)
                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .background(palette.raised.color)
        .overlay {
            RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius)
                .stroke(palette.contentQuiet.color.opacity(0.6), lineWidth: CoachWorldTokens.Shape.hairline)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label.capitalized), \(value)")
    }

    private func playerRow(_ player: TeamHealthReadModel.PlayerStatus) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            HStack(alignment: .firstTextBaseline) {
                Text(player.name)
                    .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                Spacer(minLength: CoachWorldTokens.Space.xs)
                Text(player.position)
                    .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                    .foregroundStyle(palette.contentSecondary.color)
            }
            Text("Condition \(player.condition)% · Fatigue \(player.fatigue)%")
                .font(CoachWorldTokens.TypeRole.body)
            Text("\(player.availability) · \(player.statusDetail)")
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(CoachWorldTokens.Space.sm)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .background(palette.raised.color.opacity(0.7))
        .overlay {
            RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius)
                .stroke(palette.contentQuiet.color.opacity(0.6), lineWidth: CoachWorldTokens.Shape.hairline)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(player.name), \(player.position), condition \(player.condition) percent, "
                + "fatigue \(player.fatigue) percent, \(player.availability), \(player.statusDetail)"
        )
        .accessibilitySortPriority(50)
    }
}
