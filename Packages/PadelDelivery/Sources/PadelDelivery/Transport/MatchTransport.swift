import Foundation
import PadelStorage

public protocol MatchSender: Sendable {
    /// Enqueues rather than sends: the phone may be unreachable for hours, so
    /// nothing is promised and nothing comes back here. The only word about
    /// the match is ``onDelivery(_:)``'s receipt.
    func send(_ match: SavedMatch)

    /// A match handed over before this fires goes nowhere, with no second
    /// attempt in that launch: the session to the phone activates
    /// asynchronously.
    func onReady(_ ready: @escaping @Sendable () -> Void)

    /// Set once when the app is assembled: the receipt arrives whenever,
    /// including after the app was unloaded and launched again, which no
    /// closure passed along with a match outlives. The whole match comes back
    /// because the receipt is for a version, not for an identifier.
    func onDelivery(_ confirm: @escaping @Sendable (SavedMatch) -> Void)
}

public protocol MatchReceiver: Sendable {
    /// Set once when the app is assembled: the match arrives into an app the
    /// system woke for its sake alone, not into one its owner opened.
    func onArrival(_ receive: @escaping @Sendable (SavedMatch) -> Void)

    /// Called once the match is written down, not when it arrives: what the
    /// watch waits for is a receipt from the history, not from the transport.
    func confirmArrival(of match: SavedMatch)
}

/// The live half, beside the queue: what is sent here leaves now or not at
/// all, and nothing is kept for later.
public protocol LiveLink: Sendable {
    /// `false` until the session activates, and whenever the other app cannot
    /// take a message this moment.
    var isReachable: Bool { get }

    /// Set once when the app is assembled. Called from the session's queue,
    /// which is not the main one, and may repeat a value it already reported.
    func onReachabilityChange(_ change: @escaping @Sendable (Bool) -> Void)
}

public protocol ScorerLink: LiveLink {
    func send(_ update: MatchUpdate) throws

    func onIntent(_ receive: @escaping @Sendable (MatchIntent) -> Void)
}

public protocol RemoteLink: LiveLink {
    func send(_ intent: MatchIntent) throws

    func onUpdate(_ receive: @escaping @Sendable (MatchUpdate) -> Void)
}

public enum LiveLinkError: Error, Equatable {
    /// Thrown by a live send at once while ``LiveLink/isReachable`` is `false`.
    /// A message lost after leaving is logged and reported nowhere.
    case unreachable
}

public struct NoMatchTransport: MatchSender, MatchReceiver, ScorerLink, RemoteLink {
    public init() {}

    public var isReachable: Bool { false }

    public func onReachabilityChange(_ change: @escaping @Sendable (Bool) -> Void) {}

    public func send(_ update: MatchUpdate) throws {
        throw LiveLinkError.unreachable
    }

    public func send(_ intent: MatchIntent) throws {
        throw LiveLinkError.unreachable
    }

    public func onIntent(_ receive: @escaping @Sendable (MatchIntent) -> Void) {}

    public func onUpdate(_ receive: @escaping @Sendable (MatchUpdate) -> Void) {}

    public func send(_ match: SavedMatch) {}

    public func onReady(_ ready: @escaping @Sendable () -> Void) {}

    public func onDelivery(_ confirm: @escaping @Sendable (SavedMatch) -> Void) {}

    public func onArrival(_ receive: @escaping @Sendable (SavedMatch) -> Void) {}

    public func confirmArrival(of match: SavedMatch) {}
}
