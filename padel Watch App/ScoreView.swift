import PadelScoring
import SwiftUI

/// Экран счёта: две равные зоны во весь экран, по одной на сторону.
///
/// Соперники сверху, мы снизу — так же, как на корте: они за сеткой, перед
/// нами. Попадать в свою половину нужно не глядя и мокрой рукой, поэтому зоны
/// делят экран пополам и ничем, кроме очков, не заняты.
struct ScoreView: View {
    /// Наша сторона узнаётся по цвету, а не по подписи: подпись отняла бы
    /// место у цифры, ради которой на часы и смотрят. Цвет живёт здесь, а не
    /// в акцентном цвете приложения, потому что это решение экрана счёта.
    static let ourColor = Color(red: 0.188, green: 0.820, blue: 0.345)

    let points: SideCounts
    let onRallyWon: (Side) -> Void

    var body: some View {
        VStack(spacing: 2) {
            ScoreZone(side: .them, points: points[.them], onRallyWon: onRallyWon)
            ScoreZone(side: .us, points: points[.us], onRallyWon: onRallyWon)
        }
        .ignoresSafeArea()
    }
}

/// Половина экрана, принадлежащая одной стороне: её очки и её касание.
private struct ScoreZone: View {
    let side: Side
    let points: Int
    let onRallyWon: (Side) -> Void

    var body: some View {
        Button {
            onRallyWon(side)
        } label: {
            Text("\(points)")
                .font(.system(size: 64, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(background)
                // Иначе касание ловит только сама цифра, а не вся половина.
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue("\(points)")
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
}

#Preview {
    ScoreView(points: SideCounts(us: 12, them: 9)) { _ in }
}
