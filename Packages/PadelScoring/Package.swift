// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PadelScoring",
    // macOS is here on purpose: the engine's tests run natively, without a
    // simulator, and it also keeps HealthKit and WatchConnectivity from
    // compiling inside the package.
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
