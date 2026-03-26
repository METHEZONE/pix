import AppKit

struct GlowStyle {
    let color: NSColor
    let intensity: CGFloat       // 0.5 - 2.0
    let trailLength: CGFloat     // 0.5 - 3.0 (lifetime multiplier)
    let trailColor: NSColor
    let pulseRate: CFTimeInterval // seconds per pulse cycle
    let particleSize: CGFloat    // base size in points

    static let defaultGlow = GlowStyle(
        color: NSColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0),
        intensity: 1.0,
        trailLength: 1.5,
        trailColor: NSColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 0.6),
        pulseRate: 3.0,
        particleSize: 12.0
    )
}
