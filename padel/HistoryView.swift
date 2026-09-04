import PadelScoring
import PadelStorage
import SwiftUI
import os

/// История матчей на телефоне — пока в самом грубом виде.
///
/// Настоящий список с длительностью и набором правил делает тикет 11; здесь
/// ровно столько, чтобы приехавший с часов матч было видно глазами, а не
/// только в базе.
///
/// Матч приезжает в приложение, разбуженное системой ради него одного, и экран
/// об этом никак не узнаёт. Пока он не наблюдает за базой — это тоже тикет 11 —
/// история перечитывается на возвращении в активное состояние и по жесту
/// обновления: матч, приехавший под открытым экраном, иначе не появился бы
/// вовсе.
struct HistoryView: View {
    private let store: any MatchStore

    @State private var matches: [SavedMatch] = []

    /// Матч приезжает в приложение, свёрнутое в фон, — экран узнаёт об этом,
    /// когда его снова открыли.
    @Environment(\.scenePhase) private var scenePhase

    init(store: any MatchStore) {
        self.store = store
    }

    var body: some View {
        NavigationStack {
            Group {
                if matches.isEmpty {
                    ContentUnavailableView(
                        "Матчей пока нет",
                        systemImage: "figure.tennis",
                        description: Text("Сыгранный на часах матч появится здесь сам"))
                } else {
                    List(matches) { match in
                        row(match)
                    }
                    .refreshable { reload() }
                }
            }
            .navigationTitle("История")
        }
        .task { reload() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { reload() }
        }
    }

    private func row(_ saved: SavedMatch) -> some View {
        let state = saved.match.state

        return VStack(alignment: .leading, spacing: 2) {
            Text("\(state.finalScore.us) : \(state.finalScore.them)")
                .font(.headline)

            Text(saved.startedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)

            if state.outcome == .abandoned {
                Text("недоигранный")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func reload() {
        do {
            matches = try store.matches()
        } catch {
            logger.error("История не прочитана: \(error.localizedDescription)")
        }
    }
}

#Preview {
    HistoryView(store: NoMatchStore())
}

private let logger = Logger(subsystem: "com.vveidi.padel", category: "history")
