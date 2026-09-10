import CoreGraphics

/// The controls' sizes, off the boards.
///
/// The same argument `CourtMetrics` makes, for the other half of the package:
/// the court is drawn in fractions of its half because it is stretched across
/// two very different screens, and a control is not — a button is very nearly
/// the same size on a wrist as in a hand, so the numbers here are absolute and
/// resolve per platform.
///
/// The watch boards are drawn at 2x and the phone boards at 1x, so a watch
/// number is the board's pixels halved and a phone number is the board's
/// pixels (the spec's "Reading the boards"). **Type sizes are not here** —
/// they come from ``TypeRamp``, which is the whole reason a screen never names
/// a face.
///
/// Every height here is a **minimum**. A control whose height is fixed is a
/// control that clips the first time somebody turns Dynamic Type up, and the
/// boards are drawn at one setting out of twelve.
enum ControlMetrics {
    // MARK: The segmented choice

    /// One side of the two-way choice: 58px on the watch's board, 62 on the
    /// phone's.
    static var segmentHeight: CGFloat { Platform.value(watch: 29, phone: 62) }

    /// Between one capsule and the next — side by side on the phone, down the
    /// page on the watch.
    static var segmentGap: CGFloat { Platform.value(watch: 3.5, phone: 8) }

    /// Left and right of a capsule's label, so a long one is padded rather
    /// than pressed against the ring.
    static var segmentPadding: CGFloat { Platform.value(watch: 3.5, phone: 8) }

    /// The ring around the chosen side. Inset, so it sits inside the segment
    /// rather than growing it — the boards draw it as `inset` box shadow.
    static var segmentRing: CGFloat { Platform.value(watch: 1, phone: 2) }

    // MARK: The settings card

    /// Left and right of the rows — and so also of the dividers, which is why
    /// they stop short of the card's own edge.
    static var cardPadding: CGFloat { Platform.value(watch: 8, phone: 18) }

    /// Above the first row and below the last. Small on purpose: the rows
    /// carry their own height, and the card is a shape around them rather
    /// than a box with air in it.
    static let cardPaddingVertical: CGFloat = 2

    /// Above and below what a row or a capsule holds — its own padding, not
    /// the card's, so that a row inside a card does not pay both.
    static let rowPaddingVertical: CGFloat = 2

    /// The line between two rows. Half a point on the watch is one physical
    /// pixel at 2x, which is what the board draws.
    static var divider: CGFloat { Platform.value(watch: 0.5, phone: 1) }

    // MARK: The rows in the card

    /// A row in the card: 64px on the watch's board, 68 on the phone's. It is
    /// the card that decides how tall a row is, not what the row does — a row
    /// that stands its value under its label asks for ``stackedRowHeight``
    /// instead, which is this floor raised by the second line and nothing
    /// else.
    static var rowHeight: CGFloat { Platform.value(watch: 32, phone: 68) }

    /// Between a row's label and whatever stands with it — the ± beside it on
    /// the phone, the chosen value under it on the watch.
    static var rowGap: CGFloat { Platform.value(watch: 6, phone: 14) }

    /// A row that stands its value *under* its label: two lines of type, the
    /// gap between them, and the row's own padding above and below.
    ///
    /// The watch's ``ChoiceRow`` reaches this by holding two texts, and the
    /// number is written down for the rows that hold one and have to stand
    /// among them without looking short — the golden point, which is a label
    /// and a switch. On the phone no row stacks and this is ``rowHeight``,
    /// which is why the toggle can ask for it on either platform.
    ///
    /// A minimum like every other height here: turn Dynamic Type up and the
    /// two texts grow past it, with the toggle's own label growing beside
    /// them.
    static var stackedRowHeight: CGFloat {
        max(
            rowHeight,
            (TypeRamp.body.size + TypeRamp.control.size) * lineHeight + rowGap
                + 2 * rowPaddingVertical)
    }

    /// How much taller a line is than the type it is set in — the room the
    /// face keeps above the ascenders and below the descenders.
    private static let lineHeight: CGFloat = 1.2

    // MARK: The stepper row, which is the phone's alone

    /// The circular − and + .
    ///
    /// A phone number and not a pair: ``StepperRow`` is unavailable on
    /// watchOS, and the board's 15pt circle is exactly why (see that control's
    /// doc comment). The Mac takes it because the Mac takes the phone's
    /// numbers, which is what lets the tests measure this control at all.
    static let stepperButton: CGFloat = 34

    /// What the finger actually has to hit — larger than the circle drawn
    /// under it, which costs the layout nothing: see ``stepperSpacing``.
    static let stepperHit: CGFloat = 44

    /// The spacing that leaves the *drawn* gap at ``rowGap`` once each button
    /// is wearing a hit area wider than its circle.
    ///
    /// Half the overhang sits on each side of the circle, so it is half the
    /// overhang that has to come out of the spacing.
    static var stepperSpacing: CGFloat {
        max(0, rowGap - (stepperHit - stepperButton) / 2)
    }

    /// The bar of the − and the + , which the board draws as `M5 12h14` in a
    /// 24-unit box: 14 units of a 15pt icon.
    static let stepperGlyph: CGFloat = 9

    /// How thick that bar is — the board's `stroke-width: 2.8` at the same
    /// scale, round-capped.
    static let stepperGlyphStroke: CGFloat = 1.8

    /// The width kept for the value, so that 9 and 40 do not move the two
    /// buttons apart.
    static let stepperValue: CGFloat = 20

    // MARK: The pill button

    /// 64 on the phone, and about half that on the wrist.
    static var pillHeight: CGFloat { Platform.value(watch: 32, phone: 64) }

    /// Around the label, so a label too long for the pill's width grows the
    /// pill instead of being cut.
    static var pillPadding: CGFloat { Platform.value(watch: 8, phone: 16) }

    /// Above and below the label, for the same reason.
    static var pillPaddingVertical: CGFloat { Platform.value(watch: 5, phone: 10) }

    /// Between the ball and the label it rides beside.
    static var pillGap: CGFloat { Platform.value(watch: 5.5, phone: 11) }

    /// The ball on the primary button — 21pt on the history board.
    static var pillBall: CGFloat { Platform.value(watch: 11, phone: 21) }

    // MARK: The history tile

    /// Left and right of whatever the tile is carrying.
    static var tilePadding: CGFloat { Platform.value(watch: 9, phone: 18) }

    /// Above and below it.
    static var tilePaddingVertical: CGFloat { Platform.value(watch: 8, phone: 16) }

    /// The `ball` glow a won match carries. 74×74 on the board, hung off the
    /// corner so that only its inner quarter falls on the tile.
    static var tileGlow: CGFloat { Platform.value(watch: 37, phone: 74) }

    /// How far past the corner it hangs.
    static var tileGlowOffset: CGFloat { Platform.value(watch: 7, phone: 14) }
}
