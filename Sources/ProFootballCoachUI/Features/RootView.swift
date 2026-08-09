import SwiftUI
import FootballSimCore

/// Entry point. Shows the menu until a franchise is loaded, then the tabbed franchise shell.
public struct RootView: View {
    @State private var app = AppState()
    @Environment(\.scenePhase) private var scenePhase

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
        .tint(app.theme.tint)
        .preferredColorScheme(app.appearance.colorScheme)
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { app.lastError != nil },
                set: { if !$0 { app.lastError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { app.lastError = nil }
        } message: {
            Text(app.lastError ?? "")
        }
        .alert(
            app.pendingPayoff?.title ?? "",
            isPresented: Binding(
                get: { app.pendingPayoff != nil },
                set: { if !$0 { app.clearPayoff() } }
            )
        ) {
            Button("Good") { app.clearPayoff() }
        } message: {
            Text(app.pendingPayoff?.detail ?? "")
        }
        .onChange(of: scenePhase) { _, phase in
            // A dynasty must never be lost to a write that did not finish before the app left
            // the foreground.
            if phase != .active { Task { await app.flush() } }
        }
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
        .appearanceAware()
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
                            title: "New Franchise",
                            subtitle: "Take over a team and build a dynasty"
                        ) { showingNewGame = true }

                        menuRow(
                            icon: "folder.fill",
                            title: "Load Franchise",
                            subtitle: app.saves.isEmpty
                                ? "No saved franchises yet"
                                : "\(app.saves.count) saved franchise\(app.saves.count == 1 ? "" : "s")"
                        ) { showingLoad = true }
                        .disabled(app.saves.isEmpty)

                        menuRow(
                            icon: "flag.checkered",
                            title: "Scenarios",
                            subtitle: "Preset challenges with a single objective"
                        ) { showingScenarios = true }
                    }

                    Text("Every team, player and league in this game is fictional.")
                        .font(.labelFont)
                        .foregroundStyle(Broadcast.muted)
                        .multilineTextAlignment(.center)
                }
                .padding(Layout.medium)
            }
            .background(Broadcast.page)
            .navigationTitle("")
            .sheet(isPresented: $showingNewGame) { NewFranchiseWizard() }
            .appearanceAware()
            .sheet(isPresented: $showingLoad) { LoadFranchiseView() }
            .appearanceAware()
            .sheet(isPresented: $showingScenarios) { ScenarioPickerView() }
            .appearanceAware()
        }
    }

    /// The cover, and — once a franchise exists — the front page of your league.
    private var header: some View {
        VStack(alignment: .leading, spacing: Layout.small) {
            Text("Pro Football Coach")
                .font(.displayFont)
                .foregroundStyle(Broadcast.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("Run the franchise. Call every down.")
                .font(.bodyFont)
                .foregroundStyle(Broadcast.muted)

            Rule()

            if let latest = app.saves.first {
                // The most recent franchise is the standing headline, not a row buried in a sheet.
                Button { app.load(id: latest.id) } label: {
                    VStack(alignment: .leading, spacing: Layout.tight) {
                        Text("Where you left off")
                            .font(.labelFont)
                            .foregroundStyle(Broadcast.muted)
                        HStack(alignment: .center, spacing: Layout.small) {
                            TeamMark(
                                abbreviation: latest.teamAbbreviation,
                                primaryHex: latest.primaryHex,
                                secondaryHex: latest.secondaryHex,
                                size: 34
                            )
                            Text(latest.teamName)
                                .font(.titleFont)
                                .foregroundStyle(Broadcast.ink)
                            Spacer(minLength: 0)
                            Text(String(latest.year))
                                .font(.figureFont)
                                .foregroundStyle(Broadcast.ink)
                        }
                        Text("\(latest.phaseLabel) · \(latest.coachName)")
                            .font(.labelFont)
                            .foregroundStyle(Broadcast.muted)
                        Rule()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    "Continue \(latest.teamName), \(String(latest.year)), \(latest.phaseLabel), "
                        + "coached by \(latest.coachName)"
                )
            }
        }
        .padding(.top, Layout.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// A line of the contents page. The icons were three decorative rainbow glyphs carrying no
    /// meaning, against the system's own rule that colour is only used where it means something.
    private func menuRow(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Layout.tight) {
                HStack(alignment: .firstTextBaseline, spacing: Layout.small) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(Broadcast.muted)
                        .frame(width: 20)
                        .accessibilityHidden(true)
                    Text(title)
                        .font(.titleFont)
                        .foregroundStyle(Broadcast.ink)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Broadcast.muted)
                }
                Text(subtitle)
                    .font(.labelFont)
                    .foregroundStyle(Broadcast.muted)
                    .padding(.leading, 28)
                Rule()
            }
            .padding(.vertical, Layout.tight)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

struct LoadFranchiseView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var pendingDelete: SaveMeta?

    var body: some View {
        NavigationStack {
            List {
                ForEach(app.saves) { save in
                    Button {
                        app.load(id: save.id)
                        // Only leave if the franchise actually opened. Dismissing regardless
                        // would take the failure alert down with the sheet, unseen.
                        if app.league != nil { dismiss() }
                    } label: {
                        HStack(spacing: Layout.medium) {
                            TeamMark(
                                abbreviation: save.teamAbbreviation,
                                primaryHex: save.primaryHex,
                                secondaryHex: save.secondaryHex,
                                size: 34
                            )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(save.name)
                                    .font(.titleFont)
                                    .foregroundStyle(Broadcast.ink)
                                Text("\(save.teamName) · \(String(save.year)) · \(save.phaseLabel)")
                                    .font(.labelFont)
                                    .foregroundStyle(Broadcast.muted)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { pendingDelete = save } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Broadcast.page)
            .navigationTitle("Load Franchise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .preferredColorScheme(app.appearance.colorScheme)
            .alert(
                "Delete \(pendingDelete?.name ?? "this franchise")?",
                isPresented: Binding(
                    get: { pendingDelete != nil },
                    set: { if !$0 { pendingDelete = nil } }
                ),
                presenting: pendingDelete
            ) { save in
                Button("Delete", role: .destructive) {
                    app.delete(id: save.id)
                    pendingDelete = nil
                }
                Button("Keep", role: .cancel) { pendingDelete = nil }
            } message: { save in
                Text("\(save.teamName), \(String(save.year)), \(save.phaseLabel). "
                     + "This cannot be undone.")
            }
        }
    }
}
