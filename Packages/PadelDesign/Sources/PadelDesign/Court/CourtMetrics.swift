import CoreGraphics

/// The court's thicknesses.
///
/// Everything here is absolute, because everything left here is a thickness: a
/// shape 0.5% of the screen wide is a shape nobody can see on a wrist. They
/// resolve per platform the way the radii do — the boards' pixels halved on
/// the watch, which is drawn at 2x, and taken at face value on the phone,
/// which is drawn at 1x.
///
/// The one proportion it used to hold was the service line's, and the lines
/// were deleted along with the shape they were measured in — see
/// ``CourtHalf``.
enum CourtMetrics {
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
