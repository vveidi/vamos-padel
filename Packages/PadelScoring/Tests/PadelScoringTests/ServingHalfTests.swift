import Testing

@testable import PadelScoring

@Suite("Serving half")
struct ServingHalfTests {
    // MARK: Where a game starts

    @Test("The first rally of a match is served from the right")
    func theMatchOpensFromTheRight() {
        #expect(classicState([]).servingHalf == .right)
        #expect(pointsToState([]).servingHalf == .right)
    }

    /// The case that fails if the half is anchored on the rallies of the whole
    /// match rather than on those of the game: the game below takes five
    /// rallies, so the two answers disagree the moment it ends.
    @Test("The half alternates through a game and starts the next one on the right")
    func theHalfAlternatesWithinAGameAndResetsWithIt() {
        let game: [Side] = [.us, .us, .us, .them, .us]
        let expected: [ServingHalf] = [.right, .left, .right, .left, .right]

        for played in 0..<game.count {
            #expect(classicState(Array(game.prefix(played))).servingHalf == expected[played])
        }

        let afterTheGame = classicState(game)

        #expect(afterTheGame.games == SideCounts(us: 1, them: 0))
        #expect(afterTheGame.servingHalf == .right)
    }

    // MARK: The tiebreak

    /// The one place where the two rhythms are visibly different: the serve
    /// passes after one rally and every two after that, while the half goes on
    /// flipping every single rally. A counter shared between them would look
    /// right everywhere else.
    ///
    /// It is also where the golden point does not reach: 3:3 in a tiebreak —
    /// six rallies played — is an ordinary rally from the right.
    @Test("In a tiebreak the half flips every rally while the serve does not")
    func theTieBreakKeepsTheHalfAlternating() {
        let sides: [Side] = [.us, .them, .them, .us, .us, .them, .them, .us, .us]

        // The points are traded so that the tiebreak lasts the whole rotation.
        let traded: [Side] = (0..<sides.count).map { $0.isMultiple(of: 2) ? .us : .them }

        for (played, side) in sides.enumerated() {
            let state = classicState(toSixAll + Array(traded.prefix(played)))

            #expect(state.games == SideCounts(us: 6, them: 6))
            #expect(state.servingSide == side)
            #expect(state.servingHalf == ServingHalf.alternating(played))
        }
    }

    // MARK: Deuce

    /// The receiving pair picks the side on a golden point, and the app is
    /// never told which.
    @Test("The golden point has no half, and the rally before it does")
    func theGoldenPointHasNoHalf() {
        let toFortyThirty: [Side] = [.us, .us, .us, .them, .them]

        #expect(classicState(toFortyThirty).points.label(for: .us) == "40")
        #expect(classicState(toFortyThirty).servingHalf == .left)

        let atDeuce = classicState(toFortyThirty + [.them])

        #expect(atDeuce.points == .game(SideCounts(us: 3, them: 3)))
        #expect(atDeuce.servingHalf == nil)
    }

    /// Without the golden point, 3:3 is just another rally: the game plays on
    /// for a two-point lead and every one of those rallies has a half.
    @Test("Advantage scoring never leaves the half unknown")
    func advantageScoringAlwaysHasAHalf() {
        let toDeuce: [Side] = [.us, .us, .us, .them, .them, .them]
        var played = toDeuce

        // Deuce, advantage, back to deuce, and on: the game refuses to end.
        for winner in [Side.us, .them, .us, .them] {
            let state = classicState(played, goldenPoint: false)

            #expect(state.servingHalf == ServingHalf.alternating(played.count))
            #expect(state.servingHalf != nil)

            played.append(winner)
        }

        #expect(classicState(toDeuce, goldenPoint: false).servingHalf == .right)
        #expect(classicState(toDeuce + [.us], goldenPoint: false).servingHalf == .left)
    }

    // MARK: The match to N points

    /// With the default X = 4 the service turn and the whole match agree on
    /// the parity, so only an odd X can catch a half anchored on the wrong
    /// one: rally three opens a turn and is served from the right, where the
    /// match's own parity says left.
    @Test("The half is anchored on the service turn, not on the match")
    func theServiceTurnAnchorsTheHalf() {
        let winners: [Side] = [.us, .them, .them, .us, .us, .them]
        let expected: [ServingHalf] = [.right, .left, .right, .right, .left, .right]

        for (played, half) in expected.enumerated() {
            #expect(pointsToState(Array(winners.prefix(played)), every: 3).servingHalf == half)
        }
    }

    /// X reaches the engine from the start screen and may be nonsense; the
    /// half answers it the way the side already does.
    @Test("An X below one behaves like X = 1", arguments: [0, -2])
    func serveChangeBelowOneBehavesLikeOne(every: Int) {
        // Every rally opens a service turn of its own, so every rally is
        // served from the right.
        for played in 0...3 {
            #expect(pointsToState(rallies(.us, played), every: every).servingHalf == .right)
        }
    }

    // MARK: Undo

    /// No code of its own rolls the half back: it is computed from the journal
    /// like the rest of the state, so shortening the journal is all it takes.
    @Test("Undo restores the half across a game boundary and a golden point")
    func undoRestoresTheHalf() {
        var match = Match(ruleset: .defaultClassic)

        for winner in [Side.us, .us, .us, .them, .them, .them, .us] {
            let before = match.state

            match.record(rallyWonBy: winner)
            match.undo()

            #expect(match.state == before)

            match.record(rallyWonBy: winner)
        }

        // The journal above ends on the rally after a golden point, which took
        // the game: the next one opens a game and comes from the right.
        #expect(match.state.games == SideCounts(us: 1, them: 0))
        #expect(match.state.servingHalf == .right)

        match.undo()

        #expect(match.state.servingHalf == nil)
    }
}

// MARK: - Building journals

private let toSixAll = gamesWonBy([.us, .them, .us, .them, .us, .them, .us, .them, .us, .them, .us, .them])

private func classicState(
    _ winners: [Side], goldenPoint: Bool = true
) -> MatchState {
    MatchState(
        // Three sets keep the match alive past everything these cases play
        // out; the half is a live value and says nothing once it is over.
        ruleset: .classic(setsToWin: 3, goldenPoint: goldenPoint),
        journal: journal(winners))
}

private func pointsToState(_ winners: [Side], every: Int = 4) -> MatchState {
    MatchState(
        // The target is deliberately out of reach: this suite is about the
        // half, not about the end of the match.
        ruleset: .pointsTo(target: 99, serveChangesEvery: every),
        journal: journal(winners))
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
