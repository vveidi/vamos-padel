import Foundation
import PadelScoring

@testable import PadelStorage

/// The moment the matches in these tests start from.
///
/// A round second on purpose: GRDB stores time to millisecond precision, and
/// `Date()` with its fractions of a microsecond would not come back from the
/// database as the same value. That precision is more than a match needs, and
/// the test cares more about the round trip.
let aMoment = Date(timeIntervalSince1970: 1_800_000_000)

/// The match ends on the second point: two rallies are enough for tests that
/// care that the match ended, not about the score it ended on.
let toTwo = Ruleset.pointsTo(target: 2, serveChangesEvery: 4)

extension SavedMatch {
    /// A match in which the listed rallies were played, one per second.
    static func played(
        _ winners: [Side],
        ruleset: Ruleset = .defaultPointsTo,
        firstServer: Side = .us,
        from start: Date = aMoment
    ) -> SavedMatch {
        var saved = SavedMatch(
            match: Match(ruleset: ruleset, firstServer: firstServer), startedAt: start)

        for (played, winner) in winners.enumerated() {
            saved.record(rallyWonBy: winner, at: start.addingTimeInterval(TimeInterval(played)))
        }

        return saved
    }
}
