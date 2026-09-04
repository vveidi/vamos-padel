import PadelStorage
import PadelSync
import SwiftUI
import os

@main
struct PadelApp: App {
    /// Хранилище телефона — своё, не то же, что на часах: у каждого
    /// приложения свой контейнер, и договариваться им не о чем. Матчи
    /// приезжают сюда с часов и остаются здесь навсегда.
    private let store: any MatchStore

    /// Приём матчей. Живёт столько же, сколько приложение: матч приезжает в
    /// приложение, разбуженное системой ради него одного, а не в открытое
    /// владельцем, — и подписаться на это надо до того, как экран появится.
    private let reception: MatchReception

    init() {
        do {
            store = try SQLiteMatchStore.inApplicationSupport()
        } catch {
            logger.error("Хранилище не открылось: \(error.localizedDescription)")

            store = NoMatchStore()
        }

        // Сессия поднимается после того, как приём подписался: посылка,
        // приехавшая в приложение без обработчика, не приедет второй раз.
        let transport = WatchConnectivityTransport()

        reception = MatchReception(store: store, receiver: transport)

        transport.activate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
    }
}

private let logger = Logger(subsystem: "com.vveidi.padel", category: "storage")
