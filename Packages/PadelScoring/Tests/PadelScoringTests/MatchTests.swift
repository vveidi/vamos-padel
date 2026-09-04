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

    @Test("Прекращённый досрочно матч помечается недоигранным")
    func abandoningMarksTheMatchUnfinished() {
        var match = Match(ruleset: .defaultPointsTo)
        match.record(rallyWonBy: .us)

        match.abandon()

        #expect(match.isAbandoned)
        #expect(match.state.outcome == .abandoned)
        #expect(match.state.outcome.winner == nil)
    }

    /// Час игры не пропадает: прекращение меняет исход, а не сыгранное.
    @Test("Прекращение оставляет журнал и счёт такими, какими они были")
    func abandoningKeepsTheJournalAndTheScore() {
        var match = Match(ruleset: .defaultPointsTo)
        for winner in [Side.us, .us, .them, .us, .them] { match.record(rallyWonBy: winner) }
        let played = match.journal

        match.abandon()

        #expect(match.journal == played)
        #expect(match.state.points == .count(SideCounts(us: 3, them: 2)))
        #expect(match.state.finalScore == SideCounts(us: 3, them: 2))
    }

    @Test("В прекращённом матче розыгрыши не записываются")
    func anAbandonedMatchRecordsNothing() {
        var match = Match(ruleset: .defaultPointsTo)
        match.record(rallyWonBy: .us)
        match.abandon()
        let abandoned = match

        match.record(rallyWonBy: .them)

        #expect(match == abandoned)
    }

    /// Победа уже случилась, и объявлять её недоигранной нечем: набор правил
    /// закончил матч раньше, чем игрок собрался с корта.
    @Test("Выигранный матч прекратить досрочно нельзя")
    func aWonMatchCannotBeAbandoned() {
        var match = Match(ruleset: .pointsTo(target: 2, serveChangesEvery: 4))
        match.record(rallyWonBy: .us)
        match.record(rallyWonBy: .us)

        match.abandon()

        #expect(match.isAbandoned == false)
        #expect(match.state.outcome == .finished(winner: .us))
    }

    /// Отмена возвращает в игру матч, законченный ошибочным касанием, — но не
    /// матч, прекращённый досрочно: от случайного прекращения защищает
    /// подтверждение на экране, а не отмена очка.
    @Test("Отмена не возвращает прекращённый матч в игру")
    func undoDoesNotResumeAnAbandonedMatch() {
        var match = Match(ruleset: .defaultPointsTo)
        match.record(rallyWonBy: .us)
        match.abandon()
        let abandoned = match

        match.undo()

        #expect(match == abandoned)
    }

    /// Стартового экрана пока нет, и приложение открывается сразу на счёте:
    /// прекратить матч можно раньше первого розыгрыша. Отдельного правила на
    /// этот случай нет намеренно — недоигранный матч с пустым журналом и есть
    /// точное описание того, что произошло.
    @Test("Матч, прекращённый до первого розыгрыша, недоигран с нулевым счётом")
    func abandoningBeforeTheFirstRallyLeavesAnEmptyMatch() {
        var match = Match(ruleset: .defaultClassic)

        match.abandon()

        #expect(match.state.outcome == .abandoned)
        #expect(match.journal.isEmpty)
    }
}
