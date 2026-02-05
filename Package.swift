// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AudioKitPC",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "AudioKitPC",
            targets: ["AudioKitPC"]
        ),
    ],
    targets: [
        .target(
            name: "AudioKitPC",
            dependencies: []
        ),
        .testTarget(
            name: "AudioKitPCTests",
            dependencies: ["AudioKitPC"]
        ),
    ]
)
