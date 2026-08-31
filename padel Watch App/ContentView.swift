import PadelScoring
import SwiftUI

/// Экрана счёта здесь пока нет — он появится в тикете 02 вместе с движком.
/// Приложение доказывает ровно две вещи: что оно запускается на часах и что
/// доменные типы пакета `PadelScoring` ему видны.
struct ContentView: View {
    var body: some View {
        Text("Сторон на корте: \(Side.allCases.count)")
            .multilineTextAlignment(.center)
    }
}

#Preview {
    ContentView()
}
