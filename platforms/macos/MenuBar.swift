import Cocoa
import SwiftUI

class MenuBarController {
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "GoNhanh")
        }

        setupMenu()

        // Start keyboard hook
        RustBridge.startHook()
    }

    private func setupMenu() {
        let menu = NSMenu()

        let enabledItem = NSMenuItem(
            title: "Bật GoNhanh",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        enabledItem.target = self
        enabledItem.state = .on
        menu.addItem(enabledItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(
            title: "Cài đặt...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        let aboutItem = NSMenuItem(
            title: "Về GoNhanh",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Thoát",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc func toggleEnabled() {
        // TODO: Toggle via Rust
        if let item = statusItem.menu?.item(at: 0) {
            item.state = item.state == .on ? .off : .on
        }
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let contentView = SettingsView()
            let hostingController = NSHostingController(rootView: contentView)

            settingsWindow = NSWindow(contentViewController: hostingController)
            settingsWindow?.title = "GoNhanh - Cài đặt"
            settingsWindow?.styleMask = [.titled, .closable]
            settingsWindow?.setContentSize(NSSize(width: 400, height: 300))
            settingsWindow?.center()
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func showAbout() {
        let options: [NSApplication.AboutPanelOptionKey: Any] = [
            .applicationName: "GoNhanh",
            .applicationVersion: "0.1.0",
            .credits: NSAttributedString(string: "Bộ gõ tiếng Việt hiệu suất cao\n\n🦀 Made with Rust + SwiftUI")
        ]
        NSApp.orderFrontStandardAboutPanel(options: options)
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }
}
