import AppKit
import Combine
import SwiftUI

/// Quản lý danh sách ứng dụng bị loại trừ khỏi clipboard history.
/// Lưu vào UserDefaults, tự động pre-populate các password manager phổ biến.
final class ExcludeManager: ObservableObject {

    static let shared = ExcludeManager()

    // MARK: - UserDefaults key
    private let kExcludedIDs  = "excludedBundleIDs"
    private let kDidSeedOnce  = "excludeManagerDidSeedDefaults"

    // MARK: - Published state (dùng trong SwiftUI)
    @Published private(set) var excludedApps: [ExcludedApp] = []

    // MARK: - Known password managers (seed mặc định)
    static let defaultPasswordManagers: [ExcludedApp] = [
        ExcludedApp(bundleID: "com.agilebits.onepassword7",   name: "1Password 7"),
        ExcludedApp(bundleID: "com.1password.1password",      name: "1Password"),
        ExcludedApp(bundleID: "com.bitwarden.desktop",        name: "Bitwarden"),
        ExcludedApp(bundleID: "com.lastpass.LastPass",        name: "LastPass"),
        ExcludedApp(bundleID: "com.dashlane.Dashlane",        name: "Dashlane"),
        ExcludedApp(bundleID: "org.keepassxc.keepassxc",      name: "KeePassXC"),
        ExcludedApp(bundleID: "com.apple.keychainaccess",     name: "Keychain Access"),
        ExcludedApp(bundleID: "com.enpass.Enpass",            name: "Enpass"),
        ExcludedApp(bundleID: "com.agilebits.onepassword-osx",name: "1Password (legacy)"),
    ]

    // MARK: - Init
    private init() {
        seedDefaultsIfNeeded()
        load()
    }

    // MARK: - Public API

    /// Kiểm tra xem bundle ID có bị loại trừ không — gọi từ ClipboardMonitor
    func isExcluded(bundleID: String?) -> Bool {
        guard let id = bundleID, !id.isEmpty else { return false }
        return excludedApps.contains { $0.bundleID == id }
    }

    /// Thêm app mới vào danh sách
    @discardableResult
    func add(_ app: ExcludedApp) -> Bool {
        guard !excludedApps.contains(where: { $0.bundleID == app.bundleID }) else { return false }
        excludedApps.append(app)
        save()
        return true
    }

    /// Xóa theo index (dùng trong List onDelete)
    func remove(at offsets: IndexSet) {
        excludedApps.remove(atOffsets: offsets)
        save()
    }

    /// Xóa theo bundle ID
    func remove(bundleID: String) {
        excludedApps.removeAll { $0.bundleID == bundleID }
        save()
    }

    /// Thêm app đang chạy ở foreground vào danh sách (convenience)
    @discardableResult
    func addFrontmostApp() -> ExcludedApp? {
        guard let app = AppDelegate.shared.previousFrontmostApp ?? NSWorkspace.shared.frontmostApplication,
              let id  = app.bundleIdentifier,
              !id.isEmpty,
              id != Bundle.main.bundleIdentifier
        else { return nil }

        let name = app.localizedName ?? id
        let entry = ExcludedApp(bundleID: id, name: name, icon: app.icon)
        add(entry)
        return entry
    }

    // MARK: - Persistence

    private func load() {
        guard let raw = UserDefaults.standard.array(forKey: kExcludedIDs) as? [[String: String]]
        else { excludedApps = []; return }

        excludedApps = raw.compactMap { dict in
            guard let id = dict["bundleID"], let name = dict["name"] else { return nil }
            // Cố gắng lấy icon của app từ hệ thống (nếu app đang cài)
            let icon = NSWorkspace.shared.icon(forFile:
                NSWorkspace.shared.urlForApplication(withBundleIdentifier: id)?.path ?? ""
            )
            return ExcludedApp(bundleID: id, name: name, icon: icon)
        }
    }

    private func save() {
        let raw = excludedApps.map { ["bundleID": $0.bundleID, "name": $0.name] }
        UserDefaults.standard.set(raw, forKey: kExcludedIDs)
    }

    /// Lần đầu chạy app: tự động thêm các password manager phổ biến đã cài
    private func seedDefaultsIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: kDidSeedOnce) else { return }
        UserDefaults.standard.set(true, forKey: kDidSeedOnce)

        // Chỉ seed những app thực sự đang được cài trên máy
        let installed = Self.defaultPasswordManagers.filter { app in
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleID) != nil
        }

        if !installed.isEmpty {
            let raw = installed.map { ["bundleID": $0.bundleID, "name": $0.name] }
            UserDefaults.standard.set(raw, forKey: kExcludedIDs)
        }
    }
}
