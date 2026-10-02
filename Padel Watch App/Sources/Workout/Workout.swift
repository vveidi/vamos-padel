/// A running workout is what keeps the app foregrounded for the length of a
/// match: without one the system unloads it between games and the wrist raise
/// returns to the watch face. The health data is a side effect.
protocol Workout {
    /// Does nothing if a workout is already running.
    /// - Parameter sharedWithPhone: Hands the session to the phone as well, which is
    ///   what keeps the phone's app running through a paired match (ADR-0010).
    func start(sharedWithPhone: Bool)

    /// Does nothing if none was started.
    /// - Parameter saving: `false` throws the workout away instead of writing
    ///   it to Health.
    func end(saving: Bool)
}

extension Workout {
    func start() {
        start(sharedWithPhone: false)
    }

    func end() {
        end(saving: true)
    }
}

/// - Note: A denied Health permission does not lead here — such a match still
///   runs through ``HealthKitWorkout``, which simply writes nothing.
struct NoWorkout: Workout {
    func start(sharedWithPhone: Bool) {}

    func end(saving: Bool) {}
}
