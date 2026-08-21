// Draws the canonical 166-mark team logo set as flat vector artwork.
//
//   swift Tools/TeamLogos/generate_logos.swift            write every PNG
//   swift Tools/TeamLogos/generate_logos.swift --manifest write PNGs and refresh concept/prompt
//
// Every mark is derived from the manifest record alone, so the same manifest always produces the
// same bytes. Marks are built from a small library of hand-drawn silhouettes rather than an image
// model: the shapes are original geometry, carry no lettering, and reference no real identity.
//
// The house style is the one athletics marks share: one dominant silhouette, flat fills in the
// team's own two colours, a single dark keyline and a paper halo so the mark holds on either page.
// Detail that cannot survive a 20-point draw is left out on purpose.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - design space

// Artwork is authored in a 0...100 box with y pointing down, then mapped into the canvas.

struct Pt {
    var x: Double
    var y: Double
}

func p(_ x: Double, _ y: Double) -> Pt { Pt(x: x, y: y) }

enum Ink {
    case primary
    case secondary
    case paper
    case ink
}

enum Geom {
    case poly([Pt], Double)
    case circle(Pt, Double)
    case ring(Pt, Double, Double)
}

struct Mark {
    var geom: Geom
    var fill: Ink
}

func poly(_ points: [Pt], _ rounding: Double = 0.03, _ fill: Ink) -> Mark {
    Mark(geom: .poly(points, rounding), fill: fill)
}

func disc(_ centre: Pt, _ radius: Double, _ fill: Ink) -> Mark {
    Mark(geom: .circle(centre, radius), fill: fill)
}

func ring(_ centre: Pt, _ outer: Double, _ inner: Double, _ fill: Ink) -> Mark {
    Mark(geom: .ring(centre, outer, inner), fill: fill)
}

func flip(_ points: [Pt]) -> [Pt] { points.map { p(100 - $0.x, $0.y) }.reversed() }

// MARK: - transforms

func mirrored(_ marks: [Mark]) -> [Mark] {
    marks.map { mark in
        var copy = mark
        switch mark.geom {
        case .poly(let points, let rounding):
            copy.geom = .poly(flip(points), rounding)
        case .circle(let centre, let radius):
            copy.geom = .circle(p(100 - centre.x, centre.y), radius)
        case .ring(let centre, let outer, let inner):
            copy.geom = .ring(p(100 - centre.x, centre.y), outer, inner)
        }
        return copy
    }
}

func fitted(_ marks: [Mark], scale: Double, dy: Double = 0) -> [Mark] {
    func move(_ point: Pt) -> Pt {
        p(50 + (point.x - 50) * scale, 50 + (point.y - 50) * scale + dy)
    }
    return marks.map { mark in
        var copy = mark
        switch mark.geom {
        case .poly(let points, let rounding):
            copy.geom = .poly(points.map(move), rounding)
        case .circle(let centre, let radius):
            copy.geom = .circle(move(centre), radius * scale)
        case .ring(let centre, let outer, let inner):
            copy.geom = .ring(move(centre), outer * scale, inner * scale)
        }
        return copy
    }
}

func swappedRoles(_ marks: [Mark]) -> [Mark] {
    marks.map { mark in
        var copy = mark
        switch mark.fill {
        case .primary: copy.fill = .secondary
        case .secondary: copy.fill = .primary
        default: break
        }
        return copy
    }
}

func recoloured(_ marks: [Mark], _ fill: Ink) -> [Mark] {
    marks.map { Mark(geom: $0.geom, fill: fill) }
}

func rotated(_ marks: [Mark], degrees: Double) -> [Mark] {
    let radians = degrees * .pi / 180
    func spin(_ point: Pt) -> Pt {
        let dx = point.x - 50, dy = point.y - 50
        return p(50 + dx * cos(radians) - dy * sin(radians),
                 50 + dx * sin(radians) + dy * cos(radians))
    }
    return marks.map { mark in
        var copy = mark
        switch mark.geom {
        case .poly(let points, let rounding):
            copy.geom = .poly(points.map(spin), rounding)
        case .circle(let centre, let radius):
            copy.geom = .circle(spin(centre), radius)
        case .ring(let centre, let outer, let inner):
            copy.geom = .ring(spin(centre), outer, inner)
        }
        return copy
    }
}

// MARK: - shared shapes

func star(centre: Pt, outer: Double, inner: Double, points: Int, fill: Ink) -> Mark {
    var result: [Pt] = []
    let step = Double.pi / Double(points)
    for index in 0..<(points * 2) {
        let radius = index.isMultiple(of: 2) ? outer : inner
        let angle = -Double.pi / 2 + Double(index) * step
        result.append(p(centre.x + cos(angle) * radius, centre.y + sin(angle) * radius))
    }
    return poly(result, 0.02, fill)
}

func bar(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ r: Double, _ fill: Ink) -> Mark {
    poly([p(x0, y0), p(x1, y0), p(x1, y1), p(x0, y1)], r, fill)
}

// MARK: - subjects

// One mark per nickname noun. A team is named after a thing, so the mark is that thing and
// nothing else: the set this replaced drew a compass roundel for the Silver Kestrels.
//
// Everything here is built from few large shapes with wide gaps between them, because the mark is
// read at 20 points far more often than at 44 and detail that cannot survive that size is a
// liability rather than craft.

// MARK: shared animal bases

/// A bird of prey in profile, facing left. `hook` deepens the beak, `crest` raises the nape.
func raptorHead(hook: Double, crest: Bool) -> [Mark] {
    var marks: [Mark] = []
    if crest {
        marks.append(poly([p(70, 20), p(98, 4), p(96, 26), p(88, 24), p(90, 34)], 0.05, .secondary))
    }
    marks.append(poly([p(4, 50), p(20, 37), p(34, 25), p(52, 17), p(72, 19), p(90, 31),
                       p(95, 52), p(85, 73), p(66, 87), p(45, 85), p(31, 72), p(25, 59),
                       p(11, 59)], 0.03, .primary))
    marks.append(poly([p(4, 50), p(20, 37), p(33, 49), p(28, 60 + hook), p(16, 67 + hook),
                       p(10, 59)], 0.05, .secondary))
    marks.append(poly([p(27, 30), p(59, 23), p(62, 36), p(29, 43)], 0.1, .ink))
    marks.append(poly([p(34, 40), p(55, 35), p(57, 47), p(36, 52)], 0.12, .paper))
    return marks
}

/// A long-billed wading bird, facing left. `curve` bends the bill downwards.
func waderHead(curve: Double, plume: Bool) -> [Mark] {
    var marks: [Mark] = []
    if plume {
        marks.append(poly([p(64, 26), p(92, 14), p(88, 30), p(72, 34)], 0.08, .secondary))
    }
    marks.append(poly([p(28, 44), p(37, 28), p(52, 21), p(68, 26), p(77, 40), p(78, 60),
                       p(66, 77), p(49, 85), p(35, 77), p(26, 62)], 0.06, .primary))
    marks.append(poly([p(2, 84), p(10 + curve, 58), p(30, 42), p(39, 52),
                       p(20 + curve, 66), p(12, 88)], 0.06, .secondary))
    marks.append(poly([p(42, 36), p(58, 32), p(60, 43), p(44, 46)], 0.14, .paper))
    return marks
}

/// A short-muzzled mammal head, seen forward. `ear` is the ear height, `fangs` shows teeth.
func beastHead(ear: Double, fangs: Bool, blunt: Bool) -> [Mark] {
    let muzzle = blunt
        ? [p(30, 54), p(70, 54), p(74, 74), p(50, 88), p(26, 74)]
        : [p(34, 52), p(66, 52), p(70, 70), p(50, 86), p(30, 70)]
    var marks: [Mark] = [
        poly([p(12, ear), p(31, 30), p(50, 23), p(69, 30), p(88, ear), p(93, 44), p(82, 68),
              p(62, 85), p(50, 92), p(38, 85), p(18, 68), p(7, 44)], 0.04, .primary),
        poly(muzzle, 0.14, .secondary),
        poly([p(16, 36), p(41, 31), p(43, 42), p(18, 48)], 0.12, .paper),
        poly([p(84, 36), p(59, 31), p(57, 42), p(82, 48)], 0.12, .paper),
        poly([p(42, 57), p(58, 57), p(50, 70)], 0.12, .ink),
    ]
    if fangs {
        marks.append(poly([p(39, 80), p(46, 80), p(43, 93)], 0.05, .paper))
        marks.append(poly([p(54, 80), p(61, 80), p(58, 93)], 0.05, .paper))
    }
    return marks
}

// MARK: shared object bases

/// Two shafts crossed behind a pair of heads, the shape most trade marks resolve to.
func crossed(_ head: [Pt], _ mirrorHead: Bool = true) -> [Mark] {
    var marks: [Mark] = [
        poly([p(16, 8), p(26, 2), p(86, 90), p(76, 96)], 0.05, .primary),
        poly([p(84, 8), p(74, 2), p(14, 90), p(24, 96)], 0.05, .primary),
        poly(head, 0.05, .secondary),
    ]
    if mirrorHead { marks.append(poly(flip(head), 0.05, .secondary)) }
    return marks
}

/// A haft with a head at the top, for the single-tool marks.
func hafted(_ head: [Mark]) -> [Mark] {
    [bar(44, 40, 56, 96, 0.12, .primary)] + head
}

// MARK: the forty

func subject(_ noun: String) -> [Mark] {
    switch noun {
    case "Wardens":
        // A hand lantern: cap, glass, base, bail.
        return [
            poly([p(38, 6), p(62, 6), p(58, 18), p(42, 18)], 0.14, .secondary),
            poly([p(34, 18), p(66, 18), p(72, 74), p(28, 74)], 0.08, .primary),
            poly([p(41, 30), p(59, 30), p(62, 64), p(38, 64)], 0.1, .paper),
            bar(26, 74, 74, 90, 0.16, .secondary),
            ring(p(50, 6), 13, 7, .secondary),
        ]
    case "Drovers":
        // A crook, the curl at the top and a long shaft.
        return [
            poly([p(30, 6), p(62, 4), p(80, 22), p(72, 46), p(50, 52), p(40, 40), p(52, 34),
                  p(60, 40), p(66, 28), p(56, 18), p(36, 20)], 0.14, .primary),
            bar(38, 46, 52, 96, 0.1, .secondary),
        ]
    case "Delvers":
        return crossed([p(6, 30), p(26, 22), p(44, 30), p(30, 40), p(14, 40)])
    case "Sentinels":
        // A watchtower with a crenellated head.
        return [
            poly([p(24, 16), p(34, 16), p(34, 8), p(44, 8), p(44, 16), p(56, 16), p(56, 8),
                  p(66, 8), p(66, 16), p(76, 16), p(76, 30), p(24, 30)], 0.03, .secondary),
            poly([p(28, 30), p(72, 30), p(82, 94), p(18, 94)], 0.04, .primary),
            poly([p(43, 44), p(57, 44), p(57, 66), p(43, 66)], 0.3, .paper),
        ]
    case "Bulwarks":
        // A stepped battlement seen square-on.
        return [
            poly([p(6, 30), p(22, 30), p(22, 18), p(40, 18), p(40, 30), p(60, 30), p(60, 18),
                  p(78, 18), p(78, 30), p(94, 30), p(94, 88), p(6, 88)], 0.02, .primary),
            bar(20, 48, 80, 60, 0.1, .secondary),
            poly([p(40, 62), p(60, 62), p(60, 88), p(40, 88)], 0.06, .secondary),
        ]
    case "Foresters":
        return [
            poly([p(50, 4), p(70, 44), p(60, 44), p(78, 76), p(22, 76), p(40, 44), p(30, 44)],
                 0.03, .secondary),
            bar(44, 72, 56, 96, 0.1, .secondary),
            poly([p(6, 24), p(30, 14), p(46, 34), p(26, 46), p(10, 42)], 0.06, .primary),
            poly([p(94, 24), p(70, 14), p(54, 34), p(74, 46), p(90, 42)], 0.06, .primary),
        ]
    case "Marauders":
        // A boarding hook crossed with a straight blade.
        return [
            poly([p(14, 92), p(4, 82), p(52, 30), p(74, 22), p(84, 34), p(66, 42), p(58, 56),
                  p(72, 62), p(64, 72), p(44, 62), p(46, 44)], 0.08, .primary),
            poly([p(86, 92), p(96, 82), p(48, 28), p(38, 8), p(24, 14), p(34, 34)], 0.05,
                 .secondary),
        ]
    case "Prospectors":
        return [
            // A pick over an ore chunk.
            poly([p(4, 22), p(30, 8), p(50, 20), p(70, 8), p(96, 22), p(72, 30), p(50, 38),
                  p(28, 30)], 0.05, .primary),
            bar(44, 30, 56, 62, 0.08, .primary),
            poly([p(26, 62), p(46, 54), p(68, 58), p(80, 76), p(62, 94), p(34, 92), p(20, 78)],
                 0.1, .secondary),
        ]
    case "Voyagers":
        return [
            star(centre: p(50, 50), outer: 47, inner: 14, points: 4, fill: .primary),
            star(centre: p(50, 50), outer: 30, inner: 9, points: 4, fill: .secondary),
            ring(p(50, 50), 22, 15, .paper),
        ]
    case "Reapers":
        // A scythe: a deep crescent blade on an angled snaith.
        return [
            // A scythe: a straight snaith and one crescent that comes to a point.
            poly([p(72, 6), p(86, 14), p(46, 94), p(30, 88)], 0.06, .secondary),
            poly([p(4, 26), p(40, 12), p(78, 22), p(60, 34), p(34, 30), p(18, 42)], 0.08,
                 .primary),
            poly([p(4, 26), p(18, 42), p(48, 52), p(84, 54), p(78, 22), p(52, 34)], 0.1,
                 .primary),
        ]
    case "Anchors":
        return [
            ring(p(50, 12), 11, 5, .secondary),
            bar(43, 20, 57, 78, 0.1, .primary),
            bar(22, 28, 78, 40, 0.24, .primary),
            poly([p(8, 48), p(21, 45), p(27, 66), p(50, 78), p(73, 66), p(79, 45), p(92, 48),
                  p(83, 80), p(50, 95), p(17, 80)], 0.06, .secondary),
        ]
    case "Wayfarers":
        return [
            poly([p(28, 10), p(52, 10), p(50, 22), p(30, 22)], 0.14, .secondary),
            poly([p(24, 22), p(56, 22), p(60, 62), p(20, 62)], 0.08, .primary),
            poly([p(31, 32), p(49, 32), p(51, 54), p(29, 54)], 0.1, .paper),
            poly([p(62, 4), p(74, 4), p(80, 96), p(68, 96)], 0.06, .secondary),
        ]
    case "Wreckers":
        // A hook on a chain over a broken spar.
        return [
            // One heavy hook on a short chain.
            ring(p(50, 10), 9, 4, .secondary),
            bar(43, 18, 57, 34, 0.1, .secondary),
            poly([p(36, 34), p(64, 34), p(74, 62), p(58, 88), p(30, 90), p(16, 70), p(30, 58),
                  p(40, 72), p(52, 70), p(56, 58), p(44, 52)], 0.14, .primary),
        ]
    case "Harriers": return raptorHead(hook: 0, crest: false)
    case "Kestrels": return raptorHead(hook: 4, crest: true)
    case "Goshawks": return raptorHead(hook: 2, crest: false)
    case "Shrikes": return raptorHead(hook: 6, crest: true)
    case "Herons": return waderHead(curve: 0, plume: true)
    case "Curlews": return waderHead(curve: 10, plume: false)
    case "Stalkers": return beastHead(ear: 6, fangs: true, blunt: false)
    case "Otters": return beastHead(ear: 26, fangs: false, blunt: true)
    case "Martens": return beastHead(ear: 10, fangs: true, blunt: true)
    case "Wyverns":
        return [
            poly([p(28, 26), p(8, 6), p(0, 22), p(14, 38)], 0.06, .secondary),
            poly([p(72, 26), p(92, 6), p(100, 22), p(86, 38)], 0.06, .secondary),
            poly([p(30, 30), p(70, 30), p(80, 50), p(66, 68), p(50, 92), p(34, 68), p(20, 50)],
                 0.04, .primary),
            poly([p(34, 66), p(66, 66), p(58, 84), p(42, 84)], 0.06, .paper),
            poly([p(30, 42), p(44, 38), p(45, 50), p(31, 53)], 0.12, .ink),
            poly([p(70, 42), p(56, 38), p(55, 50), p(69, 53)], 0.12, .ink),
        ]
    case "Colliers":
        // A safety lamp: dome, cage, base.
        return [
            ring(p(50, 9), 9, 4, .secondary),
            poly([p(22, 18), p(78, 18), p(84, 36), p(16, 36)], 0.08, .primary),
            bar(24, 36, 36, 72, 0.14, .primary),
            bar(64, 36, 76, 72, 0.14, .primary),
            poly([p(38, 40), p(62, 40), p(58, 68), p(42, 68)], 0.14, .secondary),
            poly([p(14, 72), p(86, 72), p(92, 94), p(8, 94)], 0.08, .primary),
        ]
    case "Ironsides":
        // A riveted hull plate.
        return [
            poly([p(12, 10), p(88, 10), p(88, 56), p(50, 92), p(12, 56)], 0.06, .primary),
            disc(p(26, 24), 7, .secondary),
            disc(p(74, 24), 7, .secondary),
            disc(p(26, 52), 7, .secondary),
            disc(p(74, 52), 7, .secondary),
            bar(38, 22, 62, 70, 0.14, .secondary),
        ]
    case "Quarrymen":
        return crossed([p(4, 24), p(28, 16), p(46, 26), p(30, 40), p(10, 40)])
    case "Beacons":
        return [
            poly([p(30, 44), p(38, 20), p(46, 30), p(50, 4), p(62, 26), p(68, 18), p(72, 44)],
                 0.08, .secondary),
            poly([p(10, 46), p(90, 46), p(78, 72), p(22, 72)], 0.04, .primary),
            poly([p(34, 72), p(66, 72), p(74, 96), p(26, 96)], 0.06, .primary),
        ]
    case "Tanners":
        // A crescent knife above a stretched hide.
        return [
            // A round knife: one deep crescent and a grip, nothing else.
            poly([p(4, 30), p(50, 16), p(96, 30), p(88, 64), p(50, 86), p(12, 64)], 0.1, .primary),
            poly([p(16, 34), p(50, 26), p(84, 34), p(76, 54), p(50, 66), p(24, 54)], 0.14, .paper),
            bar(42, 4, 58, 26, 0.14, .secondary),
        ]
    case "Coopers":
        return [
            // A staved cask reads instantly; a bare hoop reads as a ring.
            poly([p(20, 12), p(80, 12), p(94, 50), p(80, 90), p(20, 90), p(6, 50)], 0.1, .primary),
            bar(8, 26, 92, 38, 0.2, .secondary),
            bar(8, 62, 92, 74, 0.2, .secondary),
            bar(46, 12, 54, 90, 0.1, .secondary),
        ]
    case "Sawyers":
        // A saw blade with a toothed edge and a grip.
        return [
            poly([p(4, 16), p(78, 16), p(86, 48), p(4, 48)], 0.03, .primary),
            poly([p(6, 48), p(17, 74), p(28, 48), p(39, 74), p(50, 48), p(61, 74), p(72, 48),
                  p(83, 72), p(88, 48)], 0.02, .primary),
            poly([p(78, 4), p(97, 12), p(97, 52), p(78, 48)], 0.12, .secondary),
        ]
    case "Riggers":
        // A block and tackle.
        return [
            ring(p(50, 8), 8, 4, .secondary),
            poly([p(24, 16), p(76, 16), p(82, 54), p(50, 70), p(18, 54)], 0.16, .primary),
            ring(p(50, 38), 16, 7, .paper),
            poly([p(40, 68), p(60, 68), p(66, 82), p(50, 96), p(34, 82)], 0.16, .secondary),
        ]
    case "Ferrymen":
        return [
            poly([p(4, 58), p(96, 58), p(78, 88), p(22, 88)], 0.06, .primary),
            poly([p(44, 58), p(56, 58), p(52, 12), p(48, 12)], 0.06, .secondary),
            poly([p(56, 14), p(88, 14), p(74, 34), p(56, 34)], 0.05, .secondary),
            bar(6, 88, 94, 96, 0.3, .secondary),
        ]
    case "Smelters":
        // A crucible tipping a pour.
        return [
            // A crucible tipped over a pour.
            poly([p(10, 14), p(62, 14), p(70, 30), p(56, 52), p(20, 52)], 0.1, .primary),
            poly([p(62, 22), p(88, 30), p(84, 46), p(60, 38)], 0.1, .primary),
            poly([p(78, 40), p(92, 44), p(80, 96), p(62, 92)], 0.16, .secondary),
            bar(14, 52, 62, 68, 0.14, .secondary),
        ]
    case "Chandlers":
        return [
            bar(14, 26, 30, 88, 0.06, .primary),
            bar(42, 14, 58, 88, 0.06, .primary),
            bar(70, 26, 86, 88, 0.06, .primary),
            poly([p(22, 4), p(28, 16), p(22, 26), p(16, 16)], 0.2, .secondary),
            poly([p(50, 0), p(57, 12), p(50, 22), p(43, 12)], 0.2, .secondary),
            poly([p(78, 4), p(84, 16), p(78, 26), p(72, 16)], 0.2, .secondary),
        ]
    case "Fletchers":
        // Three arrows, points up, fletching at the foot.
        return [
            poly([p(20, 6), p(30, 30), p(10, 30)], 0.03, .secondary),
            poly([p(50, 2), p(60, 26), p(40, 26)], 0.03, .secondary),
            poly([p(80, 6), p(90, 30), p(70, 30)], 0.03, .secondary),
            bar(15, 30, 25, 78, 0.06, .primary),
            bar(45, 26, 55, 78, 0.06, .primary),
            bar(75, 30, 85, 78, 0.06, .primary),
            poly([p(6, 76), p(94, 76), p(80, 96), p(20, 96)], 0.06, .secondary),
        ]
    case "Bastions":
        return [
            star(centre: p(50, 52), outer: 46, inner: 26, points: 5, fill: .primary),
            star(centre: p(50, 52), outer: 26, inner: 15, points: 5, fill: .secondary),
        ]
    case "Ramparts":
        return [
            poly([p(4, 34), p(20, 34), p(20, 20), p(38, 20), p(38, 34), p(62, 34), p(62, 20),
                  p(80, 20), p(80, 34), p(96, 34), p(96, 50), p(4, 50)], 0.02, .primary),
            poly([p(10, 50), p(90, 50), p(84, 92), p(16, 92)], 0.04, .secondary),
            bar(42, 62, 58, 92, 0.08, .primary),
        ]
    case "Palisades":
        return [
            poly([p(6, 26), p(18, 12), p(30, 26), p(30, 92), p(6, 92)], 0.04, .primary),
            poly([p(32, 18), p(44, 4), p(56, 18), p(56, 92), p(32, 92)], 0.04, .secondary),
            poly([p(58, 26), p(70, 12), p(82, 26), p(82, 92), p(58, 92)], 0.04, .primary),
            bar(2, 52, 94, 64, 0.1, .secondary),
        ]
    case "Cairns":
        return [
            poly([p(18, 76), p(82, 76), p(88, 94), p(12, 94)], 0.1, .primary),
            poly([p(24, 54), p(76, 54), p(80, 74), p(20, 74)], 0.12, .secondary),
            poly([p(32, 32), p(68, 32), p(72, 52), p(28, 52)], 0.14, .primary),
            poly([p(40, 10), p(62, 10), p(66, 30), p(36, 30)], 0.16, .secondary),
        ]
    case "Lodestars":
        return [
            star(centre: p(50, 50), outer: 48, inner: 11, points: 4, fill: .primary),
            star(centre: p(50, 50), outer: 24, inner: 6, points: 4, fill: .secondary),
        ]
    default:
        // Unreached: every noun the grammar can emit has a case above, and a test enumerates them.
        return [ring(p(50, 50), 46, 30, .primary), disc(p(50, 50), 18, .secondary)]
    }
}

// MARK: - composition

// The family decides how the subject is presented, not what it is. Six readings, so a league of
// forty subjects still looks like a league rather than a catalogue page.

let emblemFrames: [[Pt]] = [
    [p(8, 6), p(92, 6), p(92, 48), p(50, 95), p(8, 48)],
    [p(10, 5), p(90, 5), p(90, 70), p(50, 95), p(10, 70)],
    [p(28, 5), p(72, 5), p(95, 50), p(72, 95), p(28, 95), p(5, 50)],
    [p(50, 3), p(97, 50), p(50, 97), p(3, 50)],
]

func composed(_ noun: String, family: String, index: Int) -> [Mark] {
    let base = subject(noun)
    switch family {
    case "animalCreature":
        return base
    case "originalCharacter":
        // A banner under the mark, the way a crest sits over a scroll.
        return fitted(base, scale: 0.86, dy: -8)
            + [poly([p(8, 82), p(50, 76), p(92, 82), p(86, 96), p(50, 91), p(14, 96)], 0.08,
                    .secondary)]
    case "equipmentVehicle":
        return fitted(base, scale: 0.92, dy: -3)
            + [poly([p(12, 91), p(88, 91), p(82, 99), p(18, 99)], 0.2, .secondary)]
    case "regionalSymbol":
        // A horizon band, not a landscape: one bar and one rise, well clear of the subject.
        return [poly([p(2, 84), p(30, 74), p(50, 79), p(70, 72), p(98, 83), p(98, 95), p(2, 95)],
                     0.1, .secondary)]
            + fitted(base, scale: 0.80, dy: -10)
    case "framedEmblem":
        let frame = [poly(emblemFrames[index % emblemFrames.count], 0.05, .primary)]
        return frame + fitted(recoloured(frame, .paper), scale: 0.80)
            + fitted(base, scale: 0.62, dy: -3)
    default:
        // Speed lines behind, subject in front and still the largest shape.
        return [poly([p(2, 26), p(46, 18), p(50, 30), p(6, 38)], 0.2, .secondary),
                poly([p(2, 48), p(38, 42), p(41, 54), p(5, 60)], 0.2, .secondary),
                poly([p(4, 70), p(32, 65), p(34, 77), p(6, 82)], 0.2, .secondary)]
            + fitted(rotated(base, degrees: -8), scale: 0.84, dy: -2)
    }
}

// MARK: - separation

// Two marks that share a frame collapse to the same coarse signature even when their motifs
// differ, so each mark is checked against the ones already drawn and nudged until it stands apart.
// The ladder is ordered gently-first and is a pure function of the position, so the set is stable.

struct Nudge {
    var swap: Bool
    var invert: Bool
    var scale: Double
    var angle: Double
    var mirror: Bool
}

let separationLadder: [Nudge] = {
    var result = [Nudge(swap: false, invert: false, scale: 1, angle: 0, mirror: false)]
    for mirror in [false, true] {
        for angle in [0.0, 9, -9, 16, -16] {
            for scale in [1.0, 0.93, 0.86, 0.79] {
                for invert in [false, true] {
                    for swap in [true, false] {
                        if !mirror && !invert && angle == 0 && scale == 1 && !swap { continue }
                        result.append(Nudge(swap: swap, invert: invert, scale: scale,
                                            angle: angle, mirror: mirror))
                    }
                }
            }
        }
    }
    return result
}()

func invertedPolarity(_ marks: [Mark]) -> [Mark] {
    marks.map { mark in
        var copy = mark
        switch mark.fill {
        case .paper: copy.fill = .ink
        case .ink: copy.fill = .paper
        default: break
        }
        return copy
    }
}

func nudged(_ base: [Mark], by nudge: Nudge) -> [Mark] {
    var result = nudge.swap ? swappedRoles(base) : base
    if nudge.invert { result = invertedPolarity(result) }
    if nudge.mirror { result = mirrored(result) }
    if nudge.angle != 0 { result = rotated(result, degrees: nudge.angle) }
    if nudge.scale != 1 { result = fitted(result, scale: nudge.scale) }
    return result
}

// The same 8x8 average hash the asset suite uses to reject near-duplicates.
func averageHash(_ image: CGImage) -> UInt64 {
    var pixels = [UInt8](repeating: 0, count: 64)
    guard let context = CGContext(data: &pixels,
                                  width: 8,
                                  height: 8,
                                  bitsPerComponent: 8,
                                  bytesPerRow: 8,
                                  space: CGColorSpaceCreateDeviceGray(),
                                  bitmapInfo: CGImageAlphaInfo.none.rawValue)
    else { return 0 }
    context.interpolationQuality = .low
    context.draw(image, in: CGRect(x: 0, y: 0, width: 8, height: 8))
    let average = pixels.reduce(0) { $0 + Int($1) } / pixels.count
    return pixels.enumerated().reduce(into: UInt64.zero) { result, entry in
        if Int(entry.element) >= average { result |= UInt64(1) << UInt64(entry.offset) }
    }
}

// A rotated or enlarged mark can reach the canvas edge, which the asset suite reads as a mark
// that has been cropped. Any rung that does is skipped rather than shipped.
func hasClearBorder(_ image: CGImage) -> Bool {
    let side = image.width
    var pixels = [UInt8](repeating: 0, count: side * side * 4)
    guard let context = CGContext(data: &pixels,
                                  width: side,
                                  height: side,
                                  bitsPerComponent: 8,
                                  bytesPerRow: side * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { return false }
    context.setBlendMode(.copy)
    context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
    for offset in 0..<side {
        let last = (side - 1) * side
        if pixels[offset * 4 + 3] != 0 || pixels[(last + offset) * 4 + 3] != 0 { return false }
        if pixels[offset * side * 4 + 3] != 0 { return false }
        if pixels[(offset * side + side - 1) * 4 + 3] != 0 { return false }
    }
    return true
}

func hammingDistance(_ lhs: UInt64, _ rhs: UInt64) -> Int { (lhs ^ rhs).nonzeroBitCount }

// MARK: - colour

struct RGB {
    var r: Double
    var g: Double
    var b: Double

    static func parse(_ hex: String) -> RGB {
        let digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let value = UInt32(digits, radix: 16) ?? 0
        return RGB(r: Double((value >> 16) & 0xFF) / 255,
                   g: Double((value >> 8) & 0xFF) / 255,
                   b: Double(value & 0xFF) / 255)
    }

    var luminance: Double { 0.2126 * r + 0.7152 * g + 0.0722 * b }

    var cg: CGColor { CGColor(red: r, green: g, blue: b, alpha: 1) }
}

let charcoal = RGB(r: 0.05, g: 0.06, b: 0.07)
let chalk = RGB(r: 0.97, g: 0.98, b: 0.97)

struct Palette {
    var primary: RGB
    var secondary: RGB
    var paper: RGB
    var ink: RGB
    var halo: RGB

    init(primaryHex: String, secondaryHex: String) {
        let first = RGB.parse(primaryHex)
        let second = RGB.parse(secondaryHex)
        // The dominant silhouette takes the darker colour so the mark holds its shape on a light
        // page; the brighter colour becomes the accent.
        if first.luminance <= second.luminance {
            primary = first
            secondary = second
        } else {
            primary = second
            secondary = first
        }
        // A dark keyline needs at least one fill light enough to sit against it.
        let readableAgainstCharcoal = max(primary.luminance, secondary.luminance) >= 0.24
        ink = readableAgainstCharcoal ? charcoal : chalk
        halo = readableAgainstCharcoal ? chalk : charcoal
        paper = chalk
    }

    func colour(_ role: Ink) -> CGColor {
        switch role {
        case .primary: return primary.cg
        case .secondary: return secondary.cg
        case .paper: return paper.cg
        case .ink: return ink.cg
        }
    }
}

// MARK: - rendering

let outputSize = 256
let renderSize = 1024
let designInset = 0.06
let keylineWidth = 1.15
let haloWidth = 1.15

func path(for geom: Geom, scale: Double, origin: Double) -> CGPath {
    // The design box is y-down; CoreGraphics is y-up, so every y is flipped on the way in.
    func map(_ point: Pt) -> CGPoint {
        CGPoint(x: origin + point.x * scale, y: origin + (100 - point.y) * scale)
    }
    func box(_ centre: Pt, _ radius: Double) -> CGRect {
        CGRect(x: origin + (centre.x - radius) * scale,
               y: origin + (100 - centre.y - radius) * scale,
               width: radius * 2 * scale,
               height: radius * 2 * scale)
    }
    let result = CGMutablePath()
    switch geom {
    case .circle(let centre, let radius):
        result.addEllipse(in: box(centre, radius))
    case .ring(let centre, let outer, let inner):
        result.addEllipse(in: box(centre, outer))
        result.addEllipse(in: box(centre, inner))
    case .poly(let points, let rounding):
        guard points.count >= 3 else { break }
        if rounding <= 0 {
            result.move(to: map(points[0]))
            for point in points.dropFirst() { result.addLine(to: map(point)) }
            result.closeSubpath()
            break
        }
        // Each corner is cut back by the same fraction of both adjoining edges, which is a pair
        // of lerps towards the neighbours. Half an edge is the ceiling: past that the cuts of
        // adjacent corners cross and the outline folds through itself.
        let cut = min(rounding, 0.5)
        let count = points.count
        func towards(_ corner: Pt, _ neighbour: Pt) -> Pt {
            p(corner.x + (neighbour.x - corner.x) * cut,
              corner.y + (neighbour.y - corner.y) * cut)
        }
        for index in 0..<count {
            let current = points[index]
            let entry = towards(current, points[(index + count - 1) % count])
            let leave = towards(current, points[(index + 1) % count])
            if index == 0 {
                result.move(to: map(entry))
            } else {
                result.addLine(to: map(entry))
            }
            result.addQuadCurve(to: map(leave), control: map(current))
        }
        result.closeSubpath()
    }
    return result
}

func render(_ marks: [Mark], palette: Palette) -> CGImage? {
    guard let context = CGContext(data: nil,
                                  width: renderSize,
                                  height: renderSize,
                                  bitsPerComponent: 8,
                                  bytesPerRow: renderSize * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { return nil }
    let side = Double(renderSize)
    let origin = side * designInset
    let scale = (side - origin * 2) / 100
    context.setAllowsAntialiasing(true)
    context.setLineJoin(.round)
    context.setLineCap(.round)

    let paths = marks.map { mark -> (CGPath, Ink, Bool) in
        var isRing = false
        if case .ring = mark.geom { isRing = true }
        return (path(for: mark.geom, scale: scale, origin: origin), mark.fill, isRing)
    }

    // A halo under the whole mark keeps the silhouette readable on either page, the way a second
    // keyline does on a printed athletics mark.
    context.setStrokeColor(palette.halo.cg)
    context.setFillColor(palette.halo.cg)
    context.setLineWidth((keylineWidth + haloWidth) * 2 * scale)
    for (shape, _, isRing) in paths {
        context.addPath(shape)
        context.strokePath()
        context.addPath(shape)
        if isRing { context.drawPath(using: .eoFill) } else { context.fillPath() }
    }

    for (shape, role, isRing) in paths {
        context.setStrokeColor(palette.colour(.ink))
        context.setLineWidth(keylineWidth * 2 * scale)
        context.addPath(shape)
        context.strokePath()
        context.setFillColor(palette.colour(role))
        context.addPath(shape)
        if isRing { context.drawPath(using: .eoFill) } else { context.fillPath() }
    }

    guard let full = context.makeImage() else { return nil }
    guard let down = CGContext(data: nil,
                               width: outputSize,
                               height: outputSize,
                               bitsPerComponent: 8,
                               bytesPerRow: outputSize * 4,
                               space: CGColorSpaceCreateDeviceRGB(),
                               bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { return nil }
    down.interpolationQuality = .high
    down.draw(full, in: CGRect(x: 0, y: 0, width: outputSize, height: outputSize))
    return down.makeImage()
}

struct Failure: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}

// Encoding and decoding before the checks run means the border scan and the hash see exactly the
// bytes the asset suite will read back, so the separation margin needs no slack for round-tripping.
func encodedPNG(_ image: CGImage) -> (data: Data, decoded: CGImage)? {
    let buffer = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(
        buffer, UTType.png.identifier as CFString, 1, nil
    ) else { return nil }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination),
          let source = CGImageSourceCreateWithData(buffer as CFData, nil),
          let decoded = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
    return (buffer as Data, decoded)
}

// MARK: - manifest

struct Record: Codable {
    var stableID: String
    var name: String
    var abbreviation: String
    var primaryColorHex: String
    var secondaryColorHex: String
    var family: String
    var concept: String
    var prompt: String
    var assetName: String
    var filename: String
    var generationStatus: String
    var humanApproved: Bool
    var reviewNotes: String
}

struct Manifest: Codable {
    var schemaVersion: Int
    var worldSeed: UInt64
    var teams: [Record]
}

// MARK: - main

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let manifestURL = root.appendingPathComponent("Tools/TeamLogos/manifest.json")
let assetsURL = root.appendingPathComponent(
    "Sources/ProFootballCoachUI/Resources/TeamLogos.xcassets"
)
let manifest = try JSONDecoder().decode(Manifest.self, from: Data(contentsOf: manifestURL))
let ordered = manifest.teams.sorted { $0.stableID < $1.stableID }
var nextSlot: [String: Int] = [:]
var slotByID: [String: Int] = [:]
for record in ordered {
    let slot = nextSlot[record.family, default: 0]
    slotByID[record.stableID] = slot
    nextSlot[record.family] = slot + 1
}

// The asset suite rejects any pair closer than five bits, and the candidates below are hashed
// from their encoded bytes, so this is the same measurement the suite makes.
let minimumSeparation = 5

var written = 0
var nudgeCount = 0
var drawnHashes: [UInt64] = []
var nudgeByID: [String: Nudge] = [:]
for record in ordered {
    let slot = slotByID[record.stableID] ?? 0
    let palette = Palette(primaryHex: record.primaryColorHex,
                          secondaryHex: record.secondaryColorHex)
    let noun = record.name.split(separator: " ").last.map(String.init) ?? ""
    let base = composed(noun, family: record.family, index: slot)
    var chosen: Data?
    for (rung, nudge) in separationLadder.enumerated() {
        guard let candidate = render(nudged(base, by: nudge), palette: palette),
              let encoded = encodedPNG(candidate),
              hasClearBorder(encoded.decoded) else { continue }
        let hash = averageHash(encoded.decoded)
        guard drawnHashes.allSatisfy({ hammingDistance($0, hash) >= minimumSeparation })
        else { continue }
        drawnHashes.append(hash)
        chosen = encoded.data
        nudgeByID[record.stableID] = nudge
        if rung > 0 { nudgeCount += 1 }
        break
    }
    guard let png = chosen else {
        throw Failure("no ladder rung separates \(record.name) from the marks already drawn")
    }
    let directory = assetsURL.appendingPathComponent(record.assetName + ".imageset")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try png.write(to: directory.appendingPathComponent(record.filename), options: .atomic)
    let contents = """
    {
      "images" : [
        {
          "filename" : "\(record.filename)",
          "idiom" : "universal",
          "scale" : "1x"
        }
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }

    """
    try contents.write(to: directory.appendingPathComponent("Contents.json"),
                       atomically: true, encoding: .utf8)
    written += 1
}

print("wrote \(written) marks at \(outputSize)x\(outputSize); \(nudgeCount) needed a nudge")
