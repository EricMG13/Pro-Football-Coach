import Foundation

/// Release lanes are data so the default harness and CI can enumerate the same gates.
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
    case m1Soak = "M1SoakTests"
    case m2Soak = "M2SoakTests"
    case legal = "LegalTests"
}

struct SuiteCatalog: Sendable {
    struct Runner: Sendable, Equatable {
        let command: String
        let function: String
    }

    /// A gate is either dispatched today, or explicitly not yet — and if not, the entry says why
    /// and where the spec that will unblock it lives. `docs/qa/feature-coverage.csv` QA-001 states
    /// the rule this exists to satisfy: "execute or explicitly mark unsupported gates; never treat
    /// name registration as implementation." There is no silent third option.
    enum Disposition: Sendable, Equatable {
        case runnable(Runner)
        case unwritten(reason: String, spec: String)
    }

    struct Entry: Sendable, Equatable {
        let gate: ReleaseGateID
        let lane: String
        let defaultRun: Bool
        let disposition: Disposition

        var runner: Runner? {
            if case let .runnable(runner) = disposition { return runner }
            return nil
        }
    }

    static let entries: [Entry] = ReleaseGateID.allCases.map { gate in
        Entry(
            gate: gate,
            lane: lane(for: gate),
            defaultRun: defaultRun.contains(gate),
            disposition: disposition(for: gate)
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
             .voiceOver, .touchTarget, .reachability, .errorSurface, .smallestDeviceLayout,
             .accessibility: return "accessibility"
        case .agencyBudget, .performanceBudget: return "performance"
        case .determinism, .twoTierConsistency: return "determinism"
        case .saveOffMainActor, .saveCoalescing, .saveWriteBudget, .saveOpenReadOnly: return "persistence"
        case .m1Soak, .m2Soak: return "soaks"
        case .legal: return "legal"
        }
    }

    static func disposition(for gate: ReleaseGateID) -> Disposition {
        switch gate {
        case .commitmentCoverage:
            return .runnable(Runner(command: "--commitment-coverage", function: "runCommitmentCoverageTest"))
        case .contrastByConstruction, .voiceOver, .touchTarget, .reachability, .errorSurface:
            return .runnable(Runner(command: "--core-contracts", function: "runContractTests"))
        case .dynamicType:
            return .runnable(Runner(command: "--design-contracts", function: "runAccessibilityReflowTests"))
        case .reduceMotion:
            return .runnable(Runner(command: "--reduce-motion", function: "runReduceMotionContractTests"))
        case .determinism:
            return .runnable(Runner(command: "--architecture-only", function: "runArchitectureTests"))
        case .accessibility:
            return .runnable(Runner(command: "--design-contracts", function: "runAccessibilityReflowTests"))
        case .saveOffMainActor, .saveCoalescing, .saveWriteBudget, .saveOpenReadOnly:
            return .runnable(Runner(command: "--save-document", function: "runSaveDocumentTests"))
        case .agencyBudget:
            return .unwritten(
                reason: "multiplies call-in counts by presentation-time constants that "
                    + "03-MATCH-ENGINE.md section 6's D1 note labels proposals, not measurements — "
                    + "the event-count half is mechanisable today, the minutes half is not",
                spec: "docs/OPEN-DECISIONS.md D1"
            )
        case .performanceBudget:
            return .unwritten(
                reason: "the budget is already known-red on this host (2.83s median week-advance "
                    + "against a 2.0s ceiling, docs/plans/2026-08-12-road-to-beta.md B-4); must "
                    + "assert release-only and needs a device trace, not just a Mac number",
                spec: "docs/OPEN-DECISIONS.md D4"
            )
        case .twoTierConsistency:
            return .unwritten(
                reason: "TOST at alpha=0.05 with stated margins is fully specified, but it compares "
                    + "against P5's abstracted model, which does not exist yet",
                spec: "docs/OPEN-DECISIONS.md D3"
            )
        case .smallestDeviceLayout:
            return .unwritten(
                reason: "no-clipping and full-reachability at a rendered size need a view host; "
                    + "this harness is headless with neither XCTest nor a view host (04 section 7.1) "
                    + "— the same wall as U-4's open rendered limb",
                spec: "docs/OPEN-DECISIONS.md D15/G-09"
            )
        case .m1Soak:
            return .runnable(Runner(command: "--m1-soak", function: "runM1SoakTests"))
        case .m2Soak:
            return .runnable(Runner(command: "--m2-soak", function: "runM2SoakTests"))
        case .legal:
            return .runnable(Runner(command: "--legal-only", function: "runLegalTests"))
        }
    }

    static func printCatalog() {
        for entry in entries {
            let status: String
            switch entry.disposition {
            case let .runnable(runner):
                status = "\(runner.command) → \(runner.function)"
            case let .unwritten(reason, spec):
                status = "UNWRITTEN (\(spec)): \(reason)"
            }
            print("\(entry.gate.rawValue)\t\(entry.lane)\t\(entry.defaultRun ? "default" : "release")\t\(status)")
        }
    }
}

func runCommitmentCoverageTest() {
    suite("Commitment coverage") {
        test("every PRODUCT commitment names a gate with a declared disposition") {
            let productURL = URL(fileURLWithPath: "PRODUCT.md")
            guard let product = try? String(contentsOf: productURL, encoding: .utf8) else {
                expect(false, "PRODUCT.md is unavailable")
                return
            }
            let identifiers = product
                .split(separator: "\n")
                .flatMap { line -> [String] in
                    guard line.contains("|") else { return [] }
                    let matches = line.split(separator: "`")
                    return stride(from: 1, to: matches.count, by: 2).map { String(matches[$0]) }
                }
            let entries = Dictionary(uniqueKeysWithValues: SuiteCatalog.entries.map { ($0.gate.rawValue, $0) })
            expect(!identifiers.isEmpty, "PRODUCT.md commitment table is empty")
            let main = try? String(contentsOf: URL(fileURLWithPath: "Tests/SimTests/main.swift"),
                                   encoding: .utf8)
            for identifier in identifiers {
                guard let entry = entries[identifier] else {
                    expect(false, "unregistered commitment test \(identifier)")
                    continue
                }
                switch entry.disposition {
                case let .runnable(runner):
                    expect(main?.contains("CommandLine.arguments.contains(\"\(runner.command)\")") == true,
                           "\(identifier) command \(runner.command) is not dispatched")
                    expect(main?.contains("\(runner.function)(") == true,
                           "\(identifier) runner \(runner.function) is not dispatched")
                case let .unwritten(reason, spec):
                    // A commitment naming an unwritten gate is not itself a defect -- it is the
                    // QA-001 rule from docs/qa/feature-coverage.csv working as designed: "execute
                    // or explicitly mark unsupported gates." What would be a defect is an unwritten
                    // gate with no stated reason or no citation back to the spec that unblocks it.
                    expect(!reason.isEmpty, "\(identifier) is unwritten with no stated reason")
                    expect(!spec.isEmpty, "\(identifier) is unwritten with no cited spec")
                }
            }
        }

        test("every registered gate declares its runner state") {
            expectEqual(SuiteCatalog.entries.count, ReleaseGateID.allCases.count)
            var runnableCount = 0
            for entry in SuiteCatalog.entries {
                switch entry.disposition {
                case .runnable:
                    runnableCount += 1
                case let .unwritten(reason, spec):
                    expect(!reason.isEmpty, "\(entry.gate.rawValue) is unwritten with no stated reason")
                    expect(!spec.isEmpty, "\(entry.gate.rawValue) is unwritten with no cited spec")
                }
            }
            print("Gate disposition: \(runnableCount) runnable, "
                + "\(SuiteCatalog.entries.count - runnableCount) unwritten")
            // Named rather than counted, so a fifth gate silently going unwritten is caught
            // immediately, and closing one of these four requires deleting it from this list --
            // an intentional edit, not an incidental pass. Same shape as AccessibilityReflowTests'
            // "the convention keeps the draft room family landed".
            let expectedUnwritten: Set<ReleaseGateID> = [
                .agencyBudget, .performanceBudget, .twoTierConsistency, .smallestDeviceLayout
            ]
            let actualUnwritten = Set(SuiteCatalog.entries.compactMap { entry -> ReleaseGateID? in
                if case .unwritten = entry.disposition { return entry.gate }
                return nil
            })
            expectEqual(actualUnwritten, expectedUnwritten,
                        "the unwritten gate set changed -- update this list deliberately")
        }
    }
}
