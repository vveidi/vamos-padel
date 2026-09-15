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
        .library(name: "PadelStorage", targets: ["PadelStorage"]),
        .library(name: "PadelStorageDatabase", targets: ["PadelStorageDatabase"]),
    ],
    dependencies: [
        .package(path: "../PadelScoring"),
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.11.1"),
    ],
    targets: [
        // `PadelStorage` is the interface — the protocols and `SavedMatch`,
        // with no database in its graph. `PadelStorageDatabase` is the one
        // implementation behind it. Both live under the one source folder, so
        // each names its half with a `path:`.
        .target(
            name: "PadelStorage",
            dependencies: [
                .product(name: "PadelScoring", package: "PadelScoring")
            ],
            path: "Sources/PadelStorage/Interface"),
        .target(
            name: "PadelStorageDatabase",
            dependencies: [
                "PadelStorage",
                .product(name: "PadelScoring", package: "PadelScoring"),
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "Sources/PadelStorage/Database"),
        .testTarget(
            name: "PadelStorageTests",
            dependencies: [
                "PadelStorage",
                "PadelStorageDatabase",
                // The migration tests need a database before the store has
                // opened it: otherwise there is nowhere to get a "database of
                // the previous version" from.
                .product(name: "GRDB", package: "GRDB.swift"),
            ]),
    ]
)
