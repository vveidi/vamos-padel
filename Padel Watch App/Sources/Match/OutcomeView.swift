import PadelDesign
import PadelScoring
import SwiftUI

struct OutcomeView: View {
    /// `nil` means abandoned, which is neither a win nor a loss.
    let winner: Side?

    /// Games in classic scoring, points in a match to N points.
    let score: SideCounts

    let onUndo: () -> Void

    let onFinish: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headline

                scoreLine.padding(.top, Board.headlineGap)

                buttons.padding(.top, Board.buttonsGap)
            }
            .padding(.horizontal, Board.inset)
            .padding(.bottom, Board.inset)
        }
        .background { ground }
    }

    // MARK: What happened

    private var headline: some View {
        Text(Self.sentence(winner))
            .textStyle(.display)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.5)
            .foregroundStyle(headlineInk)
    }

    /// The numbers are drawn winner-first, but VoiceOver always hears ours
    /// then theirs — spoken without the headline beside it, either order would
    /// otherwise be a guess.
    private var scoreLine: some View {
        counts
            .textStyle(.score)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .accessibilityLabel(Text("us \(score[.us]), opponents \(score[.them])"))
    }

    @ViewBuilder private var counts: some View {
        if let winner {
            Text(verbatim: "\(score[winner]) : \(score[winner.opposite])")
                .foregroundStyle(Color.courtInk)
        } else {
            (Text(verbatim: "\(score[.us])").foregroundStyle(Color.ball)
                + Text(verbatim: " : \(score[.them])").foregroundStyle(Color.ink))
        }
    }

    /// A whole sentence per outcome, not a side's name dropped into a frame:
    /// English puts the side before the verb and Russian after it.
    private static func sentence(_ winner: Side?) -> LocalizedStringKey {
        switch winner {
        case .us: "We won"
        case .them: "Opponents won"
        case nil: "Match unfinished"
        }
    }

    private var headlineInk: Color {
        switch winner {
        case .us: .ball
        case .them: Color.courtInk.weight(.control)
        case nil: Color.ink.weight(.control)
        }
    }

    // MARK: What to do next

    private var buttons: some View {
        VStack(spacing: Board.buttonGap) {
            PillButton(Text("New match"), carriesBall: true, action: onFinish)

            if winner != nil { undo }
        }
    }

    /// Shorter than the score screen's equivalent action on purpose: "Undo the
    /// last rally" is three lines of Russian in a pill this wide, which leaves
    /// the quiet button taller than the primary one above it.
    private var undo: some View {
        PillButton(Text("Undo the rally"), variant: .quiet, action: onUndo)
    }

    // MARK: The ground

    private var ground: some View {
        Group {
            if winner != nil {
                CourtHalf()
            } else {
                Color.night
            }
        }
        .overlay { Floodlight(corner: .topTrailing) }
        .overlay { NightScrim(edge: .bottom) }
        .ignoresSafeArea()
    }
}

/// This screen has no artboard; the numbers are borrowed from the screens that
/// do have one.
private enum Board {
    /// The settings page's inset — the boards' 16px halved.
    static let inset: CGFloat = 8

    static let headlineGap: CGFloat = 4

    static let buttonsGap: CGFloat = 16

    static let buttonGap: CGFloat = 6
}

#if DEBUG

private func outcome(winner: Side?, score: SideCounts) -> OutcomeView {
    OutcomeView(winner: winner, score: score, onUndo: {}, onFinish: {})
}

private func inRussian(_ view: some View) -> some View {
    view.environment(\.locale, Locale(identifier: "ru"))
}

private func atLargestType(_ view: some View) -> some View {
    view.environment(\.dynamicTypeSize, .accessibility5)
}

private let win = outcome(winner: .us, score: SideCounts(us: 6, them: 4))

private let defeat = outcome(winner: .them, score: SideCounts(us: 4, them: 6))

private let abandoned = outcome(winner: nil, score: SideCounts(us: 3, them: 5))

#Preview("A win") { win }

#Preview("In Russian: a win") { inRussian(win) }

#Preview("At the largest type: a win") { atLargestType(win) }

#Preview("In Russian, at the largest type: a win") { atLargestType(inRussian(win)) }

#Preview("A defeat") { defeat }

#Preview("In Russian: a defeat") { inRussian(defeat) }

#Preview("At the largest type: a defeat") { atLargestType(defeat) }

#Preview("In Russian, at the largest type: a defeat") { atLargestType(inRussian(defeat)) }

#Preview("An abandoned match") { abandoned }

#Preview("In Russian: an abandoned match") { inRussian(abandoned) }

#Preview("At the largest type: an abandoned match") { atLargestType(abandoned) }

#Preview("In Russian, at the largest type: an abandoned match") {
    atLargestType(inRussian(abandoned))
}

#endif
