import SwiftUI
import CoachWorldApp
import ProFootballCoachUI

@main
struct ProFootballCoachApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.environment["PROOF_SCREEN"] != nil {
                RootView()
            } else {
                CoachWorldAppRootView()
            }
            #else
            CoachWorldAppRootView()
            #endif
        }
    }
}
