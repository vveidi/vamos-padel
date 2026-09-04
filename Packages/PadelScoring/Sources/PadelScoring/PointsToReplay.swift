/// A match to N points walked over a journal: the side that reaches `target`
/// first wins.
///
/// The same walk with two readers as in classic scoring — the score screen
/// asks it for the state, the match card for the course — except that here
/// there is nothing to fold: a step of the course is a rally, and the score is
/// the rallies counted up.
struct PointsToReplay {
    /// The score after every rally, up to and including the one that won the
    /// match.
    private(set) var steps: [ScoreStep] = []

    /// The side that won the match, if it is over.
    private(set) var winner: Side?

    /// How many points pass before the serve changes hands. X comes from
    /// outside and is therefore clamped from below: at zero the serve would
    /// not merely "never change" — it would crash the app on a division by
    /// zero.
    private let serveChangesEvery: Int

    init(target: Int, serveChangesEvery: Int, journal: RallyJournal) {
        self.serveChangesEvery = max(serveChangesEvery, 1)

        for rally in journal.rallies {
            let score = points.incrementing(rally.winner)

            steps.append(ScoreStep(winner: rally.winner, score: score))

            // The check comes after a rally, so an empty journal is always an
            // unfinished match, and any target below two behaves like "to one
            // point": whoever takes the first rally wins. A sensible lower
            // bound on N is set by the start screen, but even a senseless
            // value must neither crash the app nor make the match endless.
            if score[rally.winner] >= target {
                winner = rally.winner
                return
            }
        }
    }

    /// The points each side has taken — over the whole match: it is not
    /// divided into games.
    var points: SideCounts { steps.last?.score ?? SideCounts() }

    var outcome: MatchOutcome { MatchOutcome(winner: winner) }

    /// How many times the serve has changed hands: every X rallies, counted
    /// from the first server.
    var serveChanges: Int { points.total / serveChangesEvery }
}
