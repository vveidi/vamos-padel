import Foundation
import PadelScoring
import PadelStorage
import PadelStorageDatabase
import Testing

@testable import PadelDelivery

@Suite("Delivering matches to the phone")
struct MatchDeliveryTests {
    @Test("A finished match is put in the queue")
    func aFinishedMatchIsQueued() throws {
        let store = try DatabaseMatchStore.inMemory()
        let transport = FakeTransport()
        let saved = SavedMatch.played([.us, .us], ruleset: toTwo)

        try store.save(saved)
        MatchDelivery(queue: store, sender: transport).deliverPending()

        #expect(transport.sent.map(\.id) == [saved.id])
    }

    @Test("The whole match travels, not its result")
    func theWholeMatchTravels() throws {
        let store = try DatabaseMatchStore.inMemory()
        let transport = FakeTransport()
        let saved = SavedMatch.played(
            [.them, .us, .them], ruleset: .classic(setsToWin: 1, goldenPoint: true),
            firstServer: .them)

        var abandoned = saved
        abandoned.abandon()

        try store.save(abandoned)
        MatchDelivery(queue: store, sender: transport).deliverPending()

        #expect(transport.sent == [abandoned])
    }

    @Test("A match in progress is not put in the queue")
    func aMatchInProgressIsNotQueued() throws {
        let store = try DatabaseMatchStore.inMemory()
        let transport = FakeTransport()

        try store.save(SavedMatch.played([.us], ruleset: toTwo))
        MatchDelivery(queue: store, sender: transport).deliverPending()

        #expect(transport.sent.isEmpty)
    }

    /// A second connection to the same in-memory database stands in for the
    /// relaunch.
    @Test("The queue survives a relaunch of the app")
    func theQueueSurvivesARelaunch() throws {
        let database = "delivery-\(UUID().uuidString)"
        let saved = SavedMatch.played([.us, .us], ruleset: toTwo)

        let store = try DatabaseMatchStore.inMemory(named: database)
        try store.save(saved)

        let afterRelaunch = try DatabaseMatchStore.inMemory(named: database)
        let transport = FakeTransport()

        _ = MatchDelivery(queue: afterRelaunch, sender: transport)
        transport.becomeReady()

        #expect(transport.sent.map(\.id) == [saved.id])
    }

    @Test("Nothing leaves before the transport is ready")
    func nothingIsSentBeforeTheTransportIsReady() throws {
        let store = try DatabaseMatchStore.inMemory()
        let transport = FakeTransport()

        try store.save(SavedMatch.played([.us, .us], ruleset: toTwo))
        _ = MatchDelivery(queue: store, sender: transport)

        #expect(transport.sent.isEmpty)

        transport.becomeReady()

        #expect(transport.sent.count == 1)
    }

    @Test("A confirmed match is not sent again")
    func aConfirmedMatchIsNotSentAgain() throws {
        let store = try DatabaseMatchStore.inMemory()
        let transport = FakeTransport()
        let delivery = MatchDelivery(queue: store, sender: transport)

        try store.save(SavedMatch.played([.us, .us], ruleset: toTwo))
        delivery.deliverPending()
        transport.confirmDelivered()

        transport.forget()
        delivery.deliverPending()

        #expect(transport.sent.isEmpty)
    }

    @Test("An unconfirmed match is sent again")
    func anUnconfirmedMatchIsSentAgain() throws {
        let store = try DatabaseMatchStore.inMemory()
        let transport = FakeTransport()
        let delivery = MatchDelivery(queue: store, sender: transport)
        let saved = SavedMatch.played([.us, .us], ruleset: toTwo)

        try store.save(saved)
        delivery.deliverPending()

        transport.forget()
        delivery.deliverPending()

        #expect(transport.sent.map(\.id) == [saved.id])
    }

    /// Any write of the match clears its delivery mark, which is what sends a
    /// match played on after delivery a second time.
    @Test("A match changed after delivery is sent again")
    func aMatchChangedAfterDeliveryIsSentAgain() throws {
        let store = try DatabaseMatchStore.inMemory()
        let transport = FakeTransport()
        let delivery = MatchDelivery(queue: store, sender: transport)

        var saved = SavedMatch.played([.us, .us], ruleset: toTwo)
        try store.save(saved)
        delivery.deliverPending()
        transport.confirmDelivered()
        transport.forget()

        saved.undo(at: aMoment.addingTimeInterval(30))
        try store.save(saved)
        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(60))
        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(90))
        try store.save(saved)

        delivery.deliverPending()

        #expect(transport.sent == [saved])
    }

    @Test("A receipt for an older version of the match does not clear the queue")
    func aReceiptForAnOlderVersionDoesNotClearTheQueue() throws {
        let store = try DatabaseMatchStore.inMemory()
        let transport = FakeTransport()
        let delivery = MatchDelivery(queue: store, sender: transport)

        var saved = SavedMatch.played([.us, .us], ruleset: toTwo)
        try store.save(saved)
        delivery.deliverPending()

        let delivered = saved

        // The match changes while the receipt is in flight.
        saved.undo(at: aMoment.addingTimeInterval(30))
        try store.save(saved)
        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(60))
        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(90))
        try store.save(saved)

        transport.deliverReceipts(for: [delivered])
        transport.forget()
        delivery.deliverPending()

        #expect(transport.sent == [saved])
    }

    @Test("A match without a single rally is not sent")
    func aMatchWithoutRalliesIsNotSent() throws {
        let store = try DatabaseMatchStore.inMemory()
        let transport = FakeTransport()

        var empty = SavedMatch(match: Match(ruleset: toTwo), startedAt: aMoment)
        empty.abandon()

        try store.save(empty)
        MatchDelivery(queue: store, sender: transport).deliverPending()

        #expect(empty.match.state.outcome.isOver)
        #expect(transport.sent.isEmpty)
    }

    @Test("An empty store has nothing to deliver")
    func anEmptyStoreQueuesNothing() throws {
        let transport = FakeTransport()

        MatchDelivery(queue: try DatabaseMatchStore.inMemory(), sender: transport).deliverPending()

        #expect(transport.sent.isEmpty)
    }
}
