import PadelScoring
import PadelStorage
import PadelDelivery
import SwiftUI
import os

/// Идущий матч: пока он не кончился — счёт, как только кончился — итог.
///
/// Матч приходит снаружи уже начатым: набор правил и первую подачу спросил
/// стартовый экран, а продолжить прерванный решил корень приложения. Дальше
/// матч живёт здесь и наружу не возвращается — корню довольно знать, что он
/// есть.
///
/// Здесь же он обрастает тем, ради чего переживает полтора часа на корте:
/// тренировкой, которая идёт ровно столько же, сколько матч, записью в
/// хранилище после каждого розыгрыша и отправкой на телефон, как только он
/// кончился.
struct MatchView: View {
    /// Матч и время, когда он игрался.
    @State private var saved: SavedMatch

    private let store: any MatchStore

    @State private var workout: any Workout

    private let delivery: MatchDelivery

    /// Уводит с матча на стартовый экран. Зовётся только с экрана итога:
    /// начать новый матч посреди идущего — это его прекратить, а для этого
    /// есть страница управления.
    private let onFinish: () -> Void

    /// Хранилище, тренировка и доставка приходят снаружи, а не создаются
    /// здесь: превью не должно ни просить доступ к здоровью, ни заводить базу,
    /// ни поднимать сессию к телефону.
    init(
        match: SavedMatch,
        store: any MatchStore,
        workout: any Workout,
        delivery: MatchDelivery,
        onFinish: @escaping () -> Void
    ) {
        _saved = State(initialValue: match)
        self.store = store
        _workout = State(initialValue: workout)
        self.delivery = delivery
        self.onFinish = onFinish
    }

    var body: some View {
        let state = saved.match.state

        Group {
            if state.outcome.isOver {
                OutcomeView(
                    winner: state.outcome.winner,
                    score: state.finalScore,
                    onUndo: undo,
                    onFinish: onFinish)
            } else {
                ScorePages(
                    points: state.points,
                    games: state.games,
                    sets: setsWorthShowing(state),
                    servingSide: state.servingSide,
                    onRallyWon: record(rallyWonBy:),
                    onUndo: undo,
                    onAbandon: abandon)
            }
        }
        // Тренировка идёт ровно тогда, когда идёт матч. Условие написано через
        // `.inProgress`, а не через «есть победитель», и потому одинаково
        // закрывает тренировку и у доигранного матча, и у прекращённого
        // досрочно: у второго победителя нет, но игра в нём кончилась, и
        // держать ради него Always-On и разбуженное приложение незачем.
        //
        // Обратный переход существует не зря: отмена последнего розыгрыша
        // возвращает в игру матч, законченный ошибочным касанием (тикет 05), и
        // тогда начинается новая тренировка. В Health от этого остаётся две
        // записи вместо одной — цена за то, что доигранный после отмены матч
        // не остаётся без Always-On и без защиты от выгрузки. Прекращённый
        // досрочно матч в игру не возвращается, и его тренировка закрывается
        // один раз.
        .onChange(of: state.outcome == .inProgress, initial: true) { _, isInProgress in
            if isInProgress {
                workout.start()
            } else {
                workout.end()
            }
        }
    }

    /// Счёт по сетам показывается только там, где он что-то говорит: в матче
    /// до одного сета он равен 0:0 до последнего розыгрыша, а в матче до двух
    /// без него геймы врут — они обнуляются с каждым сетом. Спрашивается это
    /// у набора правил, а не у сыгранного: недоигранный матч до двух сетов
    /// может не досчитать ни одного, и это не повод выдать счёт текущего сета
    /// за счёт матча.
    private func setsWorthShowing(_ state: MatchState) -> SideCounts? {
        saved.match.ruleset.isMultiSet ? state.sets : nil
    }

    private func record(rallyWonBy side: Side) {
        saved.record(rallyWonBy: side, at: .now)

        persist()
    }

    private func undo() {
        saved.match.undo()

        persist()
    }

    /// Матч уже записан, и прекращение дописывает ему одну пометку. Экран
    /// итога и конец тренировки приходят следом сами: и то и другое смотрит
    /// на исход, а он теперь недоигранный.
    ///
    /// Подтверждение спрашивает страница управления, а не этот метод: сюда
    /// приходит уже решённое.
    private func abandon() {
        saved.match.abandon()

        persist()
    }

    /// Запись после каждого розыгрыша, а не в конце матча: матч, прерванный на
    /// середине, восстанавливается ровно потому, что уже записан.
    ///
    /// Неудача записи до матча не долетает — по той же причине, по которой до
    /// него не долетает неудача тренировки: счёт на корте важнее всего, ради
    /// чего его записывают.
    private func persist() {
        do {
            try store.save(saved)
        } catch {
            logger.error("Матч не сохранён: \(error.localizedDescription)")
        }

        // Матч кончился — его пора везти на телефон, и игрок для этого ничего
        // не нажимает. Спрашивается это здесь, а не в самой доставке, только
        // ради того, чтобы не ходить в базу за очередью после каждого очка:
        // пока матч идёт, очередь заведомо пуста.
        //
        // Отправка идёт после записи и не раньше: очередь на доставку — это
        // само хранилище, и уехать может только записанное.
        if saved.match.state.outcome.isOver {
            delivery.deliverPending()
        }
    }
}

#Preview {
    MatchView(
        match: SavedMatch(match: Match(ruleset: .defaultClassic), startedAt: .now),
        store: NoMatchStore(),
        workout: NoWorkout(),
        delivery: MatchDelivery(store: NoMatchStore(), sender: NoMatchTransport()),
        onFinish: {})
}

private let logger = Logger(subsystem: "com.vveidi.padel.watchkitapp", category: "match")
