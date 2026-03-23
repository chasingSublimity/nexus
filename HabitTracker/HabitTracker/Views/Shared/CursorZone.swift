import AppKit
import SwiftUI

/// Invisible overlay that updates the cursor when the mouse enters its bounds.
/// Returns nil from hitTest so resize drags pass through to the window.
struct CursorZone: NSViewRepresentable {
    let cursor: NSCursor

    func makeNSView(context: Context) -> CursorZoneNSView {
        CursorZoneNSView(cursor: cursor)
    }

    func updateNSView(_ nsView: CursorZoneNSView, context: Context) {}
}

final class CursorZoneNSView: NSView {
    private let cursor: NSCursor

    init(cursor: NSCursor) {
        self.cursor = cursor
        super.init(frame: .zero)
        addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect],
            owner: self,
            userInfo: nil
        ))
    }

    required init?(coder: NSCoder) { fatalError() }

    override func mouseEntered(with event: NSEvent) { cursor.push() }
    override func mouseExited(with event: NSEvent) { NSCursor.pop() }
    override func resetCursorRects() { addCursorRect(bounds, cursor: cursor) }

    // Let all clicks fall through so window edge-drag resize still works.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
