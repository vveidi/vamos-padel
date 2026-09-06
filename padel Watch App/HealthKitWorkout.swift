import HealthKit
import os

/// The workout on HealthKit: `HKWorkoutSession` plus `HKLiveWorkoutBuilder`.
///
/// A thin wrapper over a system API, and it is not covered by tests — decided
/// so in the spec, because there is nothing to check here beyond HealthKit
/// itself. All the wrapper adds of its own are two promises. First: a failure
/// never reaches the match. Health may be unavailable, permission may not be
/// granted, the session may die mid-game; none of that must throw the score off
/// or make it disappear. Second: a workout is either running or not, and the
/// transitions between those states do not tread on each other's heels.
final class HealthKitWorkout: NSObject, Workout {
    private let healthStore = HKHealthStore()

    /// What we write: the workout itself and the calories burned. Heart rate
    /// is deliberately absent from the list — the system writes it, we only
    /// read.
    private static let typesToShare: Set<HKSampleType> = [
        HKObjectType.workoutType(),
        HKQuantityType(.activeEnergyBurned),
    ]

    /// What we read: what the workout builder puts into it by itself.
    private static let typesToRead: Set<HKObjectType> = [
        HKQuantityType(.heartRate),
        HKQuantityType(.activeEnergyBurned),
    ]

    /// Non-nil exactly when a workout is running.
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    /// A queue one link long.
    ///
    /// Starting and ending are asynchronous operations of several steps, and
    /// they are called by a screen that cannot wait. Without the queue,
    /// undoing the last rally on the outcome screen would manage to start a
    /// new workout before the previous one had ended, and both would write into
    /// the same `session`.
    private var pending: Task<Void, Never>?

    func start() {
        enqueue { await self.begin() }
    }

    func end() {
        enqueue { await self.finish() }
    }

    private func enqueue(_ operation: @escaping () async -> Void) {
        let previous = pending

        pending = Task {
            await previous?.value
            await operation()
        }
    }

    private func begin() async {
        guard session == nil, HKHealthStore.isHealthDataAvailable() else { return }

        // Permission is asked before every match but shown once: HealthKit
        // stays quiet by itself once every type has been decided on. A denial
        // never reaches here — for reads HealthKit deliberately never reports
        // one, so that an app cannot infer anything about health from it — so
        // the answer to any outcome is the same: carry on and do not get in
        // the match's way. The explanation of why a match counter needs health
        // access lives in NSHealth*UsageDescription; the system shows it in
        // this very dialog.
        // The status is logged on both sides of the request because the
        // request itself is silent about what it did: it neither throws nor
        // reports when it decides against showing the dialog. Two readings
        // tell those cases apart. Still "not determined" afterwards means the
        // system declined to ask — a locked watch keeps the Health store shut
        // and answers everything that way. "denied" means an answer is already
        // on file from an earlier install, and no dialog is ever coming.
        logger.notice("health share permission before asking: \(self.shareStatus(), privacy: .public)")

        do {
            try await healthStore.requestAuthorization(
                toShare: Self.typesToShare, read: Self.typesToRead)
        } catch {
            logger.error("health permission was not granted: \(error.localizedDescription)")
        }

        logger.notice("health share permission after asking: \(self.shareStatus(), privacy: .public)")

        let configuration = HKWorkoutConfiguration()

        // Padel is not among the workout types, and tennis is the closest
        // there is: the same racket doubles court, the same estimate of effort.
        // It is why the match will appear in Health under the word "Tennis".
        configuration.activityType = .tennis

        // We do not measure distance, and an indoor court means only one thing
        // to the watch: do not wake the GPS. An hour and a half of GPS for
        // nothing is the battery that will not last a second match.
        configuration.locationType = .indoor

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
                // The session is already running and there is nothing to put
                // into it. Leaving it open means burning the battery until the
                // end of the day.
                session.end()
                throw error
            }

            self.session = session
            self.builder = builder
        } catch {
            logger.error("the workout did not start: \(error.localizedDescription)")
        }
    }

    /// What HealthKit says about the types we write, as one line of log.
    ///
    /// The types we read are not here, and cannot be: HealthKit answers
    /// `notDetermined` for a read type whatever the truth, so that an app
    /// cannot infer from a refusal that there is something to hide.
    private func shareStatus() -> String {
        Self.typesToShare
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

    private func finish() async {
        guard let session, let builder else { return }

        // The references are cleared before the first await: while the workout
        // is closing, the match is already being counted without it, and a
        // second `end` must not close it twice, nor a `start` find the place
        // taken.
        self.session = nil
        self.builder = nil

        let endedAt = Date()
        session.end()

        do {
            try await builder.endCollection(at: endedAt)

            // This is the call that puts the workout into Health. Without it
            // the match stays a session that came and went.
            try await builder.finishWorkout()
        } catch {
            logger.error("the workout was not written: \(error.localizedDescription)")
        }
    }
}

extension HealthKitWorkout: HKWorkoutSessionDelegate {
    /// A change of session state does not concern us: the match commands the
    /// workout, not the other way round. The method is required by the
    /// protocol.
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {}

    /// The only channel by which it can be heard that the workout died
    /// mid-match. There is nothing to answer with — the score keeps being
    /// counted — but staying silent is not an option: otherwise "the match is
    /// not in Health" would be left without an explanation.
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession, didFailWithError error: Error
    ) {
        let description = error.localizedDescription

        Task { @MainActor in
            logger.error("the workout was interrupted: \(description)")
        }
    }
}

private let logger = Logger(subsystem: "com.vveidi.padel.watchkitapp", category: "workout")
