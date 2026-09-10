import Testing

@testable import PadelScoring

@Suite("Rally journal")
struct RallyJournalTests {
    @Test("A new journal is empty")
    func newJournalIsEmpty() {
        let journal = RallyJournal()

        #expect(journal.isEmpty)
        #expect(journal.last == nil)
    }

    @Test("A rally is appended at the end and remembers the winning side")
    func appendRecordsWinner() {
        var journal = RallyJournal()

        journal.append(wonBy: .us)
        journal.append(wonBy: .them)

        #expect(journal.count == 2)
        #expect(journal.last == Rally(wonBy: .them))
    }

    @Test("Undo returns the journal to exactly its previous state")
    func removeLastRestoresPreviousState() {
        var journal = RallyJournal()
        journal.append(wonBy: .us)
        let beforeLastRally = journal

        journal.append(wonBy: .them)
        journal.removeLast()

        #expect(journal == beforeLastRally)
    }

    @Test("Undo returns the rally it removed")
    func removeLastReturnsTheRemovedRally() {
        var journal = RallyJournal()
        journal.append(wonBy: .them)

        #expect(journal.removeLast() == Rally(wonBy: .them))
    }

    @Test("Undo on an empty journal is safe")
    func removeLastOnEmptyJournalIsSafe() {
        var journal = RallyJournal()

        #expect(journal.removeLast() == nil)
        #expect(journal.isEmpty)
    }

    @Test("Journals with the same sequence of rallies are equal")
    func journalsWithSameRalliesAreEqual() {
        var one = RallyJournal()
        one.append(wonBy: .us)
        one.append(wonBy: .them)

        var another = RallyJournal()
        another.append(wonBy: .us)
        another.append(wonBy: .them)

        #expect(one == another)
    }

    @Test("The order of rallies matters")
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
