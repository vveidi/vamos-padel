import Testing

@testable import PadelScoring

@Suite("Матч")
struct MatchTests {
    @Test("Новый матч начинается с пустого журнала и нулевого счёта")
    func newMatchStartsEmpty() {
        let match = Match(ruleset: .defaultPointsTo)

        #expect(match.journal.isEmpty)
        #expect(match.state == MatchState())
    }

    @Test("Записанный розыгрыш попадает в журнал и увеличивает счёт")
    func recordingARallyScores() {
        var match = Match(ruleset: .defaultPointsTo)

        match.record(rallyWonBy: .them)

        #expect(match.journal.rallies == [Rally(wonBy: .them)])
        #expect(match.state.points == .count(SideCounts(us: 0, them: 1)))
    }

    @Test("После окончания матча розыгрыши не записываются")
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
}
