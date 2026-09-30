import os
import PadelDesign
import PadelScoring
import PadelStorage
import SwiftUI

struct HistoryView: View {
    private let store: any MatchStore

    @State private var history = History.unknown

    @State private var attempt = 0

    init(store: any MatchStore) {
        self.store = store
    }

    var body: some View {
        NavigationStack {
            what
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background { ground }
                .navigationTitle("History")
                .toolbar {
                    // Bare, because it is a label and not a control: iOS 26
                    // stands every bar item on a glass capsule, and a count
                    // wearing one reads as a button that does nothing when it
                    // is tapped.
                    if #available(iOS 26.0, *) {
                        ToolbarItem(placement: .topBarTrailing) { count }
                            .sharedBackgroundVisibility(.hidden)
                    } else {
                        ToolbarItem(placement: .topBarTrailing) { count }
                    }
                }
        }
        .task(id: attempt) { await watch() }
    }

    private enum History {
        case unknown
        case known([SavedMatch])
        case unreadable
    }

    // MARK: The count

    @ViewBuilder private var count: some View {
        if case .known(let matches) = history, !matches.isEmpty {
            Text("\(matches.count) matches")
                .textStyle(.caption)
                .foregroundStyle(.ink.weight(.tertiary))
        }
    }

    // MARK: What the screen has to say

    @ViewBuilder private var what: some View {
        switch history {
        case .unknown: waiting
        case .known(let matches) where matches.isEmpty: empty
        case .known(let matches): tiles(matches)
        case .unreadable: unreadable
        }
    }

    private func tiles(_ matches: [SavedMatch]) -> some View {
        ScrollView {
            LazyVStack(spacing: Board.tileGap) {
                ForEach(matches) { match in
                    NavigationLink {
                        MatchCard(match: match)
                    } label: {
                        CourtTile(outcome: match.match.state.outcome) {
                            MatchRow(match: match)
                        }
                    }
                    // Without it the link tints its own label and draws a
                    // pressed state over the tile, which is the system's
                    // furniture arriving by the back door.
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, Board.titleGap)
            .padding(.horizontal, Board.inset)
            .padding(.bottom, Board.inset)
        }
    }

    private var waiting: some View {
        ProgressView()
            .tint(.ball)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var empty: some View {
        Notice(
            "No matches yet",
            sentence: "A match played on your watch shows up here by itself"
        ) {
            EmptyView()
        }
    }

    private var unreadable: some View {
        Notice(
            "Can't load your history",
            sentence: "Your matches are still there, but the app couldn't read them"
        ) {
            PillButton(Text("Try again"), variant: .quiet) {
                history = .unknown
                attempt += 1
            }
        }
    }

    // MARK: The ground

    private var ground: some View {
        Color.night
            .overlay { Floodlight(corner: .topTrailing, strength: Board.floodlight) }
            .ignoresSafeArea()
    }

    private func watch() async {
        do {
            for try await matches in store.matchesObserved() {
                history = .known(matches)
            }
        } catch {
            logger.error("the history stopped arriving: \(error.localizedDescription)")

            // A history that did arrive stays on screen. A failure on the
            // first read is the other case: nothing to keep, and the
            // observation is over — without this the screen waits forever.
            if case .known = history { return }

            history = .unreadable
        }
    }
}

private struct Notice<Action: View>: View {
    private let title: LocalizedStringKey
    private let sentence: LocalizedStringKey
    private let action: Action

    init(
        _ title: LocalizedStringKey,
        sentence: LocalizedStringKey,
        @ViewBuilder action: () -> Action
    ) {
        self.title = title
        self.sentence = sentence
        self.action = action()
    }

    var body: some View {
        VStack(spacing: Board.noticeGap) {
            Text(title)
                .textStyle(.display)
                .foregroundStyle(.ink.weight(.control))

            Text(sentence)
                .textStyle(.body)
                .foregroundStyle(.ink.weight(.secondary))

            action.padding(.top, Board.noticeGap)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Board.noticeInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// What the history board drew around the tiles, in its pixels — the phone
/// boards are 1x (`docs/design/README.md`, "Reading the boards").
private enum Board {
    static let inset: CGFloat = 20

    /// Between the navigation bar and the first tile. Short of the board's 22
    /// because the large title brings its own baseline-to-content gap with it.
    static let titleGap: CGFloat = 8

    static let tileGap: CGFloat = 10

    static let floodlight: Double = 0.13

    static let noticeGap: CGFloat = 12

    static let noticeInset: CGFloat = 40
}

#if DEBUG

#Preview("The history") { HistoryView(store: PreviewMatchStore.filled) }

#Preview("An empty history") { HistoryView(store: PreviewMatchStore.empty) }

#Preview("An unreadable history") { HistoryView(store: PreviewMatchStore.unreadable) }

#Preview("In Russian: the history") { inRussian(HistoryView(store: PreviewMatchStore.filled)) }

#Preview("In Russian: an empty history") { inRussian(HistoryView(store: PreviewMatchStore.empty)) }

#Preview("In Russian: an unreadable history") { inRussian(HistoryView(store: PreviewMatchStore.unreadable)) }

#Preview("At the largest type") { atLargestType(HistoryView(store: PreviewMatchStore.filled)) }

#Preview("In Russian, at the largest type") {
    atLargestType(inRussian(HistoryView(store: PreviewMatchStore.filled)))
}

#Preview("In Russian, at the largest type: unreadable") {
    atLargestType(inRussian(HistoryView(store: PreviewMatchStore.unreadable)))
}

private func inRussian(_ view: some View) -> some View {
    view.environment(\.locale, Locale(identifier: "ru"))
}

private func atLargestType(_ view: some View) -> some View {
    view.environment(\.dynamicTypeSize, .accessibility5)
}

private struct PreviewMatchStore: MatchStore {
    let history: [SavedMatch]

    let readable: Bool

    static let filled = PreviewMatchStore(
        history: [
            .preview(classicWonBy: .us),
            .preview(twoSetsWonBy: .them),
            .preview(pointsTo: 16),
            .preview(pointsTo: 21, abandonedAfter: 9),
            .previewClassicAbandoned,
        ],
        readable: true)

    static let empty = PreviewMatchStore(history: [], readable: true)

    static let unreadable = PreviewMatchStore(history: [], readable: false)

    func save(_ match: SavedMatch) throws {}

    func matchInProgress() throws -> SavedMatch? { nil }

    func match(id: UUID) throws -> SavedMatch? { history.first { $0.id == id } }

    func lastRuleset() throws -> Ruleset? { history.first?.match.ruleset }

    func matches() throws -> [SavedMatch] { history }

    func matchesObserved() -> AsyncThrowingStream<[SavedMatch], any Error> {
        AsyncThrowingStream { continuation in
            guard readable else {
                continuation.finish(throwing: CocoaError(.fileReadCorruptFile))

                return
            }

            continuation.yield(history)
            continuation.finish()
        }
    }
}

#endif

private let logger = Logger(subsystem: "com.vveidi.padel", category: "history")
