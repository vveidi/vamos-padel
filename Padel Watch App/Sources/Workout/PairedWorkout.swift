import PadelDelivery

/// The workout of a paired match, which runs on the wrist and is handed to the
/// phone. It runs whatever the "Record to Health" switch says; the switch
/// decides only whether it is saved (ADR-0010).
final class PairedWorkout {
    private let workout: any Workout
    private let remote: MatchRemote
    private let savesToHealth: () -> Bool
    private let isScoringAlone: () -> Bool

    private var following: Task<Void, Never>?
    private var deadline: Task<Void, Never>?
    private var hasSeenAMatch = false

    init(
        workout: any Workout, remote: MatchRemote, savesToHealth: @escaping () -> Bool,
        isScoringAlone: @escaping () -> Bool
    ) {
        self.workout = workout
        self.remote = remote
        self.savesToHealth = savesToHealth
        self.isScoringAlone = isScoringAlone
    }

    /// Does nothing while one runs, or while the watch scores a match of its
    /// own, whose workout this would otherwise end. The workout ends once a
    /// match that ran is over or let go of — or, unsaved, when none arrives.
    func begin() {
        guard following == nil, !isScoringAlone() else { return }

        hasSeenAMatch = false
        workout.start(sharedWithPhone: true)

        following = Task {
            await followTheMatch()

            if !Task.isCancelled { finish() }
        }

        deadline = Task {
            try? await Task.sleep(for: PadelWorkout.watchWaitsForTheMatch)

            if !Task.isCancelled, !hasSeenAMatch { finish() }
        }
    }

    /// Where the phone's raise lands. A watch scoring a match of its own says
    /// so, rather than leave the phone waiting for a workout that never comes.
    func answerThePhone() {
        guard isScoringAlone() else { return begin() }

        // Unreachable leaves the phone to its wait, which ends in "unreachable".
        try? remote.send(.scoringAlone)
    }

    /// Ends, unsaved, a workout no match has arrived for, so a match scored
    /// alone can start its own.
    func standDown() {
        guard following != nil, !hasSeenAMatch else { return }

        finish()
    }

    private func followTheMatch() async {
        for await update in remote.updates() {
            if update.isRunning {
                hasSeenAMatch = true
            } else if hasSeenAMatch {
                return
            }
        }
    }

    private func finish() {
        following?.cancel()
        deadline?.cancel()
        following = nil
        deadline = nil

        workout.end(saving: hasSeenAMatch && savesToHealth())
    }
}
