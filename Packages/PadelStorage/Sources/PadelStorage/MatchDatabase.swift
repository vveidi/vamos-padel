import GRDB

/// The schema of the match database and its history.
///
/// The schema is versioned by migrations from its very first version, and that
/// is not provision for the future: the rally journal will certainly change
/// once players appear (ADR-0003).
///
/// There is exactly one version so far, and no new one appears before the
/// first release: the app has not a single user, so the schema is edited
/// directly in `v1` rather than appended by a migration to a database nobody
/// has. On their own device the developer gets a second `v1` by deleting the
/// app.
///
/// The rule changes the day the app reaches somebody else: from that moment a
/// released migration is untouchable and a new version is appended after it.
/// The database on the watch exists in a single copy and, until the transfer
/// to the phone, is the only copy of the match (ADR-0002) — rewriting the
/// migration history will then mean losing what it holds.
enum MatchDatabase {
    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        // Spelled out even though it is the default: all this line does is
        // turn "erase the database on a schema mismatch" from a setting that
        // can be switched on without thinking into a decision taken here. We
        // have no backup (ADR-0002); there is nothing to erase and no reason
        // to.
        migrator.eraseDatabaseOnSchemaChange = false

        migrator.registerMigration("v1") { db in
            try db.create(table: "match") { t in
                t.primaryKey("id", .text)

                // The ruleset is spread across columns rather than folded
                // into JSON: the SQLite file was chosen for portability
                // (ADR-0003), and a JSON string inside a column is portable
                // exactly as far as the reader knows our format.
                t.column("ruleset", .text).notNull()
                t.column("setsToWin", .integer)
                t.column("goldenPoint", .boolean)
                t.column("target", .integer)
                t.column("serveChangesEvery", .integer)

                t.column("firstServer", .text).notNull()
                t.column("startedAt", .datetime).notNull()
                t.column("lastRallyAt", .datetime).notNull()

                // The one piece of match state kept in a column rather than
                // computed by the engine from the journal (ADR-0001): there is
                // nowhere to derive abandonment from. The journal of a match
                // stopped at 5:2 is no different from the journal of a match
                // about to resume — only the player who left the court knows
                // the difference.
                t.column("abandoned", .boolean).notNull()

                // The delivered-to-the-phone mark is not a property of the
                // match but a receipt of the queue: the store itself serves as
                // the queue (ADR-0004), because a second list beside it would
                // one day diverge from it. On the phone the column exists and
                // is always empty — it has nowhere to deliver to.
                //
                // The default is there because writing the match knows nothing
                // about delivery, and should not: it happens after every rally,
                // while delivery happens once, at the end.
                t.column("delivered", .boolean).notNull().defaults(to: false)

                // The ruleset columns are filled half per case, and without
                // this check a half belonging to the other case would slip into
                // the database silently. The rule is written into the schema
                // and not only into the code, because code that is not ours
                // will read this file too (ADR-0003).
                t.check(
                    sql: """
                        (ruleset = 'classic'
                            AND setsToWin IS NOT NULL AND goldenPoint IS NOT NULL
                            AND target IS NULL AND serveChangesEvery IS NULL)
                        OR (ruleset = 'pointsTo'
                            AND target IS NOT NULL AND serveChangesEvery IS NOT NULL
                            AND setsToWin IS NULL AND goldenPoint IS NULL)
                        """)
            }

            // A rally is a row, not an element of an array in a column of the
            // match: the journal is the single stored truth about the match
            // (ADR-0001), and storing it so that only our code can read it
            // would give away half of what SQLite was chosen for.
            try db.create(table: "rally") { t in
                t.column("matchId", .text)
                    .notNull()
                    .references("match", onDelete: .cascade)

                // The journal is ordered, and the order in it is part of the
                // data: the score is computed from it. Insertion order cannot
                // be relied on, so the index is stored explicitly.
                t.column("ordinal", .integer).notNull()

                t.column("winner", .text).notNull()

                t.primaryKey(["matchId", "ordinal"])
            }
        }

        return migrator
    }
}
