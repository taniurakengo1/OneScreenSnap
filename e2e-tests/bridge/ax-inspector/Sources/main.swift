import AppKit
import Foundation

// Inspect OneScreenSnap via Accessibility API
// Usage: ax-inspector [menu-items | window | status-item]

let args = CommandLine.arguments
let command = args.count > 1 ? args[1] : "status-item"

struct AXResult: Codable {
    let command: String
    let success: Bool
    let data: [String: AnyCodable]
    let error: String?
}

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) { value = s }
        else if let i = try? container.decode(Int.self) { value = i }
        else if let b = try? container.decode(Bool.self) { value = b }
        else if let a = try? container.decode([String].self) { value = a }
        else { value = "unknown" }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let s as String: try container.encode(s)
        case let i as Int: try container.encode(i)
        case let b as Bool: try container.encode(b)
        case let a as [String]: try container.encode(a)
        default: try container.encode(String(describing: value))
        }
    }
}

func findOneScreenSnap() -> NSRunningApplication? {
    NSWorkspace.shared.runningApplications.first {
        $0.bundleIdentifier == "com.onescreensnap.app" ||
        $0.localizedName == "OneScreenSnap"
    }
}

func getMenuItems() -> [String: AnyCodable] {
    guard let app = findOneScreenSnap() else {
        return ["error": AnyCodable("OneScreenSnap not running")]
    }

    let appElement = AXUIElementCreateApplication(app.processIdentifier)
    var menuBar: CFTypeRef?
    let err = AXUIElementCopyAttributeValue(appElement, kAXMenuBarAttribute as CFString, &menuBar)

    if err != .success {
        return ["error": AnyCodable("Cannot access menu bar: \(err.rawValue)")]
    }

    // For menu bar apps (LSUIElement), extras menu bar is used
    var extras: CFTypeRef?
    let extrasErr = AXUIElementCopyAttributeValue(appElement, kAXExtrasMenuBarAttribute as CFString, &extras)

    let items: [String] = []

    // Try to get status menu items via system-wide element
    let systemWide = AXUIElementCreateSystemWide()
    var focusedApp: CFTypeRef?
    AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp)

    return [
        "pid": AnyCodable(Int(app.processIdentifier)),
        "bundleId": AnyCodable(app.bundleIdentifier ?? "unknown"),
        "isRunning": AnyCodable(true),
        "menuBarAccessible": AnyCodable(err == .success),
        "extrasMenuBarAccessible": AnyCodable(extrasErr == .success),
        "items": AnyCodable(items),
    ]
}

func getWindowInfo() -> [String: AnyCodable] {
    guard let app = findOneScreenSnap() else {
        return ["error": AnyCodable("OneScreenSnap not running")]
    }

    let appElement = AXUIElementCreateApplication(app.processIdentifier)
    var windowsRef: CFTypeRef?
    let err = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)

    if err != .success {
        return ["windowCount": AnyCodable(0), "error": AnyCodable("Cannot access windows")]
    }

    guard let windows = windowsRef as? [AXUIElement] else {
        return ["windowCount": AnyCodable(0)]
    }

    var windowInfos: [String] = []
    for window in windows {
        var titleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
        let title = (titleRef as? String) ?? "untitled"
        windowInfos.append(title)
    }

    return [
        "windowCount": AnyCodable(windows.count),
        "windowTitles": AnyCodable(windowInfos),
    ]
}

func getStatusItemInfo() -> [String: AnyCodable] {
    guard let app = findOneScreenSnap() else {
        return [
            "isRunning": AnyCodable(false),
            "error": AnyCodable("OneScreenSnap not running"),
        ]
    }

    return [
        "isRunning": AnyCodable(true),
        "pid": AnyCodable(Int(app.processIdentifier)),
        "bundleId": AnyCodable(app.bundleIdentifier ?? "unknown"),
        "isHidden": AnyCodable(app.isHidden),
        "activationPolicy": AnyCodable(Int(app.activationPolicy.rawValue)),
    ]
}

let data: [String: AnyCodable]
switch command {
case "menu-items":
    data = getMenuItems()
case "window":
    data = getWindowInfo()
case "status-item":
    data = getStatusItemInfo()
default:
    data = ["error": AnyCodable("Unknown command: \(command)")]
}

let result = AXResult(command: command, success: data["error"] == nil, data: data, error: nil)
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
if let jsonData = try? encoder.encode(result), let json = String(data: jsonData, encoding: .utf8) {
    print(json)
}
