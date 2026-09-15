import Foundation
import PadelScoring
import PadelStorage
import PadelStorageDatabase
import Testing

@testable import PadelDelivery

@Suite("Receiving matches on the phone")
struct MatchReceptionTests {
    @Test("A match that arrives lands in the phone's store")
    func anArrivingMatchIsStored() throws {
        let store = try DatabaseMatchStore.inMemory()
        let transport = FakeTransport()
        let saved = SavedMatch.played([.them, .them], ruleset: toTwo)

        _ = MatchReception(store: store, receiver: transport)
        transport.deliver(saved)

        #expect(try store.match(id: saved.id) == saved)
    }

    /// The watch sends the match again until it gets a confirmation, and the
    /// transport has a queue of its own — the same match arriving twice is by
    /// design. It is recognized by the identifier created on the first rally.
    @Test("Arriving twice does not create a second match")
    func arrivingTwiceDoesNotDuplicateTheMatch() throws {
        let store = try DatabaseMatchStore.inMemory()
        let transport = FakeTransport()
        let saved = SavedMatch.played([.us, .us], ruleset: toTwo)

        _ = MatchReception(store: store, receiver: transport)
        transport.deliver(saved)
        transport.deliver(saved)

        #expect(try store.matches() == [saved])
    }

    /// The same match, but played out after a point was undone: what arrived
    /// later is fresher, and that is what the history must keep.
    @Test("A second arrival updates the match rather than appending to it")
    func arrivingAgainUpdatesTheMatch() throws {
        let store = try DatabaseMatchStore.inMemory()
        let transport = FakeTransport()

        var saved = SavedMatch.played([.us, .us], ruleset: toTwo)
        _ = MatchReception(store: store, receiver: transport)
        transport.deliver(saved)

        saved.undo(at: aMoment.addingTimeInterval(30))
        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(60))
        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(90))
        transport.deliver(saved)

        #expect(try store.matches() == [saved])
    }

    /// The receipt is the only thing that takes a match off the queue on the
    /// watch (ADR-0002), and the phone gives it for what it wrote down, not for
    /// what it received.
    @Test("The phone signs for a match it stored")
    func aStoredMatchIsConfirmed() throws {
        let store = try DatabaseMatchStore.inMemory()
        let transport = FakeTransport()
        let saved = SavedMatch.played([.us, .us], ruleset: toTwo)

        _ = MatchReception(store: store, receiver: transport)
        transport.deliver(saved)

        #expect(transport.receipts == [saved])
    }

    /// The database did not open on the phone. There is no receipt, so the
    /// match stays in the queue on the watch and will arrive again instead of
    /// vanishing from the history for good.
    @Test("The phone does not sign for a match it failed to store")
    func anUnstoredMatchIsNotConfirmed() {
        let transport = FakeTransport()

        _ = MatchReception(store: FailingMatchStore(), receiver: transport)
        transport.deliver(SavedMatch.played([.us, .us], ruleset: toTwo))

        #expect(transport.receipts.isEmpty)
    }

    @Test("Different matches do not merge into one")
    func differentMatchesAreStoredSeparately() throws {
        let store = try DatabaseMatchStore.inMemory()
        let transport = FakeTransport()
        let earlier = SavedMatch.played([.us, .us], ruleset: toTwo)
        let later = SavedMatch.played([.them, .them], from: aMoment.addingTimeInterval(3600))

        _ = MatchReception(store: store, receiver: transport)
        transport.deliver(earlier)
        transport.deliver(later)

        #expect(try store.matches() == [later, earlier])
    }
}
