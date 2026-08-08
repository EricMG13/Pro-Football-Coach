import Foundation
import FootballSimCore

func runSeededRandomTests() {
    suite("SeededRandom") {
        test("determinism for same seed") {
            var a = SeededRandom(seed: 42), b = SeededRandom(seed: 42)
            expect((0..<100).map { _ in a.next() } == (0..<100).map { _ in b.next() })
        }

        test("different seeds diverge") {
            var a = SeededRandom(seed: 1), b = SeededRandom(seed: 2)
            expect((0..<20).map { _ in a.next() } != (0..<20).map { _ in b.next() })
        }

        test("int stays in bounds") {
            var r = SeededRandom(seed: 1)
            var ok = true
            for _ in 0..<5_000 where !(40...99).contains(r.int(in: 40...99)) { ok = false }
            expect(ok, "int(in:) escaped its range")
        }

        test("int handles single-value range") {
            var r = SeededRandom(seed: 3)
            expectEqual(r.int(in: 7...7), 7)
        }

        test("int covers whole range") {
            var r = SeededRandom(seed: 11)
            var seen = Set<Int>()
            for _ in 0..<2_000 { seen.insert(r.int(in: 0...9)) }
            expectEqual(seen.count, 10, "uniform coverage of 0...9")
        }

        test("double01 stays in unit interval") {
            var r = SeededRandom(seed: 5)
            var ok = true
            for _ in 0..<5_000 {
                let d = r.double01()
                if d < 0 || d >= 1 { ok = false }
            }
            expect(ok, "double01 outside [0,1)")
        }

        test("gaussian matches requested moments") {
            var r = SeededRandom(seed: 7)
            let xs = (0..<40_000).map { _ in r.gaussian(mean: 70, sd: 8) }
            let mean = xs.reduce(0, +) / Double(xs.count)
            let sd = (xs.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(xs.count)).squareRoot()
            expectClose(mean, 70, 0.4, "sample mean")
            expectClose(sd, 8, 0.4, "sample sd")
        }

        test("chance matches requested frequency") {
            var r = SeededRandom(seed: 13)
            let hits = (0..<20_000).filter { _ in r.chance(0.25) }.count
            expectClose(Double(hits) / 20_000, 0.25, 0.02, "p=0.25 frequency")
            expect(r.chance(0) == false, "p=0 must never hit")
            expect(r.chance(1) == true, "p=1 must always hit")
        }

        test("pick and shuffle stay in domain") {
            var r = SeededRandom(seed: 17)
            let source = Array(1...10)
            var ok = true
            for _ in 0..<500 where !source.contains(r.pick(source)) { ok = false }
            expect(ok, "pick returned a foreign element")
            expect(r.shuffled(source).sorted() == source, "shuffle must be a permutation")
        }

        test("shuffle reorders") {
            var r = SeededRandom(seed: 19)
            expect(r.shuffled(Array(1...50)) != Array(1...50))
        }

        test("codable round trip continues stream") {
            var a = SeededRandom(seed: 9)
            _ = a.next()
            let data = try JSONEncoder().encode(a)
            var restored = try JSONDecoder().decode(SeededRandom.self, from: data)
            var original = a
            expectEqual(original.next(), restored.next())
            expectEqual(original.next(), restored.next())
        }
    }
}
