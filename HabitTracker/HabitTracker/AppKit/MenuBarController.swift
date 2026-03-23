import AppKit
import SwiftUI
import SwiftData

@MainActor
final class MenuBarController {
    private var statusItem: NSStatusItem?
    private lazy var popover: NSPopover = makePopover()

    var onOpenNexus: (() -> Void)?
    private let coordinator: GamificationCoordinator

    init(coordinator: GamificationCoordinator) {
        self.coordinator = coordinator
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "◈"
        statusItem?.button?.font = NSFont(name: "FiraCode-Regular", size: 14)
        statusItem?.button?.action = #selector(togglePopover)
        statusItem?.button?.target = self
    }

    private func makePopover() -> NSPopover {
        let p = NSPopover()
        p.contentSize = NSSize(width: 280, height: 320)
        p.behavior = .transient
        p.animates = false
        p.contentViewController = NSHostingController(
            rootView: MenuBarPanelView(onOpenNexus: { [weak self] in
                self?.popover.performClose(nil)
                self?.onOpenNexus?()
            })
            .environmentObject(coordinator)
            .modelContainer(coordinator.container)
        )
        return p
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            // Ensure SwiftUI content size is current
            popover.contentSize = popover.contentViewController?.view.fittingSize ?? NSSize(width: 280, height: 320)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
