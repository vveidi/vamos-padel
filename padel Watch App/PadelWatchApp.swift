import PadelStorage
import PadelDelivery
import SwiftUI
import os

@main
struct PadelWatchApp: App {
    /// Хранилище открывается один раз за запуск приложения.
    ///
    /// Не открылось — матч всё равно ведётся, просто не переживёт выгрузки.
    /// Это хуже, чем матч с записью, и лучше, чем приложение, которое не
    /// запустилось на корте.
    ///
    /// Оно же очередь на доставку (ADR-0004), поэтому здесь два протокола:
    /// экранам достаётся хранилище, доставке — очередь, а объект один.
    private let store: any MatchStore & MatchDeliveryQueue

    /// Доставка на телефон. Живёт столько же, сколько приложение: подтверждение
    /// приходит когда угодно, в том числе задолго после того, как игрок ушёл с
    /// корта и убрал часы.
    private let delivery: MatchDelivery

    init() {
        do {
            store = try SQLiteMatchStore.inApplicationSupport()
        } catch {
            logger.error("Хранилище не открылось: \(error.localizedDescription)")

            store = NoMatchStore()
        }

        // Сессия поднимается после того, как доставка подписалась: транспорт
        // сообщает о своей готовности и о доехавшем матче по одному разу.
        // Накопившееся уедет само, как только сессия поднимется, — поэтому
        // отправку при запуске никто не зовёт руками.
        let transport = WatchConnectivityTransport()

        delivery = MatchDelivery(queue: store, sender: transport)

        transport.activate()
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store, workout: HealthKitWorkout(), delivery: delivery)
        }
    }
}

private let logger = Logger(subsystem: "com.vveidi.padel.watchkitapp", category: "storage")
