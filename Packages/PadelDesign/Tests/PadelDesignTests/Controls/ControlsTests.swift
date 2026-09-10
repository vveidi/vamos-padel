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
/// **Not checkable: the push.** `ChoiceRow` opens a page, and what a rendered
/// row can be asked is what it says before the tap — the label, and the chosen
/// value lit in `ball`. That the page comes up already scrolled to what is
/// chosen is a `ScrollViewReader` doing its job, and it is checked on a wrist
/// and in the preview, not here.
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

/// The watch's row: what it says with the page still shut.
///
/// It renders on the Mac because `@available(iOS, unavailable)` excludes iOS
/// and nothing else — which is the point of marking the pair that way rather
/// than wrapping them in `#if`: the two platforms' controls are still one
/// module, and both can be measured from one test run.
@Suite("The choice row")
@MainActor
struct ChoiceRowTests {
    static let width: CGFloat = 198

    static func row(
        chosen: Int = 2, in range: ClosedRange<Int> = 1...3, label: String = "Sets",
        width: CGFloat = ChoiceRowTests.width
    ) throws -> Raster {
        var held = chosen

        let binding = Binding(get: { held }, set: { held = $0 })

        return try #require(
            Raster(
                NavigationStack {
                    ChoiceRow(Text(verbatim: label), value: binding, in: range)
                }
                .frame(width: width)
                .background(Color.night)))
    }

    /// The row's whole job with the page shut: say which one is chosen. A row
    /// that drew the same thing for 2 and for 3 would send the player into the
    /// page to find out what they already set.
    @Test("The row shows the value that is chosen")
    func theChosenValueIsOnTheRow() throws {
        let two = try Self.row(chosen: 2)
        let three = try Self.row(chosen: 3)

        // The bottom half of the row, which is where the value stands now that
        // it is under the label: the label itself says "Sets" in both.
        let strip = { (raster: Raster) in
            raster.meanLuminance(
                columns: 0..<raster.width,
                rows: (raster.height / 2)..<raster.height)
        }

        #expect(strip(two) != strip(three), "the row draws the same thing for 2 and 3")
    }

    /// The brief allows no chevron, so the value lit in `ball` is the whole of
    /// the affordance — it is the only lit thing on an otherwise quiet row,
    /// and in this app `ball` means "this is yours, or this is chosen".
    ///
    /// *Where* it is lit is the other half of the check: under the label at
    /// the leading edge, and nothing lit on the label's own line.
    @Test("The value is lit in ball, on its own line under the label")
    func theValueIsDrawnInBall() throws {
        let raster = try Self.row()

        let lit = { (columns: Range<Int>, rows: Range<Int>) in
            columns.contains { column in
                rows.contains { row in
                    raster.pixel(column, row, isCloseTo: .ball, tolerance: 0.2)
                }
            }
        }

        #expect(
            lit(0..<(raster.width / 3), (raster.height / 2)..<raster.height),
            "nothing under the label is drawn in the accent")
        #expect(
            !lit(0..<raster.width, 0..<(raster.height / 3)),
            "the value is on the label's line rather than under it")
    }

    /// Two texts tall for every value, and not only for the ones that ran out
    /// of width. A card of these rows is read as a column of one shape, which
    /// a row that stacked only in Russian would not give it.
    @Test("A row is as tall as its label and its value together")
    func theRowStandsTwoTextsTall() throws {
        let short = try Self.row()
        let long = try Self.row(label: "Подача через (X)", width: 110)

        #expect(Double(short.height) >= Double(ControlMetrics.stackedRowHeight))
        #expect(Double(long.height) >= Double(ControlMetrics.stackedRowHeight))
    }

    /// The page a row opens is a column of the same shape as the card it came
    /// from — tapping a row should not swap cells of one height for cells of
    /// another. `ChoiceList` is private and nothing here can push it, so the
    /// question goes to the capsule it fills the page with.
    @Test("A capsule down the page stands as tall as the row that opened it")
    func thePageKeepsTheCardsShape() throws {
        let capsule = { (place: ChoiceCapsule.Place) in
            Raster(
                ChoiceCapsule(label: Text(verbatim: "16"), isChosen: true, place: place)
                    .frame(width: ChoiceRowTests.width)
                    .background(Color.night))
        }

        let onThePage = try #require(capsule(.downThePage))
        let besideItsTwin = try #require(capsule(.besideItsTwin))

        #expect(Double(onThePage.height) >= Double(ControlMetrics.stackedRowHeight))
        #expect(
            onThePage.height > besideItsTwin.height,
            "the page is drawn in the phone's segment height")
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
