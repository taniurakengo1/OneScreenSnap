// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "clipboard-info",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "clipboard-info", path: "Sources"),
    ]
)
