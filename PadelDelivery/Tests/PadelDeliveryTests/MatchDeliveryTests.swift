import Foundation
import PadelScoring
import PadelStorage
import Testing

@testable import PadelDelivery

@Suite("Доставка матчей на телефон")
struct MatchDeliveryTests {
    /// То, ради чего тикет и написан: игрок не нажимает «синхронизировать».
    /// Матч кончился — и уехал, телефон при этом может лежать в раздевалке.
    @Test("Законченный матч ставится в очередь")
    func aFinishedMatchIsQueued() throws {
        let store = try SQLiteMatchStore.inMemory()
        let transport = FakeTransport()
        let saved = SavedMatch.played([.us, .us], ruleset: toTwo)

        try store.save(saved)
        MatchDelivery(queue: store, sender: transport).deliverPending()

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
        MatchDelivery(queue: store, sender: transport).deliverPending()

        #expect(transport.sent == [abandoned])
    }

    @Test("Идущий матч в очередь не попадает")
    func aMatchInProgressIsNotQueued() throws {
        let store = try SQLiteMatchStore.inMemory()
        let transport = FakeTransport()

        try store.save(SavedMatch.played([.us], ruleset: toTwo))
        MatchDelivery(queue: store, sender: transport).deliverPending()

        #expect(transport.sent.isEmpty)
    }

    /// Очередь — это само хранилище, поэтому перезапуск она переживает вместе
    /// с матчами. Второе соединение к той же базе — это и есть перезапуск.
    @Test("Очередь переживает перезапуск приложения")
    func theQueueSurvivesARelaunch() throws {
        let database = "delivery-\(UUID().uuidString)"
        let saved = SavedMatch.played([.us, .us], ruleset: toTwo)

        let store = try SQLiteMatchStore.inMemory(named: database)
        try store.save(saved)

        let afterRelaunch = try SQLiteMatchStore.inMemory(named: database)
        let transport = FakeTransport()

        // Никто не зовёт доставку руками: приложение запустилось, транспорт
        // поднялся — этого довольно.
        _ = MatchDelivery(queue: afterRelaunch, sender: transport)
        transport.becomeReady()

        #expect(transport.sent.map(\.id) == [saved.id])
    }

    /// Сессия к телефону поднимается асинхронно. Матч, отданный ей до этого,
    /// не уехал бы никуда, а второй попытки в этот запуск не случилось бы —
    /// поэтому очередь ждёт готовности, а не наоборот.
    @Test("До готовности транспорта не уезжает ничего")
    func nothingIsSentBeforeTheTransportIsReady() throws {
        let store = try SQLiteMatchStore.inMemory()
        let transport = FakeTransport()

        try store.save(SavedMatch.played([.us, .us], ruleset: toTwo))
        _ = MatchDelivery(queue: store, sender: transport)

        #expect(transport.sent.isEmpty)

        transport.becomeReady()

        #expect(transport.sent.count == 1)
    }

    /// Часы — источник правды до подтверждённой доставки (ADR-0002), поэтому
    /// с очереди матч снимает подтверждение, а не отправка.
    @Test("Подтверждённый матч больше не уезжает")
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

    /// Телефона не было весь вечер, а приложение выгрузили. Неподтверждённый
    /// матч обязан уехать снова — иначе он не уедет никогда.
    @Test("Неподтверждённый матч уезжает снова")
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

    /// Отмена очка в законченном матче (тикет 05) возвращает его в игру, и
    /// доигранный заново он расходится с тем, что уже на телефоне. Отметка о
    /// доставке гаснет с любой записью матча, поэтому он уезжает второй раз —
    /// а второй приезд на телефоне затирает первый.
    @Test("Матч, изменившийся после доставки, уезжает заново")
    func aMatchChangedAfterDeliveryIsSentAgain() throws {
        let store = try SQLiteMatchStore.inMemory()
        let transport = FakeTransport()
        let delivery = MatchDelivery(queue: store, sender: transport)

        var saved = SavedMatch.played([.us, .us], ruleset: toTwo)
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

    /// Расписка приходит когда угодно, в том числе через час после отправки.
    /// За это время матч мог измениться — и расписка о прошлой версии не
    /// вправе гасить очередь, в которую он из-за этой правки вернулся.
    @Test("Расписка о прошлой версии матча очередь не гасит")
    func aReceiptForAnOlderVersionDoesNotClearTheQueue() throws {
        let store = try SQLiteMatchStore.inMemory()
        let transport = FakeTransport()
        let delivery = MatchDelivery(queue: store, sender: transport)

        var saved = SavedMatch.played([.us, .us], ruleset: toTwo)
        try store.save(saved)
        delivery.deliverPending()

        let delivered = saved

        // Пока расписка ехала, последнее очко отменили и матч доиграли заново.
        saved.match.undo()
        try store.save(saved)
        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(60))
        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(90))
        try store.save(saved)

        transport.deliverReceipts(for: [delivered])
        transport.forget()
        delivery.deliverPending()

        #expect(transport.sent == [saved])
    }

    /// Матч начинается первым розыгрышем — так его определяет глоссарий.
    /// Прекращённый раньше сохраняется честно, но в истории на телефоне ему
    /// делать нечего: «0:0, 0 минут» это не история, а след от промаха.
    @Test("Матч без единого розыгрыша не уезжает")
    func aMatchWithoutRalliesIsNotSent() throws {
        let store = try SQLiteMatchStore.inMemory()
        let transport = FakeTransport()

        var empty = SavedMatch(match: Match(ruleset: toTwo), startedAt: aMoment)
        empty.match.abandon()

        try store.save(empty)
        MatchDelivery(queue: store, sender: transport).deliverPending()

        #expect(empty.match.state.outcome.isOver)
        #expect(transport.sent.isEmpty)
    }

    @Test("В пустом хранилище доставлять нечего")
    func anEmptyStoreQueuesNothing() throws {
        let transport = FakeTransport()

        MatchDelivery(queue: try SQLiteMatchStore.inMemory(), sender: transport).deliverPending()

        #expect(transport.sent.isEmpty)
    }
}
