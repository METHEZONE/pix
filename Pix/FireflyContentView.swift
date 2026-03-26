import AppKit

class FireflyContentView: NSView {
    weak var character: FireflyCharacter?
    private var isDragging = false
    private var lastDragLoc: NSPoint = .zero
    private var lastDragTime: CFTimeInterval = 0
    private var dragVelocity: CGPoint = .zero  // pixels/sec

    override func hitTest(_ point: NSPoint) -> NSView? {
        let localPoint = convert(point, from: superview)
        guard bounds.contains(localPoint) else { return nil }
        // Generous hit area (50pt radius from center)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let dx = localPoint.x - center.x
        let dy = localPoint.y - center.y
        if dx * dx + dy * dy <= 55 * 55 { return self }
        return nil
    }

    override func mouseDown(with event: NSEvent) {
        lastDragLoc = NSEvent.mouseLocation
        lastDragTime = CACurrentMediaTime()
        dragVelocity = .zero
        isDragging = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let char = character, let win = window else { return }

        if !isDragging {
            isDragging = true
            char.startDrag()
        }

        let now = CACurrentMediaTime()
        let loc = NSEvent.mouseLocation
        let dt = max(now - lastDragTime, 0.001)

        // Track velocity (exponential moving average for smooth fling)
        let rawVx = (loc.x - lastDragLoc.x) / CGFloat(dt)
        let rawVy = (loc.y - lastDragLoc.y) / CGFloat(dt)
        dragVelocity.x = dragVelocity.x * 0.6 + rawVx * 0.4
        dragVelocity.y = dragVelocity.y * 0.6 + rawVy * 0.4

        lastDragLoc = loc
        lastDragTime = now

        let newX = loc.x - 60
        let newY = loc.y - 60
        win.setFrameOrigin(NSPoint(x: newX, y: newY))
        char.position = CGPoint(x: loc.x, y: loc.y)
        char.flightBehavior.position = char.position
        char.renderer.updatePosition(x: 60, y: 60)
    }

    override func mouseUp(with event: NSEvent) {
        if isDragging {
            isDragging = false
            // Fling! Pass velocity to character physics
            let speed = sqrt(dragVelocity.x * dragVelocity.x + dragVelocity.y * dragVelocity.y)
            if speed > 100 {
                // Clamp max fling speed
                let maxSpeed: CGFloat = 1500
                let clampedSpeed = min(speed, maxSpeed)
                let scale = clampedSpeed / speed
                character?.fling(velocity: CGPoint(x: dragVelocity.x * scale, y: dragVelocity.y * scale))
            } else {
                character?.endDrag()
            }
        } else {
            character?.handleClick()
        }
    }
}
