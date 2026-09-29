import GRDB

/// There is one schema version: a column is added by editing `v1` rather than
/// by appending a second migration, until the first release, after which the
/// rule inverts. ADR-0014 has the whole of it, including what flips it.
enum MatchDatabase {
    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        // Spelled out even though it is the default, so that erasing on a
        // schema mismatch is a decision taken here rather than a setting
        // switched on without thinking. There is no backup (ADR-0002).
        migrator.eraseDatabaseOnSchemaChange = false

        migrator.registerMigration("v1") { db in
            try db.create(table: "match") { t in
                t.primaryKey("id", .text)

                t.column("ruleset", .text).notNull()
                t.column("setsToWin", .integer)
                t.column("goldenPoint", .boolean)
                t.column("target", .integer)
                t.column("serveChangesEvery", .integer)

                t.column("firstServer", .text).notNull()
                t.column("startedAt", .datetime).notNull()
                t.column("lastRallyAt", .datetime).notNull()

                t.column("abandoned", .boolean).notNull()

                // The default is there because writing the match knows nothing
                // about delivery, and should not: it happens after every rally,
                // while delivery happens once, at the end.
                t.column("delivered", .boolean).notNull().defaults(to: false)

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

            try db.create(table: "rally") { t in
                t.column("matchId", .text)
                    .notNull()
                    .references("match", onDelete: .cascade)

                // The order of the journal is part of the data — the score is
                // computed from it — and insertion order cannot be relied on.
                t.column("ordinal", .integer).notNull()

                t.column("winner", .text).notNull()

                t.primaryKey(["matchId", "ordinal"])
            }
        }

        return migrator
    }
}
