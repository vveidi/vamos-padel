/// The workout the match runs inside.
///
/// The app does not survive an hour and a half on court by itself: the system
/// unloads it between games, the screen goes dark, and raising your wrist
/// returns you to the watch face. Registering the match as a workout is the
/// only way to change that. Heart rate, calories and activity rings come as a
/// side effect, but they are not the reason: the reason is that the score has
/// to be on the screen for the whole match.
///
/// A protocol rather than HealthKit outright, for the same reason the store and
/// the transport sit behind protocols (ADR-0002): the screens must know nothing
/// about health. The immediate benefit is the preview, which would otherwise
/// ask for Health access and write a workout into it every time somebody opened
/// the canvas.
protocol Workout {
    /// Starts the workout. Does nothing if one is already running.
    func start()

    /// Ends the workout and hands it to Health. Does nothing if none was
    /// started.
    func end()
}

/// No workout at all: the match is played, the score is counted, and nothing
/// reaches Health.
///
/// For previews, and for the case where there is no health access whatsoever. A
/// denied permission does not lead here: a match with a denial still runs
/// through `HealthKitWorkout`, which simply writes nothing.
struct NoWorkout: Workout {
    func start() {}

    func end() {}
}
