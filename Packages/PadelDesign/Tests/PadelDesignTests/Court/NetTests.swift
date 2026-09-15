import SwiftUI
import Testing

@testable import PadelDesign

@Suite("The net")
@MainActor
struct NetTests {
    static let width = 200

    /// Room above and below the tape for the posts to stand in.
    static let height = 40

    static func net() throws -> Raster {
        try #require(
            Raster(NetLine(), size: CGSize(width: CGFloat(width), height: CGFloat(height))))
    }

    /// The rows in which one column is drawn on. Read off alpha at 0.7, which
    /// is above the shadow's own 0.5 and below the tape's 0.82: the shadow is
    /// a real part of the net and would otherwise answer for the tape.
    static func drawnRows(of raster: Raster, at column: Int) -> [Int] {
        (0..<raster.height).filter { raster.alpha(column, $0) > 0.7 }
    }

    @Test("The tape runs the whole width")
    func theTapeSpansTheNet() throws {
        let raster = try Self.net()
        let middle = Self.drawnRows(of: raster, at: Self.width / 2)

        #expect(!middle.isEmpty, "no tape at all")

        for row in middle {
            #expect(raster.alpha(4, row) > 0.7 && raster.alpha(Self.width - 5, row) > 0.7)
        }
    }

    @Test("A post stands at each end, taller than the tape")
    func thePostsStandAtBothEnds() throws {
        let raster = try Self.net()

        let tape = Self.drawnRows(of: raster, at: Self.width / 2)
        let leading = Self.drawnRows(of: raster, at: 1)
        let trailing = Self.drawnRows(of: raster, at: Self.width - 2)

        #expect(leading == trailing, "the two ends of the net are not the same net")
        #expect(leading.count > tape.count, "the posts do not stand proud of the tape")
        #expect(Set(tape).isSubset(of: Set(leading)), "the posts miss the tape they hold")

        // Three tapes long, as the boards draw it.
        #expect(abs(Double(leading.count) - 3 * Double(tape.count)) <= 1)
    }

    @Test("The net takes only the tape's height from the layout")
    func thePostsTakeNoRoom() throws {
        let raster = try #require(
            Raster(
                VStack(spacing: 0) {
                    Color.red.frame(height: 10)
                    NetLine()
                    Color.blue.frame(height: 10)
                }
                .frame(width: 100)))

        #expect(raster.height == 20 + Int(CourtMetrics.tape))
    }

    // MARK: The court

    @Test("The court is a half, the net, and an equal half")
    func theCourtIsTwoEqualHalvesAcrossTheNet() throws {
        let height = 401
        let raster = try #require(
            Raster(Court(), size: CGSize(width: CGFloat(Self.width), height: CGFloat(height))))

        // The net is the brightest thing on an unlit court by a distance — ink
        // at 0.82 against a surface carrying nothing but a weave at 0.03.
        let brightest = try #require(
            (0..<height).max { raster.rowLuminance($0) < raster.rowLuminance($1) })

        #expect(
            abs(brightest - height / 2) <= 2,
            "the net is not in the middle, so the halves are not equal")

        #expect(raster.pixel(50, height / 4, isCloseTo: .court))
        #expect(raster.pixel(50, height * 3 / 4, isCloseTo: .court))
    }
}
