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

    private var selectedEntry: TeamTable.Entry { TeamTable.entries[teamIndex] }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                StepIndicator(current: step, total: 4)
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
            .background(Color.pageBackground)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
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
                                            primaryHex: entry.primaryHex
                                        )
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(entry.city) \(entry.name)").font(.headline)
                                            Text(entry.stadium)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if teamIndex == index {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                        }
                                    }
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
                                Text(option.displayName).font(.headline)
                                Text(option.detail).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if background == option {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            }
                        }
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
                VStack(spacing: Layout.small) {
                    TeamBadge(
                        abbreviation: selectedEntry.abbreviation,
                        primaryHex: selectedEntry.primaryHex,
                        size: 64
                    )
                    Text("\(selectedEntry.city) \(selectedEntry.name)")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text("\(selectedEntry.conference.displayName) · \(selectedEntry.division.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .card()

                VStack(spacing: Layout.small) {
                    SummaryRow(label: "Coach", value: coachName)
                    SummaryRow(label: "Age", value: "\(age)")
                    SummaryRow(label: "Background", value: background.displayName)
                    SummaryRow(label: "Playoffs", value: settings.playoffFormat.displayName)
                    SummaryRow(label: "Trades", value: settings.tradeDifficulty.displayName)
                    SummaryRow(label: "Salary cap", value: settings.salaryCapEnabled ? "On" : "Off")
                    SummaryRow(label: "Injuries", value: settings.injuriesEnabled ? "On" : "Off")
                }
                .card()
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

struct StepIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: Layout.small) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? Color.accentColor : Color.secondary.opacity(0.25))
                    .frame(width: index == current ? 26 : 10, height: 6)
                    .animation(.snappy, value: current)
            }
        }
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

/// Circular team mark built from colour and abbreviation — no image assets to ship.
struct TeamBadge: View {
    let abbreviation: String
    let primaryHex: String
    var size: CGFloat = 34

    var body: some View {
        Circle()
            .fill(Color(hex: primaryHex))
            .frame(width: size, height: size)
            .overlay(
                Text(abbreviation)
                    .font(.system(size: size * 0.32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .padding(2)
            )
    }

    init(abbreviation: String, primaryHex: String, size: CGFloat = 34) {
        self.abbreviation = abbreviation
        self.primaryHex = primaryHex
        self.size = size
    }

    init(team: Team, size: CGFloat = 34) {
        self.init(abbreviation: team.abbreviation, primaryHex: team.colors.primaryHex, size: size)
    }
}
