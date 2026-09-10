import PadelScoring
import SwiftUI
import Testing

@testable import PadelDesign

/// The court's geometry, drawn and then measured.
///
/// Read off the boards, the whole of it is four claims: the service line is
/// 30% in from the half's *outer* edge, the center line runs from there to the
/// net and no further, the outline has three sides because the net is the
/// fourth, and our half is theirs mirrored rather than a second drawing of it.
/// Every one of them is a picture, and every one of them compiles when wrong.
///
/// The frame is 200×400 throughout, so a fraction of the half is a round
/// number of pixels and a failure reports a position rather than a ratio.
@Suite("The court")
@MainActor
struct CourtTests {
    static let width = 200
    static let height = 400

    static let size = CGSize(width: CGFloat(width), height: CGFloat(height))

    /// The row a fraction of the way in from a half's **outer** edge — the top
    /// of their half, the bottom of ours.
    ///
    /// The mirror, written once here so the assertions below can be written
    /// once each. If this and ``PadelDesign/PaintedLine`` were wrong in the
    /// same direction the suite would pass for the wrong reason, which is why
    /// the mirror is also checked head-on further down, without this helper.
    static func inward(_ fraction: Double, on side: Side) -> Int {
        switch side {
        case .them: Int(Double(height) * fraction)
        case .us: Int(Double(height) * (1 - fraction))
        }
    }

    /// A patch a few pixels either side of one point, which is what nearly
    /// every assertion here samples — see
    /// ``Raster/meanLuminance(columns:rows:)``.
    static func patch(_ raster: Raster, column: Int, row: Int) -> Double {
        raster.meanLuminance(
            columns: max(0, column - 4)..<min(width, column + 5),
            rows: max(0, row - 4)..<min(height, row + 5))
    }

    static func half(_ side: Side) throws -> Raster {
        try #require(Raster(CourtHalf(side: side), size: size))
    }

    /// The suite is only as good as the sampler under it, and a sampler that
    /// had the image upside down would agree with a court that was.
    @Test("The sampler reads the picture the right way up")
    func theSamplerIsNotUpsideDown() throws {
        let raster = try #require(
            Raster(
                VStack(spacing: 0) {
                    Color.red
                    Color.blue
                },
                size: CGSize(width: 20, height: 20)))

        #expect(raster.pixel(10, 2, isCloseTo: .red))
        #expect(raster.pixel(10, 17, isCloseTo: .blue))
    }

    @Test("Each half is painted in its own surface", arguments: Side.allCases)
    func theHalvesArePaintedInTheirOwnTints(side: Side) throws {
        let raster = try Self.half(side)

        // A quarter of the way across and halfway down, which is clear of
        // every line on both halves.
        #expect(raster.pixel(50, 200, isCloseTo: Color.courtSurface(side)))
    }

    @Test("The service line is 30% in from the outer edge", arguments: Side.allCases)
    func theServiceLineIsWhereTheBoardPutsIt(side: Side) throws {
        let raster = try Self.half(side)

        // The brightest row wins, and the service line is the strongest of the
        // three paints on purpose — the eye is meant to find the service boxes
        // first. The ends are left out so that the outline's own horizontal
        // run, which is 2.5% in, cannot answer for it.
        let rows = Int(Double(Self.height) * 0.05)..<Int(Double(Self.height) * 0.95)
        let brightest = try #require(rows.max { raster.rowLuminance($0) < raster.rowLuminance($1) })

        #expect(abs(brightest - Self.inward(0.3, on: side)) <= 3)
    }

    @Test(
        "The center line runs from the service line to the net, and no further",
        arguments: Side.allCases)
    func theCenterLineStopsAtTheServiceLine(side: Side) throws {
        let raster = try Self.half(side)
        let middle = Self.width / 2
        let clearOfIt = middle - 40

        // Between the service line and the net: the center line is there.
        for fraction in [0.5, 0.9] {
            let row = Self.inward(fraction, on: side)

            #expect(
                Self.patch(raster, column: middle, row: row)
                    > Self.patch(raster, column: clearOfIt, row: row) + 0.02,
                "no center line at \(Int(fraction * 100))% of \(side)'s half")
        }

        // Behind the service line, between it and the back of the court:
        // nothing but surface.
        let behind = Self.inward(0.15, on: side)

        #expect(
            abs(
                Self.patch(raster, column: middle, row: behind)
                    - Self.patch(raster, column: clearOfIt, row: behind)) < 0.01,
            "the center line runs past the service line into the back of \(side)'s half")
    }

    @Test("The outline has three sides, and the net is the fourth", arguments: Side.allCases)
    func theOutlineLeavesTheNetEdgeUndrawn(side: Side) throws {
        let raster = try Self.half(side)

        // Well clear of the center line, so that only the outline can be
        // brightening anything.
        let column = 50
        let surface = Self.patch(raster, column: column, row: 200)

        // The outline's own inset, which is the one number here that is points
        // rather than a fraction — see `CourtMetrics`.
        let margin = Int(CourtMetrics.outlineInset + CourtMetrics.line / 2)
        let back = side == .them ? margin : Self.height - 1 - margin

        #expect(
            Self.patch(raster, column: column, row: back) > surface + 0.02,
            "no line along the back of \(side)'s half")

        let net = side == .them ? Self.height - 1 : 0

        #expect(
            abs(Self.patch(raster, column: column, row: net) - surface) < 0.012,
            "a line was drawn along the net, which the tape already is")

        // And down the side, which every half has on both sides.
        #expect(
            Self.patch(raster, column: margin, row: 200) > surface + 0.02,
            "no line down the near side")
        #expect(
            Self.patch(raster, column: Self.width - 1 - margin, row: 200) > surface + 0.02,
            "no line down the far side")
    }

    /// The claim the ticket rests on: "the two halves are the same court seen
    /// from our end … write it as one view with a `side` rather than two views
    /// that happen to look alike, or the mirror will be 'fixed' in one of
    /// them."
    ///
    /// Checked head-on rather than through ``inward(_:on:)``: every row that
    /// carries a line across their half must carry one across ours, at the
    /// mirrored row, and nowhere else. A service line that moved in one half
    /// and not in the other fails here even if each half is internally
    /// consistent.
    @Test("Our half is theirs mirrored, and not a second drawing of it")
    func theHalvesAreOneGeometry() throws {
        let theirs = try Self.paintedRows(of: .them)
        let ours = try Self.paintedRows(of: .us)

        #expect(!theirs.isEmpty, "no lines found at all — the threshold is wrong")
        #expect(ours == theirs.map { Self.height - 1 - $0 }.sorted())
    }

    /// The rows of a half that carry a line running across it.
    ///
    /// A line running *down* the half — the center line, the outline's two
    /// sides — is two pixels of two hundred and moves a row's mean by nothing.
    /// A line running across it moves it a long way, so the rows sort
    /// themselves into two groups and the threshold only has to land between
    /// them.
    static func paintedRows(of side: Side) throws -> [Int] {
        let raster = try Self.half(side)
        let rows = (0..<raster.height).map(raster.rowLuminance)
        let surface = rows.sorted()[rows.count / 2]

        return rows.indices.filter { rows[$0] > surface + 0.06 }
    }

    // MARK: The weave

    /// The weave is texture and not pattern: "at a glance it should read as a
    /// surface and not as stripes". A test cannot glance at it, but it can
    /// check the two ways it stops being texture — vanishing, and shouting.
    @Test("The weave lies on the surface without becoming stripes", arguments: Side.allCases)
    func theWeaveIsTextureRatherThanPattern(side: Side) throws {
        let raster = try Self.half(side)

        // A diagonal run clear of every line on either half, crossing the
        // weave's own diagonal so that both the on and the off of it are in
        // the sample.
        let samples = (110..<170).map { raster.luminance($0, $0 + 100) }
        let lightest = try #require(samples.max())
        let darkest = try #require(samples.min())

        #expect(lightest > darkest, "the weave drew nothing at all")
        #expect(
            lightest - darkest < 0.05,
            "the weave reads as stripes rather than as a surface")
        #expect(
            darkest > Raster.luminance(of: Color.courtSurface(side)) - 0.005,
            "the weave darkened the court instead of lighting it")
    }
}
