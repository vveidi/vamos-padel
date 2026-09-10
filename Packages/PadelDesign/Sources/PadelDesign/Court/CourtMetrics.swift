import CoreGraphics

/// The court's proportions, and the few thicknesses that cannot be one.
///
/// The geometry is **fractions of the half it is drawn in**, because the same
/// court is drawn on a 198pt watch screen and on a 393pt phone, and a table of
/// numbers for each is how the two drift apart.
///
/// What stays absolute is thickness. A line 0.5% of the screen wide is a line
/// nobody can see on a wrist, so the thicknesses resolve per platform the way
/// the radii do: the boards' pixels halved on the watch, which is drawn at 2x,
/// and taken at face value on the phone, which is drawn at 1x.
enum CourtMetrics {
    /// Where the service line crosses its half, measured from the half's
    /// **outer** edge — the top of their half, the bottom of ours.
    ///
    /// One number for both, because the halves are one court seen from our
    /// end. ``PaintedLine`` mirrors rather than measuring twice.
    static let serviceLine: CGFloat = 0.3

    /// A painted line. 2px on both boards.
    static var line: CGFloat { Platform.value(watch: 1, phone: 2) }

    /// How far inside the half the outline runs, on the three sides it has.
    static var outlineInset: CGFloat { Platform.value(watch: 5, phone: 10) }

    /// The net's tape — and with it the whole net, since a post is one tape
    /// wide and three tapes long.
    ///
    /// The one thickness the boards do not agree on: 4px at the watch's 2x is
    /// 2pt, 3px at the phone's 1x is 3pt. The net is proportionally heavier on
    /// the small screen, which is the right way round.
    static var tape: CGFloat { Platform.value(watch: 2, phone: 3) }

    /// One stripe of the weave. Off is twice on — the boards' 2px on, 4px off.
    ///
    /// The watch takes the board's pixels halved, which lands the stripe back
    /// on 2 physical pixels at 2x: exactly what the board draws. Whether a
    /// stripe that fine survives a wrist is a question for a device and not
    /// for a canvas, and coarsening it is one number here.
    static var weave: CGFloat { Platform.value(watch: 1, phone: 2) }

    /// The blur under the net, in SwiftUI's terms.
    ///
    /// The boards give the shadow as CSS's `0 3px 9px`, and CSS's blur radius
    /// is about twice SwiftUI's — hence 4.5 on the phone rather than 9.
    static var shadowRadius: CGFloat { Platform.value(watch: 2.5, phone: 4.5) }

    /// How far the shadow falls below what casts it.
    static var shadowOffset: CGFloat { Platform.value(watch: 1.5, phone: 3) }
}
