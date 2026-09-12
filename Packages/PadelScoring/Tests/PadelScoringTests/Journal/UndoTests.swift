import Testing

@testable import PadelScoring

@Suite("Undoing the last point")
struct UndoTests {
    /// The strongest check in the ticket: not "undo works on a game
    /// boundary" but "undo cannot go wrong anywhere". The journal below runs
    /// through a game, deuce, a set boundary and a tiebreak, and on every
    /// rally the state before the record is compared with the state after the
    /// undo — serve and outcome included.
    @Test("Undo restores exactly the state that preceded the rally")
    func undoRestoresTheStateExactly() {
        var match = Match(ruleset: .classic(setsToWin: 2, goldenPoint: false), firstServer: .them)

        var sawDeuce = false
        var sawTieBreak = false
        var sawSet = false

        for winner in aMatchThroughEveryBoundary {
            let before = match.state

            match.record(rallyWonBy: winner)
            match.undo()

            #expect(match.state == before)

            match.record(rallyWonBy: winner)

            let state = match.state
            sawDeuce = sawDeuce || state.points.label(for: .us) == "AD"
            sawTieBreak = sawTieBreak || state.games == SideCounts(us: 6, them: 6)
            sawSet = sawSet || state.sets != SideCounts()
        }

        // Otherwise the fixture will one day stop crossing the boundaries
        // while the test stays just as green and keeps promising it does.
        #expect(sawDeuce, "the journal never reached deuce")
        #expect(sawTieBreak, "the journal never reached a tiebreak")
        #expect(sawSet, "the journal never reached the end of a set")
    }

    @Test("Undo works in the match to N points as well")
    func undoWorksInPointsToAsWell() {
        var match = Match(ruleset: .pointsTo(target: 16, serveChangesEvery: 4))
        for winner in [Side.us, .us, .them, .us] { match.record(rallyWonBy: winner) }
        let before = match.state

        match.record(rallyWonBy: .them)
        match.undo()

        #expect(match.state == before)
        #expect(match.state.servingSide == .them)
    }

    // MARK: Boundaries

    @Test("Undo crosses the game boundary and gives the serve back")
    func undoCrossesTheGameBoundary() {
        var match = Match(ruleset: .defaultClassic)
        for _ in 0..<3 { match.record(rallyWonBy: .us) }
        let atFortyLove = match.state

        // The game is won: the points are zeroed, the serve went to the
        // opponents.
        match.record(rallyWonBy: .us)
        #expect(match.state.games == SideCounts(us: 1, them: 0))
        #expect(match.state.servingSide == .them)

        match.undo()

        #expect(match.state == atFortyLove)
        #expect(match.state.points.label(for: .us) == "40")
        #expect(match.state.servingSide == .us)
    }

    @Test("Undo crosses the set boundary")
    func undoCrossesTheSetBoundary() {
        var match = Match(ruleset: .classic(setsToWin: 2, goldenPoint: true))
        for winner in gamesWonBy([.us, .us, .us, .us, .us]) { match.record(rallyWonBy: winner) }
        for _ in 0..<3 { match.record(rallyWonBy: .us) }
        let beforeTheSet = match.state

        match.record(rallyWonBy: .us)
        #expect(match.state.sets == SideCounts(us: 1, them: 0))
        #expect(match.state.games == SideCounts())

        match.undo()

        #expect(match.state == beforeTheSet)
        #expect(match.state.sets == SideCounts())
        #expect(match.state.games == SideCounts(us: 5, them: 0))
    }

    @Test("Undo crosses the tiebreak boundary")
    func undoCrossesTheTieBreakBoundary() {
        var match = Match(ruleset: .classic(setsToWin: 2, goldenPoint: true))
        for winner in toSixAll { match.record(rallyWonBy: winner) }
        for _ in 0..<6 { match.record(rallyWonBy: .us) }
        let inTheTieBreak = match.state

        // The seventh point takes the tiebreak and the set, and zeroes the
        // games.
        match.record(rallyWonBy: .us)
        #expect(match.state.sets == SideCounts(us: 1, them: 0))

        match.undo()

        #expect(match.state == inTheTieBreak)
        #expect(match.state.games == SideCounts(us: 6, them: 6))
        #expect(match.state.points == .count(SideCounts(us: 6, them: 0)))
    }

    // MARK: A finished match

    @Test("Undo brings a finished match back into play")
    func undoBringsAFinishedMatchBack() {
        var match = Match(ruleset: .pointsTo(target: 3, serveChangesEvery: 4))
        for _ in 0..<2 { match.record(rallyWonBy: .us) }
        let beforeTheEnd = match.state

        match.record(rallyWonBy: .us)
        #expect(match.state.outcome == .finished(winner: .us))

        match.undo()

        #expect(match.state == beforeTheEnd)
        #expect(match.state.outcome == .inProgress)

        // And the match accepts rallies again: before the undo, `record` was
        // not writing them.
        match.record(rallyWonBy: .them)
        #expect(match.state.points == .count(SideCounts(us: 2, them: 1)))
    }

    @Test("Undo also brings back a match finished by a set")
    func undoBringsAFinishedClassicMatchBack() {
        var match = Match(ruleset: .defaultClassic)
        for winner in gamesWonBy([.us, .us, .us, .us, .us, .us]) { match.record(rallyWonBy: winner) }
        #expect(match.state.outcome == .finished(winner: .us))

        match.undo()

        #expect(match.state.outcome == .inProgress)
        #expect(match.state.games == SideCounts(us: 5, them: 0))
        #expect(match.state.points.label(for: .us) == "40")
    }

    // MARK: Repeated undo and the empty journal

    @Test("Repeated undo walks the journal back step by step")
    func repeatedUndoWalksTheJournalBack() {
        var match = Match(ruleset: .defaultClassic)
        var states: [MatchState] = []

        for winner in gamesWonBy([.us, .them, .us]) {
            states.append(match.state)
            match.record(rallyWonBy: winner)
        }

        for expected in states.reversed() {
            match.undo()
            #expect(match.state == expected)
        }

        #expect(match.journal.isEmpty)
    }

    @Test("Undo on an empty journal breaks nothing")
    func undoOnAnEmptyJournalIsHarmless() {
        var match = Match(ruleset: .defaultClassic)
        let fresh = match

        for _ in 0..<3 { match.undo() }

        #expect(match == fresh)
        #expect(match.journal.isEmpty)
        #expect(match.state.outcome == .inProgress)

        // And the match is still alive.
        match.record(rallyWonBy: .them)
        #expect(match.state.points.label(for: .them) == "15")
    }

    @Test("Undo reports whether it took a rally back")
    func undoReportsWhetherItTookARallyBack() {
        var match = Match(ruleset: .defaultClassic)
        let onAnEmptyJournal = match.undo()

        match.record(rallyWonBy: .us)
        let onTheOneRally = match.undo()
        let onTheEmptyJournalAgain = match.undo()

        match.record(rallyWonBy: .us)
        match.abandon()
        let onAnAbandonedMatch = match.undo()

        #expect(onAnEmptyJournal == false)
        #expect(onTheOneRally)
        #expect(onTheEmptyJournalAgain == false)
        #expect(onAnAbandonedMatch == false)
    }
}

// MARK: - Building journals

/// The rallies of a match that passes through a game to love, a game through
/// deuce, a set boundary and a tiebreak: each of them a boundary where undo
/// could have lied.
private let aMatchThroughEveryBoundary: [Side] =
    // The first set to 6:6 — no game along the way closes the set.
    gamesWonBy([.us, .them, .us, .them, .us, .them, .us, .them, .us, .them, .us, .them])
    // The tiebreak: 3:3, then four of our points in a row — the set at 7:6.
    + [.us, .them, .us, .them, .us, .them, .us, .us, .us, .us]
    // The second set: an ordinary game, then a game through deuce and
    // advantage.
    + gamesWonBy([.us, .them])
    + [.us, .us, .us, .them, .them, .them, .us, .them, .us, .us]

private let toSixAll = gamesWonBy([.us, .them, .us, .them, .us, .them, .us, .them, .us, .them, .us, .them])

private func gamesWonBy(_ winners: [Side]) -> [Side] {
    winners.flatMap { Array(repeating: $0, count: 4) }
}
