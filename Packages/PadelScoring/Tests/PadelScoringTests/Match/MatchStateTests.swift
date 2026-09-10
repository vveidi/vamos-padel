import Testing

@testable import PadelScoring

@Suite("Match state: the match to N points")
struct MatchStateTests {
    @Test("Before the first rally the score is nil and the match is on")
    func emptyJournalScoresNothing() {
        let state = MatchState(ruleset: .defaultPointsTo, journal: RallyJournal())

        #expect(state.points == .count(SideCounts()))
        #expect(state.outcome == .inProgress)
    }

    @Test("Every rally adds a point to the side that won it")
    func everyRallyScoresForItsWinner() {
        let state = MatchState(ruleset: .defaultPointsTo, journal: journal(.us, .them, .us))

        #expect(state.points == .count(SideCounts(us: 2, them: 1)))
        #expect(state.outcome == .inProgress)
    }

    @Test("The match ends as soon as a side reaches N points")
    func matchFinishesAtTargetPoints() {
        let state = MatchState(
            ruleset: .pointsTo(target: 3, serveChangesEvery: 4),
            journal: journal(.us, .them, .us, .us))

        #expect(state.points == .count(SideCounts(us: 3, them: 1)))
        #expect(state.outcome == .finished(winner: .us))
    }

    @Test("Rallies after the finish no longer change the score")
    func ralliesAfterTheFinishDoNotCount() {
        let state = MatchState(
            ruleset: .pointsTo(target: 2, serveChangesEvery: 4),
            journal: journal(.us, .us, .them, .them, .them))

        #expect(state.points == .count(SideCounts(us: 2, them: 0)))
        #expect(state.outcome == .finished(winner: .us))
    }

    @Test("With N = 1 the match ends on the very first rally")
    func targetOfOnePointEndsWithTheFirstRally() {
        let ruleset = Ruleset.pointsTo(target: 1, serveChangesEvery: 4)

        #expect(MatchState(ruleset: ruleset, journal: RallyJournal()).outcome == .inProgress)
        #expect(MatchState(ruleset: ruleset, journal: journal(.them)).outcome == .finished(winner: .them))
    }

    /// An N below one is senseless, but it comes from outside (ticket 06), so
    /// the engine has to behave predictably: neither crash the app nor leave
    /// behind a match that can never be finished.
    @Test("An N below one does not break the match but behaves like N = 1", arguments: [0, -3])
    func targetBelowOneBehavesLikeOne(target: Int) {
        let ruleset = Ruleset.pointsTo(target: target, serveChangesEvery: 4)

        #expect(MatchState(ruleset: ruleset, journal: RallyJournal()).outcome == .inProgress)
        #expect(MatchState(ruleset: ruleset, journal: journal(.us, .them)).outcome == .finished(winner: .us))
    }

    @Test("The same journal always yields the same state")
    func theSameJournalAlwaysScoresTheSame() {
        let ruleset = Ruleset.pointsTo(target: 4, serveChangesEvery: 4)
        let played = journal(.us, .them, .us, .them, .us)

        // A separately built journal with the same sequence: the state must
        // not depend on anything but the sequence itself.
        var replayed = RallyJournal()
        for rally in played.rallies { replayed.append(wonBy: rally.winner) }

        #expect(MatchState(ruleset: ruleset, journal: played) == MatchState(ruleset: ruleset, journal: replayed))
    }
}

/// A journal in which the listed sides win the rallies in order.
private func journal(_ winners: Side...) -> RallyJournal {
    RallyJournal(winners.map(Rally.init(wonBy:)))
}
