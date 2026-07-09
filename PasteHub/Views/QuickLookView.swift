import SwiftUI

struct QuickLookView: View {
    let item: ClipboardItem

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label(item.contentType.rawValue.capitalized,
                      systemImage: contentTypeIcon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(item.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)

            Divider()

            // Content
            ScrollView {
                contentBody
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Source app (nếu có)
            if let appName = item.sourceAppName {
                Divider()
                HStack {
                    Image(systemName: "app.badge")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text("quicklook.from \(appName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.bar)
            }
        }
    }

    @ViewBuilder
    private var contentBody: some View {
        switch item.contentType {
        case .image:
            if let img = loadImage() {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            } else {
                Text("quicklook.loadError")
                    .foregroundStyle(.secondary)
            }

        case .url:
            VStack(alignment: .leading, spacing: 12) {
                Text(item.content)
                    .font(.body)
                    .textSelection(.enabled)
                if let url = URL(string: item.content) {
                    Link("quicklook.openBrowser", destination: url)
                        .font(.callout)
                }
            }

        case .filePath:
            VStack(alignment: .leading, spacing: 8) {
                Text(item.content)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                Text(URL(fileURLWithPath: item.content).lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        default: // .text
            Text(item.content)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
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
        let url = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PasteHub/images/\(item.content).png")
        return NSImage(contentsOf: url)
    }
}
