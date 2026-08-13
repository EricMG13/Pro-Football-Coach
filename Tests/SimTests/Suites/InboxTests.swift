import Foundation
import FootballSimCore

func runInboxTests() {
    suite("The inbox") {
        test("the game initiates a conversation") {
            // 02 section 7 records the previous build's failure verbatim: zero inbound events, the
            // game never initiated a conversation. The inbox did not exist here either — the
            // scheduler's expiringInboundEvents step is inactive and a comment in the read-model
            // provider says why.
            let source = GameState.bootstrap(seed: 89_001)
            var state = try CareerControlSystem.startCollegeCareer(
                at: source.programmes.ids[0],
                in: source
            ).state
            state = CareerMandatoryDecisionSystem.refresh(in: state)

            let inbox = InboxReadModel.build(from: state)
            expect(!inbox.items.isEmpty, "the inbox was empty in the first week of a career")
            expect(inbox.items.count <= InboxReadModel.maximumItems,
                   "the inbox is unbounded")
        }

        test("an item that asks is a decision, not a second decision system") {
            let source = GameState.bootstrap(seed: 89_002)
            var state = try CareerControlSystem.startCollegeCareer(
                at: source.programmes.ids[0],
                in: source
            ).state
            state = CareerMandatoryDecisionSystem.refresh(in: state)
            let inbox = InboxReadModel.build(from: state)

            let pending = Set(state.pending.mandatoryDecisions.map(\.id))
            for item in inbox.requiringAnswer {
                expect(item.decisionID != nil, "an item that asks named no decision")
                expect(pending.contains(item.decisionID!),
                       "an inbox item asked about a decision the world does not have")
            }
            expectEqual(inbox.requiringAnswer.count,
                        min(pending.count, InboxReadModel.maximumItems),
                        "the inbox and the pending decisions disagree about what is outstanding")
        }

        test("a contented world is quiet") {
            // Pressure that is always on is not pressure, and a channel that speaks every week about
            // nothing is the dashboard 02 section 7 argues against.
            for support in [InboxWeights.concernedSupport, InboxWeights.concernedSupport + 10] {
                for stakeholder in CareerStakeholder.allCases {
                    expect(InboxReadModel.disposition(stakeholder, support: support) == nil,
                           "\(stakeholder.rawValue) spoke at a contented \(support)")
                }
            }
            for stakeholder in CareerStakeholder.allCases {
                expect(InboxReadModel.disposition(stakeholder,
                                                  support: InboxWeights.alarmedSupport) != nil,
                       "\(stakeholder.rawValue) said nothing while alarmed")
                expect(InboxReadModel.disposition(stakeholder,
                                                  support: InboxWeights.delightedSupport) != nil,
                       "\(stakeholder.rawValue) said nothing while delighted")
            }
        }

        test("the heaviest item leads") {
            let source = GameState.bootstrap(seed: 89_003)
            var state = try CareerControlSystem.startCollegeCareer(
                at: source.programmes.ids[0],
                in: source
            ).state
            state = CareerMandatoryDecisionSystem.refresh(in: state)
            let items = InboxReadModel.build(from: state).items
            for index in 1..<max(1, items.count) {
                expect(items[index - 1].weight >= items[index].weight,
                       "the inbox is not ordered by weight")
            }
            if let first = items.first, !state.pending.mandatoryDecisions.isEmpty {
                expect(first.requiresAnswer,
                       "something outranked the decision the week is waiting on")
            }
        }

        test("a rebuild is identical, including the identities it derives") {
            // Derived items still need stable identity, or a reader watching the inbox would see it
            // reshuffle under them every week the world was rebuilt.
            let source = GameState.bootstrap(seed: 89_004)
            var state = try CareerControlSystem.startCollegeCareer(
                at: source.programmes.ids[0],
                in: source
            ).state
            state = CareerMandatoryDecisionSystem.refresh(in: state)
            let first = InboxReadModel.build(from: state)
            let second = InboxReadModel.build(from: state)
            expectEqual(first.items.map(\.id), second.items.map(\.id),
                        "two builds of one world produced different item identities")
            expectEqual(first, second, "the inbox is not a function of the world")
        }
    }
}
