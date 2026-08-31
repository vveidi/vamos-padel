// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PadelScoring",
    // macOS присутствует намеренно: тесты движка гоняются нативно, без симулятора,
    // и заодно HealthKit с WatchConnectivity перестают компилироваться в пакете.
    platforms: [
        .iOS(.v18),
        .watchOS(.v11),
        .macOS(.v14),
    ],
    products: [
        .library(name: "PadelScoring", targets: ["PadelScoring"])
    ],
    targets: [
        .target(name: "PadelScoring"),
        .testTarget(name: "PadelScoringTests", dependencies: ["PadelScoring"]),
    ]
)
