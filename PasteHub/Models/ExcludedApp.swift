//
//  ExcludedApp.swift
//  PasteHub
//
//  Model đại diện cho ứng dụng bị loại trừ khỏi clipboard history.
//

import AppKit

struct ExcludedApp: Identifiable, Equatable {
    let id      = UUID()
    let bundleID: String
    let name    : String
    var icon    : NSImage?

    static func == (lhs: ExcludedApp, rhs: ExcludedApp) -> Bool {
        lhs.bundleID == rhs.bundleID
    }
}
