import PadelScoring
import SwiftUI

/// The score screen and the control page beside it.
///
/// Stopping a match has to be possible from the court, and there is no room for
/// it on the score screen: there are exactly two tap zones and three numbers
/// there, and any button would take space from them or intercept the tap that
/// awards a point. So the controls move to a neighbouring page — the same place
/// the system's workout puts them: the match runs inside one anyway, and a
/// swipe to a page with an "End" button is something the player has already
/// done on this watch.
///
/// What opens is always the score, never the controls: the control page is
/// needed once per match, the score between every two rallies.
struct ScorePages: View {
    let points: Points
    let games: SideCounts?
    let sets: SideCounts?
    let servingSide: Side
    let onRallyWon: (Side) -> Void
    let onUndo: () -> Void

    /// Stops the match early. The confirmation is asked for by the control
    /// page, so what leaves here is already decided.
    let onAbandon: () -> Void

    @State private var page = Page.score

    private enum Page {
        case controls
        case score
    }

    var body: some View {
        TabView(selection: $page) {
            MatchControls(onAbandon: onAbandon)
                .tag(Page.controls)

            ScoreView(
                points: points,
                games: games,
                sets: sets,
                servingSide: servingSide,
                onRallyWon: onRallyWon,
                onUndo: onUndo)
                .tag(Page.score)
        }
        .tabViewStyle(.page)
    }
}

/// The control page: the only thing that can be done to a running match apart
/// from scoring it is to stop it.
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
        // The confirmation is mandatory: a swipe with a wet hand and a
        // mis-tap on the button are exactly what a match must not be cut short
        // by. It is also the only guard against an accidental stop: the match
        // does not come back into play.
        .confirmationDialog(
            "End the match?",
            isPresented: $isConfirming,
            titleVisibility: .visible
        ) {
            Button("End", role: .destructive, action: onAbandon)
            Button("Keep playing", role: .cancel) {}
        } message: {
            Text("The match will be saved as unfinished.")
        }
    }
}

#if DEBUG

/// The control page is the one thing on these two pages made of words, and it
/// is also the narrowest place they are said in: a destructive button, the
/// confirmation over it and the line under that. The dialog is reached by
/// tapping "End" in the preview.
private let pages = ScorePages(
    points: .game(SideCounts(us: 3, them: 2)),
    games: SideCounts(us: 4, them: 5),
    sets: nil,
    servingSide: .us,
    onRallyWon: { _ in },
    onUndo: {},
    onAbandon: {})

#Preview { pages }

#Preview("In Russian") { pages.environment(\.locale, Locale(identifier: "ru")) }

#endif
