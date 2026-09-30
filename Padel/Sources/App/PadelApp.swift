import os
import PadelDelivery
import PadelStorage
import PadelStorageDatabase
import SwiftUI
import UIKit

@main
struct PadelApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    private let store: any MatchStore

    /// Held for as long as the app: nothing reads it, and letting it go would
    /// drop the subscription.
    private let reception: MatchReception

    init() {
        do {
            store = try DatabaseMatchStore.inApplicationSupport()
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
            RootView(store: store)
                // The app is one court at dusk and there is no second design
                // for noon (ADR-0006). A phone set to light would otherwise
                // hand the system's own views — a navigation bar, a spinner, a
                // sheet — a white ground inside a night screen.
                .preferredColorScheme(.dark)
        }
    }
}

/// Where the app answers what it may be turned to. UIKit asks on every
/// rotation and again on a geometry request, and it refuses a request for an
/// orientation the answer does not name.
@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate {
    /// Narrowed to landscape by the scoreboard for as long as it is up.
    static var orientations = UIInterfaceOrientationMask.allButUpsideDown

    nonisolated func application(
        _ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        MainActor.assumeIsolated { Self.orientations }
    }
}

private let logger = Logger(subsystem: "com.vveidi.padel", category: "storage")
