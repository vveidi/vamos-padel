import GRDB

/// Схема базы матчей и её история.
///
/// Схема версионируется миграциями с самой первой версии, и это не запас на
/// будущее: журнал розыгрышей точно изменится, когда появятся игроки
/// (ADR-0003). Правило одно и не обсуждается — уже выпущенная миграция
/// неприкосновенна, новая версия дописывается следующей. База на часах
/// существует в единственном экземпляре и до передачи на телефон является
/// единственной копией матча (ADR-0002): переписать историю миграций значит
/// потерять то, что в ней лежит.
enum MatchDatabase {
    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        // Названо явно, хотя это и значение по умолчанию: единственное, что
        // делает эта строка, — превращает «стереть базу при расхождении схемы»
        // из настройки, которую можно включить не подумав, в решение, принятое
        // здесь. Бэкапа у нас нет (ADR-0002), стирать нечего и незачем.
        migrator.eraseDatabaseOnSchemaChange = false

        migrator.registerMigration("v1") { db in
            try db.create(table: "match") { t in
                t.primaryKey("id", .text)

                // Набор правил разложен по колонкам, а не свёрнут в JSON:
                // файл SQLite выбран за переносимость (ADR-0003), а строка
                // JSON внутри колонки переносима ровно настолько, насколько
                // читатель знает наш формат.
                t.column("ruleset", .text).notNull()
                t.column("setsToWin", .integer)
                t.column("goldenPoint", .boolean)
                t.column("target", .integer)
                t.column("serveChangesEvery", .integer)

                t.column("firstServer", .text).notNull()
                t.column("startedAt", .datetime).notNull()
                t.column("lastRallyAt", .datetime).notNull()

                // Колонки набора правил заполнены по половине на вариант, и
                // без этой проверки половинка от другого варианта пролезла бы
                // в базу молча. Правило записано в схеме, а не только в коде,
                // потому что читать этот файл будет и не наш код (ADR-0003).
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

            // Розыгрыш — строка, а не элемент массива в колонке матча: журнал
            // и есть единственная сохраняемая правда о матче (ADR-0001), и
            // хранить его так, чтобы прочитать мог только наш код, значило бы
            // отдать половину того, ради чего выбран SQLite.
            try db.create(table: "rally") { t in
                t.column("matchId", .text)
                    .notNull()
                    .references("match", onDelete: .cascade)

                // Журнал упорядочен, и порядок в нём — часть данных: по нему
                // считается счёт. Полагаться на порядок вставки нельзя, номер
                // хранится явно.
                t.column("ordinal", .integer).notNull()

                t.column("winner", .text).notNull()

                t.primaryKey(["matchId", "ordinal"])
            }
        }

        migrator.registerMigration("v2") { db in
            // Единственное состояние матча, которое хранится колонкой, а не
            // считается движком из журнала (ADR-0001): недоигранность неоткуда
            // вывести. Журнал матча, прекращённого при 5:2, ничем не отличается
            // от журнала матча, который вот-вот продолжат, — разницу знает
            // только игрок, ушедший с корта.
            //
            // Умолчание нужно не новым строкам, а старым: матчи, записанные
            // до появления пометки, прекратить досрочно было нечем, и читаться
            // они должны как обычные.
            try db.alter(table: "match") { t in
                t.add(column: "abandoned", .boolean).notNull().defaults(to: false)
            }
        }

        return migrator
    }
}
