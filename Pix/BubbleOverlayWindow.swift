import AppKit

class BubbleOverlayWindow {
    private let window: NSWindow
    private let containerView: NSView
    private var bubbleViews = [String: PixelBubbleView]()

    init() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 20)
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]

        containerView = NSView(frame: screen.frame)
        containerView.wantsLayer = true
        window.contentView = containerView
        window.orderFrontRegardless()
    }

    func showBubble(id: String, text: String, at point: NSPoint, isCompletion: Bool) {
        let screenOrigin = window.frame.origin

        if let existing = bubbleViews[id] {
            existing.update(text: text, isCompletion: isCompletion)
            let localX = point.x - screenOrigin.x - existing.frame.width / 2
            let localY = point.y - screenOrigin.y
            existing.frame.origin = NSPoint(x: localX, y: localY)
            existing.isHidden = false
            return
        }

        let bubble = PixelBubbleView(text: text, isCompletion: isCompletion)
        let localX = point.x - screenOrigin.x - bubble.frame.width / 2
        let localY = point.y - screenOrigin.y
        bubble.frame.origin = NSPoint(x: localX, y: localY)
        containerView.addSubview(bubble)
        bubbleViews[id] = bubble

        // Fade in
        bubble.alphaValue = 0
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            bubble.animator().alphaValue = 1.0
        }
    }

    func hideBubble(id: String) {
        guard let bubble = bubbleViews[id], !bubble.isHidden else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.2
            bubble.animator().alphaValue = 0
        }, completionHandler: {
            bubble.isHidden = true
        })
    }

    func removeBubble(id: String) {
        bubbleViews[id]?.removeFromSuperview()
        bubbleViews.removeValue(forKey: id)
    }
}

// MARK: - MapleStory-style Pixel Bubble

class PixelBubbleView: NSView {
    private let label: NSTextField
    private var isCompletion: Bool

    // Colors
    private static let bgColor = NSColor(red: 0.08, green: 0.06, blue: 0.18, alpha: 0.92)
    private static let borderGold = NSColor(red: 0.95, green: 0.78, blue: 0.2, alpha: 1.0)
    private static let borderGoldDim = NSColor(red: 0.75, green: 0.6, blue: 0.15, alpha: 0.7)
    private static let textGold = NSColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 1.0)
    private static let completionGreen = NSColor(red: 0.4, green: 1.0, blue: 0.5, alpha: 1.0)
    private static let sparkleColor = NSColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 0.9)

    private static let pixelFont: NSFont = {
        NSFont(name: "Menlo-Bold", size: 10) ?? .monospacedSystemFont(ofSize: 10, weight: .bold)
    }()

    init(text: String, isCompletion: Bool) {
        self.isCompletion = isCompletion

        label = NSTextField(labelWithString: text)
        label.font = Self.pixelFont
        label.textColor = isCompletion ? Self.completionGreen : Self.textGold
        label.alignment = .center
        label.drawsBackground = false
        label.isBordered = false

        let textSize = (text as NSString).size(withAttributes: [.font: Self.pixelFont])
        let padH: CGFloat = 20
        let padV: CGFloat = 8
        let tailH: CGFloat = 8  // Pixel tail height
        let sparkleH: CGFloat = 6 // Top sparkle row
        let bubbleW = max(ceil(textSize.width) + padH * 2, 60)
        let bubbleH = ceil(textSize.height) + padV * 2 + tailH + sparkleH

        super.init(frame: NSRect(x: 0, y: 0, width: bubbleW, height: bubbleH))
        wantsLayer = true

        label.frame = NSRect(x: padH, y: tailH + padV - 2, width: bubbleW - padH * 2, height: textSize.height + 4)
        addSubview(label)
    }

    required init?(coder: NSCoder) { fatalError() }

    func update(text: String, isCompletion: Bool) {
        self.isCompletion = isCompletion
        label.stringValue = text
        label.textColor = isCompletion ? Self.completionGreen : Self.textGold

        let textSize = (text as NSString).size(withAttributes: [.font: Self.pixelFont])
        let padH: CGFloat = 20
        let padV: CGFloat = 8
        let tailH: CGFloat = 8
        let sparkleH: CGFloat = 6
        let bubbleW = max(ceil(textSize.width) + padH * 2, 60)
        let bubbleH = ceil(textSize.height) + padV * 2 + tailH + sparkleH

        frame.size = NSSize(width: bubbleW, height: bubbleH)
        label.frame = NSRect(x: padH, y: tailH + padV - 2, width: bubbleW - padH * 2, height: textSize.height + 4)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let w = bounds.width
        let h = bounds.height
        let tailH: CGFloat = 8
        let sparkleH: CGFloat = 6
        let borderW: CGFloat = 2
        let cornerInset: CGFloat = 4 // Pixel corner cut

        // --- Main bubble body (with pixel-cut corners) ---
        let bodyRect = NSRect(x: 0, y: tailH, width: w, height: h - tailH - sparkleH)

        let bodyPath = CGMutablePath()
        let bx = bodyRect.minX, by = bodyRect.minY
        let bw = bodyRect.width, bh = bodyRect.height
        // Bottom-left (cut corner)
        bodyPath.move(to: CGPoint(x: bx + cornerInset, y: by))
        // Bottom edge
        bodyPath.addLine(to: CGPoint(x: bx + bw - cornerInset, y: by))
        // Bottom-right cut
        bodyPath.addLine(to: CGPoint(x: bx + bw, y: by + cornerInset))
        // Right edge
        bodyPath.addLine(to: CGPoint(x: bx + bw, y: by + bh - cornerInset))
        // Top-right cut
        bodyPath.addLine(to: CGPoint(x: bx + bw - cornerInset, y: by + bh))
        // Top edge
        bodyPath.addLine(to: CGPoint(x: bx + cornerInset, y: by + bh))
        // Top-left cut
        bodyPath.addLine(to: CGPoint(x: bx, y: by + bh - cornerInset))
        // Left edge
        bodyPath.addLine(to: CGPoint(x: bx, y: by + cornerInset))
        bodyPath.closeSubpath()

        // Fill background
        ctx.setFillColor(Self.bgColor.cgColor)
        ctx.addPath(bodyPath)
        ctx.fillPath()

        // Border (double line pixel effect)
        ctx.setStrokeColor(Self.borderGold.cgColor)
        ctx.setLineWidth(borderW)
        ctx.addPath(bodyPath)
        ctx.strokePath()

        // Inner border line (1px inset)
        let innerInset: CGFloat = 3
        let innerRect = bodyRect.insetBy(dx: innerInset, dy: innerInset)
        let innerPath = CGMutablePath()
        let ix = innerRect.minX, iy = innerRect.minY
        let iw = innerRect.width, ih = innerRect.height
        let ic: CGFloat = 2
        innerPath.move(to: CGPoint(x: ix + ic, y: iy))
        innerPath.addLine(to: CGPoint(x: ix + iw - ic, y: iy))
        innerPath.addLine(to: CGPoint(x: ix + iw, y: iy + ic))
        innerPath.addLine(to: CGPoint(x: ix + iw, y: iy + ih - ic))
        innerPath.addLine(to: CGPoint(x: ix + iw - ic, y: iy + ih))
        innerPath.addLine(to: CGPoint(x: ix + ic, y: iy + ih))
        innerPath.addLine(to: CGPoint(x: ix, y: iy + ih - ic))
        innerPath.addLine(to: CGPoint(x: ix, y: iy + ic))
        innerPath.closeSubpath()

        ctx.setStrokeColor(Self.borderGoldDim.cgColor)
        ctx.setLineWidth(1)
        ctx.addPath(innerPath)
        ctx.strokePath()

        // --- Tail (pixel triangle pointing down) ---
        let tailW: CGFloat = 10
        let tailX = w / 2
        ctx.setFillColor(Self.bgColor.cgColor)
        ctx.move(to: CGPoint(x: tailX - tailW / 2, y: tailH))
        ctx.addLine(to: CGPoint(x: tailX, y: 0))
        ctx.addLine(to: CGPoint(x: tailX + tailW / 2, y: tailH))
        ctx.closePath()
        ctx.fillPath()

        // Tail border
        ctx.setStrokeColor(Self.borderGold.cgColor)
        ctx.setLineWidth(borderW)
        ctx.move(to: CGPoint(x: tailX - tailW / 2, y: tailH))
        ctx.addLine(to: CGPoint(x: tailX, y: 0))
        ctx.addLine(to: CGPoint(x: tailX + tailW / 2, y: tailH))
        ctx.strokePath()

        // --- Sparkle dots on top edge ---
        let sparkleY = h - sparkleH / 2 - 1
        let sparkleCount = max(Int(w / 14), 3)
        let sparkleSpacing = (w - 16) / CGFloat(sparkleCount - 1)

        ctx.setFillColor(Self.sparkleColor.cgColor)
        for i in 0..<sparkleCount {
            let sx = 8 + CGFloat(i) * sparkleSpacing
            let sz: CGFloat = (i % 3 == 0) ? 3 : 2 // Vary size
            ctx.fillEllipse(in: CGRect(x: sx - sz / 2, y: sparkleY - sz / 2, width: sz, height: sz))
        }

        // Corner sparkle diamonds (bigger)
        for cx in [CGFloat(6), w - 6] {
            let dSize: CGFloat = 3
            let dy = sparkleY
            ctx.move(to: CGPoint(x: cx, y: dy - dSize))
            ctx.addLine(to: CGPoint(x: cx + dSize, y: dy))
            ctx.addLine(to: CGPoint(x: cx, y: dy + dSize))
            ctx.addLine(to: CGPoint(x: cx - dSize, y: dy))
            ctx.closePath()
            ctx.fillPath()
        }
    }
}
