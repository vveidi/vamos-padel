import Foundation
import GRDB
import PadelScoring
import PadelStorage

/// Writes synchronously, on the thread it was called from: one rally is a
/// single short transaction, and waiting for it costs the screen less than
/// working out in which order two consecutive taps reached the database.
public final class DatabaseMatchStore: MatchStore, MatchDeliveryQueue {
    private let dbQueue: DatabaseQueue

    /// The path is worked out here rather than in the apps: each of them has
    /// its own container, so this one rule yields two different databases,
    /// which have nothing to agree about.
    public static func inApplicationSupport() throws -> DatabaseMatchStore {
        let directory = URL.applicationSupportDirectory

        // On a fresh install the directory does not exist yet, and SQLite
        // does not create it.
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true)

        let file = directory.appending(path: "matches.sqlite")

        return try DatabaseMatchStore(DatabaseQueue(path: file.path(percentEncoded: false)))
    }

    /// An in-memory database: tests and previews.
    ///
    /// - Parameter name: needed only to open several connections to the same
    ///   database; without it each one gets a database of its own.
    public static func inMemory(named name: String? = nil) throws -> DatabaseMatchStore {
        try DatabaseMatchStore(DatabaseQueue(named: name))
    }

    init(_ dbQueue: DatabaseQueue) throws {
        self.dbQueue = dbQueue

        try MatchDatabase.migrator.migrate(dbQueue)
    }

    public func save(_ saved: SavedMatch) throws {
        let id = saved.id.uuidString
        let ruleset = Self.columns(of: saved.match.ruleset)

        try dbQueue.write { db in
            // The delivery mark is cleared along the way: a write is precisely
            // "the match changed", so what stays delivered would be a version
            // that from this moment diverges from the one on the watch.
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

            // Rewritten in full rather than appended to: the same method writes
            // a match arriving from the watch, which can be any version. One
            // replayed after an undo is no continuation of the previous, and
            // appending its tail would assemble a journal nobody played.
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
            // The last match, not the first unfinished one that turns up: one
            // left at 3:2 a month ago must not rise from the dead in the
            // middle of a court.
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

    /// Ordered by the last rally where `matches(in:)` orders by the start,
    /// and the two must not be unified: a match begun earlier but played out
    /// later is the later one to continue, while the history shows starts and
    /// would argue with its own dates if it were ordered by anything else.
    private static let lastMatch =
        "SELECT * FROM match ORDER BY lastRallyAt DESC, rowid DESC LIMIT 1"

    public func match(id: UUID) throws -> SavedMatch? {
        try dbQueue.read { db in
            let row = try Row.fetchOne(
                db, sql: "SELECT * FROM match WHERE id = ?", arguments: [id.uuidString])

            guard let row else { return nil }

            return try Self.savedMatch(row: row, db: db)
        }
    }

    public func matches() throws -> [SavedMatch] {
        try dbQueue.read { db in try Self.matches(in: db) }
    }

    public func matchesObserved() -> AsyncThrowingStream<[SavedMatch], any Error> {
        AsyncThrowingStream { continuation in
            // Scheduled on the cooperative pool rather than on the main queue:
            // the screen reads the values from an async loop of its own, and
            // which actor they come back on is that loop's business.
            let cancellable = ValueObservation
                .tracking { db in try Self.matches(in: db) }
                .start(
                    in: dbQueue,
                    scheduling: .task,
                    onError: { continuation.finish(throwing: $0) },
                    onChange: { continuation.yield($0) })

            continuation.onTermination = { _ in cancellable.cancel() }
        }
    }

    private static func matches(in db: Database) throws -> [SavedMatch] {
        let rows = try Row.fetchAll(
            db, sql: "SELECT * FROM match ORDER BY startedAt DESC, rowid DESC")

        return try rows.map { try savedMatch(row: $0, db: db) }
    }

    public func matchesAwaitingDelivery() throws -> [SavedMatch] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(
                db, sql: "SELECT * FROM match WHERE delivered = 0 ORDER BY lastRallyAt, rowid")

            // Being over is the engine's answer and not a column's, so the
            // filter cannot run in SQL. There is little to filter: as many
            // rows carry an uncleared mark as there are matches yet to
            // arrive — usually zero or one.
            return try rows
                .map { try Self.savedMatch(row: $0, db: db) }
                .filter { !$0.match.journal.isEmpty && $0.match.state.outcome.isOver }
        }
    }

    public func markDelivered(_ delivered: SavedMatch) throws {
        try dbQueue.write { db in
            let row = try Row.fetchOne(
                db, sql: "SELECT * FROM match WHERE id = ?",
                arguments: [delivered.id.uuidString])

            // The receipt is for a version, not for an identifier: if they
            // differ, the match changed after it was sent and stands in the
            // queue as a different one.
            guard let row, try Self.savedMatch(row: row, db: db) == delivered else { return }

            try db.execute(
                sql: "UPDATE match SET delivered = 1 WHERE id = ?",
                arguments: [delivered.id.uuidString])
        }
    }

    /// Half the columns are empty for each case — which half is guarded by the
    /// check in the schema.
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
            throw MatchStoreError.unreadableMatch(reason: "the identifier \"\(id)\" is not a UUID")
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
                throw MatchStoreError.unreadableMatch(reason: "classic scoring without its rules")
            }

            return .classic(setsToWin: setsToWin, goldenPoint: goldenPoint)
        case "pointsTo":
            guard let target: Int = row["target"], let every: Int = row["serveChangesEvery"] else {
                throw MatchStoreError.unreadableMatch(reason: "a match to N points without an N")
            }

            return .pointsTo(target: target, serveChangesEvery: every)
        default:
            throw MatchStoreError.unreadableMatch(reason: "unknown ruleset \"\(kind)\"")
        }
    }

    private static func side(named name: String) throws -> Side {
        guard let side = Side(rawValue: name) else {
            throw MatchStoreError.unreadableMatch(reason: "unknown side \"\(name)\"")
        }

        return side
    }
}

/// The database handed back a row that does not add up to a match: what the
/// schema cannot guard is the spelling of a side and the format of an
/// identifier, and substituting a default for either would bring somebody
/// else's score back onto the court.
public enum MatchStoreError: Error, Equatable {
    case unreadableMatch(reason: String)
}
