/// How a touch on the score screen becomes a rally.
enum TapMode: String {
    /// One tap anywhere awards the rally to us, two to the opponents; where the
    /// finger lands is ignored.
    case multiTap = "multi-tap"

    /// The half that is hit is the side that scores.
    case tapZones = "tap-zones"
}
