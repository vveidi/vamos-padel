import PadelScoring
import SwiftUI

/// Экраны истории появятся в тикетах 11 и 12. Пока приложение доказывает, что
/// доменные типы пакета `PadelScoring` видны и с этой стороны тоже.
struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "figure.tennis")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Сторон на корте: \(Side.allCases.count)")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
