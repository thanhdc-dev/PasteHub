# PasteHub

A lightweight macOS menu bar app that keeps your clipboard history accessible — built with SwiftUI, GRDB (SQLite), and Sparkle.

## Features

✨ **Auto-save clipboard history** — Every text, URL, image (PNG), and file path you copy is automatically saved

🔍 **Quick search** — Find any previously copied item in seconds with full‑text search

📌 **Pin favorites** — Keep frequently used items pinned at the top; they survive history clearing

🎨 **Beautiful UI** — Clean, macOS‑native design with dark/light mode support

⚡ **Fast & lightweight** — Uses minimal CPU and memory; background polling at 0.5 s

🔒 **Private & offline** — All data stored locally in `~/Library/Application Support/PasteHub`, zero cloud sync

🔄 **Auto‑updates via Sparkle** — Seamless background updates with user‑friendly notifications

🧹 **Auto‑clear** — Old (unpinned) items are automatically removed after a configurable retention period (default: never)

📁 **Source app tracking** — Each item stores the app it was copied from (name & bundle ID)

🚫 **Exclude apps** — Prevent copying from specific applications (e.g. password managers)

⚙️ **Customizable settings** — Choose whether to save images and file paths, set retention days, launch at login, and more

⌨️ **Global shortcut** — Default `⌘⌥V` to open/close clipboard history

🚀 **Auto-paste (Opt-in)** — Optionally paste automatically (`⌘V`) into the active app immediately after selecting an item. Requires Accessibility permission only if enabled.

❌ **No Accessibility API by default** — PasteHub does **not** require Accessibility permissions by default. If Auto-paste is off, it simply copies the item to your clipboard for manual pasting with `⌘V`.

## Architecture

PasteHub follows the **MVVM (Model-View-ViewModel)** pattern with a **feature-based** folder structure.

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

### Data Flow

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

### Key Dependencies

| Library | Purpose |
|---------|---------|
| [GRDB](https://github.com/groue/GRDB.swift) | SQLite database with type-safe queries & migrations |
| [Sparkle](https://sparkle-project.org) | Auto-update framework |
| [HotKey](https://github.com/soffes/HotKey) | Global keyboard shortcut registration |

## How to Use

1. Install PasteHub from releases or build from source
2. Grant clipboard access permission when prompted (macOS will ask automatically).
3. Copy anything as usual — PasteHub saves it automatically
4. Press `⌘⌥V` to open clipboard history
5. Click any item (or press `Enter`) to copy it to your clipboard. If **Auto Paste** is enabled in Settings, the item is automatically pasted into the active application; otherwise, you paste it manually using `⌘V`.
6. Navigate with `↑`/`↓`, press `Space` for QuickLook preview, `Delete` to remove
7. Pin important items by clicking the pin icon or using the context menu

## ⚠️ Opening PasteHub on macOS (Unsigned App Notice)
 
PasteHub is **open-source and free**, distributed outside the Mac App Store without a paid Apple Developer certificate. Because of this, macOS Gatekeeper will show a warning the first time you open it — this is expected and does **not** mean the app is unsafe. You can review the full source code in this repository yourself.
 
You may see one of these messages:
- *"PasteHub.app" is damaged and can't be opened. You should move it to the Trash.*
- *"PasteHub.app" cannot be opened because the developer cannot be verified.*
**To open PasteHub, choose one of the methods below:**
 
### Method 1 — Right-click to open (recommended, no Terminal needed)
1. Locate `PasteHub.app` in Finder (usually in `/Applications`)
2. **Right-click** (or Control-click) the app icon → select **Open**
3. A dialog will appear — click **Open** again to confirm
4. You only need to do this once; future launches work normally (double-click)

### Method 2 — Allow via System Settings
1. Try opening the app once (it will be blocked)
2. Go to **System Settings → Privacy & Security**
3. Scroll down to find *"PasteHub.app" was blocked...*
4. Click **Open Anyway**
> **Why isn't PasteHub notarized?** Apple requires a paid Developer Program membership ($99/year) to notarize apps and avoid this warning. As a free, community-driven open-source project, we currently don't pay for this. If you'd like to support removing this friction for all users, contributions or sponsorship are welcome — see [Contributing](#contributing) *(if you add a CONTRIBUTING.md, link it here)*.

### Method 3 — Remove the quarantine flag via Terminal
If Method 1 still shows "damaged" (this happens due to how macOS flags files downloaded from the internet), run:
 
```bash
xattr -cr /Applications/PasteHub.app
```
 
Then open the app normally by double-clicking.

---

## Requirements

- macOS 13 Ventura or later (uses `SMAppService` for login item)
- ~20 MB disk space (more with many images)

## Settings

Accessible via the gear icon in the popover header. Options:

| Setting | Description | Default |
|---------|-------------|---------|
| **Retention** | Number of days to keep unpinned items (0 = forever) | 0 |
| **Save images** | Whether to store copied images | Enabled |
| **Save file paths** | Whether to store copied file URLs | Disabled |
| **Launch at login** | Start PasteHub automatically on login | Disabled |
| **Auto Paste** | Automatically simulate ⌘V after selecting an item (requires Accessibility permission) | Disabled |
| **Excluded apps** | Bundle IDs/short names to ignore | – |

## Privacy

PasteHub respects your privacy:
- All clipboard data is stored **locally** on your device
- No tracking, no analytics, no cloud upload
- No account or login required
- Uninstall via Finder → hold `⌥` while dragging to Trash — all data is deleted

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘⌥V` | Open/close clipboard history |
| `⌘,` | Open settings |
| `↑` / `↓` | Navigate items |
| `Enter` | Copy selected item to clipboard (and automatically paste if Auto Paste is enabled) |
| `Space` | QuickLook preview (image, text) |
| `Delete` | Remove item from history |
| `Esc` | Clear search → close popover |
| `⌘Q` | Quit PasteHub (from menu bar icon) |

## Technologies

- **SwiftUI** for the entire user interface
- **GRDB** for SQLite database with migrations and full‑text search
- **Sparkle** for automatic software updates
- **NSEvent** monitors for global shortcut and local keyboard handling
- **QuickLook** for image/text preview

Enjoy PasteHub! 📋
