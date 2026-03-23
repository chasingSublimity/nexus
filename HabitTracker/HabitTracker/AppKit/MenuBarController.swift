import AppKit
import SwiftUI
import SwiftData

final class MenuBarController {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    var onOpenNexus: (() -> Void)?
    var store: HabitStore?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "◈"
        statusItem?.button?.font = NSFont(name: "FiraCode-Regular", size: 14)
        statusItem?.button?.action = #selector(togglePopover)
        statusItem?.button?.target = self
    }

    @objc private func togglePopover() {
        if let popover, popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let store else { return }
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 320)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: Text("[OPEN NEXUS]")
                .font(.firaCode(12))
                .foregroundColor(.neonGreen)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.voidBlack)
                .onTapGesture { [weak self] in
                    popover.performClose(nil)
                    self?.onOpenNexus?()
                }
                .modelContainer(store.container)
        )
        self.popover = popover

        if let button = statusItem?.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
