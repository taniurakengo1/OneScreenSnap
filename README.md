# OneScreenSnap

A macOS menu bar app that captures a specific display to your clipboard with a single keyboard shortcut.

Unlike macOS's built-in `Cmd+Shift+3` (which captures all displays) or `Cmd+Shift+4` (which requires manual selection), OneScreenSnap lets you **pre-assign a shortcut to each display** and capture it instantly — no mouse interaction needed.

## Features

- **Per-display shortcuts** — Assign a different keyboard shortcut to each connected display
- **Instant clipboard** — Captured image goes straight to clipboard, ready to paste
- **Visual feedback** — Screen flash + sound on capture
- **Multi-display aware** — Auto-detects all connected displays, handles hotplug
- **Stable bindings** — Shortcuts survive display reconnection (matched by name + resolution)
- **Menu bar app** — Runs silently in the menu bar, no Dock icon

## Use Case

You're using Claude Code (or any AI coding assistant) and need to paste screenshots of different windows frequently. Instead of:

1. `Cmd+Shift+4` → drag to select → switch to terminal → `Cmd+V`

You do:

1. `F10` → `Cmd+V`

That's it. One key to capture, one key to paste.

## Requirements

- macOS 14.0 (Sonoma) or later
- Screen Recording permission (required for ScreenCaptureKit)
- Accessibility permission (required for global keyboard shortcuts)

## Installation

```bash
git clone https://github.com/taniurakengo1/OneScreenSnap.git
cd OneScreenSnap
sudo make install
make start
```

This builds a proper `.app` bundle and installs it to `/Applications/OneScreenSnap.app`.

Other commands:

```bash
make stop        # Stop OneScreenSnap
make uninstall   # Remove everything
make bundle      # Build .app bundle without installing
```

> **Note:** Xcode or Command Line Tools are required. Install with `xcode-select --install` if needed.

### First launch

1. OneScreenSnap will request **Screen Recording** and **Accessibility** permissions
2. Go to **System Settings → Privacy & Security → Screen Recording** and toggle ON
3. Go to **System Settings → Privacy & Security → Accessibility** and toggle ON
4. Click the camera icon in the menu bar → **Settings...**
5. Assign a shortcut to each display

## How it works

1. OneScreenSnap uses **ScreenCaptureKit** (Apple's official API) to capture displays
2. Global keyboard shortcuts are captured via **CGEventTap** (Accessibility API)
3. When a shortcut is pressed, the corresponding display is captured and written to `NSPasteboard`
4. A brief screen flash and sound confirm the capture

No data is sent externally. No network access. Everything stays on your Mac.

## Roadmap

- [ ] Fixed rectangle capture — Define a region once, capture it with one key every time
- [ ] Multiple rectangle presets — Capture several fixed regions at once
- [ ] File save option — Save captures to disk (PNG/JPEG)
- [ ] Capture history — View and re-copy recent captures from the menu bar

## Technical Notes

- Uses **ScreenCaptureKit** (macOS 14+) — Apple's recommended API for screen capture
- Retina-aware — Captures at native resolution with proper scaling
- No private APIs — Can be distributed on the Mac App Store in the future
- Display bindings use stable keys (display name + resolution) to survive reconnection

## Contributing

Contributions are welcome! Please open an issue or pull request.

## License

[MIT License](LICENSE)
