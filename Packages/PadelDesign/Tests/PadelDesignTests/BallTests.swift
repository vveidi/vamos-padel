import SwiftUI
import Testing

@testable import PadelDesign

/// The ball, drawn and then looked at.
///
/// Three things have to be true of it and none of them are visible in source:
/// it is yellow rather than white, it has **two** seams rather than one or a
/// cross, and it is the same object at 10pt in a score corner as at 34pt on a
/// button — which is what a drawn path buys over an asset and what a test can
/// actually check.
@Suite("The ball")
@MainActor
struct BallTests {
    /// Large enough that the seams are several pixels wide, which is what
    /// makes them findable at all.
    static let size = 96

    static func ball(
        _ finish: Ball.Finish = .onCourt, size: Int = BallTests.size
    ) throws -> Raster {
        try #require(
            Raster(
                Ball(size: CGFloat(size), finish: finish),
                size: CGSize(width: CGFloat(size), height: CGFloat(size))))
    }

    /// Where the seam bows closest to the middle of the ball, as a fraction of
    /// its width.
    ///
    /// The midpoint of the boards' curve `M3.6 4.3 c 3.9 3 3.9 12.4 0 15.4`,
    /// which a cubic puts at `(P₀ + 3P₁ + 3P₂ + P₃) / 8` — 6.5 of 24 across,
    /// and 12 of 24 down, which is the ball's own middle.
    static let seamBow = 6.5 / 24.0

    @Test("The ball is the accent's yellow, not white")
    func theFeltIsBallYellow() throws {
        let raster = try Self.ball()

        #expect(raster.pixel(Self.size / 2, Self.size / 4, isCloseTo: .ball))
        #expect(!raster.pixel(Self.size / 2, Self.size / 4, isCloseTo: .white))
    }

    @Test("It is round, and the frame's corners are left alone")
    func theBallIsACircleInItsFrame() throws {
        let raster = try Self.ball()

        for corner in [(2, 2), (Self.size - 3, 2), (2, Self.size - 3)] {
            #expect(
                raster.alpha(corner.0, corner.1) < 0.2,
                "the ball fills its corners, so it is not a circle")
        }
    }

    /// Two arcs, one curving in from each edge. A single seam, or a cross, or
    /// the system ball's seam, all pass every other check here.
    @Test("Two seams curve in, one from each edge")
    func theSeamsAreTwoArcs() throws {
        let raster = try Self.ball()
        let middle = Self.size / 2
        let felt = raster.luminance(middle, middle)

        let leading = Int(Double(Self.size) * Self.seamBow)
        let trailing = Self.size - 1 - leading

        #expect(raster.luminance(leading, middle) < felt - 0.1, "no seam on the near edge")
        #expect(raster.luminance(trailing, middle) < felt - 0.1, "no seam on the far edge")

        // And nothing down the middle, which is what tells two arcs from a
        // cross or from a seam drawn across the ball.
        #expect(
            abs(raster.luminance(middle, middle) - raster.luminance(middle, middle - 12)) < 0.05,
            "something is drawn through the middle of the ball")
    }

    @Test("The seams are the dark green, not the label's near-black")
    func theSeamIsNotOnBall() throws {
        let raster = try Self.ball()
        let leading = Int(Double(Self.size) * Self.seamBow)

        // `ballSeam` at 0.4 over `ball`, which is a long way from `onBall` —
        // a seam at label strength turns the ball into a beach ball.
        #expect(!raster.pixel(leading, Self.size / 2, isCloseTo: .onBall, tolerance: 0.1))
    }

    /// The one place the ball is drawn the other way round: dark felt, bright
    /// seams, cut out of a `ball`-yellow button where the court's own ball
    /// would be yellow on yellow.
    @Test("The cut-out is the ball inverted")
    func theCutOutInvertsTheBall() throws {
        let raster = try Self.ball(.cutOut)
        let middle = Self.size / 2
        let leading = Int(Double(Self.size) * Self.seamBow)

        #expect(raster.pixel(middle, Self.size / 4, isCloseTo: .onBall))
        #expect(
            raster.luminance(leading, middle) > raster.luminance(middle, middle) + 0.1,
            "the seams did not come up with the felt")
    }

    /// "It must scale, since it is drawn at 10pt in a score zone and at 21pt
    /// on a button." Every size the ticket lists, and the ball has to be the
    /// same object at all of them.
    ///
    /// The frame is `size`; the felt is r 11 of a 24-unit box inside it, which
    /// is 22/24 of that. A ball that had been pinned to one size, or drawn
    /// from an asset, would hold its pixels while the frame moved.
    @Test("The same ball at every size it is drawn at", arguments: [10, 15, 20, 21, 24, 30, 34])
    func theBallIsOneObjectAtEverySize(size: Int) throws {
        let raster = try Self.ball(size: size)
        let widest = raster.drawnWidth(inRow: size / 2)

        #expect(
            abs(Double(widest) - Double(size) * 22 / 24) <= 1,
            "at \(size)pt the ball is \(widest)px across")
    }
}
