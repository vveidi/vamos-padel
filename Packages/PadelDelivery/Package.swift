// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PadelDelivery",
    // macOS is here for the same reason as in the neighbouring packages: the
    // delivery queue and the parcel format run natively, without a simulator
    // and without a watch-and-phone pair. It also stops WatchConnectivity from
    // compiling anywhere except its own implementation — the single one, hidden
    // behind an `#if`.
    platforms: [
        .iOS(.v18),
        .watchOS(.v11),
        .macOS(.v14),
    ],
    products: [
        .library(name: "PadelDelivery", targets: ["PadelDelivery"])
    ],
    dependencies: [
        .package(path: "../PadelScoring"),
        .package(path: "../PadelStorage"),
    ],
    targets: [
        .target(
            name: "PadelDelivery",
            dependencies: [
                .product(name: "PadelScoring", package: "PadelScoring"),
                .product(name: "PadelStorage", package: "PadelStorage"),
            ]),
        .testTarget(name: "PadelDeliveryTests", dependencies: ["PadelDelivery"]),
    ]
)
