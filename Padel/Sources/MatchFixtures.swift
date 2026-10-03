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
    static func preview(
        _ winners: [Side], ruleset: Ruleset, abandoned: Bool = false,
        firstServer: Side = .us,
        startedAt start: Date = Date(timeIntervalSinceNow: -3 * 24 * 60 * 60)
    ) -> SavedMatch {
        var saved = SavedMatch(
            match: Match(ruleset: ruleset, firstServer: firstServer), scoring: .aloneOnPhone,
            startedAt: start)

        for (played, winner) in winners.enumerated() {
            saved.record(
                rallyWonBy: winner, at: start.addingTimeInterval(TimeInterval(played) * 60))
        }

        if abandoned { saved.abandon() }

        return saved
    }

    var asPaired: SavedMatch {
        SavedMatch(
            id: id, match: match, scoring: .paired, startedAt: startedAt, lastRallyAt: lastRallyAt)
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

    // MARK: Matches still in play

    static var previewInPlay: SavedMatch {
        .preview(
            games([.us, .them, .us]) + [.us, .us, .them],
            ruleset: .classic(setsToWin: 1, goldenPoint: false), startedAt: .previewKickOff)
    }

    static func preview(justAfterARallyTo side: Side) -> SavedMatch {
        .preview(
            games([.us, .them, .us]) + [side.opposite, side],
            ruleset: .classic(setsToWin: 1, goldenPoint: false), startedAt: .previewKickOff)
    }

    /// The rally that took the game is the last one in its journal.
    static func preview(justAfterAGameTo side: Side) -> SavedMatch {
        .preview(
            games([side.opposite, side, side.opposite, side]),
            ruleset: .classic(setsToWin: 1, goldenPoint: false), startedAt: .previewKickOff)
    }

    static var previewInTieBreak: SavedMatch {
        .preview(
            games(Array(repeating: [Side.us, .them], count: 6).flatMap { $0 })
                + [.us, .us, .them, .us, .them, .them, .us],
            ruleset: .classic(setsToWin: 1, goldenPoint: true), startedAt: .previewKickOff)
    }

    /// Three points each with a golden point in force, which is the one state
    /// where the engine has no serving half to hand over.
    static var previewAtGoldenPoint: SavedMatch {
        .preview(
            games([.us, .them]) + [.us, .us, .us, .them, .them, .them],
            ruleset: .classic(setsToWin: 2, goldenPoint: true), startedAt: .previewKickOff)
    }

    static var previewInSecondSet: SavedMatch {
        .preview(
            games(Array(repeating: Side.us, count: 6)) + games([.them, .us]) + [.them, .them],
            ruleset: .classic(setsToWin: 2, goldenPoint: true), startedAt: .previewKickOff)
    }

    static var previewCountingPoints: SavedMatch {
        .preview(
            Array(repeating: [Side.us, .them], count: 5).flatMap { $0 } + [.us, .us],
            ruleset: .pointsTo(target: 16, serveChangesEvery: 4), startedAt: .previewKickOff)
    }

    // MARK: One serve each, for the four corners

    /// The server's own half, which the engine alternates rally by rally: the
    /// first serve of a game is from the right and the second from the left.
    static func preview(serving side: Side, from half: ServingHalf) -> SavedMatch {
        .preview(
            half == .right ? [] : [side],
            ruleset: .classic(setsToWin: 1, goldenPoint: false),
            firstServer: side, startedAt: .previewKickOff)
    }

    private static func games(_ winners: [Side]) -> [Side] {
        winners.flatMap { Array(repeating: $0, count: 4) }
    }
}

extension Date {
    /// A match in play began this long ago, so a preview of the scoreboard
    /// carries a clock reading like a real one's rather than like Tuesday's.
    static var previewKickOff: Date { Date(timeIntervalSinceNow: -48 * 60) }
}

#endif
