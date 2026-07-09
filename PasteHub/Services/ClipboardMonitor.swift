import AppKit
import Combine

class ClipboardMonitor: ObservableObject {
    @Published var items: [ClipboardItem] = []

    private var timer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private let pollInterval = 0.5
    private let db = DatabaseManager.shared

    // MARK: - Lifecycle

    func start() {
        // Load items từ DB khi khởi động
        loadFromDatabase()

        timer = Timer.scheduledTimer(
            withTimeInterval: pollInterval,
            repeats: true
        ) { [weak self] _ in
            self?.checkForChanges()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Core Logic

    private func checkForChanges() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount

        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount
        
        // Lấy source app NGAY LÚC phát hiện thay đổi — thời điểm chính xác nhất
        let sourceApp = NSWorkspace.shared.frontmostApplication
        let sourceAppBundleID = sourceApp?.bundleIdentifier
        let sourceAppName = sourceApp?.localizedName
        
        // Exclude check
        if ExcludeManager.shared.isExcluded(bundleID: sourceAppBundleID) {
            return
        }
        
        guard var newItem = readCurrentClipboard() else { return }
         
        // Gán source app vào item
        newItem.sourceAppBundleID = sourceAppBundleID
        newItem.sourceAppName = sourceAppName
        
        // Tránh trùng item liền kề
        if let lastItem = items.first,
           lastItem.content == newItem.content,
           lastItem.contentType == newItem.contentType {
            return
        }
         
        saveAndAdd(newItem)
    }

    private func readCurrentClipboard() -> ClipboardItem? {
        let pasteboard = NSPasteboard.general

        // Text / URL
        if let string = pasteboard.string(forType: .string) {
            guard !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { return nil }

            if let url = URL(string: string),
               url.scheme == "http" || url.scheme == "https" {
                return ClipboardItem(content: string, contentType: .url)
            }
            return ClipboardItem(content: string, contentType: .text)
        }
        
        // File path
        if let fileURLs = pasteboard.readObjects(
            forClasses: [NSURL.self], options: nil
        ) as? [URL], let first = fileURLs.first {
            // Kiểm tra user setting
            guard UserDefaults.standard.bool(forKey: "saveFilePaths") else {
                return nil
            }
            return ClipboardItem(content: first.path, contentType: .filePath)
        }

        // Image
        let shouldSaveImages = UserDefaults.standard.bool(forKey: "saveImages")
        // Default true nếu chưa set
        let saveImages = UserDefaults.standard.object(forKey: "saveImages") == nil
            ? true : shouldSaveImages

        if saveImages, let filename = db.saveImage(from: pasteboard) {
            return ClipboardItem(content: filename, contentType: .image)
        }

        return nil
    }

    // MARK: - Database Operations

    private func loadFromDatabase() {
        DispatchQueue.global(qos: .userInitiated).async {
            let loaded = (try? DatabaseManager.shared.loadAllItems()) ?? []
            DispatchQueue.main.async {
                self.items = loaded
            }
        }
    }

    /// Gọi từ bên ngoài (AppDelegate) sau khi auto-clear xóa items
    func reloadFromDatabase() {
        loadFromDatabase()
    }

    private func saveAndAdd(_ item: ClipboardItem) {
        DispatchQueue.global(qos: .background).async {
            try? self.db.saveItem(item)
            try? self.db.trimIfNeeded()

            DispatchQueue.main.async {
                self.items.insert(item, at: 0)
                // Re-sort: pinned trước
                let pinned = self.items.filter { $0.isPinned }
                let unpinned = self.items.filter { !$0.isPinned }
                self.items = pinned + unpinned
            }
        }
    }

    func deleteItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        DispatchQueue.global(qos: .background).async {
            try? self.db.deleteItem(item)
        }
    }

    func clearAll() {
        items = items.filter { $0.isPinned }
        DispatchQueue.global(qos: .background).async {
            try? self.db.clearAll(keepPinned: true)
        }
    }

    func togglePin(_ item: ClipboardItem) {
        // Tìm bằng id thay vì Equatable — không bị ảnh hưởng bởi isPinned thay đổi
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        
        // Update
        items[index].isPinned.toggle()
        let updated = items[index]
        
        // Re-sort
        let pinned = items.filter { $0.isPinned }
        let unpinned = items.filter { !$0.isPinned }
        items = pinned + unpinned
        
        // Lưu xuống DB/
        DispatchQueue.global(qos: .background).async {
            try? self.db.updateItem(updated)
        }
    }

    func copyToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.contentType {
        case .text, .url, .filePath:
            pasteboard.setString(item.content, forType: .string)

        case .image:
            // Copy ảnh thực sự (PNG data) lên clipboard
            if let data = db.loadImageData(named: item.content) {
                pasteboard.setData(data, forType: .png)
            }
        }

        lastChangeCount = pasteboard.changeCount
    }

    // Search — dùng DB full-text
    func search(query: String) {
        guard !query.isEmpty else {
            loadFromDatabase()
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let results = (try? self.db.searchItems(query: query)) ?? []
            DispatchQueue.main.async {
                self.items = results
            }
        }
    }
}
