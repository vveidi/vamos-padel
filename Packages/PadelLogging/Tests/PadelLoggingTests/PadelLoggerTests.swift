import Foundation
import Pulse
import Testing

import PadelLogging

@Suite("A message written through the logger")
struct PadelLoggerTests {
    private let store: LoggerStore
    private let logger: PadelLogger

    init() throws {
        store = try LoggerStore(
            storeURL: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString),
            options: [.create, .inMemory, .synchronous])
        logger = PadelLogger(subsystem: "com.vveidi.padel.tests", category: "delivery", store: store)
    }

    @Test(
        "reaches the store with its category as the label and the matching level",
        arguments: [
            ("debug", LoggerStore.Level.debug),
            ("info", .info),
            ("notice", .notice),
            ("error", .error),
            ("fault", .critical),
        ])
    func reachesTheStore(method: String, level: LoggerStore.Level) throws {
        write("the parcel was not delivered", through: method)

        let stored = try #require(try store.messages().only)
        #expect(stored.text == "the parcel was not delivered")
        #expect(stored.label == "delivery")
        #expect(stored.level == level.rawValue)
    }

    @Test("keeps the place it was written from")
    func keepsItsPlace() throws {
        logger.notice("the session is not activated")

        let stored = try #require(try store.messages().only)
        #expect(stored.file == "PadelLoggerTests.swift")
        #expect(stored.function == "keepsItsPlace()")
    }

    private func write(_ message: String, through method: String) {
        switch method {
        case "debug": logger.debug(message)
        case "info": logger.info(message)
        case "notice": logger.notice(message)
        case "error": logger.error(message)
        case "fault": logger.fault(message)
        default: Issue.record("no such method: \(method)")
        }
    }
}

extension Array {
    fileprivate var only: Element? { count == 1 ? first : nil }
}
