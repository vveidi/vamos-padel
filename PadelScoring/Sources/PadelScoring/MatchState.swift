/// Счёт матча и его исход — то, что показывает экран.
///
/// Значение вычисляется из набора правил и журнала розыгрышей и нигде не
/// хранится рядом с ними (ADR-0001).
public struct MatchState: Equatable, Sendable {
    /// Очки в текущем гейме, а в счёте до N очков — за весь матч.
    public let points: Points

    /// Геймы в текущем сете. `nil` там, где геймов нет: счёт до N очков не
    /// делится на геймы, и показывать в нём «0 : 0» было бы враньём.
    public let games: SideCounts?

    /// Выигранные сеты, `nil` там, где сетов нет.
    public let sets: SideCounts?

    public let outcome: MatchOutcome

    /// Внутренний намеренно: собрать состояние мимо журнала не должен уметь
    /// никто, иначе счёт снова окажется величиной, которую кто-то хранит
    /// рядом с журналом (ADR-0001).
    init(
        points: Points = .count(SideCounts()),
        games: SideCounts? = nil,
        sets: SideCounts? = nil,
        outcome: MatchOutcome = .inProgress
    ) {
        self.points = points
        self.games = games
        self.sets = sets
        self.outcome = outcome
    }

    /// Счёт, которым матч запомнится.
    ///
    /// В классическом счёте это геймы — «6 : 4», — а не очки: последний
    /// розыгрыш матча заканчивает гейм и обнуляет их. Матч длиннее одного сета
    /// запоминается сетами, иначе счёт последнего сета выдавал бы себя за счёт
    /// всего матча.
    public var finalScore: SideCounts {
        if let sets, sets.us + sets.them > 1 { return sets }

        return games ?? points.counts
    }
}

extension MatchState {
    /// Движок: чистая функция от набора правил и журнала к состоянию.
    public init(ruleset: Ruleset, journal: RallyJournal) {
        switch ruleset {
        case .pointsTo(let target, _):
            self = .pointsTo(target: target, journal: journal)
        case .classic(let setsToWin, let goldenPoint):
            self = .classic(setsToWin: setsToWin, goldenPoint: goldenPoint, journal: journal)
        }
    }

    /// Счёт до N очков: побеждает сторона, первой набравшая `target`.
    ///
    /// Проверка стоит после розыгрыша, поэтому пустой журнал — всегда
    /// незаконченный матч, а любое `target` меньше двух ведёт себя как
    /// «до одного очка»: выигрывает тот, кто взял первый розыгрыш. Осмысленную
    /// нижнюю границу N задаёт стартовый экран (тикет 06), но и бессмысленное
    /// значение не должно ни ронять приложение, ни делать матч бесконечным.
    private static func pointsTo(target: Int, journal: RallyJournal) -> MatchState {
        var points = SideCounts()

        for rally in journal.rallies {
            points = points.incrementing(rally.winner)

            if points[rally.winner] >= target {
                return MatchState(points: .count(points), outcome: .finished(winner: rally.winner))
            }
        }

        return MatchState(points: .count(points))
    }

    /// Классический счёт: очки складываются в геймы, геймы в сеты, сеты
    /// заканчивают матч.
    ///
    /// Свёртка одна на все три уровня, потому что уровень поднимается только
    /// тем же розыгрышем, который закрыл уровень ниже: очко, выигравшее гейм,
    /// может тем же движением выиграть сет, а вместе с ним и матч.
    ///
    /// Число сетов приходит извне (тикет 06) и потому подпирается снизу: матч
    /// до нуля сетов невозможно ни начать, ни закончить.
    private static func classic(
        setsToWin: Int, goldenPoint: Bool, journal: RallyJournal
    ) -> MatchState {
        let setsToWin = max(setsToWin, 1)

        var sets = SideCounts()
        var games = SideCounts()
        var points = SideCounts()
        var isTieBreak = false

        for rally in journal.rallies {
            points = points.incrementing(rally.winner)

            let gameWon =
                isTieBreak
                ? tieBreakIsWon(by: rally.winner, points: points)
                : gameIsWon(by: rally.winner, points: points, goldenPoint: goldenPoint)

            guard gameWon else { continue }

            points = SideCounts()
            games = games.incrementing(rally.winner)

            if setIsWon(by: rally.winner, games: games) {
                sets = sets.incrementing(rally.winner)

                if sets[rally.winner] >= setsToWin {
                    // Геймы намеренно не обнуляются: счётом закончившегося
                    // матча остаётся тот, которым он закончился.
                    return MatchState(
                        points: .game(points),
                        games: games,
                        sets: sets,
                        outcome: .finished(winner: rally.winner))
                }

                games = SideCounts()
                isTieBreak = false
            } else {
                isTieBreak = games == SideCounts(us: 6, them: 6)
            }
        }

        return MatchState(
            points: isTieBreak ? .count(points) : .game(points), games: games, sets: sets)
    }

    /// Гейм выигран при четырёх очках и разнице в два.
    ///
    /// Золотое очко сводит правило к «первому, кто дошёл до четырёх»: до
    /// «ровно» четвёртое очко и так означает разницу минимум в два, а на самом
    /// «ровно» решает один розыгрыш — тот, что делает счёт 4:3.
    private static func gameIsWon(by winner: Side, points: SideCounts, goldenPoint: Bool) -> Bool {
        let own = points[winner]

        guard own >= 4 else { return false }

        return goldenPoint || own - points[winner.opposite] >= 2
    }

    /// Тай-брейк играется до семи очков с разницей в два.
    ///
    /// Золотое очко на него не распространяется: это правило гейма, а тай-брейк
    /// геймом не является.
    private static func tieBreakIsWon(by winner: Side, points: SideCounts) -> Bool {
        points[winner] >= 7 && points[winner] - points[winner.opposite] >= 2
    }

    /// Сет выигран при шести геймах и разнице в два, а после тай-брейка — со
    /// счётом 7:6, который под разницу в два не подходит и потому назван
    /// отдельно. Другого способа получить 7:6 в сете нет.
    private static func setIsWon(by winner: Side, games: SideCounts) -> Bool {
        let own = games[winner]
        let other = games[winner.opposite]

        if own == 7 && other == 6 { return true }

        return own >= 6 && own - other >= 2
    }
}
