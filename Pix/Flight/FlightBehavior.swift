import Foundation
import CoreGraphics
import QuartzCore

struct FlightPersonality {
    let speedRange: ClosedRange<CGFloat>
    let turnRate: CGFloat
    let pauseFrequency: CGFloat
    let pauseDuration: ClosedRange<Double>
    let wanderScale: Double
    let swimPulseInterval: Double  // seconds between jellyfish pulses

    static let defaultPersonality = FlightPersonality(
        speedRange: 30...80,
        turnRate: 1.0,
        pauseFrequency: 0.08,
        pauseDuration: 3.0...8.0,
        wanderScale: 0.3,
        swimPulseInterval: 1.8
    )
}

class FlightBehavior {
    private let noise: PerlinNoise
    private let personality: FlightPersonality
    private var timeOffset: Double

    var heading: CGFloat = 0
    var speed: CGFloat = 0       // current speed (jellyfish: bursts then coasts)
    var targetSpeed: CGFloat = 50
    var position: CGPoint = .zero

    // Jellyfish swim state
    private var lastPulseTime: CFTimeInterval = 0
    private var isPulseCoasting = true  // decelerating after pulse
    var onSwimPulse: ((CGFloat) -> Void)?  // callback to renderer for animation

    init(personality: FlightPersonality, seed: Int) {
        self.noise = PerlinNoise(seed: seed)
        self.personality = personality
        self.timeOffset = Double.random(in: 0...1000)
        self.heading = CGFloat.random(in: 0...(2 * .pi))
        self.speed = personality.speedRange.lowerBound
    }

    func update(dt: CGFloat, screenBounds: CGRect, siblings: [CGPoint]) -> CGPoint {
        let now = CACurrentMediaTime()
        let time = now + timeOffset

        // 1. Wander: Perlin noise drives heading angle change rate
        let noiseVal = noise.octaveNoise2D(
            x: time * personality.wanderScale,
            y: Double(position.x) * 0.001 + Double(position.y) * 0.001,
            octaves: 2
        )
        heading += CGFloat(noiseVal) * personality.turnRate * dt * 0.8

        // 2. Jellyfish swim pulse
        let pulseInterval = personality.swimPulseInterval
        if now - lastPulseTime > pulseInterval {
            // PULSE: burst of speed in current heading direction
            lastPulseTime = now
            isPulseCoasting = false
            let burstSpeed = personality.speedRange.upperBound * CGFloat.random(in: 0.8...1.2)
            targetSpeed = burstSpeed

            // Trigger cap animation
            onSwimPulse?(1.0)
        }

        // Speed envelope: quick acceleration on pulse, slow deceleration (coast)
        if !isPulseCoasting {
            speed += (targetSpeed - speed) * dt * 8.0  // fast ramp up
            if speed >= targetSpeed * 0.9 {
                isPulseCoasting = true
                targetSpeed = personality.speedRange.lowerBound * 0.3  // coast to near-stop
            }
        } else {
            // Gentle deceleration (jellyfish coast)
            speed += (targetSpeed - speed) * dt * 1.5
            speed = max(speed, personality.speedRange.lowerBound * 0.2) // never fully stop
        }

        // 3. Screen edge avoidance
        let margin: CGFloat = 100
        let force: CGFloat = 2.5
        if position.x < screenBounds.minX + margin {
            let s = 1.0 - (position.x - screenBounds.minX) / margin
            heading += s * force * dt
        }
        if position.x > screenBounds.maxX - margin {
            let s = 1.0 - (screenBounds.maxX - position.x) / margin
            heading -= s * force * dt
        }
        if position.y < screenBounds.minY + margin {
            let s = 1.0 - (position.y - screenBounds.minY) / margin
            let upAngle = CGFloat.pi / 2
            heading += (upAngle - heading) * s * dt * 0.8
        }
        if position.y > screenBounds.maxY - margin {
            let s = 1.0 - (screenBounds.maxY - position.y) / margin
            let downAngle = -CGFloat.pi / 2
            heading += (downAngle - heading) * s * dt * 0.8
        }

        // 4. Separation
        for sib in siblings {
            let dx = position.x - sib.x, dy = position.y - sib.y
            let dist = sqrt(dx * dx + dy * dy)
            if dist < 150 && dist > 0.1 {
                let s = (1.0 - dist / 150) * 1.5
                let away = atan2(dy, dx)
                heading += (away - heading) * s * dt * 0.3
            }
        }

        // 5. Apply movement
        let vx = cos(heading) * speed
        let vy = sin(heading) * speed
        position.x += vx * dt
        position.y += vy * dt

        // 6. Clamp
        position.x = max(screenBounds.minX + 10, min(position.x, screenBounds.maxX - 10))
        position.y = max(screenBounds.minY + 10, min(position.y, screenBounds.maxY - 10))

        return position
    }
}
