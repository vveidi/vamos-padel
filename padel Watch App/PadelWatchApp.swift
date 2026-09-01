import PadelStorage
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

    init() {
        do {
            store = try SQLiteMatchStore.inApplicationSupport()
        } catch {
            logger.error("Хранилище не открылось: \(error.localizedDescription)")

            store = NoMatchStore()
        }
    }

    var body: some Scene {
        WindowGroup {
            MatchView(store: store, workout: HealthKitWorkout())
        }
    }
}

private let logger = Logger(subsystem: "com.vveidi.padel.watchkitapp", category: "storage")
