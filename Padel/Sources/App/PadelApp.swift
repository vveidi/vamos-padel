import PadelDelivery
import PadelLogging
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
        .onChange(of: scenePhase, logPhaseChange)
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

private let logger = PadelLogger(subsystem: "com.vveidi.padel", category: "storage")

private let appLogger = PadelLogger(subsystem: "com.vveidi.padel", category: "app")
