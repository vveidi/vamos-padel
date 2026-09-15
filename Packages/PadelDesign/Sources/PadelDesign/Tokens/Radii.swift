import CoreGraphics

/// The corner radii, named for what they wrap rather than for their size.
///
/// - Note: Halved on the wrist. The watch boards are drawn at 2x and the phone
///   boards at 1x, and layout transfers off a board (`docs/design/README.md`).
extension CGFloat {
    public static var card: CGFloat { Platform.value(watch: 11, phone: 24) }

    public static var tile: CGFloat { Platform.value(watch: 12, phone: 24) }

    /// Rounded, not a capsule: the boards give it a radius well short of half
    /// its height, and at 64pt tall a capsule would read as a lozenge.
    public static var button: CGFloat { Platform.value(watch: 10, phone: 22) }

    public static var segment: CGFloat { Platform.value(watch: 9, phone: 20) }
}
