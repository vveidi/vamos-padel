import Foundation
import PadelScoring
import PadelStorage
import Testing

@testable import PadelDelivery

@Suite("Приём матчей на телефоне")
struct MatchReceptionTests {
    @Test("Приехавший матч попадает в хранилище телефона")
    func anArrivingMatchIsStored() throws {
        let store = try SQLiteMatchStore.inMemory()
        let transport = FakeTransport()
        let saved = SavedMatch.played([.them, .them])

        _ = MatchReception(store: store, receiver: transport)
        transport.deliver(saved)

        #expect(try store.match(id: saved.id) == saved)
    }

    /// Часы отправляют матч заново, пока не получат подтверждения, и своя
    /// очередь есть у транспорта — один и тот же матч приезжает дважды по
    /// замыслу. Узнаётся он по идентификатору, заведённому при первом
    /// розыгрыше.
    @Test("Повторный приезд не заводит второй матч")
    func arrivingTwiceDoesNotDuplicateTheMatch() throws {
        let store = try SQLiteMatchStore.inMemory()
        let transport = FakeTransport()
        let saved = SavedMatch.played([.us, .us])

        _ = MatchReception(store: store, receiver: transport)
        transport.deliver(saved)
        transport.deliver(saved)

        #expect(try store.matches() == [saved])
    }

    /// Тот же матч, но доигранный после отмены очка: приехавшее позже —
    /// свежее, и в истории должно остаться оно.
    @Test("Второй приезд обновляет матч, а не дописывает его")
    func arrivingAgainUpdatesTheMatch() throws {
        let store = try SQLiteMatchStore.inMemory()
        let transport = FakeTransport()

        var saved = SavedMatch.played([.us, .us])
        _ = MatchReception(store: store, receiver: transport)
        transport.deliver(saved)

        saved.match.undo()
        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(60))
        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(90))
        transport.deliver(saved)

        #expect(try store.matches() == [saved])
    }

    @Test("Разные матчи не сливаются в один")
    func differentMatchesAreStoredSeparately() throws {
        let store = try SQLiteMatchStore.inMemory()
        let transport = FakeTransport()
        let earlier = SavedMatch.played([.us, .us])
        let later = SavedMatch.played([.them, .them], from: aMoment.addingTimeInterval(3600))

        _ = MatchReception(store: store, receiver: transport)
        transport.deliver(earlier)
        transport.deliver(later)

        #expect(try store.matches() == [later, earlier])
    }
}
