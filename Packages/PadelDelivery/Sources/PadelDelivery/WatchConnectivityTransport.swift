#if canImport(WatchConnectivity)

    import Foundation
    import PadelStorage
    import WatchConnectivity

    /// The transport on WatchConnectivity: the only implementation of the seam
    /// from ADR-0002, and the only place in the whole codebase that knows about
    /// it.
    ///
    /// The match is enqueued through `transferUserInfo` rather than sent as a
    /// message: a message requires the phone to be reachable right now, and it
    /// is lying in a bag behind the net. The queue is kept by the system — it
    /// survives both the app being unloaded and the watch being restarted,
    /// delivers in the order things were enqueued, and wakes the app on the
    /// phone for every parcel. The receipt comes back the same way: the phone
    /// may just as well be the first to wake up.
    ///
    /// One and the same object stands at both ends: a device has a single
    /// session, and there is nothing to split it between sending and receiving
    /// with. The apps use different halves of it — the watch sends, the phone
    /// receives.
    public final class WatchConnectivityTransport: NSObject, MatchSender, MatchReceiver {
        /// The handlers are set when the app is assembled and called from the
        /// session's queue. The lock here is not against a race over them but
        /// so that this claim is one the compiler can check.
        private let handlers = Handlers()

        /// The session, if the device supports one.
        ///
        /// `nil` on an iPad and other devices without a pair: a match neither
        /// arrives on them nor leaves them, and everything else works.
        private var session: WCSession? { WCSession.isSupported() ? WCSession.default : nil }

        public override init() {
            super.init()
        }

        /// Turns the session on.
        ///
        /// Called after the handlers are set: a parcel that arrives into an app
        /// without a handler will not arrive a second time.
        ///
        /// Readiness comes not from here but later, from
        /// `activationDidComplete`: activation is asynchronous, and until it
        /// finishes the session will carry nothing.
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

        /// Puts the parcel into the system queue.
        ///
        /// An unactivated session undertakes to carry nothing, so whatever is
        /// handed to it before readiness would vanish silently. In that case
        /// the match simply stays in the store's queue and leaves once ready.
        private func transfer(_ arrival: Arrival) {
            guard let session, session.activationState == .activated else {
                logger.notice("the session is not activated, the parcel stayed in the queue")
                return
            }

            session.transferUserInfo(MatchPayload.encode(arrival))
        }
    }

    extension WatchConnectivityTransport: WCSessionDelegate {
        /// The session came up — and only now can anything be handed to it.
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

        /// The parcel went out — or did not.
        ///
        /// This confirms no delivery: the system only knows that it carried a
        /// dictionary to the app on the other side, whereas the watch needs to
        /// know that the match reached the history. The phone signs for that,
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
                }
            } catch {
                logger.error("the parcel that arrived was not decoded: \(error.localizedDescription)")
            }
        }

        #if os(iOS)
            // Required by the protocol on the phone: the session breaks when
            // the paired watch changes. We need nothing from that beyond coming
            // back up — the history is already written into its own database.
            public func sessionDidBecomeInactive(_ session: WCSession) {}

            public func sessionDidDeactivate(_ session: WCSession) {
                WCSession.default.activate()
            }
        #endif
    }

    /// Three closures under a lock — exactly as much state as the transport
    /// has.
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
