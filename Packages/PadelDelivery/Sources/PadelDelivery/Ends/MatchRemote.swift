import Foundation

/// The watch's end of the live link: it keeps the last update that arrived and
/// nothing of its own — no match, no store. ``MatchScorer`` is the phone's end.
public final class MatchRemote: Sendable {
    private let link: any RemoteLink

    private let arrivals = Broadcast<MatchUpdate>()
    private let reachability = Broadcast<Bool>()

    public init(link: any RemoteLink) {
        self.link = link

        // Answered after it is passed on, so the end is on every stream before
        // the scorer can let go of it — and again on each resend.
        link.onUpdate { [arrivals] update in
            arrivals.send(update)

            if case .match(let saved, _) = update, saved.isPaired, saved.match.state.outcome == .abandoned {
                try? link.send(.heardEnd(of: saved.id))
            }
        }
        link.onReachabilityChange { [reachability] isReachable in reachability.send(isReachable) }

        // Read after subscribing, so a change made in between is not lost.
        reachability.send(link.isReachable)
    }

    /// The first value is the last update that arrived, if one has.
    public func updates() -> AsyncStream<MatchUpdate> {
        arrivals.stream()
    }

    /// The first value is whether the phone is reachable now.
    public func reachabilityChanges() -> AsyncStream<Bool> {
        reachability.stream()
    }

    /// Changes nothing here: what it did arrives as an update, if the phone
    /// took it.
    /// - Throws: ``LiveLinkError/unreachable`` at once while the phone is.
    public func send(_ intent: MatchIntent) throws {
        try link.send(intent)
    }
}
