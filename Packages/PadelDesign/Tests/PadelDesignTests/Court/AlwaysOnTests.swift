import PadelScoring
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

    /// Bare surface on a half: below their service line, left of the center
    /// line, and well inside the outline — no paint of any kind in it.
    static let surfaceColumns = 30..<80
    static let surfaceRows = 200..<260

    /// Their service line, which at 30% of 400 is two rows at 120.
    static let serviceRows = 120..<122

    static func half(_ side: Side, dimmed: Bool) throws -> Raster {
        try #require(
            Raster(
                CourtHalf(side: side).environment(\.isLuminanceReduced, dimmed),
                size: size))
    }

    static func surface(_ raster: Raster) -> Double {
        raster.meanLuminance(columns: surfaceColumns, rows: surfaceRows)
    }

    @Test("The halves go dark, and are still two halves")
    func theTintsFallMostOfTheWayToNight() throws {
        let litThem = try Self.half(.them, dimmed: false)
        let dimThem = try Self.half(.them, dimmed: true)
        let dimUs = try Self.half(.us, dimmed: true)

        #expect(Self.surface(dimThem) < Self.surface(litThem), "the half did not dim")
        #expect(
            Self.surface(dimThem) > Raster.luminance(of: .night),
            "the half went all the way to night")

        // Which end is ours is what the glance is for, and two tints that both
        // arrive at `night` are one black rectangle.
        //
        // The threshold is where it is because this is the number the design
        // was settled on: at a 0.72 fall the halves measured 0.021 apart and
        // were one color to look at, and at 0.55 they measure 0.032 and are
        // two. Anything that walks the fall back up fails here rather than on
        // a wrist.
        #expect(
            Self.surface(dimUs) - Self.surface(dimThem) > 0.028,
            "the two halves are one color when dimmed")
    }

    @Test("The weave goes")
    func theTextureIsNotDrawnWhenDimmed() throws {
        let lit = try Self.half(.them, dimmed: false)
        let dimmed = try Self.half(.them, dimmed: true)

        // Lit, the patch is brighter than the tint under it, and the weave is
        // the only thing in it that could be doing that.
        #expect(Self.surface(lit) > Raster.luminance(of: .courtSurface(.them)))

        // Dimmed, the patch *is* the tint.
        #expect(
            abs(Self.surface(dimmed) - Raster.luminance(of: .courtSurface(.them, dimmed: true)))
                < 1 / 255)
    }

    @Test("The lines are still there, thinner")
    func theGeometrySurvives() throws {
        let lit = try Self.half(.them, dimmed: false)
        let dimmed = try Self.half(.them, dimmed: true)

        let line = { (raster: Raster) in
            raster.meanLuminance(columns: Self.surfaceColumns, rows: Self.serviceRows)
        }

        #expect(line(dimmed) > Self.surface(dimmed), "the service line went out")
        #expect(
            line(dimmed) - Self.surface(dimmed) < line(lit) - Self.surface(lit),
            "the paint did not thin")
    }

    /// The service line is the strongest of the three at 0.34 and the outline
    /// the faintest at 0.20, so the service line surviving says nothing about
    /// the one that is actually at risk.
    @Test("The faintest line survives too")
    func theWeakestPaintIsStillVisible() throws {
        let dimmed = try Self.half(.them, dimmed: true)

        // Their outline runs down the leading edge, inset by the margin plus
        // half the thickness — 11 on the Mac's phone-sized metrics.
        let outline = dimmed.meanLuminance(columns: 10..<13, rows: 200..<260)

        #expect(outline > Self.surface(dimmed), "the outline went out")
    }

    /// The one row of the ticket's table that asks for nothing to happen, and
    /// the one a later change could undo without anything else noticing.
    @Test("The score's ink does not dim")
    func theInkIsUntouched() throws {
        for side in [Side.them, .us] {
            let score = { (dimmed: Bool) in
                try #require(
                    Raster(
                        Rectangle().fill(Color.courtInk(side))
                            .environment(\.isLuminanceReduced, dimmed),
                        size: CGSize(width: 20, height: 20)))
            }

            #expect(
                (try score(true)).patch(columns: 5..<15, rows: 5..<15, matches: try score(false)),
                "the ink dimmed with the court")
        }
    }

    @Test("The floodlight goes out")
    func theLightIsGoneWhenDimmed() throws {
        let corner = (columns: 150..<195, rows: 340..<390)

        let court = { (lit: Bool, dimmed: Bool) in
            try #require(
                Raster(
                    CourtHalf(side: .us)
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
        #expect(dimmed.luminance > Self.surface(try Self.half(.us, dimmed: true)))
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
