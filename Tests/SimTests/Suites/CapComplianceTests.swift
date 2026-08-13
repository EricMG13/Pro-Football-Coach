import Foundation
import FootballSimCore

func runCapComplianceTests() {
    suite("Cap compliance: event plumbing") {
        test("a compliance release headline names the team and the player") {
            let playerID = UUID(uuidString: "00000000-0000-4000-8000-0000000CA001")!
            let teamID = UUID(uuidString: "00000000-0000-4000-8000-0000000CA002")!
            let payload = DomainEventPayload.proCapComplianceRelease(
                playerID: playerID,
                teamID: teamID,
                deadMoneyAdded: 500
            )
            expectEqual(payload.historicalWeight, 20)
            expectEqual(Set(payload.referencedEntityIDs), Set([playerID, teamID]))
        }
    }
}
