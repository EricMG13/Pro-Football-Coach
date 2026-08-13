import Foundation

/// World-strip facts every office week screen carries. Built once in the provider so seven
/// families cannot drift on team, week, record or the Continue affordance.
public struct CoachWorldFrameContext: Sendable, Equatable {
    public let team: CoachWorldTeamReference
    public let coach: CoachWorldPersonReference
    public let seasonLabel: String
    public let weekLabel: String
    public let recordLabel: String
    public let rankLabel: String?
    public let mandatoryDueCount: Int

    public init(
        team: CoachWorldTeamReference,
        coach: CoachWorldPersonReference,
        seasonLabel: String,
        weekLabel: String,
        recordLabel: String,
        rankLabel: String?,
        mandatoryDueCount: Int
    ) {
        self.team = team
        self.coach = coach
        self.seasonLabel = seasonLabel
        self.weekLabel = weekLabel
        self.recordLabel = recordLabel
        self.rankLabel = rankLabel
        self.mandatoryDueCount = max(0, mandatoryDueCount)
    }

    public var canAdvance: Bool { mandatoryDueCount == 0 }

    public var contextLine: String {
        [coach.name, seasonLabel, weekLabel, recordLabel, rankLabel]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}

public struct CoachWorldAgendaItem: Sendable, Equatable, Identifiable {
    public enum State: Sendable, Equatable {
        case open
        case mandatory
        case complete
        case delegated
    }

    public let stableID: String
    public let title: String
    public let detail: String?
    public let cost: String
    public let state: State
    public var id: String { stableID }

    public init(
        stableID: String,
        title: String,
        detail: String?,
        cost: String,
        state: State
    ) {
        self.stableID = stableID
        self.title = title
        self.detail = detail
        self.cost = cost
        self.state = state
    }

    public var isComplete: Bool { state == .complete }

    var symbolName: String {
        switch state {
        case .open: return "circle"
        case .mandatory: return "exclamationmark.triangle"
        case .complete: return "checkmark.circle.fill"
        case .delegated: return "person.badge.clock"
        }
    }

    func symbolColor(in palette: CoachWorldTokens.Palette) -> CoachWorldTokens.ColorValue {
        switch state {
        case .open: return palette.contentQuiet
        case .mandatory: return palette.stateNegative
        case .complete: return palette.statePositive
        case .delegated: return palette.contentSecondary
        }
    }

    func costColor(in palette: CoachWorldTokens.Palette) -> CoachWorldTokens.ColorValue {
        switch state {
        case .mandatory: return palette.stateNegative
        case .complete: return palette.statePositive
        default: return palette.contentSecondary
        }
    }

    var spoken: String {
        let detailPart = detail.map { ". \($0)" } ?? ""
        return "\(title)\(detailPart). \(cost). \(stateWord)"
    }

    private var stateWord: String {
        switch state {
        case .open: return "Open"
        case .mandatory: return "Mandatory, blocks the week"
        case .complete: return "Done"
        case .delegated: return "Delegated"
        }
    }
}

public struct InboxReadModel: Sendable, Equatable {
    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let frame: CoachWorldFrameContext
    public let commitments: [CoachWorldAgendaItem]
    /// Always empty until an inbound-event system exists. The HQ correspondence field is the
    /// same blank; G-01 pinned it there, and this family inherits that pin rather than inventing
    /// mail.
    public let correspondence: [CoachingHQReadModel.Correspondence]

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        frame: CoachWorldFrameContext,
        commitments: [CoachWorldAgendaItem],
        correspondence: [CoachingHQReadModel.Correspondence]
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.frame = frame
        self.commitments = commitments
        self.correspondence = correspondence
    }
}

public struct OpponentReportReadModel: Sendable, Equatable {
    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let frame: CoachWorldFrameContext
    public let opponent: CoachWorldTeamReference?
    public let venue: CoachWorldVenueReference?
    /// Pass share observed through `observedThroughLabel`. Nil when no snapshot has been recorded
    /// and there is no opponent this week (bye).
    public let passRate: Int?
    public let turnoverRate: Int?
    public let observedThroughLabel: String?
    /// G-02 / G-05: staff interpretation and graded confidence are not engine-owned yet.

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        frame: CoachWorldFrameContext,
        opponent: CoachWorldTeamReference?,
        venue: CoachWorldVenueReference?,
        passRate: Int?,
        turnoverRate: Int?,
        observedThroughLabel: String?
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.frame = frame
        self.opponent = opponent
        self.venue = venue
        self.passRate = passRate
        self.turnoverRate = turnoverRate
        self.observedThroughLabel = observedThroughLabel
    }
}

public enum CoachWorldRunPassChoice: String, Sendable, CaseIterable {
    case runHeavy = "Run"
    case balanced = "Balanced"
    case passHeavy = "Pass"
}

public enum CoachWorldTempoChoice: String, Sendable, CaseIterable {
    case deliberate = "Deliberate"
    case balanced = "Balanced"
    case hurry = "Hurry"
}

public enum CoachWorldPressureChoice: String, Sendable, CaseIterable {
    case contain = "Contain"
    case balanced = "Balanced"
    case attack = "Attack"
}

public struct GamePlanReadModel: Sendable, Equatable {
    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let frame: CoachWorldFrameContext
    public let opponent: CoachWorldTeamReference?
    public let runPass: CoachWorldRunPassChoice?
    public let tempo: CoachWorldTempoChoice?
    public let pressure: CoachWorldPressureChoice?

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        frame: CoachWorldFrameContext,
        opponent: CoachWorldTeamReference?,
        runPass: CoachWorldRunPassChoice?,
        tempo: CoachWorldTempoChoice?,
        pressure: CoachWorldPressureChoice?
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.frame = frame
        self.opponent = opponent
        self.runPass = runPass
        self.tempo = tempo
        self.pressure = pressure
    }

    public var hasRecordedPlan: Bool {
        runPass != nil && tempo != nil && pressure != nil
    }
}

public enum CoachWorldPracticePreset: String, Sendable, CaseIterable {
    case balanced = "Balanced"
    case install = "Install"
    case conditioning = "Condition"
    case recovery = "Recover"
}

public struct PracticePlanReadModel: Sendable, Equatable {
    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let frame: CoachWorldFrameContext
    public let weeklyMinutes: Int
    public let installMinutes: Int
    public let conditioningMinutes: Int
    public let recoveryMinutes: Int
    public let positionFocusMinutes: Int
    public let positionFocusLabel: String?
    public let matchingPreset: CoachWorldPracticePreset?
    public let isRecordedThisWeek: Bool

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        frame: CoachWorldFrameContext,
        weeklyMinutes: Int,
        installMinutes: Int,
        conditioningMinutes: Int,
        recoveryMinutes: Int,
        positionFocusMinutes: Int,
        positionFocusLabel: String?,
        matchingPreset: CoachWorldPracticePreset?,
        isRecordedThisWeek: Bool
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.frame = frame
        self.weeklyMinutes = weeklyMinutes
        self.installMinutes = installMinutes
        self.conditioningMinutes = conditioningMinutes
        self.recoveryMinutes = recoveryMinutes
        self.positionFocusMinutes = positionFocusMinutes
        self.positionFocusLabel = positionFocusLabel
        self.matchingPreset = matchingPreset
        self.isRecordedThisWeek = isRecordedThisWeek
    }

    public var spentMinutes: Int {
        installMinutes + conditioningMinutes + recoveryMinutes + positionFocusMinutes
    }
}

public struct TeamHealthReadModel: Sendable, Equatable {
    public struct PlayerRow: Sendable, Equatable, Identifiable {
        public let stableID: String
        public let person: CoachWorldPersonReference
        public let number: Int
        public let position: String
        public let availability: String
        public let condition: Int
        public let injuryLabel: String?
        public let weeksRemaining: Int?
        public var id: String { stableID }

        public init(
            stableID: String,
            person: CoachWorldPersonReference,
            number: Int,
            position: String,
            availability: String,
            condition: Int,
            injuryLabel: String?,
            weeksRemaining: Int?
        ) {
            self.stableID = stableID
            self.person = person
            self.number = number
            self.position = position
            self.availability = availability
            self.condition = condition
            self.injuryLabel = injuryLabel
            self.weeksRemaining = weeksRemaining
        }
    }

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let frame: CoachWorldFrameContext
    public let rosterCount: Int
    public let availableCount: Int
    public let injuredCount: Int
    public let rows: [PlayerRow]

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        frame: CoachWorldFrameContext,
        rosterCount: Int,
        availableCount: Int,
        injuredCount: Int,
        rows: [PlayerRow]
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.frame = frame
        self.rosterCount = rosterCount
        self.availableCount = availableCount
        self.injuredCount = injuredCount
        self.rows = rows
    }
}

public struct AftermathReadModel: Sendable, Equatable {
    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let frame: CoachWorldFrameContext
    public let opponent: CoachWorldTeamReference?
    public let ourScore: Int?
    public let theirScore: Int?
    public let isHome: Bool?
    public let gameWeekLabel: String?
    public let runPass: CoachWorldRunPassChoice?
    public let tempo: CoachWorldTempoChoice?
    public let pressure: CoachWorldPressureChoice?
    public let opponentPassRate: Int?
    public let opponentTurnoverRate: Int?

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        frame: CoachWorldFrameContext,
        opponent: CoachWorldTeamReference?,
        ourScore: Int?,
        theirScore: Int?,
        isHome: Bool?,
        gameWeekLabel: String?,
        runPass: CoachWorldRunPassChoice?,
        tempo: CoachWorldTempoChoice?,
        pressure: CoachWorldPressureChoice?,
        opponentPassRate: Int?,
        opponentTurnoverRate: Int?
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.frame = frame
        self.opponent = opponent
        self.ourScore = ourScore
        self.theirScore = theirScore
        self.isHome = isHome
        self.gameWeekLabel = gameWeekLabel
        self.runPass = runPass
        self.tempo = tempo
        self.pressure = pressure
        self.opponentPassRate = opponentPassRate
        self.opponentTurnoverRate = opponentTurnoverRate
    }

    public var hasResult: Bool { ourScore != nil && theirScore != nil && opponent != nil }
}

public struct TitleContinueReadModel: Sendable, Equatable {
    public let hasExistingSave: Bool
    public let isStarting: Bool
    public let failure: String?

    public init(hasExistingSave: Bool, isStarting: Bool, failure: String?) {
        self.hasExistingSave = hasExistingSave
        self.isStarting = isStarting
        self.failure = failure
    }
}

#if DEBUG
public extension CoachWorldSampleData {
    static var weekFrame: CoachWorldFrameContext {
        CoachWorldFrameContext(
            team: homeTeam,
            coach: headCoach,
            seasonLabel: "2027 season",
            weekLabel: "Week 9",
            recordLabel: "6-2",
            rankLabel: "#19",
            mandatoryDueCount: 1
        )
    }

    static let inbox = InboxReadModel(
        snapshotID: "sample-inbox",
        provenance: .sample,
        frame: weekFrame,
        commitments: [
            CoachWorldAgendaItem(
                stableID: "sample-inbox-practice",
                title: "Set practice emphasis",
                detail: "The week cannot advance while this is open.",
                cost: "Tue",
                state: .mandatory
            ),
        ],
        correspondence: []
    )

    static let opponentReport = OpponentReportReadModel(
        snapshotID: "sample-film",
        provenance: .sample,
        frame: weekFrame,
        opponent: awayTeam,
        venue: venue,
        passRate: 58,
        turnoverRate: 12,
        observedThroughLabel: "Week 8"
    )

    static let gamePlan = GamePlanReadModel(
        snapshotID: "sample-plan",
        provenance: .sample,
        frame: weekFrame,
        opponent: awayTeam,
        runPass: .runHeavy,
        tempo: .balanced,
        pressure: .attack
    )

    static let practicePlan = PracticePlanReadModel(
        snapshotID: "sample-practice",
        provenance: .sample,
        frame: weekFrame,
        weeklyMinutes: 60,
        installMinutes: 15,
        conditioningMinutes: 15,
        recoveryMinutes: 15,
        positionFocusMinutes: 15,
        positionFocusLabel: nil,
        matchingPreset: .balanced,
        isRecordedThisWeek: true
    )

    static let teamHealth = TeamHealthReadModel(
        snapshotID: "sample-health",
        provenance: .sample,
        frame: weekFrame,
        rosterCount: 85,
        availableCount: 83,
        injuredCount: 2,
        rows: [
            .init(
                stableID: "sample-health-alvarez",
                person: .init(stableID: "sample-alvarez", name: "Tomas Alvarez", role: "OT"),
                number: 72,
                position: "OT",
                availability: "Out 2 week(s)",
                condition: 88,
                injuryLabel: "Ankle",
                weeksRemaining: 2
            ),
            .init(
                stableID: "sample-health-okafor",
                person: .init(stableID: "sample-okafor", name: "Miles Okafor", role: "WR"),
                number: 6,
                position: "WR",
                availability: "Limited",
                condition: 71,
                injuryLabel: "Shoulder",
                weeksRemaining: 1
            ),
        ]
    )

    static let aftermath = AftermathReadModel(
        snapshotID: "sample-aftermath",
        provenance: .sample,
        frame: weekFrame,
        opponent: awayTeam,
        ourScore: 24,
        theirScore: 17,
        isHome: true,
        gameWeekLabel: "Week 8",
        runPass: .runHeavy,
        tempo: .balanced,
        pressure: .contain,
        opponentPassRate: 61,
        opponentTurnoverRate: 18
    )

    static let titleContinue = TitleContinueReadModel(
        hasExistingSave: false,
        isStarting: false,
        failure: nil
    )
}
#endif
