import PadelScoring
import SwiftUI
import WatchKit

/// The score screen owns every point of its own surface as a tap zone, so the
/// controls cannot share it: a button there would swallow the tap that awards
/// a point.
struct ScorePages: View {
    let points: Points
    let games: SideCounts?
    let sets: SideCounts?
    let servingSide: Side
    let servingHalf: ServingHalf?
    @Binding var tapMode: TapMode
    let onRallyWon: (Side) -> Void
    let onUndo: () -> Void

    /// Already confirmed by the control page when this is called.
    let onAbandon: () -> Void

    @State private var page = Page.score

    private enum Page {
        case controls
        case score
        case tapMode
    }

    var body: some View {
        // Around the pages, as `StartPages` has it, and with the bar left alone
        // for the same reason: the untitled score draws none, and the titled
        // tap-mode page needs one to push its list from.
        NavigationStack {
            TabView(selection: $page) {
                MatchControls(onAbandon: onAbandon)
                    .tag(Page.controls)

                ScoreView(
                    points: points,
                    games: games,
                    sets: sets,
                    servingSide: servingSide,
                    servingHalf: servingHalf,
                    tapMode: tapMode,
                    onRallyWon: onRallyWon,
                    onUndo: onUndo)
                    .tag(Page.score)

                TapModePage(tapMode: $tapMode)
                    .tag(Page.tapMode)
            }
            .tabViewStyle(.verticalPage)
        }
    }
}

private struct MatchControls: View {
    let onAbandon: () -> Void

    @State private var isConfirming = false

    var body: some View {
        Button(role: .destructive) {
            isConfirming = true
        } label: {
            Label("End", systemImage: "xmark")
        }
        .padding(.horizontal)
        // An abandoned match does not come back into play, so this dialog is
        // the only guard against a mis-tap ending one.
        .confirmationDialog(
            "End the match?",
            isPresented: $isConfirming,
            titleVisibility: .visible
        ) {
            Button("End", role: .destructive) {
                WKInterfaceDevice.current().play(.stop)

                onAbandon()
            }
            Button("Keep playing", role: .cancel) {}
        } message: {
            Text("The match will be saved as unfinished.")
        }
    }
}

#if DEBUG

private struct Pages: View {
    @State private var tapMode = TapMode.multiTap

    var body: some View {
        ScorePages(
            points: .game(SideCounts(us: 3, them: 2)),
            games: SideCounts(us: 4, them: 5),
            sets: nil,
            servingSide: .us,
            servingHalf: .right,
            tapMode: $tapMode,
            onRallyWon: { _ in },
            onUndo: {},
            onAbandon: {})
    }
}

private let pages = Pages()

#Preview { pages }

#Preview("In Russian") { pages.environment(\.locale, Locale(identifier: "ru")) }

#endif
