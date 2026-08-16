import SwiftUI

public struct NewCareerSetupView: View {
    public let jobs: [StartingJobReadModel]
    public let defaultSeed: UInt64
    public let isWorking: Bool
    public let errorMessage: String?
    public let onStart: (String, String, UInt64, String) -> Void
    public let onSeedChanged: (UInt64) -> Void
    public let onCancel: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var firstName = "Alex"
    @State private var lastName = "Coach"
    @State private var seedText: String
    @State private var jobsSeed: UInt64
    @State private var selectedJobID: String

    public init(
        jobs: [StartingJobReadModel],
        defaultSeed: UInt64,
        isWorking: Bool = false,
        errorMessage: String? = nil,
        onStart: @escaping (String, String, UInt64, String) -> Void,
        onSeedChanged: @escaping (UInt64) -> Void = { _ in },
        onCancel: @escaping () -> Void
    ) {
        self.jobs = jobs
        self.defaultSeed = defaultSeed
        self.isWorking = isWorking
        self.errorMessage = errorMessage
        self.onStart = onStart
        self.onSeedChanged = onSeedChanged
        self.onCancel = onCancel
        _seedText = State(initialValue: String(defaultSeed))
        _jobsSeed = State(initialValue: defaultSeed)
        _selectedJobID = State(initialValue: jobs.first?.stableID ?? "")
    }

    public var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView { accessibleLayout }
            } else {
                standardLayout
            }
        }
        .foregroundStyle(palette.contentPrimary.color)
        .background(palette.page.color.ignoresSafeArea())
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    private var standardLayout: some View {
        HStack(alignment: .top, spacing: CoachWorldTokens.Space.md) {
            identityPanel
                .frame(maxWidth: 320)
            jobPanel
        }
        .padding(CoachWorldTokens.Space.lg)
    }

    private var accessibleLayout: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
            identityPanel
            jobPanel
        }
        .padding(CoachWorldTokens.Space.md)
    }

    private var identityPanel: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
            Text("New career")
                .font(CoachWorldTokens.TypeRole.display.weight(.black))
            Text("Create a coach identity and choose the first appointment.")
                .font(CoachWorldTokens.TypeRole.body)
                .fixedSize(horizontal: false, vertical: true)

            TextField("First name", text: $firstName)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Coach first name")
            TextField("Last name", text: $lastName)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Coach last name")
            TextField("World seed", text: $seedText, onCommit: refreshJobsForSeed)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("World seed")
            if UInt64(seedText) != jobsSeed {
                Text("Press return to refresh the starting jobs for this seed.")
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.stateNegative.color)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: CoachWorldTokens.Space.sm) {
                Button("Cancel", action: onCancel)
                    .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
                    .disabled(isWorking)
                Button("Start career") { submit() }
                    .buttonStyle(CoachWorldActionButtonStyle(role: .primary, palette: palette))
                    .disabled(!canSubmit || isWorking)
            }
        }
        .padding(CoachWorldTokens.Space.md)
        .coachWorldDeskSurface(
            fill: palette.work.color,
            border: palette.contentQuiet.color.opacity(0.38)
        )
        .accessibilityElement(children: .contain)
        .accessibilitySortPriority(300)
    }

    private var jobPanel: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
            Text("Starting jobs")
                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
            Text("Three generated openings. Expectations and resources come from the selected programme.")
                .font(CoachWorldTokens.TypeRole.caption)
                .fixedSize(horizontal: false, vertical: true)

            if jobs.isEmpty {
                Text("No eligible starting jobs were generated.")
                    .font(CoachWorldTokens.TypeRole.body)
            } else {
                ForEach(jobs) { job in
                    jobRow(job)
                }
            }
        }
        .padding(CoachWorldTokens.Space.md)
        .coachWorldDeskSurface(
            fill: palette.raised.color,
            border: palette.contentQuiet.color.opacity(0.38)
        )
        .accessibilitySortPriority(200)
    }

    private func jobRow(_ job: StartingJobReadModel) -> some View {
        Button {
            selectedJobID = job.stableID
        } label: {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                HStack {
                    Text(job.programme.name)
                        .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                    Spacer(minLength: CoachWorldTokens.Space.xs)
                    Text(job.cityName)
                        .font(CoachWorldTokens.TypeRole.caption)
                }
                Text("Prestige \(job.prestige) · Resources \(job.resources) · \(job.expectation)")
                    .font(CoachWorldTokens.TypeRole.caption)
                    .fixedSize(horizontal: false, vertical: true)
                Text(job.archetype)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(CoachWorldTokens.Space.sm)
            .background(
                selectedJobID == job.stableID
                    ? palette.collegeIdentity.color.opacity(0.16)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius)
            )
        }
        .buttonStyle(.plain)
        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        .disabled(isWorking)
        .accessibilityLabel("\(job.programme.name), \(job.cityName)")
        .accessibilityValue(
            selectedJobID == job.stableID
                ? "Selected. Prestige \(job.prestige). Resources \(job.resources). \(job.expectation)."
                : "Prestige \(job.prestige). Resources \(job.resources). \(job.expectation)."
        )
        .accessibilityAddTraits(selectedJobID == job.stableID ? .isSelected : [])
    }

    private var canSubmit: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && UInt64(seedText) != nil
            && UInt64(seedText) == jobsSeed
            && jobs.contains { $0.stableID == selectedJobID }
    }

    private func submit() {
        guard canSubmit, let seed = UInt64(seedText) else { return }
        onStart(firstName, lastName, seed, selectedJobID)
    }

    private func refreshJobsForSeed() {
        guard let seed = UInt64(seedText) else { return }
        jobsSeed = seed
        onSeedChanged(seed)
    }
}
