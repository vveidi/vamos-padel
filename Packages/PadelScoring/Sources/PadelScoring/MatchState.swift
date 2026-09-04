/// The match score and its outcome — what the screen shows.
///
/// The value is computed from the ruleset and the rally journal and is nowhere
/// stored alongside them (ADR-0001).
public struct MatchState: Equatable, Sendable {
    /// Points in the current game; in a match to N points, for the whole match.
    public let points: Points

    /// Games in the current set. `nil` where there are no games: a match to N
    /// points is not divided into games, and showing "0 : 0" there would be a
    /// lie.
    public let games: SideCounts?

    /// Sets won, `nil` where there are no sets.
    public let sets: SideCounts?

    /// The side serving the next rally.
    ///
    /// Like the score, computed from the journal, the ruleset and the first
    /// serve rather than stored alongside them: otherwise undoing a rally
    /// (ticket 05) would have to roll it back separately, and one day would
    /// fail to.
    public let servingSide: Side

    public let outcome: MatchOutcome

    /// The score the match will be remembered by.
    ///
    /// In classic scoring that is games — "6 : 4" — and not points: the last
    /// rally of a match ends a game and zeroes them. A match longer than one
    /// set is remembered by sets, otherwise the last set's score would pass
    /// itself off as the score of the whole match.
    ///
    /// The level is chosen by the ruleset, not by what was played: a match
    /// stopped early may have no sets at all, and calling it short merely
    /// because few sets were played would mean passing the current set's score
    /// off as the match's.
    public let finalScore: SideCounts

    /// Internal on purpose: nobody should be able to assemble a state behind
    /// the journal's back, or the score will once again be a value someone
    /// keeps next to the journal (ADR-0001).
    init(
        points: Points = .count(SideCounts()),
        games: SideCounts? = nil,
        sets: SideCounts? = nil,
        finalScore: SideCounts = SideCounts(),
        servingSide: Side = .us,
        outcome: MatchOutcome = .inProgress
    ) {
        self.points = points
        self.games = games
        self.sets = sets
        self.finalScore = finalScore
        self.servingSide = servingSide
        self.outcome = outcome
    }

    /// The same state, but with the outcome of an abandoned match.
    ///
    /// The score stays the one the match was stopped at: being abandoned is
    /// about the outcome, not about the score. Only the match changes the
    /// outcome (it alone knows it was stopped), so the property does not leave
    /// the package.
    var abandoned: MatchState {
        MatchState(
            points: points,
            games: games,
            sets: sets,
            finalScore: finalScore,
            servingSide: servingSide,
            outcome: .abandoned)
    }
}

extension MatchState {
    /// The engine: a pure function from the ruleset, the journal and the first
    /// serve to a state.
    ///
    /// The first serve is ours by default: the start screen is what asks for
    /// it, while tests and previews want a short call more than an extra
    /// argument.
    public init(ruleset: Ruleset, journal: RallyJournal, firstServer: Side = .us) {
        switch ruleset {
        case .pointsTo(let target, let serveChangesEvery):
            self = .pointsTo(
                target: target,
                serveChangesEvery: serveChangesEvery,
                firstServer: firstServer,
                journal: journal)
        case .classic(let setsToWin, let goldenPoint):
            self = .classic(
                setsToWin: setsToWin,
                goldenPoint: goldenPoint,
                firstServer: firstServer,
                journal: journal)
        }
    }

    /// A match to N points: the side that reaches `target` first wins.
    ///
    /// The check comes after a rally, so an empty journal is always an
    /// unfinished match, and any `target` below two behaves like "to one
    /// point": whoever takes the first rally wins. A sensible lower bound on N
    /// is set by the start screen, but even a senseless value must neither
    /// crash the app nor make the match endless. The serve here passes every X
    /// rallies. X comes from outside and is therefore clamped from below: at
    /// zero the serve would not merely "never change" — it would crash the app
    /// on a division by zero.
    private static func pointsTo(
        target: Int, serveChangesEvery: Int, firstServer: Side, journal: RallyJournal
    ) -> MatchState {
        let serveChangesEvery = max(serveChangesEvery, 1)

        var points = SideCounts()

        func state(outcome: MatchOutcome = .inProgress) -> MatchState {
            MatchState(
                points: .count(points),
                finalScore: points,
                servingSide: firstServer.alternating(points.total / serveChangesEvery),
                outcome: outcome)
        }

        for rally in journal.rallies {
            points = points.incrementing(rally.winner)

            if points[rally.winner] >= target {
                return state(outcome: .finished(winner: rally.winner))
            }
        }

        return state()
    }

    /// Classic scoring: points add up into games, games into sets, sets end
    /// the match.
    ///
    /// One fold for all three levels, because a level only goes up on the very
    /// rally that closed the level below: the point that wins a game can, in
    /// the same motion, win the set and with it the match.
    ///
    /// The number of sets comes from outside and is therefore clamped from
    /// below: a match to zero sets can be neither started nor finished.
    private static func classic(
        setsToWin: Int, goldenPoint: Bool, firstServer: Side, journal: RallyJournal
    ) -> MatchState {
        let setsToWin = max(setsToWin, 1)

        // The same question as `Ruleset.isMultiSet`, and the same answer: a
        // match longer than one set is remembered by sets, otherwise the last
        // set's score would pass itself off as the score of the whole match.
        let isMultiSet = setsToWin > 1

        var sets = SideCounts()
        var games = SideCounts()
        var points = SideCounts()
        var isTieBreak = false

        /// Games over the whole match, not over the current set: the serve
        /// moves on game boundaries and never notices the end of a set,
        /// whereas `games` is zeroed along with it.
        var gamesPlayed = 0

        /// The state as of the current step of the fold. Assembled here rather
        /// than at every exit, so that the level of the final score is chosen
        /// once and cannot diverge between the end of the match and its middle.
        func state(outcome: MatchOutcome = .inProgress) -> MatchState {
            MatchState(
                points: isTieBreak ? .count(points) : .game(points),
                games: games,
                sets: sets,
                finalScore: isMultiSet ? sets : games,
                servingSide: firstServer.alternating(gamesPlayed + tieBreakServeChanges),
                outcome: outcome)
        }

        /// Service changes inside the tiebreak. The tiebreak is the one place
        /// where the serve does not move on game boundaries: the first rally is
        /// served by whoever's turn it is, after that it changes every two.
        /// Without this the indicator would lie for all thirteen rallies of the
        /// tiebreak — exactly where people are looking at it.
        var tieBreakServeChanges: Int {
            isTieBreak ? (points.total + 1) / 2 : 0
        }

        for rally in journal.rallies {
            points = points.incrementing(rally.winner)

            let gameWon =
                isTieBreak
                ? tieBreakIsWon(by: rally.winner, points: points)
                : gameIsWon(by: rally.winner, points: points, goldenPoint: goldenPoint)

            guard gameWon else { continue }

            points = SideCounts()
            games = games.incrementing(rally.winner)
            gamesPlayed += 1

            if setIsWon(by: rally.winner, games: games) {
                sets = sets.incrementing(rally.winner)

                if sets[rally.winner] >= setsToWin {
                    // Games are deliberately not zeroed: the score of a
                    // finished match stays the one it finished on.
                    return state(outcome: .finished(winner: rally.winner))
                }

                games = SideCounts()
                isTieBreak = false
            } else {
                isTieBreak = games == SideCounts(us: gamesInSet, them: gamesInSet)
            }
        }

        return state()
    }

    private static let gamesInSet = 6

    private static let tieBreakPoints = 7

    /// The level is taken: a side reached the threshold and is two clear.
    ///
    /// A game, a tiebreak and a set differ only in the threshold, so the rule
    /// is one. All each of them owns is where it departs from that rule.
    private static func isWon(by winner: Side, counts: SideCounts, reaching threshold: Int) -> Bool
    {
        counts[winner] >= threshold && counts[winner] - counts[winner.opposite] >= 2
    }

    /// A game: four points, two clear.
    ///
    /// The golden point reduces the rule to "first to four": before deuce a
    /// fourth point already means a lead of at least two, and at deuce itself
    /// a single rally decides — the one that makes it 4:3.
    private static func gameIsWon(by winner: Side, points: SideCounts, goldenPoint: Bool) -> Bool {
        if goldenPoint { return points[winner] >= Points.pointsInGame }

        return isWon(by: winner, counts: points, reaching: Points.pointsInGame)
    }

    /// A tiebreak: seven points, two clear.
    ///
    /// The golden point does not extend to it: that is a rule of the game, and
    /// a tiebreak is not a game.
    private static func tieBreakIsWon(by winner: Side, points: SideCounts) -> Bool {
        isWon(by: winner, counts: points, reaching: tieBreakPoints)
    }

    /// A set: six games, two clear — and, after a tiebreak, 7:6, which does
    /// not fit a two-game lead and is therefore named separately. There is no
    /// other way to reach 7:6 in a set.
    private static func setIsWon(by winner: Side, games: SideCounts) -> Bool {
        if games[winner] == gamesInSet + 1 && games[winner.opposite] == gamesInSet { return true }

        return isWon(by: winner, counts: games, reaching: gamesInSet)
    }
}