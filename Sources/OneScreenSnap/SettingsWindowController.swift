import AppKit

private final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

// MARK: - Display Arrangement View

private final class DisplayArrangementView: NSView {
    override var isFlipped: Bool { true }

    private let displays: [DisplayInfo]
    private let colors: [NSColor] = [
        .systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemPink
    ]

    init(displays: [DisplayInfo], frame: NSRect) {
        self.displays = displays
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.backgroundColor = NSColor.quaternaryLabelColor.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard !displays.isEmpty else { return }

        var minX = CGFloat.infinity, minY = CGFloat.infinity
        var maxX = -CGFloat.infinity, maxY = -CGFloat.infinity
        for d in displays {
            minX = min(minX, d.bounds.origin.x)
            minY = min(minY, d.bounds.origin.y)
            maxX = max(maxX, d.bounds.origin.x + d.bounds.width)
            maxY = max(maxY, d.bounds.origin.y + d.bounds.height)
        }
        let totalW = maxX - minX
        let totalH = maxY - minY

        let padding: CGFloat = 20
        let availW = bounds.width - padding * 2
        let availH = bounds.height - padding * 2
        let scale = min(availW / totalW, availH / totalH)

        let scaledTotalW = totalW * scale
        let scaledTotalH = totalH * scale
        let offsetX = padding + (availW - scaledTotalW) / 2
        let offsetY = padding + (availH - scaledTotalH) / 2

        for (i, d) in displays.enumerated() {
            let x = offsetX + (d.bounds.origin.x - minX) * scale
            let y = offsetY + (d.bounds.origin.y - minY) * scale
            let w = d.bounds.width * scale
            let h = d.bounds.height * scale
            let rect = NSRect(x: x, y: y, width: w, height: h)

            let color = colors[i % colors.count]
            color.withAlphaComponent(0.15).setFill()
            let path = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)
            path.fill()

            color.withAlphaComponent(0.6).setStroke()
            path.lineWidth = 2
            path.stroke()

            let name = d.name
            let shortName = name.count > 15 ? String(name.prefix(12)) + "…" : name
            let label = d.isMain ? "\(shortName) ★" : shortName
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: max(9, min(11, h * 0.15)), weight: .medium),
                .foregroundColor: NSColor.labelColor
            ]
            let str = NSAttributedString(string: label, attributes: attrs)
            let strSize = str.size()
            let strX = rect.midX - strSize.width / 2
            let strY = rect.midY - strSize.height / 2
            str.draw(at: NSPoint(x: max(rect.minX + 4, strX), y: strY))
        }
    }
}

// MARK: - SettingsWindowController

public final class SettingsWindowController: NSWindowController {
    private let settingsManager: SettingsManager
    private let displayManager: DisplayManager
    private weak var appDelegate: AppDelegate?

    public init(settingsManager: SettingsManager, displayManager: DisplayManager, appDelegate: AppDelegate) {
        self.settingsManager = settingsManager
        self.displayManager = displayManager
        self.appDelegate = appDelegate

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.settingsTitle
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public static func positionLabel(index: Int, total: Int) -> String {
        guard total > 1 else { return "" }
        if total == 2 {
            return index == 0 ? L10n.posLeft : L10n.posRight
        }
        if index == 0 { return L10n.posLeft }
        if index == total - 1 { return L10n.posRight }
        return L10n.posCenter
    }

    /// Collect all currently assigned shortcuts (display + region)
    private func allAssignedShortcuts(excluding: Shortcut? = nil) -> [Shortcut] {
        var shortcuts: [Shortcut] = []
        for binding in settingsManager.bindings {
            if binding.shortcut != excluding {
                shortcuts.append(binding.shortcut)
            }
        }
        for preset in settingsManager.regionPresets {
            if let s = preset.shortcut, s != excluding {
                shortcuts.append(s)
            }
        }
        return shortcuts
    }

    /// Check for conflict and prompt user. Returns true if should proceed.
    private func checkConflictAndConfirm(_ shortcut: Shortcut, excluding: Shortcut? = nil) -> Bool {
        let existing = allAssignedShortcuts(excluding: excluding)
        guard existing.contains(shortcut) else { return true }

        let alert = NSAlert()
        alert.messageText = L10n.shortcutConflictTitle
        alert.informativeText = L10n.shortcutConflictMessage(shortcut.displayString)
        alert.addButton(withTitle: L10n.replace)
        alert.addButton(withTitle: L10n.cancel)
        alert.alertStyle = .warning

        if alert.runModal() == .alertFirstButtonReturn {
            // Remove old binding with this shortcut
            removeAllBindings(for: shortcut)
            return true
        }
        return false
    }

    /// Remove all existing bindings (display + region) for a given shortcut
    private func removeAllBindings(for shortcut: Shortcut) {
        // Remove from display bindings
        var bindings = settingsManager.bindings
        bindings.removeAll { $0.shortcut == shortcut }
        settingsManager.bindings = bindings

        // Remove from region presets
        var presets = settingsManager.regionPresets
        for i in presets.indices {
            if presets[i].shortcut == shortcut {
                presets[i].shortcut = nil
            }
        }
        settingsManager.regionPresets = presets
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let scrollView = NSScrollView(frame: contentView.bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true

        let documentView = FlippedView()
        scrollView.documentView = documentView

        let displays = displayManager.displays
        var y: CGFloat = 16

        // === Display Arrangement ===
        if displays.count > 1 {
            let label = sectionLabel(L10n.displayArrangement)
            label.frame = NSRect(x: 20, y: y, width: 480, height: 18)
            documentView.addSubview(label)
            y += 24

            let arrangementView = DisplayArrangementView(
                displays: displays,
                frame: NSRect(x: 20, y: y, width: 480, height: 120)
            )
            documentView.addSubview(arrangementView)
            y += 130
        }

        // === Display Shortcuts ===
        let shortcutTitle = sectionLabel(L10n.displayShortcuts)
        shortcutTitle.frame = NSRect(x: 20, y: y, width: 480, height: 18)
        documentView.addSubview(shortcutTitle)
        y += 22

        let desc = NSTextField(wrappingLabelWithString: L10n.displayShortcutsDesc)
        desc.frame = NSRect(x: 20, y: y, width: 480, height: 20)
        desc.textColor = .secondaryLabelColor
        desc.font = NSFont.systemFont(ofSize: 11)
        documentView.addSubview(desc)
        y += 28

        for (index, display) in displays.enumerated() {
            let position = Self.positionLabel(index: index, total: displays.count)
            var labelText = "\(display.name) (\(display.resolution))"
            if display.isMain { labelText += " ★" }
            if !position.isEmpty { labelText += "  [\(position)]" }

            let displayLabel = NSTextField(labelWithString: labelText)
            displayLabel.font = NSFont.systemFont(ofSize: 13)
            displayLabel.frame = NSRect(x: 20, y: y + 4, width: 300, height: 20)
            documentView.addSubview(displayLabel)

            let recorder = ShortcutRecorderView(frame: NSRect(x: 330, y: y, width: 160, height: 28))
            if let shortcut = settingsManager.shortcut(forStableKey: display.stableKey) {
                recorder.currentShortcut = shortcut
            }
            let stableKey = display.stableKey
            recorder.onShortcutChanged = { [weak self] shortcut in
                guard let self = self else { return }
                if let shortcut = shortcut {
                    let oldShortcut = self.settingsManager.shortcut(forStableKey: stableKey)
                    if self.checkConflictAndConfirm(shortcut, excluding: oldShortcut) {
                        self.settingsManager.setShortcut(shortcut, for: display)
                    } else {
                        recorder.currentShortcut = oldShortcut
                    }
                } else {
                    self.settingsManager.removeShortcut(for: display)
                }
            }
            documentView.addSubview(recorder)
            y += 36

            if index < displays.count - 1 {
                let sep = NSBox(frame: NSRect(x: 20, y: y, width: 480, height: 1))
                sep.boxType = .separator
                documentView.addSubview(sep)
                y += 8
            }
        }

        if displays.isEmpty {
            let emptyLabel = NSTextField(labelWithString: L10n.noDisplays)
            emptyLabel.frame = NSRect(x: 20, y: y, width: 480, height: 20)
            emptyLabel.textColor = .secondaryLabelColor
            documentView.addSubview(emptyLabel)
            y += 28
        }

        y += 16

        // === Region Presets ===
        let regionSep = NSBox(frame: NSRect(x: 20, y: y, width: 480, height: 1))
        regionSep.boxType = .separator
        documentView.addSubview(regionSep)
        y += 12

        let regionTitle = sectionLabel(L10n.regionPresetsTitle)
        regionTitle.frame = NSRect(x: 20, y: y, width: 380, height: 18)
        documentView.addSubview(regionTitle)

        let addRegionBtn = NSButton(title: L10n.addRegion, target: self, action: #selector(addRegionPreset))
        addRegionBtn.bezelStyle = .rounded
        addRegionBtn.frame = NSRect(x: 390, y: y - 4, width: 110, height: 24)
        addRegionBtn.font = NSFont.systemFont(ofSize: 11)
        documentView.addSubview(addRegionBtn)
        y += 22

        let regionDesc = NSTextField(wrappingLabelWithString: L10n.regionPresetsDesc)
        regionDesc.frame = NSRect(x: 20, y: y, width: 480, height: 32)
        regionDesc.textColor = .secondaryLabelColor
        regionDesc.font = NSFont.systemFont(ofSize: 11)
        documentView.addSubview(regionDesc)
        y += 38

        let presets = settingsManager.regionPresets
        for (index, preset) in presets.enumerated() {
            let displayName = displayManager.findDisplay(byStableKey: preset.displayStableKey)?.name ?? "Unknown"
            let labelText = "\(preset.name) — \(displayName) \(preset.summary)"
            let presetLabel = NSTextField(labelWithString: labelText)
            presetLabel.font = NSFont.systemFont(ofSize: 12)
            presetLabel.frame = NSRect(x: 20, y: y + 4, width: 260, height: 20)
            documentView.addSubview(presetLabel)

            let recorder = ShortcutRecorderView(frame: NSRect(x: 290, y: y, width: 140, height: 28))
            recorder.currentShortcut = preset.shortcut
            let presetId = preset.id
            recorder.onShortcutChanged = { [weak self] shortcut in
                guard let self = self else { return }
                if let shortcut = shortcut {
                    let oldShortcut = preset.shortcut
                    if self.checkConflictAndConfirm(shortcut, excluding: oldShortcut) {
                        self.settingsManager.setShortcutForRegion(shortcut, id: presetId)
                    } else {
                        recorder.currentShortcut = oldShortcut
                    }
                } else {
                    self.settingsManager.setShortcutForRegion(nil, id: presetId)
                }
            }
            documentView.addSubview(recorder)

            let deleteBtn = NSButton(title: "✕", target: self, action: #selector(deleteRegionPreset(_:)))
            deleteBtn.bezelStyle = .inline
            deleteBtn.isBordered = false
            deleteBtn.frame = NSRect(x: 440, y: y + 2, width: 24, height: 24)
            deleteBtn.tag = index
            documentView.addSubview(deleteBtn)

            y += 36

            if index < presets.count - 1 {
                let sep = NSBox(frame: NSRect(x: 20, y: y, width: 480, height: 1))
                sep.boxType = .separator
                documentView.addSubview(sep)
                y += 8
            }
        }

        if presets.isEmpty {
            let emptyLabel = NSTextField(labelWithString: L10n.noRegionPresets)
            emptyLabel.frame = NSRect(x: 20, y: y, width: 480, height: 20)
            emptyLabel.textColor = .tertiaryLabelColor
            emptyLabel.font = NSFont.systemFont(ofSize: 12)
            documentView.addSubview(emptyLabel)
            y += 28
        }

        y += 16

        // === General ===
        let generalSep = NSBox(frame: NSRect(x: 20, y: y, width: 480, height: 1))
        generalSep.boxType = .separator
        documentView.addSubview(generalSep)
        y += 12

        let generalTitle = sectionLabel(L10n.general)
        generalTitle.frame = NSRect(x: 20, y: y, width: 480, height: 18)
        documentView.addSubview(generalTitle)
        y += 26

        // Launch at login
        let loginCheckbox = NSButton(checkboxWithTitle: L10n.launchAtLogin, target: self, action: #selector(toggleLaunchAtLogin(_:)))
        loginCheckbox.frame = NSRect(x: 20, y: y, width: 240, height: 20)
        loginCheckbox.state = LaunchAtLoginManager.isEnabled ? .on : .off
        if !LaunchAtLoginManager.isInstalled {
            loginCheckbox.isEnabled = false
            loginCheckbox.toolTip = L10n.launchAtLoginDisabled
        }
        documentView.addSubview(loginCheckbox)
        y += 28

        // Feedback mode
        let feedbackLabel = NSTextField(labelWithString: L10n.feedbackLabel)
        feedbackLabel.font = NSFont.systemFont(ofSize: 13)
        feedbackLabel.frame = NSRect(x: 20, y: y + 2, width: 140, height: 20)
        documentView.addSubview(feedbackLabel)

        let feedbackPopup = NSPopUpButton(frame: NSRect(x: 170, y: y, width: 200, height: 24), pullsDown: false)
        feedbackPopup.addItems(withTitles: [
            L10n.feedbackSoundAndFlash,
            L10n.feedbackFlashOnly,
            L10n.feedbackNone
        ])
        feedbackPopup.selectItem(at: settingsManager.feedbackMode.rawValue)
        feedbackPopup.target = self
        feedbackPopup.action = #selector(feedbackModeChanged(_:))
        feedbackPopup.font = NSFont.systemFont(ofSize: 12)
        documentView.addSubview(feedbackPopup)
        y += 32

        // Resize mode
        let resizeLabel = NSTextField(labelWithString: L10n.resizeLabel)
        resizeLabel.font = NSFont.systemFont(ofSize: 13)
        resizeLabel.frame = NSRect(x: 20, y: y + 2, width: 140, height: 20)
        documentView.addSubview(resizeLabel)

        let resizePopup = NSPopUpButton(frame: NSRect(x: 170, y: y, width: 200, height: 24), pullsDown: false)
        resizePopup.addItems(withTitles: [
            L10n.resizeFull,
            L10n.resizeAI
        ])
        resizePopup.selectItem(at: settingsManager.resizeMode.rawValue)
        resizePopup.target = self
        resizePopup.action = #selector(resizeModeChanged(_:))
        resizePopup.font = NSFont.systemFont(ofSize: 12)
        documentView.addSubview(resizePopup)
        y += 32

        // Version
        let versionLabel = NSTextField(labelWithString: "OneScreenSnap v\(AppVersion.current)")
        versionLabel.frame = NSRect(x: 20, y: y, width: 200, height: 16)
        versionLabel.font = NSFont.systemFont(ofSize: 11)
        versionLabel.textColor = .tertiaryLabelColor
        documentView.addSubview(versionLabel)

        let updateBtn = NSButton(title: L10n.checkForUpdatesBtn, target: self, action: #selector(checkForUpdates))
        updateBtn.bezelStyle = .rounded
        updateBtn.frame = NSRect(x: 330, y: y - 4, width: 170, height: 24)
        updateBtn.font = NSFont.systemFont(ofSize: 11)
        documentView.addSubview(updateBtn)
        y += 30

        y += 16
        documentView.frame = NSRect(x: 0, y: 0, width: 520, height: y)
        contentView.addSubview(scrollView)

        let windowHeight = min(y + 40, 600)
        window?.setContentSize(NSSize(width: 520, height: windowHeight))
    }

    private func sectionLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.boldSystemFont(ofSize: 13)
        return label
    }

    // MARK: - Actions

    @objc private func addRegionPreset() {
        window?.orderOut(nil)
        appDelegate?.startRegionSelection()
    }

    @objc private func deleteRegionPreset(_ sender: NSButton) {
        let index = sender.tag
        let presets = settingsManager.regionPresets
        guard index < presets.count else { return }
        settingsManager.removeRegionPreset(id: presets[index].id)
        appDelegate?.refreshMenu()
        rebuildUI()
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSButton) {
        LaunchAtLoginManager.setEnabled(sender.state == .on)
    }

    @objc private func feedbackModeChanged(_ sender: NSPopUpButton) {
        if let mode = FeedbackMode(rawValue: sender.indexOfSelectedItem) {
            settingsManager.feedbackMode = mode
        }
    }

    @objc private func resizeModeChanged(_ sender: NSPopUpButton) {
        if let mode = CaptureResizeMode(rawValue: sender.indexOfSelectedItem) {
            settingsManager.resizeMode = mode
        }
    }

    @objc private func checkForUpdates() {
        UpdateChecker.checkAndNotify()
    }

    private func rebuildUI() {
        guard let contentView = window?.contentView else { return }
        contentView.subviews.forEach { $0.removeFromSuperview() }
        setupUI()
    }
}

// MARK: - ShortcutRecorderView

final class ShortcutRecorderView: NSView {
    var currentShortcut: Shortcut? {
        didSet { updateLabel() }
    }
    var onShortcutChanged: ((Shortcut?) -> Void)?

    private let label = NSTextField(labelWithString: L10n.clickToRecord)
    private let clearButton = NSButton(title: "✕", target: nil, action: nil)
    private var isRecording = false

    override init(frame: NSRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor

        label.frame = NSRect(x: 8, y: 4, width: bounds.width - 36, height: 20)
        label.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabelColor
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        addSubview(label)

        clearButton.frame = NSRect(x: bounds.width - 28, y: 2, width: 24, height: 24)
        clearButton.bezelStyle = .inline
        clearButton.isBordered = false
        clearButton.target = self
        clearButton.action = #selector(clearShortcut)
        clearButton.isHidden = true
        addSubview(clearButton)

        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(startRecording))
        addGestureRecognizer(clickGesture)

        updateLabel()
    }

    private func updateLabel() {
        if isRecording {
            label.stringValue = L10n.pressShortcut
            label.textColor = .systemOrange
            layer?.borderColor = NSColor.systemOrange.cgColor
        } else if let shortcut = currentShortcut {
            label.stringValue = shortcut.displayString
            label.textColor = .labelColor
            layer?.borderColor = NSColor.separatorColor.cgColor
            clearButton.isHidden = false
        } else {
            label.stringValue = L10n.clickToRecord
            label.textColor = .secondaryLabelColor
            layer?.borderColor = NSColor.separatorColor.cgColor
            clearButton.isHidden = true
        }
    }

    @objc private func startRecording() {
        isRecording = true
        updateLabel()
        window?.makeFirstResponder(self)
    }

    private func cancelRecording() {
        isRecording = false
        updateLabel()
    }

    @objc private func clearShortcut() {
        currentShortcut = nil
        onShortcutChanged?(nil)
    }

    override var acceptsFirstResponder: Bool { true }

    override func resignFirstResponder() -> Bool {
        if isRecording {
            cancelRecording()
        }
        return super.resignFirstResponder()
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        if event.keyCode == 0x35 { // Escape
            cancelRecording()
            return
        }

        let modifierMask: UInt64 =
            CGEventFlags.maskControl.rawValue |
            CGEventFlags.maskAlternate.rawValue |
            CGEventFlags.maskShift.rawValue |
            CGEventFlags.maskCommand.rawValue

        let flags = UInt32(UInt64(event.modifierFlags.rawValue) & modifierMask)
        let shortcut = Shortcut(keyCode: event.keyCode, modifiers: flags)
        currentShortcut = shortcut
        isRecording = false
        updateLabel()
        onShortcutChanged?(shortcut)
    }
}
