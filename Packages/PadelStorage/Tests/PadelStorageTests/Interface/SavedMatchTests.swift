import Foundation
import PadelScoring
import Testing

@testable import PadelStorage

@Suite("Saved match")
struct SavedMatchTests {
    @Test("The match starts with its first rally, not with the app opening")
    func theMatchStartsWithItsFirstRally() {
        var saved = SavedMatch(match: Match(ruleset: .defaultClassic), scoring: .aloneOnWatch, startedAt: aMoment)

        saved.record(rallyWonBy: .us, at: aMoment.addingTimeInterval(10 * 60))

        #expect(saved.startedAt == aMoment.addingTimeInterval(10 * 60))
        #expect(saved.duration == 0)
    }

    @Test("The duration spans the first rally to the last")
    func theDurationSpansTheRallies() {
        var saved = SavedMatch.played([.us])

        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(75 * 60))

        #expect(saved.duration == 75 * 60)
    }

    @Test("A rally the engine did not accept does not lengthen the match")
    func aRejectedRallyDoesNotLengthenTheMatch() {
        var saved = SavedMatch.played(
            [.us, .us], ruleset: .pointsTo(target: 2, serveChangesEvery: 4))
        let finished = saved

        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(60 * 60))

        #expect(saved == finished)
    }

    @Test("An undo ends the match at the undo")
    func anUndoEndsTheMatchAtTheUndo() {
        var saved = SavedMatch.played([.us])

        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(75 * 60))
        saved.undo(at: aMoment.addingTimeInterval(80 * 60))

        #expect(saved.duration == 80 * 60)
    }

    @Test("Undoing the only rally returns the match to zero duration")
    func undoingTheOnlyRallyReturnsTheMatchToZero() {
        var saved = SavedMatch.played([.us])

        saved.undo(at: aMoment.addingTimeInterval(10 * 60))

        #expect(saved.match.journal.isEmpty)
        #expect(saved.duration == 0)
    }

    @Test("An undo on an abandoned match moves nothing")
    func anUndoOnAnAbandonedMatchMovesNothing() {
        var saved = SavedMatch.played([.us, .them])
        saved.abandon()
        let abandoned = saved

        saved.undo(at: aMoment.addingTimeInterval(60 * 60))

        #expect(saved == abandoned)
    }

    @Test("An undo on an empty journal moves nothing")
    func anUndoOnAnEmptyJournalMovesNothing() {
        var saved = SavedMatch(match: Match(ruleset: .defaultClassic), scoring: .aloneOnWatch, startedAt: aMoment)
        let untouched = saved

        saved.undo(at: aMoment.addingTimeInterval(60 * 60))

        #expect(saved == untouched)
    }

    @Test("Stopping a match does not move the clock")
    func stoppingAMatchDoesNotMoveTheClock() {
        var saved = SavedMatch.played([.us])

        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(30 * 60))
        saved.abandon()

        #expect(saved.duration == 30 * 60)
        #expect(saved.match.isAbandoned)
    }
}
