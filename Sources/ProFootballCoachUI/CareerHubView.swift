import SwiftUI

/// A live career ledger. It is intentionally read-only until the employment transaction surface
/// exists; every displayed row is still useful because it gives the coach a durable explanation of
/// current status, support, history, and outstanding opportunities.
public struct CareerHubView: View {
    public let model: CareerHubReadModel
    public let statusMessage: String?
    public let onClose: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: CareerHubReadModel,
        statusMessage: String? = nil,
        onClose: @escaping () -> Void
    ) {
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
                if let currentJob = model.currentJob {
                    section("CURRENT APPOINTMENT") {
                        jobRow(currentJob)
                    }
                }
                section("STAKEHOLDER SUPPORT") {
                    ForEach(model.support) { row in
                        HStack {
                            Text(row.stakeholder)
                            Spacer()
                            Text("\(row.value)/100")
                                .monospacedDigit()
                                .fontWeight(.bold)
                        }
                        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(row.stakeholder), \(row.value) out of 100")
                    }
                }
                section("JOB HISTORY") {
                    if model.history.isEmpty {
                        Text("No completed appointments recorded.")
                            .foregroundStyle(palette.contentSecondary.color)
                    } else {
                        ForEach(model.history) { row in jobRow(row) }
                    }
                }
                section("OPPORTUNITIES") {
                    if model.opportunities.isEmpty {
                        Text("No active offers.")
                            .foregroundStyle(palette.contentSecondary.color)
                    } else {
                        ForEach(model.opportunities) { opportunity in
                            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                                Text(opportunity.team.name)
                                    .font(.headline)
                                Text("\(opportunity.tier) · Prestige \(opportunity.prestige)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(palette.contentSecondary.color)
                                Text("Offered \(opportunity.offered) · Expires \(opportunity.expires)")
                                    .font(.caption)
                                Text(opportunity.rationale)
                                    .font(.callout)
                            }
                            .padding(.vertical, CoachWorldTokens.Space.xs)
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
            .padding(CoachWorldTokens.Space.md)
        }
        .foregroundStyle(palette.contentPrimary.color)
        .background(palette.page.color.ignoresSafeArea())
        .frame(maxWidth: .infinity,
               alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .center)
        .accessibilitySortPriority(100)
        .safeAreaInset(edge: .top) { topBar }
    }

    private var topBar: some View {
        HStack {
            Button("Office", action: onClose)
                .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                       minHeight: CoachWorldTokens.Shape.minimumTarget)
            Spacer()
            Text("Career Hub")
                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
            Spacer()
            Text(model.status.uppercased())
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentSecondary.color)
                .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                       minHeight: CoachWorldTokens.Shape.minimumTarget)
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .background(palette.raised.color)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text(model.coach.name)
                .font(CoachWorldTokens.TypeRole.display.weight(.black))
            Text(model.coach.role)
                .font(CoachWorldTokens.TypeRole.headline)
                .foregroundStyle(palette.contentSecondary.color)
            if let statusMessage {
                Text(statusMessage)
                    .font(CoachWorldTokens.TypeRole.callout)
                    .foregroundStyle(palette.stateWarning.color)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text(title)
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            content()
        }
        .padding(CoachWorldTokens.Space.sm)
        .background(
            palette.raised.color,
            in: RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.surfaceRadius)
        )
    }

    private func jobRow(_ row: CareerHubReadModel.JobRow) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text(row.team.name)
                .font(.headline)
            Text("\(row.tier) · Started \(row.started)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.contentSecondary.color)
            if let ended = row.ended, let reason = row.reason {
                Text("Ended \(ended) · \(reason)")
                    .font(.caption)
                    .foregroundStyle(palette.contentSecondary.color)
            }
        }
        .padding(.vertical, CoachWorldTokens.Space.xs)
        .accessibilityElement(children: .combine)
    }
}
