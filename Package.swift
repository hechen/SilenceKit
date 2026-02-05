// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SilenceKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "SilenceKit",
            targets: ["SilenceKit"]
        ),
    ],
    targets: [
        .target(
            name: "SilenceKit",
            dependencies: []
        ),
        .testTarget(
            name: "SilenceKitTests",
            dependencies: ["SilenceKit"]
        ),
    ]
)
