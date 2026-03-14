import AppKit
import CoreGraphics
import os

public struct DisplayInfo: Sendable {
    public let id: CGDirectDisplayID
    public let name: String
    public let bounds: CGRect
    public let isMain: Bool

    public var resolution: String {
        "\(Int(bounds.width))×\(Int(bounds.height))"
    }

    /// Stable identifier for settings persistence (survives display reconnection)
    public var stableKey: String {
        "\(name)_\(Int(bounds.width))x\(Int(bounds.height))"
    }
}

public final class DisplayManager {
    private let lock = OSAllocatedUnfairLock(initialState: [DisplayInfo]())
    private var observer: NSObjectProtocol?

    public var displays: [DisplayInfo] {
        lock.withLock { $0 }
    }

    public init() {
        refreshDisplays()
    }

    public func startObserving() {
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshDisplays()
            NSLog("[OneScreenSnap] Display configuration changed, refreshed")
        }
    }

    public func refreshDisplays() {
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: 16)
        var displayCount: UInt32 = 0
        CGGetActiveDisplayList(16, &displayIDs, &displayCount)

        let mainDisplayID = CGMainDisplayID()
        var result: [DisplayInfo] = []

        for i in 0..<Int(displayCount) {
            let id = displayIDs[i]
            let bounds = CGDisplayBounds(id)
            let name = displayName(for: id, index: i)
            let isMain = (id == mainDisplayID)
            result.append(DisplayInfo(id: id, name: name, bounds: bounds, isMain: isMain))
        }

        result.sort { $0.bounds.origin.x < $1.bounds.origin.x }
        let sorted = result
        lock.withLock { $0 = sorted }
    }

    /// Find display by stable key (for settings restoration after reconnection)
    public func findDisplay(byStableKey key: String) -> DisplayInfo? {
        displays.first(where: { $0.stableKey == key })
    }

    private func displayName(for displayID: CGDirectDisplayID, index: Int) -> String {
        for screen in NSScreen.screens {
            if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
               screenNumber == displayID {
                return screen.localizedName
            }
        }
        return "Display \(index + 1)"
    }

    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
