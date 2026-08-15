import SwiftUI

public struct StandingsView: View {
    public let model: StandingsReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    public let onContinue: () -> Void
    public let onSelectTeam: (UUID) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: StandingsReadModel,
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
        colorScheme == .dark ? CoachWorldTokens.dark : CoachWorldTokens.light
    }

    public var body: some View {
        VStack(spacing: .zero) {
            topBar
            if let statusMessage {
                Text(statusMessage)
                    .font(CoachWorldTokens.TypeRole.callout)
                    .foregroundStyle(palette.stateWarning.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, CoachWorldTokens.Space.md)
            }
            ScrollView {
                LazyVStack(spacing: .zero) {
                    headerRow
                    ForEach(Array(model.rows.enumerated()), id: \.element.id) { index, row in
                        standingsRow(index: index, row: row)
                    }
                }
                .padding(CoachWorldTokens.Space.md)
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
                Text("\(model.tier) standings")
                    .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                Text("\(model.seasonLabel) · \(model.weekLabel)")
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

    private var headerRow: some View {
        HStack(spacing: CoachWorldTokens.Space.xs) {
            Text("#").frame(width: 24, alignment: .leading)
            Text("TEAM").frame(maxWidth: .infinity, alignment: .leading)
            Text("REC").frame(width: 76, alignment: .leading)
            Text("CONF").frame(width: 76, alignment: .leading)
            Text("PF–PA").frame(width: 70, alignment: .trailing)
        }
        .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
        .foregroundStyle(palette.contentSecondary.color)
        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Standings columns: rank, team, record, conference record, points for and against")
    }

    private func standingsRow(index: Int, row: StandingsReadModel.Row) -> some View {
        Button {
            guard let id = UUID(uuidString: row.id) else { return }
            onSelectTeam(id)
        } label: {
            HStack(spacing: CoachWorldTokens.Space.xs) {
            Text("\(index + 1)")
                .frame(width: 24, alignment: .leading)
                .monospacedDigit()
            VStack(alignment: .leading, spacing: .zero) {
                Text(row.team.name)
                    .fontWeight(row.isControlled ? .bold : .regular)
                Text(row.team.abbreviation)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(row.record)
                .frame(width: 76, alignment: .leading)
                .monospacedDigit()
            Text(row.conferenceRecord)
                .frame(width: 76, alignment: .leading)
                .monospacedDigit()
            Text("\(row.pointsFor)–\(row.pointsAgainst)")
                .frame(width: 70, alignment: .trailing)
                .monospacedDigit()
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, CoachWorldTokens.Space.xs)
        .frame(minHeight: 54)
        .background(
            row.isControlled
                ? palette.collegeIdentity.color.opacity(0.14)
                : Color.clear
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(palette.contentQuiet.color.opacity(0.35))
                .frame(height: CoachWorldTokens.Shape.hairline)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(index + 1), \(row.team.name), \(row.record), conference \(row.conferenceRecord), "
                + "\(row.pointsFor) points for, \(row.pointsAgainst) against"
        )
    }
}
