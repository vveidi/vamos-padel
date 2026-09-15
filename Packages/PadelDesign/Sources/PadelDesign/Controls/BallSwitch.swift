import SwiftUI

/// The switch the boards draw: a `ball`-yellow track with a deep teal knob.
///
/// - Note: It exists for the knob. `.tint(.ball)` reaches the track and stops
///   there, leaving the system's white knob reading as a hole punched through.
public struct BallSwitch: ToggleStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: ControlMetrics.rowGap) {
            configuration.label

            Spacer(minLength: 0)

            track(isOn: configuration.isOn)
        }
        // As tall as the rows it stands among in a ``SettingsCard``, which it
        // has one label to fill where they have a label and a value. Here
        // rather than at the call site, where two apps would ask by hand.
        .frame(minHeight: ControlMetrics.stackedRowHeight)
        .contentShape(Rectangle())
        .onTapGesture { configuration.isOn.toggle() }
        // Styled `.switch` rather than left to the environment, which still
        // holds this style and would hand the representation back to itself.
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
                .toggleStyle(.switch)
        }
    }

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

    private static let travel: TimeInterval = 0.15
}

extension ToggleStyle where Self == BallSwitch {
    public static var ball: BallSwitch { BallSwitch() }
}
