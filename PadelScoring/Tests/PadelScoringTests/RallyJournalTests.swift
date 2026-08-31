import Testing

@testable import PadelScoring

@Suite("Журнал розыгрышей")
struct RallyJournalTests {
    @Test("Новый журнал пуст")
    func newJournalIsEmpty() {
        let journal = RallyJournal()

        #expect(journal.isEmpty)
        #expect(journal.count == 0)
        #expect(journal.last == nil)
    }

    @Test("Розыгрыш дописывается в конец и запоминает победившую сторону")
    func appendRecordsWinner() {
        var journal = RallyJournal()

        journal.append(wonBy: .us)
        journal.append(wonBy: .them)

        #expect(journal.count == 2)
        #expect(journal.last == Rally(wonBy: .them))
    }

    @Test("Отмена возвращает журнал ровно в предыдущее состояние")
    func removeLastRestoresPreviousState() {
        var journal = RallyJournal()
        journal.append(wonBy: .us)
        let beforeLastRally = journal

        journal.append(wonBy: .them)
        journal.removeLast()

        #expect(journal == beforeLastRally)
    }

    @Test("Отмена возвращает убранный розыгрыш")
    func removeLastReturnsTheRemovedRally() {
        var journal = RallyJournal()
        journal.append(wonBy: .them)

        #expect(journal.removeLast() == Rally(wonBy: .them))
    }

    @Test("Отмена на пустом журнале безопасна")
    func removeLastOnEmptyJournalIsSafe() {
        var journal = RallyJournal()

        #expect(journal.removeLast() == nil)
        #expect(journal.isEmpty)
    }

    @Test("Журналы с одинаковой последовательностью розыгрышей равны")
    func journalsWithSameRalliesAreEqual() {
        var one = RallyJournal()
        one.append(wonBy: .us)
        one.append(wonBy: .them)

        var another = RallyJournal()
        another.append(wonBy: .us)
        another.append(wonBy: .them)

        #expect(one == another)
    }

    @Test("Порядок розыгрышей значим")
    func rallyOrderMatters() {
        var one = RallyJournal()
        one.append(wonBy: .us)
        one.append(wonBy: .them)

        var another = RallyJournal()
        another.append(wonBy: .them)
        another.append(wonBy: .us)

        #expect(one != another)
    }
}
