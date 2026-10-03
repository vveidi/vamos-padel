import Pulse
import os

public struct PadelLogger: Sendable {
    private let logger: Logger
    private let category: String
    private let store: LoggerStore

    public init(subsystem: String, category: String, store: LoggerStore = .shared) {
        self.logger = Logger(subsystem: subsystem, category: category)
        self.category = category
        self.store = store
    }

    public func debug(_ message: String, file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(message, as: .debug, .debug, file: file, function: function, line: line)
    }

    public func info(_ message: String, file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(message, as: .info, .info, file: file, function: function, line: line)
    }

    public func notice(_ message: String, file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(message, as: .default, .notice, file: file, function: function, line: line)
    }

    public func error(_ message: String, file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(message, as: .error, .error, file: file, function: function, line: line)
    }

    public func fault(_ message: String, file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(message, as: .fault, .critical, file: file, function: function, line: line)
    }

    private func log(
        _ message: String, as type: OSLogType, _ level: LoggerStore.Level,
        file: String, function: String, line: UInt
    ) {
        logger.log(level: type, "\(message, privacy: .public)")
        store.storeMessage(
            label: category, level: level, message: message, file: file, function: function, line: line)
    }
}
