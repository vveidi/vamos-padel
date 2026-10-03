import Foundation
import PadelLogging
import PadelScoring
import PadelStorage

/// The match's own lines, worded once for whichever device holds it: a rally
/// at `debug`, everything else at `info`.
public struct MatchLog: Sendable {
    private let logger: PadelLogger

    public init(subsystem: String) {
        logger = PadelLogger(subsystem: subsystem, category: "match")
    }

    public func started(_ saved: SavedMatch) {
        logger.info("the match started: \(Self.setUp(of: saved)); \(saved.id)")
    }

    public func joined(_ saved: SavedMatch) {
        logger.info("the phone's match was taken up: \(Self.setUp(of: saved)); \(saved.id)")
    }

    public func restored(_ saved: SavedMatch) {
        logger.info(
            "an unfinished match was taken back: \(Self.setUp(of: saved)), at \(Self.score(of: saved.match)); \(saved.id)"
        )
    }

    /// Says nothing when the journal and the outcome are both as they were.
    public func changed(from before: SavedMatch, to after: SavedMatch) {
        let rallies = after.match.journal.count - before.match.journal.count

        if rallies > 0, let last = after.match.journal.last {
            let won = rallies == 1 ? "rally won" : "\(rallies) rallies, the last won"
            logger.debug("\(won) by \(last.winner.rawValue): \(Self.score(of: after.match))")
        } else if rallies < 0 {
            logger.debug("a rally was undone: \(Self.score(of: after.match))")
        }

        guard !before.match.state.outcome.isOver, after.match.state.outcome.isOver else { return }

        logger.info(Self.ending(of: after))
    }

    static func setUp(of saved: SavedMatch) -> String {
        let match = saved.match

        return "\(name(of: match.ruleset)), \(name(of: saved.scoring)), \(match.firstServer.rawValue) to serve"
    }

    static func name(of ruleset: Ruleset) -> String {
        switch ruleset {
        case .classic(let setsToWin, let goldenPoint):
            "classic, \(setsToWin) \(setsToWin == 1 ? "set" : "sets") to win, \(goldenPoint ? "golden point" : "advantage")"
        case .pointsTo(let target, let serveChangesEvery):
            "to \(target) points, serve changes every \(serveChangesEvery)"
        }
    }

    static func name(of scoring: MatchScoring) -> String {
        switch scoring {
        case .aloneOnWatch: "scored on the watch alone"
        case .aloneOnPhone: "scored on the phone alone"
        case .paired: "paired"
        }
    }

    /// Us first, them second, everywhere.
    static func score(of match: Match) -> String {
        let state = match.state
        let points = "\(state.points.label(for: .us))–\(state.points.label(for: .them))"

        guard let games = state.games else { return points }

        let sets = match.ruleset.isMultiSet ? state.sets.map { "sets \($0.us)–\($0.them), " } ?? "" : ""

        return "\(sets)games \(games.us)–\(games.them), points \(points)"
    }

    static func ending(of saved: SavedMatch) -> String {
        let state = saved.match.state
        let lasted = Duration.seconds(saved.duration).formatted(.time(pattern: .hourMinuteSecond))

        guard let winner = state.outcome.winner else {
            return "the match was abandoned at \(score(of: saved.match)) after \(lasted); \(saved.id)"
        }

        let final = "\(state.finalScore.us)–\(state.finalScore.them)"

        return "the match is over: won by \(winner.rawValue), \(final), after \(lasted); \(saved.id)"
    }
}
