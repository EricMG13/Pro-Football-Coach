import SwiftUI
import FootballSimCore
#if canImport(UIKit)
import UIKit
#endif

/// "On the Field" — the all-22 mode.
///
/// Portrait, vertical field, one thumb. You drag back from the quarterback to aim and release to
/// throw; you swipe to juke, dive or go down. Every player on the field is a real position
/// computed from real ratings, and the indicator over a receiver tells the truth about his
/// separation — a limited passer is told about it late, which is the difference you feel when
/// you upgrade the position.
struct ArcadeFieldView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.teamTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var model: ArcadeGameModel?
    @State private var aimPoint: FieldPoint?
    @State private var showsQuitConfirmation = false
    @State private var showsTargetList = false

    let game: ScheduledGame

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    content(model)
                } else {
                    ProgressView("Warming up…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(Color.pageBackground)
            .navigationTitle("On the Field")
            .navigationBarTitleDisplayModeCompat()
            .toolbar {
                // The destructive action is deliberately not in the cancellation slot: the
                // top-left corner is where a player taps to back out, and it used to hand the
                // rest of their game to the simulator with no way back.
                ToolbarItem(placement: .primaryAction) {
                    Button("Sim to Final") { showsQuitConfirmation = true }
                }
            }
            .confirmationDialog(
                "Hand the rest of this game to the simulator?",
                isPresented: $showsQuitConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sim to Final", role: .destructive) { finishGame() }
                Button("Keep Playing", role: .cancel) {}
            } message: {
                Text("The result will be decided for you. This cannot be undone.")
            }
        }
        .onAppear(perform: setUp)
    }

    private func setUp() {
        guard model == nil,
              let league = app.league,
              let team = league.userTeam,
              let opponentID = game.opponent(of: league.userTeamID),
              let opponent = league.team(id: opponentID) else { return }
        let created = ArcadeGameModel(
            team: team,
            opponent: opponent,
            isHome: game.homeTeamID == league.userTeamID,
            game: game,
            league: league
        )
        created.start()
        model = created
    }

    private func finishGame() {
        guard let model else { return dismiss() }
        model.simulateRest()
        commit(model)
    }

    private func commit(_ model: ArcadeGameModel) {
        guard let record = model.record else { return dismiss() }
        app.mutate { $0.rng = model.game.currentRNG }
        app.advanceWeek(userGameResult: record)
        dismiss()
    }

    // MARK: - Content

    @ViewBuilder
    private func content(_ model: ArcadeGameModel) -> some View {
        VStack(spacing: 0) {
            scoreboard(model)
            field(model)
                .frame(maxHeight: .infinity)

            switch model.phase {
            case .callingPlay: playbook(model)
            case .live: liveControls(model)
            case .kicking: kickMeter(model)
            case .showingResult(let summary): resultCard(model, summary: summary)
            case .watchingDefense: defenseCard(model)
            case .finished: finishedCard(model)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func scoreboard(_ model: ArcadeGameModel) -> some View {
        let situation = model.situation
        return HStack(spacing: Layout.medium) {
            VStack(spacing: 2) {
                Text("\(model.userScore)")
                    .font(.system(.title, design: .rounded, weight: .heavy))
                    .monospacedDigit()
                Text("YOU").font(.caption2.weight(.bold)).opacity(0.8)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 2) {
                Text(clockLabel(quarter: model.quarter, seconds: model.clockRemaining))
                    .font(.headline.monospacedDigit())
                Text(
                    model.isUserOnOffense
                        ? "\(ordinal(situation.down)) & \(situation.distance)"
                        : "Opposition ball"
                )
                .font(.caption)
                .opacity(0.85)
            }

            VStack(spacing: 2) {
                Text("\(model.opponentScore)")
                    .font(.system(.title, design: .rounded, weight: .heavy))
                    .monospacedDigit()
                Text("OPP").font(.caption2.weight(.bold)).opacity(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(.white)
        .padding(Layout.medium)
        .frame(maxWidth: .infinity)
        .background(theme.gradient)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(model.userScore) to \(model.opponentScore), "
                + "\(clockLabel(quarter: model.quarter, seconds: model.clockRemaining))"
        )
    }

    /// The playing surface, and every gesture that lives on it.
    private func field(_ model: ArcadeGameModel) -> some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                if let frame = model.currentFrame {
                    FieldCanvas(
                        frame: frame,
                        teamColor: theme.primary,
                        opponentColor: Color.white.opacity(0.55),
                        yardsToGain: model.situation.distance,
                        showsIndicators: model.phase == .live
                    )
                } else {
                    RoundedRectangle(cornerRadius: Layout.chipRadius)
                        .fill(Color(hex: OpennessTier.turfHex))
                }
            }
            .contentShape(Rectangle())
            .gesture(fieldGesture(model, size: size))
            // The canvas draws shapes, which VoiceOver cannot read. The target list is the
            // equivalent path, and it is a real way to play rather than a consolation.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Field")
            .accessibilityValue(accessibilitySummary(model))
            .accessibilityHint("Use the receivers list below to throw.")
        }
        .padding(Layout.small)
    }

    private func fieldGesture(_ model: ArcadeGameModel, size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard model.phase == .live else { return }
                guard let frame = model.currentFrame else { return }
                if case .carrying = frame.phase { return }
                model.beginAiming()
                let point = fieldPoint(from: value.location, size: size, frame: frame)
                aimPoint = point
                model.aim(at: point)
            }
            .onEnded { value in
                guard model.phase == .live, let frame = model.currentFrame else { return }
                defer { aimPoint = nil }

                if case .carrying = frame.phase {
                    // Carrier control: sideways jukes, up to dive, down to go down.
                    let dx = value.translation.width
                    let dy = value.translation.height
                    if abs(dx) > abs(dy), abs(dx) > 20 {
                        model.juke(dx > 0 ? 1 : -1)
                    } else if dy < -24 {
                        model.dive()
                    } else if dy > 24 {
                        model.stall()
                    }
                    return
                }

                // A short flick forward from the pocket is a scramble, not a throw.
                if value.translation.height < -70, abs(value.translation.width) < 40 {
                    model.scramble()
                    return
                }
                model.release()
            }
    }

    /// Turns a touch into a spot on the field, using the same camera the canvas drew with.
    private func fieldPoint(from location: CGPoint, size: CGSize, frame: FieldFrame) -> FieldPoint {
        let window = ArcadeTuning.cameraWindowYards
        let camera = max(-8, frame.ballPoint.depth - window * 0.3)
        let depth = camera + (1 - location.y / max(1, size.height)) * window
        let lateral = (location.x / max(1, size.width) - 0.5) / 0.46
        return FieldPoint(depth: depth, lateral: min(1, max(-1, lateral)))
    }

    private func accessibilitySummary(_ model: ArcadeGameModel) -> String {
        let open = model.targets.filter { $0.state == .open }.count
        return "\(model.targets.count) receivers, \(open) open"
    }

    // MARK: - Controls

    private func playbook(_ model: ArcadeGameModel) -> some View {
        VStack(spacing: Layout.small) {
            Text("Call the play")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: Layout.small
            ) {
                ForEach(OffensivePlay.standardCalls, id: \.self) { call in
                    Button { model.snap(call) } label: {
                        Text(call.displayName)
                            .font(.caption.weight(.medium))
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                }
            }

            if model.situation.down == 4 {
                HStack(spacing: Layout.small) {
                    if model.isInFieldGoalRange {
                        Button { model.snap(.fieldGoal) } label: {
                            Label(
                                "Field Goal · \(model.fieldGoalDistance) yds",
                                systemImage: "figure.australian.football"
                            )
                            .font(.caption.weight(.medium))
                            .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Button { model.snap(.punt) } label: {
                        Label("Punt", systemImage: "arrow.up.forward")
                            .font(.caption.weight(.medium))
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(Layout.medium)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    private func liveControls(_ model: ArcadeGameModel) -> some View {
        VStack(spacing: Layout.small) {
            HStack {
                Text(statusLabel(model))
                    .font(.caption.weight(model.currentFrame?.sackWarningActive == true ? .bold : .regular))
                    .foregroundStyle(
                        model.currentFrame?.sackWarningActive == true ? Color.warningText : .secondary
                    )
                Spacer()
                if model.audiblesRemaining > 0 {
                    Button("Audible (\(model.audiblesRemaining))") { model.audible() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                Button("Hand Off") { model.handOff() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }

            // The gesture-free way to play the snap. Every receiver, what he is doing, and
            // whether he is open — spoken, tappable, and exactly as authoritative as the field.
            if showsTargetList || UIAccessibilityIsVoiceOverRunningCompat() {
                ForEach(model.targets, id: \.player.id) { target in
                    Button { model.throwTo(target.player.id) } label: {
                        HStack {
                            Text(target.player.athlete.name)
                                .font(.caption.weight(.medium))
                            Spacer()
                            Text(target.state.displayName)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(color(for: target.state))
                        }
                        .frame(minHeight: 36)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("\(target.player.athlete.name), \(target.state.displayName)")
                    .accessibilityHint("Throws to him.")
                }
            } else {
                Button("Show Receivers") { showsTargetList = true }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .font(.caption2)
            }
        }
        .padding(Layout.medium)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    private func color(for state: OpennessState) -> Color {
        OpennessTier(state).textColor
    }

    private func statusLabel(_ model: ArcadeGameModel) -> String {
        guard let frame = model.currentFrame else { return "Read the routes" }
        if case .carrying = frame.phase { return "Swipe to juke, up to dive, down to go down" }
        if case .ballInAir = frame.phase { return "In the air…" }
        if frame.sackWarningActive { return "Pressure — get rid of it" }
        return "Drag to aim, release to throw"
    }

    private func kickMeter(_ model: ArcadeGameModel) -> some View {
        VStack(spacing: Layout.medium) {
            Text(model.meterStage == .power ? "Tap to set power" : "Tap to set aim")
                .font(.subheadline.weight(.semibold))

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.2))
                    Capsule()
                        .fill(Color.green.opacity(0.35))
                        .frame(width: proxy.size.width * 0.18)
                        .offset(x: proxy.size.width * 0.41)
                    Capsule()
                        .fill(model.meterStage == .power ? Color.blue : Color.orange)
                        .frame(width: 6)
                        .offset(x: proxy.size.width * model.meterValue - 3)
                }
            }
            .frame(height: 26)
            .accessibilityLabel(model.meterStage == .power ? "Power meter" : "Aim meter")

            Button { model.tapMeter() } label: {
                Text(model.meterStage == .power ? "Set Power" : "Kick")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)

            Text("\(model.fieldGoalDistance)-yard attempt")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Layout.medium)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    private func resultCard(_ model: ArcadeGameModel, summary: String) -> some View {
        VStack(spacing: Layout.small) {
            Text(summary)
                .font(.subheadline)
                .multilineTextAlignment(.center)
            Button("Next Play") { model.continueAfterResult() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
        .padding(Layout.medium)
        .frame(maxWidth: .infinity)
        .background(.bar)
        .accessibilityElement(children: .contain)
    }

    /// The opposition's snap, watched rather than read. This is the genre's loudest complaint,
    /// answered: your call, their play, resolved on the same field you attack on.
    private func defenseCard(_ model: ArcadeGameModel) -> some View {
        VStack(spacing: Layout.small) {
            Text("Their ball — \(model.defensiveCall.displayName)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: Layout.small
            ) {
                ForEach(DefensivePlay.allCases, id: \.self) { call in
                    Button { model.setDefensiveCall(call) } label: {
                        Text(call.displayName)
                            .font(.caption2.weight(.medium))
                            .frame(maxWidth: .infinity, minHeight: 36)
                    }
                    .buttonStyle(model.defensiveCall == call ? .borderedProminent : .bordered)
                }
            }
            // The read. A tilt is a guess: right is worth something, wrong costs the same, and
            // neither is worth as much as a snap you play with the ball in your hands.
            HStack(spacing: Layout.tight) {
                ForEach(CoverageShade.allCases, id: \.self) { shade in
                    Button { model.setShade(shade) } label: {
                        Text(shade.displayName)
                            .font(.caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity, minHeight: 32)
                    }
                    .buttonStyle(
                        model.defensiveRead.shade == shade ? .borderedProminent : .bordered
                    )
                    .accessibilityLabel("Shade \(shade.displayName)")
                }
            }

            Button("Skip Ahead") { model.skipToNextUserSnap() }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
        }
        .padding(Layout.medium)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    private func finishedCard(_ model: ArcadeGameModel) -> some View {
        VStack(spacing: Layout.small) {
            Text("Final").font(.headline)
            if let record = model.record, let league = app.league {
                Text("\(record.score(for: league.userTeamID)) – \(record.opponentScore(for: league.userTeamID))")
                    .font(.system(.title, design: .rounded, weight: .heavy))
                    .monospacedDigit()
            }
            Button("Finish Week") { commit(model) }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
        .padding(Layout.medium)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    private func clockLabel(quarter: Int, seconds: Int) -> String {
        let label = quarter <= 4 ? "Q\(quarter)" : "OT"
        return "\(label) \(Format.clock(seconds))"
    }

    private func ordinal(_ value: Int) -> String {
        switch value {
        case 1: "1st"
        case 2: "2nd"
        case 3: "3rd"
        default: "4th"
        }
    }
}

/// VoiceOver detection that also type-checks on macOS, where the package is compile-verified.
func UIAccessibilityIsVoiceOverRunningCompat() -> Bool {
    #if os(iOS)
    return UIAccessibility.isVoiceOverRunning
    #else
    return false
    #endif
}

extension View {
    /// `navigationBarTitleDisplayMode` is iOS-only; the package type-checks on macOS too.
    @ViewBuilder
    func navigationBarTitleDisplayModeCompat() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}
