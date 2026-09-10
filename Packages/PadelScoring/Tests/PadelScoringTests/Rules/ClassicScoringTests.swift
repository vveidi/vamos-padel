import Testing

@testable import PadelScoring

@Suite("Match state: classic scoring")
struct ClassicScoringTests {
    // MARK: The game

    @Test("A game's points are named 15, 30 and 40")
    func gamePointsAreNamedTheClassicWay() {
        let ladder = ["0", "15", "30", "40"]

        for (won, name) in ladder.enumerated() {
            let state = classicState(rallies(.us, won))

            #expect(state.points.label(for: .us) == name)
            #expect(state.points.label(for: .them) == "0")
            #expect(state.outcome == .inProgress)
        }
    }

    @Test("A fourth point two clear wins the game")
    func fourthPointWinsTheGame() {
        let state = classicState(rallies(.us, 4), goldenPoint: false)

        #expect(state.games == SideCounts(us: 1, them: 0))
        #expect(state.points == .game(SideCounts()))
    }

    @Test("A game won against resistance counts too")
    func aGameWonAgainstResistanceCounts() {
        let state = classicState([.us, .them, .us, .them, .us, .us], goldenPoint: false)

        #expect(state.games == SideCounts(us: 1, them: 0))
    }

    // MARK: Deuce

    @Test("Without the golden point, deuce runs on until two clear")
    func withoutGoldenPointDeuceRunsUntilTwoClear() {
        let deuce = rallies(.us, 3) + rallies(.them, 3)

        // The advantage is ours: the game is not won yet.
        let advantage = classicState(deuce + [.us], goldenPoint: false)
        #expect(advantage.points.label(for: .us) == "AD")
        #expect(advantage.points.label(for: .them) == "40")
        #expect(advantage.games == SideCounts())

        // The opponents pulled it back — deuce again, not a game.
        let backToDeuce = classicState(deuce + [.us, .them], goldenPoint: false)
        #expect(backToDeuce.points.label(for: .us) == "40")
        #expect(backToDeuce.points.label(for: .them) == "40")
        #expect(backToDeuce.games == SideCounts())

        // Two in a row after deuce is a game.
        let won = classicState(deuce + [.us, .us], goldenPoint: false)
        #expect(won.games == SideCounts(us: 1, them: 0))
    }

    @Test("With the golden point, deuce is settled by a single rally")
    func withGoldenPointDeuceIsDecidedByOneRally() {
        let deuce = rallies(.us, 3) + rallies(.them, 3)

        #expect(classicState(deuce, goldenPoint: true).games == SideCounts())
        #expect(classicState(deuce + [.them], goldenPoint: true).games == SideCounts(us: 0, them: 1))
    }

    @Test("The golden point does not stop a game being won before deuce")
    func goldenPointLeavesTheOrdinaryGameAlone() {
        let state = classicState(rallies(.us, 3) + [.them, .us], goldenPoint: true)

        #expect(state.games == SideCounts(us: 1, them: 0))
    }

    // MARK: The set

    @Test("A set is won by six games two clear, and zeroes them")
    func aSetIsWonBySixGamesTwoClear() {
        let state = classicState(gamesWonBy([.us, .us, .us, .us, .us, .us]), setsToWin: 2)

        #expect(state.sets == SideCounts(us: 1, them: 0))
        #expect(state.games == SideCounts())
        #expect(state.outcome == .inProgress)
    }

    @Test("At 6:5 the set is not won yet; at 7:5 it is")
    func fiveGamesBehindIsNotYetASet() {
        let toFiveAll = gamesWonBy([.us, .them, .us, .them, .us, .them, .us, .them, .us, .them])

        let sixFive = classicState(toFiveAll + gamesWonBy([.us]), setsToWin: 2)
        #expect(sixFive.sets == SideCounts())
        #expect(sixFive.games == SideCounts(us: 6, them: 5))

        let sevenFive = classicState(toFiveAll + gamesWonBy([.us, .us]), setsToWin: 2)
        #expect(sevenFive.sets == SideCounts(us: 1, them: 0))
    }

    // MARK: The tiebreak

    @Test("At 6:6 a tiebreak begins: points are counted as numbers again")
    func sixAllStartsATieBreak() {
        let state = classicState(toSixAll + rallies(.us, 3))

        #expect(state.games == SideCounts(us: 6, them: 6))
        #expect(state.points == .count(SideCounts(us: 3, them: 0)))
        #expect(state.points.label(for: .us) == "3")
    }

    @Test("A tiebreak is won by seven points two clear, the set at 7:6")
    func aTieBreakIsWonBySevenTwoClear() {
        let sixPoints = classicState(toSixAll + rallies(.us, 6), setsToWin: 2)
        #expect(sixPoints.sets == SideCounts())

        // A one-set match: the games are not zeroed for a next set, and the
        // score the tiebreak ended the set on is visible in full.
        let state = classicState(toSixAll + rallies(.us, 7))

        #expect(state.games == SideCounts(us: 7, them: 6))
        #expect(state.sets == SideCounts(us: 1, them: 0))
        #expect(state.outcome == .finished(winner: .us))
        #expect(state.finalScore == SideCounts(us: 7, them: 6))
    }

    @Test("At 6:6 in a tiebreak play runs on until two clear")
    func aTieBreakAtSixAllRunsOn() {
        let tieBreakDeuce = toSixAll + rallies(.us, 6) + rallies(.them, 6)

        let sevenSix = classicState(tieBreakDeuce + [.us], setsToWin: 2)
        #expect(sevenSix.sets == SideCounts())
        #expect(sevenSix.points == .count(SideCounts(us: 7, them: 6)))

        let nineSeven = classicState(tieBreakDeuce + [.us, .us], setsToWin: 2)
        #expect(nineSeven.sets == SideCounts(us: 1, them: 0))
    }

    /// The golden point is a rule of the game, and a tiebreak is not a game.
    @Test("The golden point does not shorten a tiebreak")
    func goldenPointDoesNotShortenATieBreak() {
        let atSixAll = toSixAll + rallies(.us, 6) + rallies(.them, 6)

        #expect(classicState(atSixAll + [.us], goldenPoint: true, setsToWin: 2).sets == SideCounts())
    }

    @Test("A match ended by a tiebreak does not pass it off as a game")
    func aMatchEndedByATieBreakDoesNotClaimAGame() {
        let state = classicState(toSixAll + rallies(.us, 7))

        #expect(state.points == .count(SideCounts()))
    }

    // MARK: The end of the match

    @Test("By default the match ends on the very first set won")
    func oneSetFinishesTheMatchByDefault() {
        let state = classicState(gamesWonBy([.them, .them, .them, .them, .them, .them]))

        #expect(state.outcome == .finished(winner: .them))
        #expect(state.sets == SideCounts(us: 0, them: 1))
    }

    @Test("A match to two sets outlives its first set")
    func aTwoSetMatchOutlivesItsFirstSet() {
        let firstSet = gamesWonBy([.us, .us, .us, .us, .us, .us])

        #expect(classicState(firstSet, setsToWin: 2).outcome == .inProgress)
        #expect(classicState(firstSet + firstSet, setsToWin: 2).outcome == .finished(winner: .us))
    }

    @Test("Rallies after the finish no longer change the score")
    func ralliesAfterTheFinishDoNotCount() {
        let set = gamesWonBy([.us, .us, .us, .us, .us, .us])
        let finished = classicState(set)

        #expect(classicState(set + rallies(.them, 9)) == finished)
    }

    /// The number of sets comes from the start screen (ticket 06) and may turn
    /// out to be senseless; a match that can never be finished is not the way
    /// to report that.
    @Test("A set count below one behaves like a single set", arguments: [0, -2])
    func setsBelowOneBehaveLikeOne(setsToWin: Int) {
        let state = classicState(gamesWonBy([.us, .us, .us, .us, .us, .us]), setsToWin: setsToWin)

        #expect(state.outcome == .finished(winner: .us))
    }

    // MARK: The final score

    @Test("A finished match is remembered by its games, not by its points")
    func aFinishedMatchIsRememberedByItsGames() {
        let state = classicState(gamesWonBy([.us, .them, .us, .them, .us, .us, .us, .us]))

        #expect(state.finalScore == SideCounts(us: 6, them: 2))
    }

    @Test("A multi-set match is remembered by its sets")
    func aLongerMatchIsRememberedByItsSets() {
        let ourSet = gamesWonBy([.us, .us, .us, .us, .us, .us])
        let theirSet = gamesWonBy([.them, .them, .them, .them, .them, .them])

        let state = classicState(theirSet + ourSet + ourSet, setsToWin: 2)

        #expect(state.outcome == .finished(winner: .us))
        #expect(state.finalScore == SideCounts(us: 2, them: 1))
    }

    /// An abandoned match will arrive here with one set played, or with none
    /// at all. Choosing the level by how much was played would mean passing
    /// the current set's score off as the score of the whole match.
    @Test("An unfinished match to two sets is still remembered by sets")
    func anUnfinishedLongMatchIsStillRememberedBySets() {
        let oneSetIn = gamesWonBy([.us, .us, .us, .us, .us, .us]) + gamesWonBy([.them, .them])

        let state = classicState(oneSetIn, setsToWin: 2)

        #expect(state.outcome == .inProgress)
        #expect(state.games == SideCounts(us: 0, them: 2))
        #expect(state.finalScore == SideCounts(us: 1, them: 0))
    }

    @Test("A match to one set is remembered by games even before it ends")
    func anUnfinishedShortMatchIsRememberedByGames() {
        let state = classicState(gamesWonBy([.us, .us, .them]))

        #expect(state.finalScore == SideCounts(us: 2, them: 1))
    }

    // MARK: Shared with the engine

    @Test("The same journal always yields the same state")
    func theSameJournalAlwaysScoresTheSame() {
        let played = gamesWonBy([.us, .them, .us]) + rallies(.them, 2)

        var replayed = RallyJournal()
        for side in played { replayed.append(wonBy: side) }

        #expect(MatchState(ruleset: .defaultClassic, journal: journal(played)) == MatchState(ruleset: .defaultClassic, journal: replayed))
    }

    @Test("Before the first rally the score is nil and the match is on")
    func anEmptyJournalScoresNothing() {
        let state = classicState([])

        #expect(state.points == .game(SideCounts()))
        #expect(state.games == SideCounts())
        #expect(state.sets == SideCounts())
        #expect(state.outcome == .inProgress)
    }
}

// MARK: - Building journals

/// The rallies that bring the games to 6:6. Every game here is won to love:
/// the road to 6:6 does not matter in these tests, what starts after it does.
private let toSixAll = gamesWonBy([.us, .them, .us, .them, .us, .them, .us, .them, .us, .them, .us, .them])

/// The state of a classic match, given the listed rally winners.
private func classicState(
    _ winners: [Side], goldenPoint: Bool = true, setsToWin: Int = 1
) -> MatchState {
    MatchState(
        ruleset: .classic(setsToWin: setsToWin, goldenPoint: goldenPoint),
        journal: journal(winners))
}

private func journal(_ winners: [Side]) -> RallyJournal {
    RallyJournal(winners.map(Rally.init(wonBy:)))
}

/// `count` rallies in a row, won by one side.
private func rallies(_ side: Side, _ count: Int) -> [Side] {
    Array(repeating: side, count: count)
}

/// The rallies by which the listed sides each win a game to love — four
/// points in a row. A game to love is shorter than any other, which is why the
/// long journals are built out of it.
private func gamesWonBy(_ winners: [Side]) -> [Side] {
    winners.flatMap { rallies($0, 4) }
}
