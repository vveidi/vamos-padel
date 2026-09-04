import Foundation
import PadelScoring
import PadelStorage

/// Матч, разобранный на то, что умеет переносить транспорт.
///
/// Словарь из чисел, строк, дат и булевых значений — единственное, что
/// WatchConnectivity берётся доставить. Формат поэтому написан руками и по
/// ключам, а не выведен из `Codable` доменных типов: имена ключей — это
/// договор между двумя приложениями, которые обновляются порознь, и он не
/// должен меняться от переименования поля в движке.
///
/// Разложен так же, как в схеме базы (`MatchDatabase`), и по той же причине:
/// половина ключей набора правил пуста у каждого варианта, зато прочитать
/// посылку можно, не зная нашего кода.
enum MatchPayload {
    static func encode(_ saved: SavedMatch) -> [String: Any] {
        var payload: [String: Any] = [
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

    static func decode(_ payload: [String: Any]) throws -> SavedMatch {
        guard let id = matchId(in: payload) else {
            throw MatchPayloadError.unreadable(reason: "посылка без идентификатора матча")
        }

        guard let startedAt = payload[Key.startedAt] as? Date,
            let lastRallyAt = payload[Key.lastRallyAt] as? Date
        else {
            throw MatchPayloadError.unreadable(reason: "посылка без времени матча")
        }

        let winners = payload[Key.rallies] as? [String] ?? []

        let match = Match(
            ruleset: try ruleset(from: payload),
            firstServer: try side(named: payload[Key.firstServer] as? String),
            journal: RallyJournal(try winners.map { Rally(wonBy: try side(named: $0)) }),
            isAbandoned: payload[Key.abandoned] as? Bool ?? false)

        return SavedMatch(
            id: id, match: match, startedAt: startedAt, lastRallyAt: lastRallyAt)
    }

    /// Чей это матч — вопрос, на который приходится отвечать, не разбирая
    /// посылку целиком: подтверждение доставки приходит вместе с ней, и всё,
    /// что нужно знать о доехавшем матче, — его идентификатор.
    static func matchId(in payload: [String: Any]) -> UUID? {
        guard let id = payload[Key.id] as? String else { return nil }

        return UUID(uuidString: id)
    }

    private static func ruleset(from payload: [String: Any]) throws -> Ruleset {
        switch payload[Key.ruleset] as? String {
        case Kind.classic:
            guard let setsToWin = payload[Key.setsToWin] as? Int,
                let goldenPoint = payload[Key.goldenPoint] as? Bool
            else {
                throw MatchPayloadError.unreadable(reason: "классический счёт без правил")
            }

            return .classic(setsToWin: setsToWin, goldenPoint: goldenPoint)
        case Kind.pointsTo:
            guard let target = payload[Key.target] as? Int,
                let every = payload[Key.serveChangesEvery] as? Int
            else {
                throw MatchPayloadError.unreadable(reason: "счёт до N очков без N")
            }

            return .pointsTo(target: target, serveChangesEvery: every)
        case let kind:
            throw MatchPayloadError.unreadable(
                reason: "неизвестный набор правил «\(kind ?? "—")»")
        }
    }

    private static func side(named name: String?) throws -> Side {
        guard let name, let side = Side(rawValue: name) else {
            throw MatchPayloadError.unreadable(reason: "неизвестная сторона «\(name ?? "—")»")
        }

        return side
    }

    private enum Key {
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

    private enum Kind {
        static let classic = "classic"
        static let pointsTo = "pointsTo"
    }
}

/// Приехало то, что не складывается в матч.
///
/// Случай, которого быть не должно: посылку собирает наш же код. Остаётся
/// разъехавшаяся пара приложений — на часах обновлённое, на телефоне старое, —
/// и тогда лучше потерять один матч с записью в логе, чем показать в истории
/// счёт, собранный из умолчаний.
enum MatchPayloadError: Error, Equatable {
    case unreadable(reason: String)
}
