import SwiftUI
import HotKey
import ServiceManagement
import Combine

struct SettingsView: View {
    // MARK: - Settings State
    @Binding var showSettings: Bool

    @AppStorage("maxItems")       var maxItems: Int    = 100
    @AppStorage("launchAtLogin")  var launchAtLogin: Bool = false
    @AppStorage("saveImages")     var saveImages: Bool = true
    @AppStorage("saveFilePaths")  var saveFilePaths: Bool = true
    @AppStorage("retentionDays")  var retentionDays: Int = 0  // 0 = mãi mãi
    @AppStorage("appLanguage")    var appLanguage: String = Locale.current.language.languageCode?.identifier == "vi" ? "vi" : "en"

    @State private var isRecordingShortcut = false
    @State private var shortcutDisplay = ShortcutManager.shared.shortcutDisplayString
    @State private var showRestartAlert = false

    @AppStorage("autoPasteEnabled") var autoPasteEnabled: Bool = false
    @State private var isAccessibilityGranted = AutoPasteManager.shared.isAccessibilityGranted
    private let accessibilityCheckTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ──  ScrollView

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Lịch sử ─────────────────
                    sectionHeader(String(localized: "settings.section.history"))

                    settingRow {
                        Text("settings.maxItems")
                            .font(.system(size: 13))
                        Spacer()
                        Picker("", selection: $maxItems) {
                            Text("100").tag(100)
                            Text("200").tag(200)
                            Text("500").tag(500)
                            Text("1000").tag(1000)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 80)
                        .onChange(of: maxItems) { _, newValue in
                            _ = try? DatabaseManager.shared.trimIfNeeded(
                                maxItems: newValue
                            )
                        }
                    }

                    Divider().padding(.leading, 14)

                    settingRow {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.retention")
                                .font(.system(size: 13))
                            Text("settings.retention.description")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Picker("", selection: $retentionDays) {
                            Text("settings.retention.1day").tag(1)
                            Text("settings.retention.7days").tag(7)
                            Text("settings.retention.30days").tag(30)
                            Text("settings.retention.forever").tag(0)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 100)
                        .onChange(of: retentionDays) { _, newValue in
                            // Chạy cleanup ngay khi user thay đổi setting
                            _ = try? DatabaseManager.shared.deleteItemsOlderThan(days: newValue)
                        }
                    }

                    Divider().padding(.leading, 14)

                    settingRow {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.saveImages")
                                .font(.system(size: 13))
                            Text("settings.saveImages.description")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Toggle("", isOn: $saveImages)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }

                    Divider().padding(.leading, 14)

                    settingRow {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.saveFilePaths")
                                .font(.system(size: 13))
                            Text("settings.saveFilePaths.description")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Toggle("", isOn: $saveFilePaths)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                    
                    // ── Loại trừ ─────────────────
                    sectionHeader(String(localized: "exclude.title"))
                    
                    ExcludeSettingsSection()
                        .padding(.horizontal, 14)
                        .padding(.bottom, 8)

                    // ── Hệ thống ─────────────────
                    sectionHeader(String(localized: "settings.section.system"))

                    settingRow {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.launchAtLogin")
                                .font(.system(size: 13))
                            Text("settings.launchAtLogin.description")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Toggle("", isOn: $launchAtLogin)
                            .toggleStyle(.switch)
                            .labelsHidden()
                            .onChange(of: launchAtLogin) { _, enabled in
                                if enabled {
                                    AppDelegate.shared.enableLoginItem()
                                } else {
                                    AppDelegate.shared.disableLoginItem()
                                }
                            }
                    }
                    
                    Divider().padding(.leading, 14)
                    
                    settingRow {
                        Text("settings.language")
                            .font(.system(size: 13))
                        Spacer()
                        Picker("", selection: $appLanguage) {
                            Text("settings.language.vi").tag("vi")
                            Text("settings.language.en").tag("en")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                        .onChange(of: appLanguage) { _, newValue in
                            UserDefaults.standard.set([newValue], forKey: "AppleLanguages")
                            showRestartAlert = true
                        }
                    }

                    // ── Phím tắt ─────────────────
                    sectionHeader(String(localized: "settings.section.shortcut"))

                    settingRow {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.shortcut.open")
                                .font(.system(size: 13))
                            Text("settings.shortcut.tapToChange")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        ShortcutRecorderButton(
                            displayString: $shortcutDisplay,
                            isRecording: $isRecordingShortcut
                        )
                    }

                    // ── Auto Paste ─────────────────
                    sectionHeader(String(localized: "settings.section.autopaste"))

                    settingRow {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.autoPaste")
                                .font(.system(size: 13))
                            Text("settings.autoPaste.description")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Toggle("", isOn: $autoPasteEnabled)
                            .toggleStyle(.switch)
                            .labelsHidden()
                            .onChange(of: autoPasteEnabled) { _, enabled in
                                if enabled && !AutoPasteManager.shared.isAccessibilityGranted {
                                    AutoPasteManager.shared.requestAccessibilityPermission()
                                }
                            }
                    }

                    Divider().padding(.leading, 14)

                    // Status indicator
                    settingRow {
                        HStack {
                            Image(systemName: isAccessibilityGranted ? "checkmark.shield.fill" : "xmark.shield.fill")
                                .foregroundStyle(isAccessibilityGranted ? .green : .red)
                            Text(isAccessibilityGranted ? "settings.autoPaste.accessibilityGranted" : "settings.autoPaste.accessibilityDenied")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if !isAccessibilityGranted {
                            Button("settings.autoPaste.openSettings") {
                                AutoPasteManager.shared.openAccessibilityPreferences()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .onAppear {
                        isAccessibilityGranted = AutoPasteManager.shared.isAccessibilityGranted
                    }
                    .onReceive(accessibilityCheckTimer) { _ in
                        isAccessibilityGranted = AutoPasteManager.shared.isAccessibilityGranted
                    }

                    Divider().padding(.leading, 14)

                    settingRow {
                        Text("settings.autoPaste.footnote")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // ── Dữ liệu ──────────────────
                    sectionHeader(String(localized: "settings.section.data"))

                    settingRow {
                        Text("settings.clearAllHistory")
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                        Spacer()
                        Button("clear.all") {
                            _ = try? DatabaseManager.shared.clearAll(keepPinned: false)
                        }
                        .foregroundStyle(.red)
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .alert("settings.language.restartRequired",
               isPresented: $showRestartAlert) {
            Button("settings.language.restart") {
                NSApplication.shared.terminate(nil)
            }
            Button("clear.cancel", role: .cancel) {}
        } message: {
            Text("settings.language.restartMessage")
        }
    }

}
