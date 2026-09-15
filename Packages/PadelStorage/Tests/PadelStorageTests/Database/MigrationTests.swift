import Foundation
import GRDB
import PadelScoring
import Testing

@testable import PadelStorage
@testable import PadelStorageDatabase

@Suite("Schema migrations")
struct MigrationTests {
    /// There is one version so far, and no new one appears before the first
    /// release: the app has no users, so the schema is edited directly in
    /// `v1`. The test lists the versions literally so that a second one does
    /// not appear out of habit — "add a column" currently means appending it
    /// to `v1`, not beside it.
    ///
    /// With the first release the rule inverts: the list of versions is
    /// append-only, because a rewritten migration will be applied afresh to a
    /// database where it has already been applied, and will crash the opening.
    /// The database on the watch exists in a single copy and, until the
    /// transfer to the phone, is the only copy of the match (ADR-0002).
    @Test("The schema is versioned from its first version")
    func theSchemaIsVersionedFromTheFirstVersion() {
        #expect(
            MatchDatabase.migrator.migrations == ["v1"],
            "before release the schema is edited in v1 — it is too early for a new version")
    }

    /// GRDB was chosen for exactly this check (ADR-0003): a match written by
    /// an old version of the app has to remain readable by today's. The
    /// fixture is written in bare SQL on purpose — that is how that version
    /// would have written it, and not today's store, which did not exist back
    /// then.
    ///
    /// While there is only one schema version, "previous" and "first" are the
    /// same thing, and the check rests on the reading not depending on today's
    /// writing. Once a second version appears the test will start doing exactly
    /// what its name promises without a line changing: `migrations.first` will
    /// still be v1.
    @Test("A database left at the previous schema version reads back after migrating")
    func aDatabaseLeftAtThePreviousVersionMigrates() throws {
        let queue = try DatabaseQueue()

        let oldest = try #require(MatchDatabase.migrator.migrations.first)
        try MatchDatabase.migrator.migrate(queue, upTo: oldest)

        let id = UUID()

        try queue.write { db in
            try db.execute(
                sql: """
                    INSERT INTO match
                        (id, ruleset, setsToWin, goldenPoint, target, serveChangesEvery,
                         firstServer, startedAt, lastRallyAt, abandoned)
                    VALUES (?, 'pointsTo', NULL, NULL, 16, 4, 'them', ?, ?, 0)
                    """,
                arguments: [id.uuidString, aMoment, aMoment.addingTimeInterval(60)])

            for (ordinal, winner) in ["us", "them", "us"].enumerated() {
                try db.execute(
                    sql: "INSERT INTO rally (matchId, ordinal, winner) VALUES (?, ?, ?)",
                    arguments: [id.uuidString, ordinal, winner])
            }
        }

        // Opening the store is what applies the migrations.
        let store = try DatabaseMatchStore(queue)

        let restored = try #require(try store.matchInProgress())

        #expect(restored.id == id)
        #expect(restored.match.ruleset == .pointsTo(target: 16, serveChangesEvery: 4))
        #expect(restored.match.firstServer == .them)
        #expect(
            restored.match.journal.rallies
                == [Rally(wonBy: .us), Rally(wonBy: .them), Rally(wonBy: .us)])
        #expect(restored.duration == 60)
        #expect(restored.match.isAbandoned == false)
    }

    @Test("Migrations are not applied twice to an already migrated database")
    func migratingTwiceChangesNothing() throws {
        let database = "twice-\(UUID().uuidString)"
        let store = try DatabaseMatchStore.inMemory(named: database)
        let saved = SavedMatch.played([.us, .them])
        try store.save(saved)

        // Opening the same database a second time runs the migrator again.
        let reopened = try DatabaseMatchStore.inMemory(named: database)

        #expect(try reopened.matchInProgress() == saved)
    }

    /// The ruleset is spread across columns, each case owning its half. The
    /// check lives in the schema and not only in the code, because code other
    /// than ours will read and write this file (ADR-0003).
    @Test("The schema turns away a half-assembled ruleset")
    func theSchemaRejectsAHalfRuleset() throws {
        let queue = try DatabaseQueue()
        try MatchDatabase.migrator.migrate(queue)

        #expect(throws: DatabaseError.self) {
            try queue.write { db in
                try db.execute(
                    sql: """
                        INSERT INTO match
                            (id, ruleset, setsToWin, goldenPoint, target, serveChangesEvery,
                             firstServer, startedAt, lastRallyAt, abandoned)
                        VALUES (?, 'classic', 1, 1, 16, 4, 'us', ?, ?, 0)
                        """,
                    arguments: [UUID().uuidString, aMoment, aMoment])
            }
        }
    }
}
