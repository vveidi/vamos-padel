import Foundation
import GRDB
import PadelScoring

/// Хранилище матчей на SQLite через GRDB (ADR-0003).
///
/// Пишет синхронно и в том же потоке, откуда позвали: запись одного розыгрыша
/// — это одна короткая транзакция, и ждать её экрану дешевле, чем разбираться,
/// в каком порядке доехали до базы два касания подряд.
public final class SQLiteMatchStore: MatchStore {
    private let dbQueue: DatabaseQueue

    /// База в контейнере приложения — та, которой пользуются часы и телефон.
    ///
    /// Путь считается здесь, а не в приложениях: у каждого из них свой
    /// контейнер, поэтому одно правило даёт две разные базы, и договариваться
    /// им не о чем.
    public static func inApplicationSupport() throws -> SQLiteMatchStore {
        let directory = URL.applicationSupportDirectory

        // На свежей установке каталога ещё нет, и SQLite его не создаёт.
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true)

        let file = directory.appending(path: "matches.sqlite")

        return try SQLiteMatchStore(DatabaseQueue(path: file.path(percentEncoded: false)))
    }

    /// База в памяти: тесты и превью. Имя нужно, только если к одной и той же
    /// базе открывают несколько соединений; без него база своя у каждого.
    public static func inMemory(named name: String? = nil) throws -> SQLiteMatchStore {
        try SQLiteMatchStore(DatabaseQueue(named: name))
    }

    /// Миграции применяются при открытии, и другого места у них нет: база,
    /// открытая мимо этого инициализатора, была бы базой неизвестной версии.
    init(_ dbQueue: DatabaseQueue) throws {
        self.dbQueue = dbQueue

        try MatchDatabase.migrator.migrate(dbQueue)
    }

    public func save(_ saved: SavedMatch) throws {
        let id = saved.id.uuidString
        let ruleset = Self.columns(of: saved.match.ruleset)

        try dbQueue.write { db in
            // Обновляются только время последнего розыгрыша и пометка
            // недоигранности — ровно то, что меняется по ходу матча. Всё
            // остальное в строке — набор правил, первая подача, начало —
            // задаётся при первом розыгрыше и потом неизменно: матч, у
            // которого посреди игры поменялись правила, — это другой матч.
            //
            // Отметка о доставке при этом гасится: запись — это и есть «матч
            // изменился», а доставленной остаётся версия, которая с этого
            // момента расходится с той, что на часах. Отменённое очко в
            // законченном матче уезжает на телефон второй раз, и там второй
            // приезд затирает первый.
            try db.execute(
                sql: """
                    INSERT INTO match
                        (id, ruleset, setsToWin, goldenPoint, target, serveChangesEvery,
                         firstServer, startedAt, lastRallyAt, abandoned)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(id) DO UPDATE SET
                        lastRallyAt = excluded.lastRallyAt,
                        abandoned = excluded.abandoned,
                        delivered = 0
                    """,
                arguments: [
                    id, ruleset.kind, ruleset.setsToWin, ruleset.goldenPoint,
                    ruleset.target, ruleset.serveChangesEvery,
                    saved.match.firstServer.rawValue, saved.startedAt, saved.lastRallyAt,
                    saved.match.isAbandoned,
                ])

            let rallies = saved.match.journal.rallies

            // Журнал переписывается целиком, а не досылается хвостом.
            //
            // На часах хватило бы хвоста: там журнал растёт с конца да
            // укорачивается отменой. Но тот же метод записывает матч,
            // приехавший на телефон (тикет 10), а приезжает он любой версией —
            // и доигранная заново после отмены очка предыдущей не продолжение.
            // Дописать хвост к чужой середине значит собрать журнал, которого
            // никто не играл, и молча: длина сойдётся.
            //
            // Цена — переписанный журнал на каждом очке; матч из двухсот
            // розыгрышей это одна короткая транзакция.
            try db.execute(sql: "DELETE FROM rally WHERE matchId = ?", arguments: [id])

            for (ordinal, rally) in rallies.enumerated() {
                try db.execute(
                    sql: "INSERT INTO rally (matchId, ordinal, winner) VALUES (?, ?, ?)",
                    arguments: [id, ordinal, rally.winner.rawValue])
            }
        }
    }

    public func matchInProgress() throws -> SavedMatch? {
        try dbQueue.read { db in
            // Спрашивается последний матч, а не первый попавшийся незакончен-
            // ный: если последний доигран, продолжать нечего, а оставленный
            // месяц назад на 3:2 не должен воскресать посреди корта.
            //
            // Идёт матч или нет, спрашивается у движка, а не у колонки:
            // счёт рядом с журналом — то самое состояние, которое однажды
            // с ним разойдётся (ADR-0001). Колонка есть только у пометки
            // недоигранности, и ровно потому, что её неоткуда посчитать.
            guard let row = try Row.fetchOne(db, sql: Self.lastMatch) else { return nil }

            let saved = try Self.savedMatch(row: row, db: db)

            return saved.match.state.outcome.isOver ? nil : saved
        }
    }

    public func lastRuleset() throws -> Ruleset? {
        try dbQueue.read { db in
            guard let row = try Row.fetchOne(db, sql: Self.lastMatch) else { return nil }

            return try Self.ruleset(from: row)
        }
    }

    /// Какой матч считается прошлым. Запрос один на оба вопроса о нём — «его
    /// доигрывать?» и «по каким правилам он шёл?»: разъехавшись, они начали бы
    /// отвечать про разные матчи.
    ///
    /// Порядок по времени последнего розыгрыша, а не по времени начала: матч,
    /// начатый раньше, а доигранный позже, — всё-таки более поздний.
    private static let lastMatch =
        "SELECT * FROM match ORDER BY lastRallyAt DESC, rowid DESC LIMIT 1"

    public func matchesAwaitingDelivery() throws -> [SavedMatch] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(
                db, sql: "SELECT * FROM match WHERE delivered = 0 ORDER BY lastRallyAt, rowid")

            // Законченность спрашивается у движка, а не у колонки, по той же
            // причине, что и в `matchInProgress` (ADR-0001). Отбирать в SQL
            // тут нечего: строк с непогашенной отметкой ровно столько, сколько
            // матчей ещё не доехало, — обычно ноль или один.
            return try rows
                .map { try Self.savedMatch(row: $0, db: db) }
                .filter { $0.match.state.outcome.isOver }
        }
    }

    public func markDelivered(id: UUID) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: "UPDATE match SET delivered = 1 WHERE id = ?", arguments: [id.uuidString])
        }
    }

    public func matches() throws -> [SavedMatch] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(
                db, sql: "SELECT * FROM match ORDER BY lastRallyAt DESC, rowid DESC")

            return try rows.map { try Self.savedMatch(row: $0, db: db) }
        }
    }

    public func match(id: UUID) throws -> SavedMatch? {
        try dbQueue.read { db in
            let row = try Row.fetchOne(
                db, sql: "SELECT * FROM match WHERE id = ?", arguments: [id.uuidString])

            guard let row else { return nil }

            return try Self.savedMatch(row: row, db: db)
        }
    }

    /// Набор правил по колонкам. Половина колонок пуста у каждого варианта —
    /// какая именно, сторожит проверка в схеме.
    private static func columns(
        of ruleset: Ruleset
    ) -> (kind: String, setsToWin: Int?, goldenPoint: Bool?, target: Int?, serveChangesEvery: Int?) {
        switch ruleset {
        case .classic(let setsToWin, let goldenPoint):
            ("classic", setsToWin, goldenPoint, nil, nil)
        case .pointsTo(let target, let serveChangesEvery):
            ("pointsTo", nil, nil, target, serveChangesEvery)
        }
    }

    private static func savedMatch(row: Row, db: Database) throws -> SavedMatch {
        let id: String = row["id"]

        guard let uuid = UUID(uuidString: id) else {
            throw MatchStoreError.unreadableMatch(reason: "идентификатор «\(id)» не UUID")
        }

        let winners = try String.fetchAll(
            db,
            sql: "SELECT winner FROM rally WHERE matchId = ? ORDER BY ordinal",
            arguments: [id])

        let rallies = try winners.map { winner in
            Rally(wonBy: try side(named: winner))
        }

        let match = Match(
            ruleset: try ruleset(from: row),
            firstServer: try side(named: row["firstServer"]),
            journal: RallyJournal(rallies),
            isAbandoned: row["abandoned"])

        return SavedMatch(
            id: uuid,
            match: match,
            startedAt: row["startedAt"],
            lastRallyAt: row["lastRallyAt"])
    }

    private static func ruleset(from row: Row) throws -> Ruleset {
        let kind: String = row["ruleset"]

        switch kind {
        case "classic":
            guard let setsToWin: Int = row["setsToWin"], let goldenPoint: Bool = row["goldenPoint"]
            else {
                throw MatchStoreError.unreadableMatch(reason: "классический счёт без правил")
            }

            return .classic(setsToWin: setsToWin, goldenPoint: goldenPoint)
        case "pointsTo":
            guard let target: Int = row["target"], let every: Int = row["serveChangesEvery"] else {
                throw MatchStoreError.unreadableMatch(reason: "счёт до N очков без N")
            }

            return .pointsTo(target: target, serveChangesEvery: every)
        default:
            throw MatchStoreError.unreadableMatch(reason: "неизвестный набор правил «\(kind)»")
        }
    }

    private static func side(named name: String) throws -> Side {
        guard let side = Side(rawValue: name) else {
            throw MatchStoreError.unreadableMatch(reason: "неизвестная сторона «\(name)»")
        }

        return side
    }
}

/// База отдала строку, которая не складывается в матч.
///
/// Случай, которого быть не должно: схема сторожит и набор правил, и
/// обязательные колонки. Остаётся то, чего схема не знает, — написание
/// стороны и формат идентификатора, — и молча подставлять вместо них
/// умолчание значило бы вернуть на корт чужой счёт.
public enum MatchStoreError: Error, Equatable {
    case unreadableMatch(reason: String)
}
