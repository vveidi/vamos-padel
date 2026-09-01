import PadelScoring
import SwiftUI

/// Итог матча — то, что видно сразу после последнего розыгрыша или после
/// того, как матч прекратили досрочно.
struct OutcomeView: View {
    /// Сторона, выигравшая матч, или `nil`, если матч остался недоигранным.
    ///
    /// Именно `nil`, а не «выиграли соперники»: недоигранный матч не считается
    /// ни победой, ни поражением, и экран — последнее место, где эту разницу
    /// можно было бы потерять.
    let winner: Side?

    /// Счёт, которым матч запомнится: геймы в классическом счёте, очки в счёте
    /// до N очков. Выбирает его набор правил, а не этот экран.
    let score: SideCounts

    let onUndo: () -> Void

    var body: some View {
        Group {
            if let winner { finished(winner) } else { unfinished }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal)
        .contentShape(Rectangle())
    }

    private func finished(_ winner: Side) -> some View {
        outcome(
            headline: winner == .us ? "Мы выиграли" : "Выиграли соперники",
            isOurs: winner == .us
        ) {
            // Первым идёт счёт победителя — той стороны, которую назвала
            // строка выше. Иначе итог читается задом наперёд: на экране счёта
            // соперники сверху, а тут они шли бы вторыми.
            Text("\(score[winner]) : \(score[winner.opposite])")
        }
        // Тот же жест, что на экране счёта. Без него матч, законченный
        // ошибочным касанием, отменить нечем: этот экран занимает место того,
        // на котором жест живёт.
        //
        // У недоигранного матча жеста нет: прекращение — не розыгрыш, отменой
        // очка оно не снимается, и жест, который на вид работает, а на деле
        // только меняет счёт уже прекращённого матча, хуже, чем его
        // отсутствие. От случайного прекращения защищает подтверждение.
        .onLongPressGesture(minimumDuration: 0.5) { onUndo() }
        .accessibilityAction(named: "Отменить последний розыгрыш", onUndo)
    }

    private var unfinished: some View {
        outcome(headline: "Матч не доигран", isOurs: false) {
            // Кто есть кто, говорит цвет — тот же, которым помечена наша
            // половина экрана счёта. Победителя, который задал бы порядок,
            // здесь нет, а подпись «мы» отняла бы место у счёта.
            (Text("\(score[.us])").foregroundStyle(ScoreView.ourColor)
                + Text(" : \(score[.them])"))
                .accessibilityLabel("У нас \(score[.us]), у соперников \(score[.them])")
        }
    }

    private func outcome(
        headline: String, isOurs: Bool, @ViewBuilder score: () -> some View
    ) -> some View {
        VStack(spacing: 8) {
            Text(headline)
                .font(.headline)
                .foregroundStyle(isOurs ? ScoreView.ourColor : .secondary)

            score()
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
    }
}

#Preview("Победа") {
    OutcomeView(winner: .us, score: SideCounts(us: 6, them: 4), onUndo: {})
}

#Preview("Недоигранный матч") {
    OutcomeView(winner: nil, score: SideCounts(us: 3, them: 5), onUndo: {})
}
