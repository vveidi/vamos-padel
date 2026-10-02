import PadelDesign
import PadelScoring
import SwiftUI
import WatchKit

/// The score screen owns every point of its own surface as a tap zone, so the
/// controls cannot share it: a button there would swallow the tap that awards
/// a point.
struct ScorePages: View {
    let points: Points
    let games: SideCounts?
    let sets: SideCounts?
    let servingSide: Side
    let servingHalf: ServingHalf?
    @Binding var tapMode: TapMode
    let mark: RallyMark?

    /// Only ever `true` in a paired match: the score is the phone's last word,
    /// and nothing on these pages can ask it anything.
    let isPhoneUnreachable: Bool

    /// Counts the intents that changed nothing, refused by the phone or never
    /// sent; each new value shakes the score once.
    let refusals: Int

    let onRallyWon: (Side) -> Void
    let onUndo: () -> Void

    /// Already confirmed by the control page when this is called.
    let onAbandon: () -> Void

    @State private var page = Page.score

    private enum Page {
        case controls
        case score
        case tapMode
    }

    var body: some View {
        // Around the pages, as `StartPages` has it, and with the bar left alone
        // for the same reason: the untitled score draws none, and the titled
        // tap-mode page needs one to push its list from.
        NavigationStack {
            TabView(selection: $page) {
                MatchControls(onAbandon: onAbandon)
                    .disabled(isPhoneUnreachable)
                    .tag(Page.controls)

                ScoreView(
                    points: points,
                    games: games,
                    sets: sets,
                    servingSide: servingSide,
                    servingHalf: servingHalf,
                    tapMode: tapMode,
                    mark: mark,
                    onRallyWon: onRallyWon,
                    onUndo: onUndo,
                    refusals: refusals)
                    .disabled(isPhoneUnreachable)
                    .opacity(isPhoneUnreachable ? Board.staleScore : 1)
                    .overlay {
                        if isPhoneUnreachable { PhoneUnreachable() }
                    }
                    .animation(.easeInOut(duration: Board.staleFade), value: isPhoneUnreachable)
                    .tag(Page.score)

                TapModePage(tapMode: $tapMode)
                    .tag(Page.tapMode)
            }
            .tabViewStyle(.verticalPage)
        }
    }
}

private struct MatchControls: View {
    let onAbandon: () -> Void

    @State private var isConfirming = false

    var body: some View {
        Button(role: .destructive) {
            isConfirming = true
        } label: {
            Label("End", systemImage: "xmark")
        }
        .padding(.horizontal)
        // An abandoned match does not come back into play, so this dialog is
        // the only guard against a mis-tap ending one.
        .confirmationDialog(
            "End the match?",
            isPresented: $isConfirming,
            titleVisibility: .visible
        ) {
            Button("End", role: .destructive) {
                WKInterfaceDevice.current().play(.stop)

                onAbandon()
            }
            Button("Keep playing", role: .cancel) {}
        } message: {
            Text("The match will be saved as unfinished.")
        }
    }
}

private struct PhoneUnreachable: View {
    var body: some View {
        VStack(spacing: Board.messageGap) {
            Image(systemName: "iphone.slash")
                .textStyle(.display)
                .foregroundStyle(Color.ball)

            Text("iPhone unreachable")
                .textStyle(.control)
                .foregroundStyle(Color.ink)

            Text("Bring your iPhone closer to go on.")
                .textStyle(.caption)
                .foregroundStyle(Color.ink.weight(.secondary))
        }
        .multilineTextAlignment(.center)
        .minimumScaleFactor(Board.messageScale)
        .padding(.horizontal, Board.inset)
        .accessibilityElement(children: .combine)
    }
}

/// No board: the unreachable phone has none, and the inset is the settings
/// page's.
private enum Board {
    static let inset: CGFloat = 8

    static let messageGap: CGFloat = 4

    static let messageScale: CGFloat = 0.7

    /// Dim enough that the message over it reads first, light enough that the
    /// score is still there to be read.
    static let staleScore: Double = 0.3

    static let staleFade: TimeInterval = 0.25
}

#if DEBUG

private struct Pages: View {
    var isPhoneUnreachable = false

    @State private var tapMode = TapMode.multiTap

    var body: some View {
        ScorePages(
            points: .game(SideCounts(us: 3, them: 2)),
            games: SideCounts(us: 4, them: 5),
            sets: nil,
            servingSide: .us,
            servingHalf: .right,
            tapMode: $tapMode,
            mark: nil,
            isPhoneUnreachable: isPhoneUnreachable,
            refusals: 0,
            onRallyWon: { _ in },
            onUndo: {},
            onAbandon: {})
    }
}

private let pages = Pages()

private let unreachable = Pages(isPhoneUnreachable: true)

#Preview { pages }

#Preview("In Russian") { pages.environment(\.locale, Locale(identifier: "ru")) }

#Preview("The phone unreachable") { unreachable }

#Preview("In Russian: the phone unreachable") { unreachable.environment(\.locale, Locale(identifier: "ru")) }

#Preview("At the largest type: the phone unreachable") {
    unreachable.environment(\.dynamicTypeSize, .accessibility5)
}

#endif
