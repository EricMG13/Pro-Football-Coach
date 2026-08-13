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

/// One development week worth remembering, flattened for storage.
///
/// The engine reasons in `DevelopmentSummary`; this is what survives into the save. The nested form
/// carries up to eight components and sixteen attribute changes, and keeping six of those per player
/// across ~13,000 players would cost megabytes against a save already blocked on size (FSC-003).
/// Five scalars answer what a dossier actually asks — when, what moved, by how much, how much
/// pressure was behind it, and which reason led — and drop only detail that was already derivable
/// from the week it happened in.
///
/// A beat with `delta == 0` is a **miss**, and it is deliberately storable: `02` §8's dossier wants
/// the week the work did not land as much as the week it did. `pressure` is what separates a near
/// miss from a flat nothing, and it is why misses can outrank each other rather than tying at zero.
public struct DevelopmentBeat: Codable, Sendable, Equatable {
    public let occurredAt: CalendarState
    public let attribute: Attribute?
    public let delta: Int
    public let pressure: Int
    public let leadingReason: DevelopmentReason?

    public init(
        occurredAt: CalendarState,
        attribute: Attribute?,
        delta: Int,
        pressure: Int,
        leadingReason: DevelopmentReason?
    ) {
        precondition(
            Self.isValid(attribute: attribute, delta: delta, pressure: pressure),
            "A development beat is outside its legal shape."
        )
        self.occurredAt = occurredAt
        self.attribute = attribute
        self.delta = delta
        self.pressure = pressure
        self.leadingReason = leadingReason
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedAttribute = try container.decodeIfPresent(Attribute.self, forKey: .attribute)
        let decodedDelta = try container.decode(Int.self, forKey: .delta)
        let decodedPressure = try container.decode(Int.self, forKey: .pressure)
        guard Self.isValid(
            attribute: decodedAttribute,
            delta: decodedDelta,
            pressure: decodedPressure
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .delta,
                in: container,
                debugDescription: "A development beat is outside its legal shape."
            )
        }
        occurredAt = try container.decode(CalendarState.self, forKey: .occurredAt)
        attribute = decodedAttribute
        delta = decodedDelta
        pressure = decodedPressure
        leadingReason = try container.decodeIfPresent(
            DevelopmentReason.self,
            forKey: .leadingReason
        )
    }

    /// A beat that changed nothing. Kept, not discarded — see the type comment.
    public var isMiss: Bool { delta == 0 }

    /// Retention rank. Movement first, then the pressure behind it.
    ///
    /// Scaled so no amount of pressure can outrank actual movement: an attribute that shifted is
    /// always the better story than one that nearly did. Within each tier the comparison is by
    /// magnitude, so a decline ranks alongside an equivalent gain rather than below it — losing a
    /// point is exactly as memorable as gaining one.
    var significance: Int {
        abs(delta) * 1_000 + min(abs(pressure), 999)
    }

    private static func isValid(attribute: Attribute?, delta: Int, pressure: Int) -> Bool {
        // A non-zero delta names the attribute it moved; a miss names none. The two must agree, or
        // the dossier can render "improved" with nothing to point at.
        (attribute == nil) == (delta == 0)
            && PeopleRules.attributeDevelopmentRange.contains(delta)
            && abs(pressure)
                <= PeopleRules.maximumDevelopmentComponents
                    * max(
                        abs(PeopleRules.developmentComponentRange.lowerBound),
                        abs(PeopleRules.developmentComponentRange.upperBound)
                    )
    }
}

extension DevelopmentSummary {
    /// Flattens this week into the form the save keeps.
    ///
    /// The leading reason is the largest-magnitude component, ties broken on the reason's own name
    /// so the choice is stable across runs rather than dependent on component ordering.
    public var beat: DevelopmentBeat {
        let change = attributeChanges.max { abs($0.delta) < abs($1.delta) }
        let leading = components
            .filter { $0.value != 0 }
            .sorted {
                abs($0.value) == abs($1.value)
                    ? $0.reason.rawValue < $1.reason.rawValue
                    : abs($0.value) > abs($1.value)
            }
            .first
        return DevelopmentBeat(
            occurredAt: occurredAt,
            attribute: change.map(\.attribute),
            delta: change?.delta ?? 0,
            pressure: explainedDelta,
            leadingReason: leading?.reason
        )
    }
}

public struct PlayerLifecycleState: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID { playerID }
    public let playerID: UUID
    public private(set) var fatigue: Int
    public private(set) var injury: PlayerInjury?
    public private(set) var status: PlayerLifecycleStatus
    public private(set) var lastDevelopment: DevelopmentSummary?

    public init(
        playerID: UUID,
        fatigue: Int = 0,
        injury: PlayerInjury? = nil,
        status: PlayerLifecycleStatus = .active,
        lastDevelopment: DevelopmentSummary? = nil
    ) {
        self.playerID = playerID
        self.fatigue = min(max(fatigue, PeopleRules.fatigueRange.lowerBound),
                           PeopleRules.fatigueRange.upperBound)
        self.injury = injury
        self.status = status
        self.lastDevelopment = lastDevelopment
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
        self.init(
            playerID: try container.decode(UUID.self, forKey: .playerID),
            fatigue: decodedFatigue,
            injury: try container.decodeIfPresent(PlayerInjury.self, forKey: .injury),
            status: try container.decode(PlayerLifecycleStatus.self, forKey: .status),
            lastDevelopment: try container.decodeIfPresent(
                DevelopmentSummary.self,
                forKey: .lastDevelopment
            )
        )
    }

    public var isAvailable: Bool { status == .active && injury == nil }

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

    public mutating func sustain(_ newInjury: PlayerInjury) {
        guard status == .active, injury == nil else { return }
        injury = newInjury
    }

    public mutating func recordDevelopment(_ summary: DevelopmentSummary) {
        lastDevelopment = summary
    }

    public mutating func endCareer(as endStatus: PlayerLifecycleStatus) {
        guard endStatus != .active else { return }
        status = endStatus
        injury = nil
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

/// What the programme believed it was signing, at the moment it signed.
///
/// The fog a coach paid to clear, frozen. `ScoutingState` is wiped wholesale at every rollover
/// (`CollegeCycleSystem`), so once the class signs there is no way back to the estimate the decision
/// was actually made on — this is the one genuinely lossy fact in recruiting, and the reason it is
/// persisted rather than projected.
///
/// Held against `PlayerRecruitingOrigin.overallAtSigning`, which is the truth, it lets a dossier say
/// what no other record can: *you thought 78, give or take 4, and you were 62% sure — he was 71.*
/// Four scalars, and the estimated attribute spread is deliberately not among them; the collapsed
/// overall is what a retrospective asks about, and the per-attribute dictionary would multiply the
/// cost by the position's rated-attribute count for detail nothing reads.
public struct ProspectScoutingSnapshot: Codable, Sendable, Equatable {
    public let estimatedOverall: Rating
    public let estimatedPotential: Rating
    public let confidence: Int
    public let errorRadius: Int

    public init(
        estimatedOverall: Rating,
        estimatedPotential: Rating,
        confidence: Int,
        errorRadius: Int
    ) {
        precondition(
            Self.isValid(confidence: confidence, errorRadius: errorRadius),
            "A scouting snapshot is outside its legal shape."
        )
        self.estimatedOverall = estimatedOverall
        self.estimatedPotential = estimatedPotential
        self.confidence = confidence
        self.errorRadius = errorRadius
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedConfidence = try container.decode(Int.self, forKey: .confidence)
        let decodedRadius = try container.decode(Int.self, forKey: .errorRadius)
        guard Self.isValid(confidence: decodedConfidence, errorRadius: decodedRadius) else {
            throw DecodingError.dataCorruptedError(
                forKey: .confidence,
                in: container,
                debugDescription: "A scouting snapshot is outside its legal shape."
            )
        }
        estimatedOverall = try container.decode(Rating.self, forKey: .estimatedOverall)
        estimatedPotential = try container.decode(Rating.self, forKey: .estimatedPotential)
        confidence = decodedConfidence
        errorRadius = decodedRadius
    }

    /// The band the estimate was quoted with, clamped to the legal rating range.
    public var estimatedOverallBand: ClosedRange<Int> {
        let low = max(SharedRules.ratingRange.lowerBound, estimatedOverall.value - errorRadius)
        let high = min(SharedRules.ratingRange.upperBound, estimatedOverall.value + errorRadius)
        return low...max(low, high)
    }

    /// Whether the truth fell inside the band the coach was shown.
    ///
    /// The honest scoreboard for a scouting department: the band is a claim, and this is whether the
    /// claim held. It is not a quality judgement on the signing — a bust inside the band was
    /// correctly described and badly chosen.
    public func bandContained(_ truth: Rating) -> Bool {
        estimatedOverallBand.contains(truth.value)
    }

    private static func isValid(confidence: Int, errorRadius: Int) -> Bool {
        CollegeRules.knowledgeConfidenceRange.contains(confidence)
            && errorRadius >= 1
            && errorRadius <= SharedRules.ratingRange.upperBound
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
    /// Absent for a player who arrived without being scouted — a walk-on, or a class signed by a
    /// programme that never spent an evaluation on them.
    public let scoutingAtSigning: ProspectScoutingSnapshot?

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
        recruitingPriorities: [RecruitingPitch: Rating],
        scoutingAtSigning: ProspectScoutingSnapshot? = nil
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
        self.scoutingAtSigning = scoutingAtSigning
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
        scoutingAtSigning = try container.decodeIfPresent(
            ProspectScoutingSnapshot.self,
            forKey: .scoutingAtSigning
        )
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
    /// The weeks worth remembering, chronological, bounded and **ranked on eviction**.
    ///
    /// Stored in the order they happened because that is how a dossier reads them, but what survives
    /// truncation is chosen by `DevelopmentBeat.significance`, not by age. Keeping the newest six
    /// would fill the ring with the plateau every long career ends in and evict the breakout that
    /// made the player worth remembering — the same failure `DomainEventPayload.historicalWeight`
    /// exists to prevent in the event journal, at a different scale.
    public private(set) var developmentBeats: [DevelopmentBeat]

    public init(
        playerID: UUID,
        recruitingOrigin: PlayerRecruitingOrigin? = nil,
        seasons: [PlayerCareerSeason] = [],
        portalWindows: [CollegePortalWindowRecord],
        endedAt: CalendarState? = nil,
        endStatus: PlayerLifecycleStatus? = nil,
        developmentBeats: [DevelopmentBeat] = []
    ) {
        let normalizedSeasons = Array(seasons.suffix(PeopleRules.careerSeasonHistoryLimit))
        let normalizedBeats = Self.retaining(developmentBeats)
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
        self.developmentBeats = normalizedBeats
    }

    /// Selects the beats to keep and returns them chronologically.
    ///
    /// Ranked by significance, then by recency so a tie between two equally significant weeks keeps
    /// the later one, then by the calendar itself so the result cannot depend on input order — the
    /// same beats in a different sequence must produce the same ring, or a save round-trip could
    /// change what a player remembers.
    private static func retaining(_ beats: [DevelopmentBeat]) -> [DevelopmentBeat] {
        guard beats.count > PeopleRules.developmentBeatLimit else {
            return beats.sorted(by: chronological)
        }
        return beats
            .sorted {
                if $0.significance != $1.significance { return $0.significance > $1.significance }
                return chronological($1, $0)
            }
            .prefix(PeopleRules.developmentBeatLimit)
            .sorted(by: chronological)
    }

    private static func chronological(_ lhs: DevelopmentBeat, _ rhs: DevelopmentBeat) -> Bool {
        if lhs.occurredAt.season != rhs.occurredAt.season {
            return lhs.occurredAt.season < rhs.occurredAt.season
        }
        if lhs.occurredAt.week != rhs.occurredAt.week {
            return lhs.occurredAt.week < rhs.occurredAt.week
        }
        // Two beats in the same week can only differ by what moved. Ordered on the attribute's own
        // name so the tie is broken identically on every run.
        return (lhs.attribute?.rawValue ?? "") < (rhs.attribute?.rawValue ?? "")
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
        let decodedBeats = try container.decodeIfPresent(
            [DevelopmentBeat].self,
            forKey: .developmentBeats
        ) ?? []
        guard decodedSeasons.count <= PeopleRules.careerSeasonHistoryLimit,
              chronological,
              Self.portalHistoryIsValid(
                  playerID: decodedPlayerID,
                  seasons: decodedSeasons,
                  portalWindows: decodedPortalWindows,
                  endedAt: decodedEndedAt
              ),
              (decodedEndedAt == nil) == (decodedEndStatus == nil),
              decodedEndStatus != .active,
              // Rejected rather than silently truncated. `init` would trim an over-long ring to the
              // bound, which on a decode path would let a tampered or future-schema save load with a
              // ring quietly different from the one it stored — the save would still be wrong, just
              // no longer detectably so.
              decodedBeats.count <= PeopleRules.developmentBeatLimit else {
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
            endStatus: decodedEndStatus,
            developmentBeats: decodedBeats
        )
    }

    /// Records one development week, evicting the least significant beat when the ring is full.
    ///
    /// Returns whether the beat was kept. A beat that arrives already less significant than every
    /// beat held is dropped rather than stored and immediately evicted, so the return value means
    /// "this is part of the player's history" rather than "this was received".
    @discardableResult
    public mutating func recordDevelopmentBeat(_ beat: DevelopmentBeat) -> Bool {
        let next = Self.retaining(developmentBeats + [beat])
        guard next.contains(beat) else { return false }
        developmentBeats = next
        return true
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

    public mutating func archive(player: Player, status: PlayerLifecycleStatus) {
        guard status != .active, playerLifecycle[player.id] != nil else { return }
        playerLifecycle.removeValue(forKey: player.id)
        departedPlayers[player.id] = DepartedPlayerIdentity(player: player, status: status)
    }
}
