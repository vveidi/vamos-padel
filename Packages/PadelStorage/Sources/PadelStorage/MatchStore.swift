import Foundation
import PadelScoring

/// The match store: what lets a match outlive the app being unloaded and the
/// watch being restarted.
///
/// A protocol rather than SQLite outright, so that the engine and the screens
/// know nothing about the database — and for the same reason the workout and
/// the transport sit behind protocols (ADR-0002): this is precisely the seam
/// that is later swapped for CloudKit or a server without moving the data.
///
/// The methods throw rather than swallow an error silently: the store is not
/// the place to decide what to do about a write that did not happen. On the
/// watch the screen decides that, and decides it the same way for every
/// failure — the match goes on, a line lands in the log.
public protocol MatchStore: Sendable {
    /// Writes the match: creates a new one, updates a known one.
    ///
    /// Called after every rally, not at the end of the match. That is the whole
    /// point of the store: a match interrupted halfway is a journal without a
    /// final state, and it can be restored precisely because it is already
    /// written.
    func save(_ match: SavedMatch) throws

    /// The match still in progress, if there is one.
    ///
    /// What the app asks for at launch, so that the player carries on from the
    /// same place instead of starting over.
    func matchInProgress() throws -> SavedMatch?

    /// A recorded match in full, however it ended.
    ///
    /// The second half of the contract: a store that can write but cannot read
    /// can only be taken at its word. `matchInProgress` will not do for this —
    /// by design it hands back neither finished nor abandoned matches, and the
    /// abandoned mark lives in exactly those.
    ///
    /// Asked for by identifier, because that is what the identifier is for: by
    /// it the store recognizes that this is the same match. There is no listing
    /// here — that arrives with the history on the phone (tickets 10, 11),
    /// which needs a list rather than a single match.
    func match(id: UUID) throws -> SavedMatch?

    /// The previous match's ruleset — the one the start screen fills into a
    /// new match.
    ///
    /// Asked of the store rather than kept as a separate setting beside it:
    /// the previous match's rules are already written down with the match, and
    /// a second copy of the same value would one day diverge from the first —
    /// for the same reason the score is not stored next to the journal
    /// (ADR-0001). What is remembered is exactly what the player finished
    /// playing with, not what they span up on the parameters screen and then
    /// thought better of.
    ///
    /// `nil` — there are no matches yet, and nothing to fill in.
    func lastRuleset() throws -> Ruleset?

    /// Every recorded match, freshest first.
    ///
    /// A single reading of the history: what a test reads back, and what the
    /// observation below hands out. The screen asks for `matchesObserved()`
    /// instead — a list read once goes stale the moment the next match
    /// arrives.
    func matches() throws -> [SavedMatch]

    /// The same history, handed out afresh after every change to the store.
    ///
    /// The phone learns about a match without anybody asking: it arrives into
    /// an app woken by the system for its sake alone (ticket 10), and there
    /// may be no screen at all at that moment. Re-reading the list when the
    /// app comes back to the foreground covers every case but the one that
    /// matters — the match that arrives while the history is open in front of
    /// its owner.
    ///
    /// The first value is the history as it stands: nobody has to read it once
    /// and subscribe afterwards, and between those two there is exactly the
    /// room for a match to slip through unnoticed.
    ///
    /// The stream throws for the same reason the other methods do: the store
    /// is not the place to decide what to do about a read that did not happen.
    /// It ends on the first failure — a database that stopped answering will
    /// not start again by itself.
    func matchesObserved() -> AsyncThrowingStream<[SavedMatch], any Error>
}

/// No store at all: the match is played, the score is counted, nothing is
/// written anywhere.
///
/// For previews, and for the case where the database did not open. A match
/// without a record is worse than a match with one, but better than an app
/// that did not launch.
public struct NoMatchStore: MatchStore, MatchDeliveryQueue {
    public init() {}

    public func save(_ match: SavedMatch) throws {}

    public func matchInProgress() throws -> SavedMatch? { nil }

    public func match(id: UUID) throws -> SavedMatch? { nil }

    public func lastRuleset() throws -> Ruleset? { nil }

    public func matches() throws -> [SavedMatch] { [] }

    /// An empty history that will never change: the stream hands out the one
    /// value it has and ends, rather than staying open for a match that has
    /// nowhere to come from.
    public func matchesObserved() -> AsyncThrowingStream<[SavedMatch], any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield([])
            continuation.finish()
        }
    }

    public func matchesAwaitingDelivery() throws -> [SavedMatch] { [] }

    public func markDelivered(_ match: SavedMatch) throws {}
}
