import Foundation
import CoreGraphics

public struct CodableRect: Codable, Equatable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(_ rect: CGRect) {
        self.x = rect.origin.x
        self.y = rect.origin.y
        self.width = rect.size.width
        self.height = rect.size.height
    }

    public var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

public struct RegionPreset: Codable, Equatable {
    public let id: String
    public let displayStableKey: String
    public let rect: CodableRect
    public var shortcut: Shortcut?
    public var name: String

    public init(displayStableKey: String, rect: CGRect, name: String) {
        self.id = UUID().uuidString
        self.displayStableKey = displayStableKey
        self.rect = CodableRect(rect)
        self.shortcut = nil
        self.name = name
    }

    public var summary: String {
        let r = rect.cgRect
        return "\(Int(r.width))×\(Int(r.height)) at (\(Int(r.minX)),\(Int(r.minY)))"
    }
}
