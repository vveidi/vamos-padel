import Testing

@testable import PadelScoring

@Suite("Исход матча")
struct MatchOutcomeTests {
    @Test("У незавершённого матча нет победителя")
    func matchInProgressHasNoWinner() {
        #expect(MatchOutcome.inProgress.winner == nil)
        #expect(MatchOutcome.inProgress.isFinished == false)
    }

    @Test("У завершённого матча есть выигравшая сторона")
    func finishedMatchHasWinner() {
        let outcome = MatchOutcome.finished(winner: .them)

        #expect(outcome.winner == .them)
        #expect(outcome.isFinished)
    }
}
