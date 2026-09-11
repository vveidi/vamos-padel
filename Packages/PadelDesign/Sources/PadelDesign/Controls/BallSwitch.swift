import SwiftUI

/// The switch the boards draw: a `ball`-yellow track with a deep teal knob.
///
/// A `ToggleStyle` and not a control of its own, so the call site still writes
/// a `Toggle` — `.toggleStyle(.ball)` is the whole of the change, and the
/// binding, the label and the tap keep belonging to SwiftUI.
///
/// **It exists for the knob.** `.tint(.ball)` reaches the track and stops
/// there: the knob stays the system's white, which on a yellow track reads as
/// a hole punched through it rather than as the ball's own dark green. That is
/// the one thing the boards are emphatic about — see ``SwiftUI/Color/knob``.
///
/// ```swift
/// Toggle(isOn: $goldenPoint) { Text("Golden point") }
///     .toggleStyle(.ball)
/// ```
///
/// **The track is furniture and does not grow with the type beside it.** The
/// same argument the watch's settings page makes about its chevron: at the
/// largest Dynamic Type setting a switch that kept pace with the sentence
/// would take the width the sentence needs, and on a 198pt screen there is
/// none to give.
public struct BallSwitch: ToggleStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: ControlMetrics.rowGap) {
            configuration.label

            Spacer(minLength: 0)

            track(isOn: configuration.isOn)
        }
        // A row in a ``SettingsCard`` and as tall as the rows it stands among,
        // which it has one label to fill where they have a label and a value.
        // Here rather than at the call site: two apps asking for the same
        // height by hand is two apps to fix when the ramp moves.
        .frame(minHeight: ControlMetrics.stackedRowHeight)
        .contentShape(Rectangle())
        .onTapGesture { configuration.isOn.toggle() }
        // The system toggle's own semantics, put back whole: the trait, the
        // on and the off, and the label read with them. Styled `.switch`
        // rather than left to the environment, which still holds this style
        // and would hand the representation back to itself.
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
                .toggleStyle(.switch)
        }
    }

    /// The track with the knob in it, at the one end or the other.
    private func track(isOn: Bool) -> some View {
        Capsule()
            .fill(isOn ? Color.ball : .ink.weight(.surface))
            .frame(
                width: ControlMetrics.switchTrack.width,
                height: ControlMetrics.switchTrack.height)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    // Off, the knob is the only part of the switch that can be
                    // seen: a translucent panel on a translucent card is two
                    // shapes eight hundredths apart.
                    .fill(isOn ? Color.knob : .ink.weight(.strong))
                    .padding(ControlMetrics.switchKnobInset)
            }
            .animation(.easeOut(duration: Self.travel), value: isOn)
    }

    /// How long the knob takes to cross. Short enough that it reads as the
    /// switch answering the finger rather than as a thing sliding.
    private static let travel: TimeInterval = 0.15
}

extension ToggleStyle where Self == BallSwitch {
    /// See ``BallSwitch``.
    public static var ball: BallSwitch { BallSwitch() }
}
