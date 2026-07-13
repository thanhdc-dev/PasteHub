# Installation Guide & Gatekeeper Troubleshooting

[🇻🇳 Bản tiếng Việt](INSTALLATION.md)

This guide explains how to install PasteHub and bypass macOS gatekeeper warnings for unsigned applications.

## Requirements

Before installing, ensure your Mac meets the following requirements:
- **macOS 13 Ventura or later** (required for `SMAppService` launch-at-login APIs).
- **~20 MB of disk space** (more depending on the size and amount of image history stored).

---

## ⚠️ Opening PasteHub on macOS (Unsigned App Notice)

PasteHub is **free and open-source**, built and distributed without a paid Apple Developer certificate. Because of this, macOS Gatekeeper will block the app at first launch and show a warning. This is expected behavior and does **not** mean the app is unsafe. You can inspect the full source code in this repository.

You may encounter one of these warnings:
- *"PasteHub.app" is damaged and can't be opened. You should move it to the Trash.*
- *"PasteHub.app" cannot be opened because the developer cannot be verified.*

To open PasteHub safely, use one of the three methods below:

### Method 1: Right-Click to Open (Recommended)
This is the simplest way and does not require using the Terminal:
1. Locate `PasteHub.app` in Finder (usually in your `/Applications` folder).
2. **Right-click** (or Control-click) the app icon and select **Open**.
3. A confirmation dialog will appear. Click **Open** to confirm.
4. You only need to do this once. Future launches will open normally by double-clicking.

### Method 2: Allow via System Settings
If double-clicking blocked the app, you can allow it in your system settings:
1. Try opening PasteHub once so macOS registers the blocked attempt.
2. Open **System Settings** → **Privacy & Security**.
3. Scroll down to the *Security* section to find the message: *"PasteHub.app" was blocked from use because it is not from an identified developer*.
4. Click **Open Anyway**.

### Method 3: Remove the Quarantine Flag via Terminal
If macOS claims the app is "damaged" and won't let you use the options above, it is likely because the file has a quarantine flag attached when downloaded from a web browser. You can clear this flag:
1. Open the **Terminal** app.
2. Run the following command:
   ```bash
   xattr -cr /Applications/PasteHub.app
   ```
3. Open PasteHub normally by double-clicking it.

---

## Frequently Asked Questions

### Why isn't PasteHub notarized/signed?
Apple requires developers to pay **$99/year** for their Developer Program to sign and notarize apps, preventing these warnings. Since PasteHub is a free, community-driven open-source utility, we do not pay for this subscription.

If you would like to help fund notarization or contribute to the project, feel free to submit a Pull Request or reach out via GitHub.
