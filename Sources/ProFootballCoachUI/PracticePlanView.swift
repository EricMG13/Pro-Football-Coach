import SwiftUI
import FootballSimCore

public struct PracticePlanView: View {
    public let model: PracticePlanReadModel
    public let statusMessage: String?
    public let onSelect: (TacticalPracticePlan) -> Void
    public let onClose: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedID: String

    public init(
        model: PracticePlanReadModel,
        statusMessage: String? = nil,
        onSelect: @escaping (TacticalPracticePlan) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onSelect = onSelect
        self.onClose = onClose
        _selectedID = State(initialValue: model.options.first {
            $0.plan == model.currentPlan
        }?.id ?? "")
    }

    private var palette: CoachWorldTokens.Palette {
        colorScheme == .dark ? CoachWorldTokens.dark : CoachWorldTokens.light
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
                HStack {
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                        Text("PRACTICE PLAN")
                            .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                            .foregroundStyle(palette.collegeIdentity.color)
                        Text(model.team.name)
                            .font(CoachWorldTokens.TypeRole.display.weight(.black))
                        Text("\(model.weekLabel) · 60 minutes")
                            .font(CoachWorldTokens.TypeRole.body)
                            .foregroundStyle(palette.contentSecondary.color)
                    }
                    Spacer()
                    Button("Done", action: onClose)
                        .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                               minHeight: CoachWorldTokens.Shape.minimumTarget)
                }

                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text("Every option spends the existing 60-minute weekly budget. Effects are consumed by readiness and development.")
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
                            Spacer(minLength: 0)
                            Text("60m")
                                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                                .foregroundStyle(palette.collegeIdentity.color)
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
                    .accessibilityLabel("\(option.title). \(option.consequence). 60 minutes.")
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
