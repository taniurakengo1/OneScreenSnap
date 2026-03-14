import AppKit
import CoreGraphics

public final class ShortcutManager {
    public var onCapture: ((CGDirectDisplayID) -> Void)?
    public var onRegionCapture: ((CGRect, CGDirectDisplayID) -> Void)?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var retainedSelf: Unmanaged<ShortcutManager>?
    private weak var settingsManager: SettingsManager?
    private weak var displayManager: DisplayManager?

    private static let modifierMask: UInt64 = {
        CGEventFlags.maskControl.rawValue |
        CGEventFlags.maskAlternate.rawValue |
        CGEventFlags.maskShift.rawValue |
        CGEventFlags.maskCommand.rawValue
    }()

    public init() {}

    public func start(settingsManager: SettingsManager, displayManager: DisplayManager) {
        self.settingsManager = settingsManager
        self.displayManager = displayManager
        setupEventTap()
    }

    private func setupEventTap() {
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        let retained = Unmanaged.passRetained(self)
        let selfPtr = retained.toOpaque()

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let manager = Unmanaged<ShortcutManager>.fromOpaque(refcon).takeUnretainedValue()
                if manager.handleKeyEvent(event) {
                    return nil
                }
                return Unmanaged.passRetained(event)
            },
            userInfo: selfPtr
        )

        guard let eventTap = eventTap else {
            NSLog("[OneScreenSnap] Failed to create event tap. Check Accessibility permissions.")
            retained.release()
            return
        }

        retainedSelf = retained
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        NSLog("[OneScreenSnap] Event tap started")
    }

    private func handleKeyEvent(_ event: CGEvent) -> Bool {
        guard let settingsManager = settingsManager,
              let displayManager = displayManager else { return false }

        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags.rawValue & Self.modifierMask

        // Check display shortcuts
        let resolved = settingsManager.resolvedBindings(with: displayManager)
        for (displayID, shortcut) in resolved {
            if keyCode == shortcut.keyCode && flags == UInt64(shortcut.modifiers) {
                DispatchQueue.main.async { [weak self] in
                    self?.onCapture?(displayID)
                }
                return true
            }
        }

        // Check region preset shortcuts
        let regions = settingsManager.resolvedRegionBindings(with: displayManager)
        for (rect, displayID, shortcut) in regions {
            if keyCode == shortcut.keyCode && flags == UInt64(shortcut.modifiers) {
                DispatchQueue.main.async { [weak self] in
                    self?.onRegionCapture?(rect, displayID)
                }
                return true
            }
        }

        return false
    }

    public func stop() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        retainedSelf?.release()
        retainedSelf = nil
    }

    deinit {
        stop()
    }
}
