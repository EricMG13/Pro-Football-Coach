import SwiftUI

public struct OpponentFilmView: View {
    public let model: OpponentFilmReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    public let onContinue: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: OpponentFilmReadModel,
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
        colorScheme == .dark ? CoachWorldTokens.dark : CoachWorldTokens.light
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
                header
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let reason = model.unavailableReason {
                    ContentUnavailableView(
                        "Opponent film unavailable",
                        systemImage: "list.number",
                        description: Text(reason)
                    )
                    .frame(maxWidth: .infinity, minHeight: 180)
                } else {
                    evidence
                }
                Button(action: onContinue) {
                    Label("Continue", systemImage: "forward.end.fill")
                        .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget)
                }
                .buttonStyle(CoachWorldActionButtonStyle(
                    role: model.isCurrent ? .primary : .secondary,
                    palette: palette
                ))
                .disabled(!model.isCurrent)
            }
            .padding(CoachWorldTokens.Space.md)
        }
        .foregroundStyle(palette.contentPrimary.color)
        .background(palette.page.color.ignoresSafeArea())
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
            Text("OPPONENT REPORT / FILM ROOM")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            Text(model.opponent?.name ?? "No scheduled opponent")
                .font(CoachWorldTokens.TypeRole.display.weight(.black))
                .fixedSize(horizontal: false, vertical: true)
            Text(model.team.name + " · " + model.weekLabel)
                .font(CoachWorldTokens.TypeRole.body)
                .foregroundStyle(palette.contentSecondary.color)
        }
    }

    private var evidence: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
            Text("OBSERVER-SCOPED EVIDENCE")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentSecondary.color)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: CoachWorldTokens.Space.xs)],
                      alignment: .leading,
                      spacing: CoachWorldTokens.Space.xs) {
                cell("SOURCE GAMES", String(model.sourceGameCount))
                cell("CONFIDENCE", String(model.confidence) + "%")
                cell("PASS RATE", String(model.passRate) + "%")
                cell("TURNOVER RATE", String(model.turnoverRate) + "%")
            }
            Text(String(model.sourceFixtureCount)
                + " retained source fixture(s); no hidden current totals are shown.")
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(String(model.sourceFixtureCount) + " retained source fixtures")
        }
    }

    private func cell(_ label: String, _ value: String) -> some View {
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
        .accessibilityLabel("(label.capitalized), (value)")
    }
}
