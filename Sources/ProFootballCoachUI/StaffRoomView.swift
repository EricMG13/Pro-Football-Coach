import SwiftUI

public struct StaffRoomView: View {
    public let model: StaffRoomReadModel
    public let title: String
    public let statusMessage: String?
    public let onClose: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: StaffRoomReadModel,
        title: String = "STAFF ROOM",
        statusMessage: String? = nil,
        onClose: @escaping () -> Void
    ) {
        self.model = model
        self.title = title
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
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if model.rows.isEmpty {
                    Text("No employed staff are recorded for this organisation.")
                        .foregroundStyle(palette.contentSecondary.color)
                } else {
                    ForEach(model.rows) { row in
                        staffRow(row)
                    }
                }
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
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                    titleBlock
                    closeButton
                }
            } else {
                HStack(alignment: .top) {
                    titleBlock
                    Spacer(minLength: CoachWorldTokens.Space.sm)
                    closeButton
                }
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text(title)
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            Text(model.team.name)
                .font(CoachWorldTokens.TypeRole.display.weight(.black))
                .fixedSize(horizontal: false, vertical: true)
            Text(model.seasonLabel)
                .foregroundStyle(palette.contentSecondary.color)
        }
    }

    private var closeButton: some View {
        Button("Done", action: onClose)
            .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                   minHeight: CoachWorldTokens.Shape.minimumTarget)
    }

    private func staffRow(_ row: StaffRoomReadModel.StaffRow) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.name).font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                Spacer(minLength: CoachWorldTokens.Space.xs)
                Text(row.role).font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
            }
            Text("Age \(row.age) · Reputation \(row.reputation) · \(row.seasonsWithProgramme) season(s) together")
                .font(CoachWorldTokens.TypeRole.body)
                .foregroundStyle(palette.contentSecondary.color)
            Text("Development \(row.development) · Recruiting \(row.recruiting) · Planning \(row.gamePlanning) · Scheme \(row.schemeAffinity)")
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentSecondary.color)
        }
        .padding(CoachWorldTokens.Space.sm)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .background(palette.raised.color.opacity(0.7))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(row.name), \(row.role), age \(row.age), reputation \(row.reputation), "
                + "development \(row.development), recruiting \(row.recruiting), "
                + "planning \(row.gamePlanning), scheme affinity \(row.schemeAffinity)"
        )
    }
}
