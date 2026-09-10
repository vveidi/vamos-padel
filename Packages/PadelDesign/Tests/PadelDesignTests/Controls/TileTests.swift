import PadelScoring
import SwiftUI
import Testing

@testable import PadelDesign

/// The button at the foot of a screen and the tile in the history, drawn and
/// then looked at.
///
/// The two controls that carry no words of their own: a pill is handed a verb
/// and a tile is handed a whole match. What can be checked here is the ground
/// under them — which is the part that means something. See `ControlsTests`
/// for what this package can and cannot measure on a Mac.

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

    /// The height on the boards is a floor. A verb that has to wrap grows the
    /// button, because a button that clipped what it does would be one nobody
    /// could read before pressing it.
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

    /// The tile's whole argument: the season is readable by color. Three
    /// outcomes that drew the same ground would be a history of identical
    /// cards with the answer buried in the numbers.
    @Test("The three outcomes are three grounds")
    func eachOutcomeHasItsOwnTint() throws {
        let won = try Self.tile(.finished(winner: .us))
        let lost = try Self.tile(.finished(winner: .them))
        let stopped = try Self.tile(.abandoned)

        // Low and leading, which is as far from the glow in the top trailing
        // corner as the tile goes.
        let patch = { (raster: Raster) in
            raster.meanLuminance(columns: 20..<80, rows: 60..<80)
        }

        #expect(patch(won) != patch(lost))
        #expect(patch(lost) != patch(stopped))
        #expect(patch(won) != patch(stopped))

        #expect(won.pixel(40, 70, isCloseTo: .ourHalf))
        #expect(lost.pixel(40, 70, isCloseTo: .theirHalf))
    }

    /// `night`, lifted — the ground of the app raised into a card. It must be
    /// brighter than the ground it sits on or it is not a tile at all.
    @Test("A match stopped early is night, lifted off night")
    func theAbandonedTileIsLifted() throws {
        let stopped = try Self.tile(.abandoned)

        #expect(
            stopped.meanLuminance(columns: 20..<80, rows: 60..<80)
                > Raster.luminance(of: .night),
            "the tile is the same value as the ground under it")
    }

    /// The one place the accent appears as light rather than as a mark, and
    /// only a win carries it.
    @Test("Only a won match carries the glow")
    func theGlowMarksAWin() throws {
        let won = try Self.tile(.finished(winner: .us))
        let lost = try Self.tile(.finished(winner: .them))

        let corner = { (raster: Raster) in
            raster.meanLuminance(columns: 260..<295, rows: 4..<24)
        }
        let body = { (raster: Raster) in
            raster.meanLuminance(columns: 20..<80, rows: 60..<80)
        }

        #expect(corner(won) > body(won), "the won tile's corner is not lit")
        #expect(
            corner(lost) - body(lost) < corner(won) - body(won),
            "the lost tile carries a glow of its own")
    }

    /// A match still going has no result either, and the tint says exactly
    /// that. The words on the tile tell the two apart; the ground does not.
    @Test("A match still in progress is drawn as one stopped early")
    func inProgressBorrowsTheAbandonedTint() throws {
        let playing = try Self.tile(.inProgress)
        let stopped = try Self.tile(.abandoned)

        #expect(
            playing.meanLuminance(columns: 20..<80, rows: 60..<80)
                == stopped.meanLuminance(columns: 20..<80, rows: 60..<80))
    }
}
