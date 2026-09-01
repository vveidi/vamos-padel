import PadelScoring
import SwiftUI

/// Экран счёта и страница управления рядом с ним.
///
/// Прекратить матч нужно уметь с корта, а места на экране счёта нет: там
/// ровно две зоны касания и три величины, и любая кнопка отняла бы у них
/// пространство или перехватила бы касание, которым отдают очко. Поэтому
/// управление уезжает на соседнюю страницу — туда же, куда его убирает
/// системная тренировка: матч и так идёт внутри неё, а свайп к странице с
/// кнопкой «Завершить» — то, что игрок уже делал на этих часах.
///
/// Открывается всегда счёт, а не управление: страница управления нужна раз
/// за матч, счёт — между каждыми двумя розыгрышами.
struct ScorePages: View {
    let points: Points
    let games: SideCounts?
    let servingSide: Side
    let onRallyWon: (Side) -> Void
    let onUndo: () -> Void

    /// Прекращает матч досрочно. Подтверждение спрашивает страница управления,
    /// поэтому сюда приходит уже решённое.
    let onEnd: () -> Void

    @State private var page = Page.score

    private enum Page {
        case controls
        case score
    }

    var body: some View {
        TabView(selection: $page) {
            MatchControls(onEnd: onEnd)
                .tag(Page.controls)

            ScoreView(
                points: points,
                games: games,
                servingSide: servingSide,
                onRallyWon: onRallyWon,
                onUndo: onUndo)
                .tag(Page.score)
        }
        .tabViewStyle(.page)
    }
}

/// Страница управления: единственное, что можно сделать с идущим матчем
/// помимо счёта, — прекратить его.
private struct MatchControls: View {
    let onEnd: () -> Void

    @State private var isConfirming = false

    var body: some View {
        Button(role: .destructive) {
            isConfirming = true
        } label: {
            Label("Завершить", systemImage: "xmark")
        }
        .padding(.horizontal)
        // Подтверждение обязательно: свайп мокрой рукой и промах по кнопке —
        // ровно то, чем матч не должен обрываться. Оно же единственная защита
        // от случайного прекращения: обратно в игру матч не возвращается.
        .confirmationDialog(
            "Завершить матч?",
            isPresented: $isConfirming,
            titleVisibility: .visible
        ) {
            Button("Завершить", role: .destructive, action: onEnd)
            Button("Играть дальше", role: .cancel) {}
        } message: {
            Text("Матч сохранится недоигранным.")
        }
    }
}

#Preview {
    ScorePages(
        points: .game(SideCounts(us: 3, them: 2)),
        games: SideCounts(us: 4, them: 5),
        servingSide: .us,
        onRallyWon: { _ in },
        onUndo: {},
        onEnd: {})
}
