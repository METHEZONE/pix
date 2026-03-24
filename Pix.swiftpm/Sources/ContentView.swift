import SwiftUI

// MARK: - Stars background

private struct StarField: View {
    // Pre-generated so they don't shuffle on re-render
    private let stars: [(x: CGFloat, y: CGFloat, r: CGFloat, alpha: CGFloat)] = {
        (0..<80).map { _ in
            (CGFloat.random(in: 0...1),
             CGFloat.random(in: 0...0.85),
             CGFloat.random(in: 0.8...2.2),
             CGFloat.random(in: 0.15...0.75))
        }
    }()

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, _ in
                for s in stars {
                    let path = Path(ellipseIn: CGRect(
                        x: s.x * geo.size.width - s.r,
                        y: s.y * geo.size.height - s.r,
                        width: s.r * 2, height: s.r * 2))
                    ctx.fill(path, with: .color(.white.opacity(s.alpha)))
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Tap spark particle

private struct Spark: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let hue: Double
    var scale: CGFloat = 1
    var opacity: Double = 1
}

// MARK: - Content View

struct ContentView: View {
    @StateObject private var brain = PixBrain()
    @State private var sparks: [Spark] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Deep space background
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.00, blue: 0.18),
                        Color(red: 0.04, green: 0.00, blue: 0.10)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                StarField()

                // Ground glow
                VStack {
                    Spacer()
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.purple.opacity(0.35),
                                    Color.purple.opacity(0.0)
                                ],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(height: 3)
                        .blur(radius: 2)
                        .padding(.horizontal, 24)
                        .padding(.bottom, geo.safeAreaInsets.bottom + 55)
                }

                // Tap sparks
                ForEach(sparks) { spark in
                    Circle()
                        .fill(Color(hue: spark.hue, saturation: 0.9, brightness: 1))
                        .frame(width: 8, height: 8)
                        .scaleEffect(spark.scale)
                        .opacity(spark.opacity)
                        .position(x: spark.x, y: spark.y)
                        .allowsHitTesting(false)
                }

                // Character — positioned at brain.position (feet on ground)
                PixCharacterView(brain: brain)
                    .position(x: brain.position.x,
                              y: brain.position.y - 50)  // offset up so feet align to ground
                    .animation(
                        brain.mood == .walking
                            ? .linear(duration: 0.033)
                            : .spring(response: 0.4, dampingFraction: 0.7),
                        value: brain.position
                    )

                // Hint label (fades after first tap)
                VStack {
                    Spacer()
                    Text("Tap Pix or anywhere to interact")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                        .padding(.bottom, geo.safeAreaInsets.bottom + 10)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                brain.reactToTap(at: location)
                spawnSparks(at: location)
            }
            .onAppear {
                brain.configure(
                    screenSize: geo.size,
                    safeBottom: geo.safeAreaInsets.bottom
                )
            }
        }
    }

    // MARK: - Sparks

    private func spawnSparks(at point: CGPoint) {
        let hues: [Double] = [0.78, 0.85, 0.55, 0.15, 0.05, 0.62]
        let new = hues.map { h in
            Spark(
                x: point.x + CGFloat.random(in: -12...12),
                y: point.y + CGFloat.random(in: -12...12),
                hue: h
            )
        }
        sparks.append(contentsOf: new)

        // Animate outward + fade
        withAnimation(.easeOut(duration: 0.7)) {
            for i in (sparks.count - new.count)..<sparks.count {
                sparks[i].x += CGFloat.random(in: -55...55)
                sparks[i].y += CGFloat.random(in: -75...15)
                sparks[i].scale = 0.1
                sparks[i].opacity = 0
            }
        }

        // Clean up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            sparks.removeFirst(min(new.count, sparks.count))
        }
    }
}
