public enum MatchOutcome: Equatable, Sendable {
    case inProgress

    case finished(winner: Side)

    case abandoned

    /// Both rulesets' walks finish with the same `Side?` in hand and asked the
    /// same question of it; the answer belongs here, next to the cases, rather
    /// than spelled out once per ruleset.
    init(winner: Side?) {
        guard let winner else {
            self = .inProgress

            return
        }

        self = .finished(winner: winner)
    }

    /// The match has ended — played out or stopped early, it does not matter.
    /// The winner will not do for that: an abandoned match has none, and yet
    /// play in it has ended.
    public var isOver: Bool {
        self != .inProgress
    }

    public var winner: Side? {
        switch self {
        case .inProgress, .abandoned: nil
        case .finished(let winner): winner
        }
    }
}
