// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ax-inspector",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "ax-inspector", path: "Sources"),
    ]
)
