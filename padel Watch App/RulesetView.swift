import PadelScoring
import SwiftUI

/// Экран правил: набор правил и его параметры.
///
/// Открывается, только если игрок сам сюда пошёл, — и потому может позволить
/// себе список с регуляторами, тогда как стартовый экран не может позволить
/// себе ничего, кроме одного касания.
///
/// Границы значений задаются здесь, и это не перестраховка: движок намеренно
/// не судит о том, что ему передали (`MatchState`), — матч до нуля сетов он
/// доиграет как матч до одного, а не уронит приложение на корте. Осмысленность
/// чисел — вопрос экрана, на котором их выбирают.
struct RulesetView: View {
    @Binding var ruleset: Ruleset

    /// Числа обоих наборов правил разом.
    ///
    /// Экран помнит и то, что игрок выставил в другом наборе правил: заглянуть
    /// в соседний вариант и вернуться не должно стоить выставленных сетов.
    /// Наружу при этом уходит один набор правил — тот, что выбран.
    @State private var numbers: Numbers

    init(ruleset: Binding<Ruleset>) {
        _ruleset = ruleset
        _numbers = State(initialValue: Numbers(ruleset.wrappedValue))
    }

    var body: some View {
        List {
            Picker("Счёт", selection: $numbers.isClassic) {
                Text("классический").tag(true)
                Text("до N очков").tag(false)
            }

            if numbers.isClassic {
                Picker("Сеты", selection: $numbers.setsToWin) {
                    ForEach(Self.setsToWin, id: \.self) { Text("\($0)") }
                }

                Toggle("Золотое очко", isOn: $numbers.goldenPoint)
            } else {
                Picker("Очков (N)", selection: $numbers.target) {
                    ForEach(Self.targets, id: \.self) { Text("\($0)") }
                }

                Picker("Подача через (X)", selection: $numbers.serveChangesEvery) {
                    ForEach(Self.serveChanges, id: \.self) { Text("\($0)") }
                }
            }
        }
        .navigationTitle("Правила")
        // Выбранное уезжает наружу сразу, а не по кнопке «Готово»: на этом
        // экране нечего подтверждать, а лишнее касание — то, ради чего он и
        // спрятан за переходом.
        .onChange(of: numbers.ruleset, initial: false) { _, edited in ruleset = edited }
    }

    /// Матч до трёх выигранных сетов — это до пяти сыгранных, полный формат
    /// профессионального падела. Дальше в любительской компании не играют, и
    /// счёт по сетам на экране счёта рассчитан на одну цифру.
    private static let setsToWin = 1...3

    /// Нижняя граница — не арифметическая, а игровая: матч короче пяти очков
    /// кончается раньше, чем подача успевает перейти хоть раз. Верхняя взята
    /// с запасом над самым длинным, о чём договариваются на корте.
    private static let targets = 5...40

    /// «В разных компаниях это 2 или 4» — спека. Единица тоже осмысленна:
    /// подача переходит после каждого розыгрыша.
    private static let serveChanges = 1...6

    /// Параметры обоих наборов правил по отдельности — в том виде, в каком их
    /// правят регуляторами: у каждого числа свой, а набор правил из них
    /// собирается только целиком.
    private struct Numbers {
        var isClassic = true
        var setsToWin = 0
        var goldenPoint = false
        var target = 0
        var serveChangesEvery = 0

        /// Незанятая половина заполняется умолчаниями, и берутся они из самого
        /// `Ruleset`, а не переписываются числами: «N = 16, X = 4, один сет»
        /// живёт там, и второй копии у него быть не должно.
        init(_ ruleset: Ruleset) {
            take(.defaultClassic)
            take(.defaultPointsTo)

            // Последним — выбранный: он задаёт не только свои числа, но и то,
            // какой из двух наборов правил выбран.
            take(ruleset)
        }

        var ruleset: Ruleset {
            isClassic
                ? .classic(setsToWin: setsToWin, goldenPoint: goldenPoint)
                : .pointsTo(target: target, serveChangesEvery: serveChangesEvery)
        }

        /// Забирает числа набора правил, не трогая числа второго.
        private mutating func take(_ ruleset: Ruleset) {
            switch ruleset {
            case .classic(let setsToWin, let goldenPoint):
                isClassic = true
                self.setsToWin = setsToWin
                self.goldenPoint = goldenPoint
            case .pointsTo(let target, let serveChangesEvery):
                isClassic = false
                self.target = target
                self.serveChangesEvery = serveChangesEvery
            }
        }
    }
}

#Preview("Классический счёт") {
    @Previewable @State var ruleset = Ruleset.defaultClassic

    NavigationStack { RulesetView(ruleset: $ruleset) }
}

#Preview("Счёт до N очков") {
    @Previewable @State var ruleset = Ruleset.defaultPointsTo

    NavigationStack { RulesetView(ruleset: $ruleset) }
}
