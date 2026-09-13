import PadelScoring
import SwiftUI

/// The app's colors, read off the redesign's boards (`docs/design/`).
///
/// There is one palette and no light variant: a court at noon is a second
/// design nobody has drawn (ADR-0006). The phone pins `.dark`; the watch is
/// dark already.
///
/// **Every color the boards spend is named here** — including the ones no
/// screen will ever ask for, because tickets 02 and 03 draw the net, the ball
/// and the controls out of this file rather than out of their own hex
/// literals. What a screen uses is `public`; what only this package's own
/// primitives use is `internal`, so the distinction is enforced rather than
/// merely documented.
///
/// The public tokens are spelled twice — once on `Color`, so they can be
/// handed around as values, and once on `ShapeStyle`, so a call site can write
/// `.foregroundStyle(.ball)` the way it writes `.foregroundStyle(.red)`.
extension Color {
    // MARK: The ground and the two halves

    /// The app's ground: everything outside the court.
    public static let night = Color(hex: 0x04_18_1F)

    /// Glass blue — the half across the net, drawn at the top because that is
    /// where it is when you stand on court.
    public static let theirHalf = Color(hex: 0x0E_3D_4C)

    /// Turf green — our half, at the bottom.
    public static let ourHalf = Color(hex: 0x12_56_4F)

    // MARK: The one accent

    /// The ball's yellow, and the only color in the app.
    ///
    /// It means exactly one thing: *this is yours, or this is chosen*. It
    /// marks the serve, the half you picked, and the button that starts the
    /// match. Losses go cold and gray — there is no red anywhere, because a
    /// second color would argue with this one until it meant nothing but
    /// "good" (ADR-0006).
    public static let ball = Color(hex: 0xDD_F3_5C)

    /// A label on `ball` yellow.
    public static let onBall = Color(hex: 0x16_26_0A)

    /// The fill behind something chosen — `ball` laid on thin enough to read
    /// as a tint rather than as the ball itself. The selected segment and the
    /// picked half are drawn on it.
    public static let ballWash = Color.ball.opacity(0.14)

    /// The knob of a `ball`-tinted `Toggle`.
    ///
    /// Deep teal and not black: on the boards the knob keeps a trace of the
    /// court under it, and a black knob reads as a hole punched in the track.
    public static let knob = Color(hex: 0x0B_2B_26)

    /// The dark green of the ball's two seam arcs, at the weight the boards
    /// draw them.
    ///
    /// Not `onBall`: a label on the ball is nearly black, and a seam at that
    /// strength turns the ball into a beach ball. ``Ball`` draws the arcs.
    static let ballSeam = Color(hex: 0x14_28_12).opacity(0.4)

    /// The seams of the ball cut out of a `ball`-yellow button — the one
    /// place the ball is drawn the other way round, dark felt and bright
    /// seams, because the court's own ball there would be yellow on yellow.
    ///
    /// The ball's own color rather than the ink's: a white seam on a dark disc
    /// in a yellow button is a third value in a shape 21pt across.
    static let ballSeamCutOut = Color.ball.opacity(0.8)

    // MARK: The net

    /// The net's tape, seen from directly above.
    static let netTape = Color.ink.weight(.tape)

    /// The post at each end of the tape, brighter than the tape it holds —
    /// which is what makes the net read as seen from above rather than as a
    /// divider drawn across the screen.
    static let netPost = Color.ink.weight(.post)

    /// The shadow that lifts the net and the ball off the court.
    ///
    /// One value for both. The boards draw the net's at 0.5 and the ball's at
    /// 0.45, and two shadows five hundredths apart are one shadow written
    /// twice.
    static let shadow = Color.black.opacity(0.5)

    // MARK: The ink

    /// Text and lines on `night`. Weighted with ``Color/weight(_:)`` rather
    /// than with an opacity written at the call site.
    public static let ink = Color(hex: 0xEE_F7_F5)

    /// Text inside their half — the ink cooled to sit on glass blue.
    public static let inkTheirHalf = Color(hex: 0xDC_EF_E9)

    /// Text inside our half — the ink warmed to sit on turf green.
    public static let inkOurHalf = Color(hex: 0xF4_FF_FB)

    // MARK: The paint the court's lines are drawn in

    /// The white the lines on their half are painted in, before a weight.
    ///
    /// Never spent at full strength — ``Color/courtLine(_:on:dimmed:)`` is the
    /// only way in, which is why this is `internal`.
    static let lineTheirHalf = Color(hex: 0xB4_EB_DE)

    /// The white the lines on our half are painted in, before a weight. The
    /// brighter of the two: the boards light the near half more.
    static let lineOurHalf = Color(hex: 0xBE_F5_E4)

    // MARK: The light

    /// The floodlight's warm white.
    ///
    /// A color only in the sense that light has one. It is spent as a
    /// gradient — see ``SwiftUI/Gradient/floodlight(strength:)`` — and never
    /// as a fill, because the moment it reads as a hue the app has two
    /// accents instead of one.
    public static let floodlight = Color(hex: 0xFF_F8_D6)
}

// MARK: - Weights

/// A named weight of the ink.
///
/// The boards give the ink a dozen opacities and the same hex every time —
/// `rgba(238, 247, 245, α)`. That is one color at a weight, not a dozen
/// colors, so it is one token and this vocabulary, and a screen never writes
/// the number.
///
/// Ordered from full strength down. Three collapses are deliberate:
/// `hairline` and `surface` land on the same 0.12 and have no reason to move
/// together, the boards' 0.10 divider is read as `hairline` rather than given
/// a weight of its own — two hundredths apart is one weight drawn twice — and
/// `tape` and `control` land on the same 0.82 from opposite ends of the app.
public enum InkWeight: Sendable, CaseIterable {
    /// Full strength — a title, a score, the thing being read.
    case primary

    /// The post at each end of the net's tape.
    case post

    /// The net's tape itself.
    case tape

    /// The ink a control is drawn in — a settings row's label, the bar of a
    /// stepper's − and + .
    ///
    /// Named for the same role ``TypeRamp/control`` is named for, and it lands
    /// on `tape`'s number rather than being spent as it: the net is a shape on
    /// a court and a row label is a word under a finger, and the day one of
    /// them moves the other has no business moving with it.
    ///
    /// The boards spend 0.82 on the wrist and 0.85 in the hand. That is one
    /// weight drawn twice, by the rule the paragraph above states.
    case control

    /// A label that is legible but not chosen — the unselected half of a
    /// two-way choice.
    case strong

    /// A label beside the thing being read.
    case secondary

    /// A hint, a unit, a caption that is there when looked for.
    case tertiary

    /// A 1pt border or divider.
    case hairline

    /// A translucent panel: the settings card, a quiet button.
    case surface

    /// A translucent panel that must stay further back than `surface`.
    case surfaceQuiet

    public var opacity: Double {
        switch self {
        case .primary: 1
        case .post: 0.9
        case .tape: 0.82
        case .control: 0.82
        case .strong: 0.65
        case .secondary: 0.55
        case .tertiary: 0.4
        case .hairline: 0.12
        case .surface: 0.12
        case .surfaceQuiet: 0.08
        }
    }
}

extension Color {
    /// This color at a named weight.
    ///
    /// Written for the ink, but not restricted to it: `ourHalf` and `ball`
    /// take the same vocabulary, and the point of the vocabulary is that the
    /// number lives here and not at the call site.
    public func weight(_ weight: InkWeight) -> Color {
        opacity(weight.opacity)
    }
}

// MARK: - Reading the boards

extension Color {
    /// A color from the hex the boards are written in.
    ///
    /// The boards are HTML and give their colors as `#rrggbb`. Converting each
    /// one to three fractions by hand is where a palette drifts from the
    /// design it was read off, so the conversion happens once, here, and every
    /// token above reads like the line it came from.
    ///
    /// Deliberately not `public`: a screen that can build a color from a hex
    /// is a screen that can invent one, and the whole of this package is the
    /// argument that it should not.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255)
    }
}

// MARK: - The same tokens, as shape styles

/// `.foregroundStyle(.ball)` rather than `.foregroundStyle(Color.ball)`.
///
/// Implicit member syntax looks up static members on the type it can infer,
/// and in a `some ShapeStyle` position that is not `Color`. SwiftUI declares
/// its own colors twice for the same reason; so does this palette.
///
/// The mirror covers every `public` token, the court's four included — a
/// half-mirror would mean a call site writing `.fill(.ball)` on one line and
/// `.fill(Color.courtSurface(side))` on the next.
extension ShapeStyle where Self == Color {
    /// See ``SwiftUI/Color/night``.
    public static var night: Color { Color.night }

    /// See ``SwiftUI/Color/theirHalf``.
    public static var theirHalf: Color { Color.theirHalf }

    /// See ``SwiftUI/Color/ourHalf``.
    public static var ourHalf: Color { Color.ourHalf }

    /// See ``SwiftUI/Color/ball``.
    public static var ball: Color { Color.ball }

    /// See ``SwiftUI/Color/onBall``.
    public static var onBall: Color { Color.onBall }

    /// See ``SwiftUI/Color/ballWash``.
    public static var ballWash: Color { Color.ballWash }

    /// See ``SwiftUI/Color/knob``.
    public static var knob: Color { Color.knob }

    /// See ``SwiftUI/Color/ink``.
    public static var ink: Color { Color.ink }

    /// See ``SwiftUI/Color/inkTheirHalf``.
    public static var inkTheirHalf: Color { Color.inkTheirHalf }

    /// See ``SwiftUI/Color/inkOurHalf``.
    public static var inkOurHalf: Color { Color.inkOurHalf }

    /// See ``SwiftUI/Color/floodlight``.
    public static var floodlight: Color { Color.floodlight }

    /// See ``SwiftUI/Color/courtSurface(_:dimmed:)``.
    ///
    /// The defaulted `dimmed:` is mirrored too, and not dropped. Without it
    /// the concrete overload becomes the worse match for `courtSurface(side)`
    /// alone, this one wins, and the forward below calls itself.
    public static func courtSurface(_ side: Side, dimmed: Bool = false) -> Color {
        Color.courtSurface(side, dimmed: dimmed)
    }

    /// See ``SwiftUI/Color/courtInk(_:)-(Side)``.
    public static func courtInk(_ side: Side) -> Color { Color.courtInk(side) }

    /// See ``SwiftUI/Color/courtInk(_:)-(MatchOutcome)``.
    public static func courtInk(_ outcome: MatchOutcome) -> Color { Color.courtInk(outcome) }

    /// See ``SwiftUI/Color/courtLine(_:on:dimmed:)``.
    public static func courtLine(
        _ line: CourtLine, on side: Side, dimmed: Bool = false
    ) -> Color {
        Color.courtLine(line, on: side, dimmed: dimmed)
    }

    /// See ``SwiftUI/Color/courtWeave(on:dimmed:)``.
    public static func courtWeave(on side: Side, dimmed: Bool = false) -> Color {
        Color.courtWeave(on: side, dimmed: dimmed)
    }
}
