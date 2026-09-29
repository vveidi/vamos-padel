import Testing

@testable import PadelScoring

@Suite("Match outcome")
struct MatchOutcomeTests {
    @Test("A match in progress has no winner")
    func matchInProgressHasNoWinner() {
        #expect(MatchOutcome.inProgress.winner == nil)
        #expect(MatchOutcome.inProgress.isOver == false)
    }

    @Test("A finished match has a winning side")
    func finishedMatchHasWinner() {
        let outcome = MatchOutcome.finished(winner: .them)

        #expect(outcome.winner == .them)
        #expect(outcome.isOver)
    }

    @Test("An abandoned match is over, won by neither side")
    func abandonedMatchIsOverWithoutAWinner() {
        let outcome = MatchOutcome.abandoned

        #expect(outcome.winner == nil)
        #expect(outcome.isOver)
    }
}
