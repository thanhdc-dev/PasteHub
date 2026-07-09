import SwiftUI

enum ClipboardFilter: String, CaseIterable {
    case all
    case text
    case url
    case image
    case filePath

    var systemImage: String {
        switch self {
        case .all:      return "list.bullet"
        case .text:     return "doc.text"
        case .url:      return "link"
        case .image:    return "photo"
        case .filePath: return "folder"
        }
    }

    var localizedDisplayName: String {
        switch self {
        case .all:      String(localized: "filter.all")
        case .text:     String(localized: "filter.text")
        case .url:      String(localized: "filter.url")
        case .image:    String(localized: "filter.image")
        case .filePath: String(localized: "filter.file")
        }
    }
}

struct FilterChipBar: View {
    @Binding var selected: ClipboardFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ClipboardFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        filter: filter,
                        isSelected: selected == filter
                    ) {
                        selected = filter
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }
}

struct FilterChip: View {
    let filter: ClipboardFilter
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: filter.systemImage)
                    .font(.system(size: 11))
                Text(filter.localizedDisplayName)
                    .font(.system(size: 12))
            }
            .foregroundStyle(isSelected ? Color.accent : Color.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isSelected
                          ? Color.accent.opacity(0.12)
                          : Color.clear)
                    .overlay(
                        Capsule()
                            .stroke(
                                isSelected
                                    ? Color.accent.opacity(0.4)
                                    : Color(NSColor.separatorColor),
                                lineWidth: 0.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
