import SwiftUI

/// A number being set: a label at the leading edge, then − , the value, and + .
///
/// **The Digital Crown is the reason this control exists.** The rules screen
/// used three `Picker`s, and a `Picker` on the watch spins under the crown.
/// The boards replace them with ± , which is fine for "sets to win" (1...3) and
/// fine for "serve after" (1...6) and a disaster for "points" (5...40): 35 taps
/// to cross the range, where a spin of the crown used to do it. A redesign that
/// takes the watch's one precise input away is a downgrade dressed as a repaint
/// (the spec, "The crown survives the rules screen").
///
/// So on watchOS the row is focusable, the focused row binds the crown across
/// its range, and the focus is drawn rather than assumed: ± moves one step, the
/// crown scrubs, and the ring says which row the crown is holding. A player who
/// cannot see which row that is will move the wrong number.
///
/// The range comes from the call site and the row clamps to it. It does not
/// know what a set is — `1...3`, `1...6` and `5...40` are all the same control.
///
/// **To VoiceOver it is adjustable, not a pair of buttons.** That is what a
/// stepper is on both platforms, and it is what `Stepper` itself reports: one
/// element carrying the label, the value and `.isAdjustable`, moved by a swipe.
/// The alternative — two buttons — would need the words "increase" and
/// "decrease", and this package owns no words to give them.
public struct StepperRow: View {
    private let label: Text
    private let range: ClosedRange<Int>

    @Binding private var value: Int

    #if os(watchOS)
        @FocusState private var isFocused: Bool

        /// What the crown is holding, in the crown's own currency.
        ///
        /// A `Double` because that is what `digitalCrownRotation` binds, and a
        /// state of its own because the crown moves continuously between the
        /// integers this row is actually about.
        @State private var crown = 0.0
    #endif

    public init(_ label: Text, value: Binding<Int>, in range: ClosedRange<Int>) {
        self.label = label
        self.range = range
        _value = value
    }

    public var body: some View {
        row
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

    /// The row, wearing the crown on the platform that has one.
    private var row: some View {
        #if os(watchOS)
            content
                .focusable()
                .focused($isFocused)
                .digitalCrownRotation(
                    $crown,
                    from: Double(range.lowerBound),
                    through: Double(range.upperBound),
                    by: 1,
                    sensitivity: .medium,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true)
                // The crown and the buttons move the same number, so each has
                // to be told what the other did — otherwise a spin after two
                // taps starts from where the spinning left off.
                .onChange(of: crown) { _, spun in
                    value = clamped(Int(spun.rounded()))
                }
                .onChange(of: value) { _, changed in
                    crown = Double(changed)
                }
                .onAppear { crown = Double(value) }
                .overlay { focusRing }
        #else
            content
        #endif
    }

    private var content: some View {
        // Beside each other while the label leaves room, and above each other
        // when it stops. "Подача через (X)" at the largest setting is wider
        // than a watch on its own, and a row that kept the ± beside it would
        // be a row with the label cut off.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: ControlMetrics.stepperGap) {
                labelText
                Spacer(minLength: ControlMetrics.stepperGap)
                buttons
            }

            VStack(alignment: .leading, spacing: ControlMetrics.stepperGap) {
                labelText
                buttons.frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.vertical, ControlMetrics.cardPaddingVertical)
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

    #if os(watchOS)
        /// Which row the crown is holding.
        private var focusRing: some View {
            RoundedRectangle(cornerRadius: .segment)
                .strokeBorder(
                    isFocused ? Color.ball : .clear, lineWidth: ControlMetrics.focusRing)
        }
    #endif

    private func step(by delta: Int) {
        value = clamped(value + delta)
    }

    private func clamped(_ candidate: Int) -> Int {
        min(max(candidate, range.lowerBound), range.upperBound)
    }
}

// MARK: - The glyphs

/// The bar of a − , and the second bar that makes it a + .
///
/// Drawn rather than borrowed, for the reason ``Ball`` is: `Image(systemName:)`
/// would bring the system's weight and the system's cap, and these two are one
/// stroke off the boards — `M5 12h14`, round-capped, in a 24-unit box.
struct StepperGlyph: Shape {
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
