import HealthKit
import PadelDelivery
import PadelLogging
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

    private let logSender: any LogSender

    @Environment(\.scenePhase) private var scenePhase

    init() {
        appLogger.info("the app launched")

        do {
            let opened = try DatabaseMatchStore.inApplicationSupport()
            store = opened

            logOpened(opened)
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

        logSender = transport

        transport.activate()
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                store: store, workout: workout, delivery: delivery, remote: remote,
                pairedWorkout: pairedWorkout
            )
            .environment(\.logSender, logSender)
        }
        .onChange(of: scenePhase, logPhaseChange)
    }
}

final class PadelWatchAppDelegate: NSObject, WKApplicationDelegate {
    /// Set while the app is assembled, which is before the system makes any
    /// call to the delegate.
    static var pairedWorkout: PairedWorkout?

    /// Where the phone's `startWatchApp(toHandle:)` lands: a paired match
    /// started there.
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        Self.pairedWorkout?.answerThePhone()
    }
}

private func logOpened(_ store: some MatchStore) {
    do {
        let count = try store.matches().count

        logger.info("the store opened, matches in it: \(count)")
    } catch {
        logger.error("the matches were not counted: \(error.localizedDescription)")
    }
}

private func logPhaseChange(from old: ScenePhase, to new: ScenePhase) {
    switch (old, new) {
    case (_, .background): appLogger.info("the app went to the background")
    case (.background, _): appLogger.info("the app came back")
    default: break
    }
}

private let logger = PadelLogger(subsystem: "com.vveidi.padel.watchkitapp", category: "storage")

private let appLogger = PadelLogger(subsystem: "com.vveidi.padel.watchkitapp", category: "app")
