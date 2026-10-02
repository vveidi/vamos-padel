import PadelDesign
import SwiftUI

/// Titled, unlike the score: the bar the title earns is what the pushed list's
/// Back button stands in.
struct TapModePage: View {
    @Binding var tapMode: TapMode

    var body: some View {
        ScrollView {
            TapModeSettings(tapMode: $tapMode)
                .padding(.top, Board.titleGap)
                .padding(.horizontal, Board.inset)
                .padding(.bottom, Board.inset)
        }
        .background {
            Color.night
                .overlay { Floodlight(corner: .topLeading, strength: Board.floodlight) }
                .ignoresSafeArea()
        }
        .navigationTitle("Tap mode")
    }
}

/// The tap-mode board's pixels halved — the watch artboards were 2x
/// (`docs/design/README.md`, "Reading the boards").
private enum Board {
    /// The board's 16px.
    static let inset: CGFloat = 8

    /// The board's 20px between the title band and the card.
    static let titleGap: CGFloat = 10

    /// The board's 0.12, the start settings page's own.
    static let floodlight: Double = 0.12
}

#if DEBUG

private func page(_ tapMode: TapMode) -> some View {
    TapModeScreen(tapMode: tapMode)
}

private func inRussian(_ view: some View) -> some View {
    view.environment(\.locale, Locale(identifier: "ru"))
}

private func atLargestType(_ view: some View) -> some View {
    view.environment(\.dynamicTypeSize, .accessibility5)
}

private struct TapModeScreen: View {
    @State var tapMode: TapMode

    var body: some View {
        NavigationStack { TapModePage(tapMode: $tapMode) }
    }
}

#Preview("Multi-tap") { page(.multiTap) }

#Preview("In Russian: multi-tap") { inRussian(page(.multiTap)) }

#Preview("Tap zones") { page(.tapZones) }

#Preview("In Russian: tap zones") { inRussian(page(.tapZones)) }

#Preview("At the largest type: multi-tap") { atLargestType(page(.multiTap)) }

#Preview("In Russian, at the largest type: multi-tap") {
    atLargestType(inRussian(page(.multiTap)))
}

#Preview("At the largest type: tap zones") { atLargestType(page(.tapZones)) }

#Preview("In Russian, at the largest type: tap zones") {
    atLargestType(inRussian(page(.tapZones)))
}

#endif
