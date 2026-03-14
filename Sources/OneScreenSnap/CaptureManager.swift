import AppKit
import ScreenCaptureKit

public final class CaptureManager {

    public init() {}

    public func captureDisplay(_ displayID: CGDirectDisplayID) async -> NSImage? {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
                NSLog("[OneScreenSnap] Display \(displayID) not found in shareable content")
                return nil
            }

            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()
            config.width = Int(display.width) * scaleFactor(for: displayID)
            config.height = Int(display.height) * scaleFactor(for: displayID)
            config.pixelFormat = kCVPixelFormatType_32BGRA
            config.showsCursor = false

            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )
            let size = NSSize(width: display.width, height: display.height)
            return NSImage(cgImage: image, size: size)
        } catch {
            NSLog("[OneScreenSnap] ScreenCaptureKit error: \(error)")
            return nil
        }
    }

    public func captureRect(_ rect: CGRect, displayID: CGDirectDisplayID) async -> NSImage? {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
                return nil
            }

            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()
            let scale = scaleFactor(for: displayID)
            config.width = Int(rect.width) * scale
            config.height = Int(rect.height) * scale
            config.pixelFormat = kCVPixelFormatType_32BGRA
            config.showsCursor = false
            config.sourceRect = rect

            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )
            let size = NSSize(width: rect.width, height: rect.height)
            return NSImage(cgImage: image, size: size)
        } catch {
            NSLog("[OneScreenSnap] ScreenCaptureKit rect capture error: \(error)")
            return nil
        }
    }

    public func captureMultipleRects(_ rects: [(CGRect, CGDirectDisplayID)]) async -> NSImage? {
        var images: [NSImage] = []
        for (rect, displayID) in rects {
            if let image = await captureRect(rect, displayID: displayID) {
                images.append(image)
            }
        }
        guard !images.isEmpty else { return nil }
        return ImageComposer.composeVertically(images)
    }

    /// Resize image for AI consumption (max 1568px on longest side)
    public static func resizeForAI(_ image: NSImage) -> NSImage {
        let maxDimension: CGFloat = 1568
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else { return image }

        let scale: CGFloat
        if size.width > size.height {
            scale = maxDimension / size.width
        } else {
            scale = maxDimension / size.height
        }
        let newSize = NSSize(width: size.width * scale, height: size.height * scale)

        let resized = NSImage(size: newSize)
        resized.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: size),
                   operation: .copy, fraction: 1.0)
        resized.unlockFocus()
        return resized
    }

    private func scaleFactor(for displayID: CGDirectDisplayID) -> Int {
        for screen in NSScreen.screens {
            if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
               screenNumber == displayID {
                return Int(screen.backingScaleFactor)
            }
        }
        return 2 // Default to Retina
    }
}
