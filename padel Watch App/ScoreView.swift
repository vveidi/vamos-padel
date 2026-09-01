import PadelScoring
import SwiftUI

/// Экран счёта: две равные зоны во весь экран, по одной на сторону.
///
/// Соперники сверху, мы снизу — так же, как на корте: они за сеткой, перед
/// нами. Попадать в свою половину нужно не глядя и мокрой рукой, поэтому зоны
/// делят экран пополам и ничем, кроме счёта, не заняты.
struct ScoreView: View {
    /// Наша сторона узнаётся по цвету, а не по подписи: подпись отняла бы
    /// место у цифры, ради которой на часы и смотрят. Цвет живёт здесь, а не
    /// в акцентном цвете приложения, потому что это решение экрана счёта.
    static let ourColor = Color(red: 0.188, green: 0.820, blue: 0.345)

    let points: Points

    /// Геймы текущего сета; в счёте до N очков их нет, и тогда зона занята
    /// одними очками.
    let games: SideCounts?

    let servingSide: Side

    let onRallyWon: (Side) -> Void

    var body: some View {
        VStack(spacing: 2) {
            zone(for: .them)
            zone(for: .us)
        }
        .ignoresSafeArea()
    }

    private func zone(for side: Side) -> some View {
        ScoreZone(
            side: side,
            pointsLabel: points.label(for: side),
            games: games?[side],
            isServing: side == servingSide,
            onRallyWon: onRallyWon)
    }
}

/// Половина экрана, принадлежащая одной стороне: её счёт и её касание.
private struct ScoreZone: View {
    let side: Side

    /// Именно подпись, а не число: в гейме здесь стоит «40» или «AD».
    let pointsLabel: String

    let games: Int?
    let isServing: Bool
    let onRallyWon: (Side) -> Void

    var body: some View {
        Button {
            onRallyWon(side)
        } label: {
            // Геймы стоят рядом с очками, а не отдельной строкой посреди
            // экрана: половина остаётся одним предметом, на который смотрят,
            // и вертикаль не тратится на третий ярус. Общая базовая линия
            // держит их одним счётом, а не двумя числами по соседству.
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                // Кегль и предел сжатия — те же, что были у очков до появления
                // геймов: геймы встали рядом, но ужимать ради них цифру, ради
                // которой на часы и смотрят, не должны.
                Text(pointsLabel)
                    .font(.system(size: 64, weight: .semibold, design: .rounded))
                    .minimumScaleFactor(0.4)
                    .foregroundStyle(.white)

                if let games {
                    Text("\(games)")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Точка стоит у края, а не в строке со счётом: иначе цифра
            // съезжала бы с центра зоны при каждом переходе подачи, и взгляд
            // ловил бы её заново. Место под точку занято всегда — видимость
            // меняется, разметка нет.
            .overlay(alignment: .leading) {
                Circle()
                    .frame(width: 10, height: 10)
                    .padding(.leading, 12)
                    .foregroundStyle(.white)
                    .opacity(isServing ? 0.9 : 0)
            }
            .background(background)
            // Иначе касание ловит только сам счёт, а не вся половина.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
    }

    private var background: Color {
        switch side {
        case .us: ScoreView.ourColor.opacity(0.35)
        case .them: .white.opacity(0.1)
        }
    }

    private var accessibilityLabel: String {
        switch side {
        case .us: "Очко нам"
        case .them: "Очко соперникам"
        }
    }

    private var accessibilityValue: String {
        var value = pointsLabel

        if let games { value += ", геймов \(games)" }
        if isServing { value += ", подача" }

        return value
    }
}

#Preview("Классический счёт") {
    ScoreView(
        points: .game(SideCounts(us: 3, them: 2)),
        games: SideCounts(us: 4, them: 5),
        servingSide: .us
    ) { _ in }
}

#Preview("Счёт до N очков") {
    ScoreView(points: .count(SideCounts(us: 12, them: 9)), games: nil, servingSide: .them) { _ in }
}
