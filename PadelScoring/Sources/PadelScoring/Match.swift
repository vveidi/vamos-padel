/// Одна игра от первого розыгрыша до момента, когда набор правил объявляет её
/// законченной.
///
/// Матч — это набор правил и журнал розыгрышей, больше ничего: счёт и исход
/// вычисляются из них каждый раз заново (ADR-0001).
public struct Match: Equatable, Sendable {
    public let ruleset: Ruleset

    /// Сторона, подававшая первый розыгрыш. Свойство матча, а не набора
    /// правил: правила помнятся до следующего матча, а очередь подачи
    /// разыгрывается заново каждый раз. Спросит её стартовый экран (тикет 06).
    public let firstServer: Side

    public private(set) var journal: RallyJournal

    public init(
        ruleset: Ruleset, firstServer: Side = .us, journal: RallyJournal = RallyJournal()
    ) {
        self.ruleset = ruleset
        self.firstServer = firstServer
        self.journal = journal
    }

    /// Счёт, подача и исход матча по текущему журналу.
    public var state: MatchState {
        MatchState(ruleset: ruleset, journal: journal, firstServer: firstServer)
    }

    /// Записывает розыгрыш, выигранный указанной стороной.
    ///
    /// В законченном матче не делает ничего: касание экрана после последнего
    /// розыгрыша не должно ни менять счёт, ни отодвигать отмену (тикет 05)
    /// на лишние нажатия.
    public mutating func record(rallyWonBy side: Side) {
        guard !state.outcome.isFinished else { return }

        journal.append(wonBy: side)
    }

    /// Отменяет последний розыгрыш.
    ///
    /// Обратной арифметики здесь нет и быть не может: журнал укорачивается,
    /// а счёт, геймы, сеты и подающая сторона пересчитываются из того, что
    /// осталось (ADR-0001). Поэтому отмена одинаково проходит границу гейма,
    /// сета и тай-брейка — границы существуют только в свёртке.
    ///
    /// Законченный матч не исключение, в отличие от `record`: отмена и нужна
    /// затем, чтобы вернуть в игру матч, законченный по ошибке. На пустом
    /// журнале не делает ничего.
    public mutating func undo() {
        journal.removeLast()
    }
}
