import Foundation
import PadelScoring
import PadelStorage
import PadelStorageDatabase
import Synchronization
import Testing

@testable import PadelDelivery

@Suite("The transport's two channels")
struct SessionTransportTests {
    @Test("An update goes out live and comes back on the other end as it left")
    func anUpdateMakesTheTrip() throws {
        let phone = StubSession()
        let watch = StubSession()
        let scorer = SessionTransport(session: phone)
        let remote = SessionTransport(session: watch)
        let arrived = Inbox<MatchUpdate>()
        let update = MatchUpdate.match(
            .played([.us, .them], ruleset: toTwo),
            isPaired: true, echo: Echo(intent: .rally(wonBy: .them, base: 1), accepted: true))

        remote.onUpdate(arrived.take)
        try scorer.send(update)
        phone.sentNow.forEach { remote.received(live: $0) }

        #expect(arrived.items == [update])
        #expect(phone.enqueued.isEmpty)
    }

    @Test("An intent goes out live and comes back on the other end as it left")
    func anIntentMakesTheTrip() throws {
        let watch = StubSession()
        let remote = SessionTransport(session: watch)
        let scorer = SessionTransport(session: StubSession())
        let arrived = Inbox<MatchIntent>()

        scorer.onIntent(arrived.take)
        try remote.send(MatchIntent.undo(base: 3))
        watch.sentNow.forEach { scorer.received(live: $0) }

        #expect(arrived.items == [.undo(base: 3)])
        #expect(watch.enqueued.isEmpty)
    }

    @Test("A live send while unreachable fails at once and leaves nothing behind")
    func aLiveSendIsRefusedWhileUnreachable() {
        let session = StubSession(isReachable: false)
        let transport = SessionTransport(session: session)

        #expect(throws: LiveLinkError.unreachable) {
            try transport.send(MatchIntent.end(base: 4))
        }
        #expect(throws: LiveLinkError.unreachable) {
            try transport.send(MatchUpdate.noMatch(echo: nil))
        }
        #expect(session.sentNow.isEmpty)
        #expect(session.enqueued.isEmpty)
    }

    @Test("A session not yet activated is not reachable, whatever it says")
    func anUnactivatedSessionIsUnreachable() {
        let transport = SessionTransport(session: StubSession(isActivated: false))

        #expect(!transport.isReachable)
        #expect(throws: LiveLinkError.unreachable) {
            try transport.send(MatchIntent.undo(base: 0))
        }
    }

    @Test("A device without a pair is never reachable")
    func noSessionIsUnreachable() {
        let transport = SessionTransport(session: nil)

        #expect(!transport.isReachable)
        #expect(throws: LiveLinkError.unreachable) {
            try transport.send(MatchUpdate.noMatch(echo: nil))
        }
    }

    @Test("Reachability reaches the end as a value each time it changes")
    func reachabilityChangesUnderAnEnd() {
        let session = StubSession()
        let transport = SessionTransport(session: session)
        let reported = Inbox<Bool>()

        transport.onReachabilityChange(reported.take)
        transport.sessionActivated()
        session.isReachable = false
        transport.reachabilityChanged()
        session.isReachable = true
        transport.reachabilityChanged()

        #expect(reported.items == [true, false, true])
    }

    @Test("A session that goes inactive reports the link gone")
    func anInactiveSessionReportsUnreachable() {
        let session = StubSession()
        let transport = SessionTransport(session: session)
        let reported = Inbox<Bool>()

        transport.onReachabilityChange(reported.take)
        transport.sessionActivated()
        session.isActivated = false
        transport.reachabilityChanged()

        #expect(reported.items == [true, false])
    }

    @Test("Losing the other app stops the live sends that follow")
    func losingReachabilityRefusesTheNextSend() throws {
        let session = StubSession()
        let transport = SessionTransport(session: session)

        try transport.send(MatchIntent.rally(wonBy: .us, base: 0))
        session.isReachable = false
        transport.reachabilityChanged()

        #expect(!transport.isReachable)
        #expect(throws: LiveLinkError.unreachable) {
            try transport.send(MatchIntent.rally(wonBy: .us, base: 0))
        }
        #expect(session.sentNow.count == 1)
    }

    @Test("A finished match is still queued while the live half is unreachable")
    func theDeliveryIsQueuedWhileUnreachable() throws {
        let store = try DatabaseMatchStore.inMemory()
        let session = StubSession(isReachable: false)
        let transport = SessionTransport(session: session)
        let saved = SavedMatch.played([.us, .us], ruleset: toTwo)

        try store.save(saved)
        _ = MatchDelivery(queue: store, sender: transport)
        transport.sessionActivated()

        let queued = try session.enqueued.map(MatchPayload.decode)
        #expect(queued == [.match(saved)])
        #expect(session.sentNow.isEmpty)
    }

    @Test("A match that arrives through the queue still reaches the phone's end")
    func theQueueStillDelivers() {
        let watch = StubSession(isReachable: false)
        let phone = SessionTransport(session: StubSession(isReachable: false))
        let arrived = Inbox<SavedMatch>()
        let saved = SavedMatch.played([.them, .them], ruleset: toTwo)

        phone.onArrival(arrived.take)
        SessionTransport(session: watch).send(saved)
        watch.enqueued.forEach { phone.received(queued: $0) }

        #expect(arrived.items == [saved])
    }

    @Test("Neither channel carries the other's parcels")
    func theChannelsDoNotMix() {
        let transport = SessionTransport(session: StubSession())
        let matches = Inbox<SavedMatch>()
        let intents = Inbox<MatchIntent>()

        transport.onArrival(matches.take)
        transport.onIntent(intents.take)
        transport.received(live: MatchPayload.encode(.match(.played([.us], ruleset: toTwo))))
        transport.received(queued: MatchPayload.encode(.intent(.undo(base: 1))))

        #expect(matches.items.isEmpty)
        #expect(intents.items.isEmpty)
    }
}

/// Keeps each parcel as the property list WatchConnectivity would carry: a
/// dictionary of `Any` cannot be held behind a lock the compiler checks.
private final class StubSession: DeviceSession, Sendable {
    private struct Wire {
        var activated: Bool
        var reachable: Bool
        var queue: [Data] = []
        var live: [Data] = []
    }

    private let wire: Mutex<Wire>

    init(isActivated: Bool = true, isReachable: Bool = true) {
        wire = Mutex(Wire(activated: isActivated, reachable: isReachable))
    }

    var isActivated: Bool {
        get { wire.withLock { $0.activated } }
        set { wire.withLock { $0.activated = newValue } }
    }

    var isReachable: Bool {
        get { wire.withLock { $0.reachable } }
        set { wire.withLock { $0.reachable = newValue } }
    }

    var enqueued: [[String: Any]] { wire.withLock { $0.queue }.map(Self.payload) }

    var sentNow: [[String: Any]] { wire.withLock { $0.live }.map(Self.payload) }

    func enqueue(_ payload: [String: Any]) {
        let parcel = Self.parcel(payload)
        wire.withLock { $0.queue.append(parcel) }
    }

    func sendNow(_ payload: [String: Any]) {
        let parcel = Self.parcel(payload)
        wire.withLock { $0.live.append(parcel) }
    }

    private static func parcel(_ payload: [String: Any]) -> Data {
        try! PropertyListSerialization.data(fromPropertyList: payload, format: .binary, options: 0)
    }

    private static func payload(_ parcel: Data) -> [String: Any] {
        try! PropertyListSerialization.propertyList(from: parcel, format: nil) as! [String: Any]
    }
}

private final class Inbox<Item: Sendable>: Sendable {
    private let taken = Mutex<[Item]>([])

    var items: [Item] { taken.withLock { $0 } }

    func take(_ item: Item) {
        taken.withLock { $0.append(item) }
    }
}
