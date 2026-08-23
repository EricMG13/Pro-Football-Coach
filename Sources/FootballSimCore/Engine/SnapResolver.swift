import Foundation

/// Stages 3 and 4 of `03-MATCH-ENGINE.md` §1.1: leverages combine into an outcome, and the
/// outcome into a consequence.
///
/// **The stage order is part of the determinism contract** (`03` §1.1), so it is a fixed sequence
/// here and `EngineTests` asserts it rather than trusting call sites: assignment, then every
/// leverage, then resolution, then consequence.
///
/// **The engine owns every probability** (`03` §1.3). Nothing downstream may re-roll any of this;
/// the view reads `SnapOutcome` and draws it.
public enum SnapResolver {
    /// Resolves one snap.
    ///
    /// `rng` is threaded explicitly and never ambient. Every draw is taken in a fixed order so a
    /// replay of the same seed against the same state produces the same play, byte for byte.
    public static func resolve(
        offensiveCall: OffensiveCall,
        defensiveCall: DefensiveCall,
        personnel: SnapPersonnel,
        situation: Situation,
        rules: any ClockRules.Type,
        homeFieldAdvantage: Double = 0,
        rng: inout SeededRandom
    ) -> SnapOutcome {
        let assignment = Assignment.assign(offensiveCall: offensiveCall,
                                           defensiveCall: defensiveCall,
                                           personnel: personnel)
        // The pre-snap clock is the drive loop's, not the snap's: whether it runs at all depends on
        // what the *previous* snap did and on the tier's first-down rule, neither of which a single
        // snap can see. `secondsElapsed` here is the play's own duration.

        switch offensiveCall.playType {
        case .kneel:
            return SnapOutcome(result: .kneel, yards: -1,
                               secondsElapsed: rules.inBoundsPlaySeconds,
                               matchups: [])
        case .run:
            return resolveRun(offensiveCall, defensiveCall, assignment, personnel, situation, rules,
                              homeFieldAdvantage, &rng)
        case .pass:
            return resolvePass(offensiveCall, defensiveCall, assignment, situation, rules,
                               homeFieldAdvantage, &rng)
        case .fieldGoal:
            return resolveFieldGoal(personnel, assignment, situation, rules, homeFieldAdvantage,
                                    &rng)
        case .punt:
            return resolvePunt(personnel, situation, rules, &rng)
        }
    }

    // MARK: - Pass

    /// `03` §1.1: "protection duels resolve first, producing time-to-pressure. Route matchups
    /// resolve into an openness score per receiver. The passer selects a target from openness,
    /// progression order and decision rating, then the throw resolves against openness, accuracy
    /// and pressure."
    private static func resolvePass(
        _ offensiveCall: OffensiveCall,
        _ defensiveCall: DefensiveCall,
        _ assignment: SnapAssignment,
        _ situation: Situation,
        _ rules: any ClockRules.Type,
        _ homeFieldAdvantage: Double,
        _ rng: inout SeededRandom
    ) -> SnapOutcome {
        var matchups: [MatchupRecord] = []

        // 1. Protection.
        var protectionLeverage = 0.0
        for duel in assignment.protection {
            let leverage = Leverage.score(
                attacker: duel.blocker.attributes[.passBlock],
                defender: duel.rusher.attributes[.passRush],
                schemeFit: 0,
                situationModifier: homeFieldAdvantage - defensiveCall.aggression
                    * MatchupRules.blitzPressureBonus,
                rng: &rng
            )
            matchups.append(MatchupRecord(kind: .passProtection, attackerID: duel.blocker.id,
                                          defenderID: duel.rusher.id, leverage: leverage))
            protectionLeverage += leverage
        }
        let averageProtection = assignment.protection.isEmpty
            ? -1.0
            : protectionLeverage / Double(assignment.protection.count)
        let pressure = Swift.max(0, -averageProtection)

        // Backed up against his own line the passer takes a shorter drop, so an ordinary sack does
        // not end in the end zone. Safeties stay reachable from inside the three, which is where
        // nearly all of the real ones come from.
        let sackLoss = situation.yardLine <= MatchupRules.backedUpYardLine
            ? Swift.max(MatchupRules.sackYards,
                        Swift.min(MatchupRules.backedUpSackYards, 1 - situation.yardLine))
            : MatchupRules.sackYards
        guard let passer = assignment.passer else {
            return sackOrSafety(yards: sackLoss, situation: situation,
                                elapsed: rules.inBoundsPlaySeconds, matchups: matchups,
                                passer: nil)
        }

        // 2. Routes, into an openness score each.
        var openness: [(receiver: Player, score: Double)] = []
        for route in assignment.routes {
            let leverage = Leverage.score(
                attacker: route.receiver.attributes[.routeRunning],
                defender: route.defender.attributes[.coverage],
                schemeFit: 0,
                situationModifier: homeFieldAdvantage
                    - defensiveCall.coverage.help(against: offensiveCall.passDepth)
                    + defensiveCall.coverageDrain,
                rng: &rng
            )
            matchups.append(MatchupRecord(kind: .routeVersusCoverage, attackerID: route.receiver.id,
                                          defenderID: route.defender.id, leverage: leverage))
            openness.append((route.receiver, leverage))
        }

        // 3. Sack, if the pocket collapsed before anyone came open.
        let sackThreshold = MatchupRules.sackPressureThreshold
            - Double(passer.attributes[.poise].value - SharedRules.ratingRange.lowerBound)
            / Double(SharedRules.ratingRange.count) * MatchupRules.poiseSackRelief
        if pressure > sackThreshold || openness.isEmpty {
            // Through the safety check, not around it. The three sack returns used to bypass
            // `finish` entirely, so the single most common real safety — a sack in your own end
            // zone — could not happen: 5,000 of 5,000 sacks from the offence's own 2 came back as
            // an ordinary loss.
            return sackOrSafety(yards: sackLoss, situation: situation,
                                elapsed: rules.inBoundsPlaySeconds, matchups: matchups,
                                passer: passer)
        }

        // 4. Target selection: openness, weighted by the passer's decision rating. A poor decider
        //    drifts toward progression order rather than toward the open man.
        let decision = normalised(passer.attributes[.decision])
        let target = openness.enumerated().max { lhs, rhs in
            weightedTarget(lhs.element.score, order: lhs.offset, decision: decision)
                < weightedTarget(rhs.element.score, order: rhs.offset, decision: decision)
        }!

        // 5. The throw, against a difficulty set by *depth*, with openness as a modifier.
        //
        // The first version made the defender's rating the inverse of the chosen receiver's
        // openness. Since the target is the most open of four, that produced a weak defender on
        // almost every snap and the throw completed essentially always: `incompletion` and
        // `interception` were declared results the engine could not reach, which is the dead
        // capability `08-OPUS5-BUILD-PROMPT.md` names as this project's first failure mode. The
        // reachability test found it, and the fix is structural rather than a moved threshold —
        // a threshold nudged until incompletions appear would have been P4's calibration done
        // early, by eye, on a model that was wrong.
        //
        // Depth is the difficulty because that is what it is: a deep ball is hard to complete to
        // an open receiver. Openness then helps, and pressure hurts.
        // Three inputs, weighted so that each is one of three. Depth sets the baseline; the passer
        // is measured against a reference passer rather than against the depth itself, because
        // "how hard is this throw" and "how good is this passer" are different questions and one
        // logistic between them made the second answer both.
        let accuracy = passer.attributes[offensiveCall.passDepth.accuracy]
        let throwLeverage = Leverage.score(
            attacker: accuracy,
            defender: Rating(MatchupRules.referencePasserAccuracy),
            situationModifier: MatchupRules.throwBaseline(offensiveCall.passDepth)
                + homeFieldAdvantage
                + target.element.score * MatchupRules.opennessThrowHelp
                - pressure * MatchupRules.pressureThrowPenalty
                + offensiveCall.aggression * MatchupRules.aggressionThrowBonus,
            ratingWeight: MatchupRules.throwAccuracyWeight,
            rng: &rng
        )
        // The defender covering the TARGET, not routes[0]. The target is the argmax over
        // weightedTarget and is frequently not the first read: 1,606 of 3,867 measured throws — 42
        // percent — recorded a defender who was covering somebody else, which makes the causal
        // record 04 section 5.3 reads a lie on nearly half the passes in the game.
        matchups.append(MatchupRecord(
            kind: .throwing, attackerID: passer.id,
            defenderID: assignment.routes[target.offset].defender.id,
            leverage: throwLeverage
        ))

        let elapsed = rules.inBoundsPlaySeconds
        if throwLeverage < MatchupRules.interceptionThreshold {
            return SnapOutcome(result: .interception, yards: 0,
                               secondsElapsed: rules.stoppedPlaySeconds,
                               matchups: matchups, passerID: passer.id,
                               targetID: target.element.receiver.id)
        }
        if throwLeverage < MatchupRules.completionThreshold {
            return SnapOutcome(result: .incompletion, yards: 0,
                               secondsElapsed: rules.stoppedPlaySeconds,
                               matchups: matchups, passerID: passer.id,
                               targetID: target.element.receiver.id)
        }

        // 6. Yards after the catch, from the receiver against the nearest pursuit.
        //
        // The man covering him leads it. `assignment.pursuit` is already ordered secondary-first
        // for a pass, but the assignment cannot know *which* receiver would win -- the resolver
        // does, and the defender it beat is by definition the one standing at the catch. Hoisting
        // him is reading the record rather than guessing at it, and it is what makes the recorded
        // tackler vary with the route that actually won.
        let air = offensiveCall.passDepth.airYards
        // `routes[target.offset].defender`, the same indexing the `.throwing` matchup above
        // already uses for exactly this reason: the target is the argmax over `weightedTarget` and
        // is frequently not the first read.
        let covering = assignment.routes[target.offset].defender
        let atTheCatch = [covering] + assignment.pursuit.filter { $0.id != covering.id }
        let (afterCatch, pursuitRecord, extraPursuitAttempts) = yardsAfterContact(
            carrier: target.element.receiver, pursuit: atTheCatch,
            aggression: offensiveCall.aggression, homeFieldAdvantage: homeFieldAdvantage,
            threshold: MatchupRules.catchBreakTackleThreshold, rng: &rng
        )
        if let pursuitRecord { matchups.append(pursuitRecord) }
        // The same three terms the run gets: what the catch is worth before anyone is beaten, what
        // the receiver wins against the first pursuer, and what the break chain extends.
        let catchContact = pursuitRecord?.leverage ?? 0
        let gained = air + Int((MatchupRules.baseCatchYards
                                  + catchContact * MatchupRules.catchYardScale).rounded())
            + afterCatch
        return finish(gained: gained, situation: situation, elapsed: elapsed, matchups: matchups,
                      brokenTackleAttempts: extraPursuitAttempts, carrier: target.element.receiver,
                      passer: passer, target: target.element.receiver, rng: &rng)
    }

    /// How attractive a target is: openness, pulled toward progression order as decision falls.
    public static func weightedTarget(_ openness: Double, order: Int, decision: Double) -> Double {
        openness * decision - Double(order) * MatchupRules.progressionPenalty * (1 - decision)
    }

    // MARK: - Run

    /// `03` §1.1: "front matchups resolve into lane quality; the carrier's vision and elusiveness
    /// resolve against pursuit leverage into yards, with a break-tackle chain that can extend the
    /// play."
    private static func resolveRun(
        _ offensiveCall: OffensiveCall,
        _ defensiveCall: DefensiveCall,
        _ assignment: SnapAssignment,
        _ personnel: SnapPersonnel,
        _ situation: Situation,
        _ rules: any ClockRules.Type,
        _ homeFieldAdvantage: Double,
        _ rng: inout SeededRandom
    ) -> SnapOutcome {
        var matchups: [MatchupRecord] = []
        var laneLeverage = 0.0
        for duel in assignment.runLane {
            let leverage = Leverage.score(
                attacker: duel.blocker.attributes[.runBlock],
                defender: duel.defender.attributes[.runDefence],
                situationModifier: homeFieldAdvantage + defensiveCall.coverage.runCost
                    - defensiveCall.aggression * MatchupRules.crashRunBonus,
                rng: &rng
            )
            matchups.append(MatchupRecord(kind: .runLane, attackerID: duel.blocker.id,
                                          defenderID: duel.defender.id, leverage: leverage))
            laneLeverage += leverage
        }
        let lane = assignment.runLane.isEmpty ? 0 : laneLeverage / Double(assignment.runLane.count)

        let draw = rng.double01()
        let backs = personnel.offensive(group: .runningBacks)
        let quarterback = personnel.offensive(group: .quarterbacks).first
        let carrier: Player? = if draw < MatchupRules.quarterbackDesignedRunProbability {
            quarterback ?? backs.first
        } else if draw < MatchupRules.quarterbackDesignedRunProbability
            + MatchupRules.reserveBackDesignedRunProbability,
            backs.count > 1 {
            backs[1]
        } else {
            backs.first ?? quarterback
        }
        guard let carrier else {
            return SnapOutcome(result: .gain, yards: 0,
                               secondsElapsed: rules.inBoundsPlaySeconds,
                               matchups: matchups)
        }

        let (broken, pursuitRecord, extraPursuitAttempts) = yardsAfterContact(
            carrier: carrier, pursuit: assignment.pursuit, aggression: offensiveCall.aggression,
            homeFieldAdvantage: homeFieldAdvantage,
            threshold: MatchupRules.breakTackleThreshold
                - (rules.tier == .college ? MatchupRules.collegeBreakTackleRelief : 0),
            rng: &rng
        )
        if let pursuitRecord { matchups.append(pursuitRecord) }

        let outside = offensiveCall.runGap.isOutside ? MatchupRules.outsideRunVariance : 1.0
        // Three terms, one per clause of 03 section 1.1: what the front gave, what the carrier won
        // against the first pursuer, and what the break chain extended. The base is the play that
        // none of the three decides — a carry into a standstill still gains a couple of yards.
        let contact = pursuitRecord?.leverage ?? 0
        // The college tier spreads its run outcomes wider; 01 section 6.5's explosive-run bands for
        // the two tiers do not overlap, so this is a tier constant rather than a shared one.
        let spread = rules.tier == .college ? MatchupRules.collegeRunSpreadMultiplier : 1.0
        // One rounding, not two: rounding the chain separately from the rest quantised the result
        // twice over and made the tier multiplier step rather than slide.
        let gained = Int((MatchupRules.baseRunYards
                            + lane * MatchupRules.laneYardScale * outside * spread
                            + contact * MatchupRules.contactYardScale * spread
                            + Double(broken)).rounded())
        return finish(gained: gained, situation: situation,
                      elapsed: rules.inBoundsPlaySeconds, matchups: matchups,
                      brokenTackleAttempts: extraPursuitAttempts, carrier: carrier, passer: nil,
                      target: nil, rng: &rng)
    }

    /// The carrier against pursuit, with a bounded break-tackle chain.
    ///
    /// `03` §1.1: "the carrier's vision and elusiveness resolve against pursuit leverage into yards,
    /// **with a break-tackle chain that can extend the play**."
    ///
    /// Each break is worth more than the last, because that is the shape a run distribution has:
    /// most carries gain a few yards into a crowd, and the ones that get past the second level go a
    /// long way. A flat bonus per break gave a near-symmetric distribution and an explosive-run rate
    /// of essentially zero against a band of 0.105 to 0.130 — the model missing a tail, not a
    /// constant mistuned.
    ///
    /// Bounded because an unbounded chain is a hang with a small probability, and `03` §7's frame
    /// budget has no room for one.
    private static func yardsAfterContact(
        carrier: Player,
        pursuit: [Player],
        aggression: Double,
        homeFieldAdvantage: Double,
        threshold: Double,
        rng: inout SeededRandom
    ) -> (yards: Int, record: MatchupRecord?, extraAttempts: [MatchupRecord]) {
        guard !pursuit.isEmpty else { return (0, nil, []) }
        var yards = 0
        var record: MatchupRecord?
        // Attempts beyond the first, kept out of `record` for the same reason `record` alone used
        // to be returned: only the first ever flowed into `SnapOutcome.matchups`, which
        // `playByPlayFingerprint` hashes. These are pure observation of leverage values this loop
        // already computes — recording them draws nothing extra from `rng`.
        var extraAttempts: [MatchupRecord] = []
        for attempt in 0..<MatchupRules.maximumBrokenTackles {
            let defender = pursuit[Swift.min(attempt, pursuit.count - 1)]
            // Vision gets the carrier to the second level; elusiveness is what beats the man
            // there. 03 section 1.2's Carrier row names both and only one was being read.
            let carrying = attempt == 0
                ? carrier.attributes[.vision]
                : carrier.attributes[.elusiveness]
            let leverage = Leverage.score(
                attacker: carrying,
                defender: defender.attributes[.tackling],
                situationModifier: homeFieldAdvantage + aggression * MatchupRules.aggressionRunBonus
                    - Double(attempt) * MatchupRules.brokenTackleDecay,
                rng: &rng
            )
            if record == nil {
                // `defender`, not a separately-captured `pursuit.first`. The two are the same
                // man on attempt zero and always were, so this changes no behaviour and moves no
                // fingerprint -- but the alias made the record's identity look independent of the
                // loop when it never was, which is a trap for whoever changes the chain next.
                record = MatchupRecord(kind: .carrierVersusPursuit, attackerID: carrier.id,
                                       defenderID: defender.id, leverage: leverage)
            } else {
                extraAttempts.append(MatchupRecord(kind: .carrierVersusPursuit, attackerID: carrier.id,
                                                   defenderID: defender.id, leverage: leverage))
            }
            guard leverage > threshold else { break }
            yards += MatchupRules.brokenTackleYards * (attempt + 1)
        }
        return (yards, record, extraAttempts)
    }

    // MARK: - Kicks

    private static func resolveFieldGoal(
        _ personnel: SnapPersonnel,
        _ assignment: SnapAssignment,
        _ situation: Situation,
        _ rules: any ClockRules.Type,
        _ homeFieldAdvantage: Double,
        _ rng: inout SeededRandom
    ) -> SnapOutcome {
        let distance = situation.yardsToGoal + MatchupRules.fieldGoalSnapDistance
        guard let kicker = personnel.offensive(group: .specialists).first,
              let blocker = assignment.pursuit.first else {
            return SnapOutcome(result: .fieldGoalMissed, yards: 0,
                               secondsElapsed: rules.stoppedPlaySeconds, matchups: [])
        }
        // Distance is the defender: a long kick is a harder matchup, which keeps the whole engine
        // on one scale rather than bolting a distance curve onto the side of it.
        let difficulty = Rating(MatchupRules.fieldGoalDifficulty(distanceYards: distance,
                                                                 tier: rules.tier))
        let leverage = Leverage.score(
            attacker: kicker.attributes[.kickAccuracy],
            defender: difficulty,
            situationModifier: homeFieldAdvantage
                + normalised(kicker.attributes[.legStrength]) * MatchupRules.legStrengthHelp,
            rng: &rng
        )
        let record = MatchupRecord(kind: .kick, attackerID: kicker.id, defenderID: blocker.id,
                                   leverage: leverage)
        return SnapOutcome(result: leverage > 0 ? .fieldGoalGood : .fieldGoalMissed, yards: 0,
                           secondsElapsed: rules.stoppedPlaySeconds, matchups: [record],
                           ballCarrierID: kicker.id)
    }

    private static func resolvePunt(
        _ personnel: SnapPersonnel,
        _ situation: Situation,
        _ rules: any ClockRules.Type,
        _ rng: inout SeededRandom
    ) -> SnapOutcome {
        let punter = personnel.offensive(.punter).first ?? personnel.offensive(group: .specialists).first
        let leg = punter.map { normalised($0.attributes[.legStrength]) } ?? 0.5
        let distance = MatchupRules.basePuntYards
            + Int((leg * Double(MatchupRules.puntLegYards)).rounded())
            + rng.int(in: -MatchupRules.puntVariance...MatchupRules.puntVariance)
        return SnapOutcome(result: .punt,
                           yards: Swift.min(distance, situation.yardsToGoal),
                           secondsElapsed: rules.stoppedPlaySeconds, matchups: [],
                           ballCarrierID: punter?.id)
    }

    // MARK: - Consequence

    /// Stage 4. Turns yardage into a result, including the goal line and the fumble check.
    private static func finish(
        gained: Int,
        situation: Situation,
        elapsed: Int,
        matchups: [MatchupRecord],
        brokenTackleAttempts: [MatchupRecord] = [],
        carrier: Player,
        passer: Player?,
        target: Player?,
        rng: inout SeededRandom
    ) -> SnapOutcome {
        // The fumble draw is taken unconditionally, before the touchdown branch, so the number of
        // draws a snap consumes does not depend on where the ball ended up. A branch that skipped
        // it would couple the stream to the field position.
        let fumble = rng.chance(MatchupRules.fumbleChance)
        if fumble {
            return SnapOutcome(result: .fumbleLost, yards: gained, secondsElapsed: elapsed,
                               matchups: matchups, brokenTackleAttempts: brokenTackleAttempts,
                               ballCarrierID: carrier.id, passerID: passer?.id, targetID: target?.id)
        }
        if gained >= situation.yardsToGoal {
            return SnapOutcome(result: .touchdown, yards: situation.yardsToGoal,
                               secondsElapsed: elapsed, matchups: matchups,
                               brokenTackleAttempts: brokenTackleAttempts,
                               ballCarrierID: carrier.id, passerID: passer?.id, targetID: target?.id)
        }
        if situation.yardLine + gained <= 0 {
            return SnapOutcome(result: .safety, yards: -situation.yardLine, secondsElapsed: elapsed,
                               matchups: matchups, brokenTackleAttempts: brokenTackleAttempts,
                               ballCarrierID: carrier.id, passerID: passer?.id, targetID: target?.id)
        }
        return SnapOutcome(result: .gain, yards: gained, secondsElapsed: elapsed,
                           matchups: matchups, brokenTackleAttempts: brokenTackleAttempts,
                           ballCarrierID: carrier.id, passerID: passer?.id, targetID: target?.id)
    }

    /// A sack, unless the tackle happened behind the offence's own goal line.
    private static func sackOrSafety(
        yards: Int, situation: Situation, elapsed: Int, matchups: [MatchupRecord], passer: Player?
    ) -> SnapOutcome {
        if situation.yardLine + yards <= 0 {
            return SnapOutcome(result: .safety, yards: -situation.yardLine, secondsElapsed: elapsed,
                               matchups: matchups, ballCarrierID: passer?.id, passerID: passer?.id)
        }
        return SnapOutcome(result: .sack, yards: yards, secondsElapsed: elapsed,
                           matchups: matchups, ballCarrierID: passer?.id, passerID: passer?.id)
    }

    /// A rating on 0...1, for use as a weight.
    public static func normalised(_ rating: Rating) -> Double {
        Double(rating.value - SharedRules.ratingRange.lowerBound)
            / Double(SharedRules.ratingRange.upperBound - SharedRules.ratingRange.lowerBound)
    }
}
