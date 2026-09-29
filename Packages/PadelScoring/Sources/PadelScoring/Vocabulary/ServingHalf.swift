/// The half of the court a serve is played from: right or left of the center
/// line, **as the server sees it, facing the net**.
public enum ServingHalf: Sendable {
    case right
    case left
}

extension ServingHalf {
    /// The half a serve comes from after `rallies` have been played in the
    /// game — or in whatever stands in for one: a tiebreak, a service turn.
    static func alternating(_ rallies: Int) -> ServingHalf {
        rallies.isMultiple(of: 2) ? .right : .left
    }
}
