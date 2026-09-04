import PadelScoring
import SwiftUI

/// Экран, с которого начинается матч.
///
/// Главное здесь — скорость. Компания играет по одним и тем же правилам
/// месяцами, поэтому правила прошлого матча уже подставлены, а спрашивается
/// ровно то, что меняется каждый раз, — чья первая подача. Она же и начинает
/// матч: касание, которым игрок называет подающую сторону, и есть то самое
/// «начать одним касанием». Отдельная кнопка «Начать» рядом с выбором подачи
/// была бы вторым касанием, которое не сообщает ничего нового.
///
/// Экран правил лежит за переходом: настройка, которую спрашивают перед каждым
/// матчем, — налог на то, что случается раз в полгода.
struct StartView: View {
    /// Набор правил, с которым начнётся матч. Меняет его экран правил, а
    /// помнит — хранилище: сюда он приходит от прошлого матча.
    @Binding var ruleset: Ruleset

    /// Начинает матч с указанной первой подачей.
    let onStart: (Side) -> Void

    var body: some View {
        NavigationStack {
            List {
                // Соперники сверху, мы снизу — так же, как на экране счёта и
                // как на корте: они за сеткой, перед нами. Цвета те же, и
                // потому половина, в которую игрок будет весь матч тыкать за
                // свои очки, узнаётся ещё до первого розыгрыша.
                serve(.them)
                serve(.us)

                NavigationLink {
                    RulesetView(ruleset: $ruleset)
                } label: {
                    rules
                }
            }
            .navigationTitle("Начать матч")
        }
    }

    private func serve(_ side: Side) -> some View {
        Button {
            onStart(side)
        } label: {
            Text(side == .us ? "Подаём мы" : "Подают соперники")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 34)
        }
        .buttonStyle(.plain)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 12)
                .fill(side == .us ? ScoreView.ourColor.opacity(0.35) : .white.opacity(0.12)))
    }

    /// Правила видно, а трогать их не нужно: строка говорит, по чему сегодня
    /// играем, и открывает экран, где это меняют.
    private var rules: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(Self.name(of: ruleset))
                .font(.footnote)

            Text(Self.parameters(of: ruleset))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    /// Название набора правил — то, как его называет глоссарий. Числа сюда не
    /// подставляются: «Счёт до 21 очков» пришлось бы склонять, а «Счёт до N
    /// очков» — это имя, и N в нём объясняет строку под ним.
    private static func name(of ruleset: Ruleset) -> String {
        switch ruleset {
        case .classic: "Классический счёт"
        case .pointsTo: "Счёт до N очков"
        }
    }

    private static func parameters(of ruleset: Ruleset) -> String {
        switch ruleset {
        case .classic(let setsToWin, let goldenPoint):
            "\(sets(setsToWin)) · \(goldenPoint ? "золотое очко" : "без золотого очка")"
        case .pointsTo(let target, let serveChangesEvery):
            "N = \(target) · X = \(serveChangesEvery)"
        }
    }

    /// Больше трёх сетов экран правил не предлагает, поэтому падежей ровно два.
    private static func sets(_ count: Int) -> String {
        count == 1 ? "1 сет" : "\(count) сета"
    }
}

#Preview("Классический счёт") {
    @Previewable @State var ruleset = Ruleset.defaultClassic

    StartView(ruleset: $ruleset, onStart: { _ in })
}

#Preview("Счёт до N очков") {
    @Previewable @State var ruleset = Ruleset.pointsTo(target: 21, serveChangesEvery: 2)

    StartView(ruleset: $ruleset, onStart: { _ in })
}
