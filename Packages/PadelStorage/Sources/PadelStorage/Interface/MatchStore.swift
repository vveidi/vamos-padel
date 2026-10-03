import Foundation
import PadelScoring

public protocol MatchStore: Sendable {
    /// Called after every rally, not at the end of the match: a match
    /// interrupted halfway can be restored precisely because it is already
    /// written.
    func save(_ match: SavedMatch) throws

    /// The last match scored one of `ways`, unless it is over. An unfinished
    /// match older than that one never comes back, however long ago it was
    /// left and however it was scored.
    func matchInProgress(scored ways: Set<MatchScoring>) throws -> SavedMatch?

    /// A recorded match however it ended. Unlike ``matchInProgress()``, this
    /// hands back finished and abandoned matches too.
    func match(id: UUID) throws -> SavedMatch?

    /// The ruleset the player last finished playing with — not what they span
    /// up on the parameters screen and then thought better of.
    ///
    /// - Returns: `nil` when there are no matches yet.
    func lastRuleset() throws -> Ruleset?

    /// Every recorded match, the most recently started first.
    func matches() throws -> [SavedMatch]

    /// The same history, handed out afresh after every change to the store. The
    /// first value is the history as it stands, so nobody has to read it once
    /// and subscribe afterwards; the stream ends on the first failure, because
    /// a database that stopped answering will not start again by itself.
    func matchesObserved() -> AsyncThrowingStream<[SavedMatch], any Error>
}

extension MatchStore {
    public func matchInProgress() throws -> SavedMatch? {
        try matchInProgress(scored: Set(MatchScoring.allCases))
    }
}

/// For previews, and for the app whose database did not open.
public struct NoMatchStore: MatchStore, MatchDeliveryQueue {
    public init() {}

    public func save(_ match: SavedMatch) throws {}

    public func matchInProgress(scored ways: Set<MatchScoring>) throws -> SavedMatch? { nil }

    public func match(id: UUID) throws -> SavedMatch? { nil }

    public func lastRuleset() throws -> Ruleset? { nil }

    public func matches() throws -> [SavedMatch] { [] }

    public func matchesObserved() -> AsyncThrowingStream<[SavedMatch], any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield([])
            continuation.finish()
        }
    }

    public func matchesAwaitingDelivery() throws -> [SavedMatch] { [] }

    public func markDelivered(_ match: SavedMatch) throws {}
}
