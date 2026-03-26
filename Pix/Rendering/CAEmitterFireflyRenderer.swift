import AppKit
import QuartzCore

class CAEmitterFireflyRenderer: FireflyRenderer {
    private var emitterLayer: CAEmitterLayer?
    private var trailLayer: CAEmitterLayer?
    private(set) var bodyLayer: CAShapeLayer?
    private var innerGlow: CALayer?
    private var leftEye: CALayer?
    private var rightEye: CALayer?
    private var glowStyle: GlowStyle = .defaultGlow
    private var bobPhase: CGFloat = CGFloat.random(in: 0...(.pi * 2))
    private var morphTimer: Timer?
    private var bodySize: CGFloat = 30

    var isBeingDragged = false

    // MARK: - Glow Texture

    private static func makeGlowTexture(size: Int = 64) -> CGImage? {
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: size, height: size,
            bitsPerComponent: 8, bytesPerRow: size * 4, space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        let c = CGPoint(x: CGFloat(size) / 2, y: CGFloat(size) / 2)
        let r = CGFloat(size) / 2
        let g = CGGradient(colorsSpace: cs, colors: [
            NSColor.white.withAlphaComponent(1.0).cgColor,
            NSColor.white.withAlphaComponent(0.55).cgColor,
            NSColor.white.withAlphaComponent(0.1).cgColor,
            NSColor.white.withAlphaComponent(0.0).cgColor
        ] as CFArray, locations: [0.0, 0.18, 0.5, 1.0])!
        ctx.drawRadialGradient(g, startCenter: c, startRadius: 0, endCenter: c, endRadius: r, options: .drawsAfterEndLocation)
        return ctx.makeImage()
    }

    // MARK: - Blob Path Generation

    private func blobPath(center: CGPoint, radius: CGFloat, wobble: CGFloat = 0, phase: CGFloat = 0) -> CGPath {
        let path = CGMutablePath()
        let points = 8
        var pts: [CGPoint] = []
        for i in 0..<points {
            let angle = CGFloat(i) / CGFloat(points) * .pi * 2
            let wobbleR = radius + sin(angle * 3 + phase) * wobble * radius
            pts.append(CGPoint(x: center.x + cos(angle) * wobbleR,
                              y: center.y + sin(angle) * wobbleR))
        }
        // Smooth catmull-rom style with quad curves
        path.move(to: midpoint(pts[pts.count - 1], pts[0]))
        for i in 0..<pts.count {
            let next = (i + 1) % pts.count
            let mid = midpoint(pts[i], pts[next])
            path.addQuadCurve(to: mid, control: pts[i])
        }
        path.closeSubpath()
        return path
    }

    private func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }

    // Shape morphing paths
    private func heartPath(center: CGPoint, size: CGFloat) -> CGPath {
        let s = size * 0.9
        let p = CGMutablePath()
        p.move(to: CGPoint(x: center.x, y: center.y - s * 0.4))
        p.addCurve(to: CGPoint(x: center.x - s, y: center.y + s * 0.2),
                   control1: CGPoint(x: center.x - s * 0.1, y: center.y + s * 0.2),
                   control2: CGPoint(x: center.x - s, y: center.y + s * 0.6))
        p.addCurve(to: CGPoint(x: center.x, y: center.y + s),
                   control1: CGPoint(x: center.x - s, y: center.y - s * 0.2),
                   control2: CGPoint(x: center.x, y: center.y + s * 0.3))
        p.addCurve(to: CGPoint(x: center.x + s, y: center.y + s * 0.2),
                   control1: CGPoint(x: center.x, y: center.y + s * 0.3),
                   control2: CGPoint(x: center.x + s, y: center.y - s * 0.2))
        p.addCurve(to: CGPoint(x: center.x, y: center.y - s * 0.4),
                   control1: CGPoint(x: center.x + s, y: center.y + s * 0.6),
                   control2: CGPoint(x: center.x + s * 0.1, y: center.y + s * 0.2))
        p.closeSubpath()
        return p
    }

    private func starPath(center: CGPoint, size: CGFloat) -> CGPath {
        let p = CGMutablePath()
        let outerR = size * 0.9
        let innerR = size * 0.4
        for i in 0..<10 {
            let angle = CGFloat(i) / 10.0 * .pi * 2 - .pi / 2
            let r = i % 2 == 0 ? outerR : innerR
            let pt = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }

    // MARK: - Configure

    func configure(style: GlowStyle) {
        self.glowStyle = style
        guard let texture = Self.makeGlowTexture() else { return }
        let s = style.particleSize
        bodySize = s * 1.4

        // --- Glow particles ---
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: 60, y: 60)
        emitter.emitterSize = CGSize(width: 10, height: 10)
        emitter.emitterShape = .circle
        emitter.renderMode = .additive
        let cell = CAEmitterCell()
        cell.contents = texture
        cell.birthRate = 20
        cell.lifetime = 0.7
        cell.velocity = 3
        cell.velocityRange = 2
        cell.scale = s / 64.0 * style.intensity * 2.2
        cell.scaleRange = s / 64.0 * 0.6
        cell.alphaSpeed = -1.0
        cell.color = style.color.withAlphaComponent(0.4).cgColor
        cell.emissionRange = .pi * 2
        emitter.emitterCells = [cell]
        emitterLayer = emitter

        // --- Trail ---
        let trail = CAEmitterLayer()
        trail.emitterPosition = CGPoint(x: 60, y: 60)
        trail.emitterSize = CGSize(width: 4, height: 4)
        trail.emitterShape = .point
        trail.renderMode = .additive
        let tc = CAEmitterCell()
        tc.contents = texture
        tc.birthRate = 16
        tc.lifetime = Float(2.0 * style.trailLength)
        tc.velocity = 1.5
        tc.velocityRange = 1
        tc.scale = s / 64.0 * 0.5
        tc.scaleSpeed = -0.008
        tc.alphaSpeed = Float(-0.4 / style.trailLength)
        tc.color = style.trailColor.cgColor
        tc.yAcceleration = -0.8
        tc.emissionRange = .pi * 2
        trail.emitterCells = [tc]
        trailLayer = trail

        // --- Body (organic blob shape) ---
        let center = CGPoint(x: 60, y: 60)
        let body = CAShapeLayer()
        body.path = blobPath(center: center, radius: bodySize, wobble: 0.12, phase: 0)
        body.fillColor = style.color.withAlphaComponent(0.7).cgColor
        body.strokeColor = style.color.withAlphaComponent(0.3).cgColor
        body.lineWidth = 1.0
        body.shadowColor = style.color.withAlphaComponent(0.95).cgColor
        body.shadowOffset = .zero
        body.shadowRadius = s * 1.5
        body.shadowOpacity = 1.0
        bodyLayer = body

        // Inner highlight (gives depth)
        let inner = CALayer()
        let innerSize = bodySize * 1.0
        inner.bounds = CGRect(x: 0, y: 0, width: innerSize, height: innerSize)
        inner.position = CGPoint(x: 60, y: 62)
        inner.cornerRadius = innerSize / 2
        inner.backgroundColor = style.color.blended(withFraction: 0.5, of: .white)?.withAlphaComponent(0.25).cgColor
        innerGlow = inner

        // --- Eyes (small, cute dots — like a slime) ---
        let eyeSpacing: CGFloat = s * 0.4
        let eyeY: CGFloat = 62

        let lE = makeSlimeEye(size: s * 0.28)
        lE.position = CGPoint(x: 60 - eyeSpacing, y: eyeY)
        leftEye = lE

        let rE = makeSlimeEye(size: s * 0.28)
        rE.position = CGPoint(x: 60 + eyeSpacing, y: eyeY)
        rightEye = rE
    }

    private func makeSlimeEye(size: CGFloat) -> CALayer {
        let eye = CALayer()
        eye.bounds = CGRect(x: 0, y: 0, width: size, height: size * 1.1)
        eye.cornerRadius = size / 2
        eye.backgroundColor = NSColor(red: 0.1, green: 0.08, blue: 0.15, alpha: 0.8).cgColor

        // Tiny highlight
        let hl = CALayer()
        let hlS = size * 0.35
        hl.bounds = CGRect(x: 0, y: 0, width: hlS, height: hlS)
        hl.cornerRadius = hlS / 2
        hl.backgroundColor = NSColor.white.withAlphaComponent(0.7).cgColor
        hl.position = CGPoint(x: size * 0.6, y: size * 0.3)
        eye.addSublayer(hl)

        return eye
    }

    // MARK: - Attach

    func attach(to layer: CALayer) {
        if let t = trailLayer { layer.addSublayer(t) }
        if let e = emitterLayer { layer.addSublayer(e) }
        if let b = bodyLayer { layer.addSublayer(b) }
        if let ig = innerGlow { layer.addSublayer(ig) }
        if let le = leftEye { layer.addSublayer(le) }
        if let re = rightEye { layer.addSublayer(re) }
        startBlink()
        startWobble()
        startGlowPulse()
        startShapeMorphing()
    }

    // MARK: - Update

    func updatePosition(x: CGFloat, y: CGFloat) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        emitterLayer?.emitterPosition = CGPoint(x: x, y: y)
        trailLayer?.emitterPosition = CGPoint(x: x, y: y - 5)

        bobPhase += 0.04
        let bobY = sin(bobPhase) * 2.5
        let bobX = cos(bobPhase * 0.7) * 1.2

        let bx = x + bobX, by = y + bobY
        let center = CGPoint(x: bx, y: by)

        // Update blob path with organic wobble
        bodyLayer?.path = blobPath(center: center, radius: bodySize, wobble: 0.1, phase: bobPhase * 1.5)
        innerGlow?.position = CGPoint(x: bx, y: by + 2)

        let eyeSpacing = glowStyle.particleSize * 0.4
        leftEye?.position = CGPoint(x: bx - eyeSpacing, y: by + 2)
        rightEye?.position = CGPoint(x: bx + eyeSpacing, y: by + 2)

        CATransaction.commit()
    }

    func applySquish(vx: CGFloat, vy: CGFloat) {
        let speed = sqrt(vx * vx + vy * vy)
        guard speed > 8 else {
            bodyLayer?.transform = CATransform3DIdentity
            return
        }
        let angle = atan2(vy, vx)
        let stretch = min(speed / 500.0, 0.25)
        var t = CATransform3DIdentity
        t = CATransform3DRotate(t, angle, 0, 0, 1)
        t = CATransform3DScale(t, 1.0 + stretch, 1.0 - stretch * 0.4, 1.0)
        t = CATransform3DRotate(t, -angle, 0, 0, 1)
        CATransaction.begin(); CATransaction.setAnimationDuration(0.1)
        bodyLayer?.transform = t
        CATransaction.commit()
    }

    func jellyBounce() {
        let b = CASpringAnimation(keyPath: "transform.scale")
        b.fromValue = 0.75; b.toValue = 1.0
        b.damping = 5; b.stiffness = 250; b.mass = 0.6
        b.duration = b.settlingDuration
        bodyLayer?.add(b, forKey: "jellyBounce")
    }

    func setPulse(rate: CFTimeInterval) {}
    func setTrailEnabled(_ enabled: Bool) { trailLayer?.birthRate = enabled ? 1.0 : 0.0 }

    func dim() {
        CATransaction.begin(); CATransaction.setAnimationDuration(0.3)
        emitterLayer?.opacity = 0.15; trailLayer?.opacity = 0.05
        bodyLayer?.opacity = 0.4; innerGlow?.opacity = 0.2
        leftEye?.opacity = 0.3; rightEye?.opacity = 0.3
        CATransaction.commit()
    }

    func brighten() {
        CATransaction.begin(); CATransaction.setAnimationDuration(0.3)
        emitterLayer?.opacity = 1.0; trailLayer?.opacity = 1.0
        bodyLayer?.opacity = 1.0; innerGlow?.opacity = 1.0
        leftEye?.opacity = 1.0; rightEye?.opacity = 1.0
        CATransaction.commit()
    }

    // MARK: - Shape Morphing

    private func startShapeMorphing() {
        scheduleNextMorph()
    }

    private func scheduleNextMorph() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 25.0...50.0)) { [weak self] in
            guard let self = self, !self.isBeingDragged else { self?.scheduleNextMorph(); return }
            self.doShapeMorph()
            self.scheduleNextMorph()
        }
    }

    func doShapeMorph() {
        guard let body = bodyLayer else { return }
        let center = body.path?.boundingBox.center ?? CGPoint(x: 60, y: 60)

        let shapes: [() -> CGPath] = [
            { self.heartPath(center: center, size: self.bodySize) },
            { self.starPath(center: center, size: self.bodySize) },
        ]

        guard let targetPath = shapes.randomElement()?() else { return }
        let originalPath = blobPath(center: center, radius: bodySize, wobble: 0.1, phase: bobPhase)

        // Morph to shape
        let toShape = CABasicAnimation(keyPath: "path")
        toShape.toValue = targetPath
        toShape.duration = 0.8
        toShape.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        toShape.fillMode = .forwards
        toShape.isRemovedOnCompletion = false
        body.add(toShape, forKey: "morphTo")

        // Extra glow burst during morph
        let oldRate = emitterLayer?.birthRate ?? 1.0
        emitterLayer?.birthRate = 4.0

        // Morph back after holding
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self = self else { return }
            let back = CABasicAnimation(keyPath: "path")
            back.toValue = originalPath
            back.duration = 0.6
            back.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            body.add(back, forKey: "morphBack")
            body.removeAnimation(forKey: "morphTo")
            self.emitterLayer?.birthRate = oldRate
        }
    }

    // MARK: - Reactions

    func reactToGrab() {
        isBeingDragged = true
        let squish = CASpringAnimation(keyPath: "transform.scale")
        squish.toValue = 0.8; squish.damping = 8; squish.stiffness = 300; squish.mass = 0.5
        squish.duration = squish.settlingDuration
        squish.fillMode = .forwards; squish.isRemovedOnCompletion = false
        bodyLayer?.add(squish, forKey: "grab")

        // Eyes widen slightly
        let big = CABasicAnimation(keyPath: "transform.scale")
        big.toValue = 1.3; big.duration = 0.15
        big.fillMode = .forwards; big.isRemovedOnCompletion = false
        leftEye?.add(big, forKey: "surprise"); rightEye?.add(big, forKey: "surprise")

        emitterLayer?.birthRate = 3.0
    }

    func reactToRelease() {
        isBeingDragged = false
        bodyLayer?.removeAnimation(forKey: "grab")
        leftEye?.removeAnimation(forKey: "surprise")
        rightEye?.removeAnimation(forKey: "surprise")
        emitterLayer?.birthRate = 1.0
        jellyBounce()
    }

    func reactToFling() {
        emitterLayer?.birthRate = 4.0
    }

    func reactToWallBounce() {
        jellyBounce()
        // Dizzy eyes
        let shake = CABasicAnimation(keyPath: "position.x")
        shake.byValue = 2; shake.duration = 0.04; shake.autoreverses = true; shake.repeatCount = 3
        leftEye?.add(shake, forKey: "dizzy"); rightEye?.add(shake, forKey: "dizzy")
        emitterLayer?.birthRate = 1.0
    }

    func reactToClick() {
        let pop = CASpringAnimation(keyPath: "transform.scale")
        pop.fromValue = 1.0; pop.toValue = 1.2
        pop.damping = 5; pop.stiffness = 400; pop.mass = 0.3
        pop.duration = pop.settlingDuration; pop.autoreverses = true
        bodyLayer?.add(pop, forKey: "clickPop")

        // Happy squint
        let squint = CABasicAnimation(keyPath: "transform.scale.y")
        squint.toValue = 0.3; squint.duration = 0.1; squint.autoreverses = true
        leftEye?.add(squint, forKey: "squint"); rightEye?.add(squint, forKey: "squint")

        let old = emitterLayer?.birthRate ?? 1.0
        emitterLayer?.birthRate = 5.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.emitterLayer?.birthRate = old }
    }

    // Idle
    func doSleepyEyes() {
        let droop = CABasicAnimation(keyPath: "transform.scale.y")
        droop.toValue = 0.2; droop.duration = 0.5
        droop.fillMode = .forwards; droop.isRemovedOnCompletion = false
        leftEye?.add(droop, forKey: "sleepy"); rightEye?.add(droop, forKey: "sleepy")
    }

    func doWakeUp() {
        leftEye?.removeAnimation(forKey: "sleepy"); rightEye?.removeAnimation(forKey: "sleepy")
    }

    func doLookAt(direction: CGFloat) {
        let offset = direction * 1.5
        CATransaction.begin(); CATransaction.setAnimationDuration(0.2)
        leftEye?.position.x += offset; rightEye?.position.x += offset
        CATransaction.commit()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self = self else { return }
            CATransaction.begin(); CATransaction.setAnimationDuration(0.3)
            self.leftEye?.position.x -= offset; self.rightEye?.position.x -= offset
            CATransaction.commit()
        }
    }

    func setMouth(_ style: MouthStyle) {
        // No mouth in slime design — expressions through eyes + body shape only
    }

    enum MouthStyle { case happy, surprised, sleeping, excited }

    // MARK: - Animations

    private func startBlink() { scheduleBlink() }
    private func scheduleBlink() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2.5...5.0)) { [weak self] in
            guard let self = self, !self.isBeingDragged else { self?.scheduleBlink(); return }
            let close = CABasicAnimation(keyPath: "transform.scale.y")
            close.toValue = 0.05; close.duration = 0.06; close.autoreverses = true
            self.leftEye?.add(close, forKey: "blink"); self.rightEye?.add(close, forKey: "blink")
            self.scheduleBlink()
        }
    }

    private func startWobble() {
        // Continuous organic wobble on the blob
        let wobble = CABasicAnimation(keyPath: "path")
        wobble.duration = 3.0
        wobble.autoreverses = true
        wobble.repeatCount = .infinity
        wobble.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        let c = CGPoint(x: 60, y: 60)
        wobble.fromValue = blobPath(center: c, radius: bodySize, wobble: 0.08, phase: 0)
        wobble.toValue = blobPath(center: c, radius: bodySize, wobble: 0.15, phase: 2.0)
        bodyLayer?.add(wobble, forKey: "wobble")
    }

    private func startGlowPulse() {
        let pulse = CABasicAnimation(keyPath: "shadowRadius")
        pulse.fromValue = glowStyle.particleSize * 1.0
        pulse.toValue = glowStyle.particleSize * 2.0
        pulse.duration = glowStyle.pulseRate; pulse.autoreverses = true
        pulse.repeatCount = .infinity
        bodyLayer?.add(pulse, forKey: "glowPulse")

        let op = CABasicAnimation(keyPath: "shadowOpacity")
        op.fromValue = 0.6; op.toValue = 1.0
        op.duration = glowStyle.pulseRate; op.autoreverses = true
        op.repeatCount = .infinity
        bodyLayer?.add(op, forKey: "glowOp")
    }
}

private extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
