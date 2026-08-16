import SwiftUI

public struct ClassOverviewView: View {
    public let model: RecruitingBoardReadModel
    public let statusMessage: String?
    public let onClose: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(model: RecruitingBoardReadModel, statusMessage: String? = nil,
                onClose: @escaping () -> Void) {
        self.model = model
        self.statusMessage = statusMessage
        self.onClose = onClose
    }

    private var palette: CoachWorldTokens.Palette {
        colorScheme == .dark ? CoachWorldTokens.dark : CoachWorldTokens.light
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
                header
                if let statusMessage { Text(statusMessage).foregroundStyle(palette.stateWarning.color) }
                summary
                needs
                Text("BOARD PROSPECTS · \(model.prospects.count)")
                    .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                Text("DISCOVERABLE PROSPECTS · \(model.discovery.count)")
                    .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                    .foregroundStyle(palette.contentSecondary.color)
            }
            .padding(CoachWorldTokens.Space.md)
        }
        .foregroundStyle(palette.contentPrimary.color)
        .background(palette.page.color.ignoresSafeArea())
        .accessibilitySortPriority(100)
    }

    private var header: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) { titleBlock; closeButton }
            } else {
                HStack(alignment: .top) { titleBlock; Spacer(); closeButton }
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text("CLASS OVERVIEW").font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            Text(model.team.name).font(CoachWorldTokens.TypeRole.display.weight(.black))
            Text("Recruiting needs and current class coverage")
                .foregroundStyle(palette.contentSecondary.color)
        }
    }

    private var closeButton: some View {
        Button("Done", action: onClose)
            .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                   minHeight: CoachWorldTokens.Shape.minimumTarget)
    }

    private var summary: some View {
        HStack(spacing: CoachWorldTokens.Space.xs) {
            summaryCell("SLOTS", "\(model.capacity.scholarshipSlotsRemaining)")
            summaryCell("CONTACT", "\(model.capacity.weeklyHoursRemaining)")
            summaryCell("VISITS", "\(model.capacity.officialVisitsRemaining)")
        }
        .frame(maxWidth: .infinity)
    }

    private var needs: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text("POSITION NEEDS").font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
            ForEach(model.positionNeeds, id: \.stableID) { need in
                HStack {
                    Text(need.position).font(CoachWorldTokens.TypeRole.body.weight(.semibold))
                    Spacer()
                    Text("\(need.committed)/\(need.target)").monospacedDigit()
                }
                .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(need.position), \(need.committed) of \(need.target)")
            }
        }
    }

    private func summaryCell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading) {
            Text(label).font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
            Text(value).font(CoachWorldTokens.TypeRole.headline.weight(.black)).monospacedDigit()
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .background(palette.raised.color)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label.capitalized), \(value)")
    }
}
