import PadelDesign
import PadelStorage
import SwiftUI

struct RootView: View {
    private let store: any MatchStore

    @State private var tab = Screen.newMatch

    @State private var running: SavedMatch?

    init(store: any MatchStore) {
        self.store = store
    }

    var body: some View {
        ZStack {
            if let running {
                ScoreboardView(match: running, store: store, onLeave: leave)
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
                    NewMatchView(store: store) { running = $0 }
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

#Preview("The tabs") { RootView(store: NoMatchStore()).preferredColorScheme(.dark) }

#Preview("In Russian: the tabs") {
    RootView(store: NoMatchStore())
        .environment(\.locale, Locale(identifier: "ru"))
        .preferredColorScheme(.dark)
}

#Preview("At the largest type") {
    RootView(store: NoMatchStore())
        .environment(\.dynamicTypeSize, .accessibility5)
        .preferredColorScheme(.dark)
}

#endif
