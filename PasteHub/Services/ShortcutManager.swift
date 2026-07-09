import AppKit
import HotKey

class ShortcutManager {
    static let shared = ShortcutManager()

    private var hotKey: HotKey?

    // Callback được gọi khi shortcut được nhấn
    var onActivate: (() -> Void)?

    private init() {}

    func start() {
        register(
            keyCode: readSavedKeyCode(),
            modifiers: readSavedModifiers()
        )
    }

    func stop() {
        hotKey = nil
    }

    // MARK: - Register

    func register(keyCode: Key, modifiers: NSEvent.ModifierFlags) {
        // Hủy shortcut cũ trước
        hotKey = nil

        hotKey = HotKey(key: keyCode, modifiers: modifiers)
        hotKey?.keyDownHandler = { [weak self] in
            self?.onActivate?()
        }

        // Lưu lại setting
        saveShortcut(keyCode: keyCode, modifiers: modifiers)
    }

    // MARK: - Persist shortcut setting

    private func saveShortcut(keyCode: Key, modifiers: NSEvent.ModifierFlags) {
        UserDefaults.standard.set(keyCode.carbonKeyCode, forKey: "shortcutKeyCode")
        UserDefaults.standard.set(modifiers.rawValue, forKey: "shortcutModifiers")
    }

    private func readSavedKeyCode() -> Key {
        let saved = UserDefaults.standard.integer(forKey: "shortcutKeyCode")
        // Default: V (carbonKeyCode = 9)
        let code = saved == 0 ? UInt32(9) : UInt32(saved)
        return Key(carbonKeyCode: code) ?? .v
    }

    private func readSavedModifiers() -> NSEvent.ModifierFlags {
        let raw = UserDefaults.standard.integer(forKey: "shortcutModifiers")
        // Default: ⌘⌥
        return raw == 0
        ? [.command, .option]
            : NSEvent.ModifierFlags(rawValue: UInt(raw))
    }

    // Hiển thị shortcut dạng string: "⌘⇧V"
    var shortcutDisplayString: String {
        var parts = ""
        let mods = readSavedModifiers()
        if mods.contains(.control) { parts += "⌃" }
        if mods.contains(.option)  { parts += "⌥" }
        if mods.contains(.shift)   { parts += "⇧" }
        if mods.contains(.command) { parts += "⌘" }
        parts += readSavedKeyCode().description.uppercased()
        return parts
    }
}
