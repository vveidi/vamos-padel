import SwiftUI

/// The ball: a felt circle with two seams curving in from its edges.
///
/// Drawn rather than borrowed. `Image(systemName: "tennisball.fill")` is the
/// system's ball, and the system's ball has the system's proportions, the
/// system's seam and the system's opinion about what a sports icon looks like
/// — which is the whole of what this design is not.
///
/// It is the app's one character and it means one thing: *this is yours, or
/// this is chosen* (ADR-0006). It waits on the net before the match, sits in
/// the serving half's corner during play, and rides the primary button, and it
/// has to be the same object at 10pt and at 34pt — hence a path scaled to the
/// frame rather than an asset.
///
/// It knows nothing about a serve. Which corner a ball belongs in is domain
/// knowledge wearing layout's clothes, and it stays in `ScoreView`.
public struct Ball: View {
    /// Which way round the ball is drawn.
    public enum Finish: Sendable, CaseIterable {
        /// Yellow felt, dark seams, and a shadow under it. The ball on the
        /// court.
        case onCourt

        /// Dark felt, yellow seams, and no shadow. The ball cut out of a
        /// `ball`-yellow button, which is the one place the court's own ball
        /// would be a yellow circle on a yellow ground.
        case cutOut
    }

    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    private let size: CGFloat
    private let finish: Finish

    public init(size: CGFloat, finish: Finish = .onCourt) {
        self.size = size
        self.finish = finish
    }

    public var body: some View {
        ZStack {
            // The felt stops one unit short of the frame — the boards' circle
            // is r 11 in a 24-unit box — which is what leaves the seams room
            // to run right to the ball's edge.
            Circle()
                .fill(Color.ballFelt(finish, dimmed: isLuminanceReduced))
                .padding(size / Self.box)

            Seams()
                .stroke(
                    finish.seam,
                    style: StrokeStyle(lineWidth: size * 1.5 / Self.box, lineCap: .round))
        }
        .frame(width: size, height: size)
        // Proportions and not points: the ball is drawn at 10pt in a score
        // corner and at 34pt on a phone, and a fixed shadow would be a halo
        // under one and invisible under the other. The fractions are the three
        // boards' shadows divided by the three boards' balls, which agree.
        // A dimmed screen gets none: the lift is atmosphere, the corner is not.
        .shadow(
            color: finish.castsShadow && !isLuminanceReduced ? .shadow : .clear,
            radius: size * 0.175,
            y: size * 0.15)
    }

    /// The side of the box the boards' SVG is drawn in. Every number in this
    /// view is a fraction of it.
    private static let box: CGFloat = 24
}

extension Ball.Finish {
    /// The two seams. Dark green on the court — emphatically not `onBall`,
    /// which is nearly black and turns the ball into a beach ball — and the
    /// ball's own yellow when the felt is the dark one.
    var seam: Color {
        switch self {
        case .onCourt: .ballSeam
        case .cutOut: .ballSeamCutOut
        }
    }

    /// Whether the ball is lifted off what it sits on.
    ///
    /// A cut-out is a hole in a button rather than an object on a surface, and
    /// there is nothing under it to cast onto.
    var castsShadow: Bool { self == .onCourt }
}

// MARK: - The seams

/// The ball's two seams, off the boards' SVG.
///
/// `M3.6 4.3 c 3.9 3 3.9 12.4 0 15.4` and its mirror at x = 20.4: two cubic
/// curves that enter near the top of the ball, bow toward the middle and leave
/// near the bottom. That is a ball seen head-on, where the seam that wraps it
/// shows as two arcs and never as a cross or a single line.
private struct Seams: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 3.6, y: 4.3))
        path.addCurve(
            to: CGPoint(x: 3.6, y: 19.7),
            control1: CGPoint(x: 7.5, y: 7.3),
            control2: CGPoint(x: 7.5, y: 16.7))

        path.move(to: CGPoint(x: 20.4, y: 4.3))
        path.addCurve(
            to: CGPoint(x: 20.4, y: 19.7),
            control1: CGPoint(x: 16.5, y: 7.3),
            control2: CGPoint(x: 16.5, y: 16.7))

        // The path is written in the board's 24-unit box and scaled to
        // whatever frame it is handed. The stroke is not — `stroke` is applied
        // outside, in the view's own points, so the seam stays 1.5 units wide
        // at every size instead of being scaled twice.
        return path.applying(
            CGAffineTransform(scaleX: rect.width / 24, y: rect.height / 24))
    }
}
