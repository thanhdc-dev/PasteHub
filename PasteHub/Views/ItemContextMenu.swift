import SwiftUI

struct ItemContextMenu: View {
    @EnvironmentObject var monitor: ClipboardMonitor
    let item: ClipboardItem

    // Luôn đọc từ monitor
    private var isPinned: Bool {
        monitor.items.first { $0.id == item.id }?.isPinned ?? false
    }

    var body: some View {
        Button {
            monitor.copyToPasteboard(item)
        } label: {
            Label("itemContextMenu.copy", systemImage: "doc.on.doc")
        }

        Button {
            monitor.togglePin(item)
        } label: {
            Label(
                isPinned ? "itemContextMenu.unpin" : "itemContextMenu.pin",
                systemImage: isPinned ? "pin.slash" : "pin"
            )
        }

        Divider()

        Button(role: .destructive) {
            monitor.deleteItem(item)
        } label: {
            Label("itemContextMenu.delete", systemImage: "trash")
        }
    }
}
