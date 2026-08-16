import SwiftUI

/// A roster-scoped development ledger. It shows recorded deltas only; potential and projections
/// remain outside the read model until an authoritative plan exists.
public struct DevelopmentPlanView: View {
    public let model: RosterReadModel
    public let statusMessage: String?
    public let onClose: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(model: RosterReadModel, statusMessage: String? = nil, onClose: @escaping () -> Void) {
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
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                }
                Text("Recorded attribute changes are shown without projecting hidden potential.")
                    .font(CoachWorldTokens.TypeRole.body)
                    .foregroundStyle(palette.contentSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)
                if model.players.isEmpty {
                    ContentUnavailableView(
                        "No development evidence",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("No roster records are available for this checkpoint.")
                    )
                } else {
                    ForEach(model.players) { player in
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                                Text(player.person.name)
                                    .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                                Text("#\(player.number) · \(player.position)")
                                    .font(CoachWorldTokens.TypeRole.caption)
                                    .foregroundStyle(palette.contentSecondary.color)
                            }
                            Spacer(minLength: CoachWorldTokens.Space.sm)
                            Text(player.developmentDelta.map { $0 > 0 ? "+\($0)" : "\($0)" } ?? "—")
                                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                                .monospacedDigit()
                        }
                        .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget,
                               alignment: .leading)
                        .padding(.horizontal, CoachWorldTokens.Space.sm)
                        .background(palette.raised.color)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            "\(player.person.name), \(player.position), development change "
                                + (player.developmentDelta.map { $0 > 0 ? "+\($0)" : "\($0)" } ?? "none")
                        )
                    }
                }
            }
            .padding(CoachWorldTokens.Space.md)
        }
        .foregroundStyle(palette.contentPrimary.color)
        .background(palette.page.color.ignoresSafeArea())
        .accessibilitySortPriority(dynamicTypeSize.isAccessibilitySize ? 100 : 90)
        .safeAreaInset(edge: .top) { topBar }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text("DEVELOPMENT PLAN")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            Text(model.team.name)
                .font(CoachWorldTokens.TypeRole.display.weight(.black))
            Text("\(model.seasonLabel) · \(model.weekLabel)")
                .font(CoachWorldTokens.TypeRole.body)
                .foregroundStyle(palette.contentSecondary.color)
        }
        .accessibilitySortPriority(100)
    }

    private var topBar: some View {
        HStack {
            Text("ROSTER EVIDENCE")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
            Spacer()
            Button("Done", action: onClose)
                .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                       minHeight: CoachWorldTokens.Shape.minimumTarget)
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .background(palette.raised.color)
    }
}
