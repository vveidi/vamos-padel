import PadelScoring
import SwiftUI

/// Корневой экран часов: пока матч идёт — счёт, как только он кончился — итог.
///
/// Матч живёт здесь целиком: набор правил и журнал розыгрышей. Стартовый экран
/// (тикет 06) и сохранение матча (тикет 07) появятся позже, поэтому набор
/// правил пока берётся по умолчанию — классический счёт, — а второй матч
/// начинается перезапуском приложения. До стартового экрана выбирать не из
/// чего, а классический счёт — то, чем падел является по умолчанию.
///
/// Здесь же матч обрастает тренировкой: она начинается вместе с ним и
/// заканчивается вместе с ним.
struct MatchView: View {
    @State private var match = Match(ruleset: .defaultClassic)

    @State private var workout: any Workout

    /// Тренировка приходит снаружи, а не создаётся здесь: превью не должно
    /// просить доступ к здоровью.
    init(workout: any Workout) {
        _workout = State(initialValue: workout)
    }

    var body: some View {
        let state = match.state

        Group {
            if let winner = state.outcome.winner {
                OutcomeView(winner: winner, score: state.finalScore, onUndo: { match.undo() })
            } else {
                ScoreView(
                    points: state.points,
                    games: state.games,
                    servingSide: state.servingSide,
                    onRallyWon: { match.record(rallyWonBy: $0) },
                    onUndo: { match.undo() })
            }
        }
        // Тренировка идёт ровно тогда, когда идёт матч. Условие написано через
        // `.inProgress`, а не через «есть победитель»: досрочно прекращённый
        // матч (тикет 09) станет третьим исходом, и тренировка должна
        // закончиться вместе с ним, не дожидаясь правки этой строки.
        //
        // Обратный переход существует не зря: отмена последнего розыгрыша
        // возвращает в игру матч, законченный ошибочным касанием (тикет 05), и
        // тогда начинается новая тренировка. В Health от этого остаётся две
        // записи вместо одной — цена за то, что доигранный после отмены матч
        // не остаётся без Always-On и без защиты от выгрузки. Явного «матч
        // окончен», по которому тренировку можно было бы закрывать один раз,
        // в приложении пока нет; он появится в тикете 09.
        .onChange(of: state.outcome == .inProgress, initial: true) { _, isInProgress in
            if isInProgress {
                workout.start()
            } else {
                workout.end()
            }
        }
    }
}

#Preview {
    MatchView(workout: NoWorkout())
}
