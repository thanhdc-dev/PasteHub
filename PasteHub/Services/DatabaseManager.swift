import Foundation
import GRDB
import AppKit

class DatabaseManager {
    static let shared = DatabaseManager()

    private var dbQueue: DatabaseQueue!
    private let imageStorage = ImageStorageManager.shared

    private let appSupportURL: URL = {
        let urls = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )
        return urls[0].appendingPathComponent("PasteHub", isDirectory: true)
    }()

    // MARK: - Setup

    private init() {
        do {
            try imageStorage.setupDirectories()
            try setupDatabase()
            try cleanupOrphanedImages()
        } catch {
            fatalError("Không thể khởi tạo database: \(error)")
        }
    }

    private func setupDatabase() throws {
        let dbURL = appSupportURL.appendingPathComponent("pastehub.sqlite")
        dbQueue = try DatabaseQueue(path: dbURL.path)
        try runMigrations()
    }

    // MARK: - Migrations

    private func runMigrations() throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_create_clipboard_items") { db in
            try db.create(table: "clipboard_items") { t in
                t.column("id", .text).primaryKey()
                t.column("content", .text).notNull()
                t.column("contentType", .text).notNull()
                t.column("timestamp", .datetime).notNull()
                t.column("isPinned", .boolean).notNull().defaults(to: false)
            }

            // Index để tăng tốc search và sort
            try db.create(
                index: "idx_timestamp",
                on: "clipboard_items",
                columns: ["timestamp"]
            )
            try db.create(
                index: "idx_isPinned",
                on: "clipboard_items",
                columns: ["isPinned"]
            )
        }
        
        migrator.registerMigration("v2_add_source_app_info") { db in
            try db.alter(table: "clipboard_items") { t in
                t.add(column: "sourceAppBundleID", .text)
                t.add(column: "sourceAppName", .text)
            }
        }

        try migrator.migrate(dbQueue)
    }

    // MARK: - CRUD Operations

    func saveItem(_ item: ClipboardItem) throws {
        var mutableItem = item
        try dbQueue.write { db in
            try mutableItem.insert(db)
        }
    }

    func loadAllItems(limit: Int = 500) throws -> [ClipboardItem] {
        try dbQueue.read { db in
            // Pinned items trước, sau đó sort theo thời gian mới nhất
            try ClipboardItem
                .order(
                    ClipboardItem.Columns.isPinned.desc,
                    ClipboardItem.Columns.timestamp.desc
                )
                .limit(limit)
                .fetchAll(db)
        }
    }

    func deleteItem(_ item: ClipboardItem) throws {
        try dbQueue.write { db in
            _ = try item.delete(db)
        }

        if item.contentType == .image {
            imageStorage.deleteImageFile(named: item.content)
        }
    }

    func updateItem(_ item: ClipboardItem) throws {
        try dbQueue.write { db in
            try item.update(db)
        }
    }

    func clearAll(keepPinned: Bool = true) throws {
    // Trước tiên lấy danh sách ảnh cần xóa
    let imageItems = try dbQueue.read { db in
        try ClipboardItem
            .filter(ClipboardItem.Columns.contentType == ClipboardContentType.image.rawValue)
            .fetchAll(db)
    }

    try dbQueue.write { db in
        if keepPinned {
            // Explicitly discard the Int result
            _ = try ClipboardItem
                .filter(ClipboardItem.Columns.isPinned == false)
                .deleteAll(db)
        } else {
            _ = try ClipboardItem.deleteAll(db)
        }
    }

    // Xóa file ảnh tương ứng
    for item in imageItems {
        if !keepPinned || !item.isPinned {
            imageStorage.deleteImageFile(named: item.content)
        }
    }
}

    func searchItems(query: String) throws -> [ClipboardItem] {
        try dbQueue.read { db in
            try ClipboardItem
                .filter(ClipboardItem.Columns.content.like("%\(query)%"))
                .order(
                    ClipboardItem.Columns.isPinned.desc,
                    ClipboardItem.Columns.timestamp.desc
                )
                .fetchAll(db)
        }
    }

    // MARK: - Image Storage (delegates to ImageStorageManager)

    func saveImage(from pasteboard: NSPasteboard) -> String? {
        imageStorage.saveImage(from: pasteboard)
    }

    func loadImage(named filename: String) -> NSImage? {
        imageStorage.loadImage(named: filename)
    }

    func loadImageData(named filename: String) -> Data? {
        imageStorage.loadImageData(named: filename)
    }

    // MARK: - Auto-clear theo thời gian

    /// Xóa các item (không ghim) cũ hơn `days` ngày.
    /// Trả về số item đã xóa.
    @discardableResult
    func deleteItemsOlderThan(days: Int) throws -> Int {
        guard days > 0 else { return 0 }   // days = 0 nghĩa là "mãi mãi" — không xóa

        let cutoff = Calendar.current.date(
            byAdding: .day, value: -days, to: Date()
        ) ?? Date()

        var deletedItems: [ClipboardItem] = []

        try dbQueue.write { db in
            deletedItems = try ClipboardItem
                .filter(ClipboardItem.Columns.isPinned == false)
                .filter(ClipboardItem.Columns.timestamp < cutoff)
                .fetchAll(db)

            try ClipboardItem
                .filter(ClipboardItem.Columns.isPinned == false)
                .filter(ClipboardItem.Columns.timestamp < cutoff)
                .deleteAll(db)
        }

        // Xóa file ảnh sau khi transaction commit
        for item in deletedItems where item.contentType == .image {
            imageStorage.deleteImageFile(named: item.content)
        }

        return deletedItems.count
    }

    // MARK: - Trim old items

    /// Gọi định kỳ để giữ DB không quá lớn
    func trimIfNeeded(maxItems: Int = 500) throws {
        // Lưu các item cần xóa để xử lý file sau khi transaction thành công
        var itemsToDelete: [ClipboardItem] = []

        try dbQueue.write { db in
            // Đếm số unpinned items
            let count = try ClipboardItem
                .filter(ClipboardItem.Columns.isPinned == false)
                .fetchCount(db)

            guard count > maxItems else { return }

            // Xóa các item cũ nhất vượt quá giới hạn
            let overflow = count - maxItems
            
            // Lấy đầy đủ item thay vì chỉ lấy ID
            itemsToDelete = try ClipboardItem
                .filter(ClipboardItem.Columns.isPinned == false)
                .order(ClipboardItem.Columns.timestamp.asc)
                .limit(overflow)
                .fetchAll(db)
            
            let ids = itemsToDelete.map { $0.id.uuidString }
            
            try ClipboardItem
                .filter(ids.contains(ClipboardItem.Columns.id))
                .deleteAll(db)
        }
        // Chỉ xóa file sau khi transaction DB đã commit thành công
        for item in itemsToDelete {
            if item.contentType == .image {
                imageStorage.deleteImageFile(named: item.content)
            }
        }
    }
    
    func cleanupOrphanedImages() throws {
        let referencedFiles: Set<String> = try dbQueue.read { db in
            let imageItems = try ClipboardItem
                .filter(
                    ClipboardItem.Columns.contentType ==
                    ClipboardContentType.image.rawValue
                )
                .fetchAll(db)

            return Set(imageItems.map(\.content))
        }

        try imageStorage.cleanupOrphanedImages(referencedFiles: referencedFiles)
    }
}
