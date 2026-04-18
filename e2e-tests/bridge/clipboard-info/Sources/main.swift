import AppKit
import Foundation

struct ClipboardInfo: Codable {
    let hasImage: Bool
    let width: Int
    let height: Int
    let format: String
    let bytesPerRow: Int
}

let pasteboard = NSPasteboard.general

let types = pasteboard.types ?? []
let hasImage = types.contains(.tiff) || types.contains(.png)

var info = ClipboardInfo(hasImage: false, width: 0, height: 0, format: "none", bytesPerRow: 0)

if hasImage, let imageData = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png) {
    if let image = NSImage(data: imageData) {
        if let rep = image.representations.first as? NSBitmapImageRep {
            let format: String
            if types.contains(.png) {
                format = "PNG"
            } else {
                format = "TIFF"
            }
            info = ClipboardInfo(
                hasImage: true,
                width: rep.pixelsWide,
                height: rep.pixelsHigh,
                format: format,
                bytesPerRow: rep.bytesPerRow
            )
        } else if let rep = image.representations.first {
            info = ClipboardInfo(
                hasImage: true,
                width: Int(rep.pixelsWide),
                height: Int(rep.pixelsHigh),
                format: "TIFF",
                bytesPerRow: 0
            )
        }
    }
}

let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
if let data = try? encoder.encode(info), let json = String(data: data, encoding: .utf8) {
    print(json)
}
