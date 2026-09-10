import SwiftUI

/// One entry of the type ramp.
///
/// Screens name entries, never faces. That is the whole point of the ramp: the
/// boards are set in Unbounded and Golos Text, ticket 11 decides whether those
/// two ship, and whatever it decides it changes this file and no screen. A
/// screen that wrote `.system(size: 64, weight: .semibold, design: .rounded)`
/// — as `ScoreView` does today — would have to be rewritten instead.
///
/// Seven entries, and seven is the budget. An eighth is a sign that a screen
/// wants a size rather than a role, and the answer to that is nearly always
/// one of these seven.
public enum TypeRamp: Sendable, CaseIterable {
    /// The score. The largest thing on any screen.
    ///
    /// The watch's 46 is the board's 92px at 2x, and it is here because it was
    /// looked at rather than because the arithmetic worked: ticket 04 put the
    /// worst score this screen has — "40" with a games digit and a sets digit
    /// beside it — on the smallest watch there is, and at 46 it clears the
    /// zone with room to spare. The 64 the screen used before the redesign was
    /// a number for a score on a blank half; a score on a court needs the
    /// court to be visible around it.
    case score

    /// The games digit beside the score, sharing its baseline.
    ///
    /// Paired with ``score`` on purpose: `ScoreView` sets the two on one
    /// baseline, so they have to grow and shrink together or the baseline
    /// breaks the first time somebody turns Dynamic Type up.
    case scoreAside

    /// A screen title, or a number being set — the stepper's value.
    case display

    /// The score on a history tile. Smaller than ``display`` because a tile is
    /// read in a scrolling column, not looked at.
    case tileScore

    /// A button, a segment, a row label — anything the finger is aimed at.
    case control

    /// Running text.
    case body

    /// A note under something, read only when looked for.
    case caption

    /// The size at the default Dynamic Type setting.
    ///
    /// The watch numbers are not the phone's halved. The boards' watch
    /// artboards are 2x and their *type* is not — a 14px row label halved is
    /// 7pt, below anything watchOS has a text style for. Layout transfers from
    /// the boards; type sizes come from here (see the spec's "Reading the
    /// boards").
    public var size: CGFloat {
        switch self {
        case .score: Platform.value(watch: 46, phone: 128)
        case .scoreAside: Platform.value(watch: 14, phone: 38)
        case .display: Platform.value(watch: 17, phone: 31)
        case .tileScore: Platform.value(watch: 15, phone: 25)
        case .control: Platform.value(watch: 15, phone: 16)
        case .body: Platform.value(watch: 14, phone: 15)
        case .caption: Platform.value(watch: 13, phone: 13)
        }
    }

    /// The system text style this entry scales against.
    ///
    /// This is the `relativeTo:` of the ramp, and it is what keeps Dynamic
    /// Type working after the screens stop naming system styles. Without it
    /// the sizes above are a freeze rather than a starting point, and a player
    /// who turned the text up gets the same 13pt caption as everyone else.
    ///
    /// `.scoreAside` is anchored to `.largeTitle` alongside `.score`, and not
    /// to the `.title2` its own size would suggest. Two text styles do not
    /// scale by the same factor, so anchoring the pair apart would let the
    /// games digit drift off the score's baseline at the far end of the
    /// range — which is the one thing the ticket says the pair must not do.
    public var relativeTo: Font.TextStyle {
        switch self {
        case .score: .largeTitle
        case .scoreAside: .largeTitle
        case .display: .title3
        case .tileScore: .title3
        case .control: .headline
        case .body: .body
        case .caption: .caption
        }
    }

    /// SF Rounded for the numbers and the titles, SF for everything else.
    ///
    /// The split follows the boards, which set the numbers and titles in
    /// Unbounded — a geometric face with round bowls — and the rest in Golos
    /// Text. Ticket 11 is where the real faces arrive, and this is the column
    /// it replaces.
    public var design: Font.Design {
        switch self {
        case .score, .scoreAside, .display, .tileScore: .rounded
        case .control, .body, .caption: .default
        }
    }

    public var weight: Font.Weight {
        switch self {
        case .score, .display, .tileScore, .control: .semibold
        case .scoreAside: .medium
        case .body, .caption: .regular
        }
    }

    /// The entry as a `Font`, frozen at the default Dynamic Type setting.
    ///
    /// Deliberately not `public`. It is the ramp with its anchor stripped off,
    /// and `.font(entry.font)` compiles, looks right, and silently never
    /// scales — an escape hatch straight past the thing this ramp exists for.
    /// A screen wants ``SwiftUI/View/textStyle(_:)``, which is this font
    /// scaled by the reader's setting.
    ///
    /// It survives as `internal` because the tests need a value to compare
    /// entries by, and because a `Canvas` inside this package would have no
    /// other way to ask for one.
    var font: Font {
        .system(size: size, weight: weight, design: design)
    }
}

extension View {
    /// Sets the type from the ramp, scaled by the reader's Dynamic Type
    /// setting.
    ///
    /// `.textStyle(.score)` and not `.font(.score)`: `Font` already has a
    /// `body` and a `caption`, and an overload of `.font` taking this ramp
    /// would make `.font(.body)` ambiguous at every call site in the app.
    ///
    /// The scaling is `ScaledMetric`'s, anchored to the entry's
    /// ``TypeRamp/relativeTo``. It is the `relativeTo:` a system font cannot
    /// be built with directly — `Font.system(size:weight:design:)` takes no
    /// text style, and only `Font.custom(_:size:relativeTo:)` does, which is
    /// the road ticket 11 takes once there is a face to name.
    public func textStyle(_ entry: TypeRamp) -> some View {
        modifier(RampFont(entry))
    }
}

/// The ramp entry, scaled.
///
/// A modifier rather than a computed `Font` because `@ScaledMetric` has to sit
/// somewhere the view graph will update it from; a static function has no
/// environment to read the reader's setting out of.
private struct RampFont: ViewModifier {
    private let entry: TypeRamp

    @ScaledMetric private var size: CGFloat

    init(_ entry: TypeRamp) {
        self.entry = entry
        _size = ScaledMetric(wrappedValue: entry.size, relativeTo: entry.relativeTo)
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: entry.weight, design: entry.design))
    }
}
