public enum MatchCourse: Equatable, Sendable {
    case points([ScoreStep])

    case sets([SetCourse])

    public init(ruleset: Ruleset, journal: RallyJournal) {
        switch ruleset {
        case .pointsTo(let target, let serveChangesEvery):
            self = .points(
                PointsToReplay(
                    target: target, serveChangesEvery: serveChangesEvery, journal: journal
                ).steps)
        case .classic(let setsToWin, let goldenPoint):
            self = .sets(
                ClassicReplay(
                    setsToWin: setsToWin, goldenPoint: goldenPoint, journal: journal
                ).setsPlayed)
        }
    }

    /// A classic match can have steps of no kind whatsoever and still not be
    /// empty: the set the rallies were played in is part of the course from
    /// its first rally, even when none of them carried a game to its end.
    public var isEmpty: Bool {
        switch self {
        case .points(let steps): steps.isEmpty
        case .sets(let sets): sets.isEmpty
        }
    }
}

public struct ScoreStep: Equatable, Sendable {
    public let winner: Side

    /// The score right after it, counted in whatever the step is made of:
    /// points in a match to N points, games inside a set.
    public let score: SideCounts
}

public struct SetCourse: Equatable, Sendable {
    /// The games, in the order they were won.
    public private(set) var games: [ScoreStep] = []

    /// The points of the tiebreak that decided the set, if the set went to
    /// 6:6.
    public private(set) var tieBreak: SideCounts?

    /// The side that took the set. `nil` for the set the match was left
    /// standing in — the one in progress, or the one it was abandoned in.
    public private(set) var winner: Side?

    /// The set's score in games.
    public var score: SideCounts { games.last?.score ?? SideCounts() }

    /// Assembled by the walk alone: a set built by hand is a score kept beside
    /// the journal (ADR-0001).
    init() {}

    mutating func append(gameWonBy winner: Side, tieBreak: SideCounts?) {
        games.append(ScoreStep(winner: winner, score: score.incrementing(winner)))

        if let tieBreak { self.tieBreak = tieBreak }
    }

    mutating func close(wonBy winner: Side) {
        self.winner = winner
    }
}
