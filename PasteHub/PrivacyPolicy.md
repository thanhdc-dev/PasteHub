# Privacy Policy for PasteHub

**Last Updated:** July 2026

## Data Collected

PasteHub collects and stores the following data **locally** on your Mac:

- **Clipboard content** – Text, URLs, file paths (if enabled in Settings) and images (if enabled in Settings)
- **Source app information** – Bundle identifier and localized name of the app from which each clipboard item was copied
- **Usage preferences** – Retention period, enabled/disabled features (save images, save file paths), excluded app list, and launch‑at‑login setting

Images are saved as PNG files in `~/Library/Application Support/PasteHub/images/`.

## Data Storage

- All data is stored **exclusively** on your device in `~/Library/Application Support/PasteHub/`
- Database: SQLite via GRDB at `~/Library/Application Support/PasteHub/pastehub.sqlite`
- **Zero cloud sync** – No data is transmitted to any server
- **No analytics, no tracking, no account required**

## Permissions

PasteHub requests the following permissions:

- **Clipboard Access** – Required to monitor and copy clipboard content. The app polls the clipboard every 0.5 seconds.
- **User Selected Files** – Required to preview file paths and images (QuickLook). No full disk access is needed.
- **Accessibility** – **Not required.** PasteHub does **not** use the Accessibility API. It works by copying the selected item to your clipboard; you still paste manually with `⌘V`.

## Data Retention and Deletion

- Unpinned items older than the configured retention period (default: never, 0 days) are automatically deleted.
- You can delete individual items at any time via the popover.
- Use “Clear All” to remove all unpinned items (pinned items are kept).
- Uninstalling PasteHub (via Finder) removes all local data – simply drag the app to Trash while holding `⌥`.

## Excluded Apps

You can add applications (by bundle identifier) to an exclusion list. Content copied from excluded apps will be ignored.

## Automatic Updates

PasteHub uses **Sparkle** for automatic updates. Update checks download the latest version from the project’s release feed. No personal information is sent during this process.

## Contact

For questions about this privacy policy, contact: **thanhdc-dev@gmail.com**
