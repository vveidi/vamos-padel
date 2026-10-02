import os
import PadelDelivery
import PadelStorage
import PadelStorageDatabase
import SwiftUI

@main
struct PadelApp: App {
    private let store: any MatchStore

    /// Held for as long as the app: nothing reads it, and letting it go would
    /// drop the subscription.
    private let reception: MatchReception

    private let scorer: MatchScorer

    private let workout: WatchWorkout

    init() {
        do {
            store = try DatabaseMatchStore.inApplicationSupport()
        } catch {
            logger.error("the store did not open: \(error.localizedDescription)")

            store = NoMatchStore()
        }

        // The session comes up after both ends have subscribed: a parcel that
        // arrives into an app without a handler will not arrive a second time.
        let transport = WatchConnectivityTransport()

        reception = MatchReception(store: store, receiver: transport)

        scorer = MatchScorer(store: store, link: transport)

        workout = WatchWorkout(scorer: scorer)

        transport.activate()
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store, scorer: scorer, workout: workout)
                // The app is one court at dusk and there is no second design
                // for noon (ADR-0006). A phone set to light would otherwise
                // hand the system's own views — a navigation bar, a spinner, a
                // sheet — a white ground inside a night screen.
                .preferredColorScheme(.dark)
        }
    }
}

private let logger = Logger(subsystem: "com.vveidi.padel", category: "storage")
