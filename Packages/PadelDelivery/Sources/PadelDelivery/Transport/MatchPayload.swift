import Foundation
import PadelScoring
import PadelStorage

/// A dictionary of numbers, strings, dates and booleans is all
/// WatchConnectivity undertakes to carry, so the format is written key by key
/// rather than derived from `Codable`: the key strings are a contract with a
/// separately updated app, and a renamed field must not move them.
enum MatchPayload {
    static func encode(_ arrival: Arrival) -> [String: Any] {
        var payload: [String: Any]

        switch arrival {
        case .match(let saved), .receipt(let saved):
            payload = fields(of: saved)
        case .intent(let intent):
            payload = fields(of: intent)
        case .update(.match(let saved, let echo)):
            payload = fields(of: saved)
            if let echo { payload[Key.echo] = fields(of: echo) }
        case .update(.noMatch(let echo)):
            payload = [:]
            if let echo { payload[Key.echo] = fields(of: echo) }
        }

        payload[Key.kind] = arrival.kind
        return payload
    }

    static func decode(_ payload: [String: Any]) throws -> Arrival {
        switch payload[Key.kind] as? String {
        case Kind.match: .match(try savedMatch(from: payload))
        case Kind.receipt: .receipt(try savedMatch(from: payload))
        case Kind.intent: .intent(try intent(from: payload))
        case Kind.liveMatch:
            .update(.match(try savedMatch(from: payload), echo: try echo(in: payload)))
        case Kind.noMatch: .update(.noMatch(echo: try echo(in: payload)))
        case let kind:
            throw MatchPayloadError.unreadable(reason: "a parcel of kind \"\(kind ?? "—")\"")
        }
    }

    // MARK: The match

    private static func fields(of saved: SavedMatch) -> [String: Any] {
        fields(of: saved.match.ruleset).merging([
            Key.id: saved.id.uuidString,
            Key.firstServer: saved.match.firstServer.rawValue,
            Key.startedAt: saved.startedAt,
            Key.lastRallyAt: saved.lastRallyAt,
            Key.abandoned: saved.match.isAbandoned,
            Key.scoring: saved.scoring.rawValue,
            Key.rallies: saved.match.journal.rallies.map(\.winner.rawValue),
        ]) { _, field in field }
    }

    private static func savedMatch(from payload: [String: Any]) throws -> SavedMatch {
        guard let id = payload[Key.id] as? String, let id = UUID(uuidString: id) else {
            throw MatchPayloadError.unreadable(reason: "a parcel without a match identifier")
        }

        guard let startedAt = payload[Key.startedAt] as? Date,
            let lastRallyAt = payload[Key.lastRallyAt] as? Date
        else {
            throw MatchPayloadError.unreadable(reason: "a parcel without the match's times")
        }

        // Not defaulted: a parcel without a journal would decode into a 0:0
        // match rather than fail.
        guard let winners = payload[Key.rallies] as? [String],
            let isAbandoned = payload[Key.abandoned] as? Bool
        else {
            throw MatchPayloadError.unreadable(reason: "a parcel without a rally journal")
        }

        // Not defaulted: a match read as paired is one the remote takes over,
        // and one the watch scored, read as the phone's, would come back onto
        // the phone's court after a relaunch.
        guard let scoring = payload[Key.scoring] as? String,
            let scoring = MatchScoring(rawValue: scoring)
        else {
            throw MatchPayloadError.unreadable(reason: "a parcel that does not say how the match was scored")
        }

        let match = Match(
            ruleset: try ruleset(from: payload),
            firstServer: try side(named: payload[Key.firstServer] as? String),
            journal: RallyJournal(try winners.map { Rally(wonBy: try side(named: $0)) }),
            isAbandoned: isAbandoned)

        return SavedMatch(
            id: id, match: match, scoring: scoring, startedAt: startedAt, lastRallyAt: lastRallyAt)
    }

    private static func fields(of ruleset: Ruleset) -> [String: Any] {
        switch ruleset {
        case .classic(let setsToWin, let goldenPoint):
            [Key.ruleset: Kind.classic, Key.setsToWin: setsToWin, Key.goldenPoint: goldenPoint]
        case .pointsTo(let target, let serveChangesEvery):
            [Key.ruleset: Kind.pointsTo, Key.target: target, Key.serveChangesEvery: serveChangesEvery]
        }
    }

    private static func ruleset(from payload: [String: Any]) throws -> Ruleset {
        switch payload[Key.ruleset] as? String {
        case Kind.classic:
            guard let setsToWin = payload[Key.setsToWin] as? Int,
                let goldenPoint = payload[Key.goldenPoint] as? Bool
            else {
                throw MatchPayloadError.unreadable(reason: "classic scoring without its rules")
            }

            return .classic(setsToWin: setsToWin, goldenPoint: goldenPoint)
        case Kind.pointsTo:
            guard let target = payload[Key.target] as? Int,
                let every = payload[Key.serveChangesEvery] as? Int
            else {
                throw MatchPayloadError.unreadable(reason: "a match to N points without an N")
            }

            return .pointsTo(target: target, serveChangesEvery: every)
        case let kind:
            throw MatchPayloadError.unreadable(
                reason: "unknown ruleset \"\(kind ?? "—")\"")
        }
    }

    private static func side(named name: String?) throws -> Side {
        guard let name, let side = Side(rawValue: name) else {
            throw MatchPayloadError.unreadable(reason: "unknown side \"\(name ?? "—")\"")
        }

        return side
    }

    // MARK: The live link

    private static func fields(of intent: MatchIntent) -> [String: Any] {
        switch intent {
        case .start(let ruleset, let firstServer):
            fields(of: ruleset).merging([
                Key.intent: Kind.start, Key.firstServer: firstServer.rawValue,
            ]) { _, field in field }
        case .rally(let winner, let base):
            [Key.intent: Kind.rally, Key.winner: winner.rawValue, Key.base: base]
        case .undo(let base):
            [Key.intent: Kind.undo, Key.base: base]
        case .end(let base):
            [Key.intent: Kind.end, Key.base: base]
        case .scoringAlone:
            [Key.intent: Kind.scoringAlone]
        }
    }

    private static func intent(from payload: [String: Any]) throws -> MatchIntent {
        switch payload[Key.intent] as? String {
        case Kind.start:
            .start(
                ruleset: try ruleset(from: payload),
                firstServer: try side(named: payload[Key.firstServer] as? String))
        case Kind.rally:
            .rally(wonBy: try side(named: payload[Key.winner] as? String), base: try base(in: payload))
        case Kind.undo:
            .undo(base: try base(in: payload))
        case Kind.end:
            .end(base: try base(in: payload))
        case Kind.scoringAlone:
            .scoringAlone
        case let kind:
            throw MatchPayloadError.unreadable(reason: "an intent of kind \"\(kind ?? "—")\"")
        }
    }

    // Not defaulted: an intent read as formed against no rallies would be
    // taken by a scorer holding a fresh match.
    private static func base(in payload: [String: Any]) throws -> Int {
        guard let base = payload[Key.base] as? Int, base >= 0 else {
            throw MatchPayloadError.unreadable(reason: "an intent without the journal it was formed against")
        }

        return base
    }

    private static func fields(of echo: Echo) -> [String: Any] {
        fields(of: echo.intent).merging([Key.accepted: echo.accepted]) { _, field in field }
    }

    /// - Returns: `nil` only when the parcel carries no echo at all.
    private static func echo(in payload: [String: Any]) throws -> Echo? {
        guard let echo = payload[Key.echo] else { return nil }

        guard let echo = echo as? [String: Any], let accepted = echo[Key.accepted] as? Bool else {
            throw MatchPayloadError.unreadable(reason: "an echo without its verdict")
        }

        return Echo(intent: try intent(from: echo), accepted: accepted)
    }

    private enum Key {
        static let kind = "kind"
        static let id = "id"
        static let ruleset = "ruleset"
        static let setsToWin = "setsToWin"
        static let goldenPoint = "goldenPoint"
        static let target = "target"
        static let serveChangesEvery = "serveChangesEvery"
        static let firstServer = "firstServer"
        static let startedAt = "startedAt"
        static let lastRallyAt = "lastRallyAt"
        static let abandoned = "abandoned"
        static let scoring = "scoring"
        static let rallies = "rallies"

        static let intent = "intent"
        static let winner = "winner"
        static let base = "base"
        static let echo = "echo"
        static let accepted = "accepted"
    }

    fileprivate enum Kind {
        static let classic = "classic"
        static let pointsTo = "pointsTo"

        static let match = "match"
        static let receipt = "receipt"
        static let intent = "intent"
        static let liveMatch = "liveMatch"
        static let noMatch = "noMatch"

        static let start = "start"
        static let rally = "rally"
        static let undo = "undo"
        static let end = "end"
        static let scoringAlone = "scoringAlone"
    }
}

/// Both directions share one channel, so the parcel's `kind` key is all the
/// receiving side has to tell one of these from another.
enum Arrival: Equatable {
    case match(SavedMatch)

    /// The only thing that takes a match off the queue on the watch
    /// (ADR-0002).
    case receipt(SavedMatch)

    case intent(MatchIntent)
    case update(MatchUpdate)

    fileprivate var kind: String {
        switch self {
        case .match: MatchPayload.Kind.match
        case .receipt: MatchPayload.Kind.receipt
        case .intent: MatchPayload.Kind.intent
        case .update(.match): MatchPayload.Kind.liveMatch
        case .update(.noMatch): MatchPayload.Kind.noMatch
        }
    }
}

/// Only a pair of apps that drifted apart reaches this, and the parcel is
/// then dropped.
enum MatchPayloadError: Error, Equatable {
    case unreadable(reason: String)
}
