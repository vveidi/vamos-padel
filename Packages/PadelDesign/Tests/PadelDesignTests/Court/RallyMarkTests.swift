import SwiftUI
import Testing

@testable import PadelDesign

/// Their half on top, ours below, and ours marked: the frame is 200×400, so the
/// marked half is rows 200 and down.
@Suite("The rally mark")
@MainActor
struct RallyMarkTests {
    static let size = CGSize(width: 200, height: 400)

    static let columns = 0..<200
    static let theirs = 0..<200
    static let ours = 200..<400

    /// A patch of our half well clear of the net and the edges.
    static let patch = (columns: 30..<170, rows: 240..<360)

    static func court(markedAt level: Double?) throws -> Raster {
        try #require(
            Raster(
                VStack(spacing: 0) {
                    CourtHalf()
                    CourtHalf().overlay {
                        if let level {
                            RallyMarkFill(level: level)
                        }
                    }
                },
                size: size))
    }

    @Test("At its peak the marked half is brighter")
    func theMarkedHalfLights() throws {
        let marked = try Self.court(markedAt: 1)
        let unmarked = try Self.court(markedAt: nil)

        let lift =
            marked.meanLuminance(columns: Self.patch.columns, rows: Self.patch.rows)
            - unmarked.meanLuminance(columns: Self.patch.columns, rows: Self.patch.rows)

        // By a margin and not by a rounding step: a mark nobody can see would
        // pass a bare `>`.
        #expect(lift > 0.1, "the half lifted by only \(lift)")
    }

    /// Channel balance rather than brightness, as `PaletteTests` checks it on the
    /// tokens (ADR-0011), taken here off the half as drawn.
    @Test("At its peak the marked half is the same color, brighter")
    func theMarkedHalfKeepsItsHue() throws {
        let marked = try Self.court(markedAt: 1)
            .meanPixel(columns: Self.patch.columns, rows: Self.patch.rows)
        let unmarked = try Self.court(markedAt: nil)
            .meanPixel(columns: Self.patch.columns, rows: Self.patch.rows)

        let ratios = { (pixel: Raster.Pixel) in
            (red: pixel.red / pixel.blue, green: pixel.green / pixel.blue)
        }

        let lit = ratios(marked)
        let court = ratios(unmarked)
        let drift = max(abs(lit.red - court.red), abs(lit.green - court.green))

        // `PaletteTests`' bound: above `courtLit`'s own drift, an order of
        // magnitude below the nearest reject's.
        #expect(drift < 0.08, "the marked half drifted \(drift) off the court's hue")
    }

    @Test("The other half is untouched, to the pixel")
    func theOtherHalfIsUntouched() throws {
        let marked = try Self.court(markedAt: 1)
        let unmarked = try Self.court(markedAt: nil)

        var changed = 0

        for row in Self.theirs {
            for column in Self.columns {
                let one = marked.pixel(column, row)
                let two = unmarked.pixel(column, row)

                if one.red != two.red || one.green != two.green || one.blue != two.blue {
                    changed += 1
                }
            }
        }

        #expect(changed == 0, "\(changed) pixels of the other half changed")
    }

    /// Which pixels of the patch sit on a stripe: brighter than the patch's own
    /// mean, so the reading survives the half under them getting brighter.
    static func stripes(_ raster: Raster) -> [Bool] {
        let mean = raster.meanLuminance(columns: patch.columns, rows: patch.rows)

        return patch.rows.flatMap { row in
            patch.columns.map { column in raster.luminance(column, row) > mean }
        }
    }

    /// At peak the stripes are the mark's, laid out from the mark's own frame: a
    /// point off the half's and they miss the half's on nearly a third of the patch.
    /// The overlay guarantee, stated as a number.
    @Test("The half's weave is where it was, marked or not")
    func theWeaveDoesNotMove() throws {
        let marked = Self.stripes(try Self.court(markedAt: 1))
        let unmarked = Self.stripes(try Self.court(markedAt: nil))

        let onStripe = Double(unmarked.count { $0 }) / Double(unmarked.count)
        let agree = Double(zip(marked, unmarked).count { $0 == $1 }) / Double(unmarked.count)

        // On for one, off for two.
        #expect(abs(onStripe - 1.0 / 3) < 0.1, "the patch is not reading the weave")
        #expect(agree > 0.98, "only \(agree) of the patch agrees on where the stripes are")
    }

    @Test("At rest the mark draws nothing")
    func theMarkAtRestIsTheCourt() throws {
        let rest = try Self.court(markedAt: 0)
        let unmarked = try Self.court(markedAt: nil)

        #expect(
            rest.patch(
                columns: Self.columns, rows: Self.ours, matches: unmarked, tolerance: 1 / 1000))
    }
}
