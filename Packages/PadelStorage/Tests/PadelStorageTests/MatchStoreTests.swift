import Foundation
import PadelScoring
import Testing

@testable import PadelStorage

@Suite("Match store")
struct MatchStoreTests {
    /// The round trip is the store's central check: the rally journal is the
    /// single stored truth about a match (ADR-0001), and if it came back from
    /// the database changed, everything else is computed from somebody else's
    /// data.
    ///
    /// The ruleset is checked along with the journal, and in both cases: it is
    /// spread across columns, each case owning its half, and mixing them up
    /// means reading "16:14" as a tennis score.
    @Test(
        "A saved match reads back with the same journal and ruleset",
        arguments: [
            Ruleset.classic(setsToWin: 2, goldenPoint: true),
            .classic(setsToWin: 1, goldenPoint: false),
            .pointsTo(target: 16, serveChangesEvery: 4),
            .pointsTo(target: 21, serveChangesEvery: 2),
        ])
    func aSavedMatchReadsBackUnchanged(ruleset: Ruleset) throws {
        let store = try SQLiteMatchStore.inMemory()
        let saved = SavedMatch.played([.us, .them, .them, .us, .us], ruleset: ruleset)

        try store.save(saved)

        #expect(try store.matchInProgress() == saved)
    }

    @Test("The first server reads back", arguments: [Side.us, .them])
    func theFirstServerReadsBack(firstServer: Side) throws {
        let store = try SQLiteMatchStore.inMemory()
        let saved = SavedMatch.played([.us, .them], firstServer: firstServer)

        try store.save(saved)

        #expect(try store.matchInProgress()?.match.firstServer == firstServer)
    }

    @Test("The match's start and duration read back")
    func theStartAndDurationReadBack() throws {
        let store = try SQLiteMatchStore.inMemory()
        var saved = SavedMatch.played([.us])
        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(90 * 60))

        try store.save(saved)

        let restored = try #require(try store.matchInProgress())

        #expect(restored.startedAt == aMoment)
        #expect(restored.duration == 90 * 60)
    }

    /// The very criterion the store exists for: a match interrupted halfway is
    /// already written — there would be nothing to write it with at the end,
    /// since no end happened.
    @Test("The journal is written after every rally, not at the end of the match")
    func theJournalIsWrittenAfterEveryRally() throws {
        let store = try SQLiteMatchStore.inMemory()
        var saved = SavedMatch(match: Match(ruleset: .defaultClassic), startedAt: aMoment)

        for (played, winner) in [Side.us, .them, .us, .us].enumerated() {
            saved.record(rallyWonBy: winner, at: aMoment.addingTimeInterval(TimeInterval(played)))
            try store.save(saved)

            let restored = try store.matchInProgress()

            #expect(restored?.match.journal.count == played + 1)
            #expect(restored?.match == saved.match)
        }
    }

    /// A write works as "cut off what was undone, append what is missing", and
    /// it is checked where the journal first shortens and then grows again: an
    /// undone rally has to disappear rather than lie past the end of the
    /// journal waiting for the next point.
    @Test("Undone rallies leave the database")
    func undoneRalliesLeaveTheDatabase() throws {
        let store = try SQLiteMatchStore.inMemory()
        var saved = SavedMatch.played([.us, .us, .them, .them])
        try store.save(saved)

        saved.match.undo()
        saved.match.undo()
        try store.save(saved)

        #expect(try store.matchInProgress()?.match.journal.rallies == [Rally(wonBy: .us), Rally(wonBy: .us)])

        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(10))
        try store.save(saved)

        #expect(try store.matchInProgress()?.match == saved.match)
    }

    @Test("Undoing down to an empty journal leaves no rally in the database")
    func undoingEverythingLeavesNoRallies() throws {
        let store = try SQLiteMatchStore.inMemory()
        var saved = SavedMatch.played([.us, .them])

        try store.save(saved)
        saved.match.undo()
        saved.match.undo()
        try store.save(saved)

        #expect(try store.matchInProgress()?.match.journal.isEmpty == true)
    }

    @Test("An empty store has nothing to continue")
    func anEmptyStoreHasNothingToContinue() throws {
        #expect(try SQLiteMatchStore.inMemory().matchInProgress() == nil)
    }

    @Test("A finished match is not offered for continuation")
    func aFinishedMatchIsNotOfferedForContinuation() throws {
        let store = try SQLiteMatchStore.inMemory()
        let saved = SavedMatch.played([.us, .us], ruleset: toTwo)

        try store.save(saved)

        #expect(saved.match.state.outcome == .finished(winner: .us))
        #expect(try store.matchInProgress() == nil)
    }

    /// Being unfinished is asked of the last match, not of every match in
    /// turn: one left at 3:2 a month ago must not rise from the dead on court
    /// in place of a new one.
    @Test("The latest match is continued, not a forgotten one from before")
    func onlyTheLatestMatchIsContinued() throws {
        let store = try SQLiteMatchStore.inMemory()
        let abandonedLongAgo = SavedMatch.played([.us, .them])
        let finishedToday = SavedMatch.played(
            [.us, .us],
            ruleset: .pointsTo(target: 2, serveChangesEvery: 4),
            from: aMoment.addingTimeInterval(30 * 24 * 3600))

        try store.save(abandonedLongAgo)
        try store.save(finishedToday)

        #expect(try store.matchInProgress() == nil)
    }

    @Test("A new match does not overwrite the previous one")
    func aNewMatchDoesNotOverwriteTheOldOne() throws {
        let store = try SQLiteMatchStore.inMemory()
        let finishedYesterday = SavedMatch.played(
            [.us, .us], ruleset: .pointsTo(target: 2, serveChangesEvery: 4))
        let startedToday = SavedMatch.played(
            [.them], from: aMoment.addingTimeInterval(24 * 3600))

        try store.save(finishedYesterday)
        try store.save(startedToday)

        #expect(try store.matchInProgress() == startedToday)
    }

    /// Relaunching the app is a new connection to the same database and
    /// nothing more: the store keeps no match in memory, so the second
    /// connection sees exactly what the first one wrote.
    @Test("The match carries on after the app is relaunched")
    func theMatchSurvivesARelaunch() throws {
        let database = "relaunch-\(UUID().uuidString)"
        let store = try SQLiteMatchStore.inMemory(named: database)
        let saved = SavedMatch.played([.us, .them, .us])

        try store.save(saved)

        let afterRelaunch = try SQLiteMatchStore.inMemory(named: database)

        #expect(try afterRelaunch.matchInProgress() == saved)
    }

    /// The abandoned mark is the only thing about a match kept in a column,
    /// and it is checked through what it exists for: before stopping, the match
    /// is offered for continuation; afterwards it is not. The check catches
    /// both legs of the trip at once. Had the mark not been written, the match
    /// would come back from the database half-abandoned and land on court
    /// again; had it not been read, the same.
    ///
    /// The stop arrives after the match has already been written by its first
    /// rally, so the mark has to travel as a row update and not by an insert
    /// alone.
    @Test("A stopped match is saved abandoned and not offered for continuation")
    func anAbandonedMatchIsSavedAndNotOfferedForContinuation() throws {
        let store = try SQLiteMatchStore.inMemory()
        var saved = SavedMatch.played([.us, .them, .us])

        try store.save(saved)

        #expect(try store.matchInProgress() == saved)

        saved.match.abandon()
        try store.save(saved)

        #expect(saved.match.state.outcome == .abandoned)
        #expect(try store.matchInProgress() == nil)
    }

    /// The relaunch here is not decoration: without it the mark would be
    /// visible from a row nobody had re-read.
    @Test("The abandoned mark survives a relaunch of the app")
    func theAbandonedMarkSurvivesARelaunch() throws {
        let database = "abandoned-\(UUID().uuidString)"
        let store = try SQLiteMatchStore.inMemory(named: database)
        var saved = SavedMatch.played([.us, .them, .us])
        try store.save(saved)

        saved.match.abandon()
        try store.save(saved)

        let afterRelaunch = try SQLiteMatchStore.inMemory(named: database)

        #expect(try afterRelaunch.match(id: saved.id) == saved)
        #expect(try afterRelaunch.matchInProgress() == nil)
    }

    /// The round trip of an abandoned match is what the spec demands of
    /// Seam 2: "a saved match reads back with the same journal, ruleset and
    /// abandoned mark". Comparing the whole thing checks all three at once,
    /// and the journal matters most here: an hour of play must not be lost just
    /// because the court time ran out.
    ///
    /// The stop arrives after the match has already been written by its first
    /// rally, so the mark has to travel as a row update and not by an insert
    /// alone.
    @Test(
        "An abandoned match reads back with its journal, ruleset and mark",
        arguments: [
            Ruleset.classic(setsToWin: 2, goldenPoint: true),
            .pointsTo(target: 16, serveChangesEvery: 4),
        ])
    func anAbandonedMatchReadsBackUnchanged(ruleset: Ruleset) throws {
        let store = try SQLiteMatchStore.inMemory()
        var saved = SavedMatch.played([.us, .them, .us, .us], ruleset: ruleset)
        try store.save(saved)

        saved.match.abandon()
        try store.save(saved)

        let restored = try #require(try store.match(id: saved.id))

        #expect(restored == saved)
        #expect(restored.match.isAbandoned)
        #expect(
            restored.match.journal.rallies
                == [Rally(wonBy: .us), Rally(wonBy: .them), Rally(wonBy: .us), Rally(wonBy: .us)])
        #expect(restored.match.ruleset == ruleset)
    }

    @Test("A match that was never written is not in the store")
    func anUnknownMatchIsNotFound() throws {
        #expect(try SQLiteMatchStore.inMemory().match(id: UUID()) == nil)
    }

    // MARK: The previous match's rules

    /// Why the start screen asks the store at all: a group plays by the same
    /// rules for months, and setting them afresh every time is a tax paid for
    /// something that happens twice a year.
    @Test(
        "The previous match's rules are remembered",
        arguments: [
            Ruleset.classic(setsToWin: 2, goldenPoint: false),
            .classic(setsToWin: 1, goldenPoint: true),
            .pointsTo(target: 21, serveChangesEvery: 2),
        ])
    func theLastRulesetIsRemembered(ruleset: Ruleset) throws {
        let store = try SQLiteMatchStore.inMemory()

        try store.save(SavedMatch.played([.us, .them], ruleset: ruleset))

        #expect(try store.lastRuleset() == ruleset)
    }

    /// A finished match is not offered for continuation, but its rules are:
    /// that is the ordinary case — the next match is started after the last one
    /// was played out.
    @Test("The rules are remembered from a finished match too")
    func theRulesetOfAFinishedMatchIsRemembered() throws {
        let store = try SQLiteMatchStore.inMemory()
        let ruleset = Ruleset.pointsTo(target: 2, serveChangesEvery: 4)

        try store.save(SavedMatch.played([.us, .us], ruleset: ruleset))

        #expect(try store.matchInProgress() == nil)
        #expect(try store.lastRuleset() == ruleset)
    }

    @Test("The rules remembered are the previous match's, not the one before")
    func theRulesetComesFromTheLatestMatch() throws {
        let store = try SQLiteMatchStore.inMemory()
        let today = Ruleset.classic(setsToWin: 3, goldenPoint: false)

        try store.save(SavedMatch.played([.us], ruleset: .defaultPointsTo))
        try store.save(
            SavedMatch.played(
                [.them], ruleset: today, from: aMoment.addingTimeInterval(24 * 3600)))

        #expect(try store.lastRuleset() == today)
    }

    /// The very criterion: the settings survive a relaunch of the app. A
    /// second connection to the same database is that relaunch.
    @Test("The previous match's rules survive a relaunch of the app")
    func theLastRulesetSurvivesARelaunch() throws {
        let database = "ruleset-\(UUID().uuidString)"
        let ruleset = Ruleset.pointsTo(target: 24, serveChangesEvery: 6)

        let store = try SQLiteMatchStore.inMemory(named: database)
        try store.save(SavedMatch.played([.us, .them], ruleset: ruleset))

        let afterRelaunch = try SQLiteMatchStore.inMemory(named: database)

        #expect(try afterRelaunch.lastRuleset() == ruleset)
    }

    /// The first match on a new watch: there is nothing to fill in, and the
    /// start screen shows the defaults.
    @Test("An empty store remembers no previous ruleset")
    func anEmptyStoreRemembersNoRuleset() throws {
        #expect(try SQLiteMatchStore.inMemory().lastRuleset() == nil)
    }

    // MARK: History

    @Test("History is handed back from the freshest match to the oldest")
    func historyStartsWithTheFreshestMatch() throws {
        let store = try SQLiteMatchStore.inMemory()
        let earlier = SavedMatch.played([.us, .them])
        let later = SavedMatch.played([.them], from: aMoment.addingTimeInterval(3600))

        try store.save(earlier)
        try store.save(later)

        #expect(try store.matches() == [later, earlier])
    }

    @Test("An empty store has no history")
    func anEmptyStoreHasNoHistory() throws {
        #expect(try SQLiteMatchStore.inMemory().matches().isEmpty)
    }

    /// The reason the history is watched rather than read: on the phone a
    /// match is written by the reception, into an app woken by the system
    /// (ticket 10). Nobody tells the screen, and a list read once would go on
    /// showing yesterday's matches with today's lying beside it in the
    /// database.
    ///
    /// The first value is waited for before the second match is written, and
    /// not out of politeness: by the time it arrives the observation is
    /// watching, so the write that follows is one it cannot miss.
    @Test("A match written into the store arrives into the observed history")
    func aWrittenMatchArrivesIntoTheObservedHistory() async throws {
        let store = try SQLiteMatchStore.inMemory()
        let earlier = SavedMatch.played([.us, .them])

        try store.save(earlier)

        var history = store.matchesObserved().makeAsyncIterator()

        #expect(try await history.next() == [earlier])

        let later = SavedMatch.played([.them], from: aMoment.addingTimeInterval(3600))

        try store.save(later)

        #expect(try await history.next() == [later, earlier])
    }

    /// The empty history is a value like any other: without it the screen
    /// would have nothing to tell "there are no matches yet" from "the store
    /// has not answered yet", and it shows different things for the two.
    @Test("The observed history of an empty store starts empty")
    func theObservedHistoryOfAnEmptyStoreStartsEmpty() async throws {
        let store = try SQLiteMatchStore.inMemory()

        var history = store.matchesObserved().makeAsyncIterator()

        #expect(try await history.next() == [])
    }

    /// A match replayed after a point was undone is no continuation of the
    /// previous version but a different journal of the same length. Appending
    /// it as a tail would mean assembling a journal nobody played, and doing so
    /// silently: the length adds up. This happens on the phone, where the match
    /// arrives a second time (ticket 10).
    @Test("A diverged journal is rewritten, not appended to")
    func aDivergedJournalIsRewritten() throws {
        let store = try SQLiteMatchStore.inMemory()

        var saved = SavedMatch.played([.us, .us, .us])
        try store.save(saved)

        saved.match.undo()
        saved.match.undo()
        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(60))
        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(90))

        try store.save(saved)

        #expect(try store.match(id: saved.id) == saved)
    }

    // MARK: The delivery queue

    /// The delivery queue is the store itself, not a list beside it: what is
    /// already written after every rally need not be copied into a second
    /// queue, which would diverge from the first.
    @Test("A finished match awaits delivery")
    func aFinishedMatchAwaitsDelivery() throws {
        let store = try SQLiteMatchStore.inMemory()
        let saved = SavedMatch.played([.us, .us], ruleset: toTwo)

        try store.save(saved)

        #expect(try store.matchesAwaitingDelivery() == [saved])
    }

    @Test("A match in progress awaits nothing")
    func aMatchInProgressAwaitsNothing() throws {
        let store = try SQLiteMatchStore.inMemory()

        try store.save(SavedMatch.played([.us]))

        #expect(try store.matchesAwaitingDelivery().isEmpty)
    }

    /// An abandoned match is over too: play in it has ended, and its place in
    /// the history on the phone is alongside the rest.
    @Test("An abandoned match awaits delivery")
    func anAbandonedMatchAwaitsDelivery() throws {
        let store = try SQLiteMatchStore.inMemory()
        var saved = SavedMatch.played([.us, .them])
        saved.match.abandon()

        try store.save(saved)

        #expect(try store.matchesAwaitingDelivery() == [saved])
    }

    @Test("A match marked delivered leaves the queue")
    func aDeliveredMatchLeavesTheQueue() throws {
        let store = try SQLiteMatchStore.inMemory()
        let saved = SavedMatch.played([.us, .us], ruleset: toTwo)

        try store.save(saved)
        try store.markDelivered(saved)

        #expect(try store.matchesAwaitingDelivery().isEmpty)
    }

    /// The delivery mark is cleared by any write of the match: what stayed
    /// delivered is a version that from this moment diverges from the one on
    /// the watch.
    @Test("A match changed after delivery returns to the queue")
    func aChangedMatchReturnsToTheQueue() throws {
        let store = try SQLiteMatchStore.inMemory()
        var saved = SavedMatch.played([.us, .us], ruleset: toTwo)

        try store.save(saved)
        try store.markDelivered(saved)

        saved.match.abandon()
        try store.save(saved)

        #expect(try store.matchesAwaitingDelivery() == [saved])
    }

    /// A match begins with its first rally — that is how the glossary defines
    /// it. One stopped earlier is saved honestly, but it has no business in the
    /// history on the phone.
    @Test("A match without a single rally awaits nothing")
    func aMatchWithoutRalliesAwaitsNothing() throws {
        let store = try SQLiteMatchStore.inMemory()
        var empty = SavedMatch(match: Match(ruleset: toTwo), startedAt: aMoment)
        empty.match.abandon()

        try store.save(empty)

        #expect(empty.match.state.outcome.isOver)
        #expect(try store.matchesAwaitingDelivery().isEmpty)
    }

    /// What gets delivered is a version, not a match: a receipt for a previous
    /// version has no right to clear the queue the match returned to after a
    /// point was undone.
    @Test("A stale delivery of a previous version is not marked")
    func aStaleDeliveryIsNotMarked() throws {
        let store = try SQLiteMatchStore.inMemory()
        var saved = SavedMatch.played([.us, .us], ruleset: toTwo)

        try store.save(saved)

        let delivered = saved
        saved.match.undo()
        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(60))
        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(90))
        try store.save(saved)

        try store.markDelivered(delivered)

        #expect(try store.matchesAwaitingDelivery() == [saved])
    }

    @Test("Delivery is marked on the match it was promised to")
    func onlyTheNamedMatchIsMarkedDelivered() throws {
        let store = try SQLiteMatchStore.inMemory()
        let delivered = SavedMatch.played([.us, .us], ruleset: toTwo)
        let waiting = SavedMatch.played(
            [.them, .them], ruleset: toTwo, from: aMoment.addingTimeInterval(3600))

        try store.save(delivered)
        try store.save(waiting)
        try store.markDelivered(delivered)

        #expect(try store.matchesAwaitingDelivery() == [waiting])
    }
}
