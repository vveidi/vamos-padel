import HealthKit
import Observation
import PadelDelivery
import PadelLogging

/// The phone's half of a paired match's workout: the session the watch
/// mirrors here, which is what lets the app run on in a pocket (ADR-0010).
@Observable
final class WatchWorkout: NSObject {
    enum Start {
        case started

        /// Without the mirrored session the phone lives only while its screen
        /// is on, so a paired match is not offered at all.
        case healthRefused

        case watchDidNotAnswer

        /// The watch is scoring a match of its own, which is never taken over.
        case watchScoresAlone
    }

    /// `true` from the moment the watch's session arrives until the match it
    /// belongs to ends, or the session does.
    private(set) var holdsTheWorkout = false

    /// Read without asking: asking is left to the first paired start.
    private(set) var isHealthRefused: Bool

    @ObservationIgnored private let healthStore = HKHealthStore()

    @ObservationIgnored private let scorer: MatchScorer

    @ObservationIgnored private var session: HKWorkoutSession?

    @ObservationIgnored private var onArrival: (() -> Void)?

    /// Subscribes at once, for the reason ``MatchReception`` does: the watch's
    /// session launches the app into the background, with no screen to wait for.
    init(scorer: MatchScorer) {
        isHealthRefused = Self.isRefused(by: healthStore)
        self.scorer = scorer

        super.init()

        healthStore.workoutSessionMirroringStartHandler = { [weak self] session in
            Task { @MainActor in self?.hold(session) }
        }

        Task { [weak self] in await self?.follow(scorer) }
    }

    /// Asks for Health the first time; the system shows its dialog once and
    /// answers from what is on file after that.
    func start() async -> Start {
        guard await authorize() else { return .healthRefused }

        if holdsTheWorkout { return .started }

        // Listened for before the watch is asked: its answer can arrive
        // before `startWatchApp` returns.
        let (arrivals, arrival) = AsyncStream<Void>.makeStream()
        onArrival = { arrival.yield() }
        defer { onArrival = nil }
        let declines = scorer.remoteDeclines()

        do {
            try await healthStore.startWatchApp(toHandle: PadelWorkout.configuration)
        } catch {
            logger.error("the watch app did not start: \(error.localizedDescription)")
            return .watchDidNotAnswer
        }

        return await Self.answer(arrivals: arrivals, declines: declines)
    }

    /// Reads the answer on file again, which the player may have changed in
    /// Settings since.
    func recheckHealth() {
        isHealthRefused = Self.isRefused(by: healthStore)
    }

    /// - Returns: `false` when Health is refused.
    func authorize() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            isHealthRefused = true
            return false
        }

        do {
            try await healthStore.requestAuthorization(
                toShare: PadelWorkout.typesToShare, read: PadelWorkout.typesToRead)
        } catch {
            logger.error("health permission was not granted: \(error.localizedDescription)")
        }

        isHealthRefused = Self.isRefused(by: healthStore)

        return !isHealthRefused
    }

    /// The workout type is the one share permission the mirrored session needs.
    private static func isRefused(by healthStore: HKHealthStore) -> Bool {
        !HKHealthStore.isHealthDataAvailable()
            || healthStore.authorizationStatus(for: .workoutType()) == .sharingDenied
    }

    /// Whichever comes first: the workout, the watch declining, or the end of
    /// the wait.
    private static func answer(arrivals: AsyncStream<Void>, declines: AsyncStream<Void>) async -> Start {
        await withTaskGroup(of: Start.self) { group in
            group.addTask {
                for await _ in arrivals { return .started }
                return .watchDidNotAnswer
            }
            group.addTask {
                for await _ in declines { return .watchScoresAlone }
                return .watchDidNotAnswer
            }
            group.addTask {
                try? await Task.sleep(for: PadelWorkout.phoneWaitsForTheWorkout)
                return .watchDidNotAnswer
            }

            let answer = await group.next() ?? .watchDidNotAnswer
            group.cancelAll()

            return answer
        }
    }

    // MARK: Holding the session

    private func hold(_ session: HKWorkoutSession) {
        session.delegate = self

        self.session = session
        holdsTheWorkout = true

        onArrival?()
    }

    private func letGo(of session: HKWorkoutSession? = nil) {
        guard session == nil || session === self.session else { return }

        self.session = nil
        holdsTheWorkout = false
    }

    /// Lets go once a match that ran is over or released. A session that
    /// arrives ahead of its match, from a start on the watch, is kept.
    private func follow(_ scorer: MatchScorer) async {
        var wasRunning = false

        for await update in scorer.updates() {
            let isRunning = update.isRunning

            if wasRunning, !isRunning { letGo() }

            wasRunning = isRunning
        }
    }
}

extension WatchWorkout: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        guard toState == .ended || toState == .stopped else { return }

        Task { @MainActor in self.letGo(of: workoutSession) }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        let description = error.localizedDescription

        Task { @MainActor in
            logger.error("the mirrored workout failed: \(description)")
        }
    }

    /// The watch is out of range, flat, or its app was closed.
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession, didDisconnectFromRemoteDeviceWithError error: Error?
    ) {
        Task { @MainActor in self.letGo(of: workoutSession) }
    }
}

private let logger = PadelLogger(subsystem: "com.vveidi.padel", category: "workout")
