import PadelDesign
import SwiftUI

/// The tap-mode card and the lines under it naming the gestures of whichever
/// value is chosen.
struct TapModeSettings: View {
    @Binding var tapMode: TapMode

    var body: some View {
        VStack(alignment: .leading, spacing: Board.legendGap) {
            SettingsCard {
                ChoiceRow(
                    Text("Tap mode"),
                    selection: $tapMode,
                    options: [
                        .init(Text("Multi-tap"), value: .multiTap),
                        .init(Text("Tap zones"), value: .tapZones),
                    ])
            }

            VStack(spacing: 0) { legend }
                .textStyle(.body)
                .foregroundStyle(.ink.weight(.secondary))
        }
    }

    @ViewBuilder
    private var legend: some View {
        switch tapMode {
        case .multiTap:
            line("1 tap", does: "your point")
            line("2 taps", does: "their point")
        case .tapZones:
            line("tap bottom", does: "your point")
            line("tap top", does: "their point")
        }

        line("long press", does: "undo")
    }

    private func line(_ gesture: LocalizedStringKey, does effect: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Board.pairGap) {
            Text(gesture)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            Text(effect)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }
}

/// The tap-mode board's pixels halved — the watch artboards were 2x
/// (`docs/design/README.md`, "Reading the boards").
private enum Board {
    /// The board's 12px between the card and the first line.
    static let legendGap: CGFloat = 6

    /// The board's 16px between a gesture and what it does.
    static let pairGap: CGFloat = 8
}
