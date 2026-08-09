import Foundation

/// What the indicator over a receiver says.
public enum OpennessState: String, Sendable, Equatable, CaseIterable, Codable {
    /// Green. Clear, and staying clear long enough to throw at.
    case open
    /// Orange. The "maybe" — either the window is small, or it is open now and closing fast.
    case contested
    /// Red. Covered.
    case covered

    public var displayName: String {
        switch self {
        case .open: "Open"
        case .contested: "Contested"
        case .covered: "Covered"
        }
    }
}

/// Reads the geometry and says whether a receiver is open.
///
/// The colour is never a lie. That was a deliberate choice over the alternative — letting a poor
/// quarterback show a false green — because a bad beat you could not have read is indis-
/// tinguishable from a bug, and the mode lives or dies on the player trusting what is drawn.
public enum Openness {

    /// The truth about a receiver right now.
    ///
    /// Closing speed is what makes the orange band mean something. Three yards of separation
    /// with a safety bearing down is not a throw, and a snapshot of distance alone cannot say so.
    public static func state(separationYards: Double, closingSpeed: Double) -> OpennessState {
        if separationYards < ArcadeTuning.coveredSeparationYards { return .covered }
        if separationYards < ArcadeTuning.openSeparationYards { return .contested }
        return closingSpeed > ArcadeTuning.closingSpeedThreshold ? .contested : .open
    }

    /// The truth for every eligible receiver on the field.
    public static func survey(
        offense: [FieldedPlayer],
        defenders: [FieldedPlayer]
    ) -> [UUID: OpennessState] {
        var result: [UUID: OpennessState] = [:]
        for receiver in offense {
            guard case .receiver = receiver.role else { continue }
            guard let nearest = Coverage.nearestDefender(to: receiver, defenders: defenders) else {
                result[receiver.id] = .open
                continue
            }
            let closing = closingSpeed(
                defender: nearest.defender.point,
                defenderVelocity: nearest.defender.velocity,
                receiver: receiver.point,
                receiverVelocity: receiver.velocity
            )
            result[receiver.id] = state(separationYards: nearest.separation, closingSpeed: closing)
        }
        return result
    }
}

/// Delays what the quarterback is shown, by an amount his awareness sets.
///
/// This is the whole of how awareness lives in the hand. A 99 sees the field almost live; a 40
/// is told about a window a beat late, and a window that flickers open for less than his latency
/// he simply never sees. Reading the field yourself is how you play a limited passer — which is
/// the point, because the alternative designs either lie to the player or gate the feature off
/// behind a rating cliff.
public struct IndicatorFeed: Sendable {
    /// A state seen but not yet believed.
    private struct Candidate: Sendable {
        var state: OpennessState
        var since: Double
    }

    public let latency: Double
    private var shown: [UUID: OpennessState] = [:]
    private var candidates: [UUID: Candidate] = [:]
    private var hasSeeded = false

    public init(awareness: Int) {
        latency = ArcadeTuning.indicatorLatency(awareness)
    }

    public init(latency: Double) {
        self.latency = Swift.max(0, latency)
    }

    /// Folds in the current truth. The first call is taken at face value — the alignment is
    /// visible before the snap, so there is nothing to be late about yet.
    public mutating func update(truth: [UUID: OpennessState], now: Double) {
        guard hasSeeded else {
            shown = truth
            for (id, state) in truth { candidates[id] = Candidate(state: state, since: now) }
            hasSeeded = true
            return
        }

        for (id, state) in truth {
            if shown[id] == state {
                // Already believed; nothing pending.
                candidates[id] = Candidate(state: state, since: now)
                continue
            }
            if let candidate = candidates[id], candidate.state == state {
                if now - candidate.since >= latency { shown[id] = state }
            } else {
                candidates[id] = Candidate(state: state, since: now)
            }
        }

        // Receivers who left the play stop being reported.
        for id in shown.keys where truth[id] == nil {
            shown.removeValue(forKey: id)
            candidates.removeValue(forKey: id)
        }
    }

    public func state(for id: UUID) -> OpennessState? { shown[id] }

    public var allStates: [UUID: OpennessState] { shown }
}
