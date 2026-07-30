//
//  MenuBarManager.swift
//  PasteHub
//
//  Quản lý status item trên menu bar và popover hiển thị nội dung chính.
//

import AppKit
import SwiftUI

final class MenuBarManager {
    private weak var appDelegate: AppDelegate?

    private(set) var statusItem: NSStatusItem?
    private(set) var popover: NSPopover?

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }

    // MARK: - Setup

    func setup(clipboardMonitor: ClipboardMonitor, updaterViewModel: UpdaterViewModel) {
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength
        )

        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "doc.on.clipboard",
                accessibilityDescription: "PasteHub"
            )
            button.action = #selector(AppDelegate.handleStatusItemClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = appDelegate
        }

        popover = NSPopover()
        popover?.contentSize = NSSize(width: 380, height: 600)
        popover?.behavior = .transient
        popover?.animates = true
        popover?.appearance = NSAppearance(named: .vibrantDark)
        popover?.contentViewController = NSHostingController(
            rootView: ContentView()
                .environmentObject(clipboardMonitor)
        )
    }

    // MARK: - Popover

    func togglePopover(previousFrontmostApp: inout NSRunningApplication?) {
        guard let button = statusItem?.button else { return }

        if let popover = popover {
            if popover.isShown {
                QuickLookPanel.shared.close()
                popover.performClose(nil)
            } else {
                previousFrontmostApp = NSWorkspace.shared.frontmostApplication
                popover.show(
                    relativeTo: button.bounds,
                    of: button,
                    preferredEdge: .minY
                )
                popover.contentSize = NSSize(width: 380, height: 600)
                NSApp.activate(ignoringOtherApps: true)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    if let window = self.popover?.contentViewController?.view.window {
                        window.animationBehavior = .documentWindow
                    }
                }
            }
        }
    }

    func closePopover() {
        QuickLookPanel.shared.close()
        popover?.performClose(nil)
    }

    // MARK: - Context Menu

    func showContextMenu(updaterViewModel: UpdaterViewModel) {
        let menu = NSMenu()

        let aboutItem = NSMenuItem(
            title: "About PasteHub",
            action: #selector(AppDelegate.showAbout),
            keyEquivalent: ""
        )
        menu.addItem(aboutItem)

        let checkForUpdatesItem = NSMenuItem(
            title: "Check for Updates…",
            action: #selector(AppDelegate.checkForUpdates),
            keyEquivalent: ""
        )
        checkForUpdatesItem.isEnabled = updaterViewModel.canCheckForUpdates
        menu.addItem(checkForUpdatesItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit PasteHub",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
}
