// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TypedNetwork",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "TypedNetwork",
            targets: ["TypedNetwork"]
        ),
    ],
    targets: [
        .target(
            name: "TypedNetwork",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "TypedNetworkTests",
            dependencies: ["TypedNetwork"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
    ]
)
