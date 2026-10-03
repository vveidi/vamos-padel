// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PadelLogging",
    // macOS is here so the store's tests run natively, without a simulator.
    platforms: [
        .iOS(.v18),
        .watchOS(.v11),
        .macOS(.v15),
    ],
    products: [
        .library(name: "PadelLogging", targets: ["PadelLogging"])
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Pulse", .upToNextMinor(from: "5.2.0"))
    ],
    targets: [
        .target(
            name: "PadelLogging",
            dependencies: [
                .product(name: "Pulse", package: "Pulse")
            ]),
        .testTarget(
            name: "PadelLoggingTests",
            dependencies: [
                "PadelLogging",
                .product(name: "Pulse", package: "Pulse"),
            ]),
    ]
)
