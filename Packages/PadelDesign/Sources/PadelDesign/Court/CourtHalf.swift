import SwiftUI

/// One half of the court, seen from above: the surface and the weave over it.
///
/// **The painted lines were removed on purpose, and this is where the argument
/// lives.** A real padel half is 10m by 10m — square — and the half drawn here
/// is a letterbox, 198pt wide and about 120pt deep on a watch. Every line put
/// at its correct *fraction* of the half therefore landed in the right
/// fraction of the wrong shape: the service boxes came out as letterboxes and
/// the line a player looks for was nowhere near where they look. The outline
/// was worse than misplaced — it was a tennis import, because a padel court's
/// edge is glass and mesh and a painted sideline inside the half draws a
/// boundary that does not exist. Neither re-placing the lines nor thinning
/// them fixes that; the half is not a court to scale and cannot be made into
/// one. A service line written back here would be the same mistake a second
/// time.
///
/// **One view and not two.** Both halves are the same surface; which one is
/// ours is said by position — theirs above the net, ours below — and by the
/// net between them, which is what ``Court`` puts there.
///
/// It draws no net. The net is the half's fourth edge and belongs to whatever
/// puts two halves together — ``Court``, or a screen that wants the halves
/// filled with something.
///
/// Nothing in it knows what a rally is. A screen lays its own content over the
/// half with `.overlay`, which is why there is no content parameter here.
public struct CourtHalf: View {
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    public init() {}

    public var body: some View {
        Rectangle()
            .fill(Color.courtSurface(dimmed: isLuminanceReduced))
            .overlay { weave }
    }

    /// The surface texture.
    ///
    /// Its own layer, and so is the light a screen puts over it: both go out
    /// when the screen's luminance drops, and that could only be done without
    /// unpicking the geometry because the geometry was never mixed into them.
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
/// Texture and not pattern. At a glance it has to read as a surface rather
/// than as stripes, which is why the ink is thousandths of white and not
/// hundredths — see ``SwiftUI/Color/courtWeave(dimmed:)``.
///
/// Drawn as one path of bars because SwiftUI has no repeating gradient. The
/// boards' `repeating-linear-gradient(115deg, …)` runs its gradient at 115°,
/// so the stripes stand square to that, 25° off vertical.
struct Weave: Shape {
    /// The width of one stripe. The gap after it is twice as wide.
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
