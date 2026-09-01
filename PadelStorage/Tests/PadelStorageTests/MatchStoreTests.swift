import Foundation
import GRDB
import PadelScoring
import Testing

@testable import PadelStorage

@Suite("Хранилище матчей")
struct MatchStoreTests {
    /// Круговой рейс — главная проверка хранилища: журнал розыгрышей есть
    /// единственная сохраняемая правда о матче (ADR-0001), и если он вернулся
    /// из базы другим, всё остальное считается по чужим данным.
    ///
    /// Набор правил проверяется вместе с журналом и в обоих вариантах: он
    /// разложен по колонкам, у каждого варианта своя половина, и перепутать
    /// их — значит прочитать «16:14» как теннисный счёт.
    @Test(
        "Сохранённый матч читается обратно с тем же журналом и набором правил",
        arguments: [
            Ruleset.classic(setsToWin: 2, goldenPoint: true),
            .classic(setsToWin: 1, goldenPoint: false),
            .pointsTo(target: 16, serveChangesEvery: 4),
            .pointsTo(target: 21, serveChangesEvery: 2),
        ])
    func aSavedMatchReadsBackUnchanged(ruleset: Ruleset) throws {
        let store = try SQLiteMatchStore.inMemory()
        let saved = SavedMatch.played([.us, .them, .them, .us, .us], ruleset: ruleset)

        try store.save(saved)

        #expect(try store.matchInProgress() == saved)
    }

    @Test("Первая подача читается обратно", arguments: [Side.us, .them])
    func theFirstServerReadsBack(firstServer: Side) throws {
        let store = try SQLiteMatchStore.inMemory()
        let saved = SavedMatch.played([.us, .them], firstServer: firstServer)

        try store.save(saved)

        #expect(try store.matchInProgress()?.match.firstServer == firstServer)
    }

    @Test("Начало и длительность матча читаются обратно")
    func theStartAndDurationReadBack() throws {
        let store = try SQLiteMatchStore.inMemory()
        var saved = SavedMatch.played([.us])
        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(90 * 60))

        try store.save(saved)

        let restored = try #require(try store.matchInProgress())

        #expect(restored.startedAt == aMoment)
        #expect(restored.duration == 90 * 60)
    }

    /// Тот самый критерий, ради которого хранилище вообще существует: матч,
    /// прерванный на середине, уже записан — записывать его в конце было бы
    /// нечем, конца не случилось.
    @Test("Журнал записывается после каждого розыгрыша, а не в конце матча")
    func theJournalIsWrittenAfterEveryRally() throws {
        let store = try SQLiteMatchStore.inMemory()
        var saved = SavedMatch(match: Match(ruleset: .defaultClassic), startedAt: aMoment)

        for (played, winner) in [Side.us, .them, .us, .us].enumerated() {
            saved.record(rallyWonBy: winner, at: aMoment.addingTimeInterval(TimeInterval(played)))
            try store.save(saved)

            let restored = try store.matchInProgress()

            #expect(restored?.match.journal.count == played + 1)
            #expect(restored?.match == saved.match)
        }
    }

    /// Запись устроена как «отрезать отменённое, дописать недостающее», и
    /// проверяется она там, где журнал сначала укорачивается, а потом снова
    /// растёт: отменённый розыгрыш обязан исчезнуть, а не остаться лежать за
    /// концом журнала, дожидаясь следующего очка.
    @Test("Отменённые розыгрыши исчезают из базы")
    func undoneRalliesLeaveTheDatabase() throws {
        let store = try SQLiteMatchStore.inMemory()
        var saved = SavedMatch.played([.us, .us, .them, .them])
        try store.save(saved)

        saved.match.undo()
        saved.match.undo()
        try store.save(saved)

        #expect(try store.matchInProgress()?.match.journal.rallies == [Rally(wonBy: .us), Rally(wonBy: .us)])

        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(10))
        try store.save(saved)

        #expect(try store.matchInProgress()?.match == saved.match)
    }

    @Test("Отмена до пустого журнала не оставляет в базе ни одного розыгрыша")
    func undoingEverythingLeavesNoRallies() throws {
        let store = try SQLiteMatchStore.inMemory()
        var saved = SavedMatch.played([.us, .them])

        try store.save(saved)
        saved.match.undo()
        saved.match.undo()
        try store.save(saved)

        #expect(try store.matchInProgress()?.match.journal.isEmpty == true)
    }

    @Test("В пустом хранилище продолжать нечего")
    func anEmptyStoreHasNothingToContinue() throws {
        #expect(try SQLiteMatchStore.inMemory().matchInProgress() == nil)
    }

    @Test("Законченный матч продолжать не предлагается")
    func aFinishedMatchIsNotOfferedForContinuation() throws {
        let store = try SQLiteMatchStore.inMemory()
        let saved = SavedMatch.played([.us, .us], ruleset: .pointsTo(target: 2, serveChangesEvery: 4))

        try store.save(saved)

        #expect(saved.match.state.outcome == .finished(winner: .us))
        #expect(try store.matchInProgress() == nil)
    }

    /// Незавершённость спрашивается у последнего матча, а не у всех подряд:
    /// брошенный месяц назад на 3:2 не должен воскресать на корте вместо
    /// нового матча.
    @Test("Продолжается последний матч, а не забытый позапрошлый")
    func onlyTheLatestMatchIsContinued() throws {
        let store = try SQLiteMatchStore.inMemory()
        let abandonedLongAgo = SavedMatch.played([.us, .them])
        let finishedToday = SavedMatch.played(
            [.us, .us],
            ruleset: .pointsTo(target: 2, serveChangesEvery: 4),
            from: aMoment.addingTimeInterval(30 * 24 * 3600))

        try store.save(abandonedLongAgo)
        try store.save(finishedToday)

        #expect(try store.matchInProgress() == nil)
    }

    @Test("Новый матч не затирает предыдущий")
    func aNewMatchDoesNotOverwriteTheOldOne() throws {
        let store = try SQLiteMatchStore.inMemory()
        let finishedYesterday = SavedMatch.played(
            [.us, .us], ruleset: .pointsTo(target: 2, serveChangesEvery: 4))
        let startedToday = SavedMatch.played(
            [.them], from: aMoment.addingTimeInterval(24 * 3600))

        try store.save(finishedYesterday)
        try store.save(startedToday)

        #expect(try store.matchInProgress() == startedToday)
    }

    /// Перезапуск приложения — это новое соединение к той же базе, и ничего
    /// больше: хранилище не держит матч в памяти, поэтому второе соединение
    /// видит ровно то, что записало первое.
    @Test("Матч продолжается после перезапуска приложения")
    func theMatchSurvivesARelaunch() throws {
        let database = "relaunch-\(UUID().uuidString)"
        let store = try SQLiteMatchStore.inMemory(named: database)
        let saved = SavedMatch.played([.us, .them, .us])

        try store.save(saved)

        let afterRelaunch = try SQLiteMatchStore.inMemory(named: database)

        #expect(try afterRelaunch.matchInProgress() == saved)
    }

    /// Пометка недоигранности — единственное, что о матче хранится колонкой, и
    /// проверяется она через то, ради чего существует: до прекращения матч
    /// предлагается продолжить, после — нет. Проверка ловит обе стороны рейса
    /// сразу. Не запишись пометка — матч вернулся бы из базы недоигранным
    /// наполовину и снова попал бы на корт; не прочитайся — то же самое.
    ///
    /// Прекращение приходит после того, как матч уже записан первым
    /// розыгрышем, поэтому пометка обязана доезжать обновлением строки, а не
    /// одной только вставкой.
    @Test("Прекращённый матч сохраняется недоигранным и продолжать не предлагается")
    func anAbandonedMatchIsSavedAndNotOfferedForContinuation() throws {
        let store = try SQLiteMatchStore.inMemory()
        var saved = SavedMatch.played([.us, .them, .us])

        try store.save(saved)

        #expect(try store.matchInProgress() == saved)

        saved.match.abandon()
        try store.save(saved)

        #expect(saved.match.state.outcome == .abandoned)
        #expect(try store.matchInProgress() == nil)
    }

    /// Перезапуск здесь не украшение: без него пометку было бы видно и из
    /// строки, которую никто не перечитывал.
    @Test("Пометка недоигранности переживает перезапуск приложения")
    func theAbandonedMarkSurvivesARelaunch() throws {
        let database = "abandoned-\(UUID().uuidString)"
        let store = try SQLiteMatchStore.inMemory(named: database)
        var saved = SavedMatch.played([.us, .them, .us])
        try store.save(saved)

        // До прекращения новое соединение к той же базе матч видит и
        // предлагает продолжить — иначе `nil` ниже ничего не доказывал бы.
        #expect(try SQLiteMatchStore.inMemory(named: database).matchInProgress() == saved)

        saved.match.abandon()
        try store.save(saved)

        #expect(try SQLiteMatchStore.inMemory(named: database).matchInProgress() == nil)
    }

    /// Журнал недоигранного матча — то, ради чего матч вообще сохраняется: час
    /// игры не должен пропасть от того, что кончилось время корта. Читается он
    /// здесь голым SQL, а не хранилищем, потому что продолжать недоигранный
    /// матч не предлагается, а API для чтения законченных появится вместе с
    /// тем, кому оно нужно, — историей на телефоне (тикеты 10, 11).
    @Test("Недоигранный матч сохраняется вместе со своим журналом")
    func anAbandonedMatchKeepsItsJournal() throws {
        let database = "journal-\(UUID().uuidString)"

        // Соединение открыто до хранилища и живёт дольше него: база в памяти
        // существует, пока к ней кто-то подключён.
        let queue = try DatabaseQueue(named: database)

        var saved = SavedMatch.played([.us, .them, .us, .us])
        saved.match.abandon()

        try SQLiteMatchStore.inMemory(named: database).save(saved)

        let id = saved.id.uuidString

        let (winners, abandoned) = try queue.read { db in
            (
                try String.fetchAll(
                    db,
                    sql: "SELECT winner FROM rally WHERE matchId = ? ORDER BY ordinal",
                    arguments: [id]),
                try Bool.fetchOne(
                    db, sql: "SELECT abandoned FROM match WHERE id = ?", arguments: [id])
            )
        }

        #expect(winners == ["us", "them", "us", "us"])
        #expect(abandoned == true)
    }
}
