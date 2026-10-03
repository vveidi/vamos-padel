import HealthKit
import PadelLogging

/// Two guarantees over `HKWorkoutSession`: no failure ever reaches the match —
/// unavailable Health, a refused permission, a session dying mid-game are all
/// logged and swallowed — and the start and end transitions never overlap.
final class HealthKitWorkout: NSObject, Workout {
    private let healthStore = HKHealthStore()

    /// Non-nil exactly when a workout is running.
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    /// A queue one link long. Without it, undoing the last rally on the
    /// outcome screen starts a new workout before the previous one has ended
    /// and both write into ``session``.
    private var pending: Task<Void, Never>?

    func start(sharedWithPhone: Bool) {
        enqueue { await self.begin(sharedWithPhone: sharedWithPhone) }
    }

    func end(saving: Bool) {
        enqueue { await self.finish(saving: saving) }
    }

    private func enqueue(_ operation: @escaping () async -> Void) {
        let previous = pending

        pending = Task {
            await previous?.value
            await operation()
        }
    }

    private func begin(sharedWithPhone: Bool) async {
        guard session == nil, HKHealthStore.isHealthDataAvailable() else { return }

        // Logged either side because the request is silent about what it did.
        // Still "not determined" afterwards means the system declined to ask —
        // a locked watch answers everything that way; "denied" means an answer
        // is on file from an earlier install and no dialog is coming.
        logger.notice("health share permission before asking: \(self.shareStatus())")

        do {
            try await healthStore.requestAuthorization(
                toShare: PadelWorkout.typesToShare, read: PadelWorkout.typesToRead)
        } catch {
            logger.error("health permission was not granted: \(error.localizedDescription)")
        }

        logger.notice("health share permission after asking: \(self.shareStatus())")

        let configuration = PadelWorkout.configuration

        do {
            let session = try HKWorkoutSession(
                healthStore: healthStore, configuration: configuration)
            session.delegate = self

            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore, workoutConfiguration: configuration)

            let startedAt = Date()
            session.startActivity(with: startedAt)

            do {
                try await builder.beginCollection(at: startedAt)
            } catch {
                // The session is already running with nothing to collect into
                // it; left open it burns the battery until the end of the day.
                session.end()
                throw error
            }

            self.session = session
            self.builder = builder
        } catch {
            logger.error("the workout did not start: \(error.localizedDescription)")
            return
        }

        if sharedWithPhone, let session = self.session { await share(session) }
    }

    /// A failure leaves the workout running on the wrist alone, and the phone
    /// then holds its screen on as it does for a match it scores alone.
    private func share(_ session: HKWorkoutSession) async {
        do {
            try await session.startMirroringToCompanionDevice()
        } catch {
            logger.error("the workout was not mirrored to the phone: \(error.localizedDescription)")
        }
    }

    /// The written types only: HealthKit answers `notDetermined` for a read
    /// type whatever the truth, so that a refusal reveals nothing.
    private func shareStatus() -> String {
        PadelWorkout.typesToShare
            .map { "\($0.identifier): \(Self.name(of: healthStore.authorizationStatus(for: $0)))" }
            .sorted()
            .joined(separator: ", ")
    }

    private static func name(of status: HKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: "not determined"
        case .sharingDenied: "denied"
        case .sharingAuthorized: "authorized"
        @unknown default: "unknown (\(status.rawValue))"
        }
    }

    private func finish(saving: Bool) async {
        guard let session, let builder else { return }

        // Cleared before the first await, so a second `end` cannot close the
        // same session twice nor a `start` find the place still taken.
        self.session = nil
        self.builder = nil

        let endedAt = Date()

        // Ending the session stops its mirroring as well.
        session.end()

        do {
            try await builder.endCollection(at: endedAt)

            if saving {
                // The call that actually writes the workout into Health.
                try await builder.finishWorkout()
            } else {
                builder.discardWorkout()
            }
        } catch {
            logger.error("the workout was not written: \(error.localizedDescription)")
        }
    }
}

extension HealthKitWorkout: HKWorkoutSessionDelegate {
    /// Empty: the match commands the workout, not the other way round. The
    /// protocol requires the method.
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {}

    /// The only channel saying the workout died mid-match. Nothing answers it
    /// — the score goes on being counted — but a silent failure would leave
    /// "the match is not in Health" unexplained.
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession, didFailWithError error: Error
    ) {
        let description = error.localizedDescription

        Task { @MainActor in
            logger.error("the workout was interrupted: \(description)")
        }
    }

    /// The phone is out of range or its app was closed. The workout goes on
    /// here, unmirrored.
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession, didDisconnectFromRemoteDeviceWithError error: Error?
    ) {
        let description = error?.localizedDescription ?? "no error"

        Task { @MainActor in
            logger.notice("the phone let go of the mirrored workout: \(description)")
        }
    }
}

private let logger = PadelLogger(subsystem: "com.vveidi.padel.watchkitapp", category: "workout")
