import Foundation
import PadelScoring
import PadelStorage

/// A dictionary of numbers, strings, dates and booleans is all
/// WatchConnectivity undertakes to carry, so the format is written key by key
/// rather than derived from `Codable`: the key strings are a contract with a
/// separately updated app, and a renamed field must not move them.
enum MatchPayload {
    static func encode(_ arrival: Arrival) -> [String: Any] {
        let saved = arrival.match

        var payload: [String: Any] = [
            Key.kind: arrival.kind,
            Key.id: saved.id.uuidString,
            Key.firstServer: saved.match.firstServer.rawValue,
            Key.startedAt: saved.startedAt,
            Key.lastRallyAt: saved.lastRallyAt,
            Key.abandoned: saved.match.isAbandoned,
            Key.rallies: saved.match.journal.rallies.map(\.winner.rawValue),
        ]

        switch saved.match.ruleset {
        case .classic(let setsToWin, let goldenPoint):
            payload[Key.ruleset] = Kind.classic
            payload[Key.setsToWin] = setsToWin
            payload[Key.goldenPoint] = goldenPoint
        case .pointsTo(let target, let serveChangesEvery):
            payload[Key.ruleset] = Kind.pointsTo
            payload[Key.target] = target
            payload[Key.serveChangesEvery] = serveChangesEvery
        }

        return payload
    }

    static func decode(_ payload: [String: Any]) throws -> Arrival {
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

        let match = Match(
            ruleset: try ruleset(from: payload),
            firstServer: try side(named: payload[Key.firstServer] as? String),
            journal: RallyJournal(try winners.map { Rally(wonBy: try side(named: $0)) }),
            isAbandoned: isAbandoned)

        let saved = SavedMatch(
            id: id, match: match, startedAt: startedAt, lastRallyAt: lastRallyAt)

        switch payload[Key.kind] as? String {
        case Kind.match: return .match(saved)
        case Kind.receipt: return .receipt(saved)
        case let kind: throw MatchPayloadError.unreadable(reason: "a parcel of kind \"\(kind ?? "—")\"")
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
        static let rallies = "rallies"
    }

    fileprivate enum Kind {
        static let classic = "classic"
        static let pointsTo = "pointsTo"

        static let match = "match"
        static let receipt = "receipt"
    }
}

/// Both directions share one channel, so the parcel's `kind` key is all the
/// receiving side has to tell a match from a receipt.
enum Arrival: Equatable {
    case match(SavedMatch)

    /// The only thing that takes a match off the queue on the watch
    /// (ADR-0002).
    case receipt(SavedMatch)

    fileprivate var match: SavedMatch {
        switch self {
        case .match(let match), .receipt(let match): match
        }
    }

    fileprivate var kind: String {
        switch self {
        case .match: MatchPayload.Kind.match
        case .receipt: MatchPayload.Kind.receipt
        }
    }
}

/// Only a pair of apps that drifted apart reaches this, and the parcel is
/// then dropped.
enum MatchPayloadError: Error, Equatable {
    case unreadable(reason: String)
}
