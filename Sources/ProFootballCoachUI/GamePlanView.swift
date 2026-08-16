import SwiftUI
import FootballSimCore

public struct GamePlanView: View {
    public let model: GamePlanReadModel
    public let title: String
    public let statusMessage: String?
    public let onSelect: (TacticalPlan) -> Void
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedID: String

    public init(
        model: GamePlanReadModel,
        title: String = "GAME PLAN",
        statusMessage: String? = nil,
        onSelect: @escaping (TacticalPlan) -> Void,
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
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
                HStack {
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                        Text(title)
                            .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                            .foregroundStyle(palette.collegeIdentity.color)
                        Text(model.team.name)
                            .font(CoachWorldTokens.TypeRole.display.weight(.black))
                        Text(model.weekLabel)
                            .font(CoachWorldTokens.TypeRole.body)
                            .foregroundStyle(palette.contentSecondary.color)
                    }
                    Spacer()
                    Button("Done", action: onClose)
                        .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                               minHeight: CoachWorldTokens.Shape.minimumTarget)
                }

                if let opponent = model.opponent {
                    Text("Opponent: \(opponent.name)")
                        .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                } else {
                    Text("No fixture is scheduled this week.")
                        .foregroundStyle(palette.contentSecondary.color)
                }

                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text("Choose the committed plan used by the next fixture. The engine revalidates it when saved.")
                    .font(CoachWorldTokens.TypeRole.body)
                    .foregroundStyle(palette.contentSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(model.options) { option in
                    Button {
                        selectedID = option.id
                        onSelect(option.plan)
                    } label: {
                        HStack(alignment: .top, spacing: CoachWorldTokens.Space.sm) {
                            Image(systemName: selectedID == option.id
                                ? "checkmark.circle.fill" : "circle")
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                                Text(option.title)
                                    .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                                Text(option.consequence)
                                    .font(CoachWorldTokens.TypeRole.body)
                                    .foregroundStyle(palette.contentSecondary.color)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(CoachWorldTokens.Space.sm)
                        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                        .background(
                            selectedID == option.id
                                ? palette.collegeIdentity.color.opacity(0.16)
                                : palette.raised.color.opacity(0.6)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius)
                                .stroke(
                                    selectedID == option.id
                                        ? palette.collegeIdentity.color
                                        : palette.contentQuiet.color.opacity(0.65),
                                    lineWidth: CoachWorldTokens.Shape.hairline
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(option.title). \(option.consequence)")
                    .accessibilityAddTraits(selectedID == option.id ? .isSelected : [])
                }
            }
            .padding(CoachWorldTokens.Space.md)
        }
        .foregroundStyle(palette.contentPrimary.color)
        .background(palette.page.color.ignoresSafeArea())
        .frame(maxWidth: .infinity,
               alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .center)
        .accessibilitySortPriority(100)
    }
}
