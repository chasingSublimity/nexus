import AppKit
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

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = try! HabitStore()
        let renderer = SwiftUIEffectRenderer(userReduceMotion: {
            MainActor.assumeIsolated {
                (try? store.fetchOrCreateProfile())?.reduceMotion ?? false
            }
        })
        let anyRenderer = AnyEffectRenderer(renderer)
        _ = anyRenderer  // will be wired in Phase 3

        menuBarController = MenuBarController()
        mainWindowController = MainWindowController()

        mainWindowController?.window?.contentView = NSHostingView(
            rootView: Text("NEXUS LOADING...")
                .font(.firaCode(16))
                .foregroundColor(.neonGreen)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.voidBlack)
        )

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
