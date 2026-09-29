struct ClassicReplay {
    /// The sets, in order. The last of them is the set the match stands in,
    /// and it is empty until its first game is won.
    private(set) var sets = [SetCourse()]

    /// The points of the game in progress.
    private(set) var points = SideCounts()

    private(set) var isTieBreak = false

    private(set) var winner: Side?

    /// Games over the whole match, not over the current set: the serve moves
    /// on game boundaries and never notices the end of a set, whereas a set's
    /// games start again from zero.
    private var gamesPlayed = 0

    private let goldenPoint: Bool

    /// The number of sets comes from outside and is therefore clamped from
    /// below: a match to zero sets could be neither started nor finished.
    init(setsToWin: Int, goldenPoint: Bool, journal: RallyJournal) {
        let setsToWin = max(setsToWin, 1)
        self.goldenPoint = goldenPoint

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

    var setsWon: SideCounts {
        sets.reduce(into: SideCounts()) { counts, set in
            guard let winner = set.winner else { return }

            counts = counts.incrementing(winner)
        }
    }

    var outcome: MatchOutcome { MatchOutcome(winner: winner) }

    /// The sets that were played in — `sets` without the one the walk stands
    /// in when nothing has happened there yet.
    var setsPlayed: [SetCourse] {
        guard sets.last?.games.isEmpty == true, points == SideCounts() else { return sets }

        return Array(sets.dropLast())
    }

    /// On game boundaries — and, inside a tiebreak, every two points on top of
    /// that. The tiebreak is the one place where the serve does not move on
    /// game boundaries: its first rally is served by whoever's turn it is,
    /// after that it changes every two.
    var serveChanges: Int {
        gamesPlayed + (isTieBreak ? (points.total + 1) / 2 : 0)
    }

    /// `nil` on a golden point, where the receiving pair picks the side and
    /// the app is never told which.
    var servingHalf: ServingHalf? {
        isGoldenPoint ? nil : .alternating(points.total)
    }

    private var isGoldenPoint: Bool {
        goldenPoint && !isTieBreak
            && points == SideCounts(us: Points.deuce, them: Points.deuce)
    }

    /// The tiebreak's points go into the set on the way past: this is the last
    /// moment they exist, and afterwards a 7:6 set says nothing about how its
    /// thirteenth game went.
    private mutating func closeGame(wonBy winner: Side) {
        sets[sets.endIndex - 1].append(
            gameWonBy: winner, tieBreak: isTieBreak ? points : nil)

        points = SideCounts()
        gamesPlayed += 1
    }

    private static let gamesInSet = 6

    private static let tieBreakPoints = 7

    private static func isWon(by winner: Side, counts: SideCounts, reaching threshold: Int) -> Bool {
        counts[winner] >= threshold && counts[winner] - counts[winner.opposite] >= 2
    }

    /// The golden point reduces the rule to "first to four": before deuce a
    /// fourth point already means a lead of at least two, and at deuce itself
    /// a single rally decides — the one that makes it 4:3.
    private static func gameIsWon(by winner: Side, points: SideCounts, goldenPoint: Bool) -> Bool {
        if goldenPoint { return points[winner] >= Points.pointsInGame }

        return isWon(by: winner, counts: points, reaching: Points.pointsInGame)
    }

    private static func tieBreakIsWon(by winner: Side, points: SideCounts) -> Bool {
        isWon(by: winner, counts: points, reaching: tieBreakPoints)
    }

    /// After a tiebreak a set ends 7:6, which does not fit a two-game lead and
    /// is therefore named separately. There is no other way to reach 7:6 in a
    /// set.
    private static func setIsWon(by winner: Side, games: SideCounts) -> Bool {
        if games[winner] == gamesInSet + 1 && games[winner.opposite] == gamesInSet { return true }

        return isWon(by: winner, counts: games, reaching: gamesInSet)
    }
}
