import SwiftUI

public struct InboxView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?

    public let model: InboxReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    public let onOpen: (CoachWorldScreenID) -> Void
    public let onRead: (String) -> Void
    public let onContinue: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedID: String = ""

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
        CoachWorldFloodlitStage(palette: palette, chrome: chrome, onNavigate: onNavigateChrome) {
            scrollContent
        }
        .accessibilitySortPriority(100)
        .background(alignment: .topLeading) { CanonicalScreenStamp(id: 9) }
    }

    /// The messages scroll; the committing action does not.
    ///
    /// Six messages beside a 313-point reading pane are taller than the 291-point viewport, so a
    /// commit band at the end of the scrolling stack lands about 68 points below the bottom edge,
    /// and `04` section 7 keeps the decision due now inside the initial viewport. The band sits
    /// outside the `ScrollView` rather than pinned over it, so the scroll view's own frame shrinks
    /// by the band instead of the last message sliding underneath it.
    private var scrollContent: some View {
        VStack(spacing: .zero) {
            ScrollView {
                messages
                    .padding(.vertical, CoachWorldTokens.Pad.panel.v)
            }
            commitBar
        }
    }

    private var messages: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.md) {
            header
            if let statusMessage {
                Text(statusMessage)
                    .font(CoachWorldTokens.TypeRole.callout)
                    .foregroundStyle(palette.stateWarning.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if model.items.isEmpty {
                CoachWorldSystemState(
                    .empty(
                        "Inbox is clear. No decisions or current-week stories "
                            + "are recorded."
                    ),
                    palette: palette
                )
                .accessibilityIdentifier("weekly-command-dominant")
            } else if dynamicTypeSize.isAccessibilitySize {
                // At AX sizes the two columns stack: the reading pane cannot hold a message
                // beside a list of six at 310 points wide, and cutting the message is worse
                // than scrolling to it.
                readingPane
                messageList
            } else {
                HStack(alignment: .top, spacing: CoachWorldTokens.Gap.lg) {
                    readingPane
                    messageList
                        .frame(width: InboxMetric.listWidth)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.xs) {
            // The rail is the way back once the chrome is present; the link only exists for the
            // bare stage, where nothing else leaves this screen.
            if chrome == nil {
                Button(action: onClose) {
                    Text("\u{2190} Back")
                        .font(
                            CoachWorldTokens.display(
                                CoachWorldTokens.DisplaySize.actionSmall, weight: .bold
                            )
                        )
                        .foregroundStyle(palette.contentSecondary.color)
                        .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                               minHeight: CoachWorldTokens.Shape.minimumTarget,
                               alignment: .leading)
                }
                .buttonStyle(.plain)
            }
            FloodlitLabel3("Inbox \u{00B7} \(model.weekLabel)", palette: palette)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            if unreadCount > 0 {
                FloodlitLabel3(
                    "\(unreadCount) unanswered",
                    palette: palette,
                    tint: palette.actionPrimary.color
                )
            }
        }
    }

    private var unreadCount: Int {
        model.items.filter(\.isUnread).count
    }

    /// The message the reading pane is showing. Selection is presentation state, so it falls back
    /// to the first message rather than carrying an empty pane.
    private var selected: InboxReadModel.Item? {
        model.items.first { $0.stableID == selectedID } ?? model.items.first
    }

    /// The left column: one tappable row per message, tag then subject then sender.
    private var messageList: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xxs) {
            ForEach(model.items) { item in
                FloodlitRow(
                    isSelected: selected?.stableID == item.stableID,
                    palette: palette,
                    action: {
                        selectedID = item.stableID
                        onRead(item.stableID)
                    }
                ) {
                    HStack(spacing: CoachWorldTokens.Gap.md) {
                        Text(tag(for: item).uppercased())
                            .font(
                                CoachWorldTokens.display(
                                    CoachWorldTokens.DisplaySize.flag, weight: .bold
                                )
                            )
                            .tracking(
                                CoachWorldTokens.DisplaySize.tracking(
                                    CoachWorldTokens.DisplaySize.labelTracking,
                                    at: CoachWorldTokens.DisplaySize.flag
                                )
                            )
                            .foregroundStyle(tone(for: item))
                            .lineLimit(1)
                            .frame(width: InboxMetric.tagColumn, alignment: .leading)
                        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                            Text(item.title)
                                .font(
                                    CoachWorldTokens.display(
                                        CoachWorldTokens.DisplaySize.row, weight: .bold
                                    )
                                )
                                .foregroundStyle(
                                    item.isUnread
                                        ? palette.contentPrimary.color
                                        : palette.contentSecondary.color
                                )
                                .lineLimit(InboxMetric.subjectLines)
                                .multilineTextAlignment(.leading)
                            Text(item.sourceLabel.uppercased())
                                .font(
                                    CoachWorldTokens.display(
                                        CoachWorldTokens.DisplaySize.flag, weight: .bold
                                    )
                                )
                                .tracking(
                                    CoachWorldTokens.DisplaySize.tracking(
                                        CoachWorldTokens.DisplaySize.labelTracking,
                                        at: CoachWorldTokens.DisplaySize.flag
                                    )
                                )
                                .foregroundStyle(palette.contentQuiet.color)
                                .lineLimit(1)
                        }
                        Spacer(minLength: .zero)
                    }
                }
                .accessibilityLabel(
                    "\(item.title), from \(item.sourceLabel), "
                        + "\(item.isUnread ? "unread" : "read") \(item.kind.rawValue)"
                )
            }
        }
    }

    /// The right column: the opened message, whole, with what it is waiting on.
    @ViewBuilder
    private var readingPane: some View {
        if let item = selected {
            FloodlitCard(palette: palette, depth: .deep) {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
                    HStack(spacing: CoachWorldTokens.Gap.smPlus) {
                        FloodlitLabel3(item.sourceLabel, palette: palette)
                            .accessibilityIdentifier("weekly-command-dominant")
                        Spacer(minLength: CoachWorldTokens.Gap.xs)
                        FloodlitFlag(tag(for: item), tint: tone(for: item), palette: palette)
                    }
                    Text(item.title)
                        .font(
                            CoachWorldTokens.display(
                                CoachWorldTokens.DisplaySize.subject, weight: .bold
                            )
                        )
                        .fixedSize(horizontal: false, vertical: true)
                    Text(item.body)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.contentSecondary.color)
                        .fixedSize(horizontal: false, vertical: true)
                    FloodlitCostLine(
                        cost: item.received,
                        exposure: item.deadline,
                        palette: palette
                    )
                    Spacer(minLength: CoachWorldTokens.Gap.xs)
                    if let destination = item.destination {
                        Button {
                            onRead(item.stableID)
                            onOpen(destination)
                        } label: {
                            Text("Open the \(destination.navigationName.lowercased())")
                                .font(
                                    CoachWorldTokens.display(
                                        CoachWorldTokens.DisplaySize.action, weight: .bold
                                    )
                                )
                                .foregroundStyle(palette.actionPrimary.color)
                                .frame(minHeight: CoachWorldTokens.Shape.minimumTarget,
                                       alignment: .leading)
                                // Sizing alone does not move the target: without a content shape
                                // the button's hit and accessibility region stays the glyph bounds,
                                // which measured 17 points tall against a 44-point floor.
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: InboxMetric.paneHeight, alignment: .top)
        }
    }

    /// The tag the reference prints at the head of every row: what the message wants, not what
    /// kind of object it is. A decision is waiting on the coach; a task is on the staff; a story
    /// is only news.
    private func tag(for item: InboxReadModel.Item) -> String {
        switch item.kind {
        case .decision: item.deadline == nil ? "Decide" : "Due"
        case .task: "To do"
        case .story: item.isUnread ? "New" : "Filed"
        }
    }

    private func tone(for item: InboxReadModel.Item) -> Color {
        switch item.kind {
        case .decision: palette.actionPrimary.color
        case .task: palette.contentSecondary.color
        case .story: item.isUnread ? palette.contentPrimary.color : palette.contentQuiet.color
        }
    }

    /// One committing action, bottom-right in the thumb arc, with the reference's quiet "File it"
    /// beside it.
    private var commitBar: some View {
        HStack(spacing: CoachWorldTokens.Gap.md) {
            Spacer(minLength: .zero)
            if let item = selected, item.isUnread {
                // The frame belongs inside the label. Applied to the `Button` it expands the
                // layout box while the target stays the text, which measured 27 x 14 points.
                Button {
                    onRead(item.stableID)
                } label: {
                    Text("File it")
                        .font(
                            CoachWorldTokens.display(
                                CoachWorldTokens.DisplaySize.actionSmall, weight: .bold
                            )
                        )
                        .foregroundStyle(palette.contentQuiet.color)
                        .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                               minHeight: CoachWorldTokens.Shape.minimumTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            FloodlitCommittingAction(
                "Advance week",
                isEnabled: model.canContinue,
                action: onContinue
            )
            .accessibilityHint(model.continueReason ?? "")
        }
        .padding(.top, CoachWorldTokens.Gap.xs)
    }
}

private enum InboxMetric {
    /// The handoff's 300pt message list, plus the row padding the reference draws inside it.
    static let listWidth: CGFloat = 310
    static let tagColumn: CGFloat = 62
    static let subjectLines = 2
    /// The handoff's 313pt reading pane.
    static let paneHeight: CGFloat = 313
}
