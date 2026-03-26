import Foundation

struct PerlinNoise {
    private let permutation: [Int]

    init(seed: Int = 0) {
        var perm = Array(0..<256)
        var rng = SeededRNG(seed: UInt64(bitPattern: Int64(seed)))
        perm.shuffle(using: &rng)
        permutation = perm + perm // Double for wrapping
    }

    func noise2D(x: Double, y: Double) -> Double {
        let xi = Int(floor(x)) & 255
        let yi = Int(floor(y)) & 255
        let xf = x - floor(x)
        let yf = y - floor(y)

        let u = fade(xf)
        let v = fade(yf)

        let aa = permutation[permutation[xi] + yi]
        let ab = permutation[permutation[xi] + yi + 1]
        let ba = permutation[permutation[xi + 1] + yi]
        let bb = permutation[permutation[xi + 1] + yi + 1]

        let x1 = lerp(grad(hash: aa, x: xf, y: yf), grad(hash: ba, x: xf - 1, y: yf), t: u)
        let x2 = lerp(grad(hash: ab, x: xf, y: yf - 1), grad(hash: bb, x: xf - 1, y: yf - 1), t: u)

        return lerp(x1, x2, t: v)
    }

    /// Multi-octave noise for richer variation
    func octaveNoise2D(x: Double, y: Double, octaves: Int = 3, persistence: Double = 0.5) -> Double {
        var total = 0.0
        var frequency = 1.0
        var amplitude = 1.0
        var maxValue = 0.0

        for _ in 0..<octaves {
            total += noise2D(x: x * frequency, y: y * frequency) * amplitude
            maxValue += amplitude
            amplitude *= persistence
            frequency *= 2.0
        }

        return total / maxValue
    }

    private func fade(_ t: Double) -> Double {
        t * t * t * (t * (t * 6 - 15) + 10)
    }

    private func lerp(_ a: Double, _ b: Double, t: Double) -> Double {
        a + t * (b - a)
    }

    private func grad(hash: Int, x: Double, y: Double) -> Double {
        let h = hash & 3
        let u = h < 2 ? x : y
        let v = h < 2 ? y : x
        return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v)
    }
}

private struct SeededRNG: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 12345 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
