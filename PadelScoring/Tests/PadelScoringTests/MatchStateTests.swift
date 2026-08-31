import Testing

@testable import PadelScoring

@Suite("Состояние матча: счёт до N очков")
struct MatchStateTests {
    @Test("До первого розыгрыша счёт нулевой, матч идёт")
    func emptyJournalScoresNothing() {
        let state = MatchState(ruleset: .defaultPointsTo, journal: RallyJournal())

        #expect(state.points == SideCounts())
        #expect(state.outcome == .inProgress)
    }

    @Test("Каждый розыгрыш добавляет очко выигравшей стороне")
    func everyRallyScoresForItsWinner() {
        let state = MatchState(ruleset: .defaultPointsTo, journal: journal(.us, .them, .us))

        #expect(state.points == SideCounts(us: 2, them: 1))
        #expect(state.outcome == .inProgress)
    }

    @Test("Матч заканчивается, как только сторона набирает N очков")
    func matchFinishesAtTargetPoints() {
        let state = MatchState(
            ruleset: .pointsTo(target: 3, serveChangesEvery: 4),
            journal: journal(.us, .them, .us, .us))

        #expect(state.points == SideCounts(us: 3, them: 1))
        #expect(state.outcome == .finished(winner: .us))
    }

    @Test("После окончания матча розыгрыши больше не меняют счёт")
    func ralliesAfterTheFinishDoNotCount() {
        let state = MatchState(
            ruleset: .pointsTo(target: 2, serveChangesEvery: 4),
            journal: journal(.us, .us, .them, .them, .them))

        #expect(state.points == SideCounts(us: 2, them: 0))
        #expect(state.outcome == .finished(winner: .us))
    }

    @Test("При N = 1 матч заканчивается первым же розыгрышем")
    func targetOfOnePointEndsWithTheFirstRally() {
        let ruleset = Ruleset.pointsTo(target: 1, serveChangesEvery: 4)

        #expect(MatchState(ruleset: ruleset, journal: RallyJournal()).outcome == .inProgress)
        #expect(MatchState(ruleset: ruleset, journal: journal(.them)).outcome == .finished(winner: .them))
    }

    /// N меньше единицы бессмысленно, но приходит извне (тикет 06), поэтому
    /// движок обязан вести себя предсказуемо: не ронять приложение и не
    /// оставлять матч, который невозможно закончить.
    @Test("N меньше единицы не ломает матч, а ведёт себя как N = 1", arguments: [0, -3])
    func targetBelowOneBehavesLikeOne(target: Int) {
        let ruleset = Ruleset.pointsTo(target: target, serveChangesEvery: 4)

        #expect(MatchState(ruleset: ruleset, journal: RallyJournal()).outcome == .inProgress)
        #expect(MatchState(ruleset: ruleset, journal: journal(.us, .them)).outcome == .finished(winner: .us))
    }

    @Test("Один и тот же журнал даёт одно и то же состояние")
    func theSameJournalAlwaysScoresTheSame() {
        let ruleset = Ruleset.pointsTo(target: 4, serveChangesEvery: 4)
        let played = journal(.us, .them, .us, .them, .us)

        // Отдельно собранный журнал с той же последовательностью: состояние не
        // должно зависеть ни от чего, кроме самой последовательности.
        var replayed = RallyJournal()
        for rally in played.rallies { replayed.append(wonBy: rally.winner) }

        #expect(MatchState(ruleset: ruleset, journal: played) == MatchState(ruleset: ruleset, journal: replayed))
    }
}

/// Журнал, в котором перечисленные стороны выигрывают розыгрыши по порядку.
private func journal(_ winners: Side...) -> RallyJournal {
    RallyJournal(winners.map(Rally.init(wonBy:)))
}
