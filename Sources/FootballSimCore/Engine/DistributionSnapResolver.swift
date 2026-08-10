import Foundation

/// Resolves a snap from calibrated outcome distributions while sampling the causal attribution
/// from the same inputs that condition those distributions.
public enum DistributionSnapResolver {
    public static func resolve(
        tier: Tier,
        offensiveCall: OffensiveCall,
        defensiveCall: DefensiveCall,
        personnel: SnapPersonnel,
        situation: Situation,
        isHomeOffense: Bool,
        rng: inout SeededRandom
    ) -> SnapOutcome {
        let draws = SnapDraws(rng: &rng)
        return resolve(tier: tier, offensiveCall: offensiveCall,
                       defensiveCall: defensiveCall, personnel: personnel,
                       situation: situation, isHomeOffense: isHomeOffense, draws: draws)
    }

    /// RNG-free replay and test seam. Every random choice for the snap is supplied in `draws`.
    public static func resolve(
        tier: Tier,
        offensiveCall: OffensiveCall,
        defensiveCall: DefensiveCall,
        personnel: SnapPersonnel,
        situation: Situation,
        isHomeOffense: Bool,
        draws: SnapDraws
    ) -> SnapOutcome {
        let assignment = Assignment.assign(offensiveCall: offensiveCall,
                                           defensiveCall: defensiveCall,
                                           personnel: personnel)
        switch offensiveCall.playType {
        case .run:
            return resolveRun(tier: tier, offensiveCall: offensiveCall,
                              defensiveCall: defensiveCall, assignment: assignment,
                              situation: situation, isHomeOffense: isHomeOffense, draws: draws)
        case .pass:
            return resolvePass(tier: tier, offensiveCall: offensiveCall,
                               defensiveCall: defensiveCall, assignment: assignment,
                               situation: situation, isHomeOffense: isHomeOffense, draws: draws)
        case .fieldGoal:
            return resolveFieldGoal(tier: tier, personnel: personnel, assignment: assignment,
                                    situation: situation, isHomeOffense: isHomeOffense,
                                    draws: draws)
        case .punt:
            return resolvePunt(tier: tier, personnel: personnel, situation: situation, draws: draws)
        case .kneel:
            return SnapOutcome(result: .kneel, yards: OutcomeDistributionRules.kneelYards,
                               secondsElapsed: tier.clockRules.inBoundsPlaySeconds, matchups: [])
        }
    }

    // MARK: - Conditioning

    private static func mean(_ ratings: [Rating]) -> Double? {
        guard !ratings.isEmpty else { return nil }
        return Double(ratings.reduce(Int.zero) { $0 + $1.value }) / Double(ratings.count)
    }

    private static func ratingShift(_ rawEdge: Double, maximum: Double) -> Double {
        Swift.min(Swift.max(
            rawEdge / OutcomeDistributionRules.ratingPointsForMaximumShift * maximum,
            -maximum
        ), maximum)
    }

    private static func transfer<Band: Hashable>(
        _ signedAmount: Double, between adverse: Band, and favourable: Band,
        in weights: inout [Band
            : Double]
    ) {
        let donor = signedAmount >= .zero ? adverse : favourable
        let receiver = signedAmount >= .zero ? favourable : adverse
        let moved = Swift.min(Swift.abs(signedAmount), weights[donor, default: .zero])
        weights[donor, default: .zero] -= moved
        weights[receiver, default: .zero] += moved
    }

    /// Test seam for the distribution invariant shared by every conditioned outcome table.
    package static func validDistribution(_ weights: [Double]) -> Bool {
        weights.allSatisfy { $0.isFinite && $0 >= .zero }
            && Swift.abs(weights.reduce(.zero, +) - 1.0)
                <= OutcomeDistributionRules.probabilityTolerance
    }

    private static func assertDistribution<Band>(_ weights: [Band
        : Double]) {
        let valid = validDistribution(Array(weights.values))
        assert(valid)
        precondition(valid)
    }

    private static func homeShift(tier: Tier, isHomeOffense: Bool) -> Double {
        guard isHomeOffense else { return .zero }
        switch tier {
        case .pro: return OutcomeDistributionRules.proHomeProbabilityShift
        case .college: return OutcomeDistributionRules.collegeHomeProbabilityShift
        }
    }

    private static func attributionMagnitude(_ draws: SnapDraws) -> Double {
        OutcomeDistributionRules.minimumAttributionMagnitude
            + draws.secondary * OutcomeDistributionRules.attributionMagnitudeRange
    }

    private static func sampledIndex(count: Int, roll: Double) -> Int? {
        guard count > Int.zero else { return nil }
        return OutcomeSampling.integer(in: Int.zero...(count - 1), roll: roll)
    }

    // MARK: - Run

    private static func resolveRun(
        tier: Tier,
        offensiveCall: OffensiveCall,
        defensiveCall: DefensiveCall,
        assignment: SnapAssignment,
        situation: Situation,
        isHomeOffense: Bool,
        draws: SnapDraws
    ) -> SnapOutcome {
        let rules = tier.clockRules
        guard let carrier = assignment.carrier,
              let laneIndex = sampledIndex(count: assignment.runLane.count,
                                           roll: draws.attribution),
              let pursuerIndex = sampledIndex(count: assignment.pursuit.count,
                                              roll: draws.attribution)
        else {
            return SnapOutcome(result: .gain, yards: .zero,
                               secondsElapsed: rules.inBoundsPlaySeconds, matchups: [])
        }
        let lane = assignment.runLane[laneIndex]
        let pursuer = assignment.pursuit[pursuerIndex]

        guard let laneOffence = mean([
            lane.blocker.attributes[.runBlock], lane.blocker.attributes[.strength],
            lane.blocker.attributes[.awareness], lane.blocker.attributes[.schemeFit],
        ]), let laneDefence = mean([
            lane.defender.attributes[.runDefence], lane.defender.attributes[.shed],
            lane.defender.attributes[.gapDiscipline], lane.defender.attributes[.strength],
        ]), let carrierOffence = mean([
            carrier.attributes[.vision], carrier.attributes[.elusiveness],
            carrier.attributes[.power], carrier.attributes[.speed],
        ]), let pursuitDefence = mean([
            pursuer.attributes[.tackling], pursuer.attributes[.pursuit],
            pursuer.attributes[.speed],
        ]), let securityOffence = mean([
            carrier.attributes[.power], carrier.attributes[.awareness],
            carrier.attributes[.durability],
        ]), let securityDefence = mean([
            pursuer.attributes[.tackling], pursuer.attributes[.pursuit],
            pursuer.attributes[.power],
        ]) else {
            return SnapOutcome(result: .gain, yards: .zero,
                               secondsElapsed: rules.inBoundsPlaySeconds, matchups: [])
        }

        var weights = Dictionary(uniqueKeysWithValues:
            OutcomeDistributionRules.runWeights(tier: tier))
        transfer(ratingShift(laneOffence - laneDefence,
                             maximum: OutcomeDistributionRules.maximumProbabilityShift),
                 between: .loss, and: .medium, in: &weights)
        transfer(homeShift(tier: tier, isHomeOffense: isHomeOffense),
                 between: .loss, and: .medium, in: &weights)
        transfer(ratingShift(carrierOffence - pursuitDefence,
                             maximum: OutcomeDistributionRules.maximumProbabilityShift),
                 between: .short, and: .explosive, in: &weights)
        transfer(ratingShift(securityOffence - securityDefence,
                             maximum: OutcomeDistributionRules.maximumBallSecurityProbabilityShift),
                 between: .fumbleLost, and: .short, in: &weights)
        if offensiveCall.runGap.isOutside {
            transfer(OutcomeDistributionRules.outsideRunProbabilityShift,
                     between: .short, and: .explosive, in: &weights)
        }
        transfer(offensiveCall.aggression * OutcomeDistributionRules.runAggressionProbabilityShift,
                 between: .short, and: .explosive, in: &weights)
        transfer(defensiveCall.aggression
                    * OutcomeDistributionRules.defensiveAggressionProbabilityShift,
                 between: .medium, and: .loss, in: &weights)
        if situation.distance <= OutcomeDistributionRules.shortYardageDistance {
            transfer(OutcomeDistributionRules.shortYardageProbabilityShift,
                     between: .loss, and: .short, in: &weights)
        } else if situation.distance >= OutcomeDistributionRules.longYardageDistance {
            transfer(OutcomeDistributionRules.longYardageProbabilityShift,
                     between: .medium, and: .loss, in: &weights)
        }
        assertDistribution(weights)
        let ordered = RunOutcomeBand.allCases.map { ($0, weights[$0]!) }
        guard let band = WeightedOutcome(ordered).sample(roll: draws.outcome) else {
            return SnapOutcome(result: .gain, yards: .zero,
                               secondsElapsed: rules.inBoundsPlaySeconds, matchups: [])
        }
        return runOutcome(band: band, carrier: carrier, lane: lane, pursuer: pursuer,
                          situation: situation, rules: rules, draws: draws)
    }

    private static func runOutcome(
        band: RunOutcomeBand,
        carrier: Player,
        lane: (blocker: Player, defender: Player),
        pursuer: Player,
        situation: Situation,
        rules: any ClockRules.Type,
        draws: SnapDraws
    ) -> SnapOutcome {
        let magnitude = attributionMagnitude(draws)
        let kind: MatchupRecord.Kind
        let attackerID: UUID
        let defenderID: UUID
        let leverage: Double
        let sampledYards: Int
        let result: SnapResult

        switch band {
        case .loss:
            kind = .runLane; attackerID = lane.blocker.id; defenderID = lane.defender.id
            leverage = -magnitude
            sampledYards = OutcomeSampling.integer(in: OutcomeDistributionRules.lossYards,
                                                    roll: draws.yardage) ?? .zero
            result = situation.yardLine + sampledYards <= Int.zero ? .safety : .gain
        case .short:
            kind = .runLane; attackerID = lane.blocker.id; defenderID = lane.defender.id
            leverage = magnitude
            sampledYards = OutcomeSampling.integer(in: OutcomeDistributionRules.shortRunYards,
                                                    roll: draws.yardage) ?? .zero
            result = sampledYards >= situation.yardsToGoal ? .touchdown : .gain
        case .medium:
            kind = .runLane; attackerID = lane.blocker.id; defenderID = lane.defender.id
            leverage = magnitude
            sampledYards = OutcomeSampling.integer(in: OutcomeDistributionRules.mediumRunYards,
                                                    roll: draws.yardage) ?? .zero
            result = sampledYards >= situation.yardsToGoal ? .touchdown : .gain
        case .explosive:
            kind = .carrierVersusPursuit; attackerID = carrier.id; defenderID = pursuer.id
            leverage = magnitude
            sampledYards = OutcomeSampling.integer(in: OutcomeDistributionRules.explosiveRunYards,
                                                    roll: draws.yardage) ?? .zero
            result = sampledYards >= situation.yardsToGoal ? .touchdown : .gain
        case .breakaway:
            kind = .carrierVersusPursuit; attackerID = carrier.id; defenderID = pursuer.id
            leverage = magnitude
            sampledYards = OutcomeSampling.integer(in: OutcomeDistributionRules.breakawayRunYards,
                                                    roll: draws.yardage) ?? .zero
            result = sampledYards >= situation.yardsToGoal ? .touchdown : .gain
        case .fumbleLost:
            kind = .ballSecurity; attackerID = carrier.id; defenderID = pursuer.id
            leverage = -magnitude
            let yards = OutcomeSampling.integer(in: OutcomeDistributionRules.runFumbleYards,
                                                roll: draws.yardage) ?? .zero
            sampledYards = Swift.min(yards, Swift.max(Int.zero,
                situation.yardsToGoal - OutcomeDistributionRules.lastFieldYardOffset))
            result = .fumbleLost
        }

        let yards: Int
        switch result {
        case .touchdown: yards = situation.yardsToGoal
        case .safety: yards = -situation.yardLine
        default: yards = sampledYards
        }
        let record = MatchupRecord(kind: kind, attackerID: attackerID,
                                   defenderID: defenderID, leverage: leverage)
        return SnapOutcome(result: result, yards: yards,
                           secondsElapsed: rules.inBoundsPlaySeconds, matchups: [record],
                           ballCarrierID: carrier.id)
    }

    // MARK: - Pass

    private static func resolvePass(
        tier: Tier,
        offensiveCall: OffensiveCall,
        defensiveCall: DefensiveCall,
        assignment: SnapAssignment,
        situation: Situation,
        isHomeOffense: Bool,
        draws: SnapDraws
    ) -> SnapOutcome {
        let rules = tier.clockRules
        guard let passer = assignment.passer,
              !assignment.routes.isEmpty,
              let protectionIndex = sampledIndex(count: assignment.protection.count,
                                                 roll: draws.attribution)
        else {
            return SnapOutcome(result: .gain, yards: .zero,
                               secondsElapsed: rules.inBoundsPlaySeconds, matchups: [])
        }
        let targetWeights = assignment.routes.enumerated().map { index, route in
            (index, OutcomeDistributionRules.targetRatingFloor
                + Double(route.receiver.attributes[.routeRunning].value
                         - SharedRules.ratingRange.lowerBound)
                + Double(route.receiver.attributes[.hands].value
                         - SharedRules.ratingRange.lowerBound)
                + Double(route.receiver.attributes[.speed].value
                         - SharedRules.ratingRange.lowerBound))
        }
        guard let targetIndex = WeightedOutcome(targetWeights).sample(roll: draws.target) else {
            return SnapOutcome(result: .gain, yards: .zero,
                               secondsElapsed: rules.inBoundsPlaySeconds, matchups: [])
        }
        let route = assignment.routes[targetIndex]
        let protection = assignment.protection[protectionIndex]

        guard let protectionOffence = mean([
            protection.blocker.attributes[.passBlock], protection.blocker.attributes[.strength],
            protection.blocker.attributes[.awareness],
        ]), let protectionDefence = mean([
            protection.rusher.attributes[.passRush], protection.rusher.attributes[.finesse],
            protection.rusher.attributes[.power], protection.rusher.attributes[.motor],
        ]), let throwOffence = mean([
            passer.attributes[offensiveCall.passDepth.accuracy], passer.attributes[.armStrength],
            passer.attributes[.decision], passer.attributes[.poise],
            route.receiver.attributes[.routeRunning], route.receiver.attributes[.release],
            route.receiver.attributes[.hands], route.receiver.attributes[.speed],
        ]), let throwDefence = mean([
            route.defender.attributes[.coverage], route.defender.attributes[.awareness],
            route.defender.attributes[.hands], route.defender.attributes[.speed],
            route.defender.attributes[.agility],
        ]), let securityOffence = mean([
            route.receiver.attributes[.power], route.receiver.attributes[.awareness],
            route.receiver.attributes[.durability],
        ]), let securityDefence = mean([
            route.defender.attributes[.tackling], route.defender.attributes[.pursuit],
            route.defender.attributes[.power],
        ]) else {
            return SnapOutcome(result: .gain, yards: .zero,
                               secondsElapsed: rules.inBoundsPlaySeconds, matchups: [])
        }

        let protectionEdge = protectionOffence - protectionDefence
        let throwEdge = throwOffence - throwDefence
            + protectionEdge * OutcomeDistributionRules.passProtectionThrowWeight
        var weights = Dictionary(uniqueKeysWithValues:
            OutcomeDistributionRules.passWeights(tier: tier))
        transfer(ratingShift(protectionEdge,
                             maximum: OutcomeDistributionRules.maximumProbabilityShift),
                 between: .sack, and: .completion, in: &weights)
        transfer(ratingShift(throwEdge,
                             maximum: OutcomeDistributionRules.maximumProbabilityShift),
                 between: .incompletion, and: .completion, in: &weights)
        transfer(ratingShift(Double(passer.attributes[.decision].value
                                        - route.defender.attributes[.awareness].value),
                             maximum: OutcomeDistributionRules.maximumProbabilityShift),
                 between: .interception, and: .incompletion, in: &weights)
        transfer(ratingShift(securityOffence - securityDefence,
                             maximum: OutcomeDistributionRules.maximumBallSecurityProbabilityShift),
                 between: .fumbleLost, and: .completion, in: &weights)
        transfer(homeShift(tier: tier, isHomeOffense: isHomeOffense),
                 between: .incompletion, and: .completion, in: &weights)

        switch offensiveCall.passDepth {
        case .short:
            transfer(OutcomeDistributionRules.maximumDepthProbabilityShift,
                     between: .explosiveCompletion, and: .completion, in: &weights)
        case .mid:
            break
        case .deep:
            transfer(OutcomeDistributionRules.maximumDepthProbabilityShift,
                     between: .completion, and: .explosiveCompletion, in: &weights)
        }
        let extraRushers = defensiveCall.rushers - MatchupRules.baseRushers
        transfer(-Double(extraRushers) * OutcomeDistributionRules.rusherSackShiftPerPlayer,
                 between: .sack, and: .completion, in: &weights)
        applyCoverageTransfer(depth: offensiveCall.passDepth, shell: defensiveCall.coverage,
                              weights: &weights)

        let offensiveRisk = offensiveCall.aggression
            * OutcomeDistributionRules.passAggressionProbabilityShift
            * OutcomeDistributionRules.riskRewardSplit
        transfer(offensiveRisk, between: .completion, and: .explosiveCompletion, in: &weights)
        transfer(offensiveRisk, between: .incompletion, and: .interception, in: &weights)
        let defensiveRisk = defensiveCall.aggression
            * OutcomeDistributionRules.defensiveAggressionProbabilityShift
            * OutcomeDistributionRules.riskRewardSplit
        transfer(defensiveRisk, between: .completion, and: .sack, in: &weights)
        transfer(defensiveRisk, between: .incompletion, and: .explosiveCompletion, in: &weights)
        if situation.distance <= OutcomeDistributionRules.shortYardageDistance {
            transfer(OutcomeDistributionRules.shortYardageProbabilityShift,
                     between: .incompletion, and: .completion, in: &weights)
        } else if situation.distance >= OutcomeDistributionRules.longYardageDistance {
            transfer(OutcomeDistributionRules.longYardageProbabilityShift,
                     between: .completion, and: .explosiveCompletion, in: &weights)
        }
        assertDistribution(weights)
        let ordered = PassOutcomeBand.allCases.map { ($0, weights[$0]!) }
        guard let band = WeightedOutcome(ordered).sample(roll: draws.outcome) else {
            return SnapOutcome(result: .gain, yards: .zero,
                               secondsElapsed: rules.inBoundsPlaySeconds, matchups: [])
        }
        return passOutcome(band: band, passer: passer, route: route, protection: protection,
                           situation: situation, rules: rules, draws: draws)
    }

    private static func applyCoverageTransfer(
        depth: PassDepth,
        shell: CoverageShell,
        weights: inout [PassOutcomeBand
            : Double]
    ) {
        switch (depth, shell) {
        case (.short, .zoneUnder):
            transfer(OutcomeDistributionRules.coverageShellProbabilityShift,
                     between: .completion, and: .incompletion, in: &weights)
        case (.short, .zoneDeep), (.short, .prevent):
            transfer(OutcomeDistributionRules.coverageShellProbabilityShift,
                     between: .incompletion, and: .completion, in: &weights)
        case (.deep, .zoneDeep), (.deep, .prevent):
            transfer(OutcomeDistributionRules.coverageShellProbabilityShift,
                     between: .explosiveCompletion, and: .incompletion, in: &weights)
        case (.deep, .zoneUnder):
            transfer(OutcomeDistributionRules.coverageShellProbabilityShift,
                     between: .incompletion, and: .explosiveCompletion, in: &weights)
        case (_, .man), (.mid, _):
            break
        }
    }

    private static func passOutcome(
        band: PassOutcomeBand,
        passer: Player,
        route: (receiver: Player, defender: Player),
        protection: (blocker: Player, rusher: Player),
        situation: Situation,
        rules: any ClockRules.Type,
        draws: SnapDraws
    ) -> SnapOutcome {
        let magnitude = attributionMagnitude(draws)
        if band == .sack {
            let sampled = OutcomeSampling.integer(in: OutcomeDistributionRules.sackYards,
                                                  roll: draws.yardage) ?? .zero
            let safety = situation.yardLine + sampled <= Int.zero
            let record = MatchupRecord(kind: .passProtection, attackerID: protection.blocker.id,
                                       defenderID: protection.rusher.id, leverage: -magnitude)
            return SnapOutcome(result: safety ? .safety : .sack,
                               yards: safety ? -situation.yardLine : sampled,
                               secondsElapsed: rules.inBoundsPlaySeconds, matchups: [record],
                               passerID: passer.id)
        }

        let favourable = band == .completion || band == .explosiveCompletion
            || band == .fumbleLost
        let routeRecord = MatchupRecord(kind: .routeVersusCoverage,
                                        attackerID: route.receiver.id,
                                        defenderID: route.defender.id,
                                        leverage: favourable ? magnitude : -magnitude)
        let throwRecord = MatchupRecord(kind: .throwing, attackerID: route.receiver.id,
                                        defenderID: route.defender.id,
                                        leverage: favourable ? magnitude : -magnitude)
        switch band {
        case .interception:
            return SnapOutcome(result: .interception, yards: .zero,
                               secondsElapsed: rules.stoppedPlaySeconds,
                               matchups: [routeRecord, throwRecord], passerID: passer.id,
                               targetID: route.receiver.id)
        case .incompletion:
            return SnapOutcome(result: .incompletion, yards: .zero,
                               secondsElapsed: rules.stoppedPlaySeconds,
                               matchups: [routeRecord, throwRecord], passerID: passer.id,
                               targetID: route.receiver.id)
        case .completion, .explosiveCompletion:
            let range = band == .completion ? OutcomeDistributionRules.ordinaryPassYards
                                            : OutcomeDistributionRules.explosivePassYards
            let sampled = OutcomeSampling.integer(in: range, roll: draws.yardage) ?? .zero
            let touchdown = sampled >= situation.yardsToGoal
            return SnapOutcome(result: touchdown ? .touchdown : .gain,
                               yards: touchdown ? situation.yardsToGoal : sampled,
                               secondsElapsed: rules.inBoundsPlaySeconds,
                               matchups: [routeRecord, throwRecord],
                               ballCarrierID: route.receiver.id, passerID: passer.id,
                               targetID: route.receiver.id)
        case .fumbleLost:
            let sampled = OutcomeSampling.integer(in: OutcomeDistributionRules.passFumbleYards,
                                                  roll: draws.yardage) ?? .zero
            let yards = Swift.min(sampled, Swift.max(Int.zero,
                situation.yardsToGoal - OutcomeDistributionRules.lastFieldYardOffset))
            let security = MatchupRecord(kind: .ballSecurity, attackerID: route.receiver.id,
                                         defenderID: route.defender.id, leverage: -magnitude)
            return SnapOutcome(result: .fumbleLost, yards: yards,
                               secondsElapsed: rules.inBoundsPlaySeconds,
                               matchups: [routeRecord, throwRecord, security],
                               ballCarrierID: route.receiver.id, passerID: passer.id,
                               targetID: route.receiver.id)
        case .sack:
            preconditionFailure("sacks return before target attribution")
        }
    }

    // MARK: - Special teams

    private static func resolveFieldGoal(
        tier: Tier,
        personnel: SnapPersonnel,
        assignment: SnapAssignment,
        situation: Situation,
        isHomeOffense: Bool,
        draws: SnapDraws
    ) -> SnapOutcome {
        let rules = tier.clockRules
        guard let kicker = personnel.offensive(group: .specialists).first,
              let defender = assignment.pursuit.first,
              let offence = mean([kicker.attributes[.kickAccuracy],
                                  kicker.attributes[.legStrength], kicker.attributes[.poise]]),
              let defence = mean([defender.attributes[.blockLeverage],
                                  defender.attributes[.awareness]])
        else {
            return SnapOutcome(result: .fieldGoalMissed, yards: .zero,
                               secondsElapsed: rules.stoppedPlaySeconds, matchups: [])
        }
        let distance = situation.yardsToGoal + MatchupRules.fieldGoalSnapDistance
        let base: Double
        switch tier {
        case .pro: base = OutcomeDistributionRules.proFieldGoalBase
        case .college: base = OutcomeDistributionRules.collegeFieldGoalBase
        }
        let probability = Swift.min(Swift.max(
            base + ratingShift(offence - defence,
                               maximum: OutcomeDistributionRules
                                   .maximumFieldGoalMatchupProbabilityShift)
                - Double(Swift.max(Int.zero,
                                   distance - OutcomeDistributionRules.fieldGoalReferenceDistance))
                    * OutcomeDistributionRules.fieldGoalDistancePenaltyPerYard
                + homeShift(tier: tier, isHomeOffense: isHomeOffense),
            OutcomeDistributionRules.minimumFieldGoalProbability
        ), OutcomeDistributionRules.maximumFieldGoalProbability)
        let made = draws.outcome < probability
        let record = MatchupRecord(kind: .kick, attackerID: kicker.id, defenderID: defender.id,
                                   leverage: made ? attributionMagnitude(draws)
                                                  : -attributionMagnitude(draws))
        return SnapOutcome(result: made ? .fieldGoalGood : .fieldGoalMissed, yards: .zero,
                           secondsElapsed: rules.stoppedPlaySeconds, matchups: [record],
                           ballCarrierID: kicker.id)
    }

    private static func resolvePunt(
        tier: Tier,
        personnel: SnapPersonnel,
        situation: Situation,
        draws: SnapDraws
    ) -> SnapOutcome {
        let punter = personnel.offensive(.punter).first
            ?? personnel.offensive(group: .specialists).first
        let sampled = OutcomeSampling.integer(in: OutcomeDistributionRules.puntYards,
                                              roll: draws.yardage) ?? .zero
        return SnapOutcome(result: .punt, yards: Swift.min(sampled, situation.yardsToGoal),
                           secondsElapsed: tier.clockRules.stoppedPlaySeconds, matchups: [],
                           ballCarrierID: punter?.id)
    }
}
