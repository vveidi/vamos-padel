import CoreGraphics

/// The court's thicknesses, all of them absolute.
///
/// - Note: The boards' pixels halved on the watch, which is drawn at 2x, and
///   taken at face value on the phone, which is drawn at 1x.
enum CourtMetrics {
    /// The net's tape — and with it the whole net, since a post is one tape
    /// wide and three tapes long. The one thickness the boards disagree on:
    /// 4px at 2x is 2pt, 3px at 1x is 3pt.
    static var tape: CGFloat { Platform.value(watch: 2, phone: 3) }

    /// One stripe of the weave. Off is twice on — the boards' 2px on, 4px off,
    /// which puts the watch's stripe back on 2 physical pixels at 2x.
    static var weave: CGFloat { Platform.value(watch: 1, phone: 2) }

    /// The boards give the shadow as CSS's `0 3px 9px`, and CSS's blur radius
    /// is about twice SwiftUI's — hence 4.5 on the phone rather than 9.
    static var shadowRadius: CGFloat { Platform.value(watch: 2.5, phone: 4.5) }

    static var shadowOffset: CGFloat { Platform.value(watch: 1.5, phone: 3) }
}
