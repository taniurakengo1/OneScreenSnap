import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let displayManager = DisplayManager()
    private let captureManager = CaptureManager()
    private let shortcutManager = ShortcutManager()
    private let settingsManager = SettingsManager()
    private var settingsWindowController: SettingsWindowController?
    private var regionOverlay: RegionSelectionOverlay?

    public override init() {
        super.init()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        displayManager.startObserving()

        shortcutManager.onCapture = { [weak self] displayID in
            self?.captureDisplay(displayID)
        }
        shortcutManager.onRegionCapture = { [weak self] rect, displayID in
            self?.captureRect(rect, displayID: displayID)
        }
        shortcutManager.start(settingsManager: settingsManager, displayManager: displayManager)

        PermissionManager.checkScreenRecordingPermission()
        _ = PermissionManager.checkAccessibilityPermission()
        NSLog("[OneScreenSnap] Started v\(AppVersion.current) with \(displayManager.displays.count) display(s)")
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "viewfinder.rectangular", accessibilityDescription: "OneScreenSnap")
        }
        statusItem.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        // App name header
        let appNameItem = NSMenuItem(title: "OneScreenSnap", action: nil, keyEquivalent: "")
        appNameItem.isEnabled = false
        appNameItem.attributedTitle = NSAttributedString(
            string: "OneScreenSnap",
            attributes: [.font: NSFont.boldSystemFont(ofSize: 13)]
        )
        menu.addItem(appNameItem)
        menu.addItem(NSMenuItem.separator())

        // Display captures
        let displayCount = displayManager.displays.count
        for (index, display) in displayManager.displays.enumerated() {
            let shortcutLabel = settingsManager.shortcut(forStableKey: display.stableKey)?.displayString ?? ""
            let position = SettingsWindowController.positionLabel(index: index, total: displayCount)
            var title = "\(display.name) (\(display.resolution))"
            if display.isMain { title += " ★" }
            if !position.isEmpty { title += "  [\(position)]" }
            let item = NSMenuItem(title: title, action: #selector(captureMenuDisplay(_:)), keyEquivalent: "")
            item.tag = index
            item.target = self
            if !shortcutLabel.isEmpty {
                item.toolTip = "Shortcut: \(shortcutLabel)"
            }
            menu.addItem(item)
        }

        // Region presets
        let regions = settingsManager.regionPresets
        if !regions.isEmpty {
            menu.addItem(NSMenuItem.separator())
            let regionHeader = NSMenuItem(title: L10n.regionPresetsHeader, action: nil, keyEquivalent: "")
            regionHeader.isEnabled = false
            menu.addItem(regionHeader)
            for (index, preset) in regions.enumerated() {
                let shortcutStr = preset.shortcut?.displayString ?? ""
                let title = "\(preset.name)  \(preset.summary)"
                let item = NSMenuItem(title: title, action: #selector(captureMenuRegion(_:)), keyEquivalent: "")
                item.tag = index
                item.target = self
                if !shortcutStr.isEmpty {
                    item.toolTip = "Shortcut: \(shortcutStr)"
                }
                menu.addItem(item)
            }
        }

        menu.addItem(NSMenuItem.separator())
        let settingsItem = NSMenuItem(title: L10n.settings, action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: L10n.quit, action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    func refreshMenu() {
        statusItem.menu = buildMenu()
    }

    // MARK: - Capture Actions

    private func processAndCopy(_ image: NSImage, displayID: CGDirectDisplayID) {
        var result = image
        if settingsManager.resizeMode == .aiOptimized {
            result = CaptureManager.resizeForAI(result)
        }
        ClipboardManager.copyToClipboard(result)
        CaptureNotifier.notifySuccess(mode: settingsManager.feedbackMode, displayID: displayID)
    }

    private func captureDisplay(_ displayID: CGDirectDisplayID) {
        Task {
            guard let image = await captureManager.captureDisplay(displayID) else {
                NSLog("[OneScreenSnap] Failed to capture display \(displayID)")
                await MainActor.run { CaptureNotifier.notifyFailure(mode: settingsManager.feedbackMode, displayID: displayID) }
                return
            }
            await MainActor.run { processAndCopy(image, displayID: displayID) }
            NSLog("[OneScreenSnap] Captured display \(displayID) to clipboard")
        }
    }

    private func captureRect(_ rect: CGRect, displayID: CGDirectDisplayID) {
        Task {
            guard let image = await captureManager.captureRect(rect, displayID: displayID) else {
                NSLog("[OneScreenSnap] Failed to capture rect on display \(displayID)")
                await MainActor.run { CaptureNotifier.notifyFailure(mode: settingsManager.feedbackMode, displayID: displayID) }
                return
            }
            await MainActor.run { processAndCopy(image, displayID: displayID) }
            NSLog("[OneScreenSnap] Captured rect \(rect) on display \(displayID) to clipboard")
        }
    }

    // MARK: - Region Selection

    func startRegionSelection() {
        regionOverlay = RegionSelectionOverlay(displays: displayManager.displays)
        regionOverlay?.start { [weak self] rect, display in
            guard let self = self else { return }
            let preset = RegionPreset(
                displayStableKey: display.stableKey,
                rect: rect,
                name: "Region \(self.settingsManager.regionPresets.count + 1)"
            )
            self.settingsManager.addRegionPreset(preset)
            self.refreshMenu()
            // Reopen settings to show the new preset
            self.settingsWindowController = nil
            self.openSettings()
            NSLog("[OneScreenSnap] Added region preset: \(preset.summary) on \(display.name)")
        }
    }

    // MARK: - Menu Actions

    @objc private func captureMenuDisplay(_ sender: NSMenuItem) {
        let index = sender.tag
        guard index < displayManager.displays.count else { return }
        captureDisplay(displayManager.displays[index].id)
    }

    @objc private func captureMenuRegion(_ sender: NSMenuItem) {
        let index = sender.tag
        let presets = settingsManager.regionPresets
        guard index < presets.count else { return }
        let preset = presets[index]
        if let display = displayManager.findDisplay(byStableKey: preset.displayStableKey) {
            captureRect(preset.rect.cgRect, displayID: display.id)
        }
    }

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(
                settingsManager: settingsManager,
                displayManager: displayManager,
                appDelegate: self
            )
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
