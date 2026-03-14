import AppKit
import CoreGraphics

public final class RegionSelectionOverlay {
    public typealias Completion = (CGRect, DisplayInfo) -> Void

    private var windows: [NSWindow] = []
    private var completion: Completion?
    private var displays: [DisplayInfo]

    public init(displays: [DisplayInfo]) {
        self.displays = displays
    }

    public func start(completion: @escaping Completion) {
        self.completion = completion

        for display in displays {
            let screenFrame = screenFrame(for: display)
            let window = NSWindow(
                contentRect: screenFrame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            window.level = .screenSaver
            window.isOpaque = false
            window.backgroundColor = NSColor.black.withAlphaComponent(0.3)
            window.ignoresMouseEvents = false
            window.acceptsMouseMovedEvents = true
            window.hasShadow = false

            let selectionView = RegionSelectionView(frame: screenFrame)
            selectionView.display = display
            selectionView.onSelectionComplete = { [weak self] rect, displayInfo in
                self?.finishSelection(rect: rect, display: displayInfo)
            }
            selectionView.onCancel = { [weak self] in
                self?.cancel()
            }
            window.contentView = selectionView

            window.makeKeyAndOrderFront(nil)
            windows.append(window)
        }

        NSCursor.crosshair.push()
    }

    private func screenFrame(for display: DisplayInfo) -> NSRect {
        for screen in NSScreen.screens {
            if let num = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
               num == display.id {
                return screen.frame
            }
        }
        return NSRect(origin: .zero, size: NSSize(width: display.bounds.width, height: display.bounds.height))
    }

    private func finishSelection(rect: CGRect, display: DisplayInfo) {
        cleanup()
        // Convert from screen coordinates to display-local coordinates
        let displayFrame = screenFrame(for: display)
        let localRect = CGRect(
            x: rect.origin.x - displayFrame.origin.x,
            y: displayFrame.height - (rect.origin.y - displayFrame.origin.y) - rect.height,
            width: rect.width,
            height: rect.height
        )
        completion?(localRect, display)
    }

    private func cancel() {
        cleanup()
    }

    private func cleanup() {
        NSCursor.pop()
        for w in windows {
            w.orderOut(nil)
        }
        windows.removeAll()
    }
}

// MARK: - RegionSelectionView

private final class RegionSelectionView: NSView {
    var display: DisplayInfo?
    var onSelectionComplete: ((CGRect, DisplayInfo) -> Void)?
    var onCancel: (() -> Void)?

    private var dragStart: NSPoint?
    private var dragCurrent: NSPoint?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func mouseDown(with event: NSEvent) {
        dragStart = event.locationInWindow
        dragCurrent = dragStart
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        dragCurrent = event.locationInWindow
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let start = dragStart, let current = dragCurrent, let display = display else { return }
        let rect = rectFromPoints(start, current)
        if rect.width > 10 && rect.height > 10 {
            // Convert to screen coordinates
            let screenRect = window?.convertToScreen(rect) ?? rect
            onSelectionComplete?(screenRect, display)
        }
        dragStart = nil
        dragCurrent = nil
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 0x35 { // Escape
            onCancel?()
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        // Dim background
        NSColor.black.withAlphaComponent(0.3).setFill()
        dirtyRect.fill()

        guard let start = dragStart, let current = dragCurrent else {
            // Draw instruction text
            let text = L10n.regionSelectionHint
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 18, weight: .medium),
                .foregroundColor: NSColor.white
            ]
            let str = NSAttributedString(string: text, attributes: attrs)
            let size = str.size()
            let x = (bounds.width - size.width) / 2
            let y = (bounds.height - size.height) / 2
            str.draw(at: NSPoint(x: x, y: y))
            return
        }

        let rect = rectFromPoints(start, current)

        // Clear the selected region (make it transparent)
        NSColor.clear.setFill()
        rect.fill(using: .copy)

        // Draw selection border
        NSColor.systemBlue.setStroke()
        let path = NSBezierPath(rect: rect)
        path.lineWidth = 2
        path.stroke()

        // Draw size label
        let sizeText = "\(Int(rect.width)) × \(Int(rect.height))"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.black.withAlphaComponent(0.7)
        ]
        let str = NSAttributedString(string: " \(sizeText) ", attributes: attrs)
        let labelY = rect.minY - 24
        str.draw(at: NSPoint(x: rect.minX, y: max(0, labelY)))
    }

    private func rectFromPoints(_ p1: NSPoint, _ p2: NSPoint) -> NSRect {
        NSRect(
            x: min(p1.x, p2.x),
            y: min(p1.y, p2.y),
            width: abs(p2.x - p1.x),
            height: abs(p2.y - p1.y)
        )
    }
}
