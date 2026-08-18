import SwiftUI
import FootballSimCore

public struct DepthChartView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: DepthChartReadModel
    public let title: String
    public let statusMessage: String?
    public let onSelect: (PersonnelPlan) -> Void
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedID: String

    public init(
        model: DepthChartReadModel,
        title: String = "DEPTH CHART",
        statusMessage: String? = nil,
        onSelect: @escaping (PersonnelPlan) -> Void,
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
        CoachWorldFloodlitStage(palette: palette, chrome: chrome, onNavigate: onNavigateChrome) {
            scrollContent
        }
        .frame(maxWidth: .infinity,
               alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .center)
        .accessibilitySortPriority(100)
    }

    private var scrollContent: some View {
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

                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text("The base chart is derived from the roster. Choose only the persisted ordering override; unavailable players fall back automatically.")
                    .font(CoachWorldTokens.TypeRole.body)
                    .foregroundStyle(palette.contentSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(model.positions) { group in
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                        Text(group.title.uppercased())
                            .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                            .foregroundStyle(palette.contentSecondary.color)
                        ForEach(Array(group.slots.enumerated()), id: \.element.id) { index, slot in
                            let slotLabel = index == 0 ? "starter" : "depth \(index + 1)"
                            HStack(spacing: CoachWorldTokens.Space.sm) {
                                Text(index == 0 ? "START" : "\(index + 1)")
                                    .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                                    .foregroundStyle(slot.isUnavailable
                                        ? palette.stateWarning.color
                                        : palette.collegeIdentity.color)
                                    .frame(minWidth: 44, alignment: .leading)
                                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                                    Text(slot.playerName)
                                        .font(CoachWorldTokens.TypeRole.body.weight(.semibold))
                                    Text(slot.availability)
                                        .font(CoachWorldTokens.TypeRole.caption)
                                        .foregroundStyle(palette.contentSecondary.color)
                                }
                                Spacer(minLength: 0)
                                if slot.isOverride {
                                    Text("OVERRIDE")
                                        .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                                        .foregroundStyle(palette.collegeIdentity.color)
                                }
                            }
                            .padding(.horizontal, CoachWorldTokens.Space.sm)
                            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                            .background(palette.raised.color.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius))
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(slot.playerName), \(slotLabel). \(slot.availability)")
                        }
                    }
                }

                Text("Saved personnel options")
                    .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
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
                        .background(selectedID == option.id
                            ? palette.collegeIdentity.color.opacity(0.16)
                            : palette.raised.color.opacity(0.6))
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
    }
}
