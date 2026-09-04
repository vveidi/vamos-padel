import PadelScoring
import PadelStorage
import SwiftUI
import os

/// The history: every match played, freshest first.
///
/// The whole of the phone's part in v1. The match is played on the watch and
/// arrives here by itself (ticket 10); this screen is the shop window it ends
/// up in.
struct HistoryView: View {
    private let store: any MatchStore

    /// The history as the store last handed it out. `nil` until the first
    /// list arrives — and that is not the same as an empty history: the screen
    /// says different things about "there are no matches" and "it is not known
    /// yet whether there are any".
    ///
    /// Nothing is read here directly. The list arrives from the observation,
    /// the very first one included.
    @State private var matches: [SavedMatch]?

    init(store: any MatchStore) {
        self.store = store
    }

    var body: some View {
        NavigationStack {
            Group {
                if let matches {
                    if matches.isEmpty { empty } else { list(matches) }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("История")
        }
        .task { await watch() }
    }

    private func list(_ matches: [SavedMatch]) -> some View {
        List(matches) { MatchRow(match: $0) }
    }

    /// The first launch, and every launch until the first match is played out
    /// on the watch. Nothing is broken here and there is nothing for the owner
    /// to do — beyond going and playing, which is what the line says.
    private var empty: some View {
        ContentUnavailableView(
            "Матчей пока нет",
            systemImage: "figure.tennis",
            description: Text("Сыгранный на часах матч появится здесь сам"))
    }

    /// Watches the history for as long as the screen is on.
    ///
    /// A match arrives into an app woken by the system for its sake alone, and
    /// nobody tells the screen about it. Re-reading the list when the app
    /// returns to the foreground would cover every case except the one in
    /// front of the owner's eyes: the match that arrives while the history is
    /// open.
    private func watch() async {
        do {
            for try await matches in store.matchesObserved() {
                self.matches = matches
            }
        } catch {
            // The list stays as it was: the last history that did arrive is
            // closer to the truth than an empty screen, and a database that
            // stopped answering is nothing the owner can do anything about
            // from here.
            logger.error("the history stopped arriving: \(error.localizedDescription)")
        }
    }
}

#if DEBUG

#Preview("The history") {
    HistoryView(
        store: PreviewMatchStore([
            .preview(classicWonBy: .us),
            .preview(pointsTo: 16),
            .preview(pointsTo: 21, abandonedAfter: 9),
        ]))
}

#Preview("An empty history") {
    HistoryView(store: NoMatchStore())
}

/// A few matches and nothing else — the store the preview of a filled history
/// needs. The list arrives once and never changes: there is no watch on the
/// other end of a preview to play another match.
private struct PreviewMatchStore: MatchStore {
    private let history: [SavedMatch]

    init(_ history: [SavedMatch]) {
        self.history = history
    }

    func save(_ match: SavedMatch) throws {}

    func matchInProgress() throws -> SavedMatch? { nil }

    func match(id: UUID) throws -> SavedMatch? { history.first { $0.id == id } }

    func lastRuleset() throws -> Ruleset? { history.first?.match.ruleset }

    func matches() throws -> [SavedMatch] { history }

    func matchesObserved() -> AsyncThrowingStream<[SavedMatch], any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(history)
            continuation.finish()
        }
    }
}

#endif

private let logger = Logger(subsystem: "com.vveidi.padel", category: "history")
