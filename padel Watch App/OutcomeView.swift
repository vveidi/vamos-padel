import PadelScoring
import SwiftUI

/// The match's outcome — what is seen right after the last rally, or after the
/// match was stopped early.
struct OutcomeView: View {
    /// The side that won the match, or `nil` if the match was left abandoned.
    ///
    /// `nil` precisely, and not "the opponents won": an abandoned match counts
    /// as neither a win nor a loss, and the screen is the last place where that
    /// difference could be lost.
    let winner: Side?

    /// The score the match will be remembered by: games in classic scoring,
    /// points in the match to N points. The ruleset chooses it, not this
    /// screen.
    let score: SideCounts

    let onUndo: () -> Void

    /// Leads to the start screen for the next match. With the same tap the
    /// player picks the first server — on court it is being decided anew right
    /// then.
    let onFinish: () -> Void

    var body: some View {
        Group {
            if let winner { finished(winner) } else { unfinished }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal)
        .contentShape(Rectangle())
    }

    private func finished(_ winner: Side) -> some View {
        outcome(
            headline: winner == .us ? "Мы выиграли" : "Выиграли соперники",
            isOurs: winner == .us
        ) {
            // The winner's score comes first — the side the line above named.
            // Otherwise the outcome reads backwards: on the score screen the
            // opponents are on top, while here they would come second.
            Text("\(score[winner]) : \(score[winner.opposite])")
        }
        // The same gesture as on the score screen. Without it there is nothing
        // to undo a match finished by a mistaken tap with: this screen takes
        // the place of the one the gesture lives on.
        //
        // An abandoned match has no gesture: stopping is not a rally, undoing
        // a point does not lift it, and a gesture that looks like it works
        // while in fact only changing the score of an already stopped match is
        // worse than none. An accidental stop is guarded against by the
        // confirmation.
        .onLongPressGesture(minimumDuration: 0.5) { onUndo() }
        .accessibilityAction(named: "Отменить последний розыгрыш", onUndo)
    }

    private var unfinished: some View {
        outcome(headline: "Матч не доигран", isOurs: false) {
            // Who is who is said by the colour — the same one that marks our
            // half of the score screen. There is no winner here to set the
            // order, and a "us" label would take room away from the score.
            (Text("\(score[.us])").foregroundStyle(ScoreView.ourColor)
                + Text(" : \(score[.them])"))
                .accessibilityLabel("У нас \(score[.us]), у соперников \(score[.them])")
        }
    }

    private func outcome(
        headline: String, isOurs: Bool, @ViewBuilder score: () -> some View
    ) -> some View {
        VStack(spacing: 8) {
            Text(headline)
                .font(.headline)
                .foregroundStyle(isOurs ? ScoreView.ourColor : .secondary)

            score()
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            // A button, not a gesture: on this screen the player is no longer
            // on serve and is in no hurry, and mis-tapping into a new match in
            // the middle of dissecting the last rally is not something anybody
            // wants. By this point the match is written down in full, so
            // leaving here risks nothing.
            Button("Новый матч", action: onFinish)
                .buttonStyle(.bordered)
                .font(.footnote)
                .padding(.top, 4)
        }
    }
}

#Preview("A win") {
    OutcomeView(winner: .us, score: SideCounts(us: 6, them: 4), onUndo: {}, onFinish: {})
}

#Preview("An abandoned match") {
    OutcomeView(winner: nil, score: SideCounts(us: 3, them: 5), onUndo: {}, onFinish: {})
}
