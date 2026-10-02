import os
import PadelDelivery
import PadelStorage
import PadelStorageDatabase
import SwiftUI

@main
struct PadelWatchApp: App {
    private let store: any MatchStore & MatchDeliveryQueue

    /// Owned by the app rather than by the match screen: the phone's
    /// confirmation can arrive long after the match it confirms has ended.
    private let delivery: MatchDelivery

    private let remote: MatchRemote

    init() {
        do {
            store = try DatabaseMatchStore.inApplicationSupport()
        } catch {
            logger.error("the store did not open: \(error.localizedDescription)")

            store = NoMatchStore()
        }

        // `activate()` comes last: the transport reports readiness and an
        // arrived match once each, so both ends have to be subscribed first.
        let transport = WatchConnectivityTransport()

        delivery = MatchDelivery(queue: store, sender: transport)
        remote = MatchRemote(link: transport)

        transport.activate()
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store, workout: HealthKitWorkout(), delivery: delivery, remote: remote)
        }
    }
}

private let logger = Logger(subsystem: "com.vveidi.padel.watchkitapp", category: "storage")
