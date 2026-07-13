# Screenshot and Demo GIF Creation Guide

This guide details how to create clean, high-quality, and premium screenshots/GIFs to showcase PasteHub in the `README.md`.

## 1. Capturing Premium Screenshots

To make the app look premium, follow these best practices when taking screenshots:

- **Clean Desktop**: Hide desktop icons and use a clean, modern wallpaper (abstract wallpapers work best).
- **Use macOS Window Capture**:
  1. Press `⌘ + Shift + 4`, then press the `Spacebar`. Your cursor will turn into a camera icon.
  2. Click on the PasteHub popover window. This captures the window perfectly with its native drop shadow and transparent borders on a clean white/transparent background.
- **Light & Dark Mode**: Capture screenshots in both light and dark modes to showcase theme support.
- **App Data**: Seed the clipboard history with realistic, neat looking mock data (e.g. some clean code snippets, clean URLs, and an image thumbnail) before taking the screenshot.

---

## 2. Recording a Demo GIF

A short 5-10 second loop demonstrating how the app works (opening with `⌘⌥V`, searching, selecting an item) is highly effective.

### Option A: Using Kap (Recommended, Open Source)
[Kap](https://getkap.co/) is a free and open-source screen recorder for macOS:
1. Open Kap and set the recording frame around the PasteHub popover.
2. Record a brief action:
   - Copy some text.
   - Open PasteHub using `⌘⌥V`.
   - Filter by type (Text/URL).
   - Press `Enter` to select and copy.
3. Export directly from Kap as a **GIF** or **MP4**.

### Option B: Using Built-in macOS Recorder + FFmpeg
1. Press `⌘ + Shift + 5` and record a selected portion of your screen.
2. Save the recording (usually `.mov` format).
3. Use `ffmpeg` to convert it to an optimized GIF:
   ```bash
   ffmpeg -i demo.mov -vf "fps=15,scale=640:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 demo.gif
   ```

---

## 3. Formatting and Adding to README

1. Create an `assets` folder inside the `docs` directory:
   ```
   docs/assets/
   ```
2. Save your screenshots and GIFs using clean, lowercase names (e.g., `screenshot-light.png`, `demo.gif`).
3. Add them to the `README.md` using standard markdown:
   ```markdown
   ![PasteHub Light Mode](docs/assets/screenshot-light.png)
   ```
