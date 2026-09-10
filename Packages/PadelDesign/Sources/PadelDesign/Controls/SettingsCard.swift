import SwiftUI

/// The translucent rounded group the rows stand in — what replaced `List`'s
/// section.
///
/// **It owns the shape, the padding and the dividers, and nothing else.** The
/// rows are handed in, and it never looks inside one: a card that knew a row
/// was a stepper would be a `List` with a different background, and the brief
/// for this package is that it is not one.
///
/// The dividers go *between* rows and never at the ends, which is the whole
/// reason this cannot be a `VStack` at the call site: the caller would have to
/// interleave them by hand and get it right every time.
///
/// ```swift
/// SettingsCard {
///     StepperRow(Text("Sets"), value: $sets, in: 1...3)
///     Toggle(isOn: $goldenPoint) { Text("Golden point") }
///         .tint(.ball)
/// }
/// ```
///
/// **The `Toggle` above is the one system control the redesign keeps.** The
/// boards draw it as a `ball`-yellow track with a dark knob, which is a
/// `Toggle` with `.tint(.ball)` and nothing else — so it is taken for free
/// rather than rebuilt. Check the knob against ``SwiftUI/Color/knob``: it is
/// deep teal and not black, and a black knob reads as a hole punched in the
/// track.
public struct SettingsCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        // `Group(subviews:)` is what makes "between, and not at the ends"
        // possible: it hands over the rows the caller wrote, one at a time,
        // without this card being told how many there are or what they hold.
        Group(subviews: content) { rows in
            let first = rows.first?.id

            VStack(spacing: 0) {
                ForEach(rows) { row in
                    if row.id != first { divider }

                    row
                }
            }
        }
        .padding(.horizontal, ControlMetrics.cardPadding)
        .padding(.vertical, ControlMetrics.cardPaddingVertical)
        .background(RoundedRectangle(cornerRadius: .card).fill(.ink.weight(.surfaceQuiet)))
    }

    /// The hairline between two rows. It stops where the padding does, so it
    /// runs under the rows rather than across the card.
    private var divider: some View {
        Rectangle()
            .fill(.ink.weight(.hairline))
            .frame(height: ControlMetrics.divider)
    }
}
