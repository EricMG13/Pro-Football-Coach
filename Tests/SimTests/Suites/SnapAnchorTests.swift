import Foundation
import FootballSimCore
import ProFootballCoachUI
import CoachWorldApp

func runSnapAnchorTests() {
    suite("Snap anchors") {
        test("a field point clamps into the coordinate space of 03 section 9.2") {
            expectEqual(FieldPoint(yard: -12, lateral: 4).yard, 0)
            expectEqual(FieldPoint(yard: 180, lateral: -1).yard, 100)
            expectEqual(FieldPoint(yard: 50, lateral: -1).lateral, 0)
            expectEqual(FieldPoint(yard: 50, lateral: 9).lateral, 1)
            expectEqual(FieldPoint(yard: 40, lateral: 0.25).yard, 40)
            expectEqual(FieldPoint(yard: 40, lateral: 0.25).lateral, 0.25)
        }

        test("playback duration constants leave a snap watchable") {
            expect(AnchorRules.minimumPlaybackSeconds > 0,
                   "a zero-length playback is not a playback")
            expect(AnchorRules.maximumPlaybackSeconds > AnchorRules.minimumPlaybackSeconds,
                   "the playback ceiling must sit above its floor")
            expect(AnchorRules.clockToPlaybackRatio > 0 && AnchorRules.clockToPlaybackRatio <= 1,
                   "playback may compress clock time but never stretch it")
        }
    }
}
