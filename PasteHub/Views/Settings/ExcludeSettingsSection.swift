import SwiftUI
import AppKit

struct ExcludeSettingsSection: View {

    @ObservedObject private var manager = ExcludeManager.shared

    @State private var showAddSheet     = false
    @State private var manualBundleID   = ""
    @State private var manualAppName    = ""
    @State private var errorMessage     : String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // ── Header ──────────────────────────────────────────────────────
            HStack {
                Label("exclude.title", systemImage: "eye.slash")
                    .font(.headline)
                Spacer()
                Text("\(manager.excludedApps.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Capsule())
            }

            Text("exclude.description")
                .font(.caption)
                .foregroundColor(.secondary)

            // ── Danh sách excluded ──────────────────────────────────────────
            if manager.excludedApps.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.shield")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("exclude.empty")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 10)
                    Spacer()
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(manager.excludedApps.enumerated()), id: \.element.id) { idx, app in
                        ExcludeRow(app: app) {
                            withAnimation { manager.remove(bundleID: app.bundleID) }
                        }
                        if idx < manager.excludedApps.count - 1 {
                            Divider().padding(.leading, 36)
                        }
                    }
                }
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }

            // ── Action buttons ───────────────────────────────────────────────
            HStack(spacing: 8) {
                // Thêm app đang active
                Button {
                    if let added = manager.addFrontmostApp() {
                        errorMessage = nil
                        _ = added
                    } else {
                        errorMessage = "exclude.errorFrontmost"
                    }
                } label: {
                    Label("exclude.addFrontmost", systemImage: "plus.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("exclude.helpFrontmost")

                // Thêm thủ công
                Button {
                    manualBundleID = ""
                    manualAppName  = ""
                    errorMessage   = nil
                    showAddSheet   = true
                } label: {
                    Label("exclude.addManual", systemImage: "keyboard")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                // Quick-add preset password managers
                Menu {
                    presetMenu
                } label: {
                    Label("exclude.passwordManagers", systemImage: "key.fill")
                        .font(.caption)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .controlSize(.small)
            }

            // Error message
            if let err = errorMessage {
                Text(err)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(12)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(10)
        // ── Sheet: nhập bundle ID thủ công ──────────────────────────────────
        .sheet(isPresented: $showAddSheet) {
            AddManualSheet(
                bundleID  : $manualBundleID,
                appName   : $manualAppName,
                onConfirm : {
                    let trimID   = manualBundleID.trimmingCharacters(in: .whitespaces)
                    let trimName = manualAppName.trimmingCharacters(in: .whitespaces)
                    guard !trimID.isEmpty else {
                        errorMessage = String(localized: "exclude.errorEmptyBundle")
                        return
                    }
                    let app = ExcludedApp(bundleID: trimID, name: trimName.isEmpty ? trimID : trimName)
                    if !manager.add(app) {
                        errorMessage = String(localized: "exclude.errorDuplicate")
                    } else {
                        errorMessage = nil
                    }
                    showAddSheet = false
                },
                onCancel: { showAddSheet = false }
            )
        }
    }

    // MARK: - Preset menu cho password managers

    @ViewBuilder
    private var presetMenu: some View {
        let allPresets = ExcludeManager.defaultPasswordManagers
        let notYetAdded = allPresets.filter { preset in
            !manager.excludedApps.contains { $0.bundleID == preset.bundleID }
        }

        if notYetAdded.isEmpty {
            Text("exclude.allAdded").foregroundColor(.secondary)
        } else {
            ForEach(notYetAdded) { app in
                Button(app.name) {
                    manager.add(app)
                }
            }
            Divider()
            Button("exclude.addAll") {
                notYetAdded.forEach { manager.add($0) }
            }
        }
    }
}

// MARK: - Row hiển thị một excluded app

private struct ExcludeRow: View {
    let app     : ExcludedApp
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            // App icon
            Group {
                if let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                } else {
                    Image(systemName: "app.dashed")
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 22, height: 22)

            // Name + bundle ID
            VStack(alignment: .leading, spacing: 1) {
                Text(app.name)
                    .font(.system(size: 13))
                    .lineLimit(1)
                Text(app.bundleID)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Delete button (hiện khi hover)
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red.opacity(isHovered ? 1 : 0))
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}

// MARK: - Sheet nhập bundle ID thủ công

private struct AddManualSheet: View {
    @Binding var bundleID : String
    @Binding var appName  : String
    let onConfirm : () -> Void
    let onCancel  : () -> Void

    @FocusState private var focusBundleID: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("exclude.manualTitle")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Text("exclude.bundleID")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("exclude.bundleIDPlaceholder", text: $bundleID)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .focused($focusBundleID)
                Text("exclude.bundleIDHint")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("exclude.displayName")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("exclude.placeholderName", text: $appName)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Spacer()
                Button("clear.cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("exclude.addButton", action: onConfirm)
                    .keyboardShortcut(.defaultAction)
                    .disabled(bundleID.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 340)
        .onAppear { focusBundleID = true }
    }
}

#Preview {
    ExcludeSettingsSection()
        .frame(width: 340)
        .padding()
}
