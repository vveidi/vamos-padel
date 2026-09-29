import Foundation

public protocol MatchDeliveryQueue: Sendable {
    /// Finished matches that have not arrived yet, oldest first. A match in
    /// progress does not land here, nor does one without a single rally: a
    /// match begins with its first rally, and one stopped earlier is a mis-tap.
    func matchesAwaitingDelivery() throws -> [SavedMatch]

    /// Called on confirmation from the phone, not on the fact of sending
    /// (ADR-0002). Takes the whole match because what gets delivered is a
    /// version: one that has since diverged from the store is left in the
    /// queue, and this does nothing.
    func markDelivered(_ match: SavedMatch) throws
}
