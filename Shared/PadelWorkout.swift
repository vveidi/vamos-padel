import HealthKit

/// One definition for both apps: the phone raises the watch into the very
/// workout the watch would have started for itself.
enum PadelWorkout {
    static var configuration: HKWorkoutConfiguration {
        let configuration = HKWorkoutConfiguration()

        // HealthKit has no padel; tennis is the closest estimate of effort.
        // The match therefore appears in Health under "Tennis".
        configuration.activityType = .tennis

        // Indoor keeps the GPS asleep, which nothing here needs and which
        // would cost the battery a second match.
        configuration.locationType = .indoor

        return configuration
    }

    /// Heart rate is deliberately absent: the system writes it, we only read.
    static let typesToShare: Set<HKSampleType> = [
        HKObjectType.workoutType(),
        HKQuantityType(.activeEnergyBurned),
    ]

    /// What the live builder collects on its own.
    static let typesToRead: Set<HKObjectType> = [
        HKQuantityType(.heartRate),
        HKQuantityType(.activeEnergyBurned),
    ]

    /// How long the phone waits for the watch's workout to reach it. Long
    /// enough for a first start, where the watch asks for Health before it
    /// starts the workout.
    static let phoneWaitsForTheWorkout: Duration = .seconds(45)

    /// How long the watch runs a workout that no match arrives for: longer
    /// than the phone waits, so a phone that gave up leaves nothing running.
    static let watchWaitsForTheMatch: Duration = phoneWaitsForTheWorkout * 2
}
