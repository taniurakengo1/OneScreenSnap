import AppKit

public enum CaptureNotifier {

    private static func playShutterSound() {
        let path = "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/begin_record.caf"
        if let sound = NSSound(contentsOfFile: path, byReference: true) {
            sound.play()
        } else {
            NSSound(named: "Tink")?.play()
        }
    }

    public static func notifySuccess(mode: FeedbackMode = .soundAndFlash, displayID: CGDirectDisplayID? = nil) {
        NSLog("[OneScreenSnap] notifySuccess mode=\(mode.rawValue)")
        switch mode {
        case .soundAndFlash:
            playShutterSound()
            flashScreen(color: NSColor.white.withAlphaComponent(0.3), displayID: displayID)
        case .flashOnly:
            flashScreen(color: NSColor.white.withAlphaComponent(0.3), displayID: displayID)
        case .none:
            break
        }
    }

    public static func notifyFailure(mode: FeedbackMode = .soundAndFlash, displayID: CGDirectDisplayID? = nil) {
        // Always show error alert regardless of mode
        if mode != .none {
            NSSound(named: "Basso")?.play()
            flashScreen(color: NSColor.red.withAlphaComponent(0.2), displayID: displayID)
        }

        let alert = NSAlert()
        alert.messageText = L10n.captureFailedTitle
        alert.informativeText = L10n.captureFailedMessage
        alert.addButton(withTitle: L10n.ok)
        alert.alertStyle = .warning
        alert.runModal()
    }

    /// Find the NSScreen corresponding to a CGDirectDisplayID
    private static func screen(for displayID: CGDirectDisplayID?) -> NSScreen? {
        guard let displayID = displayID else { return NSScreen.main }
        return NSScreen.screens.first { screen in
            screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID == displayID
        } ?? NSScreen.main
    }

    private static func flashScreen(color: NSColor, displayID: CGDirectDisplayID? = nil) {
        guard let screen = screen(for: displayID) else { return }

        let flashWindow = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        flashWindow.level = .screenSaver
        flashWindow.backgroundColor = color
        flashWindow.isOpaque = false
        flashWindow.ignoresMouseEvents = true
        flashWindow.orderFront(nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            flashWindow.orderOut(nil)
        }
    }
}
