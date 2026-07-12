//
//  AutoPasteManager.swift
//  PasteHub
//
//  Quản lý tính năng tự động dán (Auto-Paste) bằng cách giả lập tổ hợp phím Cmd+V.
//

import AppKit
import ApplicationServices

final class AutoPasteManager {
    static let shared = AutoPasteManager()
    
    private init() {}
    
    /// Trạng thái bật/tắt tính năng tự động dán
    var isEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: "autoPasteEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "autoPasteEnabled")
        }
    }
    
    /// Kiểm tra ứng dụng đã được cấp quyền Accessibility (Trợ năng) hay chưa
    var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }
    
    /// Yêu cầu hệ thống hiển thị thông báo yêu cầu cấp quyền Accessibility cho ứng dụng
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
    
    /// Mở trang cấu hình Accessibility trong System Settings của macOS
    func openAccessibilityPreferences() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Thực hiện giả lập nhấn Cmd+V để tự động dán vào ứng dụng đích trước đó
    /// - Parameter previousApp: Ứng dụng frontmost trước khi popover PasteHub được mở
    func performAutoPaste(previousApp: NSRunningApplication?) {
        guard isEnabled && isAccessibilityGranted else { return }
        guard let app = previousApp, !app.isTerminated else { return }
        
        // Không thực hiện dán nếu app đích là chính PasteHub
        guard app.bundleIdentifier != Bundle.main.bundleIdentifier else { return }
        
        // Kích hoạt lại app đích
        app.activate(options: [])
        
        // Trì hoãn 100ms để đảm bảo app đích nhận đủ tiêu điểm trước khi phát sự kiện bàn phím
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let source = CGEventSource(stateID: .hidSystemState)
            
            // virtualKey: 9 là mã phím 'V' trên macOS (kVK_ANSI_V)
            guard let eventVDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true) else { return }
            eventVDown.flags = .maskCommand
            
            guard let eventVUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else { return }
            eventVUp.flags = .maskCommand
            
            // Phát sự kiện
            eventVDown.post(tap: .cghidEventTap)
            eventVUp.post(tap: .cghidEventTap)
        }
    }
}
