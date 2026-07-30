//
//  View+Helpers.swift
//  PasteHub
//
//  Các helper View dùng chung: sectionHeader, settingRow.
//

import SwiftUI

extension View {
    /// Header cho từng section trong Settings.
    @ViewBuilder
    func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.tertiary)
            .textCase(.uppercase)
            .padding(.horizontal, 14)
            .padding(.top, 18)
            .padding(.bottom, 8)
    }

    /// Row layout chuẩn cho mỗi mục settings.
    @ViewBuilder
    func settingRow<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            content()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }
}
