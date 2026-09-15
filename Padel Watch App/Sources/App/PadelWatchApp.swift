import os
import PadelDelivery
import PadelStorage
import PadelStorageDatabase
import SwiftUI

@main
struct PadelWatchApp: App {
    /// The store is opened once per launch of the app.
    ///
    /// If it did not open, the match is played all the same — it just will not
    /// survive being unloaded. That is worse than a match with a record, and
    /// better than an app that failed to launch on court.
    ///
    /// It is also the delivery queue (ADR-0004), hence two protocols here: the
    /// screens get the store, delivery gets the queue, and the object is one.
    private let store: any MatchStore & MatchDeliveryQueue

    /// Delivery to the phone. Lives as long as the app: the confirmation
    /// arrives whenever, including long after the player left the court and put
    /// the watch away.
    private let delivery: MatchDelivery

    init() {
        do {
            store = try DatabaseMatchStore.inApplicationSupport()
        } catch {
            logger.error("the store did not open: \(error.localizedDescription)")

            store = NoMatchStore()
        }

        // The session comes up after delivery has subscribed: the transport
        // reports its readiness and an arrived match once each. What has piled
        // up will leave by itself as soon as the session comes up — which is
        // why nobody calls the launch-time sending by hand.
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
