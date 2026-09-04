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
///
/// Матч и расписка о нём — одна и та же посылка с разным ключом `kind`:
/// телефон возвращает ровно то, что записал, и часы сверяют это с тем, что у
/// них лежит.
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
            throw MatchPayloadError.unreadable(reason: "посылка без идентификатора матча")
        }

        guard let startedAt = payload[Key.startedAt] as? Date,
            let lastRallyAt = payload[Key.lastRallyAt] as? Date
        else {
            throw MatchPayloadError.unreadable(reason: "посылка без времени матча")
        }

        // Журнал и пометка недоигранности спрашиваются так же строго, как
        // всё остальное, а не подставляются умолчанием: посылка без журнала
        // разобралась бы в матч 0:0 — ровно тот «счёт, собранный из
        // умолчаний», от которого этот разбор и защищает.
        guard let winners = payload[Key.rallies] as? [String],
            let isAbandoned = payload[Key.abandoned] as? Bool
        else {
            throw MatchPayloadError.unreadable(reason: "посылка без журнала розыгрышей")
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
        case let kind: throw MatchPayloadError.unreadable(reason: "посылка вида «\(kind ?? "—")»")
        }
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

/// Что приехало.
///
/// Посылки ходят в обе стороны, и по одному и тому же каналу: матч уезжает с
/// часов, расписка возвращается с телефона. Различить их обязана сама посылка
/// — принимающая сторона знает только то, что ей привезли словарь.
enum Arrival: Equatable {
    /// Матч с часов — его надо записать.
    case match(SavedMatch)

    /// Расписка с телефона: вот этот матч записан у меня. Только она и снимает
    /// матч с очереди на часах (ADR-0002).
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

/// Приехало то, что не складывается в матч.
///
/// Случай, которого быть не должно: посылку собирает наш же код. Остаётся
/// разъехавшаяся пара приложений — на часах обновлённое, на телефоне старое, —
/// и тогда лучше потерять один матч с записью в логе, чем показать в истории
/// счёт, собранный из умолчаний.
enum MatchPayloadError: Error, Equatable {
    case unreadable(reason: String)
}
