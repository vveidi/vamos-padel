import SwiftUI

/// One half of the court, seen from above: the surface and the weave over it.
///
/// - Important: No painted lines, and no identity of its own — ADR-0012. It
///   draws no net either; the net belongs to ``Court``.
public struct CourtHalf: View {
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    public init() {}

    public var body: some View {
        Rectangle()
            .fill(Color.courtSurface(dimmed: isLuminanceReduced))
            .overlay { weave }
    }

    private var weave: some View {
        Weave(stripe: CourtMetrics.weave)
            .fill(Color.courtWeave(dimmed: isLuminanceReduced))
            // The stripes are cut from a square large enough to still cover
            // the half once it is turned, so they run well past its edges.
            .clipped()
    }
}

// MARK: - The weave

/// The court's texture: fine diagonal stripes, on for one and off for two.
///
/// One path of bars because SwiftUI has no repeating gradient. The boards'
/// `repeating-linear-gradient(115deg, …)` puts the stripes 25° off vertical.
struct Weave: Shape {
    /// The width of one stripe; the gap after it is twice as wide.
    let stripe: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // A square with the rect's diagonal for a side still covers it once
        // turned, whatever the angle: the rect's corners are half a diagonal
        // from its center, and that is the square's inscribed circle.
        let reach = (rect.width * rect.width + rect.height * rect.height).squareRoot()
        let period = stripe * 3

        for step in 0...Int((reach / period).rounded(.up)) {
            path.addRect(
                CGRect(
                    x: -reach / 2 + CGFloat(step) * period,
                    y: -reach / 2,
                    width: stripe,
                    height: reach))
        }

        return
            path
            .applying(CGAffineTransform(rotationAngle: CGFloat(Angle.degrees(25).radians)))
            .applying(CGAffineTransform(translationX: rect.midX, y: rect.midY))
    }
}
