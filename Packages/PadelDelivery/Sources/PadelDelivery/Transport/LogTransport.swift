import Foundation
import PadelLogging

public protocol LogSender: Sendable {
    /// Enqueues the file, which waits for the phone however long it takes. A
    /// store still waiting is cancelled: the newer one holds everything it did.
    /// - Throws: ``LogSenderError/noSession``, and the file is the caller's.
    func send(_ logs: LogSnapshot) throws
}

public enum LogSenderError: Error, Equatable {
    /// Not activated yet, or no pair at all.
    case noSession
}

public protocol LogReceiver: Sendable {
    /// Set once when the app is assembled. Called from the session's queue,
    /// and the snapshot's file is deleted once this returns, so it has to be
    /// moved before then.
    func onLogs(_ receive: @escaping @Sendable (LogSnapshot) -> Void)
}

/// The metadata a file travels with. Its keys are a contract with a separately
/// updated app, as ``MatchPayload``'s are.
enum LogPayload {
    static func encode(_ logs: LogSnapshot) -> [String: Any] {
        [Key.kind: Kind.logs, Key.manifest: logs.manifest]
    }

    static func isLogs(_ metadata: [String: Any]?) -> Bool {
        metadata?[Key.kind] as? String == Kind.logs
    }

    static func decode(file: URL, metadata: [String: Any]?) throws -> LogSnapshot {
        guard isLogs(metadata) else {
            throw MatchPayloadError.unreadable(reason: "a file of kind \"\(metadata?[Key.kind] ?? "—")\"")
        }

        guard let manifest = metadata?[Key.manifest] as? Data else {
            throw MatchPayloadError.unreadable(reason: "a log store without its manifest")
        }

        return LogSnapshot(database: file, manifest: manifest)
    }

    private enum Key {
        static let kind = "kind"
        static let manifest = "manifest"
    }

    private enum Kind {
        static let logs = "logs"
    }
}
