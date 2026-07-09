//
//  ShortcutRecorderButton.swift
//  PasteHub
//
//  Button ghi nhận tổ hợp phím tắt mới cho ứng dụng.
//

import SwiftUI
import HotKey

struct ShortcutRecorderButton: View {
    @Binding var displayString: String
    @Binding var isRecording: Bool

    @State private var monitor: Any? = nil

    var body: some View {
        Button {
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        } label: {
            Text(isRecording ? String(localized: "settings.shortcut.pressKey") : displayString)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(isRecording ? Color.accent : Color.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isRecording
                              ? Color.accent.opacity(0.1)
                              : Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(
                                    isRecording
                                        ? Color.accent.opacity(0.5)
                                        : Color(NSColor.separatorColor),
                                    lineWidth: 0.5
                                )
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func startRecording() {
        isRecording = true

        monitor = NSEvent.addLocalMonitorForEvents(
            matching: .keyDown
        ) { [self] event in
            let mods = event.modifierFlags.intersection(
                [.command, .shift, .option, .control]
            )
            guard !mods.isEmpty else { return event }

            if let key = Key(carbonKeyCode: UInt32(event.keyCode)) {
                ShortcutManager.shared.register(
                    keyCode: key,
                    modifiers: mods
                )
                displayString = ShortcutManager.shared.shortcutDisplayString
            }

            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
    }
}
