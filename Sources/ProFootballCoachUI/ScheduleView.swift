import SwiftUI

public struct ScheduleView: View {
    public let model: ScheduleReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    public let onContinue: () -> Void
    public let onSelectTeam: (UUID) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: ScheduleReadModel,
        statusMessage: String? = nil,
        onClose: @escaping () -> Void,
        onContinue: @escaping () -> Void,
        onSelectTeam: @escaping (UUID) -> Void = { _ in }
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onClose = onClose
        self.onContinue = onContinue
        self.onSelectTeam = onSelectTeam
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    public var body: some View {
        VStack(spacing: .zero) {
            topBar
            if let statusMessage {
                Text(statusMessage)
                    .font(CoachWorldTokens.TypeRole.callout)
                    .foregroundStyle(palette.stateWarning.color)
                    .padding(.horizontal, CoachWorldTokens.Space.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if model.games.isEmpty {
                ContentUnavailableView(
                    "No \(model.tier.lowercased()) games",
                        systemImage: "calendar.badge.exclamationmark",
                    description: Text("The schedule is empty for this season.")
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                        ForEach(model.games) { game in gameRow(game) }
                    }
                    .padding(CoachWorldTokens.Space.md)
                }
            }
        }
        .foregroundStyle(palette.contentPrimary.color)
        .background(palette.page.color.ignoresSafeArea())
        .frame(maxWidth: .infinity,
               alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .center)
        .accessibilitySortPriority(100)
    }

    private var topBar: some View {
        HStack(spacing: CoachWorldTokens.Space.sm) {
            Button("League", action: onClose)
                .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                       minHeight: CoachWorldTokens.Shape.minimumTarget)
            VStack(alignment: .leading, spacing: .zero) {
                Text("\(model.tier) schedule")
                    .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                Text(model.seasonLabel)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
            }
            Spacer()
            Button(action: onContinue) {
                Label("Continue", systemImage: "forward.end.fill")
            }
            .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .background(palette.raised.color)
    }

    private func gameRow(_ game: ScheduleReadModel.GameRow) -> some View {
        Button {
            guard let id = UUID(uuidString: game.home.stableID) else { return }
            onSelectTeam(id)
        } label: {
            HStack(spacing: CoachWorldTokens.Space.sm) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                Text(game.week)
                    .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                    .foregroundStyle(palette.collegeIdentity.color)
                Text(game.stage)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
            }
            .frame(width: 78, alignment: .leading)
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                Text(game.away.name)
                Text(game.home.name)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: CoachWorldTokens.Space.xxs) {
                Text(game.score ?? "—")
                    .font(.headline.weight(.bold))
                    .monospacedDigit()
                Text(game.score == nil ? "Scheduled" : "Final")
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
            }
            .frame(width: 74, alignment: .trailing)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .frame(minHeight: 66)
        .background(
            game.isControlled
                ? palette.collegeIdentity.color.opacity(0.14)
                : palette.raised.color
        )
        .clipShape(RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(game.week), \(game.away.name) at \(game.home.name), "
                + "\(game.score ?? "scheduled")"
        )
    }
}
