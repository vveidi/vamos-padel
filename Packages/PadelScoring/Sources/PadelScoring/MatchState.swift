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

    /// The half of the court the next rally is served from, in the server's
    /// own frame — see `ServingHalf`, which is also where the warning about
    /// mirroring it on screen lives.
    ///
    /// `nil` is the golden point: the receiving pair chooses the side there
    /// and the app is not told which, so the half is not unset but unknowable.
    /// Computed with the rest of the state, and stored no more than it is
    /// (ADR-0001).
    public let servingHalf: ServingHalf?

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
        servingHalf: ServingHalf? = .right,
        outcome: MatchOutcome = .inProgress
    ) {
        self.points = points
        self.games = games
        self.sets = sets
        self.finalScore = finalScore
        self.servingSide = servingSide
        self.servingHalf = servingHalf
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
            servingHalf: servingHalf,
            outcome: .abandoned)
    }
}

extension MatchState {
    /// The engine: a pure function from the ruleset, the journal and the first
    /// serve to a state.
    ///
    /// The whole of the work is the walk over the journal — one per ruleset,
    /// shared with `MatchCourse` — and all that is left here is to read the
    /// state off it. The score the screen shows and the course the match card
    /// shows are therefore the same computation read twice, not two
    /// computations that agree for now.
    ///
    /// The first serve is ours by default: the start screen is what asks for
    /// it, while tests and previews want a short call more than an extra
    /// argument.
    public init(ruleset: Ruleset, journal: RallyJournal, firstServer: Side = .us) {
        switch ruleset {
        case .pointsTo(let target, let serveChangesEvery):
            let replay = PointsToReplay(
                target: target, serveChangesEvery: serveChangesEvery, journal: journal)

            self.init(
                points: .count(replay.points),
                finalScore: replay.points,
                servingSide: firstServer.alternating(replay.serveChanges),
                servingHalf: replay.servingHalf,
                outcome: replay.outcome)

        case .classic(let setsToWin, let goldenPoint):
            let replay = ClassicReplay(
                setsToWin: setsToWin, goldenPoint: goldenPoint, journal: journal)

            self.init(
                points: replay.isTieBreak ? .count(replay.points) : .game(replay.points),
                games: replay.games,
                sets: replay.setsWon,
                // The level of the final score is the ruleset's to choose and
                // not the walk's: a match stopped early may have no sets at
                // all, and calling it short merely because few sets were
                // played would pass the current set's score off as the
                // match's.
                finalScore: ruleset.isMultiSet ? replay.setsWon : replay.games,
                servingSide: firstServer.alternating(replay.serveChanges),
                servingHalf: replay.servingHalf,
                outcome: replay.outcome)
        }
    }
}
