import SwiftUI
import Combine

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var monitor: ClipboardMonitor

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    @State private var searchText = ""
    @State private var activeFilter: ClipboardFilter = .all
    @State private var showClearConfirm = false
    @State private var showSettings = false
    @State private var showOnboarding = false
    @State private var searchDebounceCancellable: AnyCancellable?

    // ObservableObject — thay đổi trigger re-render toàn bộ view tree
    @StateObject private var selection = SelectionState()

    // NSEvent monitor — không phải ObservableObject, không cần @StateObject
    private let keyboard = KeyboardMonitor()

    // MARK: - Computed items

    private var displayedItems: [ClipboardItem] {
        var result = monitor.items
        switch activeFilter {
        case .all:      break
        case .text:     result = result.filter { $0.contentType == .text }
        case .url:      result = result.filter { $0.contentType == .url }
        case .image:    result = result.filter { $0.contentType == .image }
        case .filePath: result = result.filter { $0.contentType == .filePath }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    private var pinnedItems:   [ClipboardItem] { displayedItems.filter {  $0.isPinned } }
    private var unpinnedItems: [ClipboardItem] { displayedItems.filter { !$0.isPinned } }
    private var flatItems:     [ClipboardItem] { pinnedItems + unpinnedItems }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            Divider()

            if showSettings {
                SettingsView(showSettings: $showSettings)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                if showOnboarding {
                    onboardingView
                        .padding(.horizontal, 14)
                        .padding(.top, 10)
                }

                FilterChipBar(selected: $activeFilter)
                    .onChange(of: activeFilter) { _, _ in
                        searchText = ""
                        selection.index = 0
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                Divider()

                if displayedItems.isEmpty {
                    emptyStateView
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    itemListView
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Divider()
                footerView
            }
        }
        .frame(minWidth: 360, idealWidth: 420, maxWidth: 480, minHeight: 500, idealHeight: 560, maxHeight: 680, alignment: .top)
        .onAppear {
            // selection là reference type — closure luôn đọc giá trị mới nhất
            keyboard.onKeyDown = { [weak selection] event in
                guard let sel = selection else { return false }
                return Self.handleKey(event, selection: sel,
                                      flatItems: self.flatItems,
                                      searchText: self.searchText,
                                      onSearchClear: {
                                          self.searchText = ""
                                          self.handleSearchQueryChange("")
                                      },
                                      onEnter: { item in
                                          self.monitor.copyToPasteboard(item)
                                          NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                                          let previousApp = AppDelegate.shared.previousFrontmostApp
                                          AppDelegate.shared.closePopover()
                                          AutoPasteManager.shared.performAutoPaste(previousApp: previousApp)
                                      },
                                      showSettings: self.showSettings)
            }
            keyboard.start()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                selection.mode = .search
                selection.index = 0
            }

            if !hasSeenOnboarding {
                showOnboarding = true
            }
        }
        .onDisappear {
            keyboard.stop()
            searchDebounceCancellable?.cancel()
        }
    }

    private func handleSearchQueryChange(_ query: String) {
        selection.index = 0
        searchDebounceCancellable?.cancel()

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            monitor.search(query: "")
            return
        }

        searchDebounceCancellable = Just(trimmedQuery)
            .delay(for: .milliseconds(220), scheduler: RunLoop.main)
            .sink { [weak monitor] debouncedQuery in
                monitor?.search(query: debouncedQuery)
            }
    }

    // MARK: - Key Handler (static — tránh capture self)

    private static func handleKey(
        _ event: NSEvent,
        selection: SelectionState,
        flatItems: [ClipboardItem],
        searchText: String,
        onSearchClear: @escaping () -> Void,
        onEnter: @escaping (ClipboardItem) -> Void,
        showSettings: Bool
    ) -> Bool {
        guard !showSettings else { return false }

        switch event.keyCode {

            case 125: // ↓
                DispatchQueue.main.async {
                    if selection.mode == .search {
                        selection.mode = .list
                        selection.index = 0
                    } else {
                        selection.index = min(selection.index + 1, flatItems.count - 1)
                    }
                    // ← thêm: cập nhật preview nếu đang mở
                    if selection.isPreviewOpen, flatItems.indices.contains(selection.index) {
                        QuickLookPanel.shared.show(item: flatItems[selection.index])
                    }
                }
                return true

            case 126: // ↑
                DispatchQueue.main.async {
                    if selection.mode == .list && selection.index == 0 {
                        selection.mode = .search
                    } else if selection.mode == .list {
                        selection.index = max(selection.index - 1, 0)
                    }
                    // ← thêm: cập nhật preview nếu đang mở
                    if selection.isPreviewOpen, flatItems.indices.contains(selection.index) {
                        QuickLookPanel.shared.show(item: flatItems[selection.index])
                    }
                }
                return true

            case 36, 76: // Return / numpad Enter
                guard selection.mode == .list,
                      flatItems.indices.contains(selection.index) else { return false }
                let item = flatItems[selection.index]
                DispatchQueue.main.async {
                    onEnter(item)
                }
                return true

            case 53: // Escape
                DispatchQueue.main.async {
                    // ← thêm: đóng preview trước
                    if QuickLookPanel.shared.isVisible {
                        QuickLookPanel.shared.close()
                        selection.isPreviewOpen = false
                        return
                    }
                    if !searchText.isEmpty {
                        onSearchClear()
                        selection.index = 0
                        selection.mode = .search
                    } else {
                        AppDelegate.shared.closePopover()
                    }
                }
                return true
            case 49: // Space
                guard selection.mode == .list,
                      flatItems.indices.contains(selection.index) else { return false }
                let item = flatItems[selection.index]
                DispatchQueue.main.async {
                    if QuickLookPanel.shared.isVisible {
                        QuickLookPanel.shared.close()
                        selection.isPreviewOpen = false
                    } else {
                        QuickLookPanel.shared.show(item: item)
                        selection.isPreviewOpen = true
                    }
                }
                return true

            default:
                if selection.mode == .list,
                   !(event.characters ?? "").isEmpty,
                   event.modifierFlags.intersection([.command, .control, .option]).isEmpty {
                    DispatchQueue.main.async { selection.mode = .search }
                }
            return false
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 10) {
            HStack {
                if showSettings {
                    HStack {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { showSettings = false }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.accent)
                                .frame(width: 26, height: 26)
                                .background(Color(NSColor.controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        Text("nav.settings").font(.system(size: 14, weight: .semibold))
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.accent)
                        Text("app.title").font(.system(size: 14, weight: .semibold))
                    }
                    Spacer()
                    IconButton(systemName: "gearshape") {
                        withAnimation(.easeInOut(duration: 0.2)) { showSettings = true }
                    }
                }
            }

            if !showSettings {
                HStack(spacing: 7) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)

                    TextField("search.placeholder", text: $searchText)
                        .font(.system(size: 13))
                        .textFieldStyle(.plain)
                        .onChange(of: searchText) { _, query in
                            handleSearchQueryChange(query)
                        }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            handleSearchQueryChange("")
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                )
            }
        }
        .padding(14)
    }

    private var onboardingView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 3) {
                    Text("onboarding.title")
                        .font(.system(size: 12, weight: .semibold))
                    Text("onboarding.subtitle")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showOnboarding = false
                        hasSeenOnboarding = true
                    }
                } label: {
                    Text("onboarding.dismiss")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
            )
        }
    }

    // MARK: - Item List

    private var itemListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    if !pinnedItems.isEmpty {
                        sectionLabel(String(localized: "section.pinned"))
                        ForEach(Array(pinnedItems.enumerated()), id: \.element.id) { offset, item in
                            itemRow(item, flatIndex: offset)
                                .id(offset)
                            Divider().padding(.leading, 52)
                        }
                    }

                    if !unpinnedItems.isEmpty {
                        sectionLabel(String(localized: "section.recent"))
                        ForEach(Array(unpinnedItems.enumerated()), id: \.element.id) { offset, item in
                            let idx = pinnedItems.count + offset
                            itemRow(item, flatIndex: idx)
                                .id(idx)
                            Divider().padding(.leading, 52)
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .onChange(of: selection.index) { _, newIdx in
                withAnimation(.easeInOut(duration: 0.15)) {
                    proxy.scrollTo(newIdx, anchor: .center)
                }
            }
        }
    }

    private func itemRow(_ item: ClipboardItem, flatIndex: Int) -> some View {
        ClipboardItemRow(
            item: item,
            flatIndex: flatIndex,
            selection: selection,
            onCopy: {
                monitor.copyToPasteboard(item)
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                let previousApp = AppDelegate.shared.previousFrontmostApp
                AppDelegate.shared.closePopover()
                AutoPasteManager.shared.performAutoPaste(previousApp: previousApp)
            },
            onPin: {
                withAnimation(.easeInOut(duration: 0.2)) { monitor.togglePin(item) }
            },
            onDelete: {
                withAnimation(.easeOut(duration: 0.2)) {
                    monitor.deleteItem(item)
                    if selection.index >= flatItems.count - 1 {
                        selection.index = max(0, flatItems.count - 2)
                    }
                }
            }
        )
        .contextMenu {
            ItemContextMenu(item: item).environmentObject(monitor)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: searchText.isEmpty ? "clipboard" : "magnifyingglass")
                .font(.system(size: 30))
                .foregroundStyle(.quaternary)

            VStack(spacing: 4) {
                Text(searchText.isEmpty ? String(localized: ("empty.noItems")) : String(localized: ("empty.search")))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(searchText.isEmpty ? String(localized: ("empty.noItemsTip")) : String(localized: ("empty.searchHint")))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if searchText.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    tipChip(String(localized: ("empty.spaceTip")))
                    tipChip(String(localized: ("empty.pinTip")))
                    tipChip(String(localized: ("empty.shortcutTip")))
                }
                .padding(.top, 4)
            }
        }
        .padding(.top, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func tipChip(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkle")
                .font(.system(size: 10))
                .foregroundStyle(Color.accentColor)
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            Text("\(monitor.items.count) items")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
            Spacer()
            Button { showClearConfirm = true } label: {
                HStack(spacing: 4) {
                    Image(systemName: "trash").font(.system(size: 11))
                    Text("clear.all").font(.system(size: 12))
                }
                .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .confirmationDialog("clear.title",
                                isPresented: $showClearConfirm,
                                titleVisibility: .visible) {
                Button("clear.keepPinned", role: .destructive) {
                    withAnimation { monitor.clearAll() }
                }
                Button("clear.all", role: .destructive) {
                    withAnimation {
                        monitor.items.removeAll()
                        try? DatabaseManager.shared.clearAll(keepPinned: false)
                    }
                }
                Button("clear.cancel", role: .cancel) {}
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
