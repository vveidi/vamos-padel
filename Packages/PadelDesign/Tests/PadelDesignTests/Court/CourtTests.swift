import SwiftUI
import Testing

@testable import PadelDesign

/// The frame is 200×400 throughout, so a fraction of the half is a round number
/// of pixels and a failure reports a position rather than a ratio.
@Suite("The court")
@MainActor
struct CourtTests {
    static let width = 200
    static let height = 400

    static let size = CGSize(width: CGFloat(width), height: CGFloat(height))

    static func half() throws -> Raster {
        try #require(Raster(CourtHalf(), size: size))
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

    @Test("The half is painted in the one surface, corner to corner")
    func theHalfIsOneSurface() throws {
        let raster = try Self.half()

        // The four corners and the middle.
        for (column, row) in [(6, 6), (Self.width - 7, 6), (6, Self.height - 7),
            (Self.width - 7, Self.height - 7), (Self.width / 2, Self.height / 2)]
        {
            #expect(
                raster.pixel(column, row, isCloseTo: .court),
                "the surface is not the court at (\(column), \(row))")
        }
    }

    /// A line running *across* the half moves its row's mean a long way; a line
    /// running *down* it moves every row's mean a little and shows up as a
    /// column instead. Both are looked for. The weave is the only thing allowed
    /// to move a reading, and it moves it by thousandths.
    @Test("Nothing is painted on the half")
    func theHalfCarriesNoLines() throws {
        let raster = try Self.half()

        let rows = (0..<Self.height).map(raster.rowLuminance)
        let columns = (0..<Self.width).map { column in
            raster.meanLuminance(columns: column..<(column + 1), rows: 0..<Self.height)
        }

        for (name, readings) in [("row", rows), ("column", columns)] {
            let lightest = try #require(readings.max())
            let darkest = try #require(readings.min())

            #expect(
                lightest - darkest < 0.01,
                "a \(name) of the half stands out from the surface, so something is painted on it")
        }
    }

    // MARK: The weave

    /// A test cannot glance at the weave, but it can check the two ways it
    /// stops being texture: vanishing, and shouting.
    @Test("The weave lies on the surface without becoming stripes")
    func theWeaveIsTextureRatherThanPattern() throws {
        let raster = try Self.half()

        // A diagonal run crossing the weave's own diagonal, so that both the
        // on and the off of it are in the sample.
        let samples = (110..<170).map { raster.luminance($0, $0 + 100) }
        let lightest = try #require(samples.max())
        let darkest = try #require(samples.min())

        #expect(lightest > darkest, "the weave drew nothing at all")
        #expect(
            lightest - darkest < 0.05,
            "the weave reads as stripes rather than as a surface")
        #expect(
            darkest > Raster.luminance(of: Color.courtSurface()) - 0.005,
            "the weave darkened the court instead of lighting it")
    }
}
