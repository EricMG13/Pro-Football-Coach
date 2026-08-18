import SwiftUI

/// The one place raw motion vocabulary may appear in `ProFootballCoachUI`.
///
/// Every timed transition elsewhere in the module routes through `.coachWorldAnimation(_:value:)`
/// or `.coachWorldPulse(active:)`, which is what makes an off-token duration, an un-reduced
/// animation, or a second easing curve **unrepresentable** rather than merely something a review
/// might catch. `04` section 6.7 is the canonical register these durations are drawn from, and this
/// file is the only place that register's raw vocabulary — `Animation.timingCurve`,
/// `withAnimation`, `.repeatForever` — is permitted to appear. A source scan asserts that; see
/// `Tests/SimTests/Suites/MotionContractTests.swift`.
///
/// `04:826`: Reduce Motion replaces travel, reveal and field animation with discrete state changes.
/// Both modifiers below read `\.accessibilityReduceMotion` themselves, so a call site cannot forget
/// the branch — there is only one way to call either of them, and it is already reduced-motion-safe.

/// `04` section 6.7's one shared curve, applied to a duration. `CoachWorldTokens.Motion` holds only
/// data — the named durations, as plain numbers — precisely so that constructing an actual
/// `Animation` from them, which is behaviour, stays confined to this file rather than requiring an
/// exemption on the token file every view already reads.
private func standard(_ duration: Double) -> Animation {
    .timingCurve(0.32, 0.72, 0, 1, duration: duration)
}

private struct CoachWorldAnimationModifier<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let duration: Double
    let value: Value

    func body(content: Content) -> some View {
        content.animation(
            reduceMotion ? nil : standard(duration),
            value: value
        )
    }
}

private struct CoachWorldPulseModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(pulsing ? CoachWorldTokens.Motion.disabledOpacity : 1)
            .onAppear {
                // `04:448` names the live dot's pulse as one of the three animations Reduce Motion
                // must remove outright, not slow: this guard is the whole of that requirement.
                guard !reduceMotion else { return }
                withAnimation(
                    standard(CoachWorldTokens.Motion.pulse).repeatForever(autoreverses: true)
                ) {
                    pulsing = true
                }
            }
    }
}

extension View {
    /// Animates `value` changing, over `duration` seconds on `04` section 6.7's one shared curve.
    /// `duration` should be one of `CoachWorldTokens.Motion`'s named durations — a literal here is
    /// exactly the off-token magic number `04` section 6.7 exists to prevent, and is why the
    /// `04b`-audit token-sync gate treats a bare number at this call site as an offender.
    func coachWorldAnimation(_ duration: Double, value: some Equatable) -> some View {
        modifier(CoachWorldAnimationModifier(duration: duration, value: value))
    }

    /// The live-snap indicator's pulse: an indefinitely repeating dim, starting when the view
    /// appears. Reduce Motion removes the animation entirely rather than slowing it — the marked
    /// view stays at full opacity, still legible as "live" without the motion.
    func coachWorldPulse() -> some View {
        modifier(CoachWorldPulseModifier())
    }
}
