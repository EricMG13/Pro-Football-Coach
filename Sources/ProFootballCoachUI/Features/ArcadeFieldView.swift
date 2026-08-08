import SwiftUI
import FootballSimCore

/// The on-field mode: call a play, then throw it yourself.
///
/// Aiming is the whole interaction. You drag back from the quarterback, a trajectory arc grows
/// toward where the ball will land, and you release. How much of that arc you can see is set by
/// your quarterback's accuracy rating, so a poor passer genuinely leaves you guessing — which is
/// the point where the roster and the controls meet.
struct ArcadeFieldView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.teamTheme) private var theme

    @State private var model: ArcadeGameModel?
    @State private var aimPoint: CGPoint?

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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sim to Final") { finishGame() }
                }
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
        // Hand the stream back so the rest of the league carries on from where this game left it.
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

            switch model.phase {
            case .callingPlay: playbook(model)
            case .live: liveControls(model)
            case .showingResult(let summary): resultCard(model, summary: summary)
            case .opponentBall: opponentCard(model)
            case .finished: finishedCard(model)
            }

            Spacer(minLength: 0)
        }
        // Pin to the top: without this the stack centres itself and leaves a band of empty
        // space under the navigation bar on a tall phone.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func scoreboard(_ model: ArcadeGameModel) -> some View {
        let situation = model.situation
        return HStack(spacing: Layout.medium) {
            VStack(spacing: 2) {
                Text("\(situation.offenseScore)")
                    .font(.system(.title, design: .rounded, weight: .heavy))
                    .monospacedDigit()
                Text("YOU").font(.caption2.weight(.bold)).opacity(0.8)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 2) {
                Text(clockLabel(situation))
                    .font(.headline.monospacedDigit())
                Text("\(ordinal(situation.down)) & \(situation.distance)")
                    .font(.caption)
                    .opacity(0.85)
            }

            VStack(spacing: 2) {
                Text("\(situation.defenseScore)")
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
    }

    /// The playing surface, and the aiming gesture that lives on it.
    private func field(_ model: ArcadeGameModel) -> some View {
        GeometryReader { proxy in
            let size = proxy.size
            // The view shows 40 yards of field ahead of the line of scrimmage.
            let yardsShown = 40.0
            let scrimmageY = size.height * 0.78

            let quarterbackPoint = fieldPoint(
                depth: -4, lateral: 0, size: size, scrimmageY: scrimmageY, yardsShown: yardsShown
            )

            ZStack {
                turf(size: size, scrimmageY: scrimmageY, yardsShown: yardsShown, situation: model.situation)

                ForEach(model.receivers) { receiver in
                    let spot = fieldPoint(
                        depth: receiver.depth, lateral: receiver.lateral,
                        size: size, scrimmageY: scrimmageY, yardsShown: yardsShown
                    )
                    ZStack {
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 22, height: 22)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                        Text(receiver.position.abbreviation)
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                    .position(spot)
                }

                if model.phase == .live {
                    Circle()
                        .fill(.white)
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(theme.primary, lineWidth: 3))
                        .position(quarterbackPoint)

                    if let aimPoint {
                        TrajectoryArc(
                            from: quarterbackPoint,
                            to: aimPoint,
                            visibleFraction: model.visibleArcFraction
                        )
                        .stroke(
                            .white.opacity(0.9),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 7])
                        )
                        Circle()
                            .strokeBorder(.white, lineWidth: 3)
                            .frame(width: 26, height: 26)
                            .position(aimPoint)
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard model.phase == .live else { return }
                        // The rush starts when the player starts aiming, not at the snap.
                        model.beginAiming()
                        aimPoint = value.location
                    }
                    .onEnded { value in
                        guard model.phase == .live else { return }
                        defer { aimPoint = nil }
                        // Converts the release point back into yards and a sideline offset.
                        let depth = (scrimmageY - value.location.y) / (size.height * 0.72) * yardsShown
                        let lateral = (value.location.x / size.width - 0.5) / 0.42
                        model.throwBall(atDepth: depth, lateral: lateral)
                    }
            )
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: Layout.chipRadius))
        .padding(Layout.small)
    }

    /// Projects a spot on the field — yards downfield and how far toward a sideline — onto the
    /// view. One place so the aiming gesture and the drawn routes cannot disagree.
    private func fieldPoint(
        depth: Double,
        lateral: Double,
        size: CGSize,
        scrimmageY: CGFloat,
        yardsShown: Double
    ) -> CGPoint {
        CGPoint(
            x: size.width * (0.5 + lateral * 0.42),
            y: scrimmageY - (depth / yardsShown) * (size.height * 0.72)
        )
    }

    private func turf(size: CGSize, scrimmageY: CGFloat, yardsShown: Double, situation: GameSituation) -> some View {
        ZStack {
            Rectangle().fill(Color(red: 0.15, green: 0.40, blue: 0.21))

            // A yard line every five yards, brighter every ten.
            ForEach(Array(stride(from: -5, through: Int(yardsShown), by: 5)), id: \.self) { yard in
                let y = scrimmageY - (Double(yard) / yardsShown) * (size.height * 0.72)
                Rectangle()
                    .fill(.white.opacity(yard % 10 == 0 ? 0.35 : 0.18))
                    .frame(height: yard % 10 == 0 ? 2 : 1)
                    .position(x: size.width / 2, y: y)
            }

            // Line of scrimmage and the line to gain.
            Rectangle().fill(.blue).frame(height: 3)
                .position(x: size.width / 2, y: scrimmageY)
            let toGain = scrimmageY - (Double(situation.distance) / yardsShown) * (size.height * 0.72)
            Rectangle().fill(.yellow).frame(height: 3)
                .position(x: size.width / 2, y: toGain)
        }
    }

    // MARK: - Controls

    private func playbook(_ model: ArcadeGameModel) -> some View {
        VStack(spacing: Layout.small) {
            Text("Call the play")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: Layout.small) {
                ForEach(OffensivePlay.standardCalls, id: \.self) { call in
                    Button { model.snap(call) } label: {
                        Text(call.displayName)
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
                Text(pressureLabel(model))
                    .font(.caption.weight(model.pocketFraction < 0.3 ? .bold : .regular))
                    .foregroundStyle(model.pocketFraction < 0.3 ? .red : .secondary)
                Spacer()
                Button("Hand Off") { model.handOff() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            // Pressure bar: when it empties, the rush gets there.
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.2))
                    Capsule()
                        .fill(model.pocketFraction < 0.3 ? Color.red : Color.green)
                        .frame(width: proxy.size.width * model.pocketFraction)
                }
            }
            .frame(height: 8)
            .accessibilityLabel("Pass protection remaining")
        }
        .padding(Layout.medium)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    private func pressureLabel(_ model: ArcadeGameModel) -> String {
        if model.heldSeconds == 0 { return "Read the routes, then drag to aim" }
        return model.pocketFraction < 0.3 ? "Pressure — get rid of it" : "Release to throw"
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
    }

    private func opponentCard(_ model: ArcadeGameModel) -> some View {
        VStack(spacing: Layout.small) {
            Text("The opposition has the ball.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Watch the Drive") { model.continueAfterResult() }
                .buttonStyle(.borderedProminent)
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

    private func clockLabel(_ situation: GameSituation) -> String {
        let quarter = situation.quarter <= 4 ? "Q\(situation.quarter)" : "OT"
        return "\(quarter) \(Format.clock(situation.clockSeconds))"
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

/// The dotted flight path, drawn only as far as the quarterback's accuracy lets you see.
struct TrajectoryArc: Shape {
    let from: CGPoint
    let to: CGPoint
    let visibleFraction: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let clamped = min(1, max(0.1, visibleFraction))
        let steps = 28
        let lastVisible = Int(Double(steps) * clamped)
        // A shallow parabola so the throw reads as a ball in the air rather than a laser.
        let lift = min(90, hypot(to.x - from.x, to.y - from.y) * 0.28)

        for step in 0...lastVisible {
            let t = Double(step) / Double(steps)
            let x = from.x + (to.x - from.x) * t
            let y = from.y + (to.y - from.y) * t - lift * sin(.pi * t)
            let point = CGPoint(x: x, y: y)
            if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }
}
