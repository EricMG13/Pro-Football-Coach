import SwiftUI
import FootballSimCore

/// The first-run guide: what the job is, and where each part of it lives.
///
/// It appears once, the first time a franchise opens, and is always reachable again from the
/// Coach tab. Deliberately short — five cards, each pointing at a real screen — because a wall
/// of rules before kickoff is the fastest way to lose somebody.
struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private struct Card: Identifiable {
        let id = UUID()
        let icon: String
        let tint: Color
        let title: String
        let body: String
    }

    private let cards: [Card] = [
        .init(
            icon: "sportscourt.fill",
            tint: .green,
            title: "Your week",
            body: "The Season tab is the loop. Each week you either simulate the game or play it "
                + "yourself — both run the same engine, so neither is the easy way out. Between "
                + "games you set the depth chart, work the phone and keep the owner happy."
        ),
        .init(
            icon: "person.3.fill",
            tint: .blue,
            title: "The roster is the team",
            body: "Fifty-three active players and sixteen on the practice squad. Swipe a player "
                + "on the depth chart to call him up or send him down, and drag to reorder who "
                + "starts. Ratings decide most games before kickoff."
        ),
        .init(
            icon: "dollarsign.circle.fill",
            tint: .orange,
            title: "The cap is the constraint",
            body: "Every contract counts against the cap, and cutting a player leaves dead money "
                + "behind. Front Office is where you sign free agents, trade, and see exactly "
                + "what a decision costs before you make it."
        ),
        .init(
            icon: "gamecontroller.fill",
            tint: .purple,
            title: "Playing a game",
            body: "Call the play, drag to aim the throw, release before the pocket collapses. "
                + "Your quarterback's accuracy decides how much room a sloppy pass gets, so good "
                + "hands help a good roster and cannot rescue a bad one."
        ),
        .init(
            icon: "figure.american.football",
            tint: .red,
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
                        VStack(spacing: Layout.large) {
                            Spacer(minLength: Layout.large)
                            Image(systemName: card.icon)
                                .font(.system(size: 64))
                                .foregroundStyle(card.tint)
                            Text(card.title)
                                .font(.system(.title, design: .rounded, weight: .bold))
                                .multilineTextAlignment(.center)
                            Text(card.body)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, Layout.large)
                            Spacer()
                            Text("\(index + 1) of \(cards.count)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
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
                        withAnimation { page += 1 }
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(Layout.medium)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
                .padding(Layout.medium)
            }
            .navigationTitle("How to Coach")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Skip") { dismiss() } }
            }
        }
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
