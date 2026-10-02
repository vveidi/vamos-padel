import PadelScoring

/// What the remote asks the scorer to do to the match; the scorer alone decides.
/// - Note: A `base` is the number of rallies the remote's screen showed when
///   the intent was formed, and is never negative.
public enum MatchIntent: Equatable, Sendable {
    case start(ruleset: Ruleset, firstServer: Side)
    case rally(wonBy: Side, base: Int)
    case undo(base: Int)
    case end(base: Int)
}
