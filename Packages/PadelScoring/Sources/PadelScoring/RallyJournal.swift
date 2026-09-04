/// Упорядоченная последовательность розыгрышей матча — единственная
/// сохраняемая правда о матче.
///
/// Счёт вычисляется из журнала и нигде не хранится рядом с ним (ADR-0001).
/// Поэтому отмена последнего очка — это удаление последней записи, а не
/// обратная арифметика, и рассинхронизироваться со счётом журнал не может.
public struct RallyJournal: Equatable, Sendable {
    public private(set) var rallies: [Rally]

    public init(_ rallies: [Rally] = []) {
        self.rallies = rallies
    }

    public var count: Int { rallies.count }

    public var isEmpty: Bool { rallies.isEmpty }

    /// Последний сыгранный розыгрыш, если он был.
    public var last: Rally? { rallies.last }

    /// Записывает розыгрыш, выигранный указанной стороной.
    public mutating func append(wonBy side: Side) {
        rallies.append(Rally(wonBy: side))
    }

    /// Убирает последний розыгрыш и возвращает его.
    ///
    /// На пустом журнале ничего не делает и возвращает `nil`: отмена, нажатая
    /// до первого очка, не должна ничего ломать.
    @discardableResult
    public mutating func removeLast() -> Rally? {
        rallies.popLast()
    }
}
