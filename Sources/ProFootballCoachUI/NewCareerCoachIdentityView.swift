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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
        if dynamicTypeSize.isAccessibilitySize {
            content.accessibilitySortPriority(100)
        } else {
            content.accessibilitySortPriority(100)
        }
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
