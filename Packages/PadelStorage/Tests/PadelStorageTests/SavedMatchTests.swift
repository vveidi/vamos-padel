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
}
