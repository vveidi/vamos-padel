/// One of the two pairs on court.
///
/// In v1 the sides are anonymous: the app knows "our" side and "the
/// opponents", but not who is actually playing.
public enum Side: String, Sendable, CaseIterable {
    case us
    case them

    /// The side across the net.
    public var opposite: Side {
        switch self {
        case .us: .them
        case .them: .us
        }
    }

    /// The side serving after `changes` service changes.
    ///
    /// Computed from parity rather than by stepping through the changes one by
    /// one: the serve moves back and forth, so all that matters is how many
    /// times it changed hands — which makes "who serves on the hundredth
    /// rally" cost exactly as much as "who serves on the first".
    func alternating(_ changes: Int) -> Side {
        changes % 2 == 0 ? self : opposite
    }
}


