# PasteHub Architecture

This document provides a detailed overview of the PasteHub codebase structure, architecture pattern, data flow, and dependencies.

## Architecture Pattern

PasteHub follows the **MVVM (Model-View-ViewModel)** pattern with a **feature-based** folder structure to keep UI presentation cleanly separated from data management and business logic.

- **Models**: Pure value types defining data entities.
- **Views**: SwiftUI views rendering the user interface.
- **ViewModels**: View state containers bridging Services to Views.
- **Services**: Singleton managers handling side effects (database, clipboard monitoring, shortcuts, app updates).

---

## Folder Structure

```
PasteHub/
├── PasteHubApp.swift                 # @main App entry point (SwiftUI App lifecycle)
│
├── App/                              # Application layer — app delegate & lifecycle
│   ├── AppDelegate.swift             # NSApplicationDelegate: coordinates startup & shutdown
│   ├── MenuBarManager.swift          # Menu bar status item, popover, and context menu
│   └── AppLifecycle.swift            # Login item (SMAppService) and auto-clear timer
│
├── Models/                           # Data models — pure value types, no business logic
│   ├── ClipboardItem.swift           # Core model: clipboard item + GRDB persistence conformance
│   ├── ClipboardContentType.swift    # Enum: text | url | image | filePath
│   └── ExcludedApp.swift             # Model for apps excluded from clipboard monitoring
│
├── Services/                         # Business logic & side effects — singleton managers
│   ├── AutoPasteManager.swift        # Singleton: controls simulated Cmd+V auto-paste & accessibility permissions
│   ├── ClipboardMonitor.swift        # ObservableObject: polls NSPasteboard, detects changes,
│   │                                 #   coordinates save/load/search with DatabaseManager
│   ├── DatabaseManager.swift         # SQLite via GRDB: migrations, CRUD, search, trim/cleanup
│   ├── ImageStorageManager.swift     # File system image storage: save, load, delete, orphan cleanup
│   ├── ShortcutManager.swift         # Global keyboard shortcut via HotKey library
│   ├── ExcludeManager.swift          # Manage excluded apps list, seed default password managers
│   └── SparkleUpdater.swift          # Sparkle auto-update controller wrapper
│
├── ViewModels/                       # View state — bridges Services → Views
│   └── SelectionState.swift          # ObservableObject: selected index, focus mode (search/list),
│                                     #   QuickLook preview state
│
├── Views/                            # SwiftUI views — presentation layer
│   ├── ContentView.swift             # Main content: header, search bar, filter bar, item list, footer
│   ├── ClipboardItemRow.swift        # Single clipboard item row + ContentTypeIcon + ImageThumbnail
│   ├── FilterChip.swift              # Filter chip bar + individual filter chip (All/Text/URL/Image/File)
│   ├── ItemContextMenu.swift         # Right-click context menu: copy, pin/unpin, delete
│   ├── QuickLookPanel.swift          # NSPanel wrapper for Quick Look preview popup
│   ├── QuickLookView.swift           # Quick Look content: text, URL, image, file path preview
│   │
│   ├── Components/                   # Reusable UI components
│   │   ├── IconButton.swift          # Small icon button used in item action bar
│   │   ├── KeyboardMonitor.swift     # Local NSEvent keyDown monitor (within popover)
│   │   └── SourceAppBadge.swift      # App icon + name badge showing copy source
│   │
│   └── Settings/                     # Settings page
│       ├── SettingsView.swift        # Full settings: history limits, retention, excludes, system
│       ├── ExcludeSettingsSection.swift  # Excluded apps management UI
│       └── ShortcutRecorderButton.swift  # Button to record new global shortcut
│
├── Extensions/                       # Swift extensions & design tokens
│   ├── Color+DesignTokens.swift      # Custom accent colors & content-type color palette
│   └── View+Helpers.swift            # View extension: sectionHeader, settingRow layout helpers
│
└── Resources/                        # Static resources
    ├── Assets.xcassets/              # App icon, accent color
    ├── Info.plist                    # App configuration
    ├── InfoPlist.xcstrings           # Localized Info.plist strings
    └── Localizable.xcstrings         # Localized UI strings (vi + en)
```

---

## Data Flow

The following diagram illustrates how clipboard events flow through PasteHub:

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────┐
│ NSPasteboard │────▶│ ClipboardMonitor │────▶│   SQLite    │
│  (system)    │poll │  (ObservableObj) │ CRUD│   (GRDB)    │
└─────────────┘     └────────┬─────────┘     └─────────────┘
                             │ @Published
                             ▼
                    ┌─────────────────┐
                    │   ContentView   │
                    │ @EnvironmentObj │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
      ClipboardItemRow  FilterChipBar   SettingsView
```

1. **ClipboardMonitor** polls the system `NSPasteboard` every 0.5 seconds in the background.
2. When a new item is detected, it validates it against excluded apps. If valid, the item is persisted in the SQLite database via **DatabaseManager**.
3. **ClipboardMonitor** updates its `@Published` state, which triggers a UI refresh in **ContentView**.
4. User interactions (e.g. searching, filtering, pinning, or deleting) go from the **Views** back to **ClipboardMonitor** to update database and state.

---

## Technologies & Dependencies

PasteHub is built using standard Apple APIs alongside modern Swift libraries:

- **SwiftUI** - For the entire user interface and settings panel.
- **SQLite (via GRDB)** - For efficient local data persistence, schema migrations, and full-text search.
- **Sparkle** - For secure, automated software updates.
- **HotKey** - For registering and managing the global keyboard shortcut.
- **NSEvent** - Monitors local keydowns to enable keyboard navigation inside the status bar popover.
- **QuickLook** - Renders native previews for text, images, and files in a popup panel.

### Library Details

| Library | Version / Source | Purpose |
|---------|------------------|---------|
| [GRDB.swift](https://github.com/groue/GRDB.swift) | Swift Package Manager | Type-safe database queries and migrations |
| [Sparkle](https://sparkle-project.org) | Swift Package Manager | Secure background software updates |
| [HotKey](https://github.com/soffes/HotKey) | Swift Package Manager | Global keyboard shortcut recording and monitoring |
