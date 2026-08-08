import SwiftUI
import FootballSimCore

/// Preset challenges, picked from the main menu.
struct ScenarioPickerView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var chosen: Scenario?
    @State private var teamIndex = 0
    @State private var firstName = ""
    @State private var lastName = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Scenario.all) { scenario in
                        Button { chosen = scenario } label: {
                            VStack(alignment: .leading, spacing: Layout.tight) {
                                HStack {
                                    Text(scenario.name).font(.headline)
                                    Spacer()
                                    if chosen?.id == scenario.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                }
                                Text(scenario.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Label(scenario.objective, systemImage: "target")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            .padding(.vertical, 2)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Choose a challenge")
                }

                if chosen != nil {
                    Section("Your Team") {
                        Picker("Team", selection: $teamIndex) {
                            ForEach(Array(TeamTable.entries.enumerated()), id: \.offset) { index, entry in
                                Text("\(entry.city) \(entry.name)").tag(index)
                            }
                        }
                    }
                    Section("Coach") {
                        TextField("First name", text: $firstName)
                        TextField("Last name", text: $lastName)
                    }
                    Section {
                        Button("Start Scenario") { start() }
                    }
                }
            }
            .navigationTitle("Scenarios")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    private func start() {
        guard let chosen else { return }
        let coach = CoachProfile(
            firstName: firstName.isEmpty ? "Alex" : firstName,
            lastName: lastName.isEmpty ? "Rivers" : lastName,
            age: 42,
            background: .playcaller
        )
        app.startScenario(
            chosen,
            teamIndex: teamIndex,
            coach: coach,
            settings: LeagueSettings()
        )
        dismiss()
    }
}

/// League record book — seeded marks that current players chase down.
struct RecordsView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        List {
            if let league = app.league {
                let records = RecordsBook.current(in: league)
                Section("Single Season") {
                    ForEach(records.filter { !$0.kind.isCareer }) { record in
                        recordRow(record)
                    }
                }
                Section("Career") {
                    ForEach(records.filter(\.kind.isCareer)) { record in
                        recordRow(record)
                    }
                }
            }
        }
        .navigationTitle("Record Book")
    }

    private func recordRow(_ record: LeagueRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.kind.displayName).font(.subheadline)
                Text("\(record.holderName) · \(String(record.year))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(record.value)")
                .font(.headline.monospacedDigit())
        }
    }
}

/// Everyone enshrined since the franchise began.
struct HallOfFameView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        List {
            let members = (app.league?.hallOfFame ?? []).sorted { $0.inductionYear > $1.inductionYear }
            if members.isEmpty {
                EmptyStateView(
                    icon: "star.circle",
                    title: "Nobody enshrined yet",
                    message: "Great careers are honoured when they end. Give it a few seasons."
                )
            } else {
                ForEach(members) { member in
                    HStack(spacing: Layout.medium) {
                        Image(systemName: "star.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(member.name).font(.headline)
                            Text("\(member.position.displayName) · Class of \(String(member.inductionYear))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(member.careerSummary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Hall of Fame")
    }
}
