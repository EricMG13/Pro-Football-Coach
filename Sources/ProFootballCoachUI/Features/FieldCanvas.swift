import SwiftUI
import FootballSimCore

/// The all-22 field.
///
/// Drawn with `Canvas` rather than SpriteKit: twenty-three moving things is nothing for an
/// immediate-mode renderer, it ships no assets, and it keeps the package compiling on macOS —
/// which is the only reason this project has been verifiable at all without Xcode.
///
/// Portrait and vertical. You attack up the screen, the camera follows the ball, and the whole
/// surface is reachable with one thumb.
struct FieldCanvas: View {
    let frame: FieldFrame
    let teamColor: Color
    let opponentColor: Color
    /// Yards to the line to gain, drawn so the stakes of the down are always on screen.
    let yardsToGain: Int
    let showsIndicators: Bool

    /// Yards of field visible top to bottom.
    private var window: Double { ArcadeTuning.cameraWindowYards }

    var body: some View {
        Canvas { context, size in
            let camera = cameraDepth
            draw(turf: context, size: size, camera: camera)
            draw(lanes: context, size: size, camera: camera)
            draw(trajectory: context, size: size, camera: camera)
            draw(players: context, size: size, camera: camera)
            draw(ball: context, size: size, camera: camera)
        }
        .background(Color(hex: OpennessTier.turfHex))
        .clipShape(RoundedRectangle(cornerRadius: Layout.chipRadius))
    }

    // MARK: - Camera

    /// The depth held a third of the way up the screen, so there is always field ahead.
    private var cameraDepth: Double {
        max(-8, frame.ballPoint.depth - window * 0.3)
    }

    private func point(_ field: FieldPoint, size: CGSize, camera: Double) -> CGPoint {
        // Depth runs up the screen; lateral runs across it.
        let y = size.height * (1 - (field.depth - camera) / window)
        let x = size.width * (0.5 + field.lateral * 0.46)
        return CGPoint(x: x, y: y)
    }

    // MARK: - Layers

    private func draw(turf context: GraphicsContext, size: CGSize, camera: Double) {
        var yard = Int(camera.rounded(.down))
        while Double(yard) <= camera + window {
            if yard % 5 == 0 {
                let y = point(FieldPoint(depth: Double(yard), lateral: 0), size: size, camera: camera).y
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y))
                line.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(
                    line,
                    with: .color(.white.opacity(yard % 10 == 0 ? 0.30 : 0.15)),
                    lineWidth: yard % 10 == 0 ? 1.6 : 0.9
                )
            }
            yard += 1
        }

        // The line of scrimmage and the line to gain — the two that decide the down.
        stroke(depth: 0, in: context, size: size, camera: camera, color: .white.opacity(0.85), width: 2)
        stroke(
            depth: Double(yardsToGain), in: context, size: size, camera: camera,
            color: .yellow.opacity(0.9), width: 2
        )
    }

    private func stroke(
        depth: Double,
        in context: GraphicsContext,
        size: CGSize,
        camera: Double,
        color: Color,
        width: CGFloat
    ) {
        let y = point(FieldPoint(depth: depth, lateral: 0), size: size, camera: camera).y
        guard y >= 0, y <= size.height else { return }
        var line = Path()
        line.move(to: CGPoint(x: 0, y: y))
        line.addLine(to: CGPoint(x: size.width, y: y))
        context.stroke(line, with: .color(color), lineWidth: width)
    }

    private func draw(lanes context: GraphicsContext, size: CGSize, camera: Double) {
        guard let suggested = frame.suggestedLane else { return }
        let center = FieldPoint.yards(depth: 1.5, lateralYards: suggested.centerLateralYards)
        let edge = FieldPoint.yards(
            depth: 1.5, lateralYards: suggested.centerLateralYards + suggested.halfWidth
        )
        let middle = point(center, size: size, camera: camera)
        let side = point(edge, size: size, camera: camera)
        let halfWidth = max(6, abs(side.x - middle.x))
        let rect = CGRect(
            x: middle.x - halfWidth,
            y: point(FieldPoint(depth: 4, lateral: 0), size: size, camera: camera).y,
            width: halfWidth * 2,
            height: max(8, middle.y - point(FieldPoint(depth: 4, lateral: 0), size: size, camera: camera).y)
        )
        context.fill(Path(roundedRect: rect, cornerRadius: 4), with: .color(.white.opacity(0.16)))
    }

    private func draw(trajectory context: GraphicsContext, size: CGSize, camera: Double) {
        guard let aim = frame.aimPoint,
              let passer = frame.players.first(where: { $0.role == .quarterback }) else { return }

        let from = point(passer.point, size: size, camera: camera)
        let to = point(aim, size: size, camera: camera)

        // Only as much of the flight as the passer's accuracy lets you see.
        let steps = 26
        let visible = max(1, Int(Double(steps) * min(1, max(0.1, frame.visibleArcFraction))))
        var path = Path()
        for step in 0...visible {
            let t = Double(step) / Double(steps)
            let lift = min(70, hypot(to.x - from.x, to.y - from.y) * 0.22) * sin(.pi * t)
            let position = CGPoint(
                x: from.x + (to.x - from.x) * t,
                y: from.y + (to.y - from.y) * t - lift
            )
            if step == 0 { path.move(to: position) } else { path.addLine(to: position) }
        }
        context.stroke(
            path,
            with: .color(.white.opacity(0.9)),
            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [5, 6])
        )

        // The scatter ring: honest about where the ball might actually land.
        let ringEdge = point(
            FieldPoint.yards(depth: aim.depth, lateralYards: aim.lateralYards + frame.scatterRadius),
            size: size,
            camera: camera
        )
        let radius = max(7, abs(ringEdge.x - to.x))
        let ring = Path(ellipseIn: CGRect(
            x: to.x - radius, y: to.y - radius, width: radius * 2, height: radius * 2
        ))
        context.stroke(ring, with: .color(.white.opacity(0.75)), lineWidth: 2)
        context.fill(ring, with: .color(.white.opacity(0.10)))
    }

    private func draw(players context: GraphicsContext, size: CGSize, camera: Double) {
        for player in frame.players {
            let spot = point(player.point, size: size, camera: camera)
            guard spot.y > -30, spot.y < size.height + 30 else { continue }
            let radius: CGFloat = player.role == .quarterback ? 11 : 9.5
            let fill = player.side == .offense ? teamColor : opponentColor
            let circle = Path(ellipseIn: CGRect(
                x: spot.x - radius, y: spot.y - radius, width: radius * 2, height: radius * 2
            ))
            context.fill(circle, with: .color(fill.opacity(player.isBeaten ? 0.45 : 1)))
            context.stroke(circle, with: .color(.white.opacity(0.9)), lineWidth: 1.5)

            if showsIndicators, player.side == .offense,
               let state = frame.indicators[player.id] {
                drawIndicator(state, at: spot, radius: radius, in: context)
            }

            context.draw(
                Text(player.athlete.position.abbreviation)
                    .font(.system(size: 7, weight: .heavy))
                    .foregroundColor(.white),
                at: spot
            )
        }
    }

    /// Colour *and* shape, so the indicator survives colour blindness and a bright afternoon:
    /// a filled ring is open, a broken ring is contested, a thin ring is covered.
    private func drawIndicator(
        _ state: OpennessState,
        at spot: CGPoint,
        radius: CGFloat,
        in context: GraphicsContext
    ) {
        let outer = radius + 5
        let rect = CGRect(x: spot.x - outer, y: spot.y - outer, width: outer * 2, height: outer * 2)
        let color = OpennessTier(state).fieldColor
        switch state {
        case .open:
            context.stroke(Path(ellipseIn: rect), with: .color(color), lineWidth: 3.5)
        case .contested:
            context.stroke(
                Path(ellipseIn: rect),
                with: .color(color),
                style: StrokeStyle(lineWidth: 3, dash: [4, 4])
            )
        case .covered:
            context.stroke(Path(ellipseIn: rect), with: .color(color), lineWidth: 1.2)
        }
    }

    private func draw(ball context: GraphicsContext, size: CGSize, camera: Double) {
        let spot = point(frame.ballPoint, size: size, camera: camera)
        let rect = CGRect(x: spot.x - 4.5, y: spot.y - 3, width: 9, height: 6)
        context.fill(Path(ellipseIn: rect), with: .color(Color(red: 0.42, green: 0.24, blue: 0.10)))
        context.stroke(Path(ellipseIn: rect), with: .color(.white), lineWidth: 1)
    }
}
