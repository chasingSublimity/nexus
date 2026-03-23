import AppKit
import SwiftUI

private final class NexusWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    // Cmd+W
    override func performClose(_ sender: Any?) {
        orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
    }

    // Escape key
    override func cancelOperation(_ sender: Any?) {
        orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
    }
}

final class MainWindowController: NSWindowController {
    convenience init() {
        let window = NexusWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "NEXUS"
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(Color.voidBlack)
        window.minSize = NSSize(width: 700, height: 480)
        window.center()
        self.init(window: window)
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(sender)
        NSApp.activate(ignoringOtherApps: true)
    }
}
