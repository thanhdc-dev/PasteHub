import AppKit
import SwiftUI
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) var shared: AppDelegate!
    var previousFrontmostApp: NSRunningApplication?
    let clipboardMonitor = ClipboardMonitor()
    let updaterViewModel = UpdaterViewModel()

    private(set) lazy var menuBarManager = MenuBarManager(appDelegate: self)
    private(set) lazy var appLifecycle = AppLifecycle(appDelegate: self)

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        requestClipboardAccess()
        clipboardMonitor.start()
        menuBarManager.setup(clipboardMonitor: clipboardMonitor, updaterViewModel: updaterViewModel)
        setupShortcut()
        appLifecycle.setupLoginItem()
        appLifecycle.runAutoClear()
        appLifecycle.setupAutoClearTimer()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor.stop()
        ShortcutManager.shared.stop()
        appLifecycle.invalidateTimer()
    }

    // MARK: - Status Item Click

    @objc func handleStatusItemClick() {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            menuBarManager.showContextMenu(updaterViewModel: updaterViewModel)
        } else {
            menuBarManager.togglePopover(previousFrontmostApp: &previousFrontmostApp)
        }
    }

    // MARK: - About & Updates

    @objc func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "PasteHub",
            .credits: NSAttributedString(
                string: "Clipboard history manager for MacOS",
                attributes: [.font: NSFont.systemFont(ofSize: 11)]
            ),
            .version: ""
        ])
    }

    @objc func checkForUpdates() {
        updaterViewModel.checkForUpdates()
    }

    // MARK: - Popover (delegates to MenuBarManager)

    @objc func togglePopover() {
        menuBarManager.togglePopover(previousFrontmostApp: &previousFrontmostApp)
    }

    func closePopover() {
        menuBarManager.closePopover()
    }

    // MARK: - Shortcut

    private func setupShortcut() {
        ShortcutManager.shared.onActivate = { [weak self] in
            DispatchQueue.main.async {
                self?.menuBarManager.togglePopover(previousFrontmostApp: &self!.previousFrontmostApp)
            }
        }
        ShortcutManager.shared.start()
    }

    // MARK: - Login Item (delegates to AppLifecycle)

    func enableLoginItem() {
        appLifecycle.enableLoginItem()
    }

    func disableLoginItem() {
        appLifecycle.disableLoginItem()
    }

    // MARK: - Auto-clear (delegates to AppLifecycle)

    func runAutoClear() {
        appLifecycle.runAutoClear()
    }

    // MARK: - Clipboard Access

    func requestClipboardAccess() {
        let pasteboard = NSPasteboard.general
        _ = pasteboard.changeCount
        print("Clipboard access requested")
    }
}
