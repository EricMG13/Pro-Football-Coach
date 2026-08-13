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

        // Stage 0: the flag, before anything else and unconditionally. Drawing it first means a
        // penalty cannot shift the stream the snap's own resolution reads; drawing it whether or not
        // it flags anything means the presence of a flag cannot change how many draws a snap
        // consumes, which is the property the draw-count test asserts. `02` §3.5.
        let flag = PenaltyModel.draw(personnel: personnel, situation: situation, rng: &rng)
        if let flag, flag.kind.isPreSnap {
            return PenaltyModel.preSnapOutcome(flag, rules: rules)
        }

        let outcome: SnapOutcome
        switch offensiveCall.playType {
        case .kneel:
            outcome = SnapOutcome(result: .kneel, yards: -1,
                                  secondsElapsed: rules.inBoundsPlaySeconds,
                                  matchups: [])
        case .run:
            outcome = resolveRun(offensiveCall, defensiveCall, assignment, situation, rules,
                                 homeFieldAdvantage, &rng)
        case .pass:
            outcome = resolvePass(offensiveCall, defensiveCall, assignment, situation, rules,
                                  homeFieldAdvantage, &rng)
        case .fieldGoal:
            outcome = resolveFieldGoal(personnel, assignment, situation, rules, homeFieldAdvantage,
                                       &rng)
        case .punt:
            outcome = resolvePunt(personnel, situation, rules, &rng)
        }
        guard let flag else { return outcome }
        // A kick is not called back by a hold on the offensive line in this model: the kicking game
        // has its own fouls and none of the seven kinds are them. Enforcing a scrimmage flag on a
        // kick would produce a field goal that scores and is simultaneously wiped out.
        if offensiveCall.playType == .fieldGoal || offensiveCall.playType == .punt {
            return outcome
        }
        return PenaltyModel.applying(flag, to: outcome, situation: situation, rules: rules)
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

        guard let passer = assignment.passer else {
            return sackOrSafety(yards: MatchupRules.sackYards, situation: situation,
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
            return sackOrSafety(yards: MatchupRules.sackYards, situation: situation,
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
        let accuracy = passer.attributes[offensiveCall.passDepth.accuracy]
        let throwLeverage = Leverage.score(
            attacker: accuracy,
            defender: Rating(MatchupRules.throwDifficulty(offensiveCall.passDepth)),
            situationModifier: homeFieldAdvantage
                + target.element.score * MatchupRules.opennessThrowHelp
                - pressure * MatchupRules.pressureThrowPenalty
                + offensiveCall.aggression * MatchupRules.aggressionThrowBonus,
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
        let air = offensiveCall.passDepth.airYards
        let (afterCatch, pursuitRecord) = yardsAfterContact(
            carrier: target.element.receiver, pursuit: assignment.pursuit,
            aggression: offensiveCall.aggression, homeFieldAdvantage: homeFieldAdvantage, rng: &rng
        )
        if let pursuitRecord { matchups.append(pursuitRecord) }
        let gained = air + afterCatch
        return finish(gained: gained, situation: situation, elapsed: elapsed, matchups: matchups,
                      carrier: target.element.receiver, passer: passer,
                      target: target.element.receiver, rng: &rng)
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

        guard let carrier = assignment.carrier else {
            return SnapOutcome(result: .gain, yards: 0,
                               secondsElapsed: rules.inBoundsPlaySeconds,
                               matchups: matchups)
        }

        let (broken, pursuitRecord) = yardsAfterContact(
            carrier: carrier, pursuit: assignment.pursuit, aggression: offensiveCall.aggression,
            homeFieldAdvantage: homeFieldAdvantage, rng: &rng
        )
        if let pursuitRecord { matchups.append(pursuitRecord) }

        let outside = offensiveCall.runGap.isOutside ? MatchupRules.outsideRunVariance : 1.0
        let gained = Int((lane * MatchupRules.laneYardScale * outside).rounded()) + broken
        return finish(gained: gained, situation: situation,
                      elapsed: rules.inBoundsPlaySeconds, matchups: matchups,
                      carrier: carrier, passer: nil, target: nil, rng: &rng)
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
        rng: inout SeededRandom
    ) -> (yards: Int, record: MatchupRecord?) {
        guard let tackler = pursuit.first else { return (0, nil) }
        var yards = 0
        var record: MatchupRecord?
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
                record = MatchupRecord(kind: .carrierVersusPursuit, attackerID: carrier.id,
                                       defenderID: tackler.id, leverage: leverage)
            }
            guard leverage > MatchupRules.breakTackleThreshold else { break }
            yards += MatchupRules.brokenTackleYards * (attempt + 1)
        }
        return (yards, record)
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
        let difficulty = Rating(MatchupRules.fieldGoalDifficulty(distanceYards: distance))
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
                               matchups: matchups, ballCarrierID: carrier.id, passerID: passer?.id,
                               targetID: target?.id)
        }
        if gained >= situation.yardsToGoal {
            return SnapOutcome(result: .touchdown, yards: situation.yardsToGoal,
                               secondsElapsed: elapsed, matchups: matchups,
                               ballCarrierID: carrier.id, passerID: passer?.id, targetID: target?.id)
        }
        if situation.yardLine + gained <= 0 {
            return SnapOutcome(result: .safety, yards: -situation.yardLine, secondsElapsed: elapsed,
                               matchups: matchups, ballCarrierID: carrier.id, passerID: passer?.id,
                               targetID: target?.id)
        }
        return SnapOutcome(result: .gain, yards: gained, secondsElapsed: elapsed,
                           matchups: matchups, ballCarrierID: carrier.id, passerID: passer?.id,
                           targetID: target?.id)
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
