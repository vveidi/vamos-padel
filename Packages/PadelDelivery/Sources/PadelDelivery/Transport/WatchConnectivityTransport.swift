#if canImport(WatchConnectivity)

    import Foundation
    import PadelStorage
    import WatchConnectivity

    /// Parcels are enqueued with `transferUserInfo`, not sent as messages: a
    /// message needs the phone reachable right now. The system's queue keeps
    /// its order and survives the app being unloaded and the watch restarting.
    /// One object stands at both ends because a device has a single session.
    public final class WatchConnectivityTransport: NSObject, MatchSender, MatchReceiver {
        /// Set when the app is assembled, called from the session's queue,
        /// which is not the main one.
        private let handlers = Handlers()

        /// `nil` on a device without a pair, such as an iPad: nothing arrives
        /// and nothing leaves, and the rest of the app works.
        private var session: WCSession? { WCSession.isSupported() ? WCSession.default : nil }

        public override init() {
            super.init()
        }

        /// Call after the handlers are set: a parcel that arrives into an app
        /// with no handler registered does not arrive a second time. Readiness
        /// follows later, from `activationDidCompleteWith`.
        public func activate() {
            guard let session else {
                logger.notice("WatchConnectivity is unavailable, there will be no delivery")
                return
            }

            session.delegate = self
            session.activate()
        }

        public func send(_ match: SavedMatch) {
            transfer(.match(match))
        }

        public func confirmArrival(of match: SavedMatch) {
            transfer(.receipt(match))
        }

        public func onReady(_ ready: @escaping @Sendable () -> Void) {
            handlers.setReady(ready)
        }

        public func onDelivery(_ confirm: @escaping @Sendable (SavedMatch) -> Void) {
            handlers.setConfirm(confirm)
        }

        public func onArrival(_ receive: @escaping @Sendable (SavedMatch) -> Void) {
            handlers.setReceive(receive)
        }

        /// An unactivated session drops what it is handed, silently; the match
        /// then stays in the store's queue and leaves once ready.
        private func transfer(_ arrival: Arrival) {
            guard let session, session.activationState == .activated else {
                logger.notice("the session is not activated, the parcel stayed in the queue")
                return
            }

            session.transferUserInfo(MatchPayload.encode(arrival))
        }
    }

    extension WatchConnectivityTransport: WCSessionDelegate {
        public func session(
            _ session: WCSession,
            activationDidCompleteWith state: WCSessionActivationState,
            error: (any Error)?
        ) {
            if let error {
                logger.error("the session was not activated: \(error.localizedDescription)")
            }

            guard state == .activated else { return }

            handlers.ready()
        }

        /// Not a delivery confirmation: the system only knows the dictionary
        /// reached the app on the other side. The phone signs for the history
        /// in a parcel of its own.
        public func session(
            _ session: WCSession,
            didFinish userInfoTransfer: WCSessionUserInfoTransfer,
            error: (any Error)?
        ) {
            if let error {
                logger.error("the parcel was not delivered: \(error.localizedDescription)")
            }
        }

        public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
            do {
                switch try MatchPayload.decode(userInfo) {
                case .match(let match): handlers.receive(match)
                case .receipt(let match): handlers.confirm(match)
                case .intent, .update: logger.error("a live link parcel arrived, and nothing reads them")
                }
            } catch {
                logger.error("the parcel that arrived was not decoded: \(error.localizedDescription)")
            }
        }

        #if os(iOS)
            // Required by the protocol on iOS, where the session breaks when
            // the paired watch changes. Nothing but reactivation is needed:
            // the history is already in the phone's own database.
            public func sessionDidBecomeInactive(_ session: WCSession) {}

            public func sessionDidDeactivate(_ session: WCSession) {
                WCSession.default.activate()
            }
        #endif
    }

    private final class Handlers: @unchecked Sendable {
        private let lock = NSLock()
        private var transportReady: (@Sendable () -> Void)?
        private var confirmDelivery: (@Sendable (SavedMatch) -> Void)?
        private var receiveMatch: (@Sendable (SavedMatch) -> Void)?

        func setReady(_ handle: @escaping @Sendable () -> Void) {
            lock.withLock { transportReady = handle }
        }

        func setConfirm(_ handle: @escaping @Sendable (SavedMatch) -> Void) {
            lock.withLock { confirmDelivery = handle }
        }

        func setReceive(_ handle: @escaping @Sendable (SavedMatch) -> Void) {
            lock.withLock { receiveMatch = handle }
        }

        func ready() {
            lock.withLock { transportReady }?()
        }

        func confirm(_ match: SavedMatch) {
            lock.withLock { confirmDelivery }?(match)
        }

        func receive(_ match: SavedMatch) {
            lock.withLock { receiveMatch }?(match)
        }
    }

#endif
