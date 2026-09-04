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

    /// Сторона, которая подаёт в следующем розыгрыше.
    ///
    /// Как и счёт, вычисляется из журнала, набора правил и первой подачи, а не
    /// хранится рядом с ними: иначе отмена розыгрыша (тикет 05) обязана была бы
    /// откатывать её отдельно и однажды этого не сделала бы.
    public let servingSide: Side

    public let outcome: MatchOutcome

    /// Счёт, которым матч запомнится.
    ///
    /// В классическом счёте это геймы — «6 : 4», — а не очки: последний
    /// розыгрыш матча заканчивает гейм и обнуляет их. Матч длиннее одного сета
    /// запоминается сетами, иначе счёт последнего сета выдавал бы себя за счёт
    /// всего матча.
    ///
    /// Выбирает уровень набор правил, а не сыгранное: у матча, прекращённого
    /// досрочно, сетов может не быть вовсе, и считать его коротким
    /// по одному тому, что сетов сыграно мало, значило бы выдать счёт текущего
    /// сета за счёт матча.
    public let finalScore: SideCounts

    /// Внутренний намеренно: собрать состояние мимо журнала не должен уметь
    /// никто, иначе счёт снова окажется величиной, которую кто-то хранит
    /// рядом с журналом (ADR-0001).
    init(
        points: Points = .count(SideCounts()),
        games: SideCounts? = nil,
        sets: SideCounts? = nil,
        finalScore: SideCounts = SideCounts(),
        servingSide: Side = .us,
        outcome: MatchOutcome = .inProgress
    ) {
        self.points = points
        self.games = games
        self.sets = sets
        self.finalScore = finalScore
        self.servingSide = servingSide
        self.outcome = outcome
    }

    /// То же состояние, но с исходом недоигранного матча.
    ///
    /// Счёт остаётся тем, на котором матч прекратили: недоигранность — это
    /// про исход, а не про счёт. Меняет исход только матч (он один знает, что
    /// его прекратили), поэтому наружу пакета свойство не выходит.
    var abandoned: MatchState {
        MatchState(
            points: points,
            games: games,
            sets: sets,
            finalScore: finalScore,
            servingSide: servingSide,
            outcome: .abandoned)
    }
}

extension MatchState {
    /// Движок: чистая функция от набора правил, журнала и первой подачи
    /// к состоянию.
    ///
    /// Первая подача по умолчанию наша: спрашивает её стартовый экран, а
    /// тестам и превью нужнее короткая запись, чем лишний аргумент.
    public init(ruleset: Ruleset, journal: RallyJournal, firstServer: Side = .us) {
        switch ruleset {
        case .pointsTo(let target, let serveChangesEvery):
            self = .pointsTo(
                target: target,
                serveChangesEvery: serveChangesEvery,
                firstServer: firstServer,
                journal: journal)
        case .classic(let setsToWin, let goldenPoint):
            self = .classic(
                setsToWin: setsToWin,
                goldenPoint: goldenPoint,
                firstServer: firstServer,
                journal: journal)
        }
    }

    /// Счёт до N очков: побеждает сторона, первой набравшая `target`.
    ///
    /// Проверка стоит после розыгрыша, поэтому пустой журнал — всегда
    /// незаконченный матч, а любое `target` меньше двух ведёт себя как
    /// «до одного очка»: выигрывает тот, кто взял первый розыгрыш. Осмысленную
    /// нижнюю границу N задаёт стартовый экран, но и бессмысленное
    /// значение не должно ни ронять приложение, ни делать матч бесконечным.
    /// Подача здесь переходит каждые X розыгрышей. X приходит извне и потому
    /// подпирается снизу: при нуле подача не «не менялась бы», а
    /// уронила бы приложение делением на ноль.
    private static func pointsTo(
        target: Int, serveChangesEvery: Int, firstServer: Side, journal: RallyJournal
    ) -> MatchState {
        let serveChangesEvery = max(serveChangesEvery, 1)

        var points = SideCounts()

        func state(outcome: MatchOutcome = .inProgress) -> MatchState {
            MatchState(
                points: .count(points),
                finalScore: points,
                servingSide: firstServer.alternating(points.total / serveChangesEvery),
                outcome: outcome)
        }

        for rally in journal.rallies {
            points = points.incrementing(rally.winner)

            if points[rally.winner] >= target {
                return state(outcome: .finished(winner: rally.winner))
            }
        }

        return state()
    }

    /// Классический счёт: очки складываются в геймы, геймы в сеты, сеты
    /// заканчивают матч.
    ///
    /// Свёртка одна на все три уровня, потому что уровень поднимается только
    /// тем же розыгрышем, который закрыл уровень ниже: очко, выигравшее гейм,
    /// может тем же движением выиграть сет, а вместе с ним и матч.
    ///
    /// Число сетов приходит извне и потому подпирается снизу: матч до нуля
    /// сетов невозможно ни начать, ни закончить.
    private static func classic(
        setsToWin: Int, goldenPoint: Bool, firstServer: Side, journal: RallyJournal
    ) -> MatchState {
        let setsToWin = max(setsToWin, 1)

        // Тот же вопрос, что `Ruleset.isMultiSet`, и тот же ответ: матч
        // длиннее одного сета запоминается сетами, иначе счёт последнего сета
        // выдавал бы себя за счёт всего матча.
        let isMultiSet = setsToWin > 1

        var sets = SideCounts()
        var games = SideCounts()
        var points = SideCounts()
        var isTieBreak = false

        /// Геймы за весь матч, а не за текущий сет: подача ходит по границе
        /// гейма и конца сета не замечает, а `games` обнуляется вместе с ним.
        var gamesPlayed = 0

        /// Состояние по текущему ходу свёртки. Собрано здесь, а не на каждом
        /// выходе, чтобы уровень итогового счёта выбирался один раз и не мог
        /// разойтись между концом матча и его серединой.
        func state(outcome: MatchOutcome = .inProgress) -> MatchState {
            MatchState(
                points: isTieBreak ? .count(points) : .game(points),
                games: games,
                sets: sets,
                finalScore: isMultiSet ? sets : games,
                servingSide: firstServer.alternating(gamesPlayed + tieBreakServeChanges),
                outcome: outcome)
        }

        /// Переходы подачи внутри тай-брейка. Тай-брейк — единственное место,
        /// где подача ходит не по границе гейма: первый розыгрыш подаёт тот,
        /// чья очередь, дальше меняются каждые два. Без этого индикатор врал бы
        /// все тринадцать розыгрышей тай-брейка — ровно там, где на него и
        /// смотрят.
        var tieBreakServeChanges: Int {
            isTieBreak ? (points.total + 1) / 2 : 0
        }

        for rally in journal.rallies {
            points = points.incrementing(rally.winner)

            let gameWon =
                isTieBreak
                ? tieBreakIsWon(by: rally.winner, points: points)
                : gameIsWon(by: rally.winner, points: points, goldenPoint: goldenPoint)

            guard gameWon else { continue }

            points = SideCounts()
            games = games.incrementing(rally.winner)
            gamesPlayed += 1

            if setIsWon(by: rally.winner, games: games) {
                sets = sets.incrementing(rally.winner)

                if sets[rally.winner] >= setsToWin {
                    // Геймы намеренно не обнуляются: счётом закончившегося
                    // матча остаётся тот, которым он закончился.
                    return state(outcome: .finished(winner: rally.winner))
                }

                games = SideCounts()
                isTieBreak = false
            } else {
                isTieBreak = games == SideCounts(us: gamesInSet, them: gamesInSet)
            }
        }

        return state()
    }

    private static let gamesInSet = 6

    private static let tieBreakPoints = 7

    /// Уровень взят: сторона дошла до порога и оторвалась на два.
    ///
    /// Гейм, тай-брейк и сет отличаются только порогом, поэтому правило одно.
    /// Своё у каждого — лишь то, чем он от этого правила отступает.
    private static func isWon(by winner: Side, counts: SideCounts, reaching threshold: Int) -> Bool
    {
        counts[winner] >= threshold && counts[winner] - counts[winner.opposite] >= 2
    }

    /// Гейм: четыре очка с разницей в два.
    ///
    /// Золотое очко сводит правило к «первому, кто дошёл до четырёх»: до
    /// «ровно» четвёртое очко и так означает разницу минимум в два, а на самом
    /// «ровно» решает один розыгрыш — тот, что делает счёт 4:3.
    private static func gameIsWon(by winner: Side, points: SideCounts, goldenPoint: Bool) -> Bool {
        if goldenPoint { return points[winner] >= Points.pointsInGame }

        return isWon(by: winner, counts: points, reaching: Points.pointsInGame)
    }

    /// Тай-брейк: семь очков с разницей в два.
    ///
    /// Золотое очко на него не распространяется: это правило гейма, а тай-брейк
    /// геймом не является.
    private static func tieBreakIsWon(by winner: Side, points: SideCounts) -> Bool {
        isWon(by: winner, counts: points, reaching: tieBreakPoints)
    }

    /// Сет: шесть геймов с разницей в два, а после тай-брейка — 7:6, который
    /// под разницу в два не подходит и потому назван отдельно. Другого способа
    /// получить 7:6 в сете нет.
    private static func setIsWon(by winner: Side, games: SideCounts) -> Bool {
        if games[winner] == gamesInSet + 1 && games[winner.opposite] == gamesInSet { return true }

        return isWon(by: winner, counts: games, reaching: gamesInSet)
    }
}