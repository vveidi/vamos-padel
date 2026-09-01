import PadelScoring
import SwiftUI

/// Корневой экран часов: пока матч идёт — счёт, как только он кончился — итог.
///
/// Матч живёт здесь целиком: набор правил и журнал розыгрышей. Стартовый экран
/// (тикет 06) и сохранение матча (тикет 07) появятся позже, поэтому набор
/// правил пока берётся по умолчанию — классический счёт, — а второй матч
/// начинается перезапуском приложения. До стартового экрана выбирать не из
/// чего, а классический счёт — то, чем падел является по умолчанию.
struct MatchView: View {
    @State private var match = Match(ruleset: .defaultClassic)

    var body: some View {
        let state = match.state

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
}

#Preview {
    MatchView()
}
