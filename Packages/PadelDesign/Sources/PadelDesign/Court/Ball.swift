import SwiftUI

/// The ball: a felt circle with two seams curving in from its edges.
///
/// - Note: It knows nothing about a serve. Which corner a ball belongs in is
///   domain knowledge wearing layout's clothes, and it stays in `ScoreView`.
public struct Ball: View {
    public enum Finish: Sendable, CaseIterable {
        case onCourt

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
        // corner and at 34pt on a phone. The fractions are the three boards'
        // shadows divided by the three boards' balls, which agree.
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
    var seam: Color {
        switch self {
        case .onCourt: .ballSeam
        case .cutOut: .ballSeamCutOut
        }
    }

    var castsShadow: Bool { self == .onCourt }
}

// MARK: - The seams

/// The ball's two seams, off the boards' SVG: `M3.6 4.3 c 3.9 3 3.9 12.4 0
/// 15.4` and its mirror at x = 20.4, in the same 24-unit box.
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

        // The stroke is applied outside, in the view's own points, so the seam
        // stays 1.5 units wide at every size instead of being scaled twice.
        return path.applying(
            CGAffineTransform(scaleX: rect.width / 24, y: rect.height / 24))
    }
}
