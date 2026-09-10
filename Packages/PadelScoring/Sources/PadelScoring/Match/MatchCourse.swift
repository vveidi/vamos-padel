/// The course of the score: how the match came about, and not only how it
/// ended.
///
/// Rebuilt from the rally journal by the very engine that counted the match on
/// the watch. That is what the journal is stored for instead of the final
/// score (ADR-0001), and what the engine lives in a shared package for: the
/// same journal read on either device tells the same story.
///
/// The shape follows the ruleset, the way `Points` does. A match to N points
/// is one run of rallies; classic scoring is sets made of games. A single flat
/// list would have to lie about one of the two.
public enum MatchCourse: Equatable, Sendable {
    /// A match to N points: a step for every rally.
    case points([ScoreStep])

    /// Classic scoring: the sets, each made of the games it was played out in.
    case sets([SetCourse])

    /// The course of a journal played by a ruleset.
    ///
    /// The abandoned mark is not asked for and changes nothing here: being
    /// stopped early is a fact about the outcome, not about the way the score
    /// came about.
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

    /// Nothing happened at all — which, in both rulesets, means an empty
    /// journal and nothing else.
    ///
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

/// One step of the course: a side took something — a rally, a game — and this
/// is what the score became.
///
/// The score after the step and not the step's own result, because that is
/// what the course is read for: who was ahead and by how much, at every moment
/// of the match.
public struct ScoreStep: Equatable, Sendable {
    /// The side that took the step.
    public let winner: Side

    /// The score right after it, counted in whatever the step is made of:
    /// points in a match to N points, games inside a set.
    public let score: SideCounts
}

/// A set, as it was played out.
public struct SetCourse: Equatable, Sendable {
    /// The games, in the order they were won.
    public private(set) var games: [ScoreStep] = []

    /// The points of the tiebreak that decided the set, if the set went to
    /// 6:6.
    ///
    /// Kept apart from the games rather than as a game with a strange score:
    /// the tiebreak is the one game whose points are worth reading afterwards,
    /// and "7 : 6" says nothing about how the thirteenth game went.
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
