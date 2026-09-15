import SwiftUI

/// The translucent rounded group the rows stand in. It owns the shape, the
/// padding and the dividers, and never looks inside a row. The dividers go
/// *between* rows and never at the ends, which is why a `VStack` at the call
/// site will not do: the caller would have to interleave them by hand.
public struct SettingsCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
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

    /// It stops where the padding does, so it runs under the rows rather than
    /// across the card.
    private var divider: some View {
        Rectangle()
            .fill(.ink.weight(.hairline))
            .frame(height: ControlMetrics.divider)
    }
}
