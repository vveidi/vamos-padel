import SwiftUI

/// The mark at the trailing edge of a row that opens something.
///
/// - Note: Furniture, so it does not grow with the type beside it: at the
///   largest Dynamic Type setting it would take the width the label needs.
struct Chevron: View {
    var body: some View {
        Image(systemName: "chevron.forward")
            .font(.system(size: ControlMetrics.chevron, weight: .semibold))
            .foregroundStyle(.ink.weight(.control))
            .frame(width: ControlMetrics.chevronWell, height: ControlMetrics.chevronWell)
            // The board's 0.14 read as `surface`'s 0.12 — two hundredths apart
            // is one weight drawn twice, which is `InkWeight`'s own rule.
            .background(Circle().fill(.ink.weight(.surface)))
            // It says what the row does; the row says it to VoiceOver.
            .accessibilityHidden(true)
    }
}
