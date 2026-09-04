import Foundation
import PadelStorage

/// Receiving matches from the watch — the phone's side.
///
/// Writes the match that arrived and signs for it to the watch. The receipt is
/// no formality: until it arrives, the match on the watch stands in the queue
/// and will leave again (ADR-0002), so a match not written here is not lost —
/// it arrives once more.
///
/// The history screen (tickets 11, 12) later gets the match from the store
/// rather than from here: it arrives into an app woken by the system for its
/// sake alone, and there may be no screen at all at that moment.
///
/// The same match arrives twice if the receipt did not get through. The second
/// arrival does not create a second match: the store recognises it by its
/// identifier and updates the record — with the same journal if it did not
/// change, and with a continued one if a point was undone after delivery and
/// the match played on.
public final class MatchReception: Sendable {
    private let store: any MatchStore
    private let receiver: any MatchReceiver

    public init(store: any MatchStore, receiver: any MatchReceiver) {
        self.store = store
        self.receiver = receiver

        receiver.onArrival { [store, receiver] match in
            Self.receive(match, into: store, confirmingTo: receiver)
        }
    }

    /// Writes the match that arrived and signs for it.
    public func receive(_ match: SavedMatch) {
        Self.receive(match, into: store, confirmingTo: receiver)
    }

    private static func receive(
        _ match: SavedMatch, into store: any MatchStore, confirmingTo receiver: any MatchReceiver
    ) {
        do {
            try store.save(match)
        } catch {
            // The receipt does not go out, and the watch will bring the match
            // again — with the next launch of the app on the watch.
            logger.error("the match that arrived was not saved: \(error.localizedDescription)")
            return
        }

        receiver.confirmArrival(of: match)
    }
}
