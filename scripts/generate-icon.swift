#!/usr/bin/env swift
// Generates a cute Pix app icon — a glowing blob with tiny dot eyes
import AppKit

func generateIcon(size: Int, outputPath: String) {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else { return }

    // Background (dark)
    ctx.setFillColor(NSColor(red: 0.06, green: 0.05, blue: 0.12, alpha: 1.0).cgColor)
    ctx.fill(CGRect(x: 0, y: 0, width: s, height: s))

    let center = CGPoint(x: s / 2, y: s / 2)
    let blobR = s * 0.32

    // Outer glow
    let glowColors = [
        NSColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.0).cgColor,
        NSColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.15).cgColor,
        NSColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.4).cgColor,
    ]
    if let glow = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                              colors: glowColors as CFArray,
                              locations: [0.0, 0.6, 1.0]) {
        ctx.drawRadialGradient(glow, startCenter: center, startRadius: s * 0.45,
                               endCenter: center, endRadius: blobR * 0.5, options: [])
    }

    // Blob body (organic shape via overlapping circles)
    let blobColor = NSColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.85)
    ctx.setFillColor(blobColor.cgColor)

    // Main body
    ctx.fillEllipse(in: CGRect(x: center.x - blobR, y: center.y - blobR * 0.9,
                                width: blobR * 2, height: blobR * 1.8))
    // Slightly wider at bottom for blob feel
    ctx.fillEllipse(in: CGRect(x: center.x - blobR * 1.05, y: center.y - blobR * 0.95,
                                width: blobR * 2.1, height: blobR * 1.6))

    // Inner highlight
    let hlColor = NSColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 0.35)
    ctx.setFillColor(hlColor.cgColor)
    ctx.fillEllipse(in: CGRect(x: center.x - blobR * 0.5, y: center.y + blobR * 0.05,
                                width: blobR * 1.0, height: blobR * 0.8))

    // Eyes (small dots)
    let eyeColor = NSColor(red: 0.1, green: 0.08, blue: 0.15, alpha: 0.85)
    ctx.setFillColor(eyeColor.cgColor)
    let eyeR = s * 0.035
    let eyeSpacing = s * 0.08
    let eyeY = center.y + s * 0.02
    // Left eye
    ctx.fillEllipse(in: CGRect(x: center.x - eyeSpacing - eyeR, y: eyeY - eyeR,
                                width: eyeR * 2, height: eyeR * 2.2))
    // Right eye
    ctx.fillEllipse(in: CGRect(x: center.x + eyeSpacing - eyeR, y: eyeY - eyeR,
                                width: eyeR * 2, height: eyeR * 2.2))

    // Eye highlights
    ctx.setFillColor(NSColor.white.withAlphaComponent(0.7).cgColor)
    let hlR = eyeR * 0.4
    ctx.fillEllipse(in: CGRect(x: center.x - eyeSpacing + eyeR * 0.2, y: eyeY + eyeR * 0.2,
                                width: hlR, height: hlR))
    ctx.fillEllipse(in: CGRect(x: center.x + eyeSpacing + eyeR * 0.2, y: eyeY + eyeR * 0.2,
                                width: hlR, height: hlR))

    // Sparkle dots around
    ctx.setFillColor(NSColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 0.6).cgColor)
    let sparkles: [(CGFloat, CGFloat, CGFloat)] = [
        (0.25, 0.75, 2.5), (0.75, 0.8, 2.0), (0.2, 0.35, 1.8),
        (0.8, 0.3, 2.2), (0.5, 0.88, 1.5), (0.15, 0.6, 1.5),
        (0.85, 0.55, 1.8), (0.4, 0.15, 2.0), (0.65, 0.12, 1.5),
    ]
    for (sx, sy, sr) in sparkles {
        let r = sr * (s / 512.0)
        ctx.fillEllipse(in: CGRect(x: s * sx - r, y: s * sy - r, width: r * 2, height: r * 2))
    }

    image.unlockFocus()

    // Save as PNG
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else { return }
    try? png.write(to: URL(fileURLWithPath: outputPath))
}

// Generate all needed sizes
let basePath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let sizes = [16, 32, 64, 128, 256, 512, 1024]
for size in sizes {
    generateIcon(size: size, outputPath: "\(basePath)/icon_\(size).png")
    print("Generated \(size)x\(size)")
}
