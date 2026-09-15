import SwiftUI

/// Warm white spilling onto the court from one corner. An overlay, so it takes
/// no room from the layout.
public struct Floodlight: View {
    public enum Corner: Sendable, CaseIterable {
        case topLeading
        case topTrailing
        case bottomLeading
        case bottomTrailing

        /// - Warning: Named for the layout's vocabulary, but these unit points
        ///   are literal: the light does not mirror for a right-to-left layout.
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

    public init(corner: Corner, strength: Double = 0.14) {
        self.corner = corner
        self.strength = strength
    }

    public var body: some View {
        // Elliptical rather than radial: a circle centered on the corner of a
        // screen twice as tall as it is wide lights a very different shape.
        // The falloff is the token's, so the reach here is the whole frame.
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
/// control while keeping the control legible. An overlay, so it takes no room
/// from the layout.
public struct NightScrim: View {
    private let edge: VerticalEdge
    private let depth: CGFloat

    /// - Parameter depth: How far in the fade reaches. The default is the
    ///   boards' — about a third of a watch screen, a seventh of a phone.
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

    public static var depth: CGFloat { Platform.value(watch: 75, phone: 130) }
}
