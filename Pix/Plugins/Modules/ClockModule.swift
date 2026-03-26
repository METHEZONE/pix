import Foundation
import AppKit
import QuartzCore

class ClockModule: AgentModule {
    let id = "clock"
    let name = "Clock"
    let isTickable = true
    var isActive = false
    private weak var character: FireflyCharacter?
    private var lastUpdate: CFTimeInterval = 0

    func onActivate(character: FireflyCharacter) {
        self.character = character
    }

    func onDeactivate() {
        character = nil
    }

    func onTick(deltaTime: CFTimeInterval) {
        guard isActive, let char = character, char.state == .paused else { return }
        let now = CACurrentMediaTime()
        guard now - lastUpdate > 30 else { return } // Update every 30s
        lastUpdate = now

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeStr = formatter.string(from: Date())

        char.controller?.bubbleOverlay.showBubble(
            id: "clock-\(char.definition.name)",
            text: timeStr,
            at: NSPoint(x: char.window.frame.midX, y: char.window.frame.maxY + 10),
            isCompletion: false
        )
    }

    func onChatMessage(message: String) -> String? { nil }
}
