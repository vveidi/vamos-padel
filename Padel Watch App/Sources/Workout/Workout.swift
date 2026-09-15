/// A running workout is what keeps the app foregrounded for the length of a
/// match: without one the system unloads it between games and the wrist raise
/// returns to the watch face. The health data is a side effect.
protocol Workout {
    /// Does nothing if a workout is already running.
    func start()

    /// Does nothing if none was started.
    func end()
}

/// - Note: A denied Health permission does not lead here — such a match still
///   runs through ``HealthKitWorkout``, which simply writes nothing.
struct NoWorkout: Workout {
    func start() {}

    func end() {}
}
