//
//  AppLifecycle.swift
//  PasteHub
//
//  Quản lý vòng đời ứng dụng: login item (launch at login), auto-clear timer.
//

import AppKit
import ServiceManagement

final class AppLifecycle {
    private weak var appDelegate: AppDelegate?
    private var autoClearTimer: Timer?

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }

    // MARK: - Login Item

    func setupLoginItem() {
        let launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        if launchAtLogin {
            enableLoginItem()
        }
    }

    func enableLoginItem() {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
            } catch {
                print("Lỗi đăng ký launch at login: \(error)")
            }
        }
    }

    func disableLoginItem() {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.unregister()
            } catch {
                print("Lỗi hủy launch at login: \(error)")
            }
        }
    }

    // MARK: - Auto-clear

    func setupAutoClearTimer() {
        autoClearTimer?.invalidate()
        autoClearTimer = Timer.scheduledTimer(
            withTimeInterval: 3600,  // 1 giờ
            repeats: true
        ) { [weak self] _ in
            self?.runAutoClear()
        }
    }

    func invalidateTimer() {
        autoClearTimer?.invalidate()
    }

    func runAutoClear() {
        let days = UserDefaults.standard.integer(forKey: "retentionDays")
        guard days > 0 else { return }

        DispatchQueue.global(qos: .background).async { [weak self] in
            let deleted = (try? DatabaseManager.shared.deleteItemsOlderThan(days: days)) ?? 0
            guard deleted > 0 else { return }

            DispatchQueue.main.async {
                self?.appDelegate?.clipboardMonitor.reloadFromDatabase()
            }
        }
    }
}
