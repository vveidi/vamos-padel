import Foundation
import PadelStorage

/// The sending side of the transport: what a finished match leaves the watch
/// by.
///
/// A protocol rather than WatchConnectivity outright — the very seam ADR-0002
/// was written for: a cloud or a server will appear here by swapping one
/// implementation, without moving the data. The immediate benefit is the same
/// as for the store and the workout: the delivery queue is checked by a test
/// against a stub, not by a pair of devices on the desk.
public protocol MatchSender: Sendable {
    /// Puts the match in the delivery queue.
    ///
    /// Not "sends": during the game the phone lies in a bag or in the changing
    /// room, and delivery will happen when it becomes reachable — in an hour,
    /// or at home that evening. The sender therefore promises nothing and
    /// returns nothing; the only thing that becomes known about the match is
    /// the receipt in `onDelivery`.
    func send(_ match: SavedMatch)

    /// The transport is ready to carry.
    ///
    /// It exists because readiness does not arrive at once: the session to the
    /// phone comes up asynchronously, and a match handed over before that would
    /// go nowhere. Sending what has piled up at launch starts from here too —
    /// calling it on a timer or from a screen would mean guessing when the
    /// transport woke up.
    func onReady(_ ready: @escaping @Sendable () -> Void)

    /// Who to hand the delivery receipt to.
    ///
    /// Set once when the app is assembled rather than passed with every match:
    /// the receipt arrives whenever, including after the app was unloaded and
    /// launched again — a closure handed over along with the match does not
    /// live that long.
    ///
    /// The whole match arrives, not its identifier: the phone signs for having
    /// written this particular version, and on the watch it may have changed in
    /// the meantime.
    func onDelivery(_ confirm: @escaping @Sendable (SavedMatch) -> Void)
}

/// The receiving side of the transport: what a match arrives on the phone by.
public protocol MatchReceiver: Sendable {
    /// What to do with every match that arrives.
    ///
    /// Set once when the app is assembled, and for the same reason as
    /// `onDelivery`: the match arrives into an app woken by the system for its
    /// sake alone, not into one opened by its owner.
    func onArrival(_ receive: @escaping @Sendable (SavedMatch) -> Void)

    /// Signs for the match having been written.
    ///
    /// A step of its own rather than the transport's own acknowledgment: the
    /// transport only knows that the parcel reached the app, whereas the watch
    /// has to learn that it reached the history. The difference shows on
    /// exactly the day the database failed to open on the phone.
    func confirmArrival(of match: SavedMatch)
}

/// No transport at all: the match is played and written, and goes nowhere.
///
/// For previews, and for a device where a watch-and-phone pair does not exist.
public struct NoMatchTransport: MatchSender, MatchReceiver {
    public init() {}

    public func send(_ match: SavedMatch) {}

    public func onReady(_ ready: @escaping @Sendable () -> Void) {}

    public func onDelivery(_ confirm: @escaping @Sendable (SavedMatch) -> Void) {}

    public func onArrival(_ receive: @escaping @Sendable (SavedMatch) -> Void) {}

    public func confirmArrival(of match: SavedMatch) {}
}
