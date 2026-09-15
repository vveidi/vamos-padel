import PadelScoring
import SwiftUI
import Testing

@testable import PadelDesign

/// - Note: macOS has no Dynamic Type, so nothing here turns the type up. A
///   narrow frame is the stand-in — the same `ViewThatFits` fires whenever the
///   width runs out. The thicknesses these tests see are the phone's, because
///   `Platform` gives the Mac the phone's numbers.
@Suite("The segmented choice")
@MainActor
struct SegmentedChoiceTests {
    static let width: CGFloat = 320

    static func choice(
        selecting chosen: Bool, labels: (String, String) = ("Classic", "By points"),
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
    /// `edge`. A band of columns rather than one, because the ring is two
    /// points wide and its outer pixel is shared with the corner's
    /// antialiasing.
    static func isRinged(_ raster: Raster, from edge: Int) -> Bool {
        let middle = raster.height / 2

        return (0..<4).contains {
            raster.pixel(edge + $0, middle, isCloseTo: .ball, tolerance: 0.12)
        }
    }

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

    @Test("Two labels that will not fit side by side stack instead")
    func theSegmentsStackWhenTheyRunOutOfWidth() throws {
        let beside = try Self.choice(selecting: true)
        let stacked = try Self.choice(
            selecting: true,
            labels: ("Классический счёт", "Счёт по очкам"),
            width: 120)

        #expect(
            stacked.height > beside.height,
            "the segments stayed side by side and squeezed instead")
        #expect(
            Double(stacked.height) > Double(ControlMetrics.segmentHeight) * 1.8,
            "the second segment did not go under the first")
    }
}

/// The watch's row renders on the Mac because `@available(iOS, unavailable)`
/// excludes iOS and nothing else, so both platforms' controls can be measured
/// from one test run.
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

    @Test("The row shows the value that is chosen")
    func theChosenValueIsOnTheRow() throws {
        let two = try Self.row(chosen: 2)
        let three = try Self.row(chosen: 3)

        // The bottom half of the row, where the value stands under the label:
        // the label itself says "Sets" in both.
        let strip = { (raster: Raster) in
            raster.meanLuminance(
                columns: 0..<raster.width,
                rows: (raster.height / 2)..<raster.height)
        }

        #expect(strip(two) != strip(three), "the row draws the same thing for 2 and 3")
    }

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

    @Test("A row that opens a list says so at its trailing edge")
    func theRowWearsAChevron() throws {
        let raster = try Self.row()

        let band = Int(ControlMetrics.chevronWell)
        let middle = raster.height / 2
        let rows = (middle - band / 2)..<(middle + band / 2)

        let trailing = raster.meanLuminance(
            columns: (raster.width - band)..<raster.width, rows: rows)
        // Against a band just inside it, so a dark row does not read as a
        // missing chevron.
        let ground = raster.meanLuminance(
            columns: (raster.width - 3 * band)..<(raster.width - 2 * band), rows: rows)

        #expect(trailing > ground, "nothing is drawn where the chevron should be")
    }

    /// Two texts tall for every value, and not only for the ones that ran out
    /// of width: a card of these rows is read as a column of one shape.
    @Test("A row is as tall as its label and its value together")
    func theRowStandsTwoTextsTall() throws {
        let short = try Self.row()
        let long = try Self.row(label: "Подача через (X)", width: 110)

        #expect(Double(short.height) >= Double(ControlMetrics.stackedRowHeight))
        #expect(Double(long.height) >= Double(ControlMetrics.stackedRowHeight))
    }

    /// `ChoiceList` is private and nothing here can push it, so the question
    /// goes to the capsule it fills the page with.
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

    /// Compared between the two ends of the range rather than against a
    /// number: what matters is that the unreachable button is fainter than the
    /// reachable one, whatever the exact opacity.
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

    /// Rows of a known height, so that what the card adds can be measured by
    /// subtraction.
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

    /// Measured rather than looked for: a hairline of ink at 0.12 over a panel
    /// at 0.08 is a very small difference in a picture and an exact one in a
    /// height.
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
        // padding.
        #expect(
            abs(
                Double(one.height)
                    - Double(Self.rowHeight + 2 * ControlMetrics.cardPaddingVertical)) < 1,
            "a single row is wearing a divider")
    }
}
