import AppKit
import QuartzCore

protocol FireflyRenderer: AnyObject {
    func configure(style: GlowStyle)
    func attach(to layer: CALayer)
    func updatePosition(x: CGFloat, y: CGFloat)
    func setPulse(rate: CFTimeInterval)
    func setTrailEnabled(_ enabled: Bool)
    func dim()
    func brighten()
}
