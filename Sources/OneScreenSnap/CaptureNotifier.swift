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

    public static func notifySuccess(mode: FeedbackMode = .soundAndFlash) {
        NSLog("[OneScreenSnap] notifySuccess mode=\(mode.rawValue)")
        switch mode {
        case .soundAndFlash:
            playShutterSound()
            flashScreen(color: NSColor.white.withAlphaComponent(0.3))
        case .flashOnly:
            flashScreen(color: NSColor.white.withAlphaComponent(0.3))
        case .none:
            break
        }
    }

    public static func notifyFailure(mode: FeedbackMode = .soundAndFlash) {
        // Always show error alert regardless of mode
        if mode != .none {
            NSSound(named: "Basso")?.play()
            flashScreen(color: NSColor.red.withAlphaComponent(0.2))
        }

        let alert = NSAlert()
        alert.messageText = L10n.captureFailedTitle
        alert.informativeText = L10n.captureFailedMessage
        alert.addButton(withTitle: L10n.ok)
        alert.alertStyle = .warning
        alert.runModal()
    }

    private static func flashScreen(color: NSColor) {
        guard let screen = NSScreen.main else { return }

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
