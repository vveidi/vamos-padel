import Foundation
import PadelStorage

/// The watch's end; ``MatchReception`` is the phone's. A match leaves the
/// queue on the receipt, not on the sending (ADR-0002).
public final class MatchDelivery: Sendable {
    private let queue: any MatchDeliveryQueue
    private let sender: any MatchSender

    public init(queue: any MatchDeliveryQueue, sender: any MatchSender) {
        self.queue = queue
        self.sender = sender

        sender.onReady { [queue, sender] in
            Self.deliverPending(from: queue, to: sender)
        }

        sender.onDelivery { [queue] match in
            do {
                try queue.markDelivered(match)
            } catch {
                // The match stays in the queue and leaves again, which beats
                // counting as delivered a write that did not happen.
                logger.error("delivery was not marked: \(error.localizedDescription)")
            }
        }
    }

    /// A match may go out twice — this queue and the transport's own overlap —
    /// and the phone recognizes the repeat by its identifier.
    public func deliverPending() {
        Self.deliverPending(from: queue, to: sender)
    }

    private static func deliverPending(
        from queue: any MatchDeliveryQueue, to sender: any MatchSender
    ) {
        do {
            for match in try queue.matchesAwaitingDelivery() {
                sender.send(match)
            }
        } catch {
            // Nothing surfaces on court; the next launch tries again.
            logger.error("the delivery queue was not read: \(error.localizedDescription)")
        }
    }
}
