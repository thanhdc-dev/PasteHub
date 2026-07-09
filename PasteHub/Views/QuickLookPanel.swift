import AppKit
import SwiftUI

final class QuickLookPanel {
    static let shared = QuickLookPanel()
    private var panel: NSPanel?

    func show(item: ClipboardItem) {
        // Nếu đang show cùng item → đóng (toggle)
        if let existing = panel, existing.isVisible,
           (existing.contentViewController as? NSHostingController<QuickLookView>)?.rootView.item.id == item.id {
            close()
            return
        }

        close()

        let hostingVC = NSHostingController(rootView: QuickLookView(item: item))

        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.title = "Quick Look"
        p.contentViewController = hostingVC
        p.setContentSize(NSSize(width: 520, height: 420))
        p.isFloatingPanel = true
        p.becomesKeyOnlyIfNeeded = true  // ← giữ focus ở popover
        p.center()
        p.orderFront(nil)

        self.panel = p
    }

    func close() {
        panel?.close()
        panel = nil
    }

    var isVisible: Bool { panel?.isVisible ?? false }
}
