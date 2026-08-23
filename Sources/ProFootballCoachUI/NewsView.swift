import SwiftUI

public struct NewsView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: NewsReadModel
    public let statusMessage: String?
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var openStoryID: String?

    public init(model: NewsReadModel, statusMessage: String? = nil, onClose: @escaping () -> Void) {
        self.model = model
        self.statusMessage = statusMessage
        self.onClose = onClose
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    public var body: some View {
        CoachWorldFloodlitStage(palette: palette, chrome: chrome, onNavigate: onNavigateChrome) {
            scrollContent
        }
        .accessibilitySortPriority(100)
        .background(alignment: .topLeading) { CanonicalScreenStamp(id: 50) }
    }

    private var scrollContent: some View {
        ScrollView {
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
                        .empty("No news recorded. Nothing has happened in this world yet."),
                        palette: palette
                    )
                } else if dynamicTypeSize.isAccessibilitySize {
                    storyList
                    storyPanel
                } else {
                    HStack(alignment: .top, spacing: CoachWorldTokens.Gap.lg) {
                        storyList
                            .frame(width: NewsMetric.listWidth)
                        storyPanel
                    }
                }
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
        .safeAreaInset(edge: .bottom) { footer }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.md) {
            FloodlitLabel3("The league in print", palette: palette)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitLabel3(model.weekLabel, palette: palette)
        }
    }

    /// The left column: dateline over headline, one row per story.
    private var storyList: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
            ForEach(model.items) { item in
                FloodlitRow(
                    isSelected: openStory?.stableID == item.stableID,
                    palette: palette,
                    action: { openStoryID = item.stableID }
                ) {
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                        FloodlitLabel3(item.occurred, palette: palette, tint: datelineTint(item))
                        Text(item.headline.uppercased())
                            .font(
                                CoachWorldTokens.display(
                                    CoachWorldTokens.DisplaySize.actionSmall, weight: .bold
                                )
                            )
                            .lineLimit(NewsMetric.headlineLines)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityLabel("\(item.occurred). \(item.headline)")
            }
        }
    }

    /// How much the world thinks of a story. `weight` is the model's own ranking, so the dateline
    /// of a heavy story is lit and the rest are quiet -- no new figure is invented to say so.
    private func datelineTint(_ item: NewsReadModel.Item) -> Color {
        item.weight >= NewsMetric.leadWeight
            ? palette.actionPrimary.color
            : palette.contentQuiet.color
    }

    private var openStory: NewsReadModel.Item? {
        model.items.first { $0.stableID == openStoryID } ?? model.items.first
    }

    /// The right column: the opened story, whole.
    ///
    /// The reference sets a body paragraph and an attributed line beneath the headline.
    /// `NewsReadModel.Item` records a dateline and a headline and nothing else, so the panel says
    /// the story is a headline rather than padding it out with invented prose.
    @ViewBuilder
    private var storyPanel: some View {
        if let story = openStory {
            FloodlitCard(palette: palette, depth: .deep) {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
                    FloodlitLabel3(story.occurred, palette: palette, tint: datelineTint(story))
                    Text(story.headline.uppercased())
                        .font(
                            CoachWorldTokens.display(
                                CoachWorldTokens.DisplaySize.subject, weight: .bold
                            )
                        )
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: CoachWorldTokens.Gap.xs)
                    Text("The league records the event, not the article behind it.")
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentQuiet.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? nil : NewsMetric.panelHeight,
                   alignment: .top)
        }
    }

    private var footer: some View {
        HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            Text("Everything printed here happened. None of it is speculation.")
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            Button("Back to the league", action: onClose)
                .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
        }
        .floodlitFooterStrip(palette: palette)
    }
}

private enum NewsMetric {
    /// The handoff's 330pt story list and 264pt reading panel.
    static let listWidth: CGFloat = 330
    static let panelHeight: CGFloat = 264
    static let headlineLines = 3
    /// `DomainEvent.historicalWeight` is a 0-100 scale: a season ending is 100, a suspension 15.
    /// 60 is where the world's own structural events start -- a portal window, a market opening,
    /// a draft. Above it a dateline is lit; below it, quiet.
    static let leadWeight = 60
}
