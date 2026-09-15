import Foundation
import PadelScoring
import Testing

@testable import PadelStorage

@Suite("Saved match")
struct SavedMatchTests {
    /// A match is the play from the first rally, not from the app launching.
    /// Between "opened it on court" and "served" there is a warm-up, and
    /// counting that into the match's duration means lying in the history on
    /// the phone (ticket 11).
    @Test("The match starts with its first rally, not with the app opening")
    func theMatchStartsWithItsFirstRally() {
        var saved = SavedMatch(match: Match(ruleset: .defaultClassic), startedAt: aMoment)

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

    /// A tap out of habit after the last point is not accepted by the engine,
    /// and it must not move the time either: otherwise a finished match would
    /// keep growing longer while the outcome screen hangs before your eyes.
    @Test("A rally the engine did not accept does not lengthen the match")
    func aRejectedRallyDoesNotLengthenTheMatch() {
        var saved = SavedMatch.played(
            [.us, .us], ruleset: .pointsTo(target: 2, serveChangesEvery: 4))
        let finished = saved

        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(60 * 60))

        #expect(saved == finished)
    }

    /// The rally is gone from the journal, so the match can no longer be
    /// measured to it. The undo is the closest moment the journal knows of:
    /// rallies carry no time (ADR-0001), and the moment of the rally now last
    /// is not written down anywhere.
    @Test("An undo ends the match at the undo")
    func anUndoEndsTheMatchAtTheUndo() {
        var saved = SavedMatch.played([.us])

        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(75 * 60))
        saved.undo(at: aMoment.addingTimeInterval(80 * 60))

        #expect(saved.duration == 80 * 60)
    }

    /// The initializer promises a match without a single rally has no
    /// duration, and an emptied journal has to keep that promise too.
    @Test("Undoing the only rally returns the match to zero duration")
    func undoingTheOnlyRallyReturnsTheMatchToZero() {
        var saved = SavedMatch.played([.us])

        saved.undo(at: aMoment.addingTimeInterval(10 * 60))

        #expect(saved.match.journal.isEmpty)
        #expect(saved.duration == 0)
    }

    /// Undo does not lift a stopped match back into play, so there is nothing
    /// for the clock to follow.
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
        var saved = SavedMatch(match: Match(ruleset: .defaultClassic), startedAt: aMoment)
        let untouched = saved

        saved.undo(at: aMoment.addingTimeInterval(60 * 60))

        #expect(saved == untouched)
    }

    /// Stopping appends no rally: a match cut short lasted until its last
    /// point, not until the moment it was stopped.
    @Test("Stopping a match does not move the clock")
    func stoppingAMatchDoesNotMoveTheClock() {
        var saved = SavedMatch.played([.us])

        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(30 * 60))
        saved.abandon()

        #expect(saved.duration == 30 * 60)
        #expect(saved.match.isAbandoned)
    }
}
