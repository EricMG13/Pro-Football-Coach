import Foundation

// ponytail: hand-rolled harness because neither XCTest nor swift-testing ships with
// Command Line Tools (both live inside Xcode). ~50 lines, real exit codes, zero deps.
// Swap for swift-testing if the project ever builds on a machine with full Xcode.

enum TestKit {
    nonisolated(unsafe) private static var failures: [String] = []
    nonisolated(unsafe) private static var checks = 0
    nonisolated(unsafe) private static var suiteName = ""
    nonisolated(unsafe) private static var currentTest = ""
    nonisolated(unsafe) private static var testsRun = 0
    nonisolated(unsafe) private static var failedTests = Set<String>()

    static func suite(_ name: String, _ body: () -> Void) {
        suiteName = name
        body()
    }

    static func test(_ name: String, _ body: () throws -> Void) {
        currentTest = name
        testsRun += 1
        if ProcessInfo.processInfo.environment["TRACE_TESTS"] != nil {
            FileHandle.standardError.write(Data("→ \(suiteName) › \(name)\n".utf8))
        }
        do {
            try body()
        } catch {
            record("threw \(error)")
        }
    }

    /// Runs an async test body to completion by blocking the calling thread.
    ///
    /// Only safe for work that does NOT require the main actor — it blocks the main thread, so a
    /// `@MainActor` body would deadlock. `SaveQueue` is a plain actor for exactly this reason.
    static func testAsync(_ name: String, _ body: @escaping @Sendable () async throws -> Void) {
        currentTest = name
        testsRun += 1
        let done = DispatchSemaphore(value: 0)
        Task {
            do { try await body() } catch { record("threw \(error)") }
            done.signal()
        }
        done.wait()
    }

    /// Core assertion. Records a failure with suite/test context instead of trapping,
    /// so one bad expectation doesn't hide the rest of the suite.
    static func expect(
        _ condition: Bool,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        checks += 1
        guard !condition else { return }
        let detail = message()
        let location = "\(URL(fileURLWithPath: "\(file)").lastPathComponent):\(line)"
        record(detail.isEmpty ? "expectation failed at \(location)" : "\(detail) [\(location)]")
    }

    static func expectEqual<T: Equatable>(
        _ lhs: T,
        _ rhs: T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let prefix = message()
        expect(
            lhs == rhs,
            "\(prefix.isEmpty ? "" : prefix + ": ")expected \(rhs), got \(lhs)",
            file: file,
            line: line
        )
    }

    /// Numeric closeness check for statistical assertions.
    static func expectClose(
        _ value: Double,
        _ target: Double,
        _ tolerance: Double,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let prefix = message()
        expect(
            abs(value - target) <= tolerance,
            "\(prefix.isEmpty ? "" : prefix + ": ")\(value) not within \(tolerance) of \(target)",
            file: file,
            line: line
        )
    }

    /// Range check used pervasively by the calibration suites.
    static func expectIn(
        _ value: Double,
        _ range: ClosedRange<Double>,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let prefix = message()
        expect(
            range.contains(value),
            "\(prefix.isEmpty ? "" : prefix + ": ")\(value) outside \(range.lowerBound)...\(range.upperBound)",
            file: file,
            line: line
        )
    }

    private static func record(_ detail: String) {
        let label = "\(suiteName) › \(currentTest)"
        failedTests.insert(label)
        failures.append("  ✗ \(label): \(detail)")
    }

    /// Prints the summary and terminates with a conventional exit code.
    static func finish() -> Never {
        print("\n\(testsRun) tests, \(checks) checks")
        if failures.isEmpty {
            print("✅ all passed")
            exit(0)
        }
        print("❌ \(failedTests.count) failing test(s), \(failures.count) failed check(s):")
        for failure in failures.prefix(60) { print(failure) }
        if failures.count > 60 { print("  … \(failures.count - 60) more") }
        exit(1)
    }
}

func suite(_ name: String, _ body: () -> Void) { TestKit.suite(name, body) }
func test(_ name: String, _ body: () throws -> Void) { TestKit.test(name, body) }
func testAsync(_ name: String, _ body: @escaping @Sendable () async throws -> Void) {
    TestKit.testAsync(name, body)
}
func expect(
    _ condition: Bool,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) { TestKit.expect(condition, message(), file: file, line: line) }
func expectEqual<T: Equatable>(
    _ lhs: T,
    _ rhs: T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) { TestKit.expectEqual(lhs, rhs, message(), file: file, line: line) }
func expectClose(
    _ value: Double,
    _ target: Double,
    _ tolerance: Double,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) { TestKit.expectClose(value, target, tolerance, message(), file: file, line: line) }
func expectIn(
    _ value: Double,
    _ range: ClosedRange<Double>,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) { TestKit.expectIn(value, range, message(), file: file, line: line) }
