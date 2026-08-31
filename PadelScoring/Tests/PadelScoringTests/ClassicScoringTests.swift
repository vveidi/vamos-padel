import Testing

@testable import PadelScoring

@Suite("Состояние матча: классический счёт")
struct ClassicScoringTests {
    // MARK: Гейм

    @Test("Очки в гейме называются 15, 30 и 40")
    func gamePointsAreNamedTheClassicWay() {
        let ladder = ["0", "15", "30", "40"]

        for (won, name) in ladder.enumerated() {
            let state = classicState(rallies(.us, won))

            #expect(state.points.label(for: .us) == name)
            #expect(state.points.label(for: .them) == "0")
            #expect(state.outcome == .inProgress)
        }
    }

    @Test("Четвёртое очко при разнице в два выигрывает гейм")
    func fourthPointWinsTheGame() {
        let state = classicState(rallies(.us, 4), goldenPoint: false)

        #expect(state.games == SideCounts(us: 1, them: 0))
        #expect(state.points == .game(SideCounts()))
    }

    @Test("Гейм, выигранный не всухую, тоже считается")
    func aGameWonAgainstResistanceCounts() {
        let state = classicState([.us, .them, .us, .them, .us, .us], goldenPoint: false)

        #expect(state.games == SideCounts(us: 1, them: 0))
    }

    // MARK: «Ровно»

    @Test("Без золотого очка «ровно» продолжается до разницы в два")
    func withoutGoldenPointDeuceRunsUntilTwoClear() {
        let deuce = rallies(.us, 3) + rallies(.them, 3)

        // «Больше» у нас: гейм ещё не выигран.
        let advantage = classicState(deuce + [.us], goldenPoint: false)
        #expect(advantage.points.label(for: .us) == "AD")
        #expect(advantage.points.label(for: .them) == "40")
        #expect(advantage.games == SideCounts())

        // Соперники отыгрались — снова «ровно», а не гейм.
        let backToDeuce = classicState(deuce + [.us, .them], goldenPoint: false)
        #expect(backToDeuce.points.label(for: .us) == "40")
        #expect(backToDeuce.points.label(for: .them) == "40")
        #expect(backToDeuce.games == SideCounts())

        // Два подряд после «ровно» — гейм.
        let won = classicState(deuce + [.us, .us], goldenPoint: false)
        #expect(won.games == SideCounts(us: 1, them: 0))
    }

    @Test("С золотым очком «ровно» разыгрывается одним розыгрышем")
    func withGoldenPointDeuceIsDecidedByOneRally() {
        let deuce = rallies(.us, 3) + rallies(.them, 3)

        #expect(classicState(deuce, goldenPoint: true).games == SideCounts())
        #expect(classicState(deuce + [.them], goldenPoint: true).games == SideCounts(us: 0, them: 1))
    }

    @Test("Золотое очко не мешает выиграть гейм до «ровно»")
    func goldenPointLeavesTheOrdinaryGameAlone() {
        let state = classicState(rallies(.us, 3) + [.them, .us], goldenPoint: true)

        #expect(state.games == SideCounts(us: 1, them: 0))
    }

    // MARK: Сет

    @Test("Сет выигрывается шестью геймами при разнице в два")
    func aSetIsWonBySixGamesTwoClear() {
        let state = classicState(gamesWonBy([.us, .us, .us, .us, .us, .us]), setsToWin: 2)

        #expect(state.sets == SideCounts(us: 1, them: 0))
        #expect(state.games == SideCounts())
    }

    @Test("При 6:5 сет ещё не выигран, при 7:5 — выигран")
    func fiveGamesBehindIsNotYetASet() {
        let toFiveAll = gamesWonBy([.us, .them, .us, .them, .us, .them, .us, .them, .us, .them])

        let sixFive = classicState(toFiveAll + gamesWonBy([.us]), setsToWin: 2)
        #expect(sixFive.sets == SideCounts())
        #expect(sixFive.games == SideCounts(us: 6, them: 5))

        let sevenFive = classicState(toFiveAll + gamesWonBy([.us, .us]), setsToWin: 2)
        #expect(sevenFive.sets == SideCounts(us: 1, them: 0))
    }

    // MARK: Тай-брейк

    @Test("При 6:6 начинается тай-брейк: очки снова считаются числом")
    func sixAllStartsATieBreak() {
        let state = classicState(toSixAll + rallies(.us, 3))

        #expect(state.games == SideCounts(us: 6, them: 6))
        #expect(state.points == .count(SideCounts(us: 3, them: 0)))
        #expect(state.points.label(for: .us) == "3")
    }

    @Test("Тай-брейк выигрывается семью очками при разнице в два, сет — 7:6")
    func aTieBreakIsWonBySevenTwoClear() {
        let sixPoints = classicState(toSixAll + rallies(.us, 6), setsToWin: 2)
        #expect(sixPoints.sets == SideCounts())

        // Матч в один сет: геймы не обнуляются под следующий сет, и счёт,
        // которым тай-брейк закончил сет, виден целиком.
        let state = classicState(toSixAll + rallies(.us, 7))

        #expect(state.games == SideCounts(us: 7, them: 6))
        #expect(state.sets == SideCounts(us: 1, them: 0))
        #expect(state.outcome == .finished(winner: .us))
        #expect(state.finalScore == SideCounts(us: 7, them: 6))
    }

    @Test("Выигранный сет обнуляет геймы под следующий")
    func awonSetResetsTheGames() {
        let state = classicState(gamesWonBy([.us, .us, .us, .us, .us, .us]), setsToWin: 2)

        #expect(state.sets == SideCounts(us: 1, them: 0))
        #expect(state.games == SideCounts())
        #expect(state.outcome == .inProgress)
    }

    @Test("При 6:6 в тай-брейке игра продолжается до разницы в два")
    func aTieBreakAtSixAllRunsOn() {
        let tieBreakDeuce = toSixAll + rallies(.us, 6) + rallies(.them, 6)

        let sevenSix = classicState(tieBreakDeuce + [.us], setsToWin: 2)
        #expect(sevenSix.sets == SideCounts())
        #expect(sevenSix.points == .count(SideCounts(us: 7, them: 6)))

        let nineSeven = classicState(tieBreakDeuce + [.us, .us], setsToWin: 2)
        #expect(nineSeven.sets == SideCounts(us: 1, them: 0))
    }

    /// Золотое очко — правило гейма, а тай-брейк геймом не является.
    @Test("Золотое очко не укорачивает тай-брейк")
    func goldenPointDoesNotShortenATieBreak() {
        let atSixAll = toSixAll + rallies(.us, 6) + rallies(.them, 6)

        #expect(classicState(atSixAll + [.us], goldenPoint: true, setsToWin: 2).sets == SideCounts())
    }

    // MARK: Конец матча

    @Test("По умолчанию матч заканчивается первым же выигранным сетом")
    func oneSetFinishesTheMatchByDefault() {
        let state = classicState(gamesWonBy([.them, .them, .them, .them, .them, .them]))

        #expect(state.outcome == .finished(winner: .them))
        #expect(state.sets == SideCounts(us: 0, them: 1))
    }

    @Test("Матч до двух сетов не заканчивается на первом")
    func aTwoSetMatchOutlivesItsFirstSet() {
        let firstSet = gamesWonBy([.us, .us, .us, .us, .us, .us])

        #expect(classicState(firstSet, setsToWin: 2).outcome == .inProgress)
        #expect(classicState(firstSet + firstSet, setsToWin: 2).outcome == .finished(winner: .us))
    }

    @Test("После окончания матча розыгрыши больше не меняют счёт")
    func ralliesAfterTheFinishDoNotCount() {
        let set = gamesWonBy([.us, .us, .us, .us, .us, .us])
        let finished = classicState(set)

        #expect(classicState(set + rallies(.them, 9)) == finished)
    }

    /// Число сетов приходит со стартового экрана (тикет 06) и может оказаться
    /// бессмысленным; матч, который невозможно закончить, — не тот способ об
    /// этом сообщить.
    @Test("Число сетов меньше единицы ведёт себя как один сет", arguments: [0, -2])
    func setsBelowOneBehaveLikeOne(setsToWin: Int) {
        let state = classicState(gamesWonBy([.us, .us, .us, .us, .us, .us]), setsToWin: setsToWin)

        #expect(state.outcome == .finished(winner: .us))
    }

    // MARK: Итоговый счёт

    @Test("Закончившийся матч запоминается счётом по геймам, а не по очкам")
    func aFinishedMatchIsRememberedByItsGames() {
        let state = classicState(gamesWonBy([.us, .them, .us, .them, .us, .us, .us, .us]))

        #expect(state.finalScore == SideCounts(us: 6, them: 2))
    }

    @Test("Матч из нескольких сетов запоминается счётом по сетам")
    func aLongerMatchIsRememberedByItsSets() {
        let ourSet = gamesWonBy([.us, .us, .us, .us, .us, .us])
        let theirSet = gamesWonBy([.them, .them, .them, .them, .them, .them])

        let state = classicState(theirSet + ourSet + ourSet, setsToWin: 2)

        #expect(state.outcome == .finished(winner: .us))
        #expect(state.finalScore == SideCounts(us: 2, them: 1))
    }

    // MARK: Общее с движком

    @Test("Один и тот же журнал даёт одно и то же состояние")
    func theSameJournalAlwaysScoresTheSame() {
        let played = gamesWonBy([.us, .them, .us]) + rallies(.them, 2)

        var replayed = RallyJournal()
        for side in played { replayed.append(wonBy: side) }

        #expect(MatchState(ruleset: .defaultClassic, journal: journal(played)) == MatchState(ruleset: .defaultClassic, journal: replayed))
    }

    @Test("До первого розыгрыша счёт нулевой, матч идёт")
    func anEmptyJournalScoresNothing() {
        let state = classicState([])

        #expect(state.points == .game(SideCounts()))
        #expect(state.games == SideCounts())
        #expect(state.sets == SideCounts())
        #expect(state.outcome == .inProgress)
    }
}

// MARK: - Постройка журналов

/// Розыгрыши, доводящие геймы до 6:6. Каждый гейм здесь выигрывается всухую:
/// путь к 6:6 в этих тестах не важен, важно то, что начинается после.
private let toSixAll = gamesWonBy([.us, .them, .us, .them, .us, .them, .us, .them, .us, .them, .us, .them])

/// Состояние классического матча по перечисленным победителям розыгрышей.
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

/// `count` розыгрышей подряд, выигранных одной стороной.
private func rallies(_ side: Side, _ count: Int) -> [Side] {
    Array(repeating: side, count: count)
}

/// Розыгрыши, которыми перечисленные стороны выигрывают по гейму всухую —
/// четыре очка подряд. Гейм «под ноль» короче любого другого, поэтому длинные
/// журналы собираются из него.
private func gamesWonBy(_ winners: [Side]) -> [Side] {
    winners.flatMap { rallies($0, 4) }
}
