import XCTest
import CoachWorldApp
import ProFootballCoachUI

final class ProFootballCoachTests: XCTestCase {
    func testRootCanBeConstructed() {
        _ = CoachWorldAppRootView()
        XCTAssertTrue(true)
    }

    func testDebugRootCanBeConstructed() {
        // `body` is a lazily evaluated computed property; touching it (not just `init()`) is what
        // exercises the DEBUG/non-DEBUG branch this file's dark-commitment guardrail lives in.
        _ = RootView().body
        XCTAssertTrue(true)
    }
}
