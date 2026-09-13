import Foundation
import GRDB
import PadelScoring
import PadelStorage

/// The match store on SQLite through GRDB (ADR-0003).
///
/// Writes synchronously, on the thread it was called from: writing one rally
/// is a single short transaction, and waiting for it costs the screen less
/// than working out in which order two consecutive taps reached the database.
public final class SQLiteMatchStore: MatchStore, MatchDeliveryQueue {
    private let dbQueue: DatabaseQueue

    /// The database in the app container — the one the watch and the phone
    /// use.
    ///
    /// The path is worked out here rather than in the apps: each of them has
    /// its own container, so one rule yields two different databases, and they
    /// have nothing to agree about.
    public static func inApplicationSupport() throws -> SQLiteMatchStore {
        let directory = URL.applicationSupportDirectory

        // On a fresh install the directory does not exist yet, and SQLite
        // does not create it.
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true)

        let file = directory.appending(path: "matches.sqlite")

        return try SQLiteMatchStore(DatabaseQueue(path: file.path(percentEncoded: false)))
    }

    /// An in-memory database: tests and previews. The name is only needed when
    /// several connections are opened to the same database; without it each
    /// one gets a database of its own.
    public static func inMemory(named name: String? = nil) throws -> SQLiteMatchStore {
        try SQLiteMatchStore(DatabaseQueue(named: name))
    }

    /// The migrations are applied on opening, and there is nowhere else for
    /// them: a database opened around this initializer would be a database of
    /// unknown version.
    init(_ dbQueue: DatabaseQueue) throws {
        self.dbQueue = dbQueue

        try MatchDatabase.migrator.migrate(dbQueue)
    }

    public func save(_ saved: SavedMatch) throws {
        let id = saved.id.uuidString
        let ruleset = Self.columns(of: saved.match.ruleset)

        try dbQueue.write { db in
            // Only the time of the last rally and the abandoned mark are
            // updated — exactly what changes over the course of a match.
            // Everything else in the row — the ruleset, the first server, the
            // start — is set on the first rally and immutable after that: a
            // match whose rules changed mid-play is a different match.
            //
            // The delivery mark is cleared along the way: a write is precisely
            // "the match changed", and what stays delivered is a version that
            // from this moment diverges from the one on the watch. A point
            // undone in a finished match travels to the phone a second time,
            // and there the second arrival overwrites the first.
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

            // The journal is rewritten in full rather than appended to at the
            // tail.
            //
            // On the watch a tail would be enough: there the journal grows at
            // the end and shortens by undo. But the same method writes a match
            // that arrived on the phone (ticket 10), and it can arrive as any
            // version — one replayed after a point was undone is no
            // continuation of the previous one. Appending a tail to somebody
            // else's middle means assembling a journal nobody played, and
            // doing so silently: the length will add up.
            //
            // The price is a rewritten journal on every point; a match of two
            // hundred rallies is one short transaction.
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
            // The last match is asked for, not the first unfinished one that
            // turns up: if the last one was played out there is nothing to
            // continue, and one left at 3:2 a month ago must not rise from the
            // dead in the middle of a court.
            //
            // Whether the match is running is asked of the engine, not of a
            // column: a score next to the journal is exactly the kind of state
            // that one day diverges from it (ADR-0001). Only the abandoned
            // mark has a column, and precisely because there is nowhere to
            // compute it from.
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

    /// Which match counts as the previous one. One query for both questions
    /// about it — "should it be played out?" and "under which rules did it
    /// run?": were they to drift apart, they would start answering about
    /// different matches.
    ///
    /// Ordered by the time of the last rally, not by the time of the start: a
    /// match begun earlier but played out later is the later one after all.
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
            // GRDB reads the history itself when the observation starts, and
            // again after every transaction that touched the matches or their
            // rallies — the second half of the ticket's work: a match written
            // by the reception into an app nobody is looking at still reaches
            // the screen if somebody is.
            //
            // The values are scheduled on the cooperative pool rather than on
            // the main queue: the screen reads them from an async loop of its
            // own, and it is that loop's business which actor it comes back on.
            let cancellable = ValueObservation
                .tracking { db in try Self.matches(in: db) }
                .start(
                    in: dbQueue,
                    scheduling: .task,
                    onError: { continuation.finish(throwing: $0) },
                    onChange: { continuation.yield($0) })

            // The observation lives exactly as long as somebody is reading the
            // stream: the screen goes away, the loop ends, the database stops
            // being watched.
            continuation.onTermination = { _ in cancellable.cancel() }
        }
    }

    /// The history in a single query, for both the one-off reading and the
    /// observation: were the two to drift apart, the screen would start
    /// showing something other than what the tests read back.
    ///
    /// Ordered by the start of the match, and here it parts ways with
    /// `lastMatch`, which orders by the last rally. The two answer different
    /// questions. "Which match is the previous one" is about the one played
    /// most recently — a match begun earlier but played out later is the later
    /// one after all. The history is a column of dates the reader can see, and
    /// the date in the row is the start: a match begun at seven and finished
    /// at eleven, after an hour of waiting out the rain, would otherwise stand
    /// above a match played at nine while showing an earlier time than it. A
    /// list whose order argues with its own dates reads as broken.
    private static func matches(in db: Database) throws -> [SavedMatch] {
        let rows = try Row.fetchAll(
            db, sql: "SELECT * FROM match ORDER BY startedAt DESC, rowid DESC")

        return try rows.map { try savedMatch(row: $0, db: db) }
    }

    public func matchesAwaitingDelivery() throws -> [SavedMatch] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(
                db, sql: "SELECT * FROM match WHERE delivered = 0 ORDER BY lastRallyAt, rowid")

            // Whether a match is over is asked of the engine, not of a column,
            // for the same reason as in `matchInProgress` (ADR-0001). There is
            // nothing to filter in SQL here: there are exactly as many rows
            // with an uncleared mark as there are matches yet to arrive —
            // usually zero or one.
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

            // The receipt came for a version of the match, not for its
            // identifier. If they differ, the match was changed after it was
            // sent and stands in the queue as a different one; the queue must
            // not be cleared by this receipt.
            guard let row, try Self.savedMatch(row: row, db: db) == delivered else { return }

            try db.execute(
                sql: "UPDATE match SET delivered = 1 WHERE id = ?",
                arguments: [delivered.id.uuidString])
        }
    }

    /// The ruleset spread across columns. Half the columns are empty for each
    /// case — which half is guarded by the check in the schema.
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

/// The database handed back a row that does not add up to a match.
///
/// A case that should never happen: the schema guards both the ruleset and the
/// mandatory columns. What is left is what the schema does not know — the
/// spelling of a side and the format of an identifier — and silently
/// substituting a default for them would mean bringing somebody else's score
/// back onto the court.
public enum MatchStoreError: Error, Equatable {
    case unreadableMatch(reason: String)
}
