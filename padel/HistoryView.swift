import PadelScoring
import PadelStorage
import SwiftUI
import os

/// The match history on the phone — in its crudest form so far.
///
/// The real list, with durations and rulesets, is ticket 11's job; there is
/// just enough here for a match that arrived from the watch to be visible to
/// the eye and not only in the database.
///
/// A match arrives into an app woken by the system for its sake alone, and the
/// screen learns nothing about it. Until it observes the database — that is
/// ticket 11 as well — the history is re-read on returning to the active state
/// and on a pull to refresh: otherwise a match that arrived while the screen
/// was open would never show up at all.
struct HistoryView: View {
    private let store: any MatchStore

    @State private var matches: [SavedMatch] = []

    /// A match arrives into an app that is in the background — the screen
    /// learns about it when it is opened again.
    @Environment(\.scenePhase) private var scenePhase

    init(store: any MatchStore) {
        self.store = store
    }

    var body: some View {
        NavigationStack {
            Group {
                if matches.isEmpty {
                    ContentUnavailableView(
                        "Матчей пока нет",
                        systemImage: "figure.tennis",
                        description: Text("Сыгранный на часах матч появится здесь сам"))
                } else {
                    List(matches) { match in
                        row(match)
                    }
                    .refreshable { reload() }
                }
            }
            .navigationTitle("История")
        }
        .task { reload() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { reload() }
        }
    }

    private func row(_ saved: SavedMatch) -> some View {
        let state = saved.match.state

        return VStack(alignment: .leading, spacing: 2) {
            Text("\(state.finalScore.us) : \(state.finalScore.them)")
                .font(.headline)

            Text(saved.startedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)

            if state.outcome == .abandoned {
                Text("недоигранный")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func reload() {
        do {
            matches = try store.matches()
        } catch {
            logger.error("the history was not read: \(error.localizedDescription)")
        }
    }
}

#Preview {
    HistoryView(store: NoMatchStore())
}

private let logger = Logger(subsystem: "com.vveidi.padel", category: "history")
