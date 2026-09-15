import SwiftUI

/// A number being set: a label at the leading edge, then − , the value, and + .
/// The range comes from the call site and the row clamps to it.
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
        // Beside each other while the label leaves room, above each other when
        // it stops: "Подача через (X)" at the largest setting is wider than the
        // screen on its own.
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
                // The hit area sits inside the button's label, which is the
                // only place it counts: a frame put *around* a `Button` moves
                // the button without widening what it answers to.
                .frame(width: ControlMetrics.stepperHit, height: ControlMetrics.stepperHit)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!reachable)
        .opacity(reachable ? 1 : InkWeight.tertiary.opacity)
    }

    private func step(by delta: Int) {
        value = min(max(value + delta, range.lowerBound), range.upperBound)
    }
}

// MARK: - The glyphs

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
