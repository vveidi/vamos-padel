// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PadelStorage",
    // macOS is here for the same reason as in PadelScoring: the round trip
    // through SQLite runs natively, without a simulator and without a device.
    platforms: [
        .iOS(.v18),
        .watchOS(.v11),
        .macOS(.v14),
    ],
    products: [
        .library(name: "PadelStorage", targets: ["PadelStorage"])
    ],
    dependencies: [
        .package(path: "../PadelScoring"),
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.11.1"),
    ],
    targets: [
        .target(
            name: "PadelStorage",
            dependencies: [
                .product(name: "PadelScoring", package: "PadelScoring"),
                .product(name: "GRDB", package: "GRDB.swift"),
            ]),
        .testTarget(
            name: "PadelStorageTests",
            dependencies: [
                "PadelStorage",
                // The migration tests need a database before the store has
                // opened it: otherwise there is nowhere to get a "database of
                // the previous version" from.
                .product(name: "GRDB", package: "GRDB.swift"),
            ]),
    ]
)
