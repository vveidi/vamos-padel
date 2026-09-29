#if DEBUG

import Foundation
import PadelScoring
import PadelStorage

/// Every fixture is played through the engine rather than assembled from a
/// ready score: the score is computed from the journal (ADR-0001), so a
/// made-up course would check nothing.
extension SavedMatch {
    /// A match played at a rally a minute, so that the length of a preview
    /// match is the length of a real one — rallies and the walking between
    /// them included.
    static func preview(_ winners: [Side], ruleset: Ruleset, abandoned: Bool = false) -> SavedMatch {
        let start = Date(timeIntervalSinceNow: -3 * 24 * 60 * 60)

        var saved = SavedMatch(match: Match(ruleset: ruleset), startedAt: start)

        for (played, winner) in winners.enumerated() {
            saved.record(
                rallyWonBy: winner, at: start.addingTimeInterval(TimeInterval(played) * 60))
        }

        if abandoned { saved.abandon() }

        return saved
    }

    static func preview(classicWonBy winner: Side) -> SavedMatch {
        .preview(
            games(
                Array(repeating: [winner.opposite, winner], count: 4).flatMap { $0 }
                    + [winner, winner]),
            ruleset: .classic(setsToWin: 1, goldenPoint: true))
    }

    static func preview(twoSetsWonBy winner: Side) -> SavedMatch {
        let other = winner.opposite

        let firstSet =
            games(Array(repeating: [winner, other], count: 6).flatMap { $0 })
            + Array(repeating: [winner, other], count: 5).flatMap { $0 }
            + [winner, winner]

        let secondSet = games([winner, other, winner, other, winner, other, winner, winner, winner])

        return .preview(firstSet + secondSet, ruleset: .classic(setsToWin: 2, goldenPoint: true))
    }

    static var previewClassicAbandoned: SavedMatch {
        .preview(
            games([.us, .them, .us, .us, .them]) + [.us, .us, .us],
            ruleset: .classic(setsToWin: 1, goldenPoint: true),
            abandoned: true)
    }

    static var previewAbandonedInSecondSet: SavedMatch {
        .preview(
            games(Array(repeating: Side.us, count: 6)) + [.them, .them],
            ruleset: .classic(setsToWin: 2, goldenPoint: true),
            abandoned: true)
    }

    static var previewAbandonedInTieBreak: SavedMatch {
        .preview(
            games(Array(repeating: [Side.us, .them], count: 6).flatMap { $0 })
                + [.us, .us, .them, .us, .them],
            ruleset: .classic(setsToWin: 1, goldenPoint: true),
            abandoned: true)
    }

    static func preview(pointsTo target: Int, abandonedAfter stopped: Int? = nil) -> SavedMatch {
        var rallies = Array(repeating: [Side.us, .them], count: target - 2).flatMap { $0 }
        rallies.append(.us)
        rallies.append(.us)

        return .preview(
            Array(rallies.prefix(stopped ?? rallies.count)),
            ruleset: .pointsTo(target: target, serveChangesEvery: 4),
            abandoned: stopped != nil)
    }

    static var previewNothingPlayed: SavedMatch {
        .preview([], ruleset: .classic(setsToWin: 1, goldenPoint: true))
    }

    private static func games(_ winners: [Side]) -> [Side] {
        winners.flatMap { Array(repeating: $0, count: 4) }
    }
}

#endif
