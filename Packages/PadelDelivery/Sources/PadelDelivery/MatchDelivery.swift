import Foundation
import PadelStorage

/// Delivering matches to the phone — the watch's side.
///
/// Ties together two things that know nothing of each other: the queue holding
/// the matches that have not arrived, and the transport, which can only
/// "enqueue", "say it is ready" and "bring back a receipt". The player presses
/// nothing throughout — neither during the game nor after it.
///
/// The watch stays the source of truth until delivery is confirmed
/// (ADR-0002), so what takes a match off the queue is the receipt from the
/// phone, not the sending.
public final class MatchDelivery: Sendable {
    private let queue: any MatchDeliveryQueue
    private let sender: any MatchSender

    public init(queue: any MatchDeliveryQueue, sender: any MatchSender) {
        self.queue = queue
        self.sender = sender

        // What has piled up leaves as soon as the transport is ready — that is
        // what "the queue survives a restart" amounts to. Not when the screen
        // starts: the session to the phone comes up asynchronously, and a match
        // handed over before readiness would go nowhere, with no further
        // attempt in that launch.
        sender.onReady { [queue, sender] in
            Self.deliverPending(from: queue, to: sender)
        }

        sender.onDelivery { [queue] match in
            do {
                try queue.markDelivered(match)
            } catch {
                // The match stays in the queue and will leave again — that is
                // cheaper than counting as delivered something we failed to
                // write down.
                logger.error("delivery was not marked: \(error.localizedDescription)")
            }
        }
    }

    /// Sends everything that has not arrived yet.
    ///
    /// Called when the match has ended; at launch the transport's readiness
    /// does the same.
    ///
    /// Sending again is not a bug but the design. The transport has a queue of
    /// its own, and together they will sometimes deliver one match twice; the
    /// phone recognises it by its identifier, and the second arrival creates
    /// nothing. A lost match cannot be recovered from anywhere; a redundant one
    /// costs nothing.
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
            // The failure never reaches the match: on court the score matters
            // more than what becomes of it in the evening. The next launch will
            // try again.
            logger.error("the delivery queue was not read: \(error.localizedDescription)")
        }
    }
}
