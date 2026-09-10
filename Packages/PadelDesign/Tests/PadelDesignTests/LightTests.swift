import SwiftUI
import Testing

@testable import PadelDesign

/// The two light effects.
///
/// Both are overlays, and the ticket's requirement of them is a layout one:
/// "Neither may affect layout" — the same argument `ScoreView` makes about the
/// serve indicator, that "an overlay is the whole of that guarantee". That is
/// checkable, and so is the other claim about the floodlight, which is that it
/// is a light and not a hue: it has to be visible and it has to be faint, and
/// the failure is a step in either direction.
@Suite("The light")
@MainActor
struct LightTests {
    static let size = CGSize(width: 200, height: 200)

    static func lit(from corner: Floodlight.Corner) throws -> Raster {
        try #require(
            Raster(Color.night.overlay { Floodlight(corner: corner) }, size: size))
    }

    /// The brightness of a patch at one corner of the frame.
    static func corner(_ raster: Raster, _ corner: Floodlight.Corner) -> Double {
        let near = 8
        let far = raster.width - 9

        let column = corner == .topLeading || corner == .bottomLeading ? near : far
        let row = corner == .topLeading || corner == .topTrailing ? near : far

        return raster.meanLuminance(
            columns: (column - 6)..<(column + 7), rows: (row - 6)..<(row + 7))
    }

    @Test("The light comes in from the corner it is given", arguments: Floodlight.Corner.allCases)
    func theFloodlightLightsItsOwnCorner(from: Floodlight.Corner) throws {
        let raster = try Self.lit(from: from)

        let brightest = try #require(
            Floodlight.Corner.allCases.max {
                Self.corner(raster, $0) < Self.corner(raster, $1)
            })

        #expect(brightest == from)
    }

    /// "It is a **light**, not a hue. If it starts reading as a second accent
    /// color, it is too strong or too saturated."
    ///
    /// Which is a pair of bounds: it has to lift the ground it is on, and it
    /// has to lift it by little. The app has one color and it is the ball
    /// (ADR-0006); a floodlight that arrived as paint would be the second.
    @Test("The floodlight is light rather than paint")
    func theFloodlightIsFaint() throws {
        let raster = try Self.lit(from: .topLeading)

        let lit = Self.corner(raster, .topLeading)
        let dark = Self.corner(raster, .bottomTrailing)

        #expect(lit > dark + 0.01, "the floodlight is not there at all")
        #expect(lit - dark < 0.2, "the floodlight is paint rather than light")
    }

    @Test("The scrim reaches night at its own edge", arguments: [VerticalEdge.top, .bottom])
    func theScrimFadesTowardItsEdge(edge: VerticalEdge) throws {
        let raster = try #require(
            Raster(Color.ball.overlay { NightScrim(edge: edge, depth: 60) }, size: Self.size))

        let atTheEdge = edge == .top ? 1 : raster.height - 2
        let awayFromIt = raster.height / 2

        #expect(raster.pixel(100, atTheEdge, isCloseTo: .night, tolerance: 0.06))
        #expect(raster.pixel(100, awayFromIt, isCloseTo: .ball))
    }

    /// Neither overlay may take a point from the layout. A court that ran
    /// under a floating control would stop running under it the moment the
    /// scrim pushed it about.
    @Test("Neither takes any room from the layout")
    func theOverlaysAreFree() throws {
        let bare = try #require(Raster(Text(verbatim: "40").fixedSize()))

        let floodlit = try #require(
            Raster(
                Text(verbatim: "40").fixedSize()
                    .overlay { Floodlight(corner: .topLeading) }))

        let scrimmed = try #require(
            Raster(
                Text(verbatim: "40").fixedSize()
                    .overlay { NightScrim(edge: .bottom) }))

        #expect((floodlit.width, floodlit.height) == (bare.width, bare.height))
        #expect((scrimmed.width, scrimmed.height) == (bare.width, bare.height))
    }
}
