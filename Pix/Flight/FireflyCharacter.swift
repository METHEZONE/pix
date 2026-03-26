import AppKit
import QuartzCore

enum FireflyState {
    case flying
    case paused
    case popover
    case flung       // physics-driven after fling
    case dragging
}

class FireflyCharacter {
    let definition: CharacterDefinition
    var window: FireflyWindow!
    var contentView: FireflyContentView!
    var renderer: FireflyRenderer!
    var flightBehavior: FlightBehavior!

    var state: FireflyState = .paused
    var position: CGPoint = .zero
    var isActive = false
    var isUnlocked = false
    var isOnboarding = false

    // Pause state
    private var pauseEndTime: CFTimeInterval = 0
    private var bobPhase: CGFloat = 0

    // Physics state (for fling)
    var velocity: CGPoint = .zero
    private let friction: CGFloat = 0.97      // per-frame velocity decay
    private let bounceDamp: CGFloat = 0.6     // energy kept on wall bounce
    private let minFlingSpeed: CGFloat = 15   // stop fling below this

    // Idle action state
    private var lastIdleAction: CFTimeInterval = 0
    private var idleActionInterval: Double = 4.0
    private var isSleeping = false

    // Chat / speech
    private var lastSpeech: CFTimeInterval = 0
    private var speechInterval: Double = 3.0  // First speech comes fast
    private var hasGreeted = false

    private static let greetings = [
        "hey! 👋", "whatcha doin?", "hi hi~", "sup!", "hellooo",
        "notice me~", "im here!", "yo! ✨"
    ]
    private static let observations = [
        "nice weather huh", "u look busy", "i like ur screen",
        "this is cozy", "are we having fun?", "ooh whats that",
        "hmm interesting", "im watching u work 👀"
    ]
    private static let encouragements = [
        "u got this! 💪", "keep going!", "doing great~",
        "i believe in u", "almost there!", "don't give up!",
        "ur amazing", "ship it! 🚀"
    ]
    private static let randomThoughts = [
        "i wonder what clouds taste like", "do pixels dream?",
        "bloop bloop", "✨ sparkle ✨", "la la laaa~",
        "*bounces*", "zoom zoom", "*vibing*",
        "i love floating around", "this is nice",
        "what if i was bigger", "*glows harder*",
        "hehe", "boop!", "weeee~", "nyoom",
        "did u know im made of light?", "*happy noises*"
    ]
    private static let timeMessages: [(hour: Int, msgs: [String])] = [
        (9, ["good morning! ☀️", "rise and shine~", "new day new code!"]),
        (12, ["lunch time? 🍙", "take a break maybe?", "its noon already!"]),
        (15, ["afternoon slump?", "coffee? ☕", "hang in there~"]),
        (18, ["its getting late!", "dinner time? 🍕", "almost evening~"]),
        (22, ["still up? 🌙", "dont stay up too late!", "sleepy yet?"]),
        (0, ["its so late! 😴", "go to sleep!", "night owl huh"])
    ]

    // Popover state
    var isIdleForPopover = false
    var popoverWindow: NSWindow?
    var terminalView: TerminalView?
    var claudeSession: ClaudeSession?
    var clickOutsideMonitor: Any?
    var escapeKeyMonitor: Any?

    // Bubble state
    var currentPhrase = ""
    var showingCompletion = false
    var completionBubbleExpiry: CFTimeInterval = 0
    private var lastPhraseUpdate: CFTimeInterval = 0

    weak var controller: PixController?

    private static let thinkingPhrases = [
        "hmm...", "thinking...", "one sec...", "ok hold on",
        "let me check", "working on it", "almost...", "bear with me",
        "on it!", "gimme a sec", "glowing...", "processing...",
        "hang tight", "just a moment", "figuring it out",
        "crunching...", "reading...", "looking..."
    ]

    private static let completionPhrases = [
        "done!", "all set!", "ready!", "here you go", "got it!",
        "finished!", "ta-da!", "voila!", "✨"
    ]

    init(definition: CharacterDefinition) {
        self.definition = definition
    }

    func setup() {
        window = FireflyWindow.create(size: 120)

        contentView = FireflyContentView(frame: NSRect(x: 0, y: 0, width: 120, height: 120))
        contentView.character = self
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.clear.cgColor

        renderer = CAEmitterFireflyRenderer()
        renderer.configure(style: definition.glowStyle)
        renderer.attach(to: contentView.layer!)

        window.contentView = contentView

        flightBehavior = FlightBehavior(
            personality: definition.flightPersonality,
            seed: definition.name.hashValue
        )

        // Wire swim pulse — no-op for now, jellyfish flight handles speed bursts

        // Random start position
        if let screen = NSScreen.main {
            let bounds = screen.frame
            position = CGPoint(
                x: CGFloat.random(in: bounds.minX + 200...bounds.maxX - 200),
                y: CGFloat.random(in: bounds.minY + 200...bounds.maxY - 200)
            )
            flightBehavior.position = position
        }

        pauseEndTime = CACurrentMediaTime() + Double.random(in: 1.0...4.0)
    }

    // MARK: - Update

    func update(dt: CFTimeInterval, screenBounds: CGRect, siblings: [CGPoint]) {
        if isIdleForPopover {
            updatePopoverPosition()
            updateThinkingPhrase()
            return
        }

        let now = CACurrentMediaTime()

        switch state {
        case .dragging:
            break // Handled by FireflyContentView

        case .flung:
            // Physics: apply velocity, friction, bounce off walls
            position.x += velocity.x * CGFloat(dt)
            position.y += velocity.y * CGFloat(dt)
            velocity.x *= friction
            velocity.y *= friction

            // Slight gravity
            velocity.y -= 80 * CGFloat(dt)

            // Wall bounces
            var bounced = false
            if position.x < screenBounds.minX + 20 {
                position.x = screenBounds.minX + 20
                velocity.x = abs(velocity.x) * bounceDamp
                bounced = true
            }
            if position.x > screenBounds.maxX - 20 {
                position.x = screenBounds.maxX - 20
                velocity.x = -abs(velocity.x) * bounceDamp
                bounced = true
            }
            if position.y < screenBounds.minY + 20 {
                position.y = screenBounds.minY + 20
                velocity.y = abs(velocity.y) * bounceDamp
                bounced = true
            }
            if position.y > screenBounds.maxY - 20 {
                position.y = screenBounds.maxY - 20
                velocity.y = -abs(velocity.y) * bounceDamp
                bounced = true
            }

            if bounced {
                if let r = renderer as? CAEmitterFireflyRenderer { r.reactToWallBounce() }
                SoundManager.shared.playCompletion()
            }

            // Squishy deformation based on velocity
            if let r = renderer as? CAEmitterFireflyRenderer {
                r.applySquish(vx: velocity.x, vy: velocity.y)
            }

            let winPos = NSPoint(x: position.x - 60, y: position.y - 60)
            window.setFrameOrigin(winPos)
            renderer.updatePosition(x: 60, y: 60)
            flightBehavior.position = position

            // Stop fling when slow enough
            let speed = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
            if speed < minFlingSpeed {
                velocity = .zero
                if let r = renderer as? CAEmitterFireflyRenderer {
                    r.applySquish(vx: 0, vy: 0) // reset squish
                    r.setMouth(.happy)
                }
                enterPause()

                // Fun reaction after fling
                let reactions = ["that was wild!", "wooo!", "again?!", "im dizzy", "hehe wheee"]
                controller?.bubbleOverlay.showBubble(
                    id: definition.name, text: reactions.randomElement()!,
                    at: NSPoint(x: position.x, y: position.y + 70), isCompletion: true
                )
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                    self?.controller?.bubbleOverlay.hideBubble(id: self?.definition.name ?? "")
                }
            }

        case .paused:
            if now >= pauseEndTime {
                if isSleeping {
                    isSleeping = false
                    if let r = renderer as? CAEmitterFireflyRenderer { r.doWakeUp() }
                }
                state = .flying
            } else {
                bobPhase += CGFloat(dt) * 2.0
                let bobY = sin(bobPhase) * 3.0
                let winPos = NSPoint(x: position.x - 60, y: position.y - 60 + bobY)
                window.setFrameOrigin(winPos)
                renderer.updatePosition(x: 60, y: 60)
            }

            // Idle actions
            if now - lastIdleAction > idleActionInterval {
                lastIdleAction = now
                idleActionInterval = Double.random(in: 6.0...15.0)
                performRandomIdleAction()
            }

        case .flying:
            position = flightBehavior.update(dt: CGFloat(dt), screenBounds: screenBounds, siblings: siblings)
            let winPos = NSPoint(x: position.x - 60, y: position.y - 60)
            window.setFrameOrigin(winPos)
            renderer.updatePosition(x: 60, y: 60)

            // Squishy stretch in direction of movement
            if let r = renderer as? CAEmitterFireflyRenderer {
                r.applySquish(vx: flightBehavior.speed * cos(flightBehavior.heading),
                             vy: flightBehavior.speed * sin(flightBehavior.heading))
            }

            if Double.random(in: 0...1) < Double(definition.flightPersonality.pauseFrequency) * dt {
                if let r = renderer as? CAEmitterFireflyRenderer {
                    r.applySquish(vx: 0, vy: 0)
                }
                enterPause()
            }

        case .popover:
            break
        }

        updateThinkingPhrase()

        if showingCompletion && now >= completionBubbleExpiry {
            showingCompletion = false
        }

        // Ambient speech (only when not in popover and not busy)
        if !isIdleForPopover && !(claudeSession?.isBusy ?? false) && !showingCompletion && state != .flung && state != .dragging {
            if !hasGreeted {
                hasGreeted = true
                lastSpeech = now
                showSpeechBubble("hey! im pix ✨")
            } else if now - lastSpeech > speechInterval {
                lastSpeech = now
                speechInterval = Double.random(in: 6.0...14.0)
                sayAmbient()
            }
        }
    }

    // MARK: - Ambient Speech

    private func sayAmbient() {
        let hour = Calendar.current.component(.hour, from: Date())

        // Time-based messages (30% chance)
        if Double.random(in: 0...1) < 0.3 {
            for (h, msgs) in Self.timeMessages {
                if abs(hour - h) <= 1, let msg = msgs.randomElement() {
                    showSpeechBubble(msg)
                    return
                }
            }
        }

        // Pick random category
        let roll = Double.random(in: 0...1)
        let msg: String
        if roll < 0.15 {
            msg = Self.greetings.randomElement()!
        } else if roll < 0.3 {
            msg = Self.observations.randomElement()!
        } else if roll < 0.45 {
            msg = Self.encouragements.randomElement()!
        } else {
            msg = Self.randomThoughts.randomElement()!
        }
        showSpeechBubble(msg)
    }

    private func showSpeechBubble(_ text: String) {
        controller?.bubbleOverlay.showBubble(
            id: definition.name,
            text: text,
            at: NSPoint(x: position.x, y: position.y + 70),
            isCompletion: Bool.random() // random styling variety
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2.5...4.0)) { [weak self] in
            self?.controller?.bubbleOverlay.hideBubble(id: self?.definition.name ?? "")
        }
    }

    // MARK: - Fling

    func fling(velocity: CGPoint) {
        state = .flung
        self.velocity = velocity
        if let r = renderer as? CAEmitterFireflyRenderer {
            r.reactToFling()
            r.isBeingDragged = false
        }
    }

    // MARK: - Idle Actions

    private func performRandomIdleAction() {
        guard let r = renderer as? CAEmitterFireflyRenderer else { return }
        let action = Int.random(in: 0...5)

        switch action {
        case 0:
            // Look around
            let dir: CGFloat = Bool.random() ? 1.0 : -1.0
            r.doLookAt(direction: dir)
            // doLookAt handles its own reset

        case 1:
            // Sleepy
            isSleeping = true
            r.doSleepyEyes()
            pauseEndTime = CACurrentMediaTime() + Double.random(in: 5.0...10.0)
            controller?.bubbleOverlay.showBubble(
                id: definition.name, text: "zzz...",
                at: NSPoint(x: position.x, y: position.y + 70), isCompletion: false
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
                self?.controller?.bubbleOverlay.hideBubble(id: self?.definition.name ?? "")
            }

        case 2:
            // Random happy bounce
            r.reactToClick()
            let moods = ["~♪", "✨", "yay!", ":D", "lalala"]
            controller?.bubbleOverlay.showBubble(
                id: definition.name, text: moods.randomElement()!,
                at: NSPoint(x: position.x, y: position.y + 70), isCompletion: true
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.controller?.bubbleOverlay.hideBubble(id: self?.definition.name ?? "")
            }

        case 3:
            // Curious - look at cursor
            let mousePos = NSEvent.mouseLocation
            let dir: CGFloat = mousePos.x > position.x ? 1.0 : -1.0
            r.doLookAt(direction: dir)
            // doLookAt handles its own reset

        case 4:
            // Excited wiggle
            r.setMouth(.excited)
            let wiggle = CABasicAnimation(keyPath: "transform.rotation.z")
            wiggle.fromValue = -0.1; wiggle.toValue = 0.1
            wiggle.duration = 0.12; wiggle.autoreverses = true; wiggle.repeatCount = 4
            r.bodyLayer?.add(wiggle, forKey: "wiggle")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { r.setMouth(.happy) }

        default:
            // Just chill
            break
        }
    }

    private func enterPause() {
        state = .paused
        bobPhase = 0
        let dur = definition.flightPersonality.pauseDuration
        pauseEndTime = CACurrentMediaTime() + Double.random(in: dur)
    }

    // MARK: - Click Handling

    // MARK: - Drag Interaction

    func startDrag() {
        state = .dragging
        if let r = renderer as? CAEmitterFireflyRenderer {
            r.isBeingDragged = true
            r.reactToGrab()
        }
        // Hide bubble while dragging
        controller?.bubbleOverlay.hideBubble(id: definition.name)
    }

    func endDrag() {
        if let r = renderer as? CAEmitterFireflyRenderer {
            r.isBeingDragged = false
            r.reactToRelease()
        }
        // Resume flying after a moment
        enterPause()
        pauseEndTime = CACurrentMediaTime() + Double.random(in: 1.0...3.0)

        // Fun: show a reaction bubble
        let reactions = ["wheee!", "woah!", "again! again!", "dizzy~", "that was fun!", "hehe"]
        let reaction = reactions.randomElement()!
        controller?.bubbleOverlay.showBubble(
            id: definition.name,
            text: reaction,
            at: NSPoint(x: position.x, y: position.y + 70),
            isCompletion: true
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self = self else { return }
            self.controller?.bubbleOverlay.hideBubble(id: self.definition.name)
        }
    }

    func handleClick() {
        // Click reaction animation
        if let r = renderer as? CAEmitterFireflyRenderer {
            r.reactToClick()
        }
        if isOnboarding {
            controller?.completeOnboarding()
            openPopover()
            return
        }
        if isIdleForPopover {
            closePopover()
        } else {
            openPopover()
        }
    }

    func openPopover() {
        // Close sibling popovers
        controller?.characters.forEach { sibling in
            if sibling !== self && sibling.isIdleForPopover {
                sibling.closePopover()
            }
        }

        isIdleForPopover = true
        state = .popover
        renderer.dim()

        // Lazy session creation
        if claudeSession == nil {
            guard controller?.canOpenSession() ?? false else {
                controller?.bubbleOverlay.showBubble(
                    id: "session-limit",
                    text: "another firefly is chatting",
                    at: NSPoint(x: window.frame.midX, y: window.frame.maxY + 10),
                    isCompletion: false
                )
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.controller?.bubbleOverlay.hideBubble(id: "session-limit")
                }
                isIdleForPopover = false
                state = .paused
                enterPause()
                renderer.brighten()
                return
            }
            let session = ClaudeSession()
            claudeSession = session
            wireSession(session)
            session.start()
        }

        if popoverWindow == nil {
            createPopoverWindow()
        }

        if let terminal = terminalView, let session = claudeSession, !session.history.isEmpty {
            terminal.replayHistory(session.history)
        }

        updatePopoverPosition()
        popoverWindow?.orderFrontRegardless()
        popoverWindow?.makeKey()
        if let terminal = terminalView {
            popoverWindow?.makeFirstResponder(terminal.inputField)
        }

        // Track chat count for unlocks
        CharacterRegistry.shared.incrementChatCount()

        removeEventMonitors()
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, let pop = self.popoverWindow else { return }
            let charFrame = self.window.frame
            if !pop.frame.contains(NSEvent.mouseLocation) && !charFrame.contains(NSEvent.mouseLocation) {
                self.closePopover()
            }
        }
        escapeKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { self?.closePopover(); return nil }
            return event
        }
    }

    func closePopover() {
        guard isIdleForPopover else { return }
        popoverWindow?.orderOut(nil)
        removeEventMonitors()
        isIdleForPopover = false
        renderer.brighten()
        enterPause()
    }

    private func removeEventMonitors() {
        if let m = clickOutsideMonitor { NSEvent.removeMonitor(m); clickOutsideMonitor = nil }
        if let m = escapeKeyMonitor { NSEvent.removeMonitor(m); escapeKeyMonitor = nil }
    }

    // MARK: - Popover Window

    func createPopoverWindow() {
        let charColor = definition.glowStyle.color
        let popW: CGFloat = 400
        let popH: CGFloat = 300

        let win = FireflyWindow(
            contentRect: CGRect(x: 0, y: 0, width: popW, height: popH),
            styleMask: .borderless, backing: .buffered, defer: false
        )
        win.isOpaque = false
        win.backgroundColor = .clear
        win.hasShadow = true
        win.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 10)
        win.collectionBehavior = [.canJoinAllSpaces, .stationary]
        win.appearance = NSAppearance(named: .darkAqua)

        let container = NSView(frame: NSRect(x: 0, y: 0, width: popW, height: popH))
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor(red: 0.06, green: 0.06, blue: 0.1, alpha: 0.96).cgColor
        container.layer?.cornerRadius = 8
        container.layer?.masksToBounds = true
        container.layer?.borderWidth = 1.5
        container.layer?.borderColor = charColor.withAlphaComponent(0.5).cgColor
        container.autoresizingMask = [.width, .height]

        // Title bar (pixel game style)
        let titleH: CGFloat = 24
        let titleBar = NSView(frame: NSRect(x: 0, y: popH - titleH, width: popW, height: titleH))
        titleBar.wantsLayer = true
        titleBar.layer?.backgroundColor = NSColor(red: 0.08, green: 0.08, blue: 0.14, alpha: 1.0).cgColor
        container.addSubview(titleBar)

        let titleLabel = NSTextField(labelWithString: "⬡ PIX — \(definition.displayName)")
        titleLabel.font = NSFont(name: "Menlo-Bold", size: 10) ?? .monospacedSystemFont(ofSize: 10, weight: .bold)
        titleLabel.textColor = charColor
        titleLabel.frame = NSRect(x: 8, y: 4, width: 300, height: 16)
        titleBar.addSubview(titleLabel)

        let sep = NSView(frame: NSRect(x: 0, y: popH - titleH - 1, width: popW, height: 1))
        sep.wantsLayer = true
        sep.layer?.backgroundColor = charColor.withAlphaComponent(0.2).cgColor
        container.addSubview(sep)

        let terminal = TerminalView(frame: NSRect(x: 0, y: 0, width: popW, height: popH - titleH - 1))
        terminal.characterColor = charColor
        terminal.autoresizingMask = [.width, .height]
        terminal.onSendMessage = { [weak self] message in
            self?.claudeSession?.send(message: message)
        }
        container.addSubview(terminal)

        win.contentView = container
        popoverWindow = win
        terminalView = terminal
    }

    func updatePopoverPosition() {
        guard let pop = popoverWindow, isIdleForPopover else { return }
        guard let screen = NSScreen.main else { return }
        let charFrame = window.frame
        let popSize = pop.frame.size
        var x = charFrame.midX - popSize.width / 2
        let y = charFrame.maxY - 15
        x = max(screen.frame.minX + 4, min(x, screen.frame.maxX - popSize.width - 4))
        let clampedY = min(y, screen.frame.maxY - popSize.height - 4)
        pop.setFrameOrigin(NSPoint(x: x, y: clampedY))
    }

    // MARK: - Claude Session Wiring

    private func wireSession(_ session: ClaudeSession) {
        session.onText = { [weak self] text in
            self?.terminalView?.appendStreamingText(text)
        }
        session.onTurnComplete = { [weak self] in
            self?.terminalView?.endStreaming()
            SoundManager.shared.playCompletion()
            self?.showCompletionBubble()
        }
        session.onError = { [weak self] text in
            self?.terminalView?.appendError(text)
        }
        session.onToolUse = { [weak self] toolName, input in
            let summary = self?.formatToolInput(input) ?? ""
            self?.terminalView?.appendToolUse(toolName: toolName, summary: summary)
        }
        session.onToolResult = { [weak self] summary, isError in
            self?.terminalView?.appendToolResult(summary: summary, isError: isError)
        }
        session.onProcessExit = { [weak self] in
            self?.terminalView?.endStreaming()
            self?.terminalView?.appendError("Claude session ended.")
        }
    }

    private func formatToolInput(_ input: [String: Any]) -> String {
        if let cmd = input["command"] as? String { return cmd }
        if let path = input["file_path"] as? String { return path }
        if let pattern = input["pattern"] as? String { return pattern }
        return input.keys.sorted().prefix(3).joined(separator: ", ")
    }

    // MARK: - Thinking Phrases

    private func updateThinkingPhrase() {
        let now = CACurrentMediaTime()
        guard claudeSession?.isBusy ?? false else { return }
        if currentPhrase.isEmpty || now - lastPhraseUpdate > Double.random(in: 3.0...5.0) {
            var next = Self.thinkingPhrases.randomElement() ?? "..."
            while next == currentPhrase && Self.thinkingPhrases.count > 1 {
                next = Self.thinkingPhrases.randomElement() ?? "..."
            }
            currentPhrase = next
            lastPhraseUpdate = now
        }
    }

    func showCompletionBubble() {
        currentPhrase = Self.completionPhrases.randomElement() ?? "done!"
        showingCompletion = true
        completionBubbleExpiry = CACurrentMediaTime() + 3.0
    }
}
