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

    /// What is known about the history right now. Nothing is read here
    /// directly: every list arrives from the observation, the first one
    /// included.
    @State private var history = History.unknown

    /// Bumped to start the observation over. The store handed out a failure
    /// once; whether it will do so again is something only another attempt can
    /// say.
    @State private var attempt = 0

    init(store: any MatchStore) {
        self.store = store
    }

    var body: some View {
        NavigationStack {
            Group {
                switch history {
                case .unknown: ProgressView()
                case .known(let matches) where matches.isEmpty: empty
                case .known(let matches): list(matches)
                case .unreadable: unreadable
                }
            }
            .navigationTitle("История")
        }
        .task(id: attempt) { await watch() }
    }

    /// The three things the screen can say, and the reason they are one value
    /// rather than a list and a couple of flags: "there are no matches yet",
    /// "it is not yet known whether there are any" and "they could not be
    /// read" look alike from a distance and must never be shown for one
    /// another.
    private enum History {
        case unknown
        case known([SavedMatch])
        case unreadable
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

    /// The database did not answer — the case the screen used to spend
    /// eternity on a spinner in.
    ///
    /// Said in as many words rather than shown as an empty history: an owner
    /// with a hundred matches must not be told there are none. The button is
    /// the only thing there is to offer — the observation ends on its first
    /// failure and will not start again by itself — and it is honest about
    /// what it does: it tries again, it does not repair anything.
    private var unreadable: some View {
        ContentUnavailableView {
            Label("История не читается", systemImage: "exclamationmark.triangle")
        } description: {
            Text("Сыгранные матчи на месте, но приложение не смогло их прочитать")
        } actions: {
            Button("Попробовать снова") {
                history = .unknown
                attempt += 1
            }
        }
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
                history = .known(matches)
            }
        } catch {
            logger.error("the history stopped arriving: \(error.localizedDescription)")

            // A history that did arrive stays on screen: the last list that
            // was read is closer to the truth than anything the screen could
            // put in its place, and the owner is looking at matches, not at
            // the database.
            //
            // A failure on the very first read is the other case entirely.
            // There is nothing to keep, and the observation is over — without
            // this the screen would go on waiting for a list that will never
            // come.
            if case .known = history { return }

            history = .unreadable
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
