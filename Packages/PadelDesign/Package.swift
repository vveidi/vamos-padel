// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PadelDesign",
    // macOS is here for the same reason as in the neighboring packages: the
    // palette, the radii and the ramp are values, and a value can be checked
    // natively, without a simulator. Building for the Mac is also what gives
    // the package an index, and with it `hover` and `goToDefinition`.
    // The Mac is v15 and not v14 because of `Group(subviews:)`, which is what
    // lets `SettingsCard` put a divider between two rows it was handed and not
    // at the ends. It shipped alongside iOS 18 and watchOS 11 — the two this
    // package already required — under the Mac's own version number.
    platforms: [
        .iOS(.v18),
        .watchOS(.v11),
        .macOS(.v15),
    ],
    products: [
        .library(name: "PadelDesign", targets: ["PadelDesign"])
    ],
    // `PadelScoring` and nothing else. The design knows the domain — a court
    // half has to be told whose it is — and the domain never hears about the
    // design (ADR-0006).
    dependencies: [
        .package(path: "../PadelScoring")
    ],
    targets: [
        .target(
            name: "PadelDesign",
            dependencies: [
                .product(name: "PadelScoring", package: "PadelScoring")
            ]),
        .testTarget(name: "PadelDesignTests", dependencies: ["PadelDesign"]),
    ]
)
