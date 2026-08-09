import SwiftUI
import FootballSimCore

/// Four-step setup: pick a team, create a coach, set the rules, confirm.
struct NewFranchiseWizard: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var teamIndex = 0
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var age = 42
    @State private var background: CoachBackground = .playcaller
    @State private var settings = LeagueSettings()
    @State private var saveName = ""
    @State private var search = ""
    @State private var confirmingCancel = false

    private var selectedEntry: TeamTable.Entry { TeamTable.entries[teamIndex] }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                StepIndicator(current: step, total: 4)
                    .padding(.horizontal, Layout.medium)
                    .padding(.vertical, Layout.small)

                Group {
                    switch step {
                    case 0: teamStep
                    case 1: coachStep
                    case 2: rulesStep
                    default: confirmStep
                    }
                }

                footer
            }
            .background(Broadcast.page)
            .scrollContentBackground(.hidden)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { confirmingCancel = true }
                }
            }
        }
        // Founding a franchise is four steps of input. A stray downward swipe used to throw all
        // of it away without a word.
        .interactiveDismissDisabled(hasEnteredSomething)
        .confirmationDialog(
            "Leave without starting?",
            isPresented: $confirmingCancel,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep setting up", role: .cancel) {}
        } message: {
            Text("Your team, coach and rules are not saved until you start the franchise.")
        }
        // A sheet sits outside the root's hierarchy, so the chosen appearance does not reach it.
        .preferredColorScheme(app.appearance.colorScheme)
    }

    /// Anything worth warning about before a dismissal throws it away.
    private var hasEnteredSomething: Bool {
        step > 0 || !coachName.isEmpty || !saveName.isEmpty
    }

    private var title: String {
        switch step {
        case 0: "Choose Your Team"
        case 1: "Create Your Coach"
        case 2: "League Rules"
        default: "Confirm"
        }
    }

    // MARK: - Steps

    private var teamStep: some View {
        List {
            Section {
                TextField("Search teams", text: $search)
            }
            ForEach(Conference.allCases, id: \.self) { conference in
                ForEach(Division.allCases, id: \.self) { division in
                    let entries = TeamTable.entries.enumerated().filter { _, entry in
                        entry.conference == conference && entry.division == division
                            && (search.isEmpty
                                || "\(entry.city) \(entry.name)".localizedCaseInsensitiveContains(search))
                    }
                    if !entries.isEmpty {
                        Section("\(conference.displayName) \(division.displayName)") {
                            ForEach(entries, id: \.offset) { index, entry in
                                Button {
                                    teamIndex = index
                                } label: {
                                    HStack(spacing: Layout.medium) {
                                        TeamBadge(
                                            abbreviation: entry.abbreviation,
                                            primaryHex: entry.primaryHex,
                                            secondaryHex: entry.secondaryHex
                                        )
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(entry.city) \(entry.name)")
                                                .font(.titleFont)
                                                .foregroundStyle(Broadcast.ink)
                                            Text(entry.stadium)
                                                .font(.labelFont)
                                                .foregroundStyle(Broadcast.muted)
                                        }
                                        Spacer(minLength: Layout.tight)
                                        if teamIndex == index { Stamp("Chosen") }
                                    }
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel(
                                        "\(entry.city) \(entry.name), \(entry.stadium)"
                                            + (teamIndex == index ? ". Chosen." : "")
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private var coachStep: some View {
        Form {
            Section("Coach") {
                TextField("First name", text: $firstName)
                TextField("Last name", text: $lastName)
                Stepper("Age: \(age)", value: $age, in: 30...65)
            }

            Section {
                ForEach(CoachBackground.allCases, id: \.self) { option in
                    Button {
                        background = option
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.displayName)
                                    .font(.titleFont)
                                    .foregroundStyle(Broadcast.ink)
                                Text(option.detail)
                                    .font(.labelFont)
                                    .foregroundStyle(Broadcast.muted)
                            }
                            Spacer(minLength: Layout.tight)
                            if background == option { Stamp("Chosen") }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            "\(option.displayName). \(option.detail)"
                                + (background == option ? " Chosen." : "")
                        )
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Background")
            } footer: {
                Text("Your background opens one branch of the coaching skill tree with a free point.")
            }

            Section("Save") {
                TextField("Franchise name (optional)", text: $saveName)
            }
        }
    }

    private var rulesStep: some View {
        Form {
            Section("Playoffs") {
                Picker("Format", selection: $settings.playoffFormat) {
                    ForEach(PlayoffFormat.allCases, id: \.self) { format in
                        Text(format.displayName).tag(format)
                    }
                }
            }
            Section("Difficulty") {
                Picker("Trades", selection: $settings.tradeDifficulty) {
                    ForEach(TradeDifficulty.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                Toggle("Salary cap", isOn: $settings.salaryCapEnabled)
                Toggle("Injuries", isOn: $settings.injuriesEnabled)
                Toggle("Coach can be fired", isOn: $settings.coachFiringEnabled)
            }
            Section {
                Toggle("Coordinators call plays", isOn: $settings.autoCallPlays)
                Toggle("Show point spreads", isOn: $settings.showPredictionLine)
            } header: {
                Text("Presentation")
            } footer: {
                Text("Point spreads replace win probability on matchup cards.")
            }
        }
    }

    private var confirmStep: some View {
        ScrollView {
            VStack(spacing: Layout.medium) {
                VStack(alignment: .leading, spacing: Layout.small) {
                    Text("The appointment")
                        .font(.labelFont)
                        .foregroundStyle(Broadcast.muted)

                    HStack(spacing: Layout.medium) {
                        TeamBadge(
                            abbreviation: selectedEntry.abbreviation,
                            primaryHex: selectedEntry.primaryHex,
                            secondaryHex: selectedEntry.secondaryHex,
                            size: 56
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(selectedEntry.city) \(selectedEntry.name)")
                                .font(.displayFont)
                                .foregroundStyle(Broadcast.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("\(selectedEntry.conference.displayName) · \(selectedEntry.division.displayName)")
                                .font(.labelFont)
                                .foregroundStyle(Broadcast.muted)
                        }
                        Spacer(minLength: 0)
                    }

                    Rule()

                    LedgerRow("Coach") { Text(coachName).foregroundStyle(Broadcast.ink) }
                    Rule()
                    LedgerRow("Age") { Text("\(age)").foregroundStyle(Broadcast.ink) }
                    Rule()
                    LedgerRow("Background") {
                        Text(background.displayName).foregroundStyle(Broadcast.ink)
                    }
                    Rule()
                    LedgerRow("Playoffs") {
                        Text(settings.playoffFormat.displayName).foregroundStyle(Broadcast.ink)
                    }
                    Rule()
                    LedgerRow("Trades") {
                        Text(settings.tradeDifficulty.displayName).foregroundStyle(Broadcast.ink)
                    }
                    Rule()
                    LedgerRow("Salary cap") {
                        Text(settings.salaryCapEnabled ? "On" : "Off").foregroundStyle(Broadcast.ink)
                    }
                    Rule()
                    LedgerRow("Injuries") {
                        Text(settings.injuriesEnabled ? "On" : "Off").foregroundStyle(Broadcast.ink)
                    }
                    Rule()
                }
            }
            .padding(Layout.medium)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: Layout.medium) {
            if step > 0 {
                Button("Back") { step -= 1 }
                    .buttonStyle(.bordered)
            }
            Button(step == 3 ? "Start Franchise" : "Continue") {
                if step == 3 { start() } else { step += 1 }
            }
            .buttonStyle(.borderedProminent)
            .disabled(step == 1 && coachName.isEmpty)
        }
        .padding(Layout.medium)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    private var coachName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }

    private func start() {
        let coach = CoachProfile(
            firstName: firstName.isEmpty ? "Alex" : firstName,
            lastName: lastName.isEmpty ? "Rivers" : lastName,
            age: age,
            background: background
        )
        app.startNewFranchise(
            teamIndex: teamIndex,
            coach: coach,
            settings: settings,
            saveName: saveName
        )
        dismiss()
    }
}

/// Where you are in the founding, said rather than dotted.
///
/// This was a row of accent capsules that widened on the current step — the reference app's
/// onboarding signature, and the exact capsule shape `Stamp` was squared off to avoid. The
/// almanac numbers its steps and rules underneath them.
struct StepIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.tight) {
            Text("Step \(current + 1) of \(total)")
                .font(.labelFont)
                .foregroundStyle(Broadcast.muted)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Broadcast.rule)
                        .frame(height: 1.5)
                    Rectangle()
                        .fill(Broadcast.ink)
                        .frame(
                            width: proxy.size.width * (Double(current + 1) / Double(total)),
                            height: 1.5
                        )
                        .motionAware(.snappy, value: current)
                }
            }
            .frame(height: 1.5)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current + 1) of \(total)")
    }
}

struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

/// The franchise badge. Delegates to `TeamMark`, which draws the club's motif from its own two
/// colours — kept as a thin shim because every screen already calls `TeamBadge`.
struct TeamBadge: View {
    let abbreviation: String
    let primaryHex: String
    let secondaryHex: String
    var size: CGFloat = 34

    var body: some View {
        TeamMark(
            abbreviation: abbreviation,
            primaryHex: primaryHex,
            secondaryHex: secondaryHex,
            size: size
        )
    }

    init(
        abbreviation: String,
        primaryHex: String,
        secondaryHex: String = "#FFFFFF",
        size: CGFloat = 34
    ) {
        self.abbreviation = abbreviation
        self.primaryHex = primaryHex
        self.secondaryHex = secondaryHex
        self.size = size
    }

    init(team: Team, size: CGFloat = 34) {
        self.init(
            abbreviation: team.abbreviation,
            primaryHex: team.colors.primaryHex,
            secondaryHex: team.colors.secondaryHex,
            size: size
        )
    }
}
