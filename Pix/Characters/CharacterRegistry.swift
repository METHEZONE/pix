import Foundation
import AppKit

class CharacterRegistry {
    static let shared = CharacterRegistry()

    private let chatCountKey = "pix.stats.chatCount"
    private let startTimeKey = "pix.stats.startTime"
    private let unlockedKey = "pix.unlocked"
    private let easterEggsKey = "pix.easterEggs"

    // In-memory stat accumulation (flushed periodically)
    private var pendingChatCount = 0
    private var lastFlush: Date = Date()

    let allCharacters: [CharacterDefinition] = [
        CharacterDefinition(
            name: "Lumen", displayName: "Lumen",
            glowStyle: GlowStyle(
                color: NSColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0),
                intensity: 1.0, trailLength: 1.5,
                trailColor: NSColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 0.6),
                pulseRate: 3.0, particleSize: 12.0
            ),
            flightPersonality: FlightPersonality(
                speedRange: 35...70, turnRate: 1.0, pauseFrequency: 0.08,
                pauseDuration: 3.0...8.0, wanderScale: 0.3, swimPulseInterval: 1.8
            ),
            unlockCondition: .defaultUnlocked
        ),
        CharacterDefinition(
            name: "Nox", displayName: "Nox",
            glowStyle: GlowStyle(
                color: NSColor(red: 0.3, green: 0.4, blue: 0.95, alpha: 1.0),
                intensity: 0.8, trailLength: 2.0,
                trailColor: NSColor(red: 0.4, green: 0.5, blue: 1.0, alpha: 0.5),
                pulseRate: 4.0, particleSize: 14.0
            ),
            flightPersonality: FlightPersonality(
                speedRange: 20...50, turnRate: 0.7, pauseFrequency: 0.12,
                pauseDuration: 5.0...12.0, wanderScale: 0.2, swimPulseInterval: 2.5
            ),
            unlockCondition: .chatCount(10)
        ),
        CharacterDefinition(
            name: "Ember", displayName: "Ember",
            glowStyle: GlowStyle(
                color: NSColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 1.0),
                intensity: 1.3, trailLength: 1.0,
                trailColor: NSColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 0.7),
                pulseRate: 2.0, particleSize: 10.0
            ),
            flightPersonality: FlightPersonality(
                speedRange: 50...100, turnRate: 1.5, pauseFrequency: 0.05,
                pauseDuration: 2.0...5.0, wanderScale: 0.4, swimPulseInterval: 1.2
            ),
            unlockCondition: .timeUsed(hours: 1.0)
        ),
        CharacterDefinition(
            name: "Spectra", displayName: "Spectra",
            glowStyle: GlowStyle(
                color: NSColor(red: 0.8, green: 0.3, blue: 0.9, alpha: 1.0),
                intensity: 1.1, trailLength: 2.5,
                trailColor: NSColor(red: 0.6, green: 0.4, blue: 1.0, alpha: 0.5),
                pulseRate: 2.5, particleSize: 13.0
            ),
            flightPersonality: FlightPersonality(
                speedRange: 30...75, turnRate: 1.2, pauseFrequency: 0.07,
                pauseDuration: 3.0...7.0, wanderScale: 0.35, swimPulseInterval: 1.6
            ),
            unlockCondition: .chatCount(50)
        ),
        CharacterDefinition(
            name: "Ghost", displayName: "Ghost",
            glowStyle: GlowStyle(
                color: NSColor(white: 0.95, alpha: 1.0),
                intensity: 0.6, trailLength: 3.5,
                trailColor: NSColor(white: 0.9, alpha: 0.3),
                pulseRate: 5.0, particleSize: 16.0
            ),
            flightPersonality: FlightPersonality(
                speedRange: 15...35, turnRate: 0.5, pauseFrequency: 0.15,
                pauseDuration: 8.0...20.0, wanderScale: 0.15, swimPulseInterval: 3.0
            ),
            unlockCondition: .easterEgg("boo")
        )
    ]

    var chatCount: Int {
        UserDefaults.standard.integer(forKey: chatCountKey) + pendingChatCount
    }

    var hoursUsed: Double {
        guard let start = UserDefaults.standard.object(forKey: startTimeKey) as? Date else {
            UserDefaults.standard.set(Date(), forKey: startTimeKey)
            return 0
        }
        return Date().timeIntervalSince(start) / 3600.0
    }

    var easterEggs: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: easterEggsKey) ?? [])
    }

    func isUnlocked(_ name: String) -> Bool {
        let unlocked = UserDefaults.standard.stringArray(forKey: unlockedKey) ?? ["Lumen"]
        return unlocked.contains(name)
    }

    func incrementChatCount() {
        pendingChatCount += 1
        // Batch flush every 60 seconds
        if Date().timeIntervalSince(lastFlush) > 60 { flushStats() }
    }

    func addEasterEgg(_ keyword: String) {
        var eggs = UserDefaults.standard.stringArray(forKey: easterEggsKey) ?? []
        if !eggs.contains(keyword) {
            eggs.append(keyword)
            UserDefaults.standard.set(eggs, forKey: easterEggsKey)
        }
    }

    func checkAndUnlock(_ def: CharacterDefinition) -> Bool {
        guard !isUnlocked(def.name) else { return false }
        if def.unlockCondition.isMet(chatCount: chatCount, hoursUsed: hoursUsed, easterEggs: easterEggs) {
            var unlocked = UserDefaults.standard.stringArray(forKey: unlockedKey) ?? ["Lumen"]
            unlocked.append(def.name)
            UserDefaults.standard.set(unlocked, forKey: unlockedKey)
            return true
        }
        return false
    }

    func flushStats() {
        if pendingChatCount > 0 {
            let current = UserDefaults.standard.integer(forKey: chatCountKey)
            UserDefaults.standard.set(current + pendingChatCount, forKey: chatCountKey)
            pendingChatCount = 0
        }
        lastFlush = Date()
    }
}
