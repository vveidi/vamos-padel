import PadelDelivery
import PadelDesign
import PadelScoring
import PadelStorage
import SwiftUI

struct RootView: View {
    private let store: any MatchStore

    private let scorer: MatchScorer

    private let workout: WatchWorkout

    @State private var tab = Screen.newMatch

    /// The match the scorer holds, as first seen: the board follows it from
    /// there on its own.
    @State private var held: Held?

    init(store: any MatchStore, scorer: MatchScorer, workout: WatchWorkout) {
        self.store = store
        self.scorer = scorer
        self.workout = workout
    }

    var body: some View {
        ZStack {
            if let held {
                ScoreboardView(
                    match: held.match, scorer: scorer, isPaired: held.isPaired,
                    holdsTheWatchsWorkout: workout.holdsTheWorkout
                ) { leave(held.match) }
                    .id(held.match.id)
                    .transition(.opacity)
            } else {
                tabs
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: crossFade), value: held?.match.id)
        .task { await follow() }
    }

    private func follow() async {
        for await update in scorer.updates() {
            switch update {
            case .match(let match, let isPaired, _) where match.id != held?.match.id:
                held = Held(match: match, isPaired: isPaired)
            case .match:
                break
            case .noMatch:
                held = nil
            }
        }
    }

    private var tabs: some View {
        TabView(selection: $tab) {
            Tab("New match", systemImage: "plus.circle", value: Screen.newMatch) {
                NavigationStack {
                    NewMatchView(store: store, scorer: scorer, workout: workout)
                }
            }

            Tab("History", systemImage: "list.bullet", value: Screen.history) {
                HistoryView(store: store)
            }
        }
        .tint(.ball)
    }

    /// The tabs are built afresh here, so the history opens at the top.
    private func leave(_ match: SavedMatch) {
        tab = .history
        scorer.release(match.id)
    }

    private struct Held {
        let match: SavedMatch
        let isPaired: Bool
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

#Preview("The watch starts a paired match") {
    startedOnTheWatch.preferredColorScheme(.dark)
}

#Preview("In Russian: the watch starts a paired match") {
    startedOnTheWatch
        .environment(\.locale, Locale(identifier: "ru"))
        .preferredColorScheme(.dark)
}

@MainActor private var root: some View {
    RootView(store: NoMatchStore(), scorer: previewScorer, workout: WatchWorkout(scorer: previewScorer))
}

/// The start arrives as the watch sends it, so nothing on the phone asked for
/// the board that comes up.
@MainActor private var startedOnTheWatch: some View {
    let scorer = MatchScorer(store: NoMatchStore(), link: NoMatchTransport())
    scorer.apply(.start(ruleset: .defaultClassic, firstServer: .us))

    return RootView(store: NoMatchStore(), scorer: scorer, workout: WatchWorkout(scorer: scorer))
}

private let previewScorer = MatchScorer(store: NoMatchStore(), link: NoMatchTransport())

#endif
