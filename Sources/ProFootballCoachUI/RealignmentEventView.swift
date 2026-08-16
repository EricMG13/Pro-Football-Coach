import SwiftUI

public struct RealignmentEventView: View {
    public let model: RealignmentReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(model: RealignmentReadModel, statusMessage: String? = nil,
                onClose: @escaping () -> Void) {
        self.model = model; self.statusMessage = statusMessage; self.onClose = onClose
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    public var body: some View {
        VStack(spacing: .zero) {
            HStack(spacing: CoachWorldTokens.Space.sm) {
                Button("League", action: onClose)
                    .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                           minHeight: CoachWorldTokens.Shape.minimumTarget)
                VStack(alignment: .leading, spacing: .zero) {
                    Text("Realignment event").font(CoachWorldTokens.TypeRole.headline.weight(.black))
                    Text(model.currentSeasonLabel).font(CoachWorldTokens.TypeRole.caption)
                }
                Spacer()
            }
            .padding(.horizontal, CoachWorldTokens.Space.sm)
            .background(palette.raised.color)
            if let statusMessage { Text(statusMessage).frame(maxWidth: .infinity, alignment: .leading) }
            ScrollView {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
                    if let event = model.event {
                        Text(event.seasonLabel + " · " + event.reason)
                            .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                        ForEach(event.swaps, content: swapCard)
                    } else {
                        Text("No realignment event recorded.")
                            .foregroundStyle(palette.contentSecondary.color)
                    }
                }
                .padding(CoachWorldTokens.Space.md)
            }
        }
        .foregroundStyle(palette.contentPrimary.color)
        .background(palette.page.color.ignoresSafeArea())
        .frame(maxWidth: .infinity, alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .center)
        .accessibilitySortPriority(100)
    }

    private func swapCard(_ swap: RealignmentReadModel.Swap) -> some View {
        let title = swap.firstProgramme + " ↔ " + swap.secondProgramme
        let firstMove = swap.firstProgramme + ": " + swap.firstFrom + " → " + swap.firstTo
        let secondMove = swap.secondProgramme + ": " + swap.secondFrom + " → " + swap.secondTo
        let spoken = swap.firstProgramme + " moves from " + swap.firstFrom + " to "
            + swap.firstTo + "; " + swap.secondProgramme + " moves from "
            + swap.secondFrom + " to " + swap.secondTo
        return VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text(title).fontWeight(.bold)
            Text(firstMove)
            Text(secondMove)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(spoken)
    }
}
