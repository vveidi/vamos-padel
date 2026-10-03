#if canImport(WatchConnectivity)

    import Foundation
    import PadelLogging
    import PadelStorage
    import WatchConnectivity

    /// The finished match goes with `transferUserInfo`, whose queue keeps its
    /// order and survives the app being unloaded, and a log store with
    /// `transferFile`, which waits the same way; the live link goes with
    /// `sendMessage`, which needs the other app reachable this moment.
    public final class WatchConnectivityTransport: NSObject, MatchSender, MatchReceiver, ScorerLink,
        RemoteLink, LogSender, LogReceiver
    {
        private let transport: SessionTransport

        public override init() {
            transport = SessionTransport(session: WCSession.isSupported() ? Session() : nil)
            super.init()
        }

        /// Call after the handlers are set: a parcel that arrives into an app
        /// with no handler registered does not arrive a second time. Readiness
        /// follows later, from `activationDidCompleteWith`.
        public func activate() {
            guard WCSession.isSupported() else {
                logger.notice("WatchConnectivity is unavailable, there will be no delivery")
                return
            }

            WCSession.default.delegate = self
            WCSession.default.activate()
        }

        public var isReachable: Bool { transport.isReachable }

        public func send(_ match: SavedMatch) {
            transport.send(match)
        }

        public func confirmArrival(of match: SavedMatch) {
            transport.confirmArrival(of: match)
        }

        public func send(_ update: MatchUpdate) throws {
            try transport.send(update)
        }

        public func send(_ intent: MatchIntent) throws {
            try transport.send(intent)
        }

        public func onReady(_ ready: @escaping @Sendable () -> Void) {
            transport.onReady(ready)
        }

        public func onDelivery(_ confirm: @escaping @Sendable (SavedMatch) -> Void) {
            transport.onDelivery(confirm)
        }

        public func onArrival(_ receive: @escaping @Sendable (SavedMatch) -> Void) {
            transport.onArrival(receive)
        }

        public func onReachabilityChange(_ change: @escaping @Sendable (Bool) -> Void) {
            transport.onReachabilityChange(change)
        }

        public func onIntent(_ receive: @escaping @Sendable (MatchIntent) -> Void) {
            transport.onIntent(receive)
        }

        public func onUpdate(_ receive: @escaping @Sendable (MatchUpdate) -> Void) {
            transport.onUpdate(receive)
        }

        public func send(_ logs: LogSnapshot) throws {
            try transport.send(logs)
        }

        public func onLogs(_ receive: @escaping @Sendable (LogSnapshot) -> Void) {
            transport.onLogs(receive)
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

            transport.sessionActivated()
        }

        public func sessionReachabilityDidChange(_ session: WCSession) {
            transport.reachabilityChanged()
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
            transport.received(queued: userInfo)
        }

        public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
            transport.received(live: message)
        }

        /// The file is ours until it is delivered or given up on, either way
        /// once, so it is deleted here.
        public func session(
            _ session: WCSession,
            didFinish fileTransfer: WCSessionFileTransfer,
            error: (any Error)?
        ) {
            guard LogPayload.isLogs(fileTransfer.file.metadata) else { return }

            if let error {
                logger.error("the log store was not delivered: \(error.localizedDescription)")
            } else {
                logger.info("the log store was delivered")
            }

            try? FileManager.default.removeItem(at: fileTransfer.file.fileURL)
        }

        public func session(_ session: WCSession, didReceive file: WCSessionFile) {
            transport.received(file: file.fileURL, metadata: file.metadata)
        }

        #if os(iOS)
            // Required by the protocol on iOS, where the session breaks when
            // the paired watch changes. Beyond reporting the link gone, only
            // reactivation is needed: the history is in the phone's database.
            public func sessionDidBecomeInactive(_ session: WCSession) {
                transport.reachabilityChanged()
            }

            public func sessionDidDeactivate(_ session: WCSession) {
                WCSession.default.activate()
            }
        #endif
    }

    private struct Session: DeviceSession {
        var isActivated: Bool { WCSession.default.activationState == .activated }

        var isReachable: Bool { WCSession.default.isReachable }

        func enqueue(_ payload: [String: Any]) {
            WCSession.default.transferUserInfo(payload)
        }

        /// Without a reply handler the other app answers nothing, and only a
        /// failure comes back.
        func sendNow(_ payload: [String: Any]) {
            WCSession.default.sendMessage(payload, replyHandler: nil) { error in
                logger.error("the live parcel was not delivered: \(error.localizedDescription)")
            }
        }

        /// Whether a cancelled transfer reports its finish is undocumented, so
        /// its file goes here as well.
        func transferLogs(_ file: URL, metadata: [String: Any]) {
            for waiting in WCSession.default.outstandingFileTransfers
            where LogPayload.isLogs(waiting.file.metadata) {
                waiting.cancel()
                try? FileManager.default.removeItem(at: waiting.file.fileURL)
            }

            WCSession.default.transferFile(file, metadata: metadata)
        }
    }

#endif
