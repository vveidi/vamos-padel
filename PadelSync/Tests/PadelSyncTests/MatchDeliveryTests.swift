import Foundation
import PadelScoring
import PadelStorage
import Testing

@testable import PadelSync

@Suite("Доставка матчей на телефон")
struct MatchDeliveryTests {
    /// То, ради чего тикет и написан: игрок не нажимает «синхронизировать».
    /// Матч кончился — и уехал, телефон при этом может лежать в раздевалке.
    @Test("Законченный матч ставится в очередь")
    func aFinishedMatchIsQueued() throws {
        let store = try SQLiteMatchStore.inMemory()
        let transport = FakeTransport()
        let saved = SavedMatch.played([.us, .us])

        try store.save(saved)
        MatchDelivery(store: store, sender: transport).deliverPending()

        #expect(transport.sent.map(\.id) == [saved.id])
    }

    /// Матч уезжает целиком, а не одним счётом: журнал розыгрышей и есть
    /// единственная сохраняемая правда о матче (ADR-0001), и карточке матча
    /// на телефоне (тикет 12) нужен он, а не «6:4».
    @Test("Уезжает весь матч, а не его итог")
    func theWholeMatchTravels() throws {
        let store = try SQLiteMatchStore.inMemory()
        let transport = FakeTransport()
        let saved = SavedMatch.played(
            [.them, .us, .them], ruleset: .classic(setsToWin: 1, goldenPoint: true),
            firstServer: .them)

        var abandoned = saved
        abandoned.match.abandon()

        try store.save(abandoned)
        MatchDelivery(store: store, sender: transport).deliverPending()

        #expect(transport.sent == [abandoned])
    }

    @Test("Идущий матч в очередь не попадает")
    func aMatchInProgressIsNotQueued() throws {
        let store = try SQLiteMatchStore.inMemory()
        let transport = FakeTransport()

        try store.save(SavedMatch.played([.us]))
        MatchDelivery(store: store, sender: transport).deliverPending()

        #expect(transport.sent.isEmpty)
    }

    /// Очередь — это само хранилище, поэтому перезапуск она переживает вместе
    /// с матчами. Второе соединение к той же базе — это и есть перезапуск.
    @Test("Очередь переживает перезапуск приложения")
    func theQueueSurvivesARelaunch() throws {
        let database = "delivery-\(UUID().uuidString)"
        let saved = SavedMatch.played([.us, .us])

        let store = try SQLiteMatchStore.inMemory(named: database)
        try store.save(saved)

        let afterRelaunch = try SQLiteMatchStore.inMemory(named: database)
        let transport = FakeTransport()

        MatchDelivery(store: afterRelaunch, sender: transport).deliverPending()

        #expect(transport.sent.map(\.id) == [saved.id])
    }

    /// Часы — источник правды до подтверждённой доставки (ADR-0002), поэтому
    /// с очереди матч снимает подтверждение, а не отправка.
    @Test("Подтверждённый матч больше не уезжает")
    func aConfirmedMatchIsNotSentAgain() throws {
        let store = try SQLiteMatchStore.inMemory()
        let transport = FakeTransport()
        let delivery = MatchDelivery(store: store, sender: transport)

        try store.save(SavedMatch.played([.us, .us]))
        delivery.deliverPending()
        transport.confirmDelivered()

        transport.forget()
        delivery.deliverPending()

        #expect(transport.sent.isEmpty)
    }

    /// Телефона не было весь вечер, а приложение выгрузили. Неподтверждённый
    /// матч обязан уехать снова — иначе он не уедет никогда.
    @Test("Неподтверждённый матч уезжает снова")
    func anUnconfirmedMatchIsSentAgain() throws {
        let store = try SQLiteMatchStore.inMemory()
        let transport = FakeTransport()
        let delivery = MatchDelivery(store: store, sender: transport)
        let saved = SavedMatch.played([.us, .us])

        try store.save(saved)
        delivery.deliverPending()

        transport.forget()
        delivery.deliverPending()

        #expect(transport.sent.map(\.id) == [saved.id])
    }

    /// Отмена очка в законченном матче (тикет 05) возвращает его в игру, и
    /// доигранный заново он расходится с тем, что уже на телефоне. Отметка о
    /// доставке гаснет с любой записью матча, поэтому он уезжает второй раз —
    /// а второй приезд на телефоне затирает первый.
    @Test("Матч, изменившийся после доставки, уезжает заново")
    func aMatchChangedAfterDeliveryIsSentAgain() throws {
        let store = try SQLiteMatchStore.inMemory()
        let transport = FakeTransport()
        let delivery = MatchDelivery(store: store, sender: transport)

        var saved = SavedMatch.played([.us, .us])
        try store.save(saved)
        delivery.deliverPending()
        transport.confirmDelivered()
        transport.forget()

        // Последнее очко было ошибкой: его отменяют, и матч доигрывают.
        saved.match.undo()
        try store.save(saved)
        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(60))
        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(90))
        try store.save(saved)

        delivery.deliverPending()

        #expect(transport.sent == [saved])
    }

    @Test("В пустом хранилище доставлять нечего")
    func anEmptyStoreQueuesNothing() throws {
        let transport = FakeTransport()

        MatchDelivery(store: try SQLiteMatchStore.inMemory(), sender: transport).deliverPending()

        #expect(transport.sent.isEmpty)
    }
}
