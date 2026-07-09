//
//  KeyboardMonitor.swift
//  PasteHub
//
//  Monitor bàn phím local (trong popover), dùng NSEvent.addLocalMonitorForEvents.
//

import AppKit

final class KeyboardMonitor {
    private var monitor: Any?
    var onKeyDown: ((NSEvent) -> Bool)?

    func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.onKeyDown?(event) == true ? nil : event
        }
    }

    func stop() {
        if let m = monitor { NSEvent.removeMonitor(m) }
        monitor = nil
    }
}
