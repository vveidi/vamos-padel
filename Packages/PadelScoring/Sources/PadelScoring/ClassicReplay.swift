/// Classic scoring walked over a journal: points add up into games, games into
/// sets, sets end the match.
///
/// One walk with two readers — `MatchState` asks it for the score on screen,
/// `MatchCourse` for the course the match card shows. Written down once so
/// that the two cannot start telling different stories about one journal:
/// a course that disagreed with the score would be worse than no course at
/// all.
///
/// One fold for all three levels, because a level only goes up on the very
/// rally that closed the level below: the point that wins a game can, in the
/// same motion, win the set and with it the match.
struct ClassicReplay {
    /// The sets, in order. The last of them is the set the match stands in,
    /// and it is empty until its first game is won.
    ///
    /// A finished match is the exception: no set is opened after the one it
    /// was won by, so the score of a finished match stays the one it finished
    /// on.
    private(set) var sets = [SetCourse()]

    /// The points of the game in progress.
    private(set) var points = SideCounts()

    /// Whether the game in progress is a tiebreak. The points are then counted
    /// rather than named 15/30/40, and won by a different rule.
    private(set) var isTieBreak = false

    /// The side that won the match, if it is over.
    private(set) var winner: Side?

    /// Games over the whole match, not over the current set: the serve moves
    /// on game boundaries and never notices the end of a set, whereas a set's
    /// games start again from zero.
    private var gamesPlayed = 0

    /// The number of sets comes from outside and is therefore clamped from
    /// below: a match to zero sets could be neither started nor finished.
    init(setsToWin: Int, goldenPoint: Bool, journal: RallyJournal) {
        let setsToWin = max(setsToWin, 1)

        for rally in journal.rallies {
            points = points.incrementing(rally.winner)

            let gameWon =
                isTieBreak
                ? Self.tieBreakIsWon(by: rally.winner, points: points)
                : Self.gameIsWon(by: rally.winner, points: points, goldenPoint: goldenPoint)

            guard gameWon else { continue }

            closeGame(wonBy: rally.winner)

            guard Self.setIsWon(by: rally.winner, games: games) else {
                isTieBreak = games == SideCounts(us: Self.gamesInSet, them: Self.gamesInSet)
                continue
            }

            sets[sets.endIndex - 1].close(wonBy: rally.winner)

            if setsWon[rally.winner] >= setsToWin {
                winner = rally.winner
                return
            }

            sets.append(SetCourse())
            isTieBreak = false
        }
    }

    /// The games of the set the match stands in.
    var games: SideCounts { sets[sets.endIndex - 1].score }

    /// The sets each side has taken. Counted off the sets played rather than
    /// kept as a third counter alongside them, for the same reason the score
    /// is not kept alongside the journal (ADR-0001).
    var setsWon: SideCounts {
        sets.reduce(into: SideCounts()) { counts, set in
            guard let winner = set.winner else { return }

            counts = counts.incrementing(winner)
        }
    }

    var outcome: MatchOutcome { MatchOutcome(winner: winner) }

    /// The sets that were played in — `sets` without the one the walk stands
    /// in when nothing has happened there yet.
    ///
    /// Between a set being taken and the first rally of the next, and before
    /// the first rally of all, the walk already stands in a set nothing has
    /// happened in. That is not a set that was played, and drawing an empty
    /// one would be drawing a set that never started.
    ///
    /// One rally is enough to make it one, though — and the rally need not have
    /// finished a game. A match stopped two rallies into the second set was
    /// stopped in the second set, and a course that dropped it would hang
    /// those rallies off the first: a set that was played out to its end.
    var setsPlayed: [SetCourse] {
        guard sets.last?.games.isEmpty == true, points == SideCounts() else { return sets }

        return Array(sets.dropLast())
    }

    /// How many times the serve has changed hands.
    ///
    /// On game boundaries — and, inside a tiebreak, every two points on top of
    /// that. The tiebreak is the one place where the serve does not move on
    /// game boundaries: its first rally is served by whoever's turn it is,
    /// after that it changes every two. Without this the indicator would lie
    /// for all thirteen rallies of the tiebreak — exactly where people are
    /// looking at it.
    var serveChanges: Int {
        gamesPlayed + (isTieBreak ? (points.total + 1) / 2 : 0)
    }

    /// Writes the game down in the set the match stands in and starts the next
    /// one. The tiebreak's points go into the set on the way past: this is the
    /// last moment they exist, and afterwards a 7:6 set says nothing about how
    /// its thirteenth game went.
    private mutating func closeGame(wonBy winner: Side) {
        sets[sets.endIndex - 1].append(
            gameWonBy: winner, tieBreak: isTieBreak ? points : nil)

        points = SideCounts()
        gamesPlayed += 1
    }

    private static let gamesInSet = 6

    private static let tieBreakPoints = 7

    /// The level is taken: a side reached the threshold and is two clear.
    ///
    /// A game, a tiebreak and a set differ only in the threshold, so the rule
    /// is one. All each of them owns is where it departs from that rule.
    private static func isWon(by winner: Side, counts: SideCounts, reaching threshold: Int) -> Bool {
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
