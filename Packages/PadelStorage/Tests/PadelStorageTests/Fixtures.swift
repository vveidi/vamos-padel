import Foundation
import PadelScoring

@testable import PadelStorage

/// A round second on purpose: GRDB stores time to millisecond precision, and
/// `Date()` with its fractions of a microsecond would not come back from the
/// database as the same value.
let aMoment = Date(timeIntervalSince1970: 1_800_000_000)

let toTwo = Ruleset.pointsTo(target: 2, serveChangesEvery: 4)

extension SavedMatch {
    /// The listed rallies, played one per second from `start`.
    static func played(
        _ winners: [Side],
        ruleset: Ruleset = .defaultPointsTo,
        firstServer: Side = .us,
        scoring: MatchScoring = .aloneOnWatch,
        from start: Date = aMoment
    ) -> SavedMatch {
        var saved = SavedMatch(
            match: Match(ruleset: ruleset, firstServer: firstServer), scoring: scoring,
            startedAt: start)

        for (played, winner) in winners.enumerated() {
            saved.record(rallyWonBy: winner, at: start.addingTimeInterval(TimeInterval(played)))
        }

        return saved
    }
}
