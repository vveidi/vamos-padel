import Testing

@testable import PadelScoring

@Suite("Исход матча")
struct MatchOutcomeTests {
    @Test("У незавершённого матча нет победителя")
    func matchInProgressHasNoWinner() {
        #expect(MatchOutcome.inProgress.winner == nil)
        #expect(MatchOutcome.inProgress.isOver == false)
    }

    @Test("У завершённого матча есть выигравшая сторона")
    func finishedMatchHasWinner() {
        let outcome = MatchOutcome.finished(winner: .them)

        #expect(outcome.winner == .them)
        #expect(outcome.isOver)
    }

    /// Ради этого исход и стал третьим значением: недоигранный матч кончился,
    /// но не в чью-либо пользу.
    @Test("Недоигранный матч кончился, но не выигран ни одной стороной")
    func abandonedMatchIsOverWithoutAWinner() {
        let outcome = MatchOutcome.abandoned

        #expect(outcome.winner == nil)
        #expect(outcome.isOver)
    }
}
