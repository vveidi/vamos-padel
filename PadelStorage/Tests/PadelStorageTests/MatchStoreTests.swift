import Foundation
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

        saved.match.abandon()
        try store.save(saved)

        let afterRelaunch = try SQLiteMatchStore.inMemory(named: database)

        #expect(try afterRelaunch.match(id: saved.id) == saved)
        #expect(try afterRelaunch.matchInProgress() == nil)
    }

    /// Круговой рейс недоигранного матча — то, что спека требует от Шва 2:
    /// «сохранённый матч читается обратно с тем же журналом, набором правил и
    /// пометкой недоигранности». Сравнение целиком проверяет все три сразу, а
    /// журнал здесь главное: час игры не должен пропасть от того, что
    /// кончилось время корта.
    ///
    /// Прекращение приходит после того, как матч уже записан первым
    /// розыгрышем, поэтому пометка обязана доезжать обновлением строки, а не
    /// одной только вставкой.
    @Test(
        "Недоигранный матч читается обратно с журналом, набором правил и пометкой",
        arguments: [
            Ruleset.classic(setsToWin: 2, goldenPoint: true),
            .pointsTo(target: 16, serveChangesEvery: 4),
        ])
    func anAbandonedMatchReadsBackUnchanged(ruleset: Ruleset) throws {
        let store = try SQLiteMatchStore.inMemory()
        var saved = SavedMatch.played([.us, .them, .us, .us], ruleset: ruleset)
        try store.save(saved)

        saved.match.abandon()
        try store.save(saved)

        let restored = try #require(try store.match(id: saved.id))

        #expect(restored == saved)
        #expect(restored.match.isAbandoned)
        #expect(
            restored.match.journal.rallies
                == [Rally(wonBy: .us), Rally(wonBy: .them), Rally(wonBy: .us), Rally(wonBy: .us)])
        #expect(restored.match.ruleset == ruleset)
    }

    @Test("Матча, которого не записывали, в хранилище нет")
    func anUnknownMatchIsNotFound() throws {
        #expect(try SQLiteMatchStore.inMemory().match(id: UUID()) == nil)
    }

    // MARK: Правила прошлого матча

    /// То, ради чего стартовый экран вообще спрашивает хранилище: компания
    /// играет по одним и тем же правилам месяцами, и выставлять их каждый раз
    /// заново — налог на то, что случается раз в полгода.
    @Test(
        "Правила прошлого матча помнятся",
        arguments: [
            Ruleset.classic(setsToWin: 2, goldenPoint: false),
            .classic(setsToWin: 1, goldenPoint: true),
            .pointsTo(target: 21, serveChangesEvery: 2),
        ])
    func theLastRulesetIsRemembered(ruleset: Ruleset) throws {
        let store = try SQLiteMatchStore.inMemory()

        try store.save(SavedMatch.played([.us, .them], ruleset: ruleset))

        #expect(try store.lastRuleset() == ruleset)
    }

    /// Законченный матч продолжать не предлагается, а правила его — предлагаются:
    /// обычный случай как раз такой, следующий матч начинают после доигранного.
    @Test("Правила помнятся и от законченного матча")
    func theRulesetOfAFinishedMatchIsRemembered() throws {
        let store = try SQLiteMatchStore.inMemory()
        let ruleset = Ruleset.pointsTo(target: 2, serveChangesEvery: 4)

        try store.save(SavedMatch.played([.us, .us], ruleset: ruleset))

        #expect(try store.matchInProgress() == nil)
        #expect(try store.lastRuleset() == ruleset)
    }

    @Test("Помнятся правила прошлого матча, а не позапрошлого")
    func theRulesetComesFromTheLatestMatch() throws {
        let store = try SQLiteMatchStore.inMemory()
        let today = Ruleset.classic(setsToWin: 3, goldenPoint: false)

        try store.save(SavedMatch.played([.us], ruleset: .defaultPointsTo))
        try store.save(
            SavedMatch.played(
                [.them], ruleset: today, from: aMoment.addingTimeInterval(24 * 3600)))

        #expect(try store.lastRuleset() == today)
    }

    /// Тот самый критерий: настройки переживают перезапуск приложения. Второе
    /// соединение к той же базе — это и есть перезапуск.
    @Test("Правила прошлого матча переживают перезапуск приложения")
    func theLastRulesetSurvivesARelaunch() throws {
        let database = "ruleset-\(UUID().uuidString)"
        let ruleset = Ruleset.pointsTo(target: 24, serveChangesEvery: 6)

        let store = try SQLiteMatchStore.inMemory(named: database)
        try store.save(SavedMatch.played([.us, .them], ruleset: ruleset))

        let afterRelaunch = try SQLiteMatchStore.inMemory(named: database)

        #expect(try afterRelaunch.lastRuleset() == ruleset)
    }

    /// Первый матч на новых часах: подставлять нечего, и стартовый экран
    /// показывает умолчания.
    @Test("В пустом хранилище правил прошлого матча нет")
    func anEmptyStoreRemembersNoRuleset() throws {
        #expect(try SQLiteMatchStore.inMemory().lastRuleset() == nil)
    }

    // MARK: История

    @Test("История отдаётся от свежих матчей к старым")
    func historyStartsWithTheFreshestMatch() throws {
        let store = try SQLiteMatchStore.inMemory()
        let earlier = SavedMatch.played([.us, .them])
        let later = SavedMatch.played([.them], from: aMoment.addingTimeInterval(3600))

        try store.save(earlier)
        try store.save(later)

        #expect(try store.matches() == [later, earlier])
    }

    @Test("В пустом хранилище истории нет")
    func anEmptyStoreHasNoHistory() throws {
        #expect(try SQLiteMatchStore.inMemory().matches().isEmpty)
    }

    /// Матч, доигранный заново после отмены очка, — не продолжение прошлой
    /// версии, а другой журнал той же длины. Дописать его хвостом значило бы
    /// собрать журнал, которого никто не играл, и молча: длина сходится.
    /// Случается это на телефоне, куда матч приезжает второй раз (тикет 10).
    @Test("Разошедшийся журнал перезаписывается, а не дописывается")
    func adivergedJournalIsRewritten() throws {
        let store = try SQLiteMatchStore.inMemory()

        var saved = SavedMatch.played([.us, .us, .us])
        try store.save(saved)

        saved.match.undo()
        saved.match.undo()
        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(60))
        saved.record(rallyWonBy: .them, at: aMoment.addingTimeInterval(90))

        try store.save(saved)

        #expect(try store.match(id: saved.id) == saved)
    }

    // MARK: Очередь на доставку

    /// Очередь на доставку — само хранилище, а не список рядом с ним: то, что
    /// уже записано после каждого розыгрыша, незачем переписывать во вторую
    /// очередь, которая с первой разойдётся.
    @Test("Законченный матч ждёт доставки")
    func aFinishedMatchAwaitsDelivery() throws {
        let store = try SQLiteMatchStore.inMemory()
        let saved = SavedMatch.played([.us, .us], ruleset: .pointsTo(target: 2, serveChangesEvery: 4))

        try store.save(saved)

        #expect(try store.matchesAwaitingDelivery() == [saved])
    }

    @Test("Идущий матч доставки не ждёт")
    func aMatchInProgressAwaitsNothing() throws {
        let store = try SQLiteMatchStore.inMemory()

        try store.save(SavedMatch.played([.us]))

        #expect(try store.matchesAwaitingDelivery().isEmpty)
    }

    /// Недоигранный матч — тоже законченный: игра в нём кончилась, и в истории
    /// на телефоне ему место наравне с остальными.
    @Test("Недоигранный матч ждёт доставки")
    func anAbandonedMatchAwaitsDelivery() throws {
        let store = try SQLiteMatchStore.inMemory()
        var saved = SavedMatch.played([.us, .them])
        saved.match.abandon()

        try store.save(saved)

        #expect(try store.matchesAwaitingDelivery() == [saved])
    }

    @Test("Отмеченный доставленным матч из очереди уходит")
    func aDeliveredMatchLeavesTheQueue() throws {
        let store = try SQLiteMatchStore.inMemory()
        let saved = SavedMatch.played([.us, .us], ruleset: .pointsTo(target: 2, serveChangesEvery: 4))

        try store.save(saved)
        try store.markDelivered(id: saved.id)

        #expect(try store.matchesAwaitingDelivery().isEmpty)
    }

    /// Отметка о доставке гаснет с любой записью матча: доставленной осталась
    /// версия, которая с этого момента расходится с той, что на часах.
    @Test("Изменившийся после доставки матч возвращается в очередь")
    func aChangedMatchReturnsToTheQueue() throws {
        let store = try SQLiteMatchStore.inMemory()
        var saved = SavedMatch.played([.us, .us], ruleset: .pointsTo(target: 2, serveChangesEvery: 4))

        try store.save(saved)
        try store.markDelivered(id: saved.id)

        saved.match.abandon()
        try store.save(saved)

        #expect(try store.matchesAwaitingDelivery() == [saved])
    }

    @Test("Доставка отмечается тому матчу, которому обещали")
    func onlyTheNamedMatchIsMarkedDelivered() throws {
        let store = try SQLiteMatchStore.inMemory()
        let toTwo = Ruleset.pointsTo(target: 2, serveChangesEvery: 4)
        let delivered = SavedMatch.played([.us, .us], ruleset: toTwo)
        let waiting = SavedMatch.played(
            [.them, .them], ruleset: toTwo, from: aMoment.addingTimeInterval(3600))

        try store.save(delivered)
        try store.save(waiting)
        try store.markDelivered(id: delivered.id)

        #expect(try store.matchesAwaitingDelivery() == [waiting])
    }
}
