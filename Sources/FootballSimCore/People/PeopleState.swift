import Foundation

public enum PlayerLifecycleStatus: String, Codable, Sendable, CaseIterable, Hashable {
    case active
    case graduated
    case retired
}

public enum InjuryArea: String, Codable, Sendable, CaseIterable, Hashable {
    case head
    case shoulder
    case arm
    case torso
    case knee
    case ankle
    case foot
}

public enum InjurySeverity: String, Codable, Sendable, CaseIterable, Hashable {
    case minor
    case moderate
    case severe
}

public struct PlayerInjury: Codable, Sendable, Equatable {
    public let area: InjuryArea
    public let severity: InjurySeverity
    public let occurredAt: CalendarState
    public let originalWeeks: Int
    public private(set) var weeksRemaining: Int

    public init(
        area: InjuryArea,
        severity: InjurySeverity,
        occurredAt: CalendarState,
        originalWeeks: Int,
        weeksRemaining: Int
    ) {
        self.area = area
        self.severity = severity
        self.occurredAt = occurredAt
        self.originalWeeks = min(max(1, originalWeeks), PeopleRules.maximumInjuryWeeks)
        self.weeksRemaining = min(max(0, weeksRemaining), self.originalWeeks)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedOriginalWeeks = try container.decode(Int.self, forKey: .originalWeeks)
        let decodedWeeksRemaining = try container.decode(Int.self, forKey: .weeksRemaining)
        guard (1...PeopleRules.maximumInjuryWeeks).contains(decodedOriginalWeeks),
              (0...decodedOriginalWeeks).contains(decodedWeeksRemaining) else {
            throw DecodingError.dataCorruptedError(
                forKey: .weeksRemaining,
                in: container,
                debugDescription: "Injury duration is outside its legal bounds."
            )
        }
        self.init(
            area: try container.decode(InjuryArea.self, forKey: .area),
            severity: try container.decode(InjurySeverity.self, forKey: .severity),
            occurredAt: try container.decode(CalendarState.self, forKey: .occurredAt),
            originalWeeks: decodedOriginalWeeks,
            weeksRemaining: decodedWeeksRemaining
        )
    }

    public mutating func recoverWeek() {
        weeksRemaining = max(0, weeksRemaining - 1)
    }

    public var isRecovered: Bool { weeksRemaining == 0 }
}

/// Why a player is in trouble. `02` §5.2.
///
/// Four kinds rather than a free-text reason, because the reason decides what a suspension is worth
/// and a string cannot be reasoned about. Nothing here is a crime: this is a football team's own
/// discipline, which is the only kind a coach actually administers.
public enum DisciplineIncidentKind: String, Codable, Sendable, CaseIterable, Hashable {
    /// Missed meetings, late to treatment, the small stuff that is a pattern rather than an event.
    case timekeeping
    /// A flag for conduct in a game, or an argument on the sideline.
    case conduct
    /// A team rule, broken knowingly.
    case teamRules
    /// Something away from the building that the programme has to answer for.
    case offField
}

extension DisciplineIncidentKind: CodingKeyRepresentable {}

/// Time a player is serving. `02` §5.2.
///
/// Shaped like `PlayerInjury` on purpose: it counts down on the same weekly tick, it makes the same
/// `isAvailable` false, and every surface that already handles a missing player therefore handles
/// this one without being taught to. A second, differently-shaped absence would be a second thing
/// for every depth chart and match to get wrong.
public struct PlayerSuspension: Codable, Sendable, Equatable {
    public let reason: DisciplineIncidentKind
    public let occurredAt: CalendarState
    public let originalWeeks: Int
    public private(set) var weeksRemaining: Int

    public init(
        reason: DisciplineIncidentKind,
        occurredAt: CalendarState,
        originalWeeks: Int,
        weeksRemaining: Int
    ) {
        self.reason = reason
        self.occurredAt = occurredAt
        self.originalWeeks = min(max(1, originalWeeks), PeopleRules.maximumSuspensionWeeks)
        self.weeksRemaining = min(max(0, weeksRemaining), self.originalWeeks)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedOriginalWeeks = try container.decode(Int.self, forKey: .originalWeeks)
        let decodedWeeksRemaining = try container.decode(Int.self, forKey: .weeksRemaining)
        guard (1...PeopleRules.maximumSuspensionWeeks).contains(decodedOriginalWeeks),
              (0...decodedOriginalWeeks).contains(decodedWeeksRemaining) else {
            throw DecodingError.dataCorruptedError(
                forKey: .weeksRemaining,
                in: container,
                debugDescription: "Suspension duration is outside its legal bounds."
            )
        }
        self.init(
            reason: try container.decode(DisciplineIncidentKind.self, forKey: .reason),
            occurredAt: try container.decode(CalendarState.self, forKey: .occurredAt),
            originalWeeks: decodedOriginalWeeks,
            weeksRemaining: decodedWeeksRemaining
        )
    }

    public mutating func serveWeek() {
        weeksRemaining = max(0, weeksRemaining - 1)
    }

    public var isServed: Bool { weeksRemaining == 0 }
}

public enum DevelopmentReason: String, Codable, Sendable, CaseIterable, Hashable {
    case ageCurve
    case practice
    case playingTime
    case coaching
    case schemeFit
    case workEthic
    case decline
    case injuryRecovery
}

public struct DevelopmentComponent: Codable, Sendable, Equatable {
    public let reason: DevelopmentReason
    public let value: Int

    public init(reason: DevelopmentReason, value: Int) {
        self.reason = reason
        self.value = value
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedValue = try container.decode(Int.self, forKey: .value)
        guard PeopleRules.developmentComponentRange.contains(decodedValue) else {
            throw DecodingError.dataCorruptedError(
                forKey: .value,
                in: container,
                debugDescription: "Development component is outside its legal range."
            )
        }
        reason = try container.decode(DevelopmentReason.self, forKey: .reason)
        value = decodedValue
    }
}

public struct AttributeDevelopment: Codable, Sendable, Equatable {
    public let attribute: Attribute
    public let delta: Int

    public init(attribute: Attribute, delta: Int) {
        self.attribute = attribute
        self.delta = delta
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedDelta = try container.decode(Int.self, forKey: .delta)
        guard PeopleRules.attributeDevelopmentRange.contains(decodedDelta),
              decodedDelta != 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .delta,
                in: container,
                debugDescription: "Attribute development delta is outside its legal range."
            )
        }
        attribute = try container.decode(Attribute.self, forKey: .attribute)
        delta = decodedDelta
    }
}

/// One applied attribute delta with a dated cause for the Player Profile history.
public struct AttributeChangeRecord: Codable, Sendable, Equatable {
    public let occurredAt: CalendarState
    public let attribute: Attribute
    public let delta: Int
    public let cause: DevelopmentReason

    public init(occurredAt: CalendarState, attribute: Attribute, delta: Int, cause: DevelopmentReason) {
        self.occurredAt = occurredAt
        self.attribute = attribute
        self.delta = delta
        self.cause = cause
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let delta = try container.decode(Int.self, forKey: .delta)
        guard PeopleRules.attributeDevelopmentRange.contains(delta), delta != 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .delta,
                in: container,
                debugDescription: "Attribute change is outside its legal range."
            )
        }
        self.init(
            occurredAt: try container.decode(CalendarState.self, forKey: .occurredAt),
            attribute: try container.decode(Attribute.self, forKey: .attribute),
            delta: delta,
            cause: try container.decode(DevelopmentReason.self, forKey: .cause)
        )
    }
}

public struct DevelopmentSummary: Codable, Sendable, Equatable {
    public let occurredAt: CalendarState
    public let components: [DevelopmentComponent]
    public let attributeChanges: [AttributeDevelopment]

    public init(
        occurredAt: CalendarState,
        components: [DevelopmentComponent],
        attributeChanges: [AttributeDevelopment]
    ) {
        self.occurredAt = occurredAt
        self.components = Array(components.prefix(PeopleRules.maximumDevelopmentComponents))
        self.attributeChanges = Array(
            attributeChanges
                .sorted { $0.attribute.rawValue < $1.attribute.rawValue }
                .prefix(PeopleRules.maximumAttributeChangesPerSummary)
        )
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedComponents = try container.decode(
            [DevelopmentComponent].self,
            forKey: .components
        )
        let decodedChanges = try container.decode(
            [AttributeDevelopment].self,
            forKey: .attributeChanges
        )
        guard decodedComponents.count <= PeopleRules.maximumDevelopmentComponents,
              Set(decodedComponents.map(\.reason)).count == decodedComponents.count,
              decodedChanges.count <= PeopleRules.maximumAttributeChangesPerSummary,
              Set(decodedChanges.map(\.attribute)).count == decodedChanges.count else {
            throw DecodingError.dataCorruptedError(
                forKey: .components,
                in: container,
                debugDescription: "Development explanation exceeds its bounded unique shape."
            )
        }
        self.init(
            occurredAt: try container.decode(CalendarState.self, forKey: .occurredAt),
            components: decodedComponents,
            attributeChanges: decodedChanges
        )
    }

    public var explainedDelta: Int { components.reduce(0) { $0 + $1.value } }
    public var appliedDelta: Int { attributeChanges.reduce(0) { $0 + $1.delta } }
}

public struct PlayerLifecycleState: Codable, Sendable, Equatable, Identifiable {
    private enum CodingKeys: String, CodingKey {
        case playerID, fatigue, injury, status, lastDevelopment, recentChanges, suspension
    }

    public var id: UUID { playerID }
    public let playerID: UUID
    public private(set) var fatigue: Int
    public private(set) var injury: PlayerInjury?
    public private(set) var status: PlayerLifecycleStatus
    public private(set) var lastDevelopment: DevelopmentSummary?
    public private(set) var recentChanges: [AttributeChangeRecord]
    /// Time being served. `02` §5.2. Optional and omitted when absent, so a world in which nobody is
    /// suspended encodes to exactly the bytes it did before discipline existed — which is what keeps
    /// this additive against a schema with no migration path.
    public private(set) var suspension: PlayerSuspension?

    public init(
        playerID: UUID,
        fatigue: Int = 0,
        injury: PlayerInjury? = nil,
        status: PlayerLifecycleStatus = .active,
        lastDevelopment: DevelopmentSummary? = nil,
        recentChanges: [AttributeChangeRecord] = [],
        suspension: PlayerSuspension? = nil
    ) {
        self.playerID = playerID
        self.fatigue = min(max(fatigue, PeopleRules.fatigueRange.lowerBound),
                           PeopleRules.fatigueRange.upperBound)
        self.injury = injury
        self.status = status
        self.lastDevelopment = lastDevelopment
        self.recentChanges = Array(recentChanges.suffix(PeopleRules.recentChangeHistoryLimit))
        self.suspension = suspension
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedFatigue = try container.decode(Int.self, forKey: .fatigue)
        guard PeopleRules.fatigueRange.contains(decodedFatigue) else {
            throw DecodingError.dataCorruptedError(
                forKey: .fatigue,
                in: container,
                debugDescription: "Player fatigue is outside its legal range."
            )
        }
        let decodedRecentChanges = try container.decodeIfPresent(
            [AttributeChangeRecord].self,
            forKey: .recentChanges
        ) ?? []
        guard decodedRecentChanges.count <= PeopleRules.recentChangeHistoryLimit else {
            throw DecodingError.dataCorruptedError(
                forKey: .recentChanges,
                in: container,
                debugDescription: "Recent attribute history exceeds its bound."
            )
        }
        self.init(
            playerID: try container.decode(UUID.self, forKey: .playerID),
            fatigue: decodedFatigue,
            injury: try container.decodeIfPresent(PlayerInjury.self, forKey: .injury),
            status: try container.decode(PlayerLifecycleStatus.self, forKey: .status),
            lastDevelopment: try container.decodeIfPresent(
                DevelopmentSummary.self,
                forKey: .lastDevelopment
            ),
            recentChanges: decodedRecentChanges,
            suspension: try container.decodeIfPresent(PlayerSuspension.self, forKey: .suspension)
        )
    }

    public var isAvailable: Bool { status == .active && injury == nil && suspension == nil }

    /// Serving time counts down on the same tick recovery does, and returns whether it finished.
    ///
    /// Separate from `recoverWeek`'s return value rather than folded into it: that Bool means "came
    /// back from an injury" and drives `.playerRecovered`, so a suspension ending would otherwise
    /// announce a recovery from an injury the player never had.
    @discardableResult
    public mutating func serveSuspensionWeek() -> Bool {
        guard var current = suspension else { return false }
        current.serveWeek()
        if current.isServed {
            suspension = nil
            return true
        }
        suspension = current
        return false
    }

    /// Puts a player out. Refuses to overwrite time already being served, for the reason `sustain`
    /// refuses to overwrite an injury: the longer absence is the one the world already knows about,
    /// and a second call would quietly shorten it.
    public mutating func suspend(_ newSuspension: PlayerSuspension) {
        guard status == .active, suspension == nil else { return }
        suspension = newSuspension
    }

    @discardableResult
    public mutating func recoverWeek() -> Bool {
        fatigue = max(PeopleRules.fatigueRange.lowerBound,
                      fatigue - PeopleRules.weeklyFatigueRecovery)
        guard var currentInjury = injury else { return false }
        currentInjury.recoverWeek()
        if currentInjury.isRecovered {
            injury = nil
            return true
        }
        injury = currentInjury
        return false
    }

    public mutating func applyWorkload(_ amount: Int) {
        fatigue = min(PeopleRules.fatigueRange.upperBound, fatigue + max(0, amount))
    }

    /// Applies the current week's authored practice without adding another persisted readiness
    /// currency. Both conditioning and recovery reduce the same bounded fatigue measure that the
    /// match-availability rules already consume.
    public mutating func applyPracticeEffects(
        conditioningBenefit: Int,
        recoveryBenefit: Int
    ) {
        let reduction = max(0, conditioningBenefit) + max(0, recoveryBenefit)
        fatigue = max(PeopleRules.fatigueRange.lowerBound, fatigue - reduction)
    }

    public mutating func sustain(_ newInjury: PlayerInjury) {
        guard status == .active, injury == nil else { return }
        injury = newInjury
    }

    public mutating func recordDevelopment(_ summary: DevelopmentSummary) {
        lastDevelopment = summary
        guard let cause = summary.components.max(by: {
            abs($0.value) < abs($1.value)
        })?.reason else { return }
        recentChanges = Array((recentChanges + summary.attributeChanges.map {
            AttributeChangeRecord(
                occurredAt: summary.occurredAt,
                attribute: $0.attribute,
                delta: $0.delta,
                cause: cause
            )
        }).suffix(PeopleRules.recentChangeHistoryLimit))
    }

    public mutating func endCareer(as endStatus: PlayerLifecycleStatus) {
        guard endStatus != .active else { return }
        status = endStatus
        injury = nil
        suspension = nil
        fatigue = 0
    }
}

public struct PlayerCareerSeason: Codable, Sendable, Equatable {
    public let season: Int
    public let organisationID: UUID
    public let tier: Tier
    public let games: Int
    public let starts: Int
    public let overallAtEnd: Rating
    public let redshirtResolution: RedshirtSeasonResolution?

    public init(
        season: Int,
        organisationID: UUID,
        tier: Tier,
        games: Int,
        starts: Int,
        overallAtEnd: Rating,
        redshirtResolution: RedshirtSeasonResolution? = nil
    ) {
        let canonicalResolution = tier == .college
            ? redshirtResolution ?? RedshirtSeasonResolution(
                outcome: .notDesignated,
                plannedAppearanceLimit: nil
            )
            : nil
        let maximumGames = tier == .college
            ? CollegeRules.maximumGamesPerSeason
            : ProRules.maximumGamesPerSeason
        precondition(
            season >= 0
                && (0...maximumGames).contains(games)
                && (0...games).contains(starts)
                && ((tier == .college
                    && canonicalResolution?.isValid(appearances: games) == true)
                    || (tier == .pro && redshirtResolution == nil)),
            "Career seasons require supported usage and tier-consistent redshirt outcomes."
        )
        self.season = season
        self.organisationID = organisationID
        self.tier = tier
        self.games = games
        self.starts = starts
        self.overallAtEnd = overallAtEnd
        self.redshirtResolution = canonicalResolution
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedSeason = try container.decode(Int.self, forKey: .season)
        let decodedGames = try container.decode(Int.self, forKey: .games)
        let decodedStarts = try container.decode(Int.self, forKey: .starts)
        let decodedTier = try container.decode(Tier.self, forKey: .tier)
        let decodedResolution: RedshirtSeasonResolution?
        switch decodedTier {
        case .college:
            decodedResolution = try container.decode(
                RedshirtSeasonResolution.self,
                forKey: .redshirtResolution
            )
        case .pro:
            decodedResolution = try container.decodeIfPresent(
                RedshirtSeasonResolution.self,
                forKey: .redshirtResolution
            )
        }
        let maximumGames = decodedTier == .college
            ? CollegeRules.maximumGamesPerSeason
            : ProRules.maximumGamesPerSeason
        guard decodedSeason >= 0,
              (0...maximumGames).contains(decodedGames),
              (0...decodedGames).contains(decodedStarts),
              (decodedTier == .college
                && decodedResolution?.isValid(appearances: decodedGames) == true)
                || (decodedTier == .pro && decodedResolution == nil) else {
            throw DecodingError.dataCorruptedError(
                forKey: .games,
                in: container,
                debugDescription: "Player career season has impossible season or usage totals."
            )
        }
        season = decodedSeason
        organisationID = try container.decode(UUID.self, forKey: .organisationID)
        tier = decodedTier
        games = decodedGames
        starts = decodedStarts
        overallAtEnd = try container.decode(Rating.self, forKey: .overallAtEnd)
        redshirtResolution = decodedResolution
    }
}

public struct PlayerRecruitingOrigin: Codable, Sendable, Equatable {
    public let originCityID: UUID
    public let commitmentHistory: [RecruitingCommitmentContext]
    public let signedAt: CalendarState
    public let finalInterest: Int
    public let finalNILAllocation: Int
    public let overallAtSigning: Rating
    public let recruitingPriorities: [RecruitingPitch: Rating]

    public var signingSeason: Int { signedAt.season }
    public var programmeID: UUID { commitmentHistory.last!.winner.programmeID }
    public var committedAt: CalendarState { commitmentHistory.last!.committedAt }
    public var winnerContext: RecruitingCommitmentContenderContext {
        commitmentHistory.last!.winner
    }
    public var runnerUpContext: RecruitingCommitmentContenderContext? {
        commitmentHistory.last!.runnerUp
    }

    public init(
        originCityID: UUID,
        commitmentHistory: [RecruitingCommitmentContext],
        signedAt: CalendarState,
        finalInterest: Int,
        finalNILAllocation: Int,
        overallAtSigning: Rating,
        recruitingPriorities: [RecruitingPitch: Rating]
    ) {
        precondition(Self.isValid(
            commitmentHistory: commitmentHistory,
            signedAt: signedAt,
            finalInterest: finalInterest,
            finalNILAllocation: finalNILAllocation,
            recruitingPriorities: recruitingPriorities
        ))
        self.originCityID = originCityID
        self.commitmentHistory = commitmentHistory
        self.signedAt = signedAt
        self.finalInterest = finalInterest
        self.finalNILAllocation = finalNILAllocation
        self.overallAtSigning = overallAtSigning
        self.recruitingPriorities = recruitingPriorities
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedHistory = try container.decode(
            [RecruitingCommitmentContext].self,
            forKey: .commitmentHistory
        )
        let decodedSignedAt = try container.decode(CalendarState.self, forKey: .signedAt)
        let decodedInterest = try container.decode(Int.self, forKey: .finalInterest)
        let decodedNIL = try container.decode(Int.self, forKey: .finalNILAllocation)
        let decodedPriorities = try container.decode(
            [RecruitingPitch: Rating].self,
            forKey: .recruitingPriorities
        )
        guard Self.isValid(
            commitmentHistory: decodedHistory,
            signedAt: decodedSignedAt,
            finalInterest: decodedInterest,
            finalNILAllocation: decodedNIL,
            recruitingPriorities: decodedPriorities
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .commitmentHistory,
                in: container,
                debugDescription: "Player recruiting origin is outside its legal bounds."
            )
        }
        originCityID = try container.decode(UUID.self, forKey: .originCityID)
        commitmentHistory = decodedHistory
        signedAt = decodedSignedAt
        finalInterest = decodedInterest
        finalNILAllocation = decodedNIL
        overallAtSigning = try container.decode(Rating.self, forKey: .overallAtSigning)
        recruitingPriorities = decodedPriorities
    }

    var isValid: Bool {
        Self.isValid(
            commitmentHistory: commitmentHistory,
            signedAt: signedAt,
            finalInterest: finalInterest,
            finalNILAllocation: finalNILAllocation,
            recruitingPriorities: recruitingPriorities
        )
    }

    private static func isValid(
        commitmentHistory: [RecruitingCommitmentContext],
        signedAt: CalendarState,
        finalInterest: Int,
        finalNILAllocation: Int,
        recruitingPriorities: [RecruitingPitch: Rating]
    ) -> Bool {
        guard !commitmentHistory.isEmpty,
              commitmentHistory.count <= CollegeRules.commitmentHistoryLimit,
              commitmentHistory.allSatisfy(\.isValid),
              commitmentHistory.allSatisfy({ $0.committedAt.season == signedAt.season }),
              commitmentHistory.first?.previousWinner == nil,
              zip(commitmentHistory, commitmentHistory.dropFirst()).allSatisfy({ lhs, rhs in
                  (lhs.committedAt.season < rhs.committedAt.season
                      || (lhs.committedAt.season == rhs.committedAt.season
                          && lhs.committedAt.week < rhs.committedAt.week))
                      && lhs.winner.programmeID != rhs.winner.programmeID
                      && rhs.previousWinner?.programmeID == lhs.winner.programmeID
              }),
              let final = commitmentHistory.last,
              final.committedAt.season == signedAt.season,
              final.committedAt.week <= signedAt.week,
              (0...100).contains(finalInterest),
              (0...CollegeRules.maximumNILBudget).contains(finalNILAllocation),
              finalInterest == final.winner.relationshipInterest,
              finalNILAllocation == final.winner.nilAllocation,
              Set(recruitingPriorities.keys) == Set(RecruitingPitch.allCases) else { return false }
        return true
    }
}

public struct PlayerCareerRecord: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID { playerID }
    public let playerID: UUID
    public let recruitingOrigin: PlayerRecruitingOrigin?
    public private(set) var seasons: [PlayerCareerSeason]
    public private(set) var portalWindows: [CollegePortalWindowRecord]
    public private(set) var endedAt: CalendarState?
    public private(set) var endStatus: PlayerLifecycleStatus?

    public init(
        playerID: UUID,
        recruitingOrigin: PlayerRecruitingOrigin? = nil,
        seasons: [PlayerCareerSeason] = [],
        portalWindows: [CollegePortalWindowRecord],
        endedAt: CalendarState? = nil,
        endStatus: PlayerLifecycleStatus? = nil
    ) {
        let normalizedSeasons = Array(seasons.suffix(PeopleRules.careerSeasonHistoryLimit))
        precondition(
            Self.seasonsAreChronological(normalizedSeasons)
                && (endedAt == nil) == (endStatus == nil)
                && endStatus != .active
                && Self.portalHistoryIsValid(
                    playerID: playerID,
                    seasons: normalizedSeasons,
                    portalWindows: portalWindows,
                    endedAt: endedAt
                )
        )
        self.playerID = playerID
        self.recruitingOrigin = recruitingOrigin
        self.seasons = normalizedSeasons
        self.portalWindows = portalWindows
        self.endedAt = endedAt
        self.endStatus = endStatus
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedPlayerID = try container.decode(UUID.self, forKey: .playerID)
        let decodedOrigin = try container.decodeIfPresent(
            PlayerRecruitingOrigin.self,
            forKey: .recruitingOrigin
        )
        let decodedSeasons = try container.decode([PlayerCareerSeason].self, forKey: .seasons)
        let decodedPortalWindows = try container.decode(
            [CollegePortalWindowRecord].self,
            forKey: .portalWindows
        )
        let decodedEndedAt = try container.decodeIfPresent(CalendarState.self, forKey: .endedAt)
        let decodedEndStatus = try container.decodeIfPresent(
            PlayerLifecycleStatus.self,
            forKey: .endStatus
        )
        var previousSeason: Int?
        let chronological = decodedSeasons.allSatisfy { season in
            defer { previousSeason = season.season }
            return previousSeason.map { season.season > $0 } ?? true
        }
        guard decodedSeasons.count <= PeopleRules.careerSeasonHistoryLimit,
              chronological,
              Self.portalHistoryIsValid(
                  playerID: decodedPlayerID,
                  seasons: decodedSeasons,
                  portalWindows: decodedPortalWindows,
                  endedAt: decodedEndedAt
              ),
              (decodedEndedAt == nil) == (decodedEndStatus == nil),
              decodedEndStatus != .active else {
            throw DecodingError.dataCorruptedError(
                forKey: .seasons,
                in: container,
                debugDescription: "Player career history is malformed or unbounded."
            )
        }
        self.init(
            playerID: decodedPlayerID,
            recruitingOrigin: decodedOrigin,
            seasons: decodedSeasons,
            portalWindows: decodedPortalWindows,
            endedAt: decodedEndedAt,
            endStatus: decodedEndStatus
        )
    }

    @discardableResult
    public mutating func append(_ season: PlayerCareerSeason) -> Bool {
        guard seasons.last.map({ season.season > $0.season }) ?? true else { return false }
        let nextSeasons = Array(
            (seasons + [season]).suffix(PeopleRules.careerSeasonHistoryLimit)
        )
        guard Self.portalHistoryIsValid(
            playerID: playerID,
            seasons: nextSeasons,
            portalWindows: portalWindows,
            endedAt: endedAt
        ) else { return false }
        seasons = nextSeasons
        return true
    }

    @discardableResult
    public mutating func append(_ portalWindow: CollegePortalWindowRecord) -> Bool {
        guard endedAt == nil,
              portalWindows.count < PeopleRules.portalWindowHistoryLimit,
              portalWindow.playerID == playerID else { return false }
        let nextWindows = portalWindows + [portalWindow]
        guard Self.portalHistoryIsValid(
            playerID: playerID,
            seasons: seasons,
            portalWindows: nextWindows,
            endedAt: endedAt
        ) else { return false }
        portalWindows = nextWindows
        return true
    }

    public mutating func end(at calendar: CalendarState, status: PlayerLifecycleStatus) {
        guard status != .active,
              portalWindows.allSatisfy({ Self.occursBefore($0.openedAt, calendar) }) else {
            return
        }
        endedAt = calendar
        endStatus = status
    }

    private static func portalHistoryIsValid(
        playerID: UUID,
        seasons: [PlayerCareerSeason],
        portalWindows: [CollegePortalWindowRecord],
        endedAt: CalendarState?
    ) -> Bool {
        guard portalWindows.count <= PeopleRules.portalWindowHistoryLimit,
              portalWindows.allSatisfy({ $0.playerID == playerID }),
              Set(portalWindows.compactMap({ record -> Int? in
                  if case .transferred = record.outcome { return record.targetSeason }
                  return nil
              })).count == portalWindows.filter({ record in
                  if case .transferred = record.outcome { return true }
                  return false
              }).count,
              zip(portalWindows, portalWindows.dropFirst()).allSatisfy({ previous, next in
                  occursBefore(previous, next)
                      && previous.finalProgrammeID == next.sourceProgrammeID
              }),
              endedAt.map({ end in
                  portalWindows.allSatisfy({ occursBefore($0.openedAt, end) })
              }) ?? true else { return false }

        let targetSeasons = Set(portalWindows.map(\.targetSeason)).sorted()
        if let first = targetSeasons.first,
           let last = targetSeasons.last,
           last - first >= CollegeRules.eligibilityClockYears {
            return false
        }

        for (index, record) in portalWindows.enumerated() {
            guard record.targetSeason > 0,
                  let completedSeason = seasons.first(where: {
                      $0.season == record.targetSeason - 1 && $0.tier == .college
                  }),
                  record.intent.evidence.appearances == completedSeason.games,
                  record.intent.evidence.starts == completedSeason.starts else { return false }
            let sameTargetPostseason = portalWindows[..<index].last(where: {
                $0.targetSeason == record.targetSeason && $0.window == .postseason
            })
            let expectedSource: UUID
            switch record.window {
            case .postseason:
                expectedSource = completedSeason.organisationID
                guard record.intent.evidence.seasonsAtSource >= 1 else { return false }
            case .spring:
                expectedSource = sameTargetPostseason?.finalProgrammeID
                    ?? completedSeason.organisationID
                if let postseason = sameTargetPostseason {
                    guard record.sourceWasScholarship == postseason.finalIsScholarship,
                          record.intent.evidence.sourceRosterNIL == postseason.finalRosterNIL
                    else { return false }
                    if case .transferred = postseason.outcome {
                        guard record.intent.evidence.seasonsAtSource == 0 else { return false }
                    } else {
                        guard record.intent.evidence.seasonsAtSource >= 1 else { return false }
                    }
                } else {
                    guard record.intent.evidence.seasonsAtSource >= 1 else { return false }
                }
            }
            guard record.sourceProgrammeID == expectedSource else { return false }
        }
        return true
    }

    private static func occursBefore(
        _ lhs: CollegePortalWindowRecord,
        _ rhs: CollegePortalWindowRecord
    ) -> Bool {
        lhs.targetSeason < rhs.targetSeason
            || (lhs.targetSeason == rhs.targetSeason && lhs.window.order < rhs.window.order)
    }

    private static func occursBefore(_ lhs: CalendarState, _ rhs: CalendarState) -> Bool {
        lhs.season < rhs.season || (lhs.season == rhs.season && lhs.week < rhs.week)
    }

    private static func seasonsAreChronological(_ seasons: [PlayerCareerSeason]) -> Bool {
        zip(seasons, seasons.dropFirst()).allSatisfy { previous, next in
            previous.season < next.season
        }
    }
}

public struct StaffCareerAssignment: Codable, Sendable, Equatable {
    public let season: Int
    public let organisationID: UUID
    public let role: StaffRole

    public init(season: Int, organisationID: UUID, role: StaffRole) {
        self.season = max(0, season)
        self.organisationID = organisationID
        self.role = role
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedSeason = try container.decode(Int.self, forKey: .season)
        guard decodedSeason >= 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .season,
                in: container,
                debugDescription: "Staff assignment season cannot be negative."
            )
        }
        season = decodedSeason
        organisationID = try container.decode(UUID.self, forKey: .organisationID)
        role = try container.decode(StaffRole.self, forKey: .role)
    }
}

public struct StaffCareerRecord: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID { staffID }
    public let staffID: UUID
    public private(set) var assignments: [StaffCareerAssignment]

    public init(staffID: UUID, assignments: [StaffCareerAssignment] = []) {
        self.staffID = staffID
        self.assignments = Array(assignments.suffix(PeopleRules.careerSeasonHistoryLimit))
    }

    mutating func record(_ assignment: StaffCareerAssignment) {
        assignments = Array(
            (assignments + [assignment]).suffix(PeopleRules.careerSeasonHistoryLimit)
        )
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedAssignments = try container.decode(
            [StaffCareerAssignment].self,
            forKey: .assignments
        )
        var previousSeason: Int?
        let chronological = decodedAssignments.allSatisfy { assignment in
            defer { previousSeason = assignment.season }
            return previousSeason.map { assignment.season >= $0 } ?? true
        }
        guard decodedAssignments.count <= PeopleRules.careerSeasonHistoryLimit,
              chronological else {
            throw DecodingError.dataCorruptedError(
                forKey: .assignments,
                in: container,
                debugDescription: "Staff career history exceeds its bound."
            )
        }
        self.init(
            staffID: try container.decode(UUID.self, forKey: .staffID),
            assignments: decodedAssignments
        )
    }
}

public struct DepartedPlayerIdentity: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let firstName: String
    public let lastName: String
    public let position: Position
    public let finalAge: Int
    public let status: PlayerLifecycleStatus

    public init(player: Player, status: PlayerLifecycleStatus) {
        id = player.id
        firstName = player.firstName
        lastName = player.lastName
        position = player.position
        finalAge = player.age
        self.status = status
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedAge = try container.decode(Int.self, forKey: .finalAge)
        let decodedStatus = try container.decode(PlayerLifecycleStatus.self, forKey: .status)
        guard PeopleRules.playerAgeRange.contains(decodedAge),
              decodedStatus != .active else {
            throw DecodingError.dataCorruptedError(
                forKey: .finalAge,
                in: container,
                debugDescription: "Departed player identity has invalid age or active status."
            )
        }
        id = try container.decode(UUID.self, forKey: .id)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        position = try container.decode(Position.self, forKey: .position)
        finalAge = decodedAge
        status = decodedStatus
    }

    public var fullName: String { "\(firstName) \(lastName)" }
}

public struct PeopleState: Codable, Sendable, Equatable {
    public private(set) var playerLifecycle: [UUID: PlayerLifecycleState]
    public private(set) var playerCareers: [UUID: PlayerCareerRecord]
    public private(set) var staffCareers: [UUID: StaffCareerRecord]
    public private(set) var departedPlayers: [UUID: DepartedPlayerIdentity]

    public init(
        playerLifecycle: [PlayerLifecycleState] = [],
        playerCareers: [PlayerCareerRecord] = [],
        staffCareers: [StaffCareerRecord] = [],
        departedPlayers: [DepartedPlayerIdentity] = []
    ) {
        self.playerLifecycle = [:]
        self.playerCareers = [:]
        self.staffCareers = [:]
        self.departedPlayers = [:]
        for lifecycle in playerLifecycle where self.playerLifecycle[lifecycle.playerID] == nil {
            self.playerLifecycle[lifecycle.playerID] = lifecycle
        }
        for career in playerCareers where self.playerCareers[career.playerID] == nil {
            self.playerCareers[career.playerID] = career
        }
        for career in staffCareers where self.staffCareers[career.staffID] == nil {
            self.staffCareers[career.staffID] = career
        }
        for identity in departedPlayers where self.departedPlayers[identity.id] == nil {
            self.departedPlayers[identity.id] = identity
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedLifecycle = try container.decode(
            [UUID: PlayerLifecycleState].self,
            forKey: .playerLifecycle
        )
        let decodedPlayerCareers = try container.decode(
            [UUID: PlayerCareerRecord].self,
            forKey: .playerCareers
        )
        let decodedStaffCareers = try container.decode(
            [UUID: StaffCareerRecord].self,
            forKey: .staffCareers
        )
        let decodedDepartedPlayers = try container.decode(
            [UUID: DepartedPlayerIdentity].self,
            forKey: .departedPlayers
        )
        guard decodedLifecycle.allSatisfy({ $0.key == $0.value.playerID }),
              decodedPlayerCareers.allSatisfy({ $0.key == $0.value.playerID }),
              decodedStaffCareers.allSatisfy({ $0.key == $0.value.staffID }),
              decodedDepartedPlayers.allSatisfy({ $0.key == $0.value.id }) else {
            throw DecodingError.dataCorruptedError(
                forKey: .playerLifecycle,
                in: container,
                debugDescription: "People-state keys disagree with persistent person IDs."
            )
        }
        playerLifecycle = decodedLifecycle
        playerCareers = decodedPlayerCareers
        staffCareers = decodedStaffCareers
        departedPlayers = decodedDepartedPlayers
    }

    public static func bootstrap(
        players: [Player],
        staff: [Staff] = [],
        staffEmployerIDs: [UUID: UUID] = [:],
        season: Int = 0
    ) -> PeopleState {
        PeopleState(
            playerLifecycle: players.map { PlayerLifecycleState(playerID: $0.id) },
            playerCareers: players.map {
                PlayerCareerRecord(playerID: $0.id, portalWindows: [])
            },
            staffCareers: staff.map { member in
                StaffCareerRecord(
                    staffID: member.id,
                    assignments: staffEmployerIDs[member.id].map {
                        [StaffCareerAssignment(
                            season: season,
                            organisationID: $0,
                            role: member.role
                        )]
                    } ?? []
                )
            }
        )
    }

    @discardableResult
    public mutating func updatePlayerLifecycle(
        _ id: UUID,
        _ mutation: (inout PlayerLifecycleState) -> Void
    ) -> Bool {
        guard var lifecycle = playerLifecycle[id] else { return false }
        mutation(&lifecycle)
        guard lifecycle.playerID == id else { return false }
        playerLifecycle[id] = lifecycle
        return true
    }

    @discardableResult
    public mutating func updatePlayerCareer(
        _ id: UUID,
        _ mutation: (inout PlayerCareerRecord) -> Void
    ) -> Bool {
        guard var career = playerCareers[id] else { return false }
        mutation(&career)
        guard career.playerID == id else { return false }
        playerCareers[id] = career
        return true
    }

    public mutating func insert(
        player: Player,
        recruitingOrigin: PlayerRecruitingOrigin? = nil
    ) {
        guard playerLifecycle[player.id] == nil,
              playerCareers[player.id] == nil,
              departedPlayers[player.id] == nil else { return }
        playerLifecycle[player.id] = PlayerLifecycleState(playerID: player.id)
        playerCareers[player.id] = PlayerCareerRecord(
            playerID: player.id,
            recruitingOrigin: recruitingOrigin,
            portalWindows: []
        )
    }

    public mutating func insert(staff: Staff, assignment: StaffCareerAssignment) {
        guard staffCareers[staff.id] == nil else { return }
        staffCareers[staff.id] = StaffCareerRecord(
            staffID: staff.id,
            assignments: [assignment]
        )
    }

    /// Appends one assignment to a staff career, creating the record if the coach has none.
    ///
    /// An out-of-order season is refused rather than written: the decoder rejects a
    /// non-chronological record, and a caller must never be able to produce a save that cannot be
    /// read back.
    @discardableResult
    public mutating func recordStaffAssignment(
        _ assignment: StaffCareerAssignment,
        for staff: Staff
    ) -> Bool {
        guard var career = staffCareers[staff.id] else {
            staffCareers[staff.id] = StaffCareerRecord(
                staffID: staff.id,
                assignments: [assignment]
            )
            return true
        }
        guard career.assignments.last != assignment else { return true }
        guard career.assignments.last.map({ assignment.season >= $0.season }) ?? true else {
            return false
        }
        career.record(assignment)
        staffCareers[staff.id] = career
        return true
    }

    public mutating func archive(player: Player, status: PlayerLifecycleStatus) {
        guard status != .active, playerLifecycle[player.id] != nil else { return }
        playerLifecycle.removeValue(forKey: player.id)
        departedPlayers[player.id] = DepartedPlayerIdentity(player: player, status: status)
    }
}
