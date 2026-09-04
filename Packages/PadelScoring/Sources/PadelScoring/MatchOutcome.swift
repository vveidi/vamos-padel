/// How the match ended.
///
/// Three outcomes rather than "over or not": an abandoned match is not a win,
/// not a loss, and not a game still going. Without an outcome of its own, a
/// match left at 5:2 cannot be told apart from a lost one, and that difference
/// is gone for good — the rally journal knows nothing about it.
public enum MatchOutcome: Equatable, Sendable {
    case inProgress

    case finished(winner: Side)

    /// A match stopped before the ruleset declared it over.
    case abandoned

    /// The match has ended — played out or stopped early, it does not matter.
    ///
    /// What gets asked when deciding whether to accept more rallies and
    /// whether there is anything left to continue. The winner will not do for
    /// that: an abandoned match has none, and yet play in it has ended.
    public var isOver: Bool {
        self != .inProgress
    }

    /// The side that won the match, if it was won.
    ///
    /// An abandoned match has no winner — that is the whole point of the mark:
    /// it counts as neither a win nor a loss.
    public var winner: Side? {
        switch self {
        case .inProgress, .abandoned: nil
        case .finished(let winner): winner
        }
    }
}
