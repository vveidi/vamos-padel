#if DEBUG

import Foundation
import PadelScoring
import PadelStorage

/// The matches the previews are drawn from.
///
/// Every one of them goes through the engine rather than being assembled from
/// a ready score, because there is no way to assemble one: the score is
/// computed from the rally journal (ADR-0001), and a preview showing a score
/// nobody could have played is worth nothing. What a preview is really
/// checking here is the course of the score — and a made-up course would check
/// nothing at all.
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

        if abandoned { saved.match.abandon() }

        return saved
    }

    /// A single set taken 6 : 4 — six games to the winner, four to the other
    /// side, four straight points in each.
    static func preview(classicWonBy winner: Side) -> SavedMatch {
        .preview(
            games(
                Array(repeating: [winner.opposite, winner], count: 4).flatMap { $0 }
                    + [winner, winner]),
            ruleset: .classic(setsToWin: 1, goldenPoint: true))
    }

    /// A match to two sets, the first of them taken on a tiebreak: the longest
    /// thing the card has to draw, and the only place its tiebreak line shows
    /// up.
    static func preview(twoSetsWonBy winner: Side) -> SavedMatch {
        let other = winner.opposite

        let firstSet =
            games(Array(repeating: [winner, other], count: 6).flatMap { $0 })
            + Array(repeating: [winner, other], count: 5).flatMap { $0 }
            + [winner, winner]

        let secondSet = games([winner, other, winner, other, winner, other, winner, winner, winner])

        return .preview(firstSet + secondSet, ruleset: .classic(setsToWin: 2, goldenPoint: true))
    }

    /// A match stopped in the middle of a game: the card has to show both that
    /// the match was not played out and where inside a game it was left.
    static var previewClassicAbandoned: SavedMatch {
        .preview(
            games([.us, .them, .us, .us, .them]) + [.us, .us, .us],
            ruleset: .classic(setsToWin: 1, goldenPoint: true),
            abandoned: true)
    }

    /// A match to two sets stopped two rallies into the second one: the case
    /// where "the game was not finished" has to hang off the set play actually
    /// stopped in, and not off the one before it, which was played out 6:0.
    static var previewAbandonedInSecondSet: SavedMatch {
        .preview(
            games(Array(repeating: Side.us, count: 6)) + [.them, .them],
            ruleset: .classic(setsToWin: 2, goldenPoint: true),
            abandoned: true)
    }

    /// A match stopped inside a tiebreak — the one game of a set whose points
    /// are not a game's, and which must not be called a game.
    static var previewAbandonedInTieBreak: SavedMatch {
        .preview(
            games(Array(repeating: [Side.us, .them], count: 6).flatMap { $0 })
                + [.us, .us, .them, .us, .them],
            ruleset: .classic(setsToWin: 1, goldenPoint: true),
            abandoned: true)
    }

    /// A match to N points, taken by one point — the closest thing there is to
    /// a "16 : 14" that looks like a tennis score.
    static func preview(pointsTo target: Int, abandonedAfter stopped: Int? = nil) -> SavedMatch {
        var rallies = Array(repeating: [Side.us, .them], count: target - 2).flatMap { $0 }
        rallies.append(.us)
        rallies.append(.us)

        return .preview(
            Array(rallies.prefix(stopped ?? rallies.count)),
            ruleset: .pointsTo(target: target, serveChangesEvery: 4),
            abandoned: stopped != nil)
    }

    /// The rallies by which the listed sides each win a game to love — four
    /// points in a row. A game to love is the shortest there is, which is why
    /// the long journals are built out of it.
    private static func games(_ winners: [Side]) -> [Side] {
        winners.flatMap { Array(repeating: $0, count: 4) }
    }
}

#endif
