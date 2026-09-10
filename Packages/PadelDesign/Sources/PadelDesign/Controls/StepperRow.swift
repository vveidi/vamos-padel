import SwiftUI

/// A number being set: a label at the leading edge, then − , the value, and + .
///
/// **The phone's control, and only the phone's.** A ± pair is a fine way to
/// cross 1...3 with a thumb and a poor one on a wrist: the board's circles
/// halve to 15pt, and 5...40 behind them is 35 taps. The watch sets the same
/// numbers with ``ChoiceRow``, which opens a page and lets the crown scroll
/// it — see the spec's "The crown survives the rules screen", which this
/// control is no longer the answer to.
///
/// The range comes from the call site and the row clamps to it. It does not
/// know what a set is — `1...3`, `1...6` and `5...40` are all the same
/// control.
///
/// **To VoiceOver it is adjustable, not a pair of buttons.** That is what a
/// stepper is on the platform, and it is what `Stepper` itself reports: one
/// element carrying the label, the value and `.isAdjustable`, moved by a
/// swipe. The alternative — two buttons — would need the words "increase" and
/// "decrease", and this package owns no words to give them.
@available(watchOS, unavailable)
public struct StepperRow: View {
    private let label: Text
    private let range: ClosedRange<Int>

    @Binding private var value: Int

    public init(_ label: Text, value: Binding<Int>, in range: ClosedRange<Int>) {
        self.label = label
        self.range = range
        _value = value
    }

    public var body: some View {
        content
            // One element and not four: VoiceOver walking over a label, a
            // minus, a number and a plus is a way of hearing everything about
            // a row and changing nothing.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityValue(Text(verbatim: "\(value)"))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: step(by: 1)
                case .decrement: step(by: -1)
                @unknown default: break
                }
            }
    }

    private var content: some View {
        // Beside each other while the label leaves room, and above each other
        // when it stops. "Подача через (X)" at the largest setting is wider
        // than the screen on its own, and a row that kept the ± beside it
        // would be a row with the label cut off.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: ControlMetrics.rowGap) {
                labelText
                Spacer(minLength: ControlMetrics.rowGap)
                buttons
            }

            VStack(alignment: .leading, spacing: ControlMetrics.rowGap) {
                labelText
                buttons.frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.vertical, ControlMetrics.rowPaddingVertical)
        .frame(maxWidth: .infinity, minHeight: ControlMetrics.rowHeight)
        .contentShape(Rectangle())
    }

    private var labelText: some View {
        label
            .textStyle(.body)
            .foregroundStyle(.ink.weight(.control))
            .multilineTextAlignment(.leading)
    }

    private var buttons: some View {
        HStack(spacing: ControlMetrics.stepperSpacing) {
            stepButton(by: -1)

            Text(verbatim: "\(value)")
                .textStyle(.display)
                .foregroundStyle(.ink)
                // So that 9 becoming 10 does not shove the two buttons apart.
                .monospacedDigit()
                .frame(minWidth: ControlMetrics.stepperValue)

            stepButton(by: 1)
        }
    }

    private func stepButton(by delta: Int) -> some View {
        let reachable = range.contains(value + delta)

        return Button {
            step(by: delta)
        } label: {
            StepperGlyph(isPlus: delta > 0)
                .stroke(
                    Color.ink.weight(.control),
                    style: StrokeStyle(
                        lineWidth: ControlMetrics.stepperGlyphStroke, lineCap: .round))
                .frame(width: ControlMetrics.stepperGlyph, height: ControlMetrics.stepperGlyph)
                .frame(width: ControlMetrics.stepperButton, height: ControlMetrics.stepperButton)
                .background(Circle().fill(.ink.weight(.surface)))
                // The hit area is wider than the circle and sits inside the
                // button's label, which is the only place it counts: a frame
                // put *around* a `Button` moves the button without widening
                // what it answers to.
                .frame(width: ControlMetrics.stepperHit, height: ControlMetrics.stepperHit)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!reachable)
        // A button at the end of its range that still looks live is a small
        // lie told once per tap.
        .opacity(reachable ? 1 : InkWeight.tertiary.opacity)
    }

    private func step(by delta: Int) {
        value = min(max(value + delta, range.lowerBound), range.upperBound)
    }
}

// MARK: - The glyphs

/// The bar of a − , and the second bar that makes it a + .
///
/// Drawn rather than borrowed, for the reason ``Ball`` is: `Image(systemName:)`
/// would bring the system's weight and the system's cap, and these two are one
/// stroke off the boards — `M5 12h14`, round-capped, in a 24-unit box.
private struct StepperGlyph: Shape {
    let isPlus: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))

        if isPlus {
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }

        return path
    }
}
