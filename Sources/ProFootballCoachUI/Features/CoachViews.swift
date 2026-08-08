import SwiftUI
import FootballSimCore

/// The coaching career: level, skills, goals, contract, and the save controls.
struct CoachView: View {
    @Environment(AppState.self) private var app
    @Environment(\.teamTheme) private var theme
    @State private var showingSkills = false
    @State private var showingGoals = false
    @State private var confirmingExit = false

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.medium) {
                if let league = app.league {
                    profile(league.coach)
                    progress(league.coach)

                    VStack(spacing: 0) {
                        Button { showingSkills = true } label: {
                            row("Skill Tree", "brain.head.profile", .blue, badge: league.coach.skillPoints > 0 ? "\(league.coach.skillPoints)" : nil)
                        }
                        Divider().padding(.leading, 52)
                        Button { showingGoals = true } label: {
                            row("Season Goals", "target", .green, badge: "\(app.seasonGoals.filter(\.isComplete).count)/\(app.seasonGoals.count)")
                        }
                        Divider().padding(.leading, 52)
                        NavigationLink { HistoryView() } label: {
                            row("Franchise History", "clock.arrow.circlepath", .orange, badge: nil)
                        }
                        Divider().padding(.leading, 52)
                        NavigationLink { RecordsView() } label: {
                            row("Record Book", "list.number", .indigo, badge: nil)
                        }
                        Divider().padding(.leading, 52)
                        NavigationLink { HallOfFameView() } label: {
                            row(
                                "Hall of Fame",
                                "star.circle.fill",
                                .yellow,
                                badge: league.hallOfFame.isEmpty ? nil : "\(league.hallOfFame.count)"
                            )
                        }
                    }
                    .card()

                    contract(league.coach)

                    VStack(spacing: 0) {
                        Toggle("Autosave", isOn: Binding(
                            get: { app.autosaveEnabled },
                            set: { app.autosaveEnabled = $0 }
                        ))
                        .padding(.vertical, Layout.small)
                        Divider()
                        Button { app.persist() } label: {
                            row("Save Franchise", "square.and.arrow.down", .blue, badge: nil)
                        }
                        Divider().padding(.leading, 52)
                        Button(role: .destructive) { confirmingExit = true } label: {
                            row("Back to Main Menu", "arrow.backward.circle", .red, badge: nil)
                        }
                    }
                    .card()
                }
            }
            .padding(Layout.medium)
        }
        .background(Color.pageBackground)
        .navigationTitle("Coach")
        .sheet(isPresented: $showingSkills) { SkillTreeSheet() }
        .sheet(isPresented: $showingGoals) { SeasonGoalsSheet() }
        .alert("Return to the main menu?", isPresented: $confirmingExit) {
            Button("Save and Exit") { app.closeFranchise() }
            Button("Stay", role: .cancel) {}
        } message: {
            Text("Your franchise will be saved first.")
        }
    }

    private func profile(_ coach: CoachProfile) -> some View {
        VStack(spacing: Layout.tight) {
            Image(systemName: "figure.american.football")
                .font(.system(size: 40))
                .foregroundStyle(.white)
            Text(coach.name)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            HStack(spacing: Layout.tight) {
                Chip("Level \(coach.level)", color: .white)
                Chip("Age \(coach.age)", color: .white)
                Chip(coach.background.displayName, color: .white)
            }
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(Layout.large)
        .background(theme.gradient)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
    }

    private func progress(_ coach: CoachProfile) -> some View {
        VStack(alignment: .leading, spacing: Layout.small) {
            HStack {
                Text("Experience").font(.subheadline)
                Spacer()
                Text("\(coach.experience) / \(coach.experienceForNextLevel)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(
                value: Double(coach.experience),
                total: Double(max(1, coach.experienceForNextLevel))
            )
            Divider()
            SummaryRow(label: "Career record", value: coach.recordDescription)
            SummaryRow(label: "Championships", value: "\(coach.championships)")
            SummaryRow(label: "Playoff appearances", value: "\(coach.playoffAppearances)")
        }
        .card()
    }

    private func contract(_ coach: CoachProfile) -> some View {
        VStack(alignment: .leading, spacing: Layout.small) {
            SectionHeader("Contract")
            SummaryRow(label: "Salary", value: "\(Format.money(coach.salary)) per year")
            SummaryRow(label: "Years remaining", value: "\(coach.contractYearsRemaining)")
            SummaryRow(label: "Job security", value: "\(coach.jobSecurity)%")
            ProgressView(value: Double(coach.jobSecurity), total: 100)
                .tint(coach.jobSecurity < 25 ? .red : (coach.jobSecurity < 55 ? .orange : .green))
            if coach.jobSecurity < 25 {
                Text("The owner is losing patience.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .card()
    }

    private func row(_ title: String, _ icon: String, _ tint: Color, badge: String?) -> some View {
        HStack(spacing: Layout.medium) {
            Image(systemName: icon).foregroundStyle(tint).frame(width: 24)
            Text(title).font(.subheadline).foregroundStyle(.primary)
            Spacer()
            if let badge { Chip(badge, color: tint, filled: true) }
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
        .padding(.vertical, Layout.small)
        .contentShape(Rectangle())
    }
}

struct SkillTreeSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var branch: SkillBranch = .offense

    var body: some View {
        NavigationStack {
            VStack(spacing: Layout.medium) {
                if let coach = app.league?.coach {
                    HStack {
                        Chip("\(coach.skillPoints) skill points", color: .blue, filled: true)
                        Spacer()
                        Chip("Level \(coach.level)", color: .orange, filled: true)
                    }
                    .padding(.horizontal, Layout.medium)

                    Picker("", selection: $branch) {
                        ForEach(SkillBranch.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Layout.medium)

                    ScrollView {
                        VStack(spacing: Layout.small) {
                            ForEach(SkillTrees.nodes(for: branch), id: \.index) { node in
                                nodeRow(node, coach: coach)
                            }
                        }
                        .padding(Layout.medium)
                    }
                }
            }
            .background(Color.pageBackground)
            .navigationTitle("Skill Tree")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private func nodeRow(_ node: SkillNode, coach: CoachProfile) -> some View {
        let unlocked = coach.hasUnlocked(branch: node.branch, node: node.index)
        let previousUnlocked = node.index == 0
            || coach.hasUnlocked(branch: node.branch, node: node.index - 1)
        let affordable = coach.skillPoints >= node.cost

        return HStack(spacing: Layout.medium) {
            ZStack {
                Circle()
                    .fill(unlocked ? Color.accentColor : Color.secondary.opacity(0.18))
                    .frame(width: 44, height: 44)
                if unlocked {
                    Image(systemName: "checkmark").foregroundStyle(.white)
                } else {
                    VStack(spacing: 0) {
                        Text("\(node.cost)").font(.subheadline.weight(.bold))
                        Text("SP").font(.system(size: 8))
                    }
                    .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(node.name).font(.subheadline.weight(.medium))
                Text(node.detail).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            if !unlocked {
                Button("Unlock") {
                    app.unlockSkill(branch: node.branch, index: node.index)
                }
                .buttonStyle(.bordered)
                .disabled(!previousUnlocked || !affordable)
            }
        }
        .card()
        .opacity(previousUnlocked ? 1 : 0.55)
    }
}

struct SeasonGoalsSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Layout.small) {
                    if app.seasonGoals.isEmpty {
                        EmptyStateView(
                            icon: "target",
                            title: "No goals set",
                            message: "The owner sets objectives when a season begins."
                        )
                    }
                    ForEach(app.seasonGoals) { goal in
                        VStack(alignment: .leading, spacing: Layout.tight) {
                            HStack {
                                Text(goal.description).font(.subheadline.weight(.medium))
                                Spacer()
                                Chip("\(goal.experienceReward) XP", color: .orange)
                            }
                            ProgressView(value: goal.fraction)
                                .tint(goal.isComplete ? .green : .accentColor)
                            HStack {
                                Text("\(goal.progress) / \(goal.target)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                if goal.isEndOfSeason { Chip("END OF SEASON", color: .blue) }
                                if goal.isComplete { Chip("DONE", color: .green, filled: true) }
                            }
                        }
                        .card()
                    }
                }
                .padding(Layout.medium)
            }
            .background(Color.pageBackground)
            .navigationTitle("Season Goals")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

/// Past seasons, champions and awards.
struct HistoryView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        List {
            if let history = app.league?.history, !history.isEmpty {
                ForEach(history.reversed(), id: \.year) { season in
                    Section(String(season.year)) {
                        if let championID = season.championTeamID,
                           let champion = app.league?.team(id: championID) {
                            HStack {
                                Image(systemName: "trophy.fill").foregroundStyle(.yellow)
                                Text(champion.fullName).font(.subheadline.weight(.medium))
                            }
                        }
                        if let record = season.userRecord {
                            SummaryRow(label: "Your record", value: record.description)
                        }
                        ForEach(season.awards, id: \.kind.rawValue) { award in
                            SummaryRow(label: award.kind.displayName, value: award.playerName)
                        }
                    }
                }
            } else {
                EmptyStateView(
                    icon: "clock.arrow.circlepath",
                    title: "No history yet",
                    message: "Completed seasons are archived here."
                )
            }
        }
        .navigationTitle("History")
    }
}

/// The offseason pipeline, shown as ordered stages on the season tab.
struct OffseasonHubCard: View {
    @Environment(AppState.self) private var app
    @State private var showingDraft = false

    private var currentStage: OffseasonStage? {
        guard case .offseason(let raw) = app.league?.phase else { return nil }
        return OffseasonStage(rawValue: raw)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.small) {
            SectionHeader("Offseason")
            ForEach(OffseasonStage.allCases, id: \.self) { stage in
                let isCurrent = stage == currentStage
                let isDone = (currentStage?.rawValue ?? 0) > stage.rawValue
                HStack(spacing: Layout.small) {
                    Image(systemName: isDone ? "checkmark.circle.fill" : (isCurrent ? "circle.inset.filled" : "circle"))
                        .foregroundStyle(isDone ? .green : (isCurrent ? Color.accentColor : .secondary))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(stage.displayName)
                            .font(.subheadline)
                            .fontWeight(isCurrent ? .bold : .regular)
                        if isCurrent {
                            Text(stage.detail).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
            }

            // The draft and the re-sign window are decisions, not steps to click past, so
            // they open their own screens rather than resolving behind the advance button.
            switch currentStage {
            case .draft:
                Button { showingDraft = true } label: {
                    Label("Enter the Draft Room", systemImage: "person.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            case .reSigning:
                NavigationLink { ReSignView() } label: {
                    Label("Re-Sign Your Players", systemImage: "signature")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                Button {
                    app.advanceOffseasonStage()
                } label: {
                    Label("Done Re-Signing", systemImage: "forward.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            default:
                Button {
                    app.advanceOffseasonStage()
                } label: {
                    Label(
                        currentStage.map { "Run \($0.displayName)" } ?? "Advance",
                        systemImage: "forward.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .card()
        .fullScreenCoverCompat(item: draftBinding) { _ in DraftDayView() }
    }

    /// `fullScreenCover(item:)` needs something Identifiable; a flag is all this needs to carry.
    private var draftBinding: Binding<DraftRoomToken?> {
        Binding(
            get: { showingDraft ? DraftRoomToken() : nil },
            set: { showingDraft = $0 != nil }
        )
    }
}

struct DraftRoomToken: Identifiable {
    let id = UUID()
}
