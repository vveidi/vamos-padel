import Foundation
import GRDB
import PadelScoring
import Testing

@testable import PadelStorage

@Suite("Миграции схемы")
struct MigrationTests {
    /// Версия пока одна, и до первого выпуска новых не появляется: у
    /// приложения нет пользователей, поэтому схема правится прямо в `v1`.
    /// Тест перечисляет версии буквально, чтобы вторая не завелась по
    /// привычке — «добавить колонку» сейчас значит дописать её в `v1`, а не
    /// рядом.
    ///
    /// С первым выпуском правило станет обратным: список версий — append-only,
    /// потому что переписанная миграция применится заново к базе, где она уже
    /// применена, и уронит открытие. База на часах существует в одном
    /// экземпляре и до передачи на телефон является единственной копией матча
    /// (ADR-0002).
    @Test("Схема версионируется с первой версии")
    func theSchemaIsVersionedFromTheFirstVersion() {
        #expect(
            MatchDatabase.migrator.migrations == ["v1"],
            "до выпуска схема правится в v1 — новую версию заводить рано")
    }

    /// Ради этой проверки и выбран GRDB (ADR-0003): матч, записанный старой
    /// версией приложения, должен дочитываться сегодняшней. Фикстура написана
    /// голым SQL намеренно — так её и писала бы та версия, а не сегодняшнее
    /// хранилище, которого тогда не существовало.
    ///
    /// Пока версия схемы одна, «предыдущая» и «первая» — одно и то же, и
    /// проверка держится на том, что чтение не зависит от сегодняшней записи.
    /// С появлением второй версии тест начнёт делать ровно то, что обещает
    /// названием, не поменяв ни строки: `migrations.first` останется v1.
    @Test("База, оставшаяся на предыдущей версии схемы, дочитывается после миграций")
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

        // Открытие хранилища и есть применение миграций.
        let store = try SQLiteMatchStore(queue)

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

    @Test("Миграции применяются к уже мигрированной базе не повторно")
    func migratingTwiceChangesNothing() throws {
        let database = "twice-\(UUID().uuidString)"
        let store = try SQLiteMatchStore.inMemory(named: database)
        let saved = SavedMatch.played([.us, .them])
        try store.save(saved)

        // Второе открытие той же базы снова прогоняет мигратор.
        let reopened = try SQLiteMatchStore.inMemory(named: database)

        #expect(try reopened.matchInProgress() == saved)
    }

    /// Набор правил разложен по колонкам, у каждого варианта своя половина.
    /// Проверка живёт в схеме, а не только в коде, потому что читать и писать
    /// этот файл будет не только наш код (ADR-0003).
    @Test("Схема не пускает набор правил, собранный наполовину")
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
