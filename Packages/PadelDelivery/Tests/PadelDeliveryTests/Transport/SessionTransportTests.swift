import Foundation
import PadelScoring
import PadelStorage
import PadelStorageDatabase
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
            echo: Echo(intent: .rally(wonBy: .them, base: 1), accepted: true))

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

private final class StubSession: DeviceSession, @unchecked Sendable {
    private let lock = NSLock()
    private var activated: Bool
    private var reachable: Bool
    private var queue: [[String: Any]] = []
    private var live: [[String: Any]] = []

    init(isActivated: Bool = true, isReachable: Bool = true) {
        activated = isActivated
        reachable = isReachable
    }

    var isActivated: Bool {
        get { lock.withLock { activated } }
        set { lock.withLock { activated = newValue } }
    }

    var isReachable: Bool {
        get { lock.withLock { reachable } }
        set { lock.withLock { reachable = newValue } }
    }

    var enqueued: [[String: Any]] { lock.withLock { queue } }

    var sentNow: [[String: Any]] { lock.withLock { live } }

    func enqueue(_ payload: [String: Any]) {
        lock.withLock { queue.append(payload) }
    }

    func sendNow(_ payload: [String: Any]) {
        lock.withLock { live.append(payload) }
    }
}

private final class Inbox<Item: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var taken: [Item] = []

    var items: [Item] { lock.withLock { taken } }

    func take(_ item: Item) {
        lock.withLock { taken.append(item) }
    }
}
