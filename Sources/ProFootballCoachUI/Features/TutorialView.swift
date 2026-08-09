import SwiftUI
import FootballSimCore

/// The first-run guide: what the job is, and where each part of it lives.
///
/// It appears once, the first time a franchise opens, and is always reachable again from the
/// Coach tab. Deliberately short — five cards, each pointing at a real screen — because a wall
/// of rules before kickoff is the fastest way to lose somebody.
struct TutorialView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private struct Card: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let body: String
    }

    private let cards: [Card] = [
        .init(
            icon: "sportscourt.fill",
            title: "Your week",
            body: "The Season tab is the loop. Each week you either simulate the game or play it "
                + "yourself — both run the same engine, so neither is the easy way out. Between "
                + "games you set the depth chart, work the phone and keep the owner happy."
        ),
        .init(
            icon: "person.3.fill",
            title: "The roster is the team",
            body: "Fifty-three active players and sixteen on the practice squad. Swipe a player "
                + "on the depth chart to call him up or send him down, and drag to reorder who "
                + "starts. Ratings decide most games before kickoff."
        ),
        .init(
            icon: "dollarsign.circle.fill",
            title: "The cap is the constraint",
            body: "Every contract counts against the cap, and cutting a player leaves dead money "
                + "behind. Front Office is where you sign free agents, trade, and see exactly "
                + "what a decision costs before you make it."
        ),
        .init(
            icon: "gamecontroller.fill",
            title: "Playing a game",
            body: "Call the play, drag to aim the throw, release before the pocket collapses. "
                + "Your quarterback's accuracy decides how much room a sloppy pass gets, so good "
                + "hands help a good roster and cannot rescue a bad one."
        ),
        .init(
            icon: "figure.american.football",
            title: "Your career",
            body: "The owner sets goals every season and your job security moves with them. Hit "
                + "them and you level up, earn skill points, and get offers from better teams. "
                + "Miss them for long enough and the carousel comes for you."
        ),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: Layout.medium) {
                TabView(selection: $page) {
                    ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                        VStack(alignment: .leading, spacing: Layout.medium) {
                            Spacer(minLength: Layout.small)
                            Text("\(index + 1) of \(cards.count)")
                                .font(.labelFont)
                                .foregroundStyle(Broadcast.muted)
                            HStack(alignment: .firstTextBaseline, spacing: Layout.small) {
                                Image(systemName: card.icon)
                                    .font(.caption)
                                    .foregroundStyle(Broadcast.muted)
                                    .accessibilityHidden(true)
                                Text(card.title)
                                    .font(.displayFont)
                                    .foregroundStyle(Broadcast.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Rule()
                            Text(card.body)
                                .font(.bodyFont)
                                .foregroundStyle(Broadcast.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, Layout.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, Layout.large)
                        .tag(index)
                    }
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif

                Button(page == cards.count - 1 ? "Start Coaching" : "Next") {
                    if page == cards.count - 1 {
                        dismiss()
                    } else {
                        // The page slide is decorative; a reader who asked for less motion gets
                        // the next card without it.
                        if reduceMotion { page += 1 } else { withAnimation { page += 1 } }
                    }
                }
                .font(.titleFont)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .buttonStyle(.borderedProminent)
                .padding(Layout.medium)
            }
            .background(Broadcast.page)
            .navigationTitle("How to Coach")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Skip") { dismiss() } }
            }
        }
        .preferredColorScheme(app.appearance.colorScheme)
    }
}

/// Remembers whether the guide has been shown, so it greets a new coach exactly once.
enum TutorialPrompt {
    private static let key = "hasSeenTutorial"

    static var hasBeenSeen: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
