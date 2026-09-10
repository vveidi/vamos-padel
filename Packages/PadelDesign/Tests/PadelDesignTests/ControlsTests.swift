import PadelScoring
import SwiftUI
import Testing

@testable import PadelDesign

/// The five controls, drawn and then looked at.
///
/// What is checkable here and what is not is worth stating once, because it
/// shapes every suite below.
///
/// **Not checkable: Dynamic Type.** macOS has no such thing — `RenderingTests`
/// measured it rather than assuming it — so no test here turns the type up.
/// What *is* checkable is the reflow those settings trigger, because the same
/// `ViewThatFits` fires when the width runs out for any reason: hand a control
/// a phrase too long for the space and it stacks. A narrow frame is the
/// largest type setting's stand-in, and it fires the same branch.
///
/// **Not checkable: the Digital Crown.** There is no crown on a Mac and no
/// crown in a simulator worth the name. `StepperRow`'s crown is the ticket's
/// own "try it on a wrist, not in a canvas", and it stays that.
///
/// The thicknesses these tests see are the phone's — the package renders on
/// the Mac, and `Platform` gives the Mac the phone's numbers.
@Suite("The segmented choice")
@MainActor
struct SegmentedChoiceTests {
    static let width: CGFloat = 320

    /// Rendered at `width` unless a narrower one is asked for, which is how
    /// the stacking branch is reached.
    static func choice(
        selecting chosen: Bool, labels: (String, String) = ("Classic", "To N points"),
        width: CGFloat = SegmentedChoiceTests.width
    ) throws -> Raster {
        var selection = chosen

        let binding = Binding(get: { selection }, set: { selection = $0 })

        return try #require(
            Raster(
                SegmentedChoice(
                    selection: binding,
                    .init(Text(verbatim: labels.0), value: true),
                    .init(Text(verbatim: labels.1), value: false)
                )
                .frame(width: width)
                .background(Color.night)))
    }

    /// Whether the ring runs down the left edge of the segment starting at
    /// `edge`.
    ///
    /// A band of columns rather than one, because the ring is two points wide
    /// and its outer pixel is shared with the rounded corner's antialiasing —
    /// a single column would be asserting where the renderer put the seam.
    static func isRinged(_ raster: Raster, from edge: Int) -> Bool {
        let middle = raster.height / 2

        return (0..<4).contains {
            raster.pixel(edge + $0, middle, isCloseTo: .ball, tolerance: 0.12)
        }
    }

    /// The ring is the whole of the selection — there is no checkmark, no
    /// sliding pill and no second color — so a ring drawn on both sides, or
    /// on neither, is the failure that compiles.
    @Test("The chosen side is ringed in ball, and only that side")
    func onlyTheChosenSideIsRinged() throws {
        let raster = try Self.choice(selecting: true)

        let onChosen = Self.isRinged(raster, from: 0)
        let onOther = Self.isRinged(raster, from: raster.width / 2 + 4)

        #expect(onChosen, "the chosen side is not ringed")
        #expect(!onOther, "the side that was not chosen is ringed too")
    }

    @Test("The ring follows the selection to the other side")
    func theRingMoves() throws {
        let chosenFirst = try Self.choice(selecting: true)
        let chosenSecond = try Self.choice(selecting: false)

        let firstIsRinged = Self.isRinged(chosenFirst, from: 0)
        let secondIsRinged = Self.isRinged(chosenSecond, from: 0)

        #expect(firstIsRinged)
        #expect(!secondIsRinged, "the ring stayed on the side that was not chosen")
    }

    /// The largest Dynamic Type setting's stand-in: a phrase that does not fit
    /// beside its neighbour. Side by side it would have to be wrapped into a
    /// column two words wide, and a choice nobody can read is not one.
    @Test("Two labels that will not fit side by side stack instead")
    func theSegmentsStackWhenTheyRunOutOfWidth() throws {
        let beside = try Self.choice(selecting: true)
        let stacked = try Self.choice(
            selecting: true,
            labels: ("Классический счёт", "Счёт до N очков"),
            width: 120)

        #expect(
            stacked.height > beside.height,
            "the segments stayed side by side and squeezed instead")
        #expect(
            Double(stacked.height) > Double(ControlMetrics.segmentHeight) * 1.8,
            "the second segment did not go under the first")
    }
}

@Suite("The stepper row")
@MainActor
struct StepperRowTests {
    static let width: CGFloat = 320

    static func row(
        value: Int = 2, in range: ClosedRange<Int> = 1...3, label: String = "Sets",
        width: CGFloat = StepperRowTests.width
    ) throws -> Raster {
        var held = value

        let binding = Binding(get: { held }, set: { held = $0 })

        return try #require(
            Raster(
                StepperRow(Text(verbatim: label), value: binding, in: range)
                    .frame(width: width)
                    .background(Color.night)))
    }

    @Test("A row is at least as tall as the board's row")
    func theRowKeepsItsHeight() throws {
        let raster = try Self.row()

        #expect(Double(raster.height) >= Double(ControlMetrics.rowHeight))
    }

    /// The + at the top of the range and the − at the bottom are dimmed, and
    /// the comparison is between the two ends rather than against a number:
    /// what matters is that the unreachable one is fainter than the reachable
    /// one, whatever the exact opacity.
    @Test("A button that cannot move the value is dimmed")
    func theButtonAtTheBoundIsDimmed() throws {
        let atTop = try Self.row(value: 3)
        let atBottom = try Self.row(value: 1)

        // The trailing button is the + , the leading of the pair is the − .
        let middle = atTop.height / 2
        let plus = atTop.width - Int(ControlMetrics.stepperHit / 2)

        let plusAtTop = atTop.meanLuminance(
            columns: (plus - 6)..<(plus + 6), rows: (middle - 6)..<(middle + 6))
        let plusAtBottom = atBottom.meanLuminance(
            columns: (plus - 6)..<(plus + 6), rows: (middle - 6)..<(middle + 6))

        #expect(
            plusAtTop < plusAtBottom,
            "the + is as bright at the top of the range as in the middle of it")
    }

    /// The same stand-in for the largest type setting as in the choice above.
    @Test("A label with no room beside the ± puts them underneath")
    func theRowStacksWhenTheLabelRunsOutOfWidth() throws {
        let beside = try Self.row()
        let stacked = try Self.row(label: "Подача через (X)", width: 150)

        #expect(
            stacked.height > beside.height,
            "the label stayed beside the ± and was cut off instead")
    }
}

@Suite("The settings card")
@MainActor
struct SettingsCardTests {
    static let rowHeight: CGFloat = 40
    static let width: CGFloat = 320

    /// A card holding `count` rows of a known height, so that what the card
    /// adds can be measured by subtraction.
    static func card(rows count: Int) throws -> Raster {
        try #require(
            Raster(
                SettingsCard {
                    ForEach(0..<count, id: \.self) { _ in
                        Color.clear.frame(height: SettingsCardTests.rowHeight)
                    }
                }
                .frame(width: width)
                .background(Color.night)))
    }

    /// The card's one job beyond its shape, and the reason it cannot be a
    /// `VStack` at the call site: a divider between every pair of rows and
    /// none at either end. Measured rather than looked for, because a hairline
    /// of ink at 0.12 over a panel at 0.08 is a very small difference in a
    /// picture and an exact one in a height.
    @Test("A divider goes between two rows and never at an end")
    func dividersGoBetweenRows() throws {
        let one = try Self.card(rows: 1)
        let two = try Self.card(rows: 2)
        let three = try Self.card(rows: 3)

        let step = Double(Self.rowHeight + ControlMetrics.divider)

        #expect(
            abs(Double(two.height - one.height) - step) < 1,
            "the second row did not bring exactly one divider with it")
        #expect(
            abs(Double(three.height - two.height) - step) < 1,
            "the third row did not bring exactly one divider with it")

        // And nothing at the ends: one row is the row plus the card's own
        // padding, with no divider above or below it.
        #expect(
            abs(
                Double(one.height)
                    - Double(Self.rowHeight + 2 * ControlMetrics.cardPaddingVertical)) < 1,
            "a single row is wearing a divider")
    }
}

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
