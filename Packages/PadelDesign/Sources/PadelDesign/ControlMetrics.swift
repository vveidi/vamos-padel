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

    /// Between the two sides.
    static var segmentGap: CGFloat { Platform.value(watch: 3.5, phone: 8) }

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

    /// The line between two rows. Half a point on the watch is one physical
    /// pixel at 2x, which is what the board draws.
    static var divider: CGFloat { Platform.value(watch: 0.5, phone: 1) }

    // MARK: The stepper row

    /// A row in the card: 64px on the watch's board, 68 on the phone's.
    static var rowHeight: CGFloat { Platform.value(watch: 32, phone: 68) }

    /// The circular − and + .
    static var stepperButton: CGFloat { Platform.value(watch: 15, phone: 34) }

    /// What the finger actually has to hit.
    ///
    /// Larger than the circle it is drawn around, and deliberately so: the
    /// board's watch circle is 15pt across, which is a target nobody hits on a
    /// moving wrist. The circle stays the board's size and the hit area grows
    /// under it, which costs the layout nothing — see ``stepperSpacing``.
    static var stepperHit: CGFloat { Platform.value(watch: 26, phone: 44) }

    /// Between a circle and the value it moves, on the boards.
    static var stepperGap: CGFloat { Platform.value(watch: 6, phone: 14) }

    /// The spacing that leaves the *drawn* gap at ``stepperGap`` once each
    /// button is wearing a hit area wider than its circle.
    ///
    /// Half the overhang sits on each side of the circle, so it is half the
    /// overhang that has to come out of the spacing.
    static var stepperSpacing: CGFloat {
        max(0, stepperGap - (stepperHit - stepperButton) / 2)
    }

    /// The bar of the − and the + , which the board draws as `M5 12h14` in a
    /// 24-unit box: 14 units of a 15pt icon on the phone.
    static var stepperGlyph: CGFloat { Platform.value(watch: 4, phone: 9) }

    /// How thick that bar is — the board's `stroke-width: 2.8` at the same
    /// scale, round-capped.
    static var stepperGlyphStroke: CGFloat { Platform.value(watch: 1, phone: 1.8) }

    /// The width kept for the value, so that 9 and 40 do not move the two
    /// buttons apart.
    static var stepperValue: CGFloat { Platform.value(watch: 9, phone: 20) }

    /// The ring around the row the Digital Crown will move. Watch only —
    /// there is no crown to point at anywhere else.
    static var focusRing: CGFloat { Platform.value(watch: 1.5, phone: 2) }

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
