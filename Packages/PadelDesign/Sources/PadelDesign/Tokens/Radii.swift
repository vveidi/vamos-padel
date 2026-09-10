import CoreGraphics

/// The corner radii, named for what they wrap.
///
/// Not for their size. `.card` survives a designer deciding that a card is
/// rounder; `.r24` does not, and by the second such decision half the screens
/// are wrapping their cards in `.r20`.
///
/// They resolve per platform because the watch boards are drawn at 2x and the
/// phone boards at 1x — see the spec's "Reading the boards". Layout and
/// proportion transfer from the boards; the numbers are halved on the wrist.
///
/// They hang off `CGFloat` so that a call site reads
/// `RoundedRectangle(cornerRadius: .card)`. On Apple's 64-bit platforms
/// `CGFloat` is its own struct rather than a name for `Double`, so this adds
/// nothing to plain numbers — only to the places that already wanted a radius.
extension CGFloat {
    /// The translucent group that replaced `List`'s section — ticket 03's
    /// `SettingsCard`.
    public static var card: CGFloat { Platform.value(watch: 11, phone: 24) }

    /// A match in the history, cut from the court — ticket 03's `CourtTile`.
    public static var tile: CGFloat { Platform.value(watch: 12, phone: 24) }

    /// The primary action at the foot of a screen — ticket 03's `PillButton`.
    ///
    /// Rounded, not a capsule: the boards give it a radius well short of half
    /// its height, and at 64pt tall a capsule would read as a lozenge.
    public static var button: CGFloat { Platform.value(watch: 10, phone: 22) }

    /// One side of a two-way choice — ticket 03's `SegmentedChoice`.
    public static var segment: CGFloat { Platform.value(watch: 9, phone: 20) }
}
