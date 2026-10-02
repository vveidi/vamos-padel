import PadelDesign
import SwiftUI

/// Up from the paired start until the match arrives. The start can be lost on
/// the way and nothing says so, which is what the cancel is for.
struct WaitingForPhone: View {
    let onCancel: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Board.gap) {
                ProgressView()

                Text("Starting on iPhone…")
                    .textStyle(.control)
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.center)

                PillButton(Text("Cancel"), variant: .quiet, action: onCancel)
            }
            .padding(.horizontal, Board.inset)
        }
        .background { Color.night.ignoresSafeArea() }
    }
}

/// No board; the gaps are the outcome screen's.
private enum Board {
    static let inset: CGFloat = 8

    static let gap: CGFloat = 12
}

#if DEBUG

#Preview { WaitingForPhone(onCancel: {}) }

#Preview("In Russian") { WaitingForPhone(onCancel: {}).environment(\.locale, Locale(identifier: "ru")) }

#Preview("At the largest type") {
    WaitingForPhone(onCancel: {}).environment(\.dynamicTypeSize, .accessibility5)
}

#endif
