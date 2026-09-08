/// The half of the court a serve is played from: right or left of the center
/// line, **as the server sees it, facing the net**.
///
/// The frame is the server's own and nothing else. It is the only frame the
/// value is stable in — a pair keeps its right half when the pairs change ends
/// — and the frame padel's rules are written in.
///
/// A screen that draws the court from one end therefore mirrors one of the two
/// zones: the pair facing us serves from *their* right, which is at screen
/// left. That mirror belongs to the view and must not be worked into this
/// type, or a serve will stop reading as the diagonal it is.
public enum ServingHalf: Sendable {
    case right
    case left
}

extension ServingHalf {
    /// The half a serve comes from after `rallies` have been played in the
    /// game — or in whatever stands in for one: a tiebreak, a service turn.
    ///
    /// The first rally of the game comes from the right and the half changes
    /// with every rally after it, so all of it is the parity of the rallies
    /// played. Which is why the serve and the half can move on rhythms of
    /// their own inside a tiebreak without either one having to know about the
    /// other.
    static func alternating(_ rallies: Int) -> ServingHalf {
        rallies.isMultiple(of: 2) ? .right : .left
    }
}
