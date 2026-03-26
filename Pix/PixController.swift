import AppKit
import QuartzCore

class PixController {
    var characters: [FireflyCharacter] = []
    var bubbleOverlay: BubbleOverlayWindow!
    var moduleRegistry = AgentModuleRegistry()
    private var displayLink: CVDisplayLink?
    private var lastTickTime: CFTimeInterval = 0
    private var idleFrameCount = 0

    private static let onboardingKey = "hasCompletedOnboarding"

    func start() {
        bubbleOverlay = BubbleOverlayWindow()

        let registry = CharacterRegistry.shared
        for def in registry.allCharacters {
            let char = FireflyCharacter(definition: def)
            char.controller = self
            char.isUnlocked = registry.isUnlocked(def.name)
            char.setup()
            if def.name == "Lumen" {
                char.isActive = true
                char.window.orderFrontRegardless()
            }
            characters.append(char)
        }

        moduleRegistry.register(ClockModule())
        moduleRegistry.register(ReminderModule())

        startDisplayLink()

        if !UserDefaults.standard.bool(forKey: Self.onboardingKey) {
            triggerOnboarding()
        }
    }

    private func triggerOnboarding() {
        guard let first = characters.first(where: { $0.isActive }) else { return }
        first.isOnboarding = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.bubbleOverlay.showBubble(
                id: "onboarding",
                text: "hi! click me ✨",
                at: NSPoint(x: first.window.frame.midX, y: first.window.frame.maxY + 10),
                isCompletion: true
            )
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: Self.onboardingKey)
        characters.forEach { $0.isOnboarding = false }
        bubbleOverlay.hideBubble(id: "onboarding")
    }

    func shutdown() {
        characters.forEach { $0.claudeSession?.terminate() }
        if let dl = displayLink {
            CVDisplayLinkStop(dl)
        }
        CharacterRegistry.shared.flushStats()
    }

    // MARK: - Session Pool

    private let maxConcurrentSessions = 2

    var activeSessionCount: Int {
        characters.filter { $0.claudeSession?.isRunning ?? false }.count
    }

    func canOpenSession() -> Bool {
        activeSessionCount < maxConcurrentSessions
    }

    // MARK: - Display Link

    private func startDisplayLink() {
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        guard let displayLink = displayLink else { return }

        let callback: CVDisplayLinkOutputCallback = { _, _, _, _, _, userInfo -> CVReturn in
            let ctrl = Unmanaged<PixController>.fromOpaque(userInfo!).takeUnretainedValue()
            DispatchQueue.main.async { ctrl.tick() }
            return kCVReturnSuccess
        }

        CVDisplayLinkSetOutputCallback(displayLink, callback, Unmanaged.passUnretained(self).toOpaque())
        CVDisplayLinkStart(displayLink)
    }

    func tick() {
        let now = CACurrentMediaTime()
        let dt = lastTickTime == 0 ? 1.0 / 60.0 : now - lastTickTime
        lastTickTime = now

        guard let screen = NSScreen.main else { return }
        let bounds = screen.frame

        let activeChars = characters.filter { $0.isActive && $0.isUnlocked }

        // Energy saving: if all paused and no chat active, reduce work
        let anyBusy = activeChars.contains { $0.state != .paused || ($0.claudeSession?.isBusy ?? false) }
        if !anyBusy {
            idleFrameCount += 1
            if idleFrameCount > 300 && idleFrameCount % 6 != 0 { return } // ~10fps when idle
        } else {
            idleFrameCount = 0
        }

        let siblings = activeChars.map { $0.position }

        for (i, char) in activeChars.enumerated() {
            var otherPositions = siblings
            otherPositions.remove(at: i)
            char.update(dt: dt, screenBounds: bounds, siblings: otherPositions)

            // Update bubble position
            if char.claudeSession?.isBusy ?? false && !char.isIdleForPopover {
                bubbleOverlay.showBubble(
                    id: char.definition.name,
                    text: char.currentPhrase,
                    at: NSPoint(x: char.window.frame.midX, y: char.window.frame.maxY + 10),
                    isCompletion: false
                )
            } else if char.showingCompletion && !char.isIdleForPopover {
                bubbleOverlay.showBubble(
                    id: char.definition.name,
                    text: char.currentPhrase,
                    at: NSPoint(x: char.window.frame.midX, y: char.window.frame.maxY + 10),
                    isCompletion: true
                )
            } else if !char.isIdleForPopover {
                bubbleOverlay.hideBubble(id: char.definition.name)
            }
        }

        // Z-ordering
        let sorted = activeChars.sorted { $0.position.x < $1.position.x }
        for (i, char) in sorted.enumerated() {
            char.window.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + i)
        }

        // Tick active modules
        for mod in moduleRegistry.activeModules {
            if mod.isTickable {
                mod.onTick(deltaTime: dt)
            }
        }

        // Check unlocks periodically (every ~5s)
        if Int(now) % 5 == 0 && now - lastTickTime < 0.02 {
            checkUnlocks()
        }
    }

    private func checkUnlocks() {
        let registry = CharacterRegistry.shared
        for char in characters where !char.isUnlocked {
            if registry.checkAndUnlock(char.definition) {
                char.isUnlocked = true
                bubbleOverlay.showBubble(
                    id: "unlock-\(char.definition.name)",
                    text: "new friend unlocked! ✨",
                    at: NSPoint(x: NSScreen.main!.frame.midX, y: NSScreen.main!.frame.midY),
                    isCompletion: true
                )
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
                    self?.bubbleOverlay.hideBubble(id: "unlock-\(char.definition.name)")
                }
                SoundManager.shared.playCompletion()
                // Rebuild menu to show new character
                if let appDelegate = NSApp.delegate as? AppDelegate {
                    appDelegate.rebuildMenu()
                }
            }
        }
    }

    deinit {
        if let dl = displayLink { CVDisplayLinkStop(dl) }
    }
}
