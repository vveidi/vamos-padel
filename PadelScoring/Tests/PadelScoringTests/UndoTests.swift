import Testing

@testable import PadelScoring

@Suite("Отмена последнего очка")
struct UndoTests {
    /// Самая сильная проверка тикета: не «отмена работает на границе гейма», а
    /// «отмена не умеет ошибаться нигде». Журнал ниже проходит гейм, «ровно»,
    /// границу сета и тай-брейк, и на каждом розыгрыше состояние до записи
    /// сравнивается с состоянием после отмены — вместе с подачей и исходом.
    @Test("Отмена возвращает ровно то состояние, что было до розыгрыша")
    func undoRestoresTheStateExactly() {
        var match = Match(ruleset: .classic(setsToWin: 2, goldenPoint: false), firstServer: .them)

        var sawDeuce = false
        var sawTieBreak = false
        var sawSet = false

        for winner in aMatchThroughEveryBoundary {
            let before = match.state

            match.record(rallyWonBy: winner)
            match.undo()

            #expect(match.state == before)

            match.record(rallyWonBy: winner)

            let state = match.state
            sawDeuce = sawDeuce || state.points.label(for: .us) == "AD"
            sawTieBreak = sawTieBreak || state.games == SideCounts(us: 6, them: 6)
            sawSet = sawSet || state.sets != SideCounts()
        }

        // Иначе фикстура однажды перестанет проходить границы, а тест будет
        // всё так же зелёным и всё так же обещать, что их проходит.
        #expect(sawDeuce, "журнал не дошёл до «ровно»")
        #expect(sawTieBreak, "журнал не дошёл до тай-брейка")
        #expect(sawSet, "журнал не дошёл до конца сета")
    }

    @Test("Отмена работает и в счёте до N очков")
    func undoWorksInPointsToAsWell() {
        var match = Match(ruleset: .pointsTo(target: 16, serveChangesEvery: 4))
        for winner in [Side.us, .us, .them, .us] { match.record(rallyWonBy: winner) }
        let before = match.state

        match.record(rallyWonBy: .them)
        match.undo()

        #expect(match.state == before)
        #expect(match.state.servingSide == .them)
    }

    // MARK: Границы

    @Test("Отмена переходит границу гейма и возвращает подачу")
    func undoCrossesTheGameBoundary() {
        var match = Match(ruleset: .defaultClassic)
        for _ in 0..<3 { match.record(rallyWonBy: .us) }
        let atFortyLove = match.state

        // Гейм выигран: очки обнулились, подача ушла к соперникам.
        match.record(rallyWonBy: .us)
        #expect(match.state.games == SideCounts(us: 1, them: 0))
        #expect(match.state.servingSide == .them)

        match.undo()

        #expect(match.state == atFortyLove)
        #expect(match.state.points.label(for: .us) == "40")
        #expect(match.state.servingSide == .us)
    }

    @Test("Отмена переходит границу сета")
    func undoCrossesTheSetBoundary() {
        var match = Match(ruleset: .classic(setsToWin: 2, goldenPoint: true))
        for winner in gamesWonBy([.us, .us, .us, .us, .us]) { match.record(rallyWonBy: winner) }
        for _ in 0..<3 { match.record(rallyWonBy: .us) }
        let beforeTheSet = match.state

        match.record(rallyWonBy: .us)
        #expect(match.state.sets == SideCounts(us: 1, them: 0))
        #expect(match.state.games == SideCounts())

        match.undo()

        #expect(match.state == beforeTheSet)
        #expect(match.state.sets == SideCounts())
        #expect(match.state.games == SideCounts(us: 5, them: 0))
    }

    @Test("Отмена переходит границу тай-брейка")
    func undoCrossesTheTieBreakBoundary() {
        var match = Match(ruleset: .classic(setsToWin: 2, goldenPoint: true))
        for winner in toSixAll { match.record(rallyWonBy: winner) }
        for _ in 0..<6 { match.record(rallyWonBy: .us) }
        let inTheTieBreak = match.state

        // Седьмое очко забирает тай-брейк, сет и обнуляет геймы.
        match.record(rallyWonBy: .us)
        #expect(match.state.sets == SideCounts(us: 1, them: 0))

        match.undo()

        #expect(match.state == inTheTieBreak)
        #expect(match.state.games == SideCounts(us: 6, them: 6))
        #expect(match.state.points == .count(SideCounts(us: 6, them: 0)))
    }

    // MARK: Законченный матч

    @Test("Отмена возвращает законченный матч в игру")
    func undoBringsAFinishedMatchBack() {
        var match = Match(ruleset: .pointsTo(target: 3, serveChangesEvery: 4))
        for _ in 0..<2 { match.record(rallyWonBy: .us) }
        let beforeTheEnd = match.state

        match.record(rallyWonBy: .us)
        #expect(match.state.outcome == .finished(winner: .us))

        match.undo()

        #expect(match.state == beforeTheEnd)
        #expect(match.state.outcome == .inProgress)

        // И матч снова принимает розыгрыши: до отмены `record` их не писал.
        match.record(rallyWonBy: .them)
        #expect(match.state.points == .count(SideCounts(us: 2, them: 1)))
    }

    @Test("Отмена возвращает в игру и матч, законченный сетом")
    func undoBringsAFinishedClassicMatchBack() {
        var match = Match(ruleset: .defaultClassic)
        for winner in gamesWonBy([.us, .us, .us, .us, .us, .us]) { match.record(rallyWonBy: winner) }
        #expect(match.state.outcome == .finished(winner: .us))

        match.undo()

        #expect(match.state.outcome == .inProgress)
        #expect(match.state.games == SideCounts(us: 5, them: 0))
        #expect(match.state.points.label(for: .us) == "40")
    }

    // MARK: Несколько отмен и пустой журнал

    @Test("Несколько отмен подряд откатывают журнал последовательно")
    func repeatedUndoWalksTheJournalBack() {
        var match = Match(ruleset: .defaultClassic)
        var states: [MatchState] = []

        for winner in gamesWonBy([.us, .them, .us]) {
            states.append(match.state)
            match.record(rallyWonBy: winner)
        }

        for expected in states.reversed() {
            match.undo()
            #expect(match.state == expected)
        }

        #expect(match.journal.isEmpty)
    }

    @Test("Отмена на пустом журнале ничего не ломает")
    func undoOnAnEmptyJournalIsHarmless() {
        var match = Match(ruleset: .defaultClassic)
        let fresh = match

        for _ in 0..<3 { match.undo() }

        #expect(match == fresh)
        #expect(match.journal.isEmpty)
        #expect(match.state.outcome == .inProgress)

        // И матч по-прежнему живой.
        match.record(rallyWonBy: .them)
        #expect(match.state.points.label(for: .them) == "15")
    }
}

// MARK: - Постройка журналов

/// Розыгрыши матча, проходящего гейм всухую, гейм через «ровно», границу сета
/// и тай-брейк: каждый из них — граница, на которой отмена могла бы соврать.
private let aMatchThroughEveryBoundary: [Side] =
    // Первый сет до 6:6 — ни один гейм по дороге сет не закрывает.
    gamesWonBy([.us, .them, .us, .them, .us, .them, .us, .them, .us, .them, .us, .them])
    // Тай-брейк: 3:3, затем четыре наших очка подряд — сет 7:6.
    + [.us, .them, .us, .them, .us, .them, .us, .us, .us, .us]
    // Второй сет: обычный гейм, затем гейм через «ровно» и «больше».
    + gamesWonBy([.us, .them])
    + [.us, .us, .us, .them, .them, .them, .us, .them, .us, .us]

private let toSixAll = gamesWonBy([.us, .them, .us, .them, .us, .them, .us, .them, .us, .them, .us, .them])

private func gamesWonBy(_ winners: [Side]) -> [Side] {
    winners.flatMap { Array(repeating: $0, count: 4) }
}
