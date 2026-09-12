import Foundation
import PadelScoring
import PadelStorage
import Testing

@testable import PadelDelivery

@Suite("Delivering matches to the phone")
struct MatchDeliveryTests {
    /// What the ticket was written for: the player never presses "sync". The
    /// match ended and left, and the phone may be lying in the changing room
    /// all the while.
    @Test("A finished match is put in the queue")
    func aFinishedMatchIsQueued() throws {
        let store = try SQLiteMatchStore.inMemory()
        let transport = FakeTransport()
        let saved = SavedMatch.played([.us, .us], ruleset: toTwo)

        try store.save(saved)
        MatchDelivery(queue: store, sender: transport).deliverPending()

        #expect(transport.sent.map(\.id) == [saved.id])
    }

    /// The whole match leaves, not just a score: the rally journal is the
    /// single stored truth about a match (ADR-0001), and the match card on the
    /// phone (ticket 12) needs it, not "6:4".
    @Test("The whole match travels, not its result")
    func theWholeMatchTravels() throws {
        let store = try SQLiteMatchStore.inMemory()
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
        let store = try SQLiteMatchStore.inMemory()
        let transport = FakeTransport()

        try store.save(SavedMatch.played([.us], ruleset: toTwo))
        MatchDelivery(queue: store, sender: transport).deliverPending()

        #expect(transport.sent.isEmpty)
    }

    /// The queue is the store itself, so it survives a relaunch along with the
    /// matches. A second connection to the same database is that relaunch.
    @Test("The queue survives a relaunch of the app")
    func theQueueSurvivesARelaunch() throws {
        let database = "delivery-\(UUID().uuidString)"
        let saved = SavedMatch.played([.us, .us], ruleset: toTwo)

        let store = try SQLiteMatchStore.inMemory(named: database)
        try store.save(saved)

        let afterRelaunch = try SQLiteMatchStore.inMemory(named: database)
        let transport = FakeTransport()

        // Nobody calls delivery by hand: the app launched, the transport came
        // up — that is enough.
        _ = MatchDelivery(queue: afterRelaunch, sender: transport)
        transport.becomeReady()

        #expect(transport.sent.map(\.id) == [saved.id])
    }

    /// The session to the phone comes up asynchronously. A match handed to it
    /// before that would go nowhere, and there would be no second attempt in
    /// that launch — which is why the queue waits for readiness and not the
    /// other way round.
    @Test("Nothing leaves before the transport is ready")
    func nothingIsSentBeforeTheTransportIsReady() throws {
        let store = try SQLiteMatchStore.inMemory()
        let transport = FakeTransport()

        try store.save(SavedMatch.played([.us, .us], ruleset: toTwo))
        _ = MatchDelivery(queue: store, sender: transport)

        #expect(transport.sent.isEmpty)

        transport.becomeReady()

        #expect(transport.sent.count == 1)
    }

    /// The watch is the source of truth until delivery is confirmed
    /// (ADR-0002), so what takes a match off the queue is the confirmation,
    /// not the sending.
    @Test("A confirmed match is not sent again")
    func aConfirmedMatchIsNotSentAgain() throws {
        let store = try SQLiteMatchStore.inMemory()
        let transport = FakeTransport()
        let delivery = MatchDelivery(queue: store, sender: transport)

        try store.save(SavedMatch.played([.us, .us], ruleset: toTwo))
        delivery.deliverPending()
        transport.confirmDelivered()

        transport.forget()
        delivery.deliverPending()

        #expect(transport.sent.isEmpty)
    }

    /// The phone was away all evening and the app was unloaded. An unconfirmed
    /// match has to leave again — otherwise it will never leave at all.
    @Test("An unconfirmed match is sent again")
    func anUnconfirmedMatchIsSentAgain() throws {
        let store = try SQLiteMatchStore.inMemory()
        let transport = FakeTransport()
        let delivery = MatchDelivery(queue: store, sender: transport)
        let saved = SavedMatch.played([.us, .us], ruleset: toTwo)

        try store.save(saved)
        delivery.deliverPending()

        transport.forget()
        delivery.deliverPending()

        #expect(transport.sent.map(\.id) == [saved.id])
    }

    /// Undoing a point in a finished match (ticket 05) brings it back into
    /// play, and once played out again it diverges from what is already on the
    /// phone. The delivery mark is cleared by any write of the match, so it
    /// leaves a second time — and on the phone the second arrival overwrites
    /// the first.
    @Test("A match changed after delivery is sent again")
    func aMatchChangedAfterDeliveryIsSentAgain() throws {
        let store = try SQLiteMatchStore.inMemory()
        let transport = FakeTransport()
        let delivery = MatchDelivery(queue: store, sender: transport)

        var saved = SavedMatch.played([.us, .us], ruleset: toTwo)
        try store.save(saved)
        delivery.deliverPending()
        transport.confirmDelivered()
        transport.forget()

        // The last point was a mistake: it is undone, and the match is played
        // out again.
        saved.undo(at: aMoment.addingTimeInterval(30))
        try store.save(saved)
        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(60))
        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(90))
        try store.save(saved)

        delivery.deliverPending()

        #expect(transport.sent == [saved])
    }

    /// The receipt arrives whenever, including an hour after the sending. In
    /// that time the match may have changed — and a receipt for a previous
    /// version has no right to clear the queue it returned to because of that
    /// edit.
    @Test("A receipt for an older version of the match does not clear the queue")
    func aReceiptForAnOlderVersionDoesNotClearTheQueue() throws {
        let store = try SQLiteMatchStore.inMemory()
        let transport = FakeTransport()
        let delivery = MatchDelivery(queue: store, sender: transport)

        var saved = SavedMatch.played([.us, .us], ruleset: toTwo)
        try store.save(saved)
        delivery.deliverPending()

        let delivered = saved

        // While the receipt was traveling, the last point was undone and the
        // match played out again.
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

    /// A match begins with its first rally — that is how the glossary defines
    /// it. One stopped earlier is saved honestly, but it has no business in the
    /// history on the phone: "0:0, 0 minutes" is not history but the trace of a
    /// mis-tap.
    @Test("A match without a single rally is not sent")
    func aMatchWithoutRalliesIsNotSent() throws {
        let store = try SQLiteMatchStore.inMemory()
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

        MatchDelivery(queue: try SQLiteMatchStore.inMemory(), sender: transport).deliverPending()

        #expect(transport.sent.isEmpty)
    }
}
