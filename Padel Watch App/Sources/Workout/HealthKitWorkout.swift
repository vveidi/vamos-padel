import HealthKit
import os

/// Two guarantees over `HKWorkoutSession`: no failure ever reaches the match —
/// unavailable Health, a refused permission, a session dying mid-game are all
/// logged and swallowed — and the start and end transitions never overlap.
final class HealthKitWorkout: NSObject, Workout {
    private let healthStore = HKHealthStore()

    /// Heart rate is deliberately absent: the system writes it, we only read.
    private static let typesToShare: Set<HKSampleType> = [
        HKObjectType.workoutType(),
        HKQuantityType(.activeEnergyBurned),
    ]

    /// What the live builder collects on its own.
    private static let typesToRead: Set<HKObjectType> = [
        HKQuantityType(.heartRate),
        HKQuantityType(.activeEnergyBurned),
    ]

    /// Non-nil exactly when a workout is running.
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    /// A queue one link long. Without it, undoing the last rally on the
    /// outcome screen starts a new workout before the previous one has ended
    /// and both write into ``session``.
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

        // Logged either side because the request is silent about what it did.
        // Still "not determined" afterwards means the system declined to ask —
        // a locked watch answers everything that way; "denied" means an answer
        // is on file from an earlier install and no dialog is coming.
        logger.notice("health share permission before asking: \(self.shareStatus(), privacy: .public)")

        do {
            try await healthStore.requestAuthorization(
                toShare: Self.typesToShare, read: Self.typesToRead)
        } catch {
            logger.error("health permission was not granted: \(error.localizedDescription)")
        }

        logger.notice("health share permission after asking: \(self.shareStatus(), privacy: .public)")

        let configuration = HKWorkoutConfiguration()

        // HealthKit has no padel; tennis is the closest estimate of effort.
        // The match therefore appears in Health under "Tennis".
        configuration.activityType = .tennis

        // Indoor keeps the GPS asleep, which nothing here needs and which
        // would cost the battery a second match.
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
                // The session is already running with nothing to collect into
                // it; left open it burns the battery until the end of the day.
                session.end()
                throw error
            }

            self.session = session
            self.builder = builder
        } catch {
            logger.error("the workout did not start: \(error.localizedDescription)")
        }
    }

    /// The written types only: HealthKit answers `notDetermined` for a read
    /// type whatever the truth, so that a refusal reveals nothing.
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

        // Cleared before the first await, so a second `end` cannot close the
        // same session twice nor a `start` find the place still taken.
        self.session = nil
        self.builder = nil

        let endedAt = Date()
        session.end()

        do {
            try await builder.endCollection(at: endedAt)

            // The call that actually writes the workout into Health.
            try await builder.finishWorkout()
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
}

private let logger = Logger(subsystem: "com.vveidi.padel.watchkitapp", category: "workout")
