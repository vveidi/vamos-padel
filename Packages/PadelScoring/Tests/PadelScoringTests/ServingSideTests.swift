import Testing

@testable import PadelScoring

@Suite("Serving side")
struct ServingSideTests {
    // MARK: The match to N points

    @Test("Before the first rally the named first server serves", arguments: [Side.us, .them])
    func theFirstServerServesTheFirstRally(firstServer: Side) {
        #expect(pointsToState([], firstServer: firstServer).servingSide == firstServer)
    }

    @Test("The serve passes every X rallies and comes back after 2X")
    func serveChangesEveryXRallies() {
        // Who wins the rallies has no bearing on the serve — only how many.
        let winners: [Side] = [.us, .them, .them, .us, .us, .them, .us, .them]

        for played in 0...8 {
            let expected: Side = (played / 4) % 2 == 0 ? .us : .them

            #expect(pointsToState(Array(winners.prefix(played))).servingSide == expected)
        }
    }

    @Test("With X = 1 the serve passes after every rally")
    func serveChangesEveryRallyWhenXIsOne() {
        #expect(pointsToState([], every: 1).servingSide == .us)
        #expect(pointsToState([.them], every: 1).servingSide == .them)
        #expect(pointsToState([.them, .them], every: 1).servingSide == .us)
        #expect(pointsToState([.them, .them, .us], every: 1).servingSide == .them)
    }

    /// X comes from the start screen (ticket 06) and may turn out to be zero;
    /// dividing by it is not the way to report that.
    @Test("An X below one does not crash the match but behaves like X = 1", arguments: [0, -2])
    func serveChangeBelowOneBehavesLikeOne(every: Int) {
        #expect(pointsToState([.us], every: every).servingSide == .them)
    }

    // MARK: Classic scoring

    @Test("In classic scoring the serve passes after every game")
    func serveChangesAfterEveryGame() {
        // Inside a game the serve does not move.
        for played in 0...3 {
            #expect(classicState(rallies(.us, played)).servingSide == .us)
        }

        #expect(classicState(gamesWonBy([.us])).servingSide == .them)
        #expect(classicState(gamesWonBy([.us, .them])).servingSide == .us)
        #expect(classicState(gamesWonBy([.us, .them, .them])).servingSide == .them)
    }

    @Test("The set boundary does not throw the serve off")
    func theSetBoundaryDoesNotDisturbTheServe() {
        // Six games in, the serve is back with us, and a new set changes
        // nothing about that.
        let firstSet = gamesWonBy([.us, .us, .us, .us, .us, .us])

        #expect(classicState(firstSet, setsToWin: 2).servingSide == .us)
        #expect(classicState(firstSet + gamesWonBy([.them]), setsToWin: 2).servingSide == .them)
    }

    @Test("The first server carries into classic scoring too")
    func theFirstServerCarriesIntoClassic() {
        #expect(classicState([], firstServer: .them).servingSide == .them)
        #expect(classicState(gamesWonBy([.us]), firstServer: .them).servingSide == .us)
    }

    // MARK: The tiebreak

    /// The tiebreak is the one place where the serve does not move on game
    /// boundaries: the first rally is served by whoever's turn it is, after
    /// that it changes every two.
    @Test("In a tiebreak the serve passes after one point, then every two")
    func theTieBreakServeChangesAfterOnePointThenEveryTwo() {
        // Twelve games in, it is our turn again.
        let expected: [Side] = [.us, .them, .them, .us, .us, .them, .them, .us, .us]

        // The tiebreak points are split evenly: otherwise it would end before
        // the serve rotation completes a full cycle.
        let traded: [Side] = (0..<expected.count).map { $0.isMultiple(of: 2) ? .us : .them }

        for (played, side) in expected.enumerated() {
            let state = classicState(toSixAll + Array(traded.prefix(played)))

            #expect(state.games == SideCounts(us: 6, them: 6))
            #expect(state.servingSide == side)
        }
    }

    // MARK: Through the match

    @Test("The match reports the serve counting from its own first server")
    func theMatchServesFromItsOwnFirstServer() {
        var match = Match(ruleset: .defaultPointsTo, firstServer: .them)

        #expect(match.state.servingSide == .them)

        for _ in 0..<4 { match.record(rallyWonBy: .us) }

        #expect(match.state.servingSide == .us)
    }
}

// MARK: - Building journals

private let toSixAll = gamesWonBy([.us, .them, .us, .them, .us, .them, .us, .them, .us, .them, .us, .them])

private func pointsToState(
    _ winners: [Side], every: Int = 4, firstServer: Side = .us
) -> MatchState {
    MatchState(
        // The target is deliberately out of reach: this ticket is about the
        // serve, not about the end of the match.
        ruleset: .pointsTo(target: 99, serveChangesEvery: every),
        journal: journal(winners),
        firstServer: firstServer)
}

private func classicState(
    _ winners: [Side], setsToWin: Int = 3, firstServer: Side = .us
) -> MatchState {
    MatchState(
        ruleset: .classic(setsToWin: setsToWin, goldenPoint: true),
        journal: journal(winners),
        firstServer: firstServer)
}

private func journal(_ winners: [Side]) -> RallyJournal {
    RallyJournal(winners.map(Rally.init(wonBy:)))
}

private func rallies(_ side: Side, _ count: Int) -> [Side] {
    Array(repeating: side, count: count)
}

private func gamesWonBy(_ winners: [Side]) -> [Side] {
    winners.flatMap { rallies($0, 4) }
}
