import Foundation
import PadelStorage

/// Доставка матчей на телефон — сторона часов.
///
/// Связывает две вещи, которые друг о друге не знают: очередь, где лежат
/// недоехавшие матчи, и транспорт, который умеет только «поставить в очередь»,
/// «сказать, что готов» и «привезти расписку». Игрок при этом не нажимает
/// ничего — ни во время игры, ни после.
///
/// Часы остаются источником правды до подтверждённой доставки (ADR-0002),
/// поэтому матч снимает с очереди расписка с телефона, а не отправка.
public final class MatchDelivery: Sendable {
    private let queue: any MatchDeliveryQueue
    private let sender: any MatchSender

    public init(queue: any MatchDeliveryQueue, sender: any MatchSender) {
        self.queue = queue
        self.sender = sender

        // Накопившееся уезжает, как только транспорт готов, — в этом и состоит
        // «очередь переживает перезапуск». Не при запуске экрана: сессия к
        // телефону поднимается асинхронно, и матч, отданный до готовности, не
        // уехал бы никуда, а следующей попытки в этот запуск не случилось бы.
        sender.onReady { [queue, sender] in
            Self.deliverPending(from: queue, to: sender)
        }

        sender.onDelivery { [queue] match in
            do {
                try queue.markDelivered(match)
            } catch {
                // Матч останется в очереди и уедет ещё раз — это дешевле, чем
                // считать доставленным то, о чём мы не смогли записать.
                logger.error("Доставка не отмечена: \(error.localizedDescription)")
            }
        }
    }

    /// Отправляет всё, что ещё не доехало.
    ///
    /// Зовётся, когда матч закончился; при запуске то же самое делает
    /// готовность транспорта.
    ///
    /// Повторная отправка — не ошибка, а замысел. Своя очередь есть и у
    /// транспорта, и вместе они иногда доставят один матч дважды; телефон
    /// узнаёт его по идентификатору, и второй приезд ничего не создаёт.
    /// Потерянный матч восстановить неоткуда, лишний — не стоит ничего.
    public func deliverPending() {
        Self.deliverPending(from: queue, to: sender)
    }

    private static func deliverPending(
        from queue: any MatchDeliveryQueue, to sender: any MatchSender
    ) {
        do {
            for match in try queue.matchesAwaitingDelivery() {
                sender.send(match)
            }
        } catch {
            // До матча неудача не долетает: на корте важнее счёт, чем то, что
            // с ним будет вечером. Следующий запуск попробует снова.
            logger.error("Очередь на доставку не прочитана: \(error.localizedDescription)")
        }
    }
}
