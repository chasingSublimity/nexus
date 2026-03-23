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

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var mainWindowController: MainWindowController?
    private var effectRenderer: AnyEffectRenderer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = try! HabitStore()
        let renderer = SwiftUIEffectRenderer(userReduceMotion: {
            MainActor.assumeIsolated {
                (try? store.fetchOrCreateProfile())?.reduceMotion ?? false
            }
        })
        effectRenderer = AnyEffectRenderer(renderer)  // will be wired in Phase 3

        menuBarController = MenuBarController()
        mainWindowController = MainWindowController()

        if let renderer = effectRenderer {
            mainWindowController?.window?.contentView = NSHostingView(
                rootView: RootView(renderer: renderer)
                    .modelContainer(store.container)
            )
        }

        menuBarController?.store = store
        menuBarController?.onOpenNexus = { [weak self] in
            self?.mainWindowController?.showWindow(nil)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            mainWindowController?.showWindow(nil)
        }
        return true
    }
}
