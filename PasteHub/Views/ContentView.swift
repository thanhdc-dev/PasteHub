import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var monitor: ClipboardMonitor

    @State private var searchText = ""
    @State private var activeFilter: ClipboardFilter = .all
    @State private var showClearConfirm = false
    @State private var showSettings = false

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
                FilterChipBar(selected: $activeFilter)
                    .onChange(of: activeFilter) { _, _ in
                        searchText = ""
                        selection.index = 0
                    }
                Divider()

                if displayedItems.isEmpty {
                    emptyStateView
                } else {
                    itemListView
                }

                Divider()
                footerView
            }
        }
        .frame(width: 450, height: 500, alignment: .top)
        .onAppear {
            // selection là reference type — closure luôn đọc giá trị mới nhất
            keyboard.onKeyDown = { [weak selection] event in
                guard let sel = selection else { return false }
                return Self.handleKey(event, selection: sel,
                                      flatItems: self.flatItems,
                                      searchText: self.searchText,
                                      onSearchClear: {
                                          self.searchText = ""
                                          self.monitor.search(query: "")
                                      },
                                      onEnter: { item in
                                          self.monitor.copyToPasteboard(item)
                                          NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                                          AppDelegate.shared.closePopover()
                                      },
                                      showSettings: self.showSettings)
            }
            keyboard.start()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                selection.mode = .search
                selection.index = 0
            }
        }
        .onDisappear { keyboard.stop() }
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
                            monitor.search(query: query)
                            selection.index = 0
                        }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            monitor.search(query: "")
                            selection.index = 0
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
                AppDelegate.shared.closePopover()
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
        VStack(spacing: 10) {
            Image(systemName: searchText.isEmpty ? "clipboard" : "magnifyingglass")
                .font(.system(size: 28))
                .foregroundStyle(.quaternary)
            Text(searchText.isEmpty ? "empty.default" : "empty.search")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
            if !searchText.isEmpty {
                Text("empty.search.hint")
                    .font(.system(size: 12))
                    .foregroundStyle(.quaternary)
            }
        }
        .padding(.top, 60)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
