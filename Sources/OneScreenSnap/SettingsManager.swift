import Foundation
import CoreGraphics

public struct Shortcut: Codable, Equatable {
    public let keyCode: UInt16
    public let modifiers: UInt32

    public init(keyCode: UInt16, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    public var displayString: String {
        var parts: [String] = []
        let flags = CGEventFlags(rawValue: UInt64(modifiers))
        if flags.contains(.maskControl) { parts.append("\u{2303}") }
        if flags.contains(.maskAlternate) { parts.append("\u{2325}") }
        if flags.contains(.maskShift) { parts.append("\u{21E7}") }
        if flags.contains(.maskCommand) { parts.append("\u{2318}") }
        parts.append(Self.keyCodeToString(keyCode))
        return parts.joined()
    }

    private static func keyCodeToString(_ keyCode: UInt16) -> String {
        let mapping: [UInt16: String] = [
            0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H",
            0x05: "G", 0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V",
            0x0B: "B", 0x0C: "Q", 0x0D: "W", 0x0E: "E", 0x0F: "R",
            0x10: "Y", 0x11: "T", 0x12: "1", 0x13: "2", 0x14: "3",
            0x15: "4", 0x16: "6", 0x17: "5", 0x18: "=", 0x19: "9",
            0x1A: "7", 0x1B: "-", 0x1C: "8", 0x1D: "0",
            0x1F: "]", 0x20: "O", 0x21: "U", 0x22: "[", 0x23: "I",
            0x24: "↩", 0x25: "L", 0x26: "J", 0x28: "K",
            0x2C: "/", 0x2D: "N", 0x2E: "M",
            0x30: "⇥", 0x31: "Space", 0x33: "⌫", 0x35: "⎋",
            0x60: "F5", 0x61: "F6", 0x62: "F7", 0x63: "F3",
            0x64: "F8", 0x65: "F9", 0x67: "F11",
            0x69: "F13", 0x6B: "F14", 0x6D: "F10",
            0x6F: "F12", 0x71: "F15", 0x72: "Help",
            0x73: "Home", 0x74: "PgUp", 0x75: "⌦",
            0x76: "F4", 0x77: "End", 0x78: "F2", 0x79: "PgDn",
            0x7A: "F1", 0x7B: "←", 0x7C: "→", 0x7D: "↓", 0x7E: "↑",
        ]
        return mapping[keyCode] ?? "Key\(keyCode)"
    }
}

/// Display-to-shortcut mapping using stable keys (survives display reconnection)
public struct DisplayShortcutBinding: Codable {
    public let displayStableKey: String
    public let displayID: UInt32
    public let shortcut: Shortcut

    public init(displayStableKey: String, displayID: UInt32, shortcut: Shortcut) {
        self.displayStableKey = displayStableKey
        self.displayID = displayID
        self.shortcut = shortcut
    }
}

public enum FeedbackMode: Int {
    case soundAndFlash = 0
    case flashOnly = 1
    case none = 2
}

public enum CaptureResizeMode: Int {
    case full = 0
    case aiOptimized = 1  // max 1568px on longest side
}

public final class SettingsManager {
    private let defaults = UserDefaults.standard
    private let bindingsKey = "displayShortcutBindings"
    private let regionsKey = "regionPresets"
    private let feedbackKey = "feedbackMode"
    private let resizeKey = "captureResizeMode"

    public var feedbackMode: FeedbackMode {
        get { FeedbackMode(rawValue: defaults.integer(forKey: feedbackKey)) ?? .soundAndFlash }
        set { defaults.set(newValue.rawValue, forKey: feedbackKey) }
    }

    public var resizeMode: CaptureResizeMode {
        get { CaptureResizeMode(rawValue: defaults.integer(forKey: resizeKey)) ?? .full }
        set { defaults.set(newValue.rawValue, forKey: resizeKey) }
    }

    public var bindings: [DisplayShortcutBinding] {
        get {
            guard let data = defaults.data(forKey: bindingsKey),
                  let decoded = try? JSONDecoder().decode([DisplayShortcutBinding].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: bindingsKey)
            }
        }
    }

    public var regionPresets: [RegionPreset] {
        get {
            guard let data = defaults.data(forKey: regionsKey),
                  let decoded = try? JSONDecoder().decode([RegionPreset].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: regionsKey)
            }
        }
    }

    public init() {}

    // MARK: - Display Shortcuts

    public func shortcut(for displayID: CGDirectDisplayID) -> Shortcut? {
        bindings.first(where: { $0.displayID == displayID })?.shortcut
    }

    public func shortcut(forStableKey key: String) -> Shortcut? {
        bindings.first(where: { $0.displayStableKey == key })?.shortcut
    }

    public func setShortcut(_ shortcut: Shortcut, for display: DisplayInfo) {
        var current = bindings.filter { $0.displayStableKey != display.stableKey }
        current.append(DisplayShortcutBinding(
            displayStableKey: display.stableKey,
            displayID: display.id,
            shortcut: shortcut
        ))
        bindings = current
    }

    public func removeShortcut(for display: DisplayInfo) {
        bindings = bindings.filter { $0.displayStableKey != display.stableKey }
    }

    /// Resolve bindings using stable keys when display IDs change after reconnection
    public func resolvedBindings(with displayManager: DisplayManager) -> [(displayID: CGDirectDisplayID, shortcut: Shortcut)] {
        bindings.compactMap { binding in
            if let display = displayManager.findDisplay(byStableKey: binding.displayStableKey) {
                return (display.id, binding.shortcut)
            }
            let displays = displayManager.displays
            if displays.contains(where: { $0.id == CGDirectDisplayID(binding.displayID) }) {
                return (CGDirectDisplayID(binding.displayID), binding.shortcut)
            }
            return nil
        }
    }

    // MARK: - Region Presets

    public func addRegionPreset(_ preset: RegionPreset) {
        var presets = regionPresets
        presets.append(preset)
        regionPresets = presets
    }

    public func removeRegionPreset(id: String) {
        regionPresets = regionPresets.filter { $0.id != id }
    }

    public func setShortcutForRegion(_ shortcut: Shortcut?, id: String) {
        var presets = regionPresets
        if let index = presets.firstIndex(where: { $0.id == id }) {
            presets[index].shortcut = shortcut
            regionPresets = presets
        }
    }

    public func resolvedRegionBindings(with displayManager: DisplayManager) -> [(rect: CGRect, displayID: CGDirectDisplayID, shortcut: Shortcut)] {
        regionPresets.compactMap { preset in
            guard let shortcut = preset.shortcut,
                  let display = displayManager.findDisplay(byStableKey: preset.displayStableKey) else {
                return nil
            }
            return (preset.rect.cgRect, display.id, shortcut)
        }
    }
}
