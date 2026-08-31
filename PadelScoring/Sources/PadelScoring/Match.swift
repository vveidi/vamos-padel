/// Одна игра от первого розыгрыша до момента, когда набор правил объявляет её
/// законченной.
///
/// Матч — это набор правил и журнал розыгрышей, больше ничего: счёт и исход
/// вычисляются из них каждый раз заново (ADR-0001).
public struct Match: Equatable, Sendable {
    public let ruleset: Ruleset
    public private(set) var journal: RallyJournal

    public init(ruleset: Ruleset, journal: RallyJournal = RallyJournal()) {
        self.ruleset = ruleset
        self.journal = journal
    }

    /// Счёт и исход матча по текущему журналу.
    public var state: MatchState {
        MatchState(ruleset: ruleset, journal: journal)
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
}
