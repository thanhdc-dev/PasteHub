//
//  SourceAppBadge.swift
//  PasteHub
//
//  Badge hiển thị icon + tên ứng dụng nguồn của clipboard item.
//

import SwiftUI

struct SourceAppBadge: View {
    let bundleID: String
    let appName: String?

    @State private var appIcon: NSImage? = nil

    var body: some View {
        HStack(spacing: 3) {
            // Icon
            Group {
                if let icon = appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .frame(width: 12, height: 12)
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 10))
                        .foregroundStyle(.quaternary)
                        .frame(width: 12, height: 12)
                }
            }

            // Tên app — ưu tiên localizedName, fallback lấy phần cuối bundle ID
            if let name = appName ?? bundleID.split(separator: ".").last.map(String.init) {
                Text(name)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .onAppear { loadIcon() }
    }

    private func loadIcon() {
        DispatchQueue.global(qos: .background).async {
            let path = NSWorkspace.shared.urlForApplication(
                withBundleIdentifier: bundleID
            )?.path ?? ""
            let icon = NSWorkspace.shared.icon(forFile: path)
            DispatchQueue.main.async {
                self.appIcon = icon
            }
        }
    }
}
