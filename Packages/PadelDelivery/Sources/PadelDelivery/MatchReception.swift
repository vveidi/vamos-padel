import Foundation
import PadelStorage

/// Приём матчей с часов — сторона телефона.
///
/// Записывает приехавший матч и расписывается в этом перед часами. Расписка
/// — не формальность: пока она не пришла, матч на часах стоит в очереди и
/// уедет снова (ADR-0002), поэтому не записанный здесь матч не теряется, а
/// приезжает ещё раз.
///
/// Экрану истории (тикеты 11, 12) матч потом достаётся из хранилища, а не
/// отсюда: он приезжает в приложение, разбуженное системой ради него одного,
/// и никакого экрана в этот момент может не быть.
///
/// Один и тот же матч приезжает дважды, если расписка не дошла. Второй приезд
/// не заводит второй матч: хранилище узнаёт его по идентификатору и обновляет
/// запись — тем же журналом, если он не менялся, и продолженным, если после
/// доставки отменили очко и доиграли.
public final class MatchReception: Sendable {
    private let store: any MatchStore
    private let receiver: any MatchReceiver

    public init(store: any MatchStore, receiver: any MatchReceiver) {
        self.store = store
        self.receiver = receiver

        receiver.onArrival { [store, receiver] match in
            Self.receive(match, into: store, confirmingTo: receiver)
        }
    }

    /// Записывает приехавший матч и расписывается в этом.
    public func receive(_ match: SavedMatch) {
        Self.receive(match, into: store, confirmingTo: receiver)
    }

    private static func receive(
        _ match: SavedMatch, into store: any MatchStore, confirmingTo receiver: any MatchReceiver
    ) {
        do {
            try store.save(match)
        } catch {
            // Расписка не уходит, и часы привезут матч ещё раз — со следующим
            // запуском приложения на часах.
            logger.error("Приехавший матч не сохранён: \(error.localizedDescription)")
            return
        }

        receiver.confirmArrival(of: match)
    }
}
