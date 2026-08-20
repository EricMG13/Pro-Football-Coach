import Foundation
import FootballSimCore
import ProFootballCoachUI

public extension CoachWorldReadModelProvider {
    /// Projects current decisions and typed current-week history. It never invents a sender or
    /// reply: action rows route back to the authoritative decision surface, while ledger stories
    /// are explicitly read-only.
    static func inbox(
        from state: GameState,
        readInboxItemIDs: Set<String> = []
    ) -> InboxReadModel? {
        guard let hq = coachingHQ(from: state),
              let organisationID = UUID(uuidString: hq.team.stableID) else { return nil }

        let rosterIDs = Set(roster(from: state)?.players.compactMap { UUID(uuidString: $0.stableID) } ?? [])
        let decisions = state.pending.mandatoryDecisions
            .filter { $0.programmeID == organisationID }
            .sorted { lhs, rhs in
                if lhs.deadline != rhs.deadline { return calendarOrder(lhs.deadline, rhs.deadline) }
                return lhs.id.uuidString < rhs.id.uuidString
            }

        var items: [InboxReadModel.Item] = decisions.map { decision in
            let stableID = "decision:" + decision.id.uuidString
            let subject = subjectLabel(decision.subject, in: state)
            // The reason codes are engine spelling -- `playingTime`, `eligibility`. A coach reads
            // the sentence, so they print through the same label map the rest of the application
            // uses rather than leaking the raw case name into copy.
            let reasons = decision.reasons.prefix(2).map {
                "\(CoachWorldReadModelProvider.label($0.code)) \($0.value)"
            }
            let body = reasons.isEmpty
                ? "A response is required before the listed deadline."
                : "What is on the desk: " + reasons.joined(separator: " · ")
            return InboxReadModel.Item(
                stableID: stableID,
                kind: .decision,
                sourceLabel: "Decision desk",
                title: subject,
                body: body,
                received: "Received " + weekLabel(decision.createdAt),
                deadline: "Due " + weekLabel(decision.deadline),
                isUnread: !readInboxItemIDs.contains(stableID),
                destination: .coachingHQ
            )
        }

        let missingPreparation = state.tactical.missingPreparation(
            for: organisationID,
            at: state.calendar
        )
        items.append(contentsOf: missingPreparation.map { requirement in
            let title: String
            let destination: CoachWorldScreenID
            switch requirement {
            case .gamePlan:
                title = "Game plan required"
                destination = .gamePlan
            case .practicePlan:
                title = "Practice plan required"
                destination = .practicePlan
            }
            let stableID = "task:" + requirement.rawValue + "-" + String(state.calendar.season)
                + "-" + String(state.calendar.week)
            return InboxReadModel.Item(
                stableID: stableID,
                kind: .task,
                sourceLabel: "Weekly preparation",
                title: title,
                body: "Commit the current-week plan before the controlled fixture can continue.",
                received: "Week " + String(state.calendar.week),
                deadline: "Before the next game",
                isUnread: !readInboxItemIDs.contains(stableID),
                destination: destination
            )
        })

        let news = NewsFeedReadModel.build(from: state)
        let eventsByID = Dictionary(uniqueKeysWithValues: state.history.recent.map { ($0.id, $0) })
        let controlledEntityIDs = rosterIDs.union([organisationID])
        let stories = news.items.compactMap { story -> InboxReadModel.Item? in
            guard let event = eventsByID[story.eventID],
                  event.occurredAt == state.calendar,
                  !event.payload.referencedEntityIDs.filter({ controlledEntityIDs.contains($0) }).isEmpty else {
                return nil
            }
            let stableID = "story:" + story.eventID.uuidString
            return InboxReadModel.Item(
                stableID: stableID,
                kind: .story,
                sourceLabel: "World history",
                title: story.headline,
                body: "Typed event " + String(event.sequence) + " from the simulation ledger.",
                received: "Week " + String(event.occurredAt.week),
                deadline: nil,
                isUnread: !readInboxItemIDs.contains(stableID),
                destination: nil
            )
        }
        items.append(contentsOf: stories)
        return InboxReadModel(
            snapshotID: "inbox-" + organisationID.uuidString + "-"
                + String(state.calendar.season) + "-" + String(state.calendar.week),
            provenance: .simulationSnapshot,
            world: hq.world,
            team: hq.team,
            coach: hq.coach,
            weekLabel: hq.week.weekLabel,
            items: items,
            canContinue: hq.decision == nil && hq.weekPlan.allSatisfy { !$0.isCurrent },
            continueReason: hq.decision == nil && hq.weekPlan.allSatisfy { !$0.isCurrent }
                ? nil
                : "Resolve the current weekly obligation before continuing."
        )
    }

    private static func subjectLabel(_ subject: MandatoryDecisionSubject, in state: GameState) -> String {
        let entityName: String
        switch subject {
        case let .recruiting(prospectID):
            entityName = state.prospects[prospectID].map { "\($0.firstName) \($0.lastName)" } ?? "prospect"
        case let .portalRetention(playerID, _), let .redshirt(playerID), let .nilAllocation(playerID):
            entityName = state.players[playerID]?.fullName ?? "player"
        }
        switch subject {
        case .recruiting: return "Recruiting decision · " + entityName
        case .portalRetention: return "Portal retention · " + entityName
        case .redshirt: return "Redshirt decision · " + entityName
        case .nilAllocation: return "NIL allocation · " + entityName
        }
    }
}
