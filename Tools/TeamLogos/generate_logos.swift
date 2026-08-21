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

// MARK: - family: animal or creature

func raptorHead() -> [Mark] {
    [
        poly([p(2, 48), p(20, 38), p(32, 26), p(48, 18), p(66, 18), p(96, 6), p(84, 33),
              p(98, 44), p(82, 57), p(92, 80), p(66, 73), p(56, 90), p(38, 78), p(26, 64),
              p(12, 62)], 0.02, .primary),
        poly([p(2, 48), p(20, 38), p(33, 50), p(28, 64), p(17, 70), p(11, 62)], 0.05,
             .secondary),
        poly([p(32, 42), p(53, 37), p(55, 48), p(34, 53)], 0.14, .paper),
        poly([p(27, 33), p(58, 26), p(60, 37), p(29, 44)], 0.1, .ink),
    ]
}

func felineHead() -> [Mark] {
    [
        poly([p(12, 6), p(30, 30), p(50, 22), p(70, 30), p(88, 6), p(93, 42), p(82, 68),
              p(62, 86), p(50, 93), p(38, 86), p(18, 68), p(7, 42)], 0.03, .primary),
        poly([p(32, 52), p(68, 52), p(72, 72), p(50, 87), p(28, 72)], 0.14, .secondary),
        poly([p(16, 36), p(41, 31), p(43, 42), p(18, 48)], 0.12, .paper),
        poly([p(84, 36), p(59, 31), p(57, 42), p(82, 48)], 0.12, .paper),
        poly([p(42, 56), p(58, 56), p(50, 69)], 0.12, .ink),
        poly([p(39, 79), p(46, 79), p(43, 93)], 0.06, .paper),
        poly([p(54, 79), p(61, 79), p(58, 93)], 0.06, .paper),
    ]
}

func hornedHead() -> [Mark] {
    let horn = [p(34, 24), p(18, 6), p(2, 16), p(0, 44), p(15, 60), p(24, 50), p(12, 40),
                p(15, 22), p(30, 36)]
    return [
        poly(horn, 0.1, .secondary),
        poly(flip(horn), 0.1, .secondary),
        poly([p(34, 28), p(66, 28), p(75, 50), p(63, 74), p(50, 91), p(37, 74), p(25, 50)],
             0.05, .primary),
        poly([p(38, 60), p(62, 60), p(58, 83), p(42, 83)], 0.18, .paper),
        poly([p(31, 43), p(44, 39), p(45, 50), p(32, 53)], 0.12, .ink),
        poly([p(69, 43), p(56, 39), p(55, 50), p(68, 53)], 0.12, .ink),
    ]
}

func canineHead() -> [Mark] {
    [
        poly([p(2, 64), p(22, 54), p(34, 50), p(22, 6), p(48, 34), p(64, 4), p(78, 38),
              p(94, 50), p(98, 68), p(85, 86), p(60, 96), p(38, 90), p(22, 78), p(6, 74)],
             0.02, .primary),
        poly([p(2, 64), p(22, 54), p(38, 60), p(32, 80), p(6, 74)], 0.04, .secondary),
        poly([p(42, 50), p(63, 44), p(65, 58), p(44, 63)], 0.12, .paper),
        poly([p(8, 72), p(19, 69), p(15, 89)], 0.05, .paper),
        poly([p(24, 71), p(34, 68), p(30, 86)], 0.05, .paper),
    ]
}

// MARK: - family: original character

func characterHead(_ core: Int) -> [Mark] {
    let jaw: [Pt]
    switch core % 4 {
    case 0:
        jaw = [p(30, 24), p(20, 38), p(10, 50), p(19, 56), p(16, 63), p(24, 68), p(26, 79),
               p(40, 89), p(58, 87), p(70, 74), p(74, 54), p(68, 34), p(52, 24)]
    case 1:
        jaw = [p(28, 22), p(18, 36), p(5, 48), p(16, 54), p(12, 62), p(22, 66), p(20, 82),
               p(38, 93), p(62, 89), p(76, 72), p(78, 50), p(70, 30), p(50, 22)]
    case 2:
        jaw = [p(32, 26), p(22, 40), p(13, 52), p(22, 58), p(19, 66), p(28, 70), p(34, 84),
               p(52, 91), p(66, 80), p(72, 60), p(70, 40), p(58, 26)]
    default:
        jaw = [p(28, 26), p(16, 40), p(4, 52), p(15, 58), p(12, 66), p(24, 70), p(28, 80),
               p(44, 91), p(62, 84), p(72, 66), p(74, 46), p(64, 30), p(46, 24)]
    }
    return [
        poly(jaw, 0.06, .primary),
        poly([p(24, 42), p(38, 38), p(39, 47), p(25, 50)], 0.14, .ink),
    ]
}

func headgear(_ kind: Int) -> [Mark] {
    switch kind % 7 {
    case 0:
        return [
            poly([p(26, 26), p(32, 6), p(62, 4), p(70, 24)], 0.1, .secondary),
            bar(4, 22, 90, 32, 0.3, .secondary),
        ]
    case 1:
        return [
            poly([p(18, 32), p(26, 10), p(56, 2), p(78, 16), p(80, 36), p(66, 28), p(44, 20)],
                 0.1, .secondary),
            poly([p(40, 6), p(53, 3), p(59, 32), p(46, 34)], 0.06, .paper),
        ]
    case 2:
        return [
            poly([p(30, 26), p(10, 0), p(0, 8), p(4, 24), p(18, 34)], 0.08, .secondary),
            poly([p(70, 26), p(90, 0), p(100, 8), p(96, 24), p(82, 34)], 0.08, .secondary),
            poly([p(20, 32), p(28, 12), p(56, 6), p(76, 20), p(76, 36), p(58, 24), p(38, 22)],
                 0.1, .secondary),
        ]
    case 3:
        return [
            poly([p(12, 38), p(18, 12), p(50, 0), p(82, 14), p(88, 46), p(76, 42), p(70, 20),
                  p(46, 12), p(26, 24), p(22, 40)], 0.1, .secondary),
        ]
    case 4:
        return [
            poly([p(22, 30), p(28, 10), p(64, 8), p(72, 30)], 0.14, .secondary),
            poly([p(0, 26), p(30, 22), p(31, 34), p(2, 38)], 0.2, .secondary),
        ]
    case 5:
        return [
            poly([p(70, 22), p(94, 14), p(92, 32), p(72, 36)], 0.12, .secondary),
            poly([p(20, 32), p(26, 16), p(58, 10), p(76, 24), p(74, 34), p(48, 24), p(26, 38)],
                 0.14, .secondary),
        ]
    default:
        return [
            poly([p(18, 34), p(26, 14), p(50, 6), p(74, 16), p(80, 34)], 0.12, .secondary),
            poly([p(44, 8), p(57, 10), p(57, 34), p(44, 32)], 0.06, .paper),
            bar(6, 30, 92, 40, 0.3, .secondary),
        ]
    }
}

// MARK: - family: regional symbol

func regionalMotif(_ index: Int) -> [Mark] {
    switch index % 7 {
    case 0:
        return [
            poly([p(3, 86), p(30, 28), p(47, 58), p(63, 18), p(97, 86)], 0.02, .primary),
            poly([p(63, 18), p(76, 44), p(68, 40), p(60, 47), p(53, 38)], 0.04, .paper),
            poly([p(30, 28), p(41, 51), p(34, 48), p(28, 54), p(22, 46)], 0.04, .paper),
        ]
    case 1:
        return [
            star(centre: p(50, 50), outer: 47, inner: 19, points: 5, fill: .primary),
            star(centre: p(50, 50), outer: 24, inner: 10, points: 5, fill: .secondary),
        ]
    case 2:
        return [
            poly([p(50, 3), p(89, 85), p(50, 67), p(11, 85)], 0.03, .primary),
            poly([p(50, 26), p(71, 71), p(50, 61), p(29, 71)], 0.04, .secondary),
        ]
    case 3:
        return [
            ring(p(50, 15), 13, 6, .secondary),
            bar(44, 22, 56, 80, 0.14, .primary),
            bar(25, 32, 75, 43, 0.3, .primary),
            poly([p(9, 50), p(22, 47), p(28, 68), p(50, 79), p(72, 68), p(78, 47), p(91, 50),
                  p(83, 80), p(50, 95), p(17, 80)], 0.06, .secondary),
        ]
    case 4:
        return [
            poly([p(50, 4), p(68, 40), p(59, 40), p(74, 68), p(26, 68), p(41, 40), p(32, 40)],
                 0.03, .primary),
            bar(45, 66, 55, 90, 0.14, .secondary),
            poly([p(18, 30), p(31, 56), p(24, 56), p(36, 78), p(0, 78), p(12, 56), p(5, 56)],
                 0.03, .secondary),
            poly([p(82, 30), p(69, 56), p(76, 56), p(64, 78), p(100, 78), p(88, 56), p(95, 56)],
                 0.03, .secondary),
        ]
    case 5:
        return [
            poly([p(2, 44), p(22, 26), p(46, 36), p(68, 22), p(90, 32), p(98, 22), p(98, 44),
                  p(84, 52), p(64, 42), p(44, 56), p(20, 46), p(2, 60)], 0.14, .primary),
            poly([p(2, 66), p(22, 50), p(46, 60), p(68, 46), p(90, 56), p(98, 46), p(98, 68),
                  p(84, 76), p(64, 66), p(44, 80), p(20, 70), p(2, 84)], 0.14, .secondary),
        ]
    default:
        return [
            poly([p(46, 2), p(54, 2), p(52, 20), p(48, 20)], 0.1, .primary),
            poly([p(12, 12), p(19, 8), p(29, 22), p(23, 26)], 0.1, .primary),
            poly([p(88, 12), p(81, 8), p(71, 22), p(77, 26)], 0.1, .primary),
            poly([p(2, 44), p(2, 36), p(22, 38), p(22, 46)], 0.1, .primary),
            poly([p(98, 44), p(98, 36), p(78, 38), p(78, 46)], 0.1, .primary),
            disc(p(50, 46), 23, .secondary),
            bar(4, 68, 96, 79, 0.16, .primary),
            bar(18, 85, 82, 95, 0.2, .primary),
        ]
    }
}

// MARK: - family: equipment or vehicle

func equipmentMotif(_ index: Int) -> [Mark] {
    switch index % 7 {
    case 0:
        return [
            poly([p(9, 58), p(14, 32), p(32, 14), p(60, 12), p(83, 28), p(90, 54), p(88, 66),
                  p(58, 62), p(30, 62), p(26, 76), p(10, 74)], 0.14, .primary),
            poly([p(4, 62), p(34, 58), p(37, 72), p(7, 80)], 0.16, .secondary),
            poly([p(43, 13), p(58, 14), p(54, 60), p(39, 60)], 0.06, .paper),
        ]
    case 1:
        return [
            bar(38, 2, 62, 20, 0.1, .secondary),
            poly([p(21, 18), p(79, 18), p(85, 62), p(15, 62)], 0.06, .primary),
            disc(p(50, 39), 14, .paper),
            poly([p(5, 66), p(95, 66), p(79, 92), p(21, 92)], 0.06, .secondary),
        ]
    case 2:
        return [
            poly([p(46, 4), p(46, 60), p(14, 60)], 0.02, .secondary),
            poly([p(54, 12), p(88, 60), p(54, 60)], 0.02, .primary),
            poly([p(5, 66), p(95, 66), p(78, 94), p(22, 94)], 0.06, .primary),
        ]
    case 3:
        return [
            poly([p(28, 54), p(10, 86), p(32, 78)], 0.06, .secondary),
            poly([p(72, 54), p(90, 86), p(68, 78)], 0.06, .secondary),
            poly([p(50, 2), p(67, 26), p(71, 66), p(29, 66), p(33, 26)], 0.08, .primary),
            disc(p(50, 34), 12, .paper),
            poly([p(39, 72), p(61, 72), p(55, 96), p(45, 96)], 0.1, .secondary),
        ]
    case 4:
        return [
            ring(p(50, 50), 47, 27, .primary),
            bar(45, 4, 55, 26, 0.1, .primary),
            bar(45, 74, 55, 96, 0.1, .primary),
            bar(4, 45, 26, 55, 0.1, .primary),
            bar(74, 45, 96, 55, 0.1, .primary),
            disc(p(50, 50), 19, .secondary),
        ]
    case 5:
        return [
            poly([p(2, 33), p(13, 25), p(90, 25), p(80, 42), p(62, 45), p(58, 58), p(70, 70),
                  p(77, 84), p(23, 84), p(30, 70), p(42, 58), p(38, 45), p(14, 42)], 0.05,
                 .primary),
            bar(16, 82, 84, 95, 0.14, .secondary),
        ]
    default:
        return [
            ring(p(50, 50), 46, 31, .primary),
            poly([p(59, 10), p(29, 54), p(48, 54), p(39, 90), p(73, 44), p(53, 44)], 0.02,
                 .secondary),
        ]
    }
}

// MARK: - family: framed emblem

func frameShape(_ index: Int) -> [Mark] {
    switch index % 5 {
    case 0:
        return [poly([p(8, 6), p(92, 6), p(92, 48), p(50, 95), p(8, 48)], 0.06, .primary)]
    case 1:
        return [disc(p(50, 50), 47, .primary)]
    case 2:
        return [poly([p(10, 5), p(90, 5), p(90, 70), p(50, 95), p(10, 70)], 0.04, .primary)]
    case 3:
        return [poly([p(28, 5), p(72, 5), p(95, 50), p(72, 95), p(28, 95), p(5, 50)], 0.05,
                     .primary)]
    default:
        return [poly([p(50, 3), p(97, 50), p(50, 97), p(3, 50)], 0.05, .primary)]
    }
}

func frameDevice(_ index: Int) -> [Mark] {
    switch index % 6 {
    case 0:
        return [
            poly([p(50, 16), p(84, 52), p(66, 52), p(50, 34), p(34, 52), p(16, 52)], 0.04,
                 .secondary),
            poly([p(50, 48), p(84, 84), p(66, 84), p(50, 66), p(34, 84), p(16, 84)], 0.04,
                 .secondary),
        ]
    case 1:
        return [poly([p(60, 10), p(28, 54), p(48, 54), p(40, 92), p(74, 44), p(54, 44)], 0.02,
                     .secondary)]
    case 2:
        return [star(centre: p(50, 50), outer: 44, inner: 18, points: 5, fill: .secondary)]
    case 3:
        return [bar(14, 20, 86, 36, 0.16, .secondary),
                bar(14, 42, 86, 58, 0.16, .secondary),
                bar(14, 64, 86, 80, 0.16, .secondary)]
    case 4:
        return [bar(20, 14, 32, 54, 0.1, .secondary),
                bar(68, 14, 80, 54, 0.1, .secondary),
                poly([p(44, 6), p(56, 6), p(58, 54), p(42, 54)], 0.08, .secondary),
                bar(16, 50, 84, 64, 0.16, .secondary),
                bar(43, 62, 57, 94, 0.1, .secondary)]
    default:
        return [poly([p(50, 10), p(80, 46), p(64, 46), p(64, 90), p(36, 90), p(36, 46), p(20, 46)],
                     0.03, .secondary)]
    }
}

// MARK: - family: abstract motion

func motionMotif(_ index: Int) -> [Mark] {
    switch index % 9 {
    case 0:
        return [
            poly([p(4, 88), p(26, 46), p(58, 20), p(99, 16), p(62, 38), p(36, 58), p(20, 90)],
                 0.14, .primary),
            poly([p(22, 92), p(38, 60), p(58, 48), p(78, 44), p(54, 64), p(36, 78), p(32, 96)],
                 0.14, .secondary),
        ]
    case 1:
        return [
            poly([p(62, 2), p(26, 52), p(48, 52), p(36, 98), p(78, 44), p(54, 44)], 0.02,
                 .primary),
            poly([p(62, 2), p(40, 32), p(54, 44), p(78, 44)], 0.02, .secondary),
        ]
    case 2:
        return [
            poly([p(8, 90), p(34, 10), p(48, 10), p(24, 90)], 0.04, .primary),
            poly([p(36, 90), p(60, 10), p(74, 10), p(52, 90)], 0.04, .secondary),
            poly([p(64, 90), p(86, 10), p(98, 10), p(78, 90)], 0.04, .primary),
        ]
    case 3:
        return [
            poly([p(8, 42), p(50, 18), p(92, 42), p(92, 28), p(50, 4), p(8, 28)], 0.03, .primary),
            poly([p(8, 66), p(50, 42), p(92, 66), p(92, 52), p(50, 28), p(8, 52)], 0.03,
                 .secondary),
            poly([p(8, 90), p(50, 66), p(92, 90), p(92, 76), p(50, 52), p(8, 76)], 0.03,
                 .primary),
        ]
    case 4:
        return [
            poly([p(2, 38), p(58, 28), p(60, 46)], 0.03, .secondary),
            poly([p(6, 80), p(60, 50), p(66, 66)], 0.03, .secondary),
            disc(p(70, 46), 25, .primary),
        ]
    case 5:
        return [
            poly([p(4, 92), p(14, 54), p(36, 26), p(70, 8), p(97, 4), p(76, 30), p(82, 32),
                  p(58, 52), p(65, 55), p(40, 72), p(47, 75), p(24, 94)], 0.04, .primary),
            poly([p(24, 94), p(36, 62), p(56, 46), p(76, 38), p(60, 58), p(44, 72), p(40, 96)],
                 0.06, .secondary),
        ]
    case 6:
        return [
            poly([p(50, 2), p(70, 30), p(66, 46), p(82, 40), p(86, 66), p(64, 94), p(36, 96),
                  p(14, 70), p(24, 38), p(38, 48), p(36, 24)], 0.12, .primary),
            poly([p(50, 42), p(63, 64), p(56, 86), p(40, 84), p(35, 60)], 0.16, .secondary),
        ]
    case 7:
        return [
            ring(p(50, 50), 47, 34, .primary),
            ring(p(50, 50), 26, 14, .secondary),
            disc(p(50, 50), 7, .primary),
        ]
    default:
        return [
            poly([p(4, 50), p(38, 12), p(38, 34), p(62, 34), p(62, 66), p(38, 66), p(38, 88)],
                 0.03, .primary),
            poly([p(62, 18), p(96, 50), p(62, 82), p(62, 62), p(76, 50), p(62, 38)], 0.03,
                 .secondary),
        ]
    }
}

// MARK: - variants

// Seven structurally distinct treatments, so two teams sharing a motif never share a silhouette.

func variant(_ index: Int, applyingTo base: [Mark]) -> [Mark] {
    switch index % 7 {
    case 0:
        return base
    case 1:
        return mirrored(fitted(base, scale: 0.84, dy: -9))
            + [poly([p(4, 76), p(50, 70), p(96, 76), p(96, 95), p(50, 88), p(4, 95)], 0.06,
                    .secondary)]
    case 2:
        return [ring(p(50, 50), 48, 36, .secondary)] + fitted(base, scale: 0.64)
    case 3:
        return fitted(base, scale: 0.82, dy: -9)
            + [poly([p(6, 72), p(50, 64), p(94, 72), p(50, 98)], 0.06, .secondary)]
    case 4:
        let frame = [poly([p(9, 5), p(91, 5), p(91, 50), p(50, 97), p(9, 50)], 0.06, .primary)]
        return frame + fitted(recoloured(frame, .paper), scale: 0.80, dy: -1)
            + fitted(base, scale: 0.60, dy: -6)
    case 5:
        let frame = [poly([p(11, 4), p(89, 4), p(89, 70), p(50, 96), p(11, 70)], 0.04, .secondary)]
        return frame + fitted(recoloured(frame, .primary), scale: 0.82, dy: -1)
            + fitted(swappedRoles(base), scale: 0.58, dy: -9)
    default:
        let frame = [poly([p(50, 2), p(98, 50), p(50, 98), p(2, 50)], 0.05, .primary)]
        return frame + fitted(recoloured(frame, .paper), scale: 0.78)
            + mirrored(fitted(base, scale: 0.56))
    }
}

// MARK: - motif selection

func marks(family: String, index: Int) -> [Mark] {
    switch family {
    case "animalCreature":
        return variant(index / 4, applyingTo: [raptorHead, felineHead, hornedHead,
                                               canineHead][index % 4]())
    case "originalCharacter":
        let hat = index / 4
        return variant(hat, applyingTo: characterHead(index) + headgear(hat))
    case "regionalSymbol":
        return variant(index / 7, applyingTo: regionalMotif(index))
    case "equipmentVehicle":
        return variant(index / 7 * 2, applyingTo: equipmentMotif(index))
    case "framedEmblem":
        let frame = frameShape(index)
        return frame + fitted(recoloured(frame, .paper), scale: 0.80)
            + fitted(frameDevice(index / 5), scale: 0.62)
    default:
        return variant([0, 2, 3][min(index / 9, 2)], applyingTo: motionMotif(index))
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

let motifNames: [String: [String]] = [
    "animalCreature": ["raptor head", "big-cat head", "horned head", "long-jawed head"],
    "originalCharacter": ["broad profile", "angular profile", "square profile", "lean profile"],
    "regionalSymbol": ["peak range", "field star", "arrowhead", "anchor", "pine stand",
                       "wave crest", "sunburst horizon"],
    "equipmentVehicle": ["helmet profile", "engine front", "prow and sail", "launch stack",
                         "drive wheel", "anvil", "bolt wheel"],
    "framedEmblem": ["shield", "roundel", "pennant", "hexagon", "diamond"],
    "abstractMotion": ["sweep", "bolt", "stripe fan", "chevron stack", "comet", "wing", "flame",
                       "concentric target", "arrow cluster"],
]

let variantNames = ["plain", "mirrored over a base bar", "inside a ring", "on a wedge plinth",
                    "on a shield", "on a pennant", "mirrored in a diamond"]

func treatment(family: String, index: Int) -> (motif: String, variant: String) {
    let names = motifNames[family] ?? ["mark"]
    switch family {
    case "animalCreature":
        return (names[index % 4], variantNames[(index / 4) % 7])
    case "originalCharacter":
        return (names[index % 4] + " under headgear \(index / 4 % 7 + 1)",
                variantNames[(index / 4) % 7])
    case "framedEmblem":
        return (names[index % 5] + " frame", "device \(index / 5 % 6 + 1)")
    case "abstractMotion":
        return (names[index % 9], variantNames[[0, 2, 3][min(index / 9, 2)]])
    default:
        let step = family == "equipmentVehicle" ? 2 : 1
        return (names[index % 7], variantNames[(index / 7 * step) % 7])
    }
}

func separationNote(_ nudge: Nudge) -> String {
    var parts: [String] = []
    if nudge.mirror { parts.append("mirrored") }
    if nudge.angle != 0 { parts.append("turned \(Int(nudge.angle)) degrees") }
    if nudge.scale != 1 { parts.append("drawn at \(Int(nudge.scale * 100)) per cent") }
    if nudge.swap { parts.append("with the two colours exchanged") }
    if nudge.invert { parts.append("with the highlight and keyline inverted") }
    return parts.isEmpty ? "" : ", " + parts.joined(separator: ", ")
}

func description(family: String, index: Int, nudge: Nudge)
    -> (concept: String, prompt: String) {
    let shape = treatment(family: family, index: index)
    let separation = separationNote(nudge)
    let concept = "An original flat \(shape.motif), \(shape.variant)\(separation)."
    let prompt = """
    Drawn by Tools/TeamLogos/generate_logos.swift from this record alone.
    Motif family \(family); silhouette \(shape.motif); treatment \(shape.variant)\(separation).
    Flat fills in the record's two colours with a single keyline and a halo, no lettering, no \
    gradient, no photograph, and no real club, school, conference or event identity.
    Output one \(outputSize) x \(outputSize) PNG with transparent edges.
    """
    return (concept, prompt)
}

// MARK: - main

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let manifestURL = root.appendingPathComponent("Tools/TeamLogos/manifest.json")
let assetsURL = root.appendingPathComponent(
    "Sources/ProFootballCoachUI/Resources/TeamLogos.xcassets"
)
let updateManifest = CommandLine.arguments.contains("--manifest")

var manifest = try JSONDecoder().decode(Manifest.self, from: Data(contentsOf: manifestURL))
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
    let base = marks(family: record.family, index: slot)
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

if updateManifest {
    let note = "Redrawn as flat vector artwork on 2026-08-21; owner re-approval of the specimen "
        + "is outstanding."
    manifest.teams = manifest.teams.map { record in
        var copy = record
        let text = description(
            family: record.family,
            index: slotByID[record.stableID] ?? 0,
            nudge: nudgeByID[record.stableID]
                ?? Nudge(swap: false, invert: false, scale: 1, angle: 0, mirror: false)
        )
        copy.concept = text.concept
        copy.prompt = text.prompt
        copy.reviewNotes = note
        return copy
    }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(manifest).write(to: manifestURL, options: .atomic)
}

print("wrote \(written) marks at \(outputSize)x\(outputSize); \(nudgeCount) needed a nudge")
