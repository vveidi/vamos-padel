import Foundation
import Pulse
import Testing

import PadelLogging

@Suite("A store copied to another device")
struct LogSnapshotTests {
    private let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)

    private var outgoing: URL { root.appending(path: "outgoing") }

    private var latest: LatestLogStore { LatestLogStore(directory: root.appending(path: "received")) }

    init() throws {
        try FileManager.default.createDirectory(at: outgoing, withIntermediateDirectories: true)
    }

    @Test("opens on the other end with the messages it had")
    func arrivesWithItsMessages() throws {
        let watch = try store(saying: ["the session activated", "sent a match parcel"])

        try latest.keep(try watch.snapshot(into: outgoing))

        let kept = try #require(try latest.open())
        #expect(try kept.messages().map(\.text).sorted() == ["sent a match parcel", "the session activated"])
    }

    @Test("replaces the one kept before it")
    func replacesTheLastOne() throws {
        try latest.keep(try store(saying: ["the first"]).snapshot(into: outgoing))
        try latest.keep(try store(saying: ["the second"]).snapshot(into: outgoing))

        let kept = try #require(try latest.open())
        #expect(try kept.messages().map(\.text) == ["the second"])
    }

    @Test("leaves nothing in the outgoing directory once kept")
    func movesTheFile() throws {
        try latest.keep(try store(saying: ["moved"]).snapshot(into: outgoing))

        #expect(try FileManager.default.contentsOfDirectory(atPath: outgoing.path).isEmpty)
    }

    @Test("leaves the last one and no half-kept folder when the file is missing")
    func aFailedKeepLeavesNothing() throws {
        let received = root.appending(path: "received")
        try latest.keep(try store(saying: ["kept"]).snapshot(into: outgoing))

        #expect(throws: (any Error).self) {
            try latest.keep(LogSnapshot(database: outgoing.appending(path: "gone.sqlite"), manifest: Data()))
        }

        #expect(try FileManager.default.contentsOfDirectory(atPath: received.path) == ["latest.pulse"])
        #expect(try latest.open()?.messages().map(\.text) == ["kept"])
    }

    @Test("is absent until one arrives")
    func absentAtFirst() throws {
        #expect(try latest.open() == nil)
    }

    private func store(saying messages: [String]) throws -> LoggerStore {
        let store = try LoggerStore(
            storeURL: root.appending(path: "\(UUID().uuidString).pulse"), options: [.create, .synchronous])
        let logger = PadelLogger(subsystem: "com.vveidi.padel.tests", category: "delivery", store: store)

        for message in messages { logger.info(message) }

        return store
    }
}
