import AppKit
import SwiftData
import SwiftUI

@main
struct HabitTrackerEntryPoint {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var mainWindowController: MainWindowController?
    private var effectRenderer: AnyEffectRenderer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as an accessory app (no dock icon) so NSStatusItem.button.window
        // correctly refers to the system status bar window, not our key window.
        // We switch to .regular when the NEXUS window is shown.
        NSApp.setActivationPolicy(.accessory)

        let store = try! HabitStore()
        let coordinator = GamificationCoordinator(store: store)
        let renderer = SwiftUIEffectRenderer(userReduceMotion: {
            MainActor.assumeIsolated {
                (try? store.fetchOrCreateProfile())?.reduceMotion ?? false
            }
        })
        effectRenderer = AnyEffectRenderer(renderer)
        coordinator.wire(renderer: effectRenderer!)

        menuBarController = MenuBarController(coordinator: coordinator)
        mainWindowController = MainWindowController()

        if let renderer = effectRenderer {
            mainWindowController?.window?.contentView = NSHostingView(
                rootView: RootView(renderer: renderer, onClose: { [weak self] in
                    self?.mainWindowController?.window?.orderOut(nil)
                    NSApp.setActivationPolicy(.accessory)
                })
                .modelContainer(store.container)
                .environmentObject(coordinator)
            )
        }

        Task { await coordinator.requestNotificationPermission() }

        menuBarController?.onOpenNexus = { [weak self] in
            NSApp.setActivationPolicy(.regular)
            self?.mainWindowController?.showWindow(nil)
        }

        if CommandLine.arguments.contains("--uitesting") {
            NSApp.setActivationPolicy(.regular)
            mainWindowController?.showWindow(nil)
        }

        if CommandLine.arguments.contains("--uitesting-popover") {
            let popoverWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 280, height: 320),
                styleMask: [.titled],
                backing: .buffered,
                defer: false
            )
            popoverWindow.contentView = NSHostingView(
                rootView: MenuBarPanelView(onOpenNexus: { [weak self] in
                    NSApp.setActivationPolicy(.regular)
                    self?.mainWindowController?.showWindow(nil)
                })
                .environmentObject(coordinator)
                .modelContainer(store.container)
            )
            popoverWindow.center()
            popoverWindow.makeKeyAndOrderFront(nil)
            NSApp.setActivationPolicy(.regular)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            NSApp.setActivationPolicy(.regular)
            mainWindowController?.showWindow(nil)
        }
        return true
    }
}
