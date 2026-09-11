import SwiftUI

/// The mark at the trailing edge of a row that opens something.
///
/// **The system's glyph, unlike the ball.** A chevron is not a character this
/// app has an opinion about — it is what every platform draws for "this leads
/// somewhere", and `chevron.forward` turns itself round in a right-to-left
/// layout for free.
///
/// It sits in a well rather than on the ink, which is how the boards draw it:
/// a translucent circle keeps it from reading as a stray glyph at the end of a
/// sentence.
///
/// **It does not grow with the type beside it.** The well is furniture at the
/// end of a row, and at the largest Dynamic Type setting a circle that kept
/// pace with the label would take the width the label needs.
struct Chevron: View {
    var body: some View {
        Image(systemName: "chevron.forward")
            .font(.system(size: ControlMetrics.chevron, weight: .semibold))
            .foregroundStyle(.ink.weight(.control))
            .frame(width: ControlMetrics.chevronWell, height: ControlMetrics.chevronWell)
            // The board's 0.14. `surface` is 0.12 and is the weight this
            // vocabulary has for a translucent panel — two hundredths apart is
            // one weight drawn twice, which is the rule `InkWeight` states
            // about its own collapses.
            .background(Circle().fill(.ink.weight(.surface)))
            // It says what the row does; the row says it to VoiceOver.
            .accessibilityHidden(true)
    }
}
