// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OneScreenSnap",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "OneScreenSnapLib",
            path: "Sources/OneScreenSnap",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("ScreenCaptureKit"),
            ]
        ),
        .executableTarget(
            name: "OneScreenSnap",
            dependencies: ["OneScreenSnapLib"],
            path: "Sources/OneScreenSnapApp"
        ),
        .testTarget(
            name: "OneScreenSnapTests",
            dependencies: ["OneScreenSnapLib"],
            path: "Tests"
        ),
    ]
)
