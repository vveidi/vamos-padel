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
        // Over the bar as well as the screens, so the board keeps the whole
        // display while it holds the phone in landscape.
        .fullScreenCover(item: $running) { match in
            ScoreboardView(match: match, store: store) {
                running = nil
                tab = .history
            }
        }
    }

    private enum Screen {
        case newMatch
        case history
    }
}

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
