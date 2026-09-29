import Foundation
import PadelStorage

/// The phone's end; ``MatchDelivery`` is the watch's. The same match arrives
/// twice when a receipt is lost, and the second arrival updates the record
/// rather than adding one.
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

    public func receive(_ match: SavedMatch) {
        Self.receive(match, into: store, confirmingTo: receiver)
    }

    private static func receive(
        _ match: SavedMatch, into store: any MatchStore, confirmingTo receiver: any MatchReceiver
    ) {
        do {
            try store.save(match)
        } catch {
            // No receipt goes out, so the watch brings the match again on its
            // next launch.
            logger.error("the match that arrived was not saved: \(error.localizedDescription)")
            return
        }

        receiver.confirmArrival(of: match)
    }
}
