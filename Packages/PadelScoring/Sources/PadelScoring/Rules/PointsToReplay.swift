struct PointsToReplay {
    /// The score after every rally, up to and including the one that won the
    /// match.
    private(set) var steps: [ScoreStep] = []

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
            // point": whoever takes the first rally wins.
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

    var servingHalf: ServingHalf { .alternating(points.total % serveChangesEvery) }
}
