import Testing

@testable import PadelScoring

@Suite("Match")
struct MatchTests {
    @Test("A new match starts with an empty journal and a nil score")
    func newMatchStartsEmpty() {
        let match = Match(ruleset: .defaultPointsTo)

        #expect(match.journal.isEmpty)
        #expect(match.state == MatchState())
    }

    @Test("A recorded rally lands in the journal and raises the score")
    func recordingARallyScores() {
        var match = Match(ruleset: .defaultPointsTo)

        match.record(rallyWonBy: .them)

        #expect(match.journal.rallies == [Rally(wonBy: .them)])
        #expect(match.state.points == .count(SideCounts(us: 0, them: 1)))
    }

    @Test("A finished match records no rallies")
    func finishedMatchRecordsNothing() {
        var match = Match(ruleset: .pointsTo(target: 2, serveChangesEvery: 4))
        match.record(rallyWonBy: .us)
        match.record(rallyWonBy: .us)
        let finished = match

        match.record(rallyWonBy: .them)
        match.record(rallyWonBy: .us)

        #expect(match == finished)
        #expect(match.state.outcome == .finished(winner: .us))
    }

    @Test("Recording reports whether the rally was taken")
    func recordingReportsWhetherTheRallyWasTaken() {
        var match = Match(ruleset: .pointsTo(target: 2, serveChangesEvery: 4))

        let first = match.record(rallyWonBy: .us)
        let winning = match.record(rallyWonBy: .us)
        let afterTheEnd = match.record(rallyWonBy: .us)

        #expect(first)
        #expect(winning)
        #expect(afterTheEnd == false)

        var abandoned = Match(ruleset: .defaultPointsTo)
        abandoned.record(rallyWonBy: .us)
        abandoned.abandon()
        let afterStopping = abandoned.record(rallyWonBy: .us)

        #expect(afterStopping == false)
    }

    @Test("A match stopped early is marked abandoned")
    func abandoningMarksTheMatchUnfinished() {
        var match = Match(ruleset: .defaultPointsTo)
        match.record(rallyWonBy: .us)

        match.abandon()

        #expect(match.isAbandoned)
        #expect(match.state.outcome == .abandoned)
        #expect(match.state.outcome.winner == nil)
    }

    @Test("Stopping leaves the journal and the score as they were")
    func abandoningKeepsTheJournalAndTheScore() {
        var match = Match(ruleset: .defaultPointsTo)
        for winner in [Side.us, .us, .them, .us, .them] { match.record(rallyWonBy: winner) }
        let played = match.journal

        match.abandon()

        #expect(match.journal == played)
        #expect(match.state.points == .count(SideCounts(us: 3, them: 2)))
        #expect(match.state.finalScore == SideCounts(us: 3, them: 2))
    }

    @Test("An abandoned match records no rallies")
    func anAbandonedMatchRecordsNothing() {
        var match = Match(ruleset: .defaultPointsTo)
        match.record(rallyWonBy: .us)
        match.abandon()
        let abandoned = match

        match.record(rallyWonBy: .them)

        #expect(match == abandoned)
    }

    @Test("A won match cannot be stopped early")
    func aWonMatchCannotBeAbandoned() {
        var match = Match(ruleset: .pointsTo(target: 2, serveChangesEvery: 4))
        match.record(rallyWonBy: .us)
        match.record(rallyWonBy: .us)

        match.abandon()

        #expect(match.isAbandoned == false)
        #expect(match.state.outcome == .finished(winner: .us))
    }

    @Test("Undo does not resume an abandoned match")
    func undoDoesNotResumeAnAbandonedMatch() {
        var match = Match(ruleset: .defaultPointsTo)
        match.record(rallyWonBy: .us)
        match.abandon()
        let abandoned = match

        match.undo()

        #expect(match == abandoned)
    }

    @Test("A match stopped before the first rally is abandoned at a nil score")
    func abandoningBeforeTheFirstRallyLeavesAnEmptyMatch() {
        var match = Match(ruleset: .defaultClassic)

        match.abandon()

        #expect(match.state.outcome == .abandoned)
        #expect(match.journal.isEmpty)
    }
}
