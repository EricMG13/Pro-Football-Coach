import Foundation

/// Turns one play call, against one defensive call, into yards and a box score.
///
/// This is where player ratings actually cash out: the matchup between the units involved
/// shifts the mean, the defensive call bends the distribution, and the tails supply the
/// explosive plays and the disasters.
public enum PlayResolver {

    public struct Outcome: Sendable {
        public let category: PlayCategory
        public let yards: Int
        public let completed: Bool
        public let isTurnover: Bool
        public let description: String
        public let statDeltas: [UUID: StatLine]
        /// Which team total these yards belong in. Distinct from `category`, because a
        /// fumbled run is categorised as a turnover but its yards are still rushing yards.
        public let yardageKind: PlayCategory?

        init(
            category: PlayCategory,
            yards: Int,
            completed: Bool = true,
            isTurnover: Bool = false,
            description: String,
            statDeltas: [UUID: StatLine],
            yardageKind: PlayCategory? = nil
        ) {
            self.category = category
            self.yards = yards
            self.completed = completed
            self.isTurnover = isTurnover
            self.description = description
            self.statDeltas = statDeltas
            self.yardageKind = yardageKind ?? (category == .turnover ? nil : category)
        }
    }

    public static func resolve(
        call: OffensivePlay,
        defensiveCall: DefensivePlay,
        tempo: Tempo,
        offense: inout TeamSnapshot,
        defense: inout TeamSnapshot,
        situation: GameSituation,
        homeFieldForOffense: Bool,
        execution: PlayExecution = .neutral,
        rng: inout SeededRandom
    ) -> Outcome {
        let profile = PlayMatrix.profile(for: call)
        let adjustment = PlayMatrix.adjustment(offense: call, defense: defensiveCall)
        let weights = PlayMatrix.matchupWeights(for: call)

        var offenseRating = offense.weightedRating(weights.offense)
            + offense.coordinatorBonus(.offensiveCoordinator)
        if homeFieldForOffense { offenseRating += PlayMatrix.homeFieldRatingBonus }
        let defenseRating = defense.weightedRating(weights.defense)
            + defense.coordinatorBonus(.defensiveCoordinator)
        let delta = offenseRating - defenseRating

        return call.isPass
            ? resolvePass(
                call: call, profile: profile, adjustment: adjustment, delta: delta, tempo: tempo,
                offense: &offense, defense: &defense, situation: situation,
                execution: execution, rng: &rng
            )
            : resolveRun(
                call: call, profile: profile, adjustment: adjustment, delta: delta, tempo: tempo,
                offense: &offense, defense: &defense, situation: situation,
                execution: execution, rng: &rng
            )
    }

    // MARK: - Pass

    private static func resolvePass(
        call: OffensivePlay,
        profile: PlayProfile,
        adjustment: DefensiveAdjustment,
        delta: Double,
        tempo: Tempo,
        offense: inout TeamSnapshot,
        defense: inout TeamSnapshot,
        situation: GameSituation,
        execution: PlayExecution,
        rng: inout SeededRandom
    ) -> Outcome {
        guard let quarterback = offense.player(.qb, slot: 0) else {
            return Outcome(category: .pass, yards: 0, completed: false,
                           description: "The pass falls incomplete.", statDeltas: [:])
        }

        // Protection quality decides how often the play never gets started.
        let protection = (offense.unitRating(.ol) - defense.unitRating(.dl)) * 0.004
        let sackChance = max(
            0.005,
            profile.sackRate * adjustment.sackMultiplier * execution.sackMultiplier - protection
        )
        if rng.chance(sackChance) {
            let loss = -rng.int(in: 3...9)
            let sacker = pickDefender(&defense, shares: PlayMatrix.sackShares, rng: &rng)
            var deltas: [UUID: StatLine] = [:]
            var qbLine = StatLine()
            qbLine.sacksTaken = 1
            deltas[quarterback.id] = qbLine
            if let sacker {
                var line = StatLine()
                line.sacks = 1
                line.tackles = 1
                deltas[sacker.id] = line
            }
            return Outcome(
                category: .sack,
                yards: loss,
                completed: false,
                description: "\(sacker?.name ?? "The defense") sacks \(quarterback.name) for \(-loss) yards.",
                statDeltas: deltas
            )
        }

        let receiver = pickReceiver(&offense, rng: &rng)

        // Accuracy and coverage decide the catch; the throw itself is the QB's craft.
        let accuracyEdge = Double(quarterback.ratings[.throwAccuracy] - 70) * 0.0035
        let receiverEdge = receiver.map { Double($0.ratings[.catching] - 70) * 0.0020 } ?? 0
        let coverageEdge = Double(defense.unitRating(.cb) - 70) * -0.0018
        var completionChance = profile.completionRate
            + adjustment.completionDelta
            + delta * PlayMatrix.completionPerRatingPoint
            + accuracyEdge + receiverEdge + coverageEdge
            + execution.completionModifier
        completionChance = min(0.94, max(0.08, completionChance))

        let interceptionChance = max(
            0.002,
            profile.interceptionRate
                * adjustment.interceptionMultiplier
                * execution.interceptionMultiplier
                - Double(quarterback.ratings[.awareness] - 70) * 0.00035
        )

        if rng.chance(interceptionChance) {
            let defender = pickDefender(&defense, shares: PlayMatrix.interceptionShares, rng: &rng)
            var deltas: [UUID: StatLine] = [:]
            var qbLine = StatLine()
            qbLine.passAttempts = 1
            qbLine.interceptionsThrown = 1
            deltas[quarterback.id] = qbLine
            if let defender {
                var line = StatLine()
                line.interceptions = 1
                line.passesDefended = 1
                deltas[defender.id] = line
            }
            if let receiver {
                var line = StatLine()
                line.targets = 1
                deltas[receiver.id] = line
            }
            let returnYards = rng.int(in: 0...18)
            return Outcome(
                category: .turnover,
                yards: returnYards,
                completed: false,
                isTurnover: true,
                description: "\(quarterback.name)'s pass is intercepted by \(defender?.name ?? "the defense").",
                statDeltas: deltas
            )
        }

        guard rng.chance(completionChance) else {
            var deltas: [UUID: StatLine] = [:]
            var qbLine = StatLine()
            qbLine.passAttempts = 1
            deltas[quarterback.id] = qbLine
            if let receiver {
                var line = StatLine()
                line.targets = 1
                deltas[receiver.id] = line
            }
            let defender = pickDefender(&defense, shares: PlayMatrix.interceptionShares, rng: &rng)
            if let defender, rng.chance(0.35) {
                var line = deltas[defender.id] ?? StatLine()
                line.passesDefended = 1
                deltas[defender.id] = line
            }
            return Outcome(
                category: .pass,
                yards: 0,
                completed: false,
                description: "\(quarterback.name)'s pass to \(receiver?.name ?? "his receiver") falls incomplete.",
                statDeltas: deltas
            )
        }

        var yards = drawYards(
            profile: profile,
            adjustment: adjustment,
            delta: delta,
            tempo: tempo,
            call: call,
            rng: &rng
        )
        // Yards after catch belong to the receiver's legs.
        if let receiver {
            let elusiveness = Double(receiver.ratings[.breakTackle] - 70) * 0.05
                + Double(receiver.ratings[.speed] - 70) * 0.04
            yards += Int((elusiveness + execution.yardsModifier).rounded())
        }
        yards = clampToField(yards: yards, situation: situation, allowLoss: true)

        var deltas: [UUID: StatLine] = [:]
        var qbLine = StatLine()
        qbLine.passAttempts = 1
        qbLine.completions = 1
        qbLine.passingYards = yards
        deltas[quarterback.id] = qbLine
        if let receiver {
            var line = StatLine()
            line.targets = 1
            line.receptions = 1
            line.receivingYards = yards
            deltas[receiver.id] = line
        }
        if let tackler = pickDefender(&defense, shares: PlayMatrix.tackleShares, rng: &rng),
           situation.yardLine + yards < LeagueRules.fieldLengthYards {
            var line = deltas[tackler.id] ?? StatLine()
            line.tackles += 1
            deltas[tackler.id] = line
        }

        let scored = situation.yardLine + yards >= LeagueRules.fieldLengthYards
        if scored {
            deltas[quarterback.id]?.passingTouchdowns = 1
            if let receiver { deltas[receiver.id]?.receivingTouchdowns = 1 }
        }

        return Outcome(
            category: .pass,
            yards: yards,
            description: "\(quarterback.name) finds \(receiver?.name ?? "his receiver") for \(yards) yards.",
            statDeltas: deltas
        )
    }

    // MARK: - Run

    private static func resolveRun(
        call: OffensivePlay,
        profile: PlayProfile,
        adjustment: DefensiveAdjustment,
        delta: Double,
        tempo: Tempo,
        offense: inout TeamSnapshot,
        defense: inout TeamSnapshot,
        situation: GameSituation,
        execution: PlayExecution,
        rng: inout SeededRandom
    ) -> Outcome {
        let carrier = pickCarrier(&offense, rng: &rng)
        var yards = drawYards(
            profile: profile,
            adjustment: adjustment,
            delta: delta,
            tempo: tempo,
            call: call,
            rng: &rng
        )
        if let carrier {
            let burst = Double(carrier.ratings[.breakTackle] - 70) * 0.035
                + Double(carrier.ratings[.vision] - 70) * 0.030
                + Double(carrier.ratings[.speed] - 70) * 0.020
            yards += Int((burst + execution.yardsModifier).rounded())
        }
        yards = clampToField(yards: yards, situation: situation, allowLoss: true)

        var deltas: [UUID: StatLine] = [:]
        if let carrier {
            var line = StatLine()
            line.carries = 1
            line.rushingYards = yards
            if situation.yardLine + yards >= LeagueRules.fieldLengthYards {
                line.rushingTouchdowns = 1
            }
            deltas[carrier.id] = line
        }

        // Fumble: the defence takes it away rather than the offence merely dropping it.
        let fumbleChance = max(
            0.001,
            profile.fumbleRate * execution.fumbleMultiplier
                - (carrier.map { Double($0.ratings[.strength] - 70) * 0.00008 } ?? 0)
        )
        if rng.chance(fumbleChance) {
            let defender = pickDefender(&defense, shares: PlayMatrix.tackleShares, rng: &rng)
            if let carrier { deltas[carrier.id]?.fumbles = 1 }
            if let defender {
                var line = deltas[defender.id] ?? StatLine()
                line.forcedFumbles += 1
                line.fumbleRecoveries += 1
                line.tackles += 1
                deltas[defender.id] = line
            }
            return Outcome(
                category: .turnover,
                // Same figure the carrier's line carries: clamping only one side of this made
                // team rushing yards disagree with the sum of its players'.
                yards: yards,
                isTurnover: true,
                description: "\(carrier?.name ?? "The runner") fumbles — recovered by \(defender?.name ?? "the defense").",
                statDeltas: deltas,
                yardageKind: .run
            )
        }

        if let tackler = pickDefender(&defense, shares: PlayMatrix.tackleShares, rng: &rng),
           situation.yardLine + yards < LeagueRules.fieldLengthYards {
            var line = deltas[tackler.id] ?? StatLine()
            line.tackles += 1
            deltas[tackler.id] = line
        }

        return Outcome(
            category: .run,
            yards: yards,
            description: yards >= 0
                ? "\(carrier?.name ?? "The back") runs for \(yards) yards."
                : "\(carrier?.name ?? "The back") is dropped for a \(-yards)-yard loss.",
            statDeltas: deltas
        )
    }

    // MARK: - Yardage

    private static func drawYards(
        profile: PlayProfile,
        adjustment: DefensiveAdjustment,
        delta: Double,
        tempo: Tempo,
        call: OffensivePlay,
        rng: inout SeededRandom
    ) -> Int {
        let mean = profile.meanYards
            + adjustment.yardsDelta
            + delta * PlayMatrix.yardsPerRatingPoint(for: call)
            + tempo.yardageModifier
        var yards = rng.gaussian(mean: mean, sd: profile.yardsSD)

        // The fat tail: most plays are ordinary, a few break completely open.
        let explosiveChance = profile.explosiveRate * adjustment.explosiveMultiplier
        if rng.chance(explosiveChance) {
            yards += profile.explosiveBonusYards * (0.6 + rng.double01() * 1.4)
        }
        return Int(yards.rounded())
    }

    /// Keeps a play inside the field: you can't gain past the goal line or lose past your own.
    private static func clampToField(
        yards: Int,
        situation: GameSituation,
        allowLoss: Bool
    ) -> Int {
        let maxGain = LeagueRules.fieldLengthYards - situation.yardLine
        let maxLoss = allowLoss ? -situation.yardLine : 0
        return min(max(yards, maxLoss), maxGain)
    }

    // MARK: - Unit ratings and player selection

    private static func pickReceiver(
        _ team: inout TeamSnapshot,
        rng: inout SeededRandom
    ) -> Player? {
        pickByShares(&team, shares: PlayMatrix.targetShares, rng: &rng)
    }

    private static func pickCarrier(
        _ team: inout TeamSnapshot,
        rng: inout SeededRandom
    ) -> Player? {
        pickByShares(&team, shares: PlayMatrix.carryShares, rng: &rng)
    }

    /// Picks a specific player from a share table, falling back through the depth chart when
    /// the intended man is hurt.
    private static func pickByShares(
        _ team: inout TeamSnapshot,
        shares: [(position: Position, slot: Int, share: Double)],
        rng: inout SeededRandom
    ) -> Player? {
        var roll = rng.double01() * shares.reduce(0) { $0 + $1.share }
        for entry in shares {
            roll -= entry.share
            if roll <= 0 {
                if let player = team.player(entry.position, slot: entry.slot) { return player }
                break
            }
        }
        return team.player(.wr, slot: 0)
    }

    /// Picks a defender by position share, then weights toward the better players at that spot.
    private static func pickDefender(
        _ team: inout TeamSnapshot,
        shares: [(position: Position, share: Double)],
        rng: inout SeededRandom
    ) -> Player? {
        var roll = rng.double01() * shares.reduce(0) { $0 + $1.share }
        var chosen: Position = .lb
        for entry in shares {
            roll -= entry.share
            if roll <= 0 { chosen = entry.position; break }
        }
        // Squaring the draw weights the pick toward the top of the depth chart: starters are
        // on the field more and make more plays than their backups.
        let slot = Int(rng.double01() * rng.double01() * Double(chosen.starterCount))
        return team.player(chosen, slot: slot)
    }
}
