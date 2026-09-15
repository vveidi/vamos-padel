import CoreGraphics

/// The controls' sizes, off the boards — the board's pixels halved on the
/// watch, which is drawn at 2x, and at face value on the phone, drawn at 1x.
///
/// - Important: Every height here is a minimum, except ``switchTrack``.
enum ControlMetrics {
    // MARK: The segmented choice

    /// 58px on the watch's board, 62 on the phone's.
    static var segmentHeight: CGFloat { Platform.value(watch: 29, phone: 62) }

    static var segmentGap: CGFloat { Platform.value(watch: 3.5, phone: 8) }

    static var segmentPadding: CGFloat { Platform.value(watch: 3.5, phone: 8) }

    /// The ring around the chosen side. Inset, so it sits inside the segment
    /// rather than growing it — the boards draw it as an `inset` box shadow.
    static var segmentRing: CGFloat { Platform.value(watch: 1, phone: 2) }

    // MARK: The settings card

    static var cardPadding: CGFloat { Platform.value(watch: 8, phone: 18) }

    static let cardPaddingVertical: CGFloat = 2

    /// A row's own padding, not the card's, so a row inside a card does not pay
    /// both.
    static let rowPaddingVertical: CGFloat = 2

    /// Half a point on the watch is one physical pixel at 2x, which is what the
    /// board draws.
    static var divider: CGFloat { Platform.value(watch: 0.5, phone: 1) }

    // MARK: The rows in the card

    /// 64px on the watch's board, 68 on the phone's.
    static var rowHeight: CGFloat { Platform.value(watch: 32, phone: 68) }

    static var rowGap: CGFloat { Platform.value(watch: 6, phone: 14) }

    /// ``rowHeight`` raised by a second line, for a row that stands its value
    /// *under* its label. Written down so the rows holding one line can stand
    /// among them without looking short; on the phone no row stacks and this is
    /// ``rowHeight``.
    static var stackedRowHeight: CGFloat {
        max(
            rowHeight,
            (TypeRamp.body.size + TypeRamp.control.size) * lineHeight + rowGap
                + 2 * rowPaddingVertical)
    }

    /// How much taller a line is than the type it is set in.
    private static let lineHeight: CGFloat = 1.2

    // MARK: The chevron on a row that opens something

    /// 10px on the watch's board.
    static var rowGapToChevron: CGFloat { Platform.value(watch: 5, phone: 10) }

    /// The well the chevron sits in. 26px.
    static var chevronWell: CGFloat { Platform.value(watch: 13, phone: 26) }

    /// The board's chevron is a 14px box holding a glyph 12 units of 24 tall —
    /// about 3.5pt of actual chevron. SF's is measured by type size rather than
    /// by its box, and 9pt is where it lands on about the same height.
    static var chevron: CGFloat { Platform.value(watch: 9, phone: 18) }

    // MARK: The switch

    /// 52×31px on the watch's board, 56×33 on the phone's. The one size here
    /// that is not a minimum — see ``BallSwitch``.
    static var switchTrack: CGSize {
        CGSize(
            width: Platform.value(watch: 26, phone: 56),
            height: Platform.value(watch: 15.5, phone: 33))
    }

    /// How much track shows all round the knob — the boards' 3px, on both.
    static var switchKnobInset: CGFloat { Platform.value(watch: 1.5, phone: 3) }

    // MARK: The stepper row, which is the phone's alone

    /// A phone number and not a pair: ``StepperRow`` is unavailable on watchOS.
    /// The Mac takes it along with the rest of the phone's numbers, which is
    /// what lets the tests measure this control at all.
    static let stepperButton: CGFloat = 34

    /// What the finger has to hit, larger than the circle drawn under it.
    static let stepperHit: CGFloat = 44

    /// The spacing that leaves the *drawn* gap at ``rowGap`` once each button
    /// wears a hit area wider than its circle, half the overhang per side.
    static var stepperSpacing: CGFloat {
        max(0, rowGap - (stepperHit - stepperButton) / 2)
    }

    /// The bar of the − and the + , which the board draws as `M5 12h14` in a
    /// 24-unit box: 14 units of a 15pt icon.
    static let stepperGlyph: CGFloat = 9

    /// The board's `stroke-width: 2.8` at the same scale, round-capped.
    static let stepperGlyphStroke: CGFloat = 1.8

    /// The width kept for the value, so that 9 and 40 do not move the two
    /// buttons apart.
    static let stepperValue: CGFloat = 20

    // MARK: The pill button

    static var pillHeight: CGFloat { Platform.value(watch: 32, phone: 64) }

    static var pillPadding: CGFloat { Platform.value(watch: 8, phone: 16) }

    static var pillPaddingVertical: CGFloat { Platform.value(watch: 5, phone: 10) }

    static var pillGap: CGFloat { Platform.value(watch: 5.5, phone: 11) }

    /// 21pt on the history board.
    static var pillBall: CGFloat { Platform.value(watch: 11, phone: 21) }

    // MARK: The history tile

    static var tilePadding: CGFloat { Platform.value(watch: 9, phone: 18) }

    static var tilePaddingVertical: CGFloat { Platform.value(watch: 8, phone: 16) }

    /// 74×74 on the board, hung off the corner so that only its inner quarter
    /// falls on the tile.
    static var tileGlow: CGFloat { Platform.value(watch: 37, phone: 74) }

    static var tileGlowOffset: CGFloat { Platform.value(watch: 7, phone: 14) }
}
