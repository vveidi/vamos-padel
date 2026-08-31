/// Счёт матча и его исход — то, что показывает экран.
///
/// Значение вычисляется из набора правил и журнала розыгрышей и нигде не
/// хранится рядом с ними (ADR-0001).
public struct MatchState: Equatable, Sendable {
    /// Очки сторон.
    public let points: SideCounts

    public let outcome: MatchOutcome

    /// Внутренний намеренно: собрать состояние мимо журнала не должен уметь
    /// никто, иначе счёт снова окажется величиной, которую кто-то хранит
    /// рядом с журналом (ADR-0001).
    init(points: SideCounts = SideCounts(), outcome: MatchOutcome = .inProgress) {
        self.points = points
        self.outcome = outcome
    }
}

extension MatchState {
    /// Движок: чистая функция от набора правил и журнала к состоянию.
    public init(ruleset: Ruleset, journal: RallyJournal) {
        switch ruleset {
        case .pointsTo(let target, _):
            self = .pointsTo(target: target, journal: journal)
        case .classic:
            fatalError("Классический счёт появится в тикете 03")
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
                return MatchState(points: points, outcome: .finished(winner: rally.winner))
            }
        }

        return MatchState(points: points)
    }
}
