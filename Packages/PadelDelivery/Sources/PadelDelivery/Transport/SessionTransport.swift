import Foundation
import PadelStorage
import Synchronization

/// A device's one session to the other app. Both channels carry the
/// dictionaries ``MatchPayload`` writes.
protocol DeviceSession: Sendable {
    var isActivated: Bool { get }
    var isReachable: Bool { get }

    /// Kept by the system until the other app takes it, across relaunches.
    func enqueue(_ payload: [String: Any])

    /// Leaves now; a failure after leaving is the session's to log.
    func sendNow(_ payload: [String: Any])
}

/// What ``WatchConnectivityTransport`` does, over a session it does not name.
/// The queue carries the finished match and its receipt, the live channel
/// intents and updates, and neither carries the other's.
final class SessionTransport: MatchSender, MatchReceiver, ScorerLink, RemoteLink, Sendable {
    /// `nil` on a device without a pair, such as an iPad.
    private let session: (any DeviceSession)?
    private let handlers = Handlers()

    init(session: (any DeviceSession)?) {
        self.session = session
    }

    var isReachable: Bool {
        guard let session, session.isActivated else { return false }

        return session.isReachable
    }

    // MARK: The queue

    func send(_ match: SavedMatch) {
        enqueue(.match(match))
    }

    func confirmArrival(of match: SavedMatch) {
        enqueue(.receipt(match))
    }

    func onReady(_ ready: @escaping @Sendable () -> Void) {
        handlers.set(\.ready, to: ready)
    }

    func onDelivery(_ confirm: @escaping @Sendable (SavedMatch) -> Void) {
        handlers.set(\.receipt, to: confirm)
    }

    func onArrival(_ receive: @escaping @Sendable (SavedMatch) -> Void) {
        handlers.set(\.match, to: receive)
    }

    /// An unactivated session drops what it is handed, silently; the match
    /// then stays in the store's queue and leaves once ready.
    private func enqueue(_ arrival: Arrival) {
        guard let session, session.isActivated else {
            logger.notice("the session is not activated, the parcel stayed in the queue")
            return
        }

        session.enqueue(MatchPayload.encode(arrival))
    }

    // MARK: The live link

    func send(_ update: MatchUpdate) throws {
        try sendNow(.update(update))
    }

    func send(_ intent: MatchIntent) throws {
        try sendNow(.intent(intent))
    }

    func onReachabilityChange(_ change: @escaping @Sendable (Bool) -> Void) {
        handlers.set(\.reachability, to: change)
    }

    func onIntent(_ receive: @escaping @Sendable (MatchIntent) -> Void) {
        handlers.set(\.intent, to: receive)
    }

    func onUpdate(_ receive: @escaping @Sendable (MatchUpdate) -> Void) {
        handlers.set(\.update, to: receive)
    }

    private func sendNow(_ arrival: Arrival) throws {
        guard let session, isReachable else { throw LiveLinkError.unreachable }

        session.sendNow(MatchPayload.encode(arrival))
    }

    // MARK: What the session reports

    func sessionActivated() {
        handlers.get(\.ready)?()
        reachabilityChanged()
    }

    func reachabilityChanged() {
        handlers.get(\.reachability)?(isReachable)
    }

    func received(queued payload: [String: Any]) {
        switch decode(payload) {
        case .match(let match): handlers.get(\.match)?(match)
        case .receipt(let match): handlers.get(\.receipt)?(match)
        case .intent, .update: logger.error("a live parcel arrived through the queue and was dropped")
        case nil: break
        }
    }

    func received(live payload: [String: Any]) {
        switch decode(payload) {
        case .intent(let intent): handlers.get(\.intent)?(intent)
        case .update(let update): handlers.get(\.update)?(update)
        case .match, .receipt: logger.error("a queued parcel arrived live and was dropped")
        case nil: break
        }
    }

    private func decode(_ payload: [String: Any]) -> Arrival? {
        do {
            return try MatchPayload.decode(payload)
        } catch {
            logger.error("the parcel that arrived was not decoded: \(error.localizedDescription)")
            return nil
        }
    }
}

/// Set when the app is assembled and called from the session's queue.
private final class Handlers: Sendable {
    struct Slots {
        var ready: (@Sendable () -> Void)?
        var receipt: (@Sendable (SavedMatch) -> Void)?
        var match: (@Sendable (SavedMatch) -> Void)?
        var reachability: (@Sendable (Bool) -> Void)?
        var intent: (@Sendable (MatchIntent) -> Void)?
        var update: (@Sendable (MatchUpdate) -> Void)?
    }

    private let handlers = Mutex(Slots())

    func set<Handler: Sendable>(_ slot: WritableKeyPath<Slots, Handler?>, to handle: Handler) {
        handlers.withLock { $0[keyPath: slot] = handle }
    }

    func get<Handler: Sendable>(_ slot: KeyPath<Slots, Handler?>) -> Handler? {
        handlers.withLock { $0[keyPath: slot] }
    }
}
