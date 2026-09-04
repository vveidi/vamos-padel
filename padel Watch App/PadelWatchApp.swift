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
    private let store: any MatchStore

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

        // Сессия поднимается после того, как доставка подписалась на
        // подтверждения: транспорт сообщает о доехавшем матче один раз.
        let transport = WatchConnectivityTransport()

        delivery = MatchDelivery(store: store, sender: transport)

        transport.activate()
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store, workout: HealthKitWorkout(), delivery: delivery)
        }
    }
}

private let logger = Logger(subsystem: "com.vveidi.padel.watchkitapp", category: "storage")
