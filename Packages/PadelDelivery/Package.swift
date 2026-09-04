// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PadelDelivery",
    // macOS присутствует по той же причине, что и в соседних пакетах: очередь
    // на доставку и формат посылки гоняются нативно, без симулятора и без
    // пары «часы — телефон». Заодно WatchConnectivity перестаёт компилиро-
    // ваться везде, кроме своей реализации, — она одна и спрятана за `#if`.
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
