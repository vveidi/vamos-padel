// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PadelStorage",
    // macOS присутствует по той же причине, что и в PadelScoring: круговой рейс
    // через SQLite гоняется нативно, без симулятора и без устройства.
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
                // Тестам миграций нужна база до того, как её открыло хранилище:
                // иначе «базу предыдущей версии» неоткуда взять.
                .product(name: "GRDB", package: "GRDB.swift"),
            ]),
    ]
)
