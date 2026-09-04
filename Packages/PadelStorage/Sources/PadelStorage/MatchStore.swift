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
    /// it the store recognises that this is the same match. There is no listing
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

    /// Every recorded match, freshest first — the history the phone shows.
    func matches() throws -> [SavedMatch]
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

    public func matchesAwaitingDelivery() throws -> [SavedMatch] { [] }

    public func markDelivered(_ match: SavedMatch) throws {}
}
