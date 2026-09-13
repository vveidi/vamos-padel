import os
import PadelDesign
import PadelScoring
import PadelStorage
import SwiftUI

/// The history: every match played, freshest first.
///
/// The whole of the phone's part in v1. The match is played on the watch and
/// arrives here by itself (ticket 10); this screen is the shop window it ends
/// up in.
///
/// It is `night` with a light on it, and the matches are tiles cut from the
/// court — a win on turf, a defeat on glass, a match stopped early on neither.
/// **That is the screen's argument: a season is readable by colour before a
/// single number is.** Which is also why nothing here is a `List`: separators
/// and chevrons would rule a table over the court, and the tiles already say
/// where one match ends and the next begins.
///
/// The "New match" button the board draws at the foot is left out. It leads to
/// phone-side match creation, which this feature does not build (the spec's
/// "What is in, and what is not"), and the space it would take is left empty
/// rather than filled with something else.
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

    // MARK: The count

    /// How many matches the history holds, at the bar's trailing edge.
    ///
    /// Declined rather than counted: "1 матч", "2 матча" and "5 матчей" are
    /// three words for the same noun, and the catalog is what knows which
    /// (ADR-0005). Only ever drawn for a history that has something in it — an
    /// empty one says so in a sentence below instead, and "0 matches" in the
    /// bar above it would say it twice.
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

    /// Every match, and every one of them opens its card: the column answers
    /// "how did it end", and the card behind it "how did it come about".
    ///
    /// A `LazyVStack` and not a `List`. What `List` was giving this screen was
    /// scrolling, cell reuse and separators — losing the separators is the
    /// point, and losing the reuse is not, which is what makes it lazy: a
    /// season is a few hundred tiles and each one draws a weave and possibly a
    /// glow.
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

    /// The moment before the first list arrives, which on a database this size
    /// is one frame.
    private var waiting: some View {
        ProgressView()
            .tint(.ball)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// The first launch, and every launch until the first match is played out
    /// on the watch. Nothing is broken here and there is nothing for the owner
    /// to do — beyond going and playing, which is what the line says.
    ///
    /// The `figure.tennis` glyph it used to carry is gone with the rest of the
    /// system view: a symbol at that size on this ground reads as a second
    /// accent, and the app has one (ADR-0006).
    private var empty: some View {
        Notice(
            "No matches yet",
            sentence: "A match played on your watch shows up here by itself"
        ) {
            EmptyView()
        }
    }

    /// The database did not answer — the case the screen used to spend
    /// eternity on a spinner in.
    ///
    /// Said in as many words rather than shown as an empty history: an owner
    /// with a hundred matches must not be told there are none. The button is
    /// the only thing there is to offer — the observation ends on its first
    /// failure and will not start again by itself — and it is honest about
    /// what it does: it tries again, it does not repair anything.
    ///
    /// Quiet and not `ball` yellow, for the same reason: the accent means
    /// *this is yours, or this is chosen*, and a retry is neither.
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

    /// `night` with the history board's light in its top trailing corner.
    ///
    /// The light is what keeps a screen of `night` from being a black
    /// rectangle with cards on it, and it comes in from the corner the tiles'
    /// own glow hangs off, so the two read as one lamp.
    private var ground: some View {
        Color.night
            .overlay { Floodlight(corner: .topTrailing, strength: Board.floodlight) }
            .ignoresSafeArea()
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

/// What stands in the tiles' place when there are none: a line saying what is
/// the matter, a sentence under it, and whatever there is to do about it.
///
/// The two states it draws have to stay clearly different from one another —
/// "there are no matches yet" and "they could not be read" are the pair
/// ``HistoryView``'s `History` exists to keep apart — so the words are the
/// whole of the difference and the arrangement is deliberately the same. What
/// separates them is that one of them has a button.
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

/// What the history board drew around the tiles.
///
/// The phone boards are 1x, so these are its pixels — `docs/design/README.md`,
/// "Reading the boards". The board itself was deleted when this screen
/// shipped; these numbers are what is left of it.
private enum Board {
    /// Left and right of the page, and under the last tile.
    static let inset: CGFloat = 20

    /// Between the navigation bar and the first tile. Short of the board's 22
    /// because the large title brings its own baseline-to-content gap with it.
    static let titleGap: CGFloat = 8

    /// Between one tile and the next.
    static let tileGap: CGFloat = 10

    /// How much light the corner spends. The board's 0.13.
    static let floodlight: Double = 0.13

    /// Between the lines of a notice, and again above its button.
    static let noticeGap: CGFloat = 12

    /// Left and right of a notice's sentence, so it wraps well short of the
    /// screen's edges rather than at them.
    static let noticeInset: CGFloat = 40
}

#if DEBUG

#Preview("The history") { HistoryView(store: PreviewMatchStore.filled) }

#Preview("An empty history") { HistoryView(store: PreviewMatchStore.empty) }

#Preview("An unreadable history") { HistoryView(store: PreviewMatchStore.unreadable) }

/// The screen in the other language. All three states, because between them
/// they hold every sentence this file says.
#Preview("In Russian: the history") { inRussian(HistoryView(store: PreviewMatchStore.filled)) }

#Preview("In Russian: an empty history") { inRussian(HistoryView(store: PreviewMatchStore.empty)) }

#Preview("In Russian: an unreadable history") { inRussian(HistoryView(store: PreviewMatchStore.unreadable)) }

/// The setting at which a tile's two columns stop fitting side by side and the
/// notices find their second and third lines.
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

/// A few matches and nothing else — or no matches, or a database that will not
/// answer. The list arrives once and never changes: there is no watch on the
/// other end of a preview to play another match.
private struct PreviewMatchStore: MatchStore {
    let history: [SavedMatch]

    /// Whether the observation yields the list or fails on its first read,
    /// which is the only way to reach the screen's third state.
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
