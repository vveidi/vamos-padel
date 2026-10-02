import HealthKit
import os
import PadelDelivery
import PadelStorage
import PadelStorageDatabase
import SwiftUI
import WatchKit

@main
struct PadelWatchApp: App {
    @WKApplicationDelegateAdaptor private var delegate: PadelWatchAppDelegate

    private let store: any MatchStore & MatchDeliveryQueue

    /// Owned by the app rather than by the match screen: the phone's
    /// confirmation can arrive long after the match it confirms has ended.
    private let delivery: MatchDelivery

    /// One for the app: the transport keeps a single update handler, so a
    /// second remote would take the first one's.
    private let remote: MatchRemote

    private let workout = HealthKitWorkout()

    private let pairedWorkout: PairedWorkout

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

        pairedWorkout = PairedWorkout(
            workout: workout,
            remote: remote,
            savesToHealth: { UserDefaults.standard.object(forKey: "records-to-health") as? Bool ?? true },
            isScoringAlone: { [store] in (try? store.matchInProgress()) != nil })
        PadelWatchAppDelegate.pairedWorkout = pairedWorkout

        transport.activate()
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                store: store, workout: workout, delivery: delivery, remote: remote,
                pairedWorkout: pairedWorkout)
        }
    }
}

final class PadelWatchAppDelegate: NSObject, WKApplicationDelegate {
    /// Set while the app is assembled, which is before the system makes any
    /// call to the delegate.
    static var pairedWorkout: PairedWorkout?

    /// Where the phone's `startWatchApp(toHandle:)` lands: a paired match
    /// started there.
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        Self.pairedWorkout?.begin()
    }
}

private let logger = Logger(subsystem: "com.vveidi.padel.watchkitapp", category: "storage")
