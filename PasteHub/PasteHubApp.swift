//
//  PasteHubApp.swift
//  PasteHub
//
//  Created by ThanhDC on 9/6/26.
//

import SwiftUI

@main
struct PasteHubApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

        var body: some Scene {
            // Không có WindowGroup — đây là menu bar only app
            Settings {
                EmptyView()
            }
        }
}
