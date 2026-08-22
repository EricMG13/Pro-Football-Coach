import SwiftUI

/// Registry entry for new-coach identity and first appointment selection.
public struct NewCareerCoachIdentityView: View {
    public let jobs: [StartingJobReadModel]
    public let defaultSeed: UInt64
    public let isWorking: Bool
    public let errorMessage: String?
    public let onStart: (String, String, UInt64, String) -> Void
    public let onSeedChanged: (UInt64) -> Void
    public let onCancel: () -> Void

    public init(jobs: [StartingJobReadModel], defaultSeed: UInt64, isWorking: Bool = false,
                errorMessage: String? = nil,
                onStart: @escaping (String, String, UInt64, String) -> Void,
                onSeedChanged: @escaping (UInt64) -> Void = { _ in },
                onCancel: @escaping () -> Void) {
        self.jobs = jobs
        self.defaultSeed = defaultSeed
        self.isWorking = isWorking
        self.errorMessage = errorMessage
        self.onStart = onStart
        self.onSeedChanged = onSeedChanged
        self.onCancel = onCancel
    }

    public var body: some View {
        // Both arms of the old AX5 branch here were character-for-character identical -- an
        // accessibility-size composition that was never actually decided (S-7, 2026-08-19 review).
        // `content` delegates its whole composition to NewCareerSetupView, which is where AX5 is
        // genuinely handled; collapsed to the one statement both arms already agreed on.
        content.accessibilitySortPriority(100)
    }

    private var content: some View {
        NewCareerSetupView(
            jobs: jobs,
            defaultSeed: defaultSeed,
            isWorking: isWorking,
            errorMessage: errorMessage,
            onStart: onStart,
            onSeedChanged: onSeedChanged,
            onCancel: onCancel
        )
    }
}
