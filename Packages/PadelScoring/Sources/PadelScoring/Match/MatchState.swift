public struct MatchState: Equatable, Sendable {
    /// Points in the current game; in a match to N points, for the whole match.
    public let points: Points

    /// Games in the current set. `nil` where there are no games: a match to N
    /// points is not divided into games, and showing "0 : 0" there would be a
    /// lie.
    public let games: SideCounts?

    /// Sets won, `nil` where there are no sets.
    public let sets: SideCounts?

    public let servingSide: Side

    /// `nil` is the golden point: the receiving pair chooses the side there
    /// and the app is not told which, so the half is not unset but unknowable.
    public let servingHalf: ServingHalf?

    public let outcome: MatchOutcome

    /// In classic scoring that is games — "6 : 4" — and not points: the last
    /// rally of a match ends a game and zeroes them. A match longer than one
    /// set is remembered by sets, otherwise the last set's score would pass
    /// itself off as the score of the whole match.
    public let finalScore: SideCounts

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
                finalScore: ruleset.isMultiSet ? replay.setsWon : replay.games,
                servingSide: firstServer.alternating(replay.serveChanges),
                servingHalf: replay.servingHalf,
                outcome: replay.outcome)
        }
    }
}
