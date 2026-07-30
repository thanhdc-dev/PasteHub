import SwiftUI

struct QuickLookView: View {
    let item: ClipboardItem

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: contentTypeIcon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.contentType.rawValue.capitalized)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text(item.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if let appName = item.sourceAppName {
                    HStack(spacing: 5) {
                        Image(systemName: "app.badge")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Text(appName)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.bar)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    previewCard
                        .padding(.horizontal, 4)
                }
                .padding(16)
            }
            .background(Color(NSColor.windowBackgroundColor).opacity(0.95))

            if let appName = item.sourceAppName {
                Divider()
                HStack {
                    Image(systemName: "app.badge")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text("quicklook.from \(appName)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.bar)
            }
        }
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if item.contentType == .url {
                HStack {
                    Image(systemName: "link.circle.fill")
                        .foregroundStyle(Color.accentColor)
                        .font(.system(size: 14))
                    Text("Open link")
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                    HStack(spacing: 8) {
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(item.content, forType: .string)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.plain)
                        Link(destination: URL(string: item.content) ?? URL(string: "https://apple.com")!) {
                            Text("Open in Browser")
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.accentColor.opacity(0.16))
                                .clipShape(Capsule())
                        }
                    }
                }
            } else {
                HStack {
                    Text("Preview")
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(item.content, forType: .string)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.doc")
                            Text("Copy")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.accentColor.opacity(0.16))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            contentBody
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.82))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                        )
                )
        }
    }

    @ViewBuilder
    private var contentBody: some View {
        switch item.contentType {
        case .image:
            if let img = loadImage() {
                VStack(alignment: .center, spacing: 8) {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Text("Preview image")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("quicklook.loadError")
                    .foregroundStyle(.secondary)
            }

        case .url:
            VStack(alignment: .leading, spacing: 10) {
                Text(item.content)
                    .font(.system(size: 13))
                    .textSelection(.enabled)
                    .foregroundStyle(.primary)
                    .lineSpacing(4)
                if let url = URL(string: item.content) {
                    Link(destination: url) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.right.square")
                            Text("quicklook.openBrowser")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                    }
                }
            }

        case .filePath:
            VStack(alignment: .leading, spacing: 8) {
                Text(item.content)
                    .font(.system(size: 13, design: .monospaced))
                    .textSelection(.enabled)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("File")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(URL(fileURLWithPath: item.content).lastPathComponent)
                        .font(.system(size: 11))
                        .foregroundStyle(.primary)
                }
            }

        default: // .text
            Text(item.content)
                .font(.system(size: 13, design: .monospaced))
                .textSelection(.enabled)
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var contentTypeIcon: String {
        switch item.contentType {
        case .text:     return "doc.text"
        case .url:      return "link"
        case .image:    return "photo"
        case .filePath: return "folder"
        }
    }

    private func loadImage() -> NSImage? {
        DatabaseManager.shared.loadImage(named: item.content)
    }
}
