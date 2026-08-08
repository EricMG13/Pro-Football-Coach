import SwiftUI
import FootballSimCore

/// Entry point. Shows the menu until a franchise is loaded, then the tabbed franchise shell.
public struct RootView: View {
    @State private var app = AppState()

    public init() {}

    public var body: some View {
        Group {
            if app.league == nil {
                MainMenuView()
            } else {
                FranchiseShell()
            }
        }
        .environment(app)
        .environment(\.teamTheme, app.theme)
        .tint(app.theme.primary)
    }
}

/// The tab bar the whole franchise lives inside. Which tabs exist depends on the phase, so the
/// preseason and the offseason are not cluttered with screens that have nothing to show.
struct FranchiseShell: View {
    @Environment(AppState.self) private var app
    @State private var showingTutorial = false

    var body: some View {
        TabView {
            NavigationStack { SeasonHubView() }
                .tabItem { Label(phaseTabTitle, systemImage: "sportscourt.fill") }

            NavigationStack { ScheduleView() }
                .tabItem { Label("Schedule", systemImage: "calendar") }

            NavigationStack { TeamView() }
                .tabItem { Label("Team", systemImage: "person.3.fill") }

            NavigationStack { FrontOfficeView() }
                .tabItem { Label("Front Office", systemImage: "dollarsign.circle.fill") }

            NavigationStack { CoachView() }
                .tabItem { Label("Coach", systemImage: "figure.american.football") }
        }
        .sheet(isPresented: $showingTutorial) { TutorialView() }
        .onAppear {
            guard !TutorialPrompt.hasBeenSeen else { return }
            TutorialPrompt.hasBeenSeen = true
            showingTutorial = true
        }
    }

    private var phaseTabTitle: String {
        guard let phase = app.league?.phase else { return "Season" }
        return phase.isOffseason ? "Offseason" : "Season"
    }
}

/// Pre-franchise menu.
struct MainMenuView: View {
    @Environment(AppState.self) private var app
    @State private var showingNewGame = false
    @State private var showingLoad = false
    @State private var showingScenarios = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Layout.large) {
                    header

                    VStack(spacing: 0) {
                        menuRow(
                            icon: "play.circle.fill",
                            tint: .green,
                            title: "New Franchise",
                            subtitle: "Take over a team and build a dynasty"
                        ) { showingNewGame = true }

                        Divider().padding(.leading, 60)

                        menuRow(
                            icon: "folder.fill",
                            tint: .blue,
                            title: "Load Franchise",
                            subtitle: app.saves.isEmpty
                                ? "No saved franchises yet"
                                : "\(app.saves.count) saved franchise\(app.saves.count == 1 ? "" : "s")"
                        ) { showingLoad = true }
                        .disabled(app.saves.isEmpty)

                        Divider().padding(.leading, 60)

                        menuRow(
                            icon: "flag.checkered",
                            tint: .orange,
                            title: "Scenarios",
                            subtitle: "Preset challenges with a single objective"
                        ) { showingScenarios = true }
                    }
                    .card()

                    Text("Every team, player and league in this game is fictional.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(Layout.medium)
            }
            .background(Color.pageBackground)
            .navigationTitle("")
            .sheet(isPresented: $showingNewGame) { NewFranchiseWizard() }
            .sheet(isPresented: $showingLoad) { LoadFranchiseView() }
            .sheet(isPresented: $showingScenarios) { ScenarioPickerView() }
        }
    }

    private var header: some View {
        VStack(spacing: Layout.small) {
            Image(systemName: "football.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)
                .padding(Layout.large)
                .background(Circle().fill(Color.cardFill))
            Text("Pro Football Coach")
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .multilineTextAlignment(.center)
            Text("Run the franchise. Call every down.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, Layout.large)
    }

    private func menuRow(
        icon: String,
        tint: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Layout.medium) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(tint)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding(.vertical, Layout.small)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct LoadFranchiseView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(app.saves) { save in
                    Button {
                        app.load(id: save.id)
                        dismiss()
                    } label: {
                        HStack(spacing: Layout.medium) {
                            Circle()
                                .fill(Color(hex: save.primaryHex))
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Text(save.teamAbbreviation)
                                        .font(.system(size: 10, weight: .heavy))
                                        .foregroundStyle(.white)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(save.name).font(.headline)
                                Text("\(save.teamName) · \(String(save.year)) · \(save.phaseLabel)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    for index in offsets { app.delete(id: app.saves[index].id) }
                }
            }
            .navigationTitle("Load Franchise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
