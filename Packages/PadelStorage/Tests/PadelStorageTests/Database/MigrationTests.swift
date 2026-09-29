import Foundation
import GRDB
import PadelScoring
import Testing

@testable import PadelStorage
@testable import PadelStorageDatabase

@Suite("Schema migrations")
struct MigrationTests {
    /// The versions are listed literally so that a second one cannot appear
    /// out of habit before the first release (ADR-0014).
    @Test("The schema is versioned from its first version")
    func theSchemaIsVersionedFromTheFirstVersion() {
        #expect(
            MatchDatabase.migrator.migrations == ["v1"],
            "before release the schema is edited in v1 — it is too early for a new version")
    }

    /// The fixture is bare SQL on purpose: that is how the old version would
    /// have written it, and not today's store, which did not exist back then.
    /// While there is one schema version, "previous" and "first" are the same
    /// thing, and the test rests on reading not depending on today's writing.
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
