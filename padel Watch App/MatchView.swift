import PadelScoring
import PadelStorage
import SwiftUI
import os

/// Корневой экран часов: пока матч идёт — счёт, как только он кончился — итог.
///
/// Матч живёт здесь целиком: набор правил, журнал розыгрышей и время, когда
/// он игрался. Стартовый экран (тикет 06) появится позже, поэтому набор правил
/// пока берётся по умолчанию — классический счёт, — а второй матч начинается
/// перезапуском приложения. До стартового экрана выбирать не из чего, а
/// классический счёт — то, чем падел является по умолчанию.
///
/// Здесь же матч обрастает тем, ради чего он переживает полтора часа на корте:
/// тренировкой, которая идёт ровно столько же, сколько матч, и записью в
/// хранилище после каждого розыгрыша.
struct MatchView: View {
    /// Матч, с которого начинают, если продолжать нечего. Он же стоит здесь
    /// первые доли секунды, пока хранилище не ответило.
    @State private var saved = SavedMatch(match: Match(ruleset: .defaultClassic), startedAt: .now)

    private let store: any MatchStore

    @State private var workout: any Workout

    /// Хранилище и тренировка приходят снаружи, а не создаются здесь: превью
    /// не должно ни просить доступ к здоровью, ни заводить базу.
    init(store: any MatchStore, workout: any Workout) {
        self.store = store
        _workout = State(initialValue: workout)
    }

    var body: some View {
        let state = saved.match.state

        Group {
            if state.outcome.isOver {
                OutcomeView(
                    winner: state.outcome.winner, score: state.finalScore, onUndo: undo)
            } else {
                ScorePages(
                    points: state.points,
                    games: state.games,
                    servingSide: state.servingSide,
                    onRallyWon: record(rallyWonBy:),
                    onUndo: undo,
                    onEnd: endMatch)
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
        .task { continueMatchInProgress() }
    }

    private func record(rallyWonBy side: Side) {
        saved.record(rallyWonBy: side, at: .now)

        persist()
    }

    private func undo() {
        saved.match.undo()

        persist()
    }

    /// Прекращает матч досрочно: кончилось время корта, пошёл дождь, кто-то
    /// потянул спину.
    ///
    /// Час игры при этом не пропадает — матч уже записан, и дописывается ему
    /// одна пометка. Экран итога и конец тренировки приходят следом сами:
    /// и то и другое смотрит на исход, а он теперь недоигранный.
    ///
    /// Подтверждение спрашивает страница управления, а не этот метод: сюда
    /// приходит уже решённое.
    private func endMatch() {
        saved.match.abandon()

        persist()
    }

    /// Продолжает матч, начатый до того, как приложение выгрузили.
    ///
    /// Спрашивается только пока не сыграно ни одного розыгрыша: подменить
    /// журнал под руками игрока, который уже считает очки, хуже, чем не
    /// восстановить ничего.
    private func continueMatchInProgress() {
        guard saved.match.journal.isEmpty else { return }

        do {
            guard let inProgress = try store.matchInProgress() else { return }

            saved = inProgress
        } catch {
            logger.error("Матч не восстановлен: \(error.localizedDescription)")
        }
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
    }
}

#Preview {
    MatchView(store: NoMatchStore(), workout: NoWorkout())
}

private let logger = Logger(subsystem: "com.vveidi.padel.watchkitapp", category: "match")
