import SwiftUI

// MARK: - Character View

struct PixCharacterView: View {
    @ObservedObject var brain: PixBrain

    @State private var jumpOffsetY: CGFloat = 0
    @State private var squishX: CGFloat = 1.0
    @State private var squishY: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            // Speech bubble floats above
            if let text = brain.speech {
                SpeechBubble(text: text)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.7, anchor: .bottom).combined(with: .opacity),
                        removal: .scale(scale: 0.8, anchor: .bottom).combined(with: .opacity)
                    ))
                    .padding(.bottom, 6)
            }

            // Character canvas — flip horizontally when facing left
            PixCanvas(mood: brain.mood, walkPhase: brain.walkPhase)
                .frame(width: 80, height: 100)
                .scaleEffect(
                    x: brain.faceDir == .left ? -1 : 1,
                    y: 1,
                    anchor: .center
                )
                .scaleEffect(x: squishX, y: squishY, anchor: .bottom)
                .offset(y: jumpOffsetY)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: brain.speech != nil)
        .onChange(of: brain.isJumping) { _, jumping in
            guard jumping else { return }
            // Go up
            withAnimation(.easeOut(duration: 0.18)) {
                jumpOffsetY = -48
                squishX = 0.82
                squishY = 1.18
            }
            // Land
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                withAnimation(.easeIn(duration: 0.18)) { jumpOffsetY = 0 }
            }
            // Squish on landing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
                withAnimation(.spring(response: 0.18, dampingFraction: 0.35)) {
                    squishX = 1.22; squishY = 0.78
                }
            }
            // Recover
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    squishX = 1.0; squishY = 1.0
                }
            }
        }
    }
}

// MARK: - Canvas Drawing

struct PixCanvas: View {
    let mood: PixMood
    let walkPhase: Double

    var body: some View {
        // Blink state
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                drawPix(ctx: ctx, size: size)
            }
        }
    }

    private func drawPix(ctx: GraphicsContext, size: CGSize) {
        let cx = size.width / 2   // 40
        let phase = walkPhase
        let isWalking = mood == .walking

        // Colors
        let body   = bodyColor
        let dark   = Color(red: 0.52, green: 0.20, blue: 0.78)
        let belly  = Color(red: 0.94, green: 0.87, blue: 1.00)
        let pupil  = Color(red: 0.22, green: 0.04, blue: 0.50)

        // Leg swing (opposite phase)
        let swing  = isWalking ? CGFloat(sin(phase)) * 9 : 0

        // ── Legs (behind body) ──────────────────────────────────────
        ctx.fill(Path(ellipseIn: CGRect(x: cx - 22, y: 80 + swing,  width: 17, height: 20)), with: .color(dark))
        ctx.fill(Path(ellipseIn: CGRect(x: cx + 5,  y: 80 - swing,  width: 17, height: 20)), with: .color(dark))

        // ── Arms ────────────────────────────────────────────────────
        ctx.fill(Path(ellipseIn: CGRect(x: cx - 42, y: 48 + swing * 0.5, width: 15, height: 26)), with: .color(body))
        ctx.fill(Path(ellipseIn: CGRect(x: cx + 27, y: 48 - swing * 0.5, width: 15, height: 26)), with: .color(body))

        // ── Body ────────────────────────────────────────────────────
        ctx.fill(Path(ellipseIn: CGRect(x: cx - 27, y: 52, width: 54, height: 44)), with: .color(body))
        ctx.fill(Path(ellipseIn: CGRect(x: cx - 15, y: 60, width: 30, height: 28)), with: .color(belly))

        // ── Head ────────────────────────────────────────────────────
        ctx.fill(Path(ellipseIn: CGRect(x: cx - 29, y: 3, width: 58, height: 56)), with: .color(body))

        // ── Ears ────────────────────────────────────────────────────
        ctx.fill(Path(ellipseIn: CGRect(x: cx - 37, y: -12, width: 20, height: 28)), with: .color(dark))
        ctx.fill(Path(ellipseIn: CGRect(x: cx - 33, y:  -7, width: 11, height: 17)), with: .color(belly))
        ctx.fill(Path(ellipseIn: CGRect(x: cx + 17, y: -12, width: 20, height: 28)), with: .color(dark))
        ctx.fill(Path(ellipseIn: CGRect(x: cx + 22, y:  -7, width: 11, height: 17)), with: .color(belly))

        // ── Eyes ────────────────────────────────────────────────────
        let eyeY: CGFloat = 22

        if mood == .sleepy {
            // Half-closed arcs
            var eL = Path()
            eL.move(to: CGPoint(x: cx - 19, y: eyeY + 3))
            eL.addQuadCurve(to: CGPoint(x: cx - 5, y: eyeY + 3),
                            control: CGPoint(x: cx - 12, y: eyeY - 4))
            ctx.stroke(eL, with: .color(pupil), lineWidth: 2.5)

            var eR = Path()
            eR.move(to: CGPoint(x: cx + 5, y: eyeY + 3))
            eR.addQuadCurve(to: CGPoint(x: cx + 19, y: eyeY + 3),
                            control: CGPoint(x: cx + 12, y: eyeY - 4))
            ctx.stroke(eR, with: .color(pupil), lineWidth: 2.5)
        } else {
            // Eye whites
            ctx.fill(Path(ellipseIn: CGRect(x: cx - 21, y: eyeY - 9, width: 16, height: 18)), with: .color(.white))
            ctx.fill(Path(ellipseIn: CGRect(x: cx + 5,  y: eyeY - 9, width: 16, height: 18)), with: .color(.white))
            // Pupils
            ctx.fill(Path(ellipseIn: CGRect(x: cx - 18, y: eyeY - 6, width: 10, height: 12)), with: .color(pupil))
            ctx.fill(Path(ellipseIn: CGRect(x: cx + 8,  y: eyeY - 6, width: 10, height: 12)), with: .color(pupil))
            // Shine dots
            ctx.fill(Path(ellipseIn: CGRect(x: cx - 16, y: eyeY - 5, width: 4, height: 4)), with: .color(.white))
            ctx.fill(Path(ellipseIn: CGRect(x: cx + 10, y: eyeY - 5, width: 4, height: 4)), with: .color(.white))
        }

        // ── Mouth ───────────────────────────────────────────────────
        var mouthPath = Path()
        let mouthColor = Color(red: 0.42, green: 0.08, blue: 0.65)
        switch mood {
        case .happy, .walking:
            mouthPath.move(to: CGPoint(x: cx - 12, y: 41))
            mouthPath.addQuadCurve(to: CGPoint(x: cx + 12, y: 41),
                                   control: CGPoint(x: cx, y: 52))
        case .scared:
            mouthPath.move(to: CGPoint(x: cx - 9, y: 47))
            mouthPath.addQuadCurve(to: CGPoint(x: cx + 9, y: 47),
                                   control: CGPoint(x: cx, y: 40))
        case .sleepy:
            mouthPath.move(to: CGPoint(x: cx - 8, y: 44))
            mouthPath.addLine(to: CGPoint(x: cx + 8, y: 44))
        default:
            mouthPath.move(to: CGPoint(x: cx - 11, y: 41))
            mouthPath.addQuadCurve(to: CGPoint(x: cx + 11, y: 41),
                                   control: CGPoint(x: cx, y: 49))
        }
        ctx.stroke(mouthPath, with: .color(mouthColor), lineWidth: 2.5)

        // ── Blush (happy only) ──────────────────────────────────────
        if mood == .happy {
            let blushColor = Color.pink.opacity(0.45)
            ctx.fill(Path(ellipseIn: CGRect(x: cx - 33, y: 33, width: 15, height: 9)), with: .color(blushColor))
            ctx.fill(Path(ellipseIn: CGRect(x: cx + 18, y: 33, width: 15, height: 9)), with: .color(blushColor))
        }
    }

    private var bodyColor: Color {
        switch mood {
        case .happy:  return Color(red: 0.89, green: 0.58, blue: 1.00)
        case .scared: return Color(red: 0.68, green: 0.83, blue: 1.00)
        case .sleepy: return Color(red: 0.70, green: 0.48, blue: 0.86)
        default:      return Color(red: 0.76, green: 0.52, blue: 0.98)
        }
    }
}

// MARK: - Speech Bubble

struct SpeechBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
}
