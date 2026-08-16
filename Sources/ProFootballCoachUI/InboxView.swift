import SwiftUI

public struct InboxView: View {
    public let model: InboxReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    public let onOpen: (CoachWorldScreenID) -> Void
    public let onRead: (String) -> Void
    public let onContinue: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: InboxReadModel,
        statusMessage: String? = nil,
        onClose: @escaping () -> Void,
        onOpen: @escaping (CoachWorldScreenID) -> Void,
        onRead: @escaping (String) -> Void = { _ in },
        onContinue: @escaping () -> Void
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onClose = onClose
        self.onOpen = onOpen
        self.onRead = onRead
        self.onContinue = onContinue
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
                header
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if model.items.isEmpty {
                    ContentUnavailableView(
                        "Inbox is clear",
                        systemImage: "list.number",
                        description: Text("No decisions or current-week stories are recorded.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 180)
                } else {
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                        Text("RECENT INBOX")
                            .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                            .foregroundStyle(palette.contentSecondary.color)
                        ForEach(model.items) { item in
                            itemRow(item)
                        }
                    }
                }
                Button(action: onContinue) {
                    Label("Continue", systemImage: "forward.end.fill")
                        .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget)
                }
                .buttonStyle(CoachWorldActionButtonStyle(
                    role: model.canContinue ? .primary : .secondary,
                    palette: palette
                ))
                .disabled(!model.canContinue)
                .accessibilityHint(model.continueReason ?? "")
            }
            .padding(CoachWorldTokens.Space.md)
        }
        .foregroundStyle(palette.contentPrimary.color)
        .background(palette.page.color.ignoresSafeArea())
        .accessibilitySortPriority(100)
    }

    @ViewBuilder
    private var header: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                titleBlock
                Button("Done", action: onClose)
                    .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                           minHeight: CoachWorldTokens.Shape.minimumTarget)
            }
        } else {
            HStack(alignment: .top) {
                titleBlock
                Spacer(minLength: CoachWorldTokens.Space.sm)
                Button("Done", action: onClose)
                    .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                           minHeight: CoachWorldTokens.Shape.minimumTarget)
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text("INBOX")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            Text(model.team.name)
                .font(CoachWorldTokens.TypeRole.display.weight(.black))
                .fixedSize(horizontal: false, vertical: true)
            Text(model.weekLabel)
                .font(CoachWorldTokens.TypeRole.body)
                .foregroundStyle(palette.contentSecondary.color)
        }
    }

    @ViewBuilder
    private func itemRow(_ item: InboxReadModel.Item) -> some View {
        let content = VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.title)
                    .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                Spacer(minLength: CoachWorldTokens.Space.xs)
                Text(item.isUnread
                     ? (item.kind == .task ? "TODO" : "NEW")
                     : (item.kind == .decision ? "DUE" : "READ"))
                    .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                    .foregroundStyle(item.isUnread ? palette.collegeIdentity.color : palette.contentSecondary.color)
            }
            Text(item.body)
                .font(CoachWorldTokens.TypeRole.callout)
                .fixedSize(horizontal: false, vertical: true)
            Text([item.sourceLabel, item.received, item.deadline].compactMap { $0 }.joined(separator: " · "))
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(CoachWorldTokens.Space.sm)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(palette.raised.color.opacity(0.72))
        .overlay {
            RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius)
                .stroke(palette.contentQuiet.color.opacity(0.6), lineWidth: CoachWorldTokens.Shape.hairline)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(item.title), \(item.body), \(item.sourceLabel), \(item.received)"
                + (item.deadline.map { ", \($0)" } ?? "")
                + ", \(item.isUnread ? "Unread" : "Read") \(item.kind.rawValue)"
        )

        if let destination = item.destination {
            Button {
                onRead(item.stableID)
                onOpen(destination)
            } label: { content }
                .buttonStyle(.plain)
        } else {
            Button(action: { onRead(item.stableID) }) { content }
                .buttonStyle(.plain)
        }
    }
}
