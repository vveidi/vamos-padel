import PadelScoring
import SwiftUI

/// Итог матча — то, что видно сразу после последнего розыгрыша.
///
/// Досрочно прекращённый матч (тикет 09) сюда пока не приходит: единственный
/// способ закончить матч — набрать N очков.
struct OutcomeView: View {
    let winner: Side

    /// Счёт, которым матч запомнится: геймы в классическом счёте, очки в счёте
    /// до N очков. Выбирает его набор правил, а не этот экран.
    let score: SideCounts

    var body: some View {
        VStack(spacing: 8) {
            Text(headline)
                .font(.headline)
                .foregroundStyle(winner == .us ? ScoreView.ourColor : .secondary)

            // Первым идёт счёт победителя — той стороны, которую назвала
            // строка выше. Иначе итог читается задом наперёд: на экране счёта
            // соперники сверху, а тут они шли бы вторыми.
            Text("\(score[winner]) : \(score[winner.opposite])")
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .padding(.horizontal)
    }

    private var headline: String {
        switch winner {
        case .us: "Мы выиграли"
        case .them: "Выиграли соперники"
        }
    }
}

#Preview {
    OutcomeView(winner: .us, score: SideCounts(us: 6, them: 4))
}
