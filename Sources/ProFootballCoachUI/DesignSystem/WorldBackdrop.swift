import SwiftUI

/// What sits behind the glass — `04` §2's registers, made visible.
///
/// This is the single variable that changes between screens: the pitch when the screen is about the
/// field, the facility when it is about the programme, the footage itself in the film room. It
/// recedes into `desk` density without ever vanishing, so every screen still happens somewhere.
public enum CoachWorldWorld: Sendable, Equatable {
    /// Floodlit pitch in perspective. Match day, depth chart, practice.
    ///
    /// Swift does not allow default arguments on enum cases, so the house values live in
    /// `defaultPitch`.
    case pitch(tilt: Double, bottomBleed: CGFloat)
    /// The same pitch an hour after full time: desaturated, lights dimmed.
    case pitchAfter
    /// The facility floor at night, under warm overhead pools.
    case facility
    /// Facility with the world pushed back so a table can carry density.
    case desk
    /// Lit by its own footage: the warm lamp is gone and a cold beam throws from behind the viewer.
    case filmRoom

    /// The house pitch framing.
    public static let defaultPitch = CoachWorldWorld.pitch(tilt: 69, bottomBleed: 0.58)

    var isDesk: Bool { self == .desk }
}

/// Registry 27 — the register made visible.
///
/// **Replaced entirely by `world.page` under Reduce Transparency**, per `04` §7: "the grain is
/// dropped and the world is replaced by `world.page`". Every measured contrast ratio survives that
/// substitution, which is why §6.1 measures the roles against the three opaque elevations rather
/// than against composited glass over a lit world.
public struct WorldBackdrop: View {
    @Environment(\.coachWorldPalette) private var palette
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private let world: CoachWorldWorld

    public init(_ world: CoachWorldWorld) {
        self.world = world
    }

    public var body: some View {
        Group {
            if reduceTransparency {
                palette.page.color
            } else {
                lit
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var lit: some View {
        ZStack {
            ground
            switch world {
            case let .pitch(tilt, bleed):
                floodlightSky
                LampBeam(x: 0.12, top: -30)
                LampBeam(x: 0.86, top: -40)
                PitchPlane(tilt: tilt, bottomBleed: bleed)
                fade(CoachWorldTokens.Atmosphere.pitchVignette, leading: palette.page)

            case .pitchAfter:
                floodlightSky.opacity(0.55)
                LampBeam(x: 0.11, top: -30, opacity: 0.55)
                LampBeam(x: 0.86, top: -36, opacity: 0.55)
                PitchPlane(tilt: 70, bottomBleed: 0.60)
                    .saturation(0.72)
                    .brightness(-0.06)
                fade(CoachWorldTokens.Atmosphere.pitchAfterVignette)

            case .facility, .desk:
                WindowBand()
                FacilityFloor()
                    .opacity(world.isDesk ? 0.62 : 1)
                fade(world.isDesk
                     ? CoachWorldTokens.Atmosphere.deskVignette
                     : CoachWorldTokens.Atmosphere.facilityVignette)

            case .filmRoom:
                ProjectorBeam()
                DustMotes()
            }
        }
    }

    @ViewBuilder private var ground: some View {
        switch world {
        case .filmRoom:
            radial(CoachWorldTokens.Atmosphere.filmRoomGround, at: UnitPoint(x: 0.5, y: 0.34), to: 620)
        case .facility, .desk:
            radial(CoachWorldTokens.Atmosphere.facilityGround, at: UnitPoint(x: 0.46, y: 1.06), to: 700)
        case .pitchAfter:
            radial(CoachWorldTokens.Atmosphere.pitchAfterGround, at: UnitPoint(x: 0.5, y: 1.06), to: 700)
        case .pitch:
            radial(CoachWorldTokens.Atmosphere.pitchGround, at: UnitPoint(x: 0.5, y: 1.10), to: 720)
        }
    }

    private func radial(
        _ stops: [CoachWorldTokens.ColorValue],
        at center: UnitPoint,
        to end: CGFloat
    ) -> some View {
        RadialGradient(
            colors: stops.map(\.color), center: center, startRadius: .zero, endRadius: end
        )
    }

    private func fade(
        _ stops: [CoachWorldTokens.AtmosphereStop],
        leading: CoachWorldTokens.ColorValue? = nil
    ) -> some View {
        var gradient: [Gradient.Stop] = []
        if let leading {
            gradient.append(.init(color: leading.color, location: 0.06))
        }
        gradient.append(contentsOf: stops.map {
            Gradient.Stop(color: $0.color, location: $0.location ?? 0)
        })
        return LinearGradient(stops: gradient, startPoint: .top, endPoint: .bottom)
    }

    private var floodlightSky: some View {
        ZStack {
            RadialGradient(
                colors: [CoachWorldTokens.Atmosphere.lamp.value.color.opacity(0.30), .clear],
                center: UnitPoint(x: 0.14, y: -0.08), startRadius: .zero, endRadius: 300
            )
            RadialGradient(
                colors: [CoachWorldTokens.Atmosphere.lamp.value.color.opacity(0.22), .clear],
                center: UnitPoint(x: 0.86, y: -0.12), startRadius: .zero, endRadius: 340
            )
        }
    }
}

// MARK: - The pitch

/// Mown turf on a plane tilted away from the viewer.
///
/// **`perspective` is an unverified estimate and the first thing to tune on device.** Floodlit's
/// author states it plainly: the value maps to the prototype's CSS `perspective: 620px`, SwiftUI's
/// parameter is a different unit, and `0.55` was a guess that has never rendered. If the pitch
/// reads flat or wildly skewed, this is the dial. Carried forward verbatim rather than quietly
/// dropped, because an inherited guess that looks like a measurement is worse than one that says so.
public struct PitchPlane: View {
    public var tilt: Double
    public var bottomBleed: CGFloat
    public var perspective: CGFloat

    public init(tilt: Double = 69, bottomBleed: CGFloat = 0.58, perspective: CGFloat = 0.55) {
        self.tilt = tilt
        self.bottomBleed = bottomBleed
        self.perspective = perspective
    }

    public var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width * 1.8
            let height = proxy.size.height * 1.5

            ZStack {
                RadialGradient(
                    colors: [
                        CoachWorldTokens.Atmosphere.turfHot.color,
                        CoachWorldTokens.Atmosphere.turf.color,
                        CoachWorldTokens.Atmosphere.turfDeep.color
                    ],
                    center: UnitPoint(x: 0.5, y: 0.30),
                    startRadius: .zero,
                    endRadius: width * 0.62
                )
                MownBands()
            }
            .frame(width: width, height: height)
            .rotation3DEffect(
                .degrees(tilt), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: perspective
            )
            .offset(
                x: -(width - proxy.size.width) / 2,
                y: proxy.size.height - height + height * bottomBleed
            )
        }
        .clipped()
    }
}

/// Ground texture, encoding nothing.
///
/// **Twelve bands, not the prototype's twenty.** `04` §6.1 fixes the count: twelve bands across a
/// 120-yard field give a ten-yard distance gauge that survives a delete test, where twenty give a
/// six-yard gauge that does not. Nothing may be encoded in which band a mark falls on — the
/// contrast against the turf is deliberately near-invisible so it reads as ground, not as data.
struct MownBands: View {
    var body: some View {
        GeometryReader { proxy in
            let count = CoachWorldTokens.Atmosphere.mownBandCount
            let band = proxy.size.width / CGFloat(count)
            Canvas { context, size in
                for index in 0..<count where index.isMultiple(of: 2) {
                    context.fill(
                        Path(CGRect(x: CGFloat(index) * band, y: 0, width: band, height: size.height)),
                        with: .color(CoachWorldTokens.Atmosphere.mownBand.color)
                    )
                }
            }
        }
    }
}

// MARK: - The facility

/// The floor of the building, under two warm pools.
public struct FacilityFloor: View {
    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width * 1.6
            let height = proxy.size.height * 1.5
            let warm = CoachWorldTokens.Atmosphere.lampWarm.color

            ZStack {
                LinearGradient(
                    colors: CoachWorldTokens.Atmosphere.facilityFloor.map(\.color),
                    startPoint: .top, endPoint: .bottom
                )
                RadialGradient(
                    colors: [warm.opacity(0.30), .clear],
                    center: UnitPoint(x: 0.26, y: 0.16), startRadius: .zero, endRadius: width * 0.34
                )
                RadialGradient(
                    colors: [warm.opacity(0.18), .clear],
                    center: UnitPoint(x: 0.72, y: 0.22), startRadius: .zero, endRadius: width * 0.28
                )
                FloorSheen()
            }
            .frame(width: width, height: height)
            .rotation3DEffect(
                .degrees(73), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 0.5
            )
            .offset(x: -(width - proxy.size.width) / 2, y: proxy.size.height - height + height * 0.64)
        }
        .clipped()
    }
}

struct FloorSheen: View {
    var body: some View {
        GeometryReader { proxy in
            let count = 11
            let band = proxy.size.width / CGFloat(count)
            Canvas { context, size in
                for index in 0..<count where index.isMultiple(of: 2) {
                    context.fill(
                        Path(CGRect(x: CGFloat(index) * band, y: 0, width: band, height: size.height)),
                        with: .color(CoachWorldTokens.Atmosphere.floorSheen.color)
                    )
                }
            }
        }
    }
}

/// The office window. The lit field is always out there, which is the premise of the product.
public struct WindowBand: View {
    private let height: CGFloat
    private let mullions: [CGFloat]

    public init(height: CGFloat = 88, mullions: [CGFloat] = [0.23, 0.52, 0.78]) {
        self.height = height
        self.mullions = mullions
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: CoachWorldTokens.Atmosphere.windowBand.map(\.color),
                    startPoint: .top, endPoint: .bottom
                )

                // The distant stadium — the field you are not at tonight.
                Ellipse()
                    .fill(RadialGradient(
                        colors: CoachWorldTokens.Atmosphere.stadiumGlow.map(\.color) + [.clear],
                        center: .center, startRadius: .zero, endRadius: 170
                    ))
                    .frame(width: 340, height: 70)
                    .blur(radius: CoachWorldTokens.Atmosphere.Blur.stadiumGlow)
                    .offset(y: -14)

                Rectangle()
                    .fill(LinearGradient(
                        colors: [.clear, CoachWorldTokens.Atmosphere.stadiumLightBar.color, .clear],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: 200, height: 3)
                    .blur(radius: CoachWorldTokens.Atmosphere.Blur.stadiumBar)
                    .offset(y: -24)

                ForEach(Array(mullions.enumerated()), id: \.offset) { _, position in
                    Rectangle()
                        .fill(CoachWorldTokens.Atmosphere.mullion.color)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .offset(x: proxy.size.width * position - proxy.size.width / 2)
                }

                // Sill, and the fade into the room below it.
                Rectangle()
                    .fill(LinearGradient(
                        colors: [
                            CoachWorldTokens.Atmosphere.lampWarm.color.opacity(0.24),
                            .black.opacity(0.6)
                        ],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(height: 4)
            }
            .frame(height: height)
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, CoachWorldTokens.Atmosphere.facilityGround[1].color],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 34)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}

// MARK: - Light

/// A floodlight shaft entering from off-frame.
///
/// This is the brightest ground any panel sits over, and the value `04` §6.1's deep-panel floor is
/// derived against: lamp over mown turf composites to `#AAD3A4`, where the prototype's 0.78 fill
/// left `content.quiet` at 4.23.
public struct LampBeam: View {
    private let x: CGFloat
    private let top: CGFloat
    private let length: CGFloat
    private let opacity: Double

    public init(x: CGFloat, top: CGFloat, length: CGFloat = 150, opacity: Double = 1) {
        self.x = x
        self.top = top
        self.length = length
        self.opacity = opacity
    }

    public var body: some View {
        GeometryReader { proxy in
            Rectangle()
                .fill(LinearGradient(
                    colors: [CoachWorldTokens.Atmosphere.lamp.color, .clear],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: 2, height: length)
                .blur(radius: CoachWorldTokens.Atmosphere.Blur.lampBeam)
                .opacity(opacity)
                .position(x: proxy.size.width * x, y: top + length / 2)
        }
    }
}

/// The film room's cold throw, from behind the viewer onto the screen.
public struct ProjectorBeam: View {
    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            BeamShape()
                .fill(LinearGradient(
                    stops: CoachWorldTokens.Atmosphere.projectorThrow.map {
                        Gradient.Stop(color: $0.color, location: $0.location ?? 0)
                    } + [.init(color: .clear, location: 1)],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: 660, height: 340)
                .blur(radius: CoachWorldTokens.Atmosphere.Blur.projector)
                .position(x: proxy.size.width / 2, y: 226)
        }
    }
}

struct BeamShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.30, y: 0))
        path.addLine(to: CGPoint(x: rect.width * 0.70, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

/// Dust in the beam. Fixed positions — this is atmosphere, not simulation, and fixing them keeps
/// previews deterministic for the same reason the grain tile is seeded.
struct DustMotes: View {
    private static let motes: [(x: CGFloat, y: CGFloat, diameter: CGFloat, opacity: Double)] = [
        (0.31, 0.38, 3, 0.60), (0.44, 0.24, 2, 0.45),
        (0.57, 0.46, 2.5, 0.50), (0.38, 0.61, 2, 0.35),
        (0.63, 0.33, 2, 0.40)
    ]

    var body: some View {
        GeometryReader { proxy in
            ForEach(Array(Self.motes.enumerated()), id: \.offset) { _, mote in
                Circle()
                    .fill(CoachWorldTokens.Atmosphere.dustMote.color)
                    .frame(width: mote.diameter, height: mote.diameter)
                    .blur(radius: CoachWorldTokens.Atmosphere.Blur.dustMote)
                    .opacity(mote.opacity)
                    .position(x: proxy.size.width * mote.x, y: proxy.size.height * mote.y)
            }
        }
    }
}
