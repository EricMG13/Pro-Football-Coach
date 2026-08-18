import Foundation

/// Release lanes are data so the default harness and CI can enumerate the same gates.
///
/// **Not every case below has a runner behind it.** `.reduceMotion` does, as of
/// `ReduceMotionContractTests.swift`, and that file's own dispatch test proves it — not just that
/// the name is registered, which is all `runCommitmentCoverageTest` below ever checked. Whether the
/// same is true of the other thirteen `defaultRun` cases is not audited here: several read as
/// tangential mentions inside `ContractTests.swift` and `AccessibilityReflowTests.swift` rather than
/// a dedicated runner, and classifying which is which needs a case-by-case read this file does not
/// attempt. Stated rather than mechanised, so a reader does not mistake this comment's presence for
/// that audit having happened.
enum ReleaseGateID: String, CaseIterable, Sendable {
    case commitmentCoverage = "CommitmentCoverageTest"
    case contrastByConstruction = "ContrastByConstructionTest"
    case dynamicType = "DynamicTypeContractTest"
    case reduceMotion = "ReduceMotionContractTest"
    case voiceOver = "VoiceOverLabelTest"
    case touchTarget = "TouchTargetTest"
    case agencyBudget = "AgencyBudgetTests"
    case performanceBudget = "PerformanceBudgetTests"
    case determinism = "DeterminismTests"
    case twoTierConsistency = "TwoTierConsistencyTests"
    case reachability = "ReachabilityTest"
    case errorSurface = "ErrorSurfaceTest"
    case smallestDeviceLayout = "SmallestDeviceLayoutTest"
    case accessibility = "AccessibilityContractTests"
    case saveOffMainActor = "SaveOffMainActorTest"
    case saveCoalescing = "SaveCoalescingTest"
    case saveWriteBudget = "SaveWriteBudgetTest"
    case saveOpenReadOnly = "SaveOpenIsReadOnlyTest"
}

struct SuiteCatalog: Sendable {
    struct Entry: Sendable, Equatable {
        let gate: ReleaseGateID
        let lane: String
        let defaultRun: Bool
    }

    static let entries: [Entry] = ReleaseGateID.allCases.map { gate in
        Entry(gate: gate, lane: lane(for: gate), defaultRun: defaultRun.contains(gate))
    }

    static let defaultRun: Set<ReleaseGateID> = [
        .commitmentCoverage, .contrastByConstruction, .dynamicType, .reduceMotion,
        .voiceOver, .touchTarget, .determinism, .twoTierConsistency, .reachability,
        .errorSurface, .accessibility, .saveOffMainActor, .saveCoalescing,
        .saveOpenReadOnly
    ]

    static func lane(for gate: ReleaseGateID) -> String {
        switch gate {
        case .commitmentCoverage, .contrastByConstruction, .dynamicType, .reduceMotion,
             .voiceOver, .touchTarget, .reachability, .errorSurface, .smallestDeviceLayout,
             .accessibility: return "accessibility"
        case .agencyBudget, .performanceBudget: return "performance"
        case .determinism, .twoTierConsistency: return "determinism"
        case .saveOffMainActor, .saveCoalescing, .saveWriteBudget, .saveOpenReadOnly: return "persistence"
        }
    }

    static func printCatalog() {
        for entry in entries {
            print("\(entry.gate.rawValue)\t\(entry.lane)\t\(entry.defaultRun ? "default" : "release")")
        }
    }
}

func runCommitmentCoverageTest() {
    suite("Commitment coverage") {
        test("every PRODUCT commitment names a registered gate") {
            let productURL = URL(fileURLWithPath: "PRODUCT.md")
            guard let product = try? String(contentsOf: productURL, encoding: .utf8) else {
                expect(false, "PRODUCT.md is unavailable")
                return
            }
            let identifiers = product
                .split(separator: "\n")
                .compactMap { line -> String? in
                    guard line.contains("|") else { return nil }
                    let matches = line.split(separator: "`")
                    return matches.count >= 2 ? String(matches[1]) : nil
                }
            let registered = Set(ReleaseGateID.allCases.map(\.rawValue))
            expect(!identifiers.isEmpty, "PRODUCT.md commitment table is empty")
            for identifier in identifiers {
                expect(registered.contains(identifier), "unregistered commitment test \(identifier)")
            }
        }
    }
}
