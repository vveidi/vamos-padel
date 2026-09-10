import SwiftUI

/// The three gradients the design is lit with.
///
/// Tokens rather than shapes. A `Gradient` is a list of stops and nothing
/// else — where it starts, which corner it falls from and how far it reaches
/// belong to the view drawing it, and that view is ticket 02's
/// `Floodlight(corner:)`, `NightScrim(edge:)` and `CourtTile`. What lives here
/// is the part that must not change between the six boards: the color and the
/// weights.
extension Gradient {
    /// Warm white spilling in from one corner of the court.
    ///
    /// The boards vary it between 0.12 and 0.17 depending on how much court
    /// the corner has to cross, and it is gone by roughly two thirds of the
    /// way — hence the stop at 0.62 rather than at 1.
    ///
    /// It is *light*, not a hue. If it starts reading as a second accent it is
    /// too strong, and the fix is `strength`, never a warmer color: the app
    /// has one color and it is the ball (ADR-0006).
    public static func floodlight(strength: Double = 0.14) -> Gradient {
        Gradient(stops: [
            .init(color: .floodlight.opacity(strength), location: 0),
            .init(color: .floodlight.opacity(0), location: 0.62),
        ])
    }

    /// `night` fading in, so the court can run full bleed *under* a floating
    /// control and the control stays legible.
    ///
    /// Written for the bottom edge, where the boards use it four times out of
    /// five. The top-edge variant is this gradient reversed, not a second one:
    /// ticket 02's `NightScrim(edge:)` flips the stops rather than defining
    /// its own.
    public static let nightScrim = Gradient(stops: [
        .init(color: .night.opacity(0), location: 0),
        .init(color: .night.opacity(0.82), location: 0.46),
        .init(color: .night.opacity(0.95), location: 1),
    ])

    /// The soft `ball` glow a won match carries in the corner of its tile.
    ///
    /// The one place the accent appears as light rather than as a mark. It
    /// says *this one was yours* before a number has been read, which is the
    /// whole argument of the history screen's tints.
    public static let ballGlow = Gradient(stops: [
        .init(color: .ball.opacity(0.16), location: 0),
        .init(color: .ball.opacity(0), location: 0.7),
    ])
}
