import PadelDelivery
import PadelDesign
import PadelStorage
import SwiftUI

struct RootView: View {
    private let store: any MatchStore

    private let scorer: MatchScorer

    private let workout: WatchWorkout

    @State private var tab = Screen.newMatch

    @State private var running: SavedMatch?

    @State private var isPaired = false

    init(store: any MatchStore, scorer: MatchScorer, workout: WatchWorkout) {
        self.store = store
        self.scorer = scorer
        self.workout = workout
    }

    var body: some View {
        ZStack {
            if let running {
                ScoreboardView(
                    match: running, scorer: scorer, isPaired: isPaired,
                    holdsTheWatchsWorkout: workout.holdsTheWorkout, onLeave: leave)
                    .transition(.opacity)
            } else {
                tabs
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: crossFade), value: running?.id)
    }

    private var tabs: some View {
        TabView(selection: $tab) {
            Tab("New match", systemImage: "plus.circle", value: Screen.newMatch) {
                NavigationStack {
                    NewMatchView(store: store, scorer: scorer, workout: workout, startsPaired: false) {
                        running = $0
                        isPaired = $1
                    }
                }
            }

            Tab("History", systemImage: "list.bullet", value: Screen.history) {
                HistoryView(store: store)
            }
        }
        .tint(.ball)
    }

    /// The tabs are built afresh here, so the history opens at the top.
    private func leave() {
        scorer.release()
        tab = .history
        running = nil
    }

    private enum Screen {
        case newMatch
        case history
    }
}

private let crossFade: TimeInterval = 0.25

#if DEBUG

#Preview("The tabs") { root.preferredColorScheme(.dark) }

#Preview("In Russian: the tabs") {
    root
        .environment(\.locale, Locale(identifier: "ru"))
        .preferredColorScheme(.dark)
}

#Preview("At the largest type") {
    root
        .environment(\.dynamicTypeSize, .accessibility5)
        .preferredColorScheme(.dark)
}

@MainActor private var root: some View {
    RootView(store: NoMatchStore(), scorer: previewScorer, workout: WatchWorkout(scorer: previewScorer))
}

private let previewScorer = MatchScorer(store: NoMatchStore(), link: NoMatchTransport())

#endif
