import SwiftUI

/// One entry of the type ramp. Screens name entries, never faces or sizes.
public enum TypeRamp: Sendable, CaseIterable {
    /// - Note: The watch's 46 was measured, not derived: "40" with a games and
    ///   a sets digit beside it clears the zone on the smallest watch there is.
    case score

    case scoreAside

    case display

    case tileScore

    case control

    case body

    case caption

    /// The size at the default Dynamic Type setting.
    ///
    /// - Important: Not taken off the boards. Layout transfers, type does not
    ///   (`docs/design/README.md`): a 2x watch artboard's 14px label is not 7pt.
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

    /// The system text style this entry scales against. `scoreAside` anchors
    /// to `.largeTitle` alongside `score` and not to its own `.title3`: two
    /// text styles scale by different factors, and the pair shares a baseline.
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

    /// The entry with its anchor stripped off, so it never scales. Internal on
    /// purpose: `.font(entry.font)` compiles, looks right, and silently
    /// defeats Dynamic Type. A screen wants ``SwiftUI/View/textStyle(_:)``.
    var font: Font {
        .system(size: size, weight: weight, design: design)
    }
}

extension View {
    /// Sets the type from the ramp, scaled by the reader's Dynamic Type
    /// setting. Not an overload of `.font`: `Font` has its own `body` and
    /// `caption`, which would make `.font(.body)` ambiguous app-wide.
    public func textStyle(_ entry: TypeRamp) -> some View {
        modifier(RampFont(entry))
    }
}

/// A modifier rather than a computed `Font` because `@ScaledMetric` has to sit
/// somewhere the view graph will update it from.
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
