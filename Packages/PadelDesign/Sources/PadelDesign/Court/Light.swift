import SwiftUI

/// Warm white spilling onto the court from one corner.
///
/// It is a **light and not a hue**. The app has one color and it is the ball
/// (ADR-0006); the moment this reads as a second accent it is too strong, and
/// the fix is ``init(corner:strength:)``'s `strength`, never a warmer color.
///
/// **An overlay, and it takes no room from the layout.** The same argument
/// `ScoreView` makes about the serve indicator — "an overlay is the whole of
/// that guarantee" — applies here for the same reason: the court beneath it is
/// full-bleed, and a light that pushed it around would be a light that changed
/// where the net is.
///
/// ```swift
/// CourtHalf()
///     .overlay { Floodlight(corner: .bottomTrailing) }
/// ```
public struct Floodlight: View {
    /// The corner the light comes in from.
    ///
    /// It varies by board — top leading on the watch's start screen, bottom
    /// trailing on the score screens, top trailing on the history — so it is
    /// passed in rather than chosen here.
    ///
    /// Leading and trailing because that is the vocabulary the layout around
    /// it uses. The unit points are literal, and a light spilling across a
    /// court has no reading direction to mirror for.
    public enum Corner: Sendable, CaseIterable {
        case topLeading
        case topTrailing
        case bottomLeading
        case bottomTrailing

        var unitPoint: UnitPoint {
            switch self {
            case .topLeading: .topLeading
            case .topTrailing: .topTrailing
            case .bottomLeading: .bottomLeading
            case .bottomTrailing: .bottomTrailing
            }
        }
    }

    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    private let corner: Corner
    private let strength: Double

    /// - Parameter strength: How much light. The boards spend between 0.12 and
    ///   0.17 depending on how much court the corner has to cross.
    public init(corner: Corner, strength: Double = 0.14) {
        self.corner = corner
        self.strength = strength
    }

    public var body: some View {
        // Elliptical rather than radial: the boards give the light a width and
        // a height of its own, and a circle centered on the corner of a screen
        // twice as tall as it is wide lights a very different shape.
        //
        // The falloff is the token's, not this view's — `floodlight` is clear
        // by 62% of the way — so the reach here is the whole of the frame.
        EllipticalGradient(
            gradient: .floodlight(strength: strength),
            center: corner.unitPoint,
            startRadiusFraction: 0,
            endRadiusFraction: 1)
            // Opacity rather than an `if`, so the view keeps its identity and
            // the system's own crossfade is the only thing that animates.
            .opacity(isLuminanceReduced ? 0 : 1)
            .allowsHitTesting(false)
    }
}

/// The `night` gradient that lets the court run full bleed *under* a floating
/// control while keeping the control legible.
///
/// The alternative is a solid bar behind the buttons, which puts the court's
/// bottom edge back on the screen — and a court with an edge is a picture of a
/// court rather than the ground the app stands on.
///
/// **An overlay, and it takes no room from the layout**, for the same reason
/// ``Floodlight`` is one.
///
/// ```swift
/// Court()
///     .overlay(alignment: .bottom) { NightScrim(edge: .bottom) }
/// ```
public struct NightScrim: View {
    private let edge: VerticalEdge
    private let depth: CGFloat

    /// - Parameters:
    ///   - edge: Which end of the court fades. Bottom on the four boards with
    ///     buttons over the court, top on the phone's score board, where what
    ///     floats is the ruleset and the clock.
    ///   - depth: How far in the fade reaches. The default is the boards',
    ///     which is about a third of a watch screen and about a seventh of a
    ///     phone — the fade covers a control, and a control is nearly the same
    ///     size on both.
    public init(edge: VerticalEdge, depth: CGFloat = NightScrim.depth) {
        self.edge = edge
        self.depth = depth
    }

    public var body: some View {
        LinearGradient(
            gradient: .nightScrim,
            startPoint: edge == .bottom ? .top : .bottom,
            endPoint: edge == .bottom ? .bottom : .top)
            .frame(height: depth)
            // Pinned to its edge of whatever it is laid over, and flexible
            // against the rest of it: in an overlay that is the parent's
            // height, and the band sits at one end of it.
            .frame(maxHeight: .infinity, alignment: edge == .bottom ? .bottom : .top)
            .allowsHitTesting(false)
    }

    /// The default ``init(edge:depth:)`` depth.
    public static var depth: CGFloat { Platform.value(watch: 75, phone: 130) }
}
