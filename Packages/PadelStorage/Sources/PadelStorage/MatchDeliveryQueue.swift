import Foundation

/// The queue of matches waiting to be delivered to the phone.
///
/// A protocol of its own rather than a couple of methods on `MatchStore`: the
/// store answers "what did we play", the queue answers "which of it has left",
/// and they will change for different reasons. The implementation is one and
/// the same all along (ADR-0004): the queue is the store, because a second
/// list beside it would one day diverge from it.
public protocol MatchDeliveryQueue: Sendable {
    /// Finished matches that have not arrived yet.
    ///
    /// The queue survives a restart of the app for free — along with the
    /// matches.
    ///
    /// A match in progress does not land here: there is nothing to deliver
    /// while the score is still growing. Nor does a match without a single
    /// rally: a match begins with its first rally, and one stopped earlier is
    /// the trace of a mis-tap, which has no business in the history on the
    /// phone.
    func matchesAwaitingDelivery() throws -> [SavedMatch]

    /// Marks the match as arrived.
    ///
    /// Called on confirmation from the phone, not on the fact of sending: the
    /// watch stays the source of truth until delivery is confirmed (ADR-0002),
    /// and a match sent into the void has to leave again.
    ///
    /// Takes the whole match rather than its identifier, because what gets
    /// delivered is a version, not a match: a point undone in a finished match
    /// changes the journal, and confirmation of the old parcel must not clear
    /// the queue the match returned to because of that edit. A match that has
    /// diverged from what lies in the store is not marked.
    func markDelivered(_ match: SavedMatch) throws
}
