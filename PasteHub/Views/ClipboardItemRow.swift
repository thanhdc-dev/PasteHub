import SwiftUI

struct ClipboardItemRow: View {
    @EnvironmentObject var monitor: ClipboardMonitor
    let item: ClipboardItem
    let flatIndex: Int
    @ObservedObject var selection: SelectionState // ObservableObject — SwiftUI tự subscribe, re-render khi index/mode đổi
    let onCopy: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false
    @State private var isFlashing = false

    // Luôn đọc từ monitor — single source of truth
    private var isPinned: Bool {
        monitor.items.first { $0.id == item.id }?.isPinned ?? false
    }

    private var isSelected: Bool {
        selection.mode == .list && selection.index == flatIndex
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {

            // Icon hoặc thumbnail ảnh
            leadingView

            // Nội dung chính
            VStack(alignment: .leading, spacing: 4) {
                Text(item.preview)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Metadata row: source app + time + badges
                HStack(spacing: 5) {
                    // ── Source App ───────────────────────────────────────
                    if let bundleID = item.sourceAppBundleID {
                        SourceAppBadge(
                            bundleID: bundleID,
                            appName: item.sourceAppName
                        )
                    }

                    // Dấu phân cách chỉ hiện khi có source app
                    if item.sourceAppBundleID != nil {
                        Text("·")
                            .font(.system(size: 10))
                            .foregroundStyle(.quaternary)
                    }
                    // ────────────────────────────────────────────────────
                    Text(item.timeAgo)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)

                    if isPinned {
                        badge("ghim", color: .accent)
                            .font(.system(size: 11))
                    }

                    if item.contentType == .url {
                        badge("URL", color: .iconURLFG)
                    }

                    if item.contentType == .image {
                        badge("Ảnh", color: .iconImageFG)
                    }
                }
            }

            Spacer(minLength: 0)

            // Action buttons — chỉ hiện khi hover
            if isHovered || isSelected {
                HStack(spacing: 2) {
                    IconButton(
                        systemName: isPinned ? "pin.slash" : "pin",
                        action: onPin
                    )
                    IconButton(
                        systemName: "trash",
                        action: onDelete,
                        isDestructive: true
                    )
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(rowBackground)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            selection.mode = .list
            selection.index = flatIndex
            triggerFlash()
            onCopy()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var leadingView: some View {
        if item.contentType == .image {
            ImageThumbnail(filename: item.content)
        } else {
            ContentTypeIcon(type: item.contentType)
        }
    }

    private var rowBackground: some View {
        Group {
            if isFlashing {
                Color.accent.opacity(0.18)
            } else if isSelected {
                Color.accentColor.opacity(0.12)
            } else if isPinned {
                Color.accent.opacity(0.06)
            } else if isHovered {
                Color.primary.opacity(0.06)
            } else {
                Color.clear
            }
        }
        // Border trái khi được chọn bằng bàn phím
        .overlay(alignment: .leading) {
            if isSelected {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 2.5)
                    .padding(.vertical, 4)
            }
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Flash Effect

    private func triggerFlash() {
        // Bật flash ngay lập tức (không animate fade-in)
        isFlashing = true

        // Sau 150ms, fade mượt trở lại bình thường
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.35)) {
                isFlashing = false
            }
        }
    }
}

// MARK: - ContentTypeIcon

struct ContentTypeIcon: View {
    let type: ClipboardContentType

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(bgColor)
                .frame(width: 28, height: 28)
            Image(systemName: systemImage)
                .font(.system(size: 13))
                .foregroundStyle(fgColor)
        }
    }

    private var bgColor: Color {
        switch type {
        case .text:     return .iconText
        case .url:      return .iconURL
        case .image:    return .iconImage
        case .filePath: return .iconFile
        }
    }

    private var fgColor: Color {
        switch type {
        case .text:     return .iconTextFG
        case .url:      return .iconURLFG
        case .image:    return .iconImageFG
        case .filePath: return .iconFileFG
        }
    }

    private var systemImage: String {
        switch type {
        case .text:     return "doc.text"
        case .url:      return "link"
        case .image:    return "photo"
        case .filePath: return "folder"
        }
    }
}

// MARK: - ImageThumbnail

struct ImageThumbnail: View {
    let filename: String
    @State private var image: NSImage? = nil

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(Color(NSColor.controlBackgroundColor))
                .frame(width: 40, height: 40)

            if let img = image {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 16))
            }
        }
        .onAppear {
            // Load ảnh trên background thread
            DispatchQueue.global(qos: .userInitiated).async {
                let loaded = DatabaseManager.shared.loadImage(named: filename)
                DispatchQueue.main.async { image = loaded }
            }
        }
    }
}
