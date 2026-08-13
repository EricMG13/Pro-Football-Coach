import Foundation

/// Who an inbox item came from. `02` §7's four stakeholder groups, plus the people the week is
/// actually about.
public enum InboxSender: String, Codable, Sendable, CaseIterable {
    case administration
    case boosters
    case fanbase
    case lockerRoom
    case recruit
    case staff
    case press

    /// The stakeholder whose disposition this sender speaks for, when it speaks for one.
    public var stakeholder: CareerStakeholder? {
        switch self {
        case .administration: return .administration
        case .boosters: return .boosters
        case .fanbase: return .fanbase
        case .lockerRoom: return .lockerRoom
        case .recruit, .staff, .press: return nil
        }
    }
}

/// One item in the coach's inbox.
public struct InboxItem: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let sender: InboxSender
    public let arrivedAt: CalendarState
    public let subject: String
    /// The mandatory decision this item is asking about, when it is asking rather than telling.
    public let decisionID: UUID?
    /// Rank, so a bounded inbox drops the least important rather than the oldest.
    public let weight: Int

    public init(id: UUID, sender: InboxSender, arrivedAt: CalendarState, subject: String,
                decisionID: UUID? = nil, weight: Int) {
        self.id = id
        self.sender = sender
        self.arrivedAt = arrivedAt
        self.subject = subject
        self.decisionID = decisionID
        self.weight = weight
    }

    public var requiresAnswer: Bool { decisionID != nil }
}

/// The week's first beat. `02` §2.1, §7, §7.1.
///
/// `02` §7 records §6.0's finding about the previous build — "**zero** inbound events; the game never
/// initiated a conversation" — and makes the inbox the primary channel for everything that puts
/// pressure on a coach. It did not exist: `WorldScheduler.expiringInboundEvents` was an inactive
/// step, `CoachWorldReadModelProvider` said so in a comment, and the only thing in the game that
/// asked the coach anything was `MandatoryDecision`, whose four subjects are all college roster
/// paperwork.
///
/// **Derived, never stored**, for the reason `NewsFeedReadModel` is: `DomainEventPayload` requires
/// presentation text to be computed by read models rather than persisted, so a save carries facts
/// and the wording can change without migrating anybody's league. It also means there is no second
/// decision system to keep in step with the first — an item that *asks* is a `MandatoryDecision`
/// wearing a sender, and answering it is the existing career-session path.
public struct InboxReadModel: Sendable, Equatable {
    /// An inbox is a screen, not a census. `CLAUDE.md` requires every collection that grows across
    /// seasons to state a bound, and this one is rebuilt each week rather than accumulated.
    public static let maximumItems = 24

    public let items: [InboxItem]

    public init(items: [InboxItem]) {
        self.items = Array(items.prefix(InboxReadModel.maximumItems))
    }

    /// Items that will not let the week advance until they are answered.
    public var requiringAnswer: [InboxItem] { items.filter(\.requiresAnswer) }

    public static func build(from state: GameState) -> InboxReadModel {
        var items: [InboxItem] = []

        // 1. What is being asked. These are the items `02` §2.1 means by "at least one item requires
        //    an answer", and they are the pending decisions rather than a parallel set of them.
        for decision in state.pending.mandatoryDecisions {
            items.append(InboxItem(
                id: decision.id,
                sender: sender(for: decision),
                arrivedAt: decision.createdAt,
                subject: subject(for: decision, in: state),
                decisionID: decision.id,
                weight: InboxWeights.decision
            ))
        }

        // 2. What is being told. Stakeholder disposition is the pressure `02` §7 says must arrive
        //    from named people rather than sit on a dashboard, so a group that has moved far enough
        //    from neutral says something about it.
        for (stakeholder, support) in state.careerArc.stakeholderSupport
            .sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            guard let line = disposition(stakeholder, support: support) else { continue }
            items.append(InboxItem(
                // A stable identity for a derived item: the same world in the same week produces
                // the same identifier, so a rebuilt inbox does not reshuffle under a reader.
                id: Self.derivedID(
                    seed: state.league.seed,
                    calendar: state.calendar,
                    ordinal: (CareerStakeholder.allCases.firstIndex(of: stakeholder) ?? 0) + 1
                ),
                sender: InboxSender(rawValue: stakeholder.rawValue) ?? .administration,
                arrivedAt: state.calendar,
                subject: line,
                weight: support < InboxWeights.concernedSupport
                    ? InboxWeights.pressure
                    : InboxWeights.praise
            ))
        }

        // 3. What happened. The press reports the week's heaviest story, which is the same
        //    `historicalWeight` rank the news feed and the archive both use — one definition of
        //    important, used three times rather than three definitions.
        if let story = state.history.recent
            .filter({ $0.occurredAt == state.calendar || $0.occurredAt.week == state.calendar.week })
            .max(by: { $0.payload.historicalWeight < $1.payload.historicalWeight }),
            story.payload.historicalWeight > 0 {
            items.append(InboxItem(
                id: story.id,
                sender: .press,
                arrivedAt: story.occurredAt,
                subject: "The week's story, and what you make of it",
                weight: InboxWeights.press
            ))
        }

        // Heaviest first, then newest, then by identity so a rebuild is byte-identical.
        return InboxReadModel(items: items.sorted { lhs, rhs in
            if lhs.weight != rhs.weight { return lhs.weight > rhs.weight }
            if lhs.arrivedAt != rhs.arrivedAt {
                return lhs.arrivedAt.season == rhs.arrivedAt.season
                    ? lhs.arrivedAt.week > rhs.arrivedAt.week
                    : lhs.arrivedAt.season > rhs.arrivedAt.season
            }
            return lhs.id.uuidString < rhs.id.uuidString
        })
    }

    /// A deterministic identifier for an item nothing persists.
    ///
    /// From the world seed, the week and an ordinal — never `UUID()`, which the engine's ambient
    /// identity scan forbids and which would give the same item a new identity on every rebuild.
    static func derivedID(seed: UInt64, calendar: CalendarState, ordinal: Int) -> UUID {
        var rng = SeededRandom(seed: SeededRandom.derive(
            from: SeededRandom.derive(from: seed, scope: .scheduler,
                                      ordinal: calendar.season * 100 + calendar.week),
            scope: .scheduler,
            ordinal: ordinal
        ))
        return rng.uuid()
    }

    // MARK: - Rendering

    static func sender(for decision: MandatoryDecision) -> InboxSender {
        switch decision.responsibility {
        case .recruiting: return .recruit
        case .portalAndRetention: return .lockerRoom
        case .nilAllocation: return .boosters
        case .redshirts: return .staff
        }
    }

    static func subject(for decision: MandatoryDecision, in state: GameState) -> String {
        let name = state.players[decision.subject.entityID]?.fullName
            ?? state.prospects[decision.subject.entityID]?.fullName
            ?? "A player"
        switch decision.responsibility {
        case .recruiting: return "\(name) is waiting on you"
        case .portalAndRetention: return "\(name) is deciding whether to stay"
        case .nilAllocation: return "What \(name) is worth"
        case .redshirts: return "\(name)'s season, and whether to spend it"
        }
    }

    /// What a stakeholder group says at its current disposition, or nothing when it is content.
    ///
    /// Silence at the middle is deliberate: a channel that speaks every week about nothing is the
    /// dashboard `02` §7 is arguing against, and pressure that is always on is not pressure.
    static func disposition(_ stakeholder: CareerStakeholder, support: Int) -> String? {
        switch stakeholder {
        case .administration:
            if support <= InboxWeights.alarmedSupport { return "The athletic director wants to talk" }
            if support >= InboxWeights.delightedSupport { return "The athletic director is pleased" }
        case .boosters:
            if support <= InboxWeights.alarmedSupport { return "The boosters are asking questions" }
            if support >= InboxWeights.delightedSupport { return "The boosters want to give you more" }
        case .fanbase:
            if support <= InboxWeights.alarmedSupport { return "The fanbase has lost patience" }
            if support >= InboxWeights.delightedSupport { return "The fanbase is behind you" }
        case .lockerRoom:
            if support <= InboxWeights.alarmedSupport { return "The locker room is unsettled" }
            if support >= InboxWeights.delightedSupport { return "The locker room is with you" }
        }
        return nil
    }
}

/// The inbox's ranking constants. Weights rather than an editorial order, so a bounded inbox drops
/// the least important item rather than the oldest one.
public enum InboxWeights {
    public static let decision = 100
    public static let pressure = 60
    public static let press = 30
    public static let praise = 20
    /// Below this a group is unhappy enough to say so; at or above `delightedSupport` it is happy
    /// enough to say that instead.
    public static let concernedSupport = 50
    public static let alarmedSupport = 40
    public static let delightedSupport = 80
}
