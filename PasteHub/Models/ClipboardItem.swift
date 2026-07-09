import Foundation
import AppKit
import GRDB

// MARK: - ClipboardItem

struct ClipboardItem: Identifiable, Equatable {
    var id: UUID
    var content: String
    var contentType: ClipboardContentType
    var timestamp: Date
    var isPinned: Bool
    var sourceAppBundleID: String?
    var sourceAppName: String?

    var preview: String {
        guard contentType != .image else { return content }
        let maxLength = 100
        if content.count <= maxLength { return content }
        return String(content.prefix(maxLength)) + "…"
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    init(
        id: UUID = UUID(),
        content: String,
        contentType: ClipboardContentType,
        timestamp: Date = Date(),
        isPinned: Bool = false,
        sourceAppBundleID: String? = nil,
        sourceAppName: String? = nil
    ) {
        self.id = id
        self.content = content
        self.contentType = contentType
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.sourceAppBundleID = sourceAppBundleID
        self.sourceAppName = sourceAppName
    }
}

// MARK: - GRDB Conformance

extension ClipboardItem: @unchecked Sendable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "clipboard_items"

    enum Columns: String, ColumnExpression {
        case id, content, contentType, timestamp, isPinned
        case sourceAppBundleID
        case sourceAppName
    }

    // Tự encode thủ công — tránh circular reference với Codable
    nonisolated func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id.uuidString
        container[Columns.content] = content
        container[Columns.contentType] = contentType.rawValue
        container[Columns.timestamp] = timestamp
        container[Columns.isPinned] = isPinned
        container[Columns.sourceAppBundleID] = sourceAppBundleID
        container[Columns.sourceAppName] = sourceAppName
    }

    // Tự decode thủ công từ database row
    nonisolated init(row: Row) {
        id = UUID(uuidString: row[Columns.id]) ?? UUID()
        content = row[Columns.content]
        contentType = ClipboardContentType(
            rawValue: row[Columns.contentType]
        ) ?? .text
        timestamp = row[Columns.timestamp]
        isPinned = row[Columns.isPinned]
        sourceAppBundleID = row[Columns.sourceAppBundleID]
        sourceAppName = row[Columns.sourceAppName]
    }
}
