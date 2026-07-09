//
//  IconButton.swift
//  PasteHub
//
//  Button icon nhỏ gọn, dùng cho các action trong danh sách item.
//

import SwiftUI

struct IconButton: View {
    let systemName: String
    var action: (() -> Void)? = nil
    var isDestructive: Bool = false

    var body: some View {
        Button {
            action?()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 13))
                .foregroundStyle(isDestructive ? .red : .secondary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
