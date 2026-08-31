import PadelScoring
import SwiftUI

/// Корневой экран часов: пока матч идёт — счёт, как только он кончился — итог.
///
/// Матч живёт здесь целиком: набор правил и журнал розыгрышей. Стартовый экран
/// (тикет 06) и сохранение матча (тикет 07) появятся позже, поэтому набор
/// правил пока берётся по умолчанию — счёт до 16 очков, — а второй матч
/// начинается перезапуском приложения.
struct MatchView: View {
    @State private var match = Match(ruleset: .defaultPointsTo)

    var body: some View {
        let state = match.state

        if let winner = state.outcome.winner {
            OutcomeView(winner: winner, points: state.points)
        } else {
            ScoreView(points: state.points) { side in
                match.record(rallyWonBy: side)
            }
        }
    }
}

#Preview {
    MatchView()
}
