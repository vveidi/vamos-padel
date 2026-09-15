import PadelScoring
import SwiftUI
import Testing

@testable import PadelDesign

@Suite("The pill button")
@MainActor
struct PillButtonTests {
    static let width: CGFloat = 320

    static func pill(
        _ variant: PillButton.Variant = .primary, label: String = "New match",
        carriesBall: Bool = false, width: CGFloat = PillButtonTests.width
    ) throws -> Raster {
        try #require(
            Raster(
                PillButton(
                    Text(verbatim: label), variant: variant, carriesBall: carriesBall,
                    action: {}
                )
                .frame(width: width)
                .background(Color.night)))
    }

    @Test("The primary is the ball's yellow and the quiet one is not")
    func theTwoVariantsAreTheTwoGrounds() throws {
        let primary = try Self.pill()
        let quiet = try Self.pill(.quiet)

        #expect(primary.pixel(primary.width / 2, primary.height / 2, isCloseTo: .ball))
        #expect(!quiet.pixel(quiet.width / 2, quiet.height / 2, isCloseTo: .ball))

        // The quiet one is ink laid on thin over `night`, so it is barely
        // brighter than the ground and nowhere near the accent.
        #expect(
            Raster.luminance(of: .ball) > quiet.luminance(quiet.width / 2, quiet.height / 2))
    }

    /// The height on the boards is a floor: a verb that has to wrap grows the
    /// button rather than being clipped by it.
    @Test("A label with no room grows the pill instead of being cut")
    func aLongLabelGrowsThePill() throws {
        let short = try Self.pill()
        let long = try Self.pill(label: "Играть дальше, до конца сета", width: 140)

        #expect(Double(short.height) >= Double(ControlMetrics.pillHeight))
        #expect(long.height > short.height, "the pill kept its height and clipped its label")
    }

    @Test("The ball rides the button only when it is asked for")
    func theBallIsOptional() throws {
        let plain = try Self.pill()
        let carrying = try Self.pill(carriesBall: true)

        // The cut-out ball is `onBall` — nearly black — on the yellow, so the
        // button carrying one is the darker of the two overall.
        let strip = { (raster: Raster) in
            raster.meanLuminance(
                columns: 0..<raster.width,
                rows: (raster.height / 2 - 4)..<(raster.height / 2 + 4))
        }

        #expect(strip(carrying) < strip(plain), "the ball is not on the button")
    }
}

@Suite("The history tile")
@MainActor
struct CourtTileTests {
    static let size = CGSize(width: 300, height: 90)

    static func tile(_ outcome: MatchOutcome) throws -> Raster {
        try #require(
            Raster(
                CourtTile(outcome: outcome) {
                    Color.clear.frame(height: 50)
                }
                .background(Color.night),
                size: Self.size))
    }

    /// Low and leading, which is as far from the glow as the tile goes, and
    /// inside the hairline, so a border never answers for a ground.
    static func body(_ raster: Raster) -> Double {
        raster.meanLuminance(columns: 20..<80, rows: 60..<80)
    }

    /// The top trailing corner, where a won tile's glow hangs.
    static func corner(_ raster: Raster) -> Double {
        raster.meanLuminance(columns: 260..<295, rows: 4..<24)
    }

    @Test("The four outcomes are four grounds")
    func eachOutcomeHasItsOwnGround() throws {
        let outcomes: [MatchOutcome] = [
            .finished(winner: .us), .finished(winner: .them), .abandoned, .inProgress,
        ]
        var grounds: [(outcome: MatchOutcome, patch: Double)] = []

        for outcome in outcomes {
            grounds.append((outcome, Self.body(try Self.tile(outcome))))
        }

        for (index, one) in grounds.enumerated() {
            for two in grounds.dropFirst(index + 1) {
                #expect(
                    abs(one.patch - two.patch) > 0.01,
                    "\(one.outcome) and \(two.outcome) are the same ground")
            }
        }
    }

    @Test("A win is the court and a match still running is the court, lit")
    func theCourtsTwoGroundsAreTheCourtsTwoTokens() throws {
        #expect(try Self.tile(.finished(winner: .us)).pixel(40, 70, isCloseTo: .court))
        #expect(try Self.tile(.inProgress).pixel(40, 70, isCloseTo: .courtLit))
    }

    @Test("A loss is night, with a hairline and nothing else")
    func theLostTileIsNightInsideAHairline() throws {
        let lost = try Self.tile(.finished(winner: .them))

        #expect(lost.pixel(40, 70, isCloseTo: .night))

        // The border, read down the leading edge at the tile's waist, where
        // the rounded corners are well out of the way.
        let edge = lost.meanLuminance(columns: 0..<2, rows: 40..<50)

        #expect(edge > Self.body(lost), "no hairline, so the tile has no edge at all")

        // And no lift under it: the ground is the list's own, which is what
        // makes the hairline the only thing separating them.
        #expect(
            abs(Self.body(lost) - Raster.luminance(of: .night)) < 0.02,
            "the lost tile was lifted off the ground it is meant to sit on")
    }

    @Test("A match stopped early is night, lifted off night")
    func theAbandonedTileIsLifted() throws {
        let stopped = try Self.tile(.abandoned)

        #expect(
            Self.body(stopped) > Raster.luminance(of: .night),
            "the tile is the same value as the ground under it")
        #expect(
            Self.body(stopped) > Self.body(try Self.tile(.finished(winner: .them))),
            "a match stopped early and a match lost are the same tile")
    }

    @Test("No light falls on a match stopped early")
    func theAbandonedTileIsUnlit() throws {
        let stopped = try Self.tile(.abandoned)

        #expect(
            abs(Self.corner(stopped) - Self.body(stopped)) < 0.01,
            "the abandoned tile is lit in the corner the floodlight used to come from")
    }

    @Test("Only a won match carries the glow")
    func theGlowMarksAWin() throws {
        let won = try Self.tile(.finished(winner: .us))
        let lost = try Self.tile(.finished(winner: .them))

        #expect(Self.corner(won) > Self.body(won), "the won tile's corner is not lit")
        #expect(
            Self.corner(lost) - Self.body(lost) < Self.corner(won) - Self.body(won),
            "the lost tile carries a glow of its own")
    }
}
