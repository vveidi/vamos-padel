import PadelDesign
import SwiftUI

/// Why a paired start on the wrist did not reach a match on the phone.
enum PhoneRefusal {
    case unreachable

    /// A match the phone scores alone, which the watch never takes over.
    case scoringItsOwnMatch
}

/// Up in place of a paired match the phone could not start. Never falls back on
/// its own: starting alone is the player's tap.
struct PhoneCannotPair: View {
    let refusal: PhoneRefusal

    let onStartAlone: () -> Void

    let onCancel: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Board.gap) {
                Image(systemName: "iphone.slash")
                    .textStyle(.display)
                    .foregroundStyle(Color.ball)
                    .accessibilityHidden(true)

                Text(reason)
                    .textStyle(.control)
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.center)

                PillButton(Text("Start on Watch alone"), action: onStartAlone)

                PillButton(Text("Cancel"), variant: .quiet, action: onCancel)
            }
            .padding(.horizontal, Board.inset)
        }
        .background { Color.night.ignoresSafeArea() }
    }

    private var reason: LocalizedStringKey {
        switch refusal {
        case .unreachable: "iPhone unreachable"
        case .scoringItsOwnMatch: "iPhone is scoring a match of its own"
        }
    }
}

/// No board; the gaps are ``WaitingForPhone``'s.
private enum Board {
    static let inset: CGFloat = 8

    static let gap: CGFloat = 12
}

#if DEBUG

private func inRussian(_ view: some View) -> some View {
    view.environment(\.locale, Locale(identifier: "ru"))
}

private func atLargestType(_ view: some View) -> some View {
    view.environment(\.dynamicTypeSize, .accessibility5)
}

private func refused(_ refusal: PhoneRefusal) -> some View {
    PhoneCannotPair(refusal: refusal, onStartAlone: {}, onCancel: {})
}

#Preview("iPhone unreachable") { refused(.unreachable) }

#Preview("In Russian: iPhone unreachable") { inRussian(refused(.unreachable)) }

#Preview("iPhone scoring its own match") { refused(.scoringItsOwnMatch) }

#Preview("In Russian: iPhone scoring its own match") { inRussian(refused(.scoringItsOwnMatch)) }

#Preview("In Russian, at the largest type") { atLargestType(inRussian(refused(.scoringItsOwnMatch))) }

#endif
