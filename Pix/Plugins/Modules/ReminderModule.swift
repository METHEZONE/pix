import Foundation
import AppKit
import QuartzCore

class ReminderModule: AgentModule {
    let id = "reminder"
    let name = "Break Reminder"
    let isTickable = true
    var isActive = false
    private weak var character: FireflyCharacter?
    private var lastInteraction: CFTimeInterval = CACurrentMediaTime()
    private let idleThreshold: CFTimeInterval = 30 * 60 // 30 minutes
    private var reminderShown = false

    func onActivate(character: FireflyCharacter) {
        self.character = character
        lastInteraction = CACurrentMediaTime()
        reminderShown = false
    }

    func onDeactivate() {
        character = nil
        reminderShown = false
    }

    func onTick(deltaTime: CFTimeInterval) {
        guard isActive, let char = character else { return }
        let now = CACurrentMediaTime()

        // Reset on any chat activity
        if char.claudeSession?.isBusy ?? false {
            lastInteraction = now
            reminderShown = false
            return
        }

        if !reminderShown && now - lastInteraction > idleThreshold {
            reminderShown = true
            char.controller?.bubbleOverlay.showBubble(
                id: "reminder-\(char.definition.name)",
                text: "take a break! ☕",
                at: NSPoint(
                    x: NSScreen.main?.frame.midX ?? 500,
                    y: NSScreen.main?.frame.midY ?? 400
                ),
                isCompletion: true
            )
            SoundManager.shared.playCompletion()

            // Auto-dismiss after 10s
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
                self?.character?.controller?.bubbleOverlay.hideBubble(id: "reminder-\(char.definition.name)")
            }
        }
    }

    func onChatMessage(message: String) -> String? {
        lastInteraction = CACurrentMediaTime()
        reminderShown = false
        return nil
    }
}
