import os
import PadelDelivery
import PadelStorage
import SwiftUI

@main
struct PadelApp: App {
    /// The phone's store — its own, not the one on the watch: each app has a
    /// container of its own, and they have nothing to agree about. Matches
    /// arrive here from the watch and stay here for good.
    private let store: any MatchStore

    /// Receiving matches. Lives as long as the app: a match arrives into an
    /// app woken by the system for its sake alone rather than into one opened
    /// by its owner — and subscribing to that has to happen before any screen
    /// appears.
    private let reception: MatchReception

    init() {
        do {
            store = try SQLiteMatchStore.inApplicationSupport()
        } catch {
            logger.error("the store did not open: \(error.localizedDescription)")

            store = NoMatchStore()
        }

        // The session comes up after reception has subscribed: a parcel that
        // arrives into an app without a handler will not arrive a second time.
        let transport = WatchConnectivityTransport()

        reception = MatchReception(store: store, receiver: transport)

        transport.activate()
    }

    var body: some Scene {
        WindowGroup {
            HistoryView(store: store)
        }
    }
}

private let logger = Logger(subsystem: "com.vveidi.padel", category: "storage")
