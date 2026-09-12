import PadelScoring
import SwiftUI

/// One half of the court, seen from above: the tinted surface, the weave over
/// it, and the three lines painted on it.
///
/// **One view with a side, and not two views that look alike.** The two halves
/// are the same court seen from our end — theirs at the top because that is
/// where it is when you stand on court — so ours is theirs mirrored, and the
/// mirror lives in ``PaintedLine`` where there is exactly one of it. Written
/// as two views, the day the service line moves it moves in one of them.
///
/// It draws no net. The net is the half's fourth edge and belongs to whatever
/// puts two halves together — ``Court``, or a screen that wants the halves
/// filled with something.
///
/// Nothing in it knows what a rally is. A screen lays its own content over the
/// half with `.overlay`, which is why there is no content parameter here.
public struct CourtHalf: View {
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    private let side: Side

    public init(side: Side) {
        self.side = side
    }

    public var body: some View {
        Rectangle()
            .fill(Color.courtSurface(side, dimmed: isLuminanceReduced))
            .overlay { weave }
            .overlay { lines }
    }

    /// The surface texture.
    ///
    /// Its own layer, and so is the light a screen puts over it: both go out
    /// when the screen's luminance drops, and that could only be done without
    /// unpicking the geometry because the geometry was never mixed into them.
    private var weave: some View {
        Weave(stripe: CourtMetrics.weave)
            .fill(Color.courtWeave(on: side, dimmed: isLuminanceReduced))
            // The stripes are cut from a square large enough to still cover
            // the half once it is turned, so they run well past its edges.
            .clipped()
    }

    private var lines: some View {
        ZStack {
            ForEach(CourtLine.allCases, id: \.self) { line in
                PaintedLine(line, on: side)
                    .fill(Color.courtLine(line, on: side, dimmed: isLuminanceReduced))
            }
        }
    }
}

// MARK: - The lines

/// One of the three painted lines, as the area it covers on its half.
///
/// Every line is built as though it were on **their** half — outer edge at the
/// top, net at the bottom — and ours is that path flipped. That is the whole
/// of the mirror, in one place, applying to all three lines at once.
///
/// A filled path rather than a stroked one, so that the flip has one kind of
/// path to act on and the caller has one way to paint it.
struct PaintedLine: Shape {
    private let line: CourtLine
    private let side: Side

    init(_ line: CourtLine, on side: Side) {
        self.line = line
        self.side = side
    }

    func path(in rect: CGRect) -> Path {
        let path = fromTheirEnd(in: rect)

        switch side {
        case .them:
            return path
        case .us:
            return path.applying(
                CGAffineTransform(scaleX: 1, y: -1)
                    .concatenating(CGAffineTransform(translationX: 0, y: rect.height)))
        }
    }

    /// The line on a half whose outer edge is the top and whose net is the
    /// bottom.
    private func fromTheirEnd(in rect: CGRect) -> Path {
        let thickness = CourtMetrics.line
        let service = rect.height * CourtMetrics.serviceLine

        switch line {
        case .service:
            return Path(
                CGRect(x: 0, y: service, width: rect.width, height: thickness))

        case .center:
            // From the service line to the net, which is 70% of the half. It
            // divides the two service boxes and has no business running past
            // them into the back of the court.
            return Path(
                CGRect(
                    x: rect.midX - thickness / 2,
                    y: service,
                    width: thickness,
                    height: rect.height - service))

        case .outline:
            // Three sides and no fourth: the net is the court's far edge, and
            // a line drawn along it would only thicken the tape.
            //
            // Inset by half the thickness on top of the margin so the stroke
            // lands inside it, the way a CSS border does.
            let inset = CourtMetrics.outlineInset + thickness / 2

            var path = Path()
            path.move(to: CGPoint(x: inset, y: rect.height))
            path.addLine(to: CGPoint(x: inset, y: inset))
            path.addLine(to: CGPoint(x: rect.width - inset, y: inset))
            path.addLine(to: CGPoint(x: rect.width - inset, y: rect.height))

            return path.strokedPath(StrokeStyle(lineWidth: thickness))
        }
    }
}

// MARK: - The weave

/// The court's texture: fine diagonal stripes, on for one and off for two.
///
/// Texture and not pattern. At a glance it has to read as a surface rather
/// than as stripes, which is why the ink is thousandths of white and not
/// hundredths — see ``SwiftUI/Color/courtWeave(on:dimmed:)``.
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
