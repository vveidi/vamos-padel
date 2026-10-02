import PadelDelivery
import PadelDesign
import PadelStorage
import SwiftUI

struct RootView: View {
    private let store: any MatchStore

    private let scorer: MatchScorer

    @State private var tab = Screen.newMatch

    @State private var running: SavedMatch?

    init(store: any MatchStore, scorer: MatchScorer) {
        self.store = store
        self.scorer = scorer
    }

    var body: some View {
        ZStack {
            if let running {
                ScoreboardView(match: running, scorer: scorer, onLeave: leave)
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
                    NewMatchView(store: store, scorer: scorer) { running = $0 }
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

#Preview("The tabs") { RootView(store: NoMatchStore(), scorer: previewScorer).preferredColorScheme(.dark) }

#Preview("In Russian: the tabs") {
    RootView(store: NoMatchStore(), scorer: previewScorer)
        .environment(\.locale, Locale(identifier: "ru"))
        .preferredColorScheme(.dark)
}

#Preview("At the largest type") {
    RootView(store: NoMatchStore(), scorer: previewScorer)
        .environment(\.dynamicTypeSize, .accessibility5)
        .preferredColorScheme(.dark)
}

private let previewScorer = MatchScorer(store: NoMatchStore(), link: NoMatchTransport())

#endif
