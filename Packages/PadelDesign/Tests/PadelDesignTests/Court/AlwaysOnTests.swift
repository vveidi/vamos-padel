import SwiftUI
import Testing

@testable import PadelDesign

/// The court with the screen's luminance reduced — the same court after the
/// floodlights go off.
///
/// Every claim here is the same shape: the thing that carries information is
/// still measurable and the thing that carries atmosphere measures zero. That
/// is the whole rule, and none of it can be read off the source, because what
/// a fraction toward `night` actually leaves on screen is a picture.
///
/// The frame is the court suite's 200×400, so the two read the same way.
@Suite("The court in Always-On")
@MainActor
struct AlwaysOnTests {
    static let size = CGSize(width: 200, height: 400)

    /// A patch of surface well inside the half, clear of every edge.
    static let surfaceColumns = 30..<80
    static let surfaceRows = 200..<260

    static func half(dimmed: Bool) throws -> Raster {
        try #require(
            Raster(
                CourtHalf().environment(\.isLuminanceReduced, dimmed),
                size: size))
    }

    static func surface(_ raster: Raster) -> Double {
        raster.meanLuminance(columns: surfaceColumns, rows: surfaceRows)
    }

    /// How far the surface falls now answers to burn-in and to the score
    /// standing on it, and to nothing else: there is one surface, so there is
    /// no second tint it has to stay apart from when the lights go down.
    ///
    /// Both ends of that are here. It has to arrive somewhere well down toward
    /// `night`, or the fall is not paying for itself; and it has to stop short
    /// of `night` and stay blue, or the court has become a black rectangle
    /// with a net drawn across it.
    @Test("The court goes dark, and is still a court")
    func theSurfaceFallsMostOfTheWayToNight() throws {
        let lit = try Self.half(dimmed: false)
        let dimmed = try Self.half(dimmed: true)

        let night = Raster.luminance(of: .night)

        #expect(Self.surface(dimmed) < Self.surface(lit), "the court did not dim")
        #expect(Self.surface(dimmed) > night, "the court went all the way to night")

        // Most of the way down, measured as the fraction of the drop it
        // actually made — anything that walks `CourtDimming.surface` back up
        // to where it was when it had a second tint to stay clear of fails
        // here.
        let fell = (Self.surface(lit) - Self.surface(dimmed)) / (Self.surface(lit) - night)

        #expect(fell > 0.6, "the fall is too shallow to be worth making")

        // And still a blue rather than a gray. `night` is a teal and the court
        // is a blue, so the channel *order* survives any mix of the two and
        // says nothing — what a dim that washed the color out would lose is
        // the distance between the channels, so that is what is measured.
        let pixel = dimmed.pixel(50, 230)

        #expect(
            pixel.blue - pixel.red > 0.1,
            "the dimmed court has gone gray rather than dark")
        #expect(pixel.blue > pixel.green, "the dimmed court is no longer a blue")
    }

    @Test("The weave goes")
    func theTextureIsNotDrawnWhenDimmed() throws {
        let lit = try Self.half(dimmed: false)
        let dimmed = try Self.half(dimmed: true)

        // Lit, the patch is brighter than the surface under it, and the weave
        // is the only thing in it that could be doing that.
        #expect(Self.surface(lit) > Raster.luminance(of: .courtSurface()))

        // Dimmed, the patch *is* the surface.
        #expect(
            abs(Self.surface(dimmed) - Raster.luminance(of: .courtSurface(dimmed: true)))
                < 1 / 255)
    }

    /// The one row of the ticket's table that asks for nothing to happen, and
    /// the one a later change could undo without anything else noticing.
    @Test("The score's ink does not dim")
    func theInkIsUntouched() throws {
        let score = { (dimmed: Bool) in
            try #require(
                Raster(
                    Rectangle().fill(Color.courtInk)
                        .environment(\.isLuminanceReduced, dimmed),
                    size: CGSize(width: 20, height: 20)))
        }

        #expect(
            (try score(true)).patch(columns: 5..<15, rows: 5..<15, matches: try score(false)),
            "the ink dimmed with the court")
    }

    /// The point of dimming at all is that what is being read survives it. The
    /// score is the only thing left standing on the surface now that the lines
    /// are gone, so this is the whole of the readability claim.
    @Test("The score still stands off the court it is drawn on")
    func theInkStillReadsAgainstTheDimmedCourt() throws {
        let ink = Raster.luminance(of: .courtInk)
        let court = Raster.luminance(of: .courtSurface(dimmed: true))

        // WCAG's ratio, which the two are miles clear of and which is the only
        // number here anybody else would recognize.
        #expect((ink + 0.05) / (court + 0.05) > 4.5)
    }

    @Test("The floodlight goes out")
    func theLightIsGoneWhenDimmed() throws {
        let corner = (columns: 150..<195, rows: 340..<390)

        let court = { (lit: Bool, dimmed: Bool) in
            try #require(
                Raster(
                    CourtHalf()
                        .overlay { lit ? Floodlight(corner: .bottomTrailing) : nil }
                        .environment(\.isLuminanceReduced, dimmed),
                    size: Self.size))
        }

        // The light is worth something when the screen is up …
        #expect(
            !(try court(false, false))
                .patch(columns: corner.columns, rows: corner.rows, matches: try court(true, false)))

        // … and nothing at all when it is down.
        #expect(
            (try court(false, true))
                .patch(columns: corner.columns, rows: corner.rows, matches: try court(true, true)))
    }

    @Test("The ball stays, dimmed, and stays yellow")
    func theBallIsStillTheBall() throws {
        let ball = { (dimmed: Bool) in
            try #require(
                Raster(
                    Ball(size: 40).environment(\.isLuminanceReduced, dimmed),
                    size: CGSize(width: 40, height: 40)))
        }

        let lit = try ball(false).pixel(20, 20)
        let dimmed = try ball(true).pixel(20, 20)

        #expect(dimmed.luminance < lit.luminance, "the ball did not dim")

        // Still yellow and not a gray disc: `night` is a teal, so a felt that
        // had gone most of the way into it would have its blue catch up.
        #expect(dimmed.green > dimmed.blue, "the ball is no longer yellow")
        #expect(dimmed.red > dimmed.blue, "the ball is no longer yellow")

        // And still the brightest thing on the court, which is what pays for
        // keeping it on screen at all.
        #expect(dimmed.luminance > Self.surface(try Self.half(dimmed: true)))
    }

    @Test("The net is still strung across the middle")
    func theNetSurvives() throws {
        let court = { (dimmed: Bool) in
            try #require(
                Raster(
                    Court().environment(\.isLuminanceReduced, dimmed), size: Self.size))
        }

        // The tape sits between two flexible halves, so it is the middle three
        // rows of the frame and the surface is what is a little way off it.
        let tape = { (raster: Raster) in
            raster.meanLuminance(columns: Self.surfaceColumns, rows: 199..<201)
        }
        let beside = { (raster: Raster) in
            raster.meanLuminance(columns: Self.surfaceColumns, rows: 230..<260)
        }

        let dimmed = try court(true)
        let lit = try court(false)

        // Brighter than the surface by a margin, and not by a rounding step:
        // an assertion that only asked for `>` would pass on a net nobody can
        // see, which is the failure this test exists to catch.
        #expect(tape(dimmed) - beside(dimmed) > 0.1, "the net is not visible")

        // Dimmer than it was, by more than the surface under it lost — the
        // net is the brightest of the three pieces of geometry and has the
        // furthest to fall.
        #expect(tape(lit) - tape(dimmed) > beside(lit) - beside(dimmed), "the net did not dim")
    }
}
