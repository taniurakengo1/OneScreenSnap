import AppKit

public enum ImageComposer {

    /// Compose multiple images vertically into a single image
    public static func composeVertically(_ images: [NSImage]) -> NSImage? {
        guard !images.isEmpty else { return nil }
        if images.count == 1 { return images[0] }

        let totalWidth = images.map { $0.size.width }.max() ?? 0
        let totalHeight = images.map { $0.size.height }.reduce(0, +)
        let spacing: CGFloat = 4

        let composedSize = NSSize(
            width: totalWidth,
            height: totalHeight + spacing * CGFloat(images.count - 1)
        )

        let composedImage = NSImage(size: composedSize)
        composedImage.lockFocus()

        var yOffset: CGFloat = composedSize.height
        for image in images {
            yOffset -= image.size.height
            image.draw(
                in: NSRect(x: 0, y: yOffset, width: image.size.width, height: image.size.height),
                from: .zero,
                operation: .copy,
                fraction: 1.0
            )
            yOffset -= spacing
        }

        composedImage.unlockFocus()
        return composedImage
    }
}
