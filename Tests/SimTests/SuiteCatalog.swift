import Foundation

/// Release lanes are data so the default harness and CI can enumerate the same gates.
enum ReleaseGateID: String, CaseIterable, Sendable {
    case commitmentCoverage = "CommitmentCoverageTest"
    case contrastByConstruction = "ContrastByConstructionTest"
    case dynamicType = "DynamicTypeContractTest"
    case reduceMotion = "ReduceMotionContractTest"
    case voiceOver = "VoiceOverLabelTest"
    case touchTarget = "TouchTargetTest"
    case determinism = "DeterminismTests"
    case performanceBudget = "PerformanceBudgetTests"
    case twoTierConsistency = "TwoTierConsistencyTests"
    case reachability = "ReachabilityTest"
    case errorSurface = "ErrorSurfaceTest"
    case accessibility = "AccessibilityContractTests"
    case saveOffMainActor = "SaveOffMainActorTest"
    case saveCoalescing = "SaveCoalescingTest"
    case saveWriteBudget = "SaveWriteBudgetTest"
    case saveOpenReadOnly = "SaveOpenIsReadOnlyTest"
    case m1Soak = "M1SoakTests"
    case m2Soak = "M2SoakTests"
    case legal = "LegalTests"
}

struct SuiteCatalog: Sendable {
    struct Runner: Sendable, Equatable {
        let command: String
        let function: String
    }

    struct Entry: Sendable, Equatable {
        let gate: ReleaseGateID
        let lane: String
        let defaultRun: Bool
        let runner: Runner?
    }

    static let entries: [Entry] = ReleaseGateID.allCases.map { gate in
        Entry(
            gate: gate,
            lane: lane(for: gate),
            defaultRun: defaultRun.contains(gate),
            runner: runner(for: gate)
        )
    }

    static let defaultRun: Set<ReleaseGateID> = [
        .commitmentCoverage, .contrastByConstruction, .dynamicType, .reduceMotion,
        .voiceOver, .touchTarget, .determinism, .reachability,
        .errorSurface, .accessibility, .saveOffMainActor, .saveCoalescing,
        .saveOpenReadOnly, .legal
    ]

    static func lane(for gate: ReleaseGateID) -> String {
        switch gate {
        case .commitmentCoverage, .contrastByConstruction, .dynamicType, .reduceMotion,
             .voiceOver, .touchTarget, .reachability, .errorSurface,
             .accessibility: return "accessibility"
        case .determinism: return "determinism"
        case .performanceBudget: return "performance"
        case .twoTierConsistency: return "calibration"
        case .saveOffMainActor, .saveCoalescing, .saveWriteBudget, .saveOpenReadOnly: return "persistence"
        case .m1Soak, .m2Soak: return "soaks"
        case .legal: return "legal"
        }
    }

    static func runner(for gate: ReleaseGateID) -> Runner? {
        switch gate {
        case .commitmentCoverage:
            return Runner(command: "--commitment-coverage", function: "runCommitmentCoverageTest")
        case .contrastByConstruction, .voiceOver, .touchTarget, .reachability, .errorSurface:
            return Runner(command: "--core-contracts", function: "runContractTests")
        case .dynamicType:
            return Runner(command: "--design-contracts", function: "runAccessibilityReflowTests")
        case .reduceMotion:
            return Runner(command: "--reduce-motion", function: "runReduceMotionContractTests")
        case .determinism:
            return Runner(command: "--architecture-only", function: "runArchitectureTests")
        case .performanceBudget:
            return Runner(command: "--performance-budget", function: "runPerformanceBudgetTests")
        case .twoTierConsistency:
            return Runner(command: "--two-tier-consistency", function: "runTwoTierConsistencyTests")
        case .accessibility:
            return Runner(command: "--design-contracts", function: "runAccessibilityReflowTests")
        case .saveOffMainActor, .saveCoalescing, .saveWriteBudget, .saveOpenReadOnly:
            return Runner(command: "--save-document", function: "runSaveDocumentTests")
        case .m1Soak:
            return Runner(command: "--m1-soak", function: "runM1SoakTests")
        case .m2Soak:
            return Runner(command: "--m2-soak", function: "runM2SoakTests")
        case .legal:
            return Runner(command: "--legal-only", function: "runLegalTests")
        }
    }

    static func printCatalog() {
        for entry in entries {
            let runner = entry.runner.map { "\($0.command) → \($0.function)" } ?? "MISSING RUNNER"
            print("\(entry.gate.rawValue)\t\(entry.lane)\t\(entry.defaultRun ? "default" : "release")\t\(runner)")
        }
    }
}

func runCommitmentCoverageTest() {
    suite("Commitment coverage") {
        test("TwoTierConsistencyTests has a dispatched runner") {
            let entry = SuiteCatalog.entries.first {
                $0.gate.rawValue == "TwoTierConsistencyTests"
            }
            expectEqual(
                entry?.runner,
                SuiteCatalog.Runner(
                    command: "--two-tier-consistency",
                    function: "runTwoTierConsistencyTests"
                )
            )
            let main = try? String(
                contentsOf: URL(fileURLWithPath: "Tests/SimTests/main.swift"),
                encoding: .utf8
            )
            expect(
                main?.contains("CommandLine.arguments.contains(\"--two-tier-consistency\")") == true,
                "--two-tier-consistency is not dispatched"
            )
            expect(
                main?.contains("runTwoTierConsistencyTests()") == true,
                "runTwoTierConsistencyTests is not dispatched"
            )
        }

        test("every PRODUCT commitment names a runnable gate") {
            let productURL = URL(fileURLWithPath: "PRODUCT.md")
            guard let product = try? String(contentsOf: productURL, encoding: .utf8) else {
                expect(false, "PRODUCT.md is unavailable")
                return
            }
            let commitments = product.components(separatedBy: "## Unverified product targets")[0]
            let identifiers = commitments
                .split(separator: "\n")
                .flatMap { line -> [String] in
                    guard line.contains("|") else { return [] }
                    let matches = line.split(separator: "`")
                    return stride(from: 1, to: matches.count, by: 2).map { String(matches[$0]) }
                }
            let entries = Dictionary(uniqueKeysWithValues: SuiteCatalog.entries.map { ($0.gate.rawValue, $0) })
            expect(!identifiers.isEmpty, "PRODUCT.md commitment table is empty")
            for identifier in identifiers {
                guard let entry = entries[identifier] else {
                    expect(false, "unregistered commitment test \(identifier)")
                    continue
                }
                guard let runner = entry.runner else {
                    expect(false, "\(identifier) has no runnable command")
                    continue
                }
                let main = try? String(contentsOf: URL(fileURLWithPath: "Tests/SimTests/main.swift"),
                                       encoding: .utf8)
                expect(main?.contains("CommandLine.arguments.contains(\"\(runner.command)\")") == true,
                       "\(identifier) command \(runner.command) is not dispatched")
                expect(main?.contains("\(runner.function)(") == true,
                       "\(identifier) runner \(runner.function) is not dispatched")
            }
        }

        test("every registered gate declares its runner state") {
            expectEqual(SuiteCatalog.entries.count, ReleaseGateID.allCases.count)
            for entry in SuiteCatalog.entries where entry.runner == nil {
                expect(false, "\(entry.gate.rawValue) is registered without a runnable command")
            }
        }

        test("PerformanceBudgetTests has a dispatched runner") {
            expectEqual(
                SuiteCatalog.runner(for: .performanceBudget),
                SuiteCatalog.Runner(
                    command: "--performance-budget",
                    function: "runPerformanceBudgetTests"
                )
            )
        }
    }
}
