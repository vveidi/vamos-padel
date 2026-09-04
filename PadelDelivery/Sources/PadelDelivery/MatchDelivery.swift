import Foundation
import PadelStorage
import os

/// Доставка матчей на телефон — сторона часов.
///
/// Связывает две вещи, которые друг о друге не знают: хранилище, где лежит
/// очередь, и транспорт, который умеет только «поставить в очередь» и
/// «подтвердить». Игрок при этом не нажимает ничего — ни во время игры, ни
/// после.
///
/// Часы остаются источником правды до подтверждённой доставки (ADR-0002),
/// поэтому матч снимается с очереди подтверждением, а не отправкой.
public final class MatchDelivery: Sendable {
    private let store: any MatchStore
    private let sender: any MatchSender

    public init(store: any MatchStore, sender: any MatchSender) {
        self.store = store
        self.sender = sender

        sender.onDelivery { id in
            do {
                try store.markDelivered(id: id)
            } catch {
                // Матч останется в очереди и уедет ещё раз — это дешевле, чем
                // считать доставленным то, о чём мы не смогли записать.
                logger.error("Доставка не отмечена: \(error.localizedDescription)")
            }
        }
    }

    /// Отправляет всё, что ещё не доехало.
    ///
    /// Зовётся дважды: когда матч закончился и когда приложение запустилось.
    /// Второе и есть «очередь переживает перезапуск»: матч, не доехавший в
    /// прошлый раз, уезжает снова.
    ///
    /// Повторная отправка — не ошибка, а замысел. Своя очередь есть и у
    /// транспорта, и вместе они иногда доставят один матч дважды; телефон
    /// узнаёт его по идентификатору, и второй приезд ничего не создаёт.
    /// Потерянный матч восстановить неоткуда, лишний — не стоит ничего.
    public func deliverPending() {
        do {
            for match in try store.matchesAwaitingDelivery() {
                sender.send(match)
            }
        } catch {
            // До матча неудача не долетает: на корте важнее счёт, чем то, что
            // с ним будет вечером. Следующий запуск попробует снова.
            logger.error("Очередь на доставку не прочитана: \(error.localizedDescription)")
        }
    }
}

private let logger = Logger(subsystem: "com.vveidi.padel", category: "delivery")
