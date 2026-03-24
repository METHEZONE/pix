import SwiftUI
import Combine

// MARK: - Types

enum PixMood: Equatable {
    case idle, walking, happy, scared, sleepy
}

enum FaceDir {
    case left, right
}

// MARK: - PixBrain

class PixBrain: ObservableObject {
    // Character state (all @Published so views re-render)
    @Published var position: CGPoint = .zero
    @Published var mood: PixMood = .idle
    @Published var faceDir: FaceDir = .right
    @Published var walkPhase: Double = 0
    @Published var speech: String? = nil
    @Published var isJumping: Bool = false

    private var screenSize: CGSize = .zero
    private var safeBottom: CGFloat = 0
    private var walkTarget: CGFloat? = nil
    private var cancellables = Set<AnyCancellable>()
    private var configured = false

    // MARK: Phrases

    private let tapDirectPhrases = [
        "Hey! ✨", "Hehehe 💜", "*squeak*", "That tickles! 😄",
        "Ouch! 😤", "Again! Again! 🌀", "Pix is here! 🌟",
        "boop!", "Hiii 👋", "You found me!"
    ]

    private let idlePhrases = [
        "...zZz 💤", "Hmm... 🌙", "*yawns* ☁️", "I'm bored 😑",
        "This iPad is MINE 📱", "Hellooo? 👀", "Watch me! ✨",
        "I live here now 👾", "*stares at you*", "Boo! 👻",
        "What are you doing? 🤔", "Feed me! 🍕", "*does a little spin*"
    ]

    // MARK: - Setup

    func configure(screenSize: CGSize, safeBottom: CGFloat) {
        guard !configured else { return }
        configured = true
        self.screenSize = screenSize
        self.safeBottom = safeBottom
        position = CGPoint(x: screenSize.width / 2, y: groundY)
        startUpdateLoop()
        scheduleBehavior()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.speak("Hey! I'm Pix! 💜", for: 3.0)
        }
    }

    private var groundY: CGFloat {
        screenSize.height - safeBottom - 60
    }

    // MARK: - Interaction

    func reactToTap(at point: CGPoint) {
        let dist = hypot(point.x - position.x, point.y - position.y)
        if dist < 65 {
            // Tapped directly on Pix
            doJump()
            speak(pick(tapDirectPhrases), for: 2.0)
            setMood(.happy, for: 1.5)
        } else {
            // Tapped elsewhere — walk there
            walkTo(x: point.x)
        }
    }

    // MARK: - Actions

    private func walkTo(x: CGFloat) {
        let clamped = max(55, min(screenSize.width - 55, x))
        walkTarget = clamped
        faceDir = clamped > position.x ? .right : .left
        mood = .walking
    }

    func doJump() {
        isJumping = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
            self?.isJumping = false
        }
    }

    func speak(_ text: String, for duration: Double = 2.5) {
        let snapshot = text
        speech = snapshot
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            if self?.speech == snapshot { self?.speech = nil }
        }
    }

    private func setMood(_ m: PixMood, for duration: TimeInterval) {
        mood = m
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            if self?.mood == m { self?.mood = .idle }
        }
    }

    private func pick(_ arr: [String]) -> String {
        arr[Int.random(in: 0..<arr.count)]
    }

    // MARK: - Update Loop

    private func startUpdateLoop() {
        Timer.publish(every: 1.0 / 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
            .store(in: &cancellables)
    }

    private func tick() {
        guard screenSize != .zero else { return }

        if let target = walkTarget {
            let speed: CGFloat = 2.2
            let dx = target - position.x
            if abs(dx) <= speed {
                position.x = target
                walkTarget = nil
                mood = .idle
            } else {
                position.x += dx > 0 ? speed : -speed
                walkPhase += 0.18
            }
        }

        // Keep grounded and in bounds
        position.y = groundY
        position.x = max(55, min(screenSize.width - 55, position.x))
    }

    // MARK: - Autonomous Behaviour

    private func scheduleBehavior() {
        let delay = Double.random(in: 5.0...12.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.doBehavior()
            self?.scheduleBehavior()
        }
    }

    private func doBehavior() {
        guard screenSize != .zero else { return }
        switch Int.random(in: 0...6) {
        case 0, 1:
            // Random walk
            let x = CGFloat.random(in: 70...(screenSize.width - 70))
            walkTo(x: x)
        case 2:
            // Speak idle phrase
            speak(pick(idlePhrases))
        case 3:
            // Happy bounce
            setMood(.happy, for: 2.0)
            doJump()
            speak(pick(["Yay! 🎉", "Wheee! 🌈", "Boing! 💜"]), for: 1.5)
        case 4:
            // Sleepy
            setMood(.sleepy, for: 4.5)
            speak("...zZz 💤", for: 4.0)
        case 5:
            // Startled
            setMood(.scared, for: 1.2)
            speak(pick(["!!!", "What was that?! 😱", "👀"]), for: 2.0)
        default:
            // Walk to edge and look back
            let goLeft = position.x > screenSize.width / 2
            walkTo(x: goLeft ? 70 : screenSize.width - 70)
        }
    }
}
