import AppKit
import CoreGraphics
import ScreenCaptureKit

public enum PermissionManager {

    /// Check and request Accessibility permission (needed for global keyboard shortcuts)
    public static func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Check screen recording permission by attempting a minimal capture
    public static func checkScreenRecordingPermission() {
        Task {
            do {
                _ = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
                NSLog("[OneScreenSnap] Screen recording permission granted")
            } catch {
                NSLog("[OneScreenSnap] Screen recording permission not granted: \(error)")
            }
        }
    }
}
