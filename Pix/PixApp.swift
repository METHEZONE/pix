import SwiftUI
import AppKit

@main
struct PixApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var controller: PixController?
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        controller = PixController()
        controller?.start()
        setupMenuBar()
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller?.shutdown()
    }

    // MARK: - Menu Bar

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "sparkle", accessibilityDescription: "Pix")
        }
        rebuildMenu()
    }

    func rebuildMenu() {
        let menu = NSMenu()

        // Characters section
        if let chars = controller?.characters {
            for (i, char) in chars.enumerated() {
                let def = char.definition
                let locked = !char.isUnlocked
                let title = locked ? "\(def.displayName) 🔒" : def.displayName
                let item = NSMenuItem(title: title, action: locked ? nil : #selector(toggleCharacter(_:)), keyEquivalent: "\(i + 1)")
                item.tag = i
                item.state = char.isActive ? .on : .off
                item.isEnabled = !locked
                menu.addItem(item)
            }
        }

        menu.addItem(NSMenuItem.separator())

        // Sounds
        let soundItem = NSMenuItem(title: "Sounds", action: #selector(toggleSounds(_:)), keyEquivalent: "")
        soundItem.state = SoundManager.shared.isEnabled ? .on : .off
        menu.addItem(soundItem)

        // Theme submenu
        let themeItem = NSMenuItem(title: "Style", action: nil, keyEquivalent: "")
        let themeMenu = NSMenu()
        for (i, theme) in PopoverTheme.allThemes.enumerated() {
            let item = NSMenuItem(title: theme.name, action: #selector(switchTheme(_:)), keyEquivalent: "")
            item.tag = i
            item.state = PopoverTheme.current.name == theme.name ? .on : .off
            themeMenu.addItem(item)
        }
        themeItem.submenu = themeMenu
        menu.addItem(themeItem)

        // Plugins submenu
        let pluginItem = NSMenuItem(title: "Plugins", action: nil, keyEquivalent: "")
        let pluginMenu = NSMenu()
        if let modules = controller?.moduleRegistry.modules {
            for mod in modules {
                let item = NSMenuItem(title: mod.name, action: #selector(togglePlugin(_:)), keyEquivalent: "")
                item.representedObject = mod.id
                item.state = mod.isActive ? .on : .off
                pluginMenu.addItem(item)
            }
        }
        pluginItem.submenu = pluginMenu
        menu.addItem(pluginItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    // MARK: - Actions

    @objc func toggleCharacter(_ sender: NSMenuItem) {
        guard let chars = controller?.characters, sender.tag < chars.count else { return }
        let char = chars[sender.tag]
        char.isActive.toggle()
        if char.isActive {
            char.window.orderFrontRegardless()
        } else {
            char.window.orderOut(nil)
            char.closePopover()
        }
        rebuildMenu()
    }

    @objc func toggleSounds(_ sender: NSMenuItem) {
        SoundManager.shared.isEnabled.toggle()
        rebuildMenu()
    }

    @objc func switchTheme(_ sender: NSMenuItem) {
        let idx = sender.tag
        guard idx < PopoverTheme.allThemes.count else { return }
        PopoverTheme.current = PopoverTheme.allThemes[idx]
        controller?.characters.forEach { char in
            char.popoverWindow = nil
            char.terminalView = nil
        }
        rebuildMenu()
    }

    @objc func togglePlugin(_ sender: NSMenuItem) {
        guard let modId = sender.representedObject as? String else { return }
        controller?.moduleRegistry.toggle(moduleId: modId)
        rebuildMenu()
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}
